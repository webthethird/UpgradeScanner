// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IDepositExecute.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IOneSplitWrap.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IERC20Upgradeable.sol";
import "./HandlerHelpersUpgradeable.sol";

/**
    @title Handles ERC20 deposits and deposit executions.
    @author Router Protocol.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract ERC20HandlerUpgradeable is
    Initializable,
    ContextUpgradeable,
    IDepositExecute,
    HandlerHelpersUpgradeable,
    ILiquidityPool
{
    using SafeMathUpgradeable for uint256;

    struct DepositRecord {
        uint8 _destinationChainID;
        address _srcTokenAddress;
        address _stableTokenAddress;
        uint256 _stableTokenAmount;
        address _destStableTokenAddress;
        uint256 _destStableTokenAmount;
        address _destinationTokenAdress;
        uint256 _destinationTokenAmount;
        bytes32 _resourceID;
        address _destinationRecipientAddress;
        address _depositer;
        uint256 _srcTokenAmount;
        address _feeTokenAddress;
        uint256 _feeAmount;
        uint256 _isDestNative;
    }

    // destId => depositNonce => Deposit Record
    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    // token contract address => chainId => decimals
    mapping(address => mapping(uint8 => uint8)) public tokenDecimals;

    mapping(uint256 => mapping(uint64 => uint256)) public executeRecord;

    function __ERC20HandlerUpgradeable_init(
        address bridgeAddress,
        address ETH,
        address WETH,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        address[] memory burnableContractAddresses
    ) internal initializer {
        __Context_init_unchained();
        __HandlerHelpersUpgradeable_init();

        require(
            initialResourceIDs.length == initialContractAddresses.length,
            "initialResourceIDs & initialContractAddresses len mismatch"
        );

        _bridgeAddress = bridgeAddress;
        _ETH = ETH;
        _WETH = WETH;

        uint256 initialResourceCount = initialResourceIDs.length;
        for (uint256 i = 0; i < initialResourceCount; i++) {
            _setResource(initialResourceIDs[i], initialContractAddresses[i]);
        }

        uint256 burnableCount = burnableContractAddresses.length;
        for (uint256 i = 0; i < burnableCount; i++) {
            _setBurnable(burnableContractAddresses[i], true);
        }
    }

    function __ERC20HandlerUpgradeable_init_unchained() internal initializer {}

    /**
        @param bridgeAddress Contract address of previously deployed Bridge.
        // Resource IDs are used to identify a specific contract address.
        // These are the Resource IDs this contract will initially support.
        // These are the addresses the {initialResourceIDs} will point to,
        // and are the contracts that will be called to perform various deposit calls.
        @param burnableContractAddresses These addresses will be set as burnable and when {deposit} is called,
        the deposited token will be burned.
        When {executeProposal} is called, new tokens will be minted.

        @dev {initialResourceIDs} and {initialContractAddresses} must have the same length
        (one resourceID for every address).
        Also, these arrays must be ordered in the way that {initialResourceIDs}[0] is the
        intended resourceID for {initialContractAddresses}[0].
     */
    function initialize(
        address bridgeAddress,
        address ETH,
        address WETH,
        bytes32[] memory initialResourceIDs,
        address[] memory initialContractAddresses,
        address[] memory burnableContractAddresses
    ) external initializer {
        __ERC20HandlerUpgradeable_init(
            bridgeAddress,
            ETH,
            WETH,
            initialResourceIDs,
            initialContractAddresses,
            burnableContractAddresses
        );
    }

    receive() external payable {}

    function setTokenDecimals(
        address tokenAddress, 
        uint8 destinationChainID, 
        uint8 decimals
    ) public onlyRole(BRIDGE_ROLE) {
        require(_contractWhitelist[tokenAddress], "provided contract is not whitelisted");
        tokenDecimals[tokenAddress][destinationChainID] = decimals;
    }

    function changePrecision(
        address token,
        uint8 chainId,
        uint256 tokenAmount
    ) public view returns (uint256) {
        IERC20Upgradeable srcToken = IERC20Upgradeable(token);
        require(tokenDecimals[token][chainId] > 0, "Decimals not set for token and chain id");
        uint8 srcDecimal = srcToken.decimals();
        uint8 destDecimal = tokenDecimals[token][chainId];
        if(srcDecimal == destDecimal)
            return tokenAmount;
        if(srcDecimal > destDecimal){
            uint256 factor = (10 ** (srcDecimal - destDecimal));
            return tokenAmount / factor;
        } else {
            uint256 factor = (10 ** (destDecimal - srcDecimal));
            return tokenAmount * factor;
        }
    }

    function setExecuteRecord(
        uint256 chainId, 
        uint64 nonce
    ) internal {
        executeRecord[chainId][nonce] = block.number;
    }

    /**
        @param depositNonce This ID will have been generated by the Bridge contract.
        @param destId ID of chain deposit will be bridged to.
        @return DepositRecord
    */
    function getDepositRecord(uint64 depositNonce, uint8 destId) public view virtual returns (DepositRecord memory) {
        return _depositRecords[destId][depositNonce];
    }

    function setReserve(IHandlerReserve reserve) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _reserve = reserve;
    }

    /**
        @notice A deposit is initiatied by making a deposit in the Bridge contract.
        @param destinationChainID Chain ID of chain tokens are expected to be bridged to.
        @param depositNonce This value is generated as an ID by the Bridge contract.
        @dev Depending if the corresponding {tokenAddress} for the parsed {resourceID} is
        marked true in {_burnList}, deposited tokens will be burned, if not, they will be locked.
     */
    function deposit(
        bytes32 resourceID,
        uint8 destinationChainID,
        uint64 depositNonce,
        SwapInfo memory swapDetails
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        uint256 feeAmount;
        swapDetails.srcStableTokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[swapDetails.srcStableTokenAddress], "provided tokenAddress is not whitelisted");

        if (address(swapDetails.srcTokenAddress) == swapDetails.srcStableTokenAddress) {
            require(swapDetails.srcStableTokenAmount == swapDetails.srcTokenAmount, "Invalid token amount");
            if (swapDetails.feeTokenAddress == address(0)) {
                swapDetails.feeTokenAddress = swapDetails.srcStableTokenAddress;
            }
            (uint256 transferFee, ) = getBridgeFee(destinationChainID, swapDetails.feeTokenAddress);
            feeAmount = transferFee;
            // Fees of stable token address
            _reserve.deductFee(
                swapDetails.feeTokenAddress,
                swapDetails.depositer,
                // swapDetails.providedFee,
                transferFee,
                // _ETH,
                _isFeeEnabled,
                address(feeManager)
            );
            // just deposit
            handleDepositForReserveToken(swapDetails);
        } else if (_reserve._contractToLP(swapDetails.srcStableTokenAddress) == address(swapDetails.srcTokenAddress)) {
            require(swapDetails.srcStableTokenAmount == swapDetails.srcTokenAmount, "Invalid token amount");
            feeAmount = deductFeeAndHandleDepositForLPToken(swapDetails, destinationChainID);
        } else {
            if (swapDetails.feeTokenAddress != address(0)) {
                (, uint256 exchangeFee) = getBridgeFee(destinationChainID, swapDetails.feeTokenAddress);
                feeAmount = exchangeFee;
                // Fees of stable token address

                _reserve.deductFee(
                    swapDetails.feeTokenAddress,
                    swapDetails.depositer,
                    // swapDetails.providedFee,
                    exchangeFee,
                    // _ETH,
                    _isFeeEnabled,
                    address(feeManager)
                );
            }

            _reserve.lockERC20(
                address(swapDetails.srcTokenAddress),
                swapDetails.depositer,
                _oneSplitAddress,
                swapDetails.srcTokenAmount
            );
            handleDepositForNonReserveToken(swapDetails);
            if (swapDetails.feeTokenAddress == address(0)) {
                (, uint256 exchangeFee) = getBridgeFee(destinationChainID, swapDetails.srcStableTokenAddress);
                feeAmount = exchangeFee;
                swapDetails.feeTokenAddress = swapDetails.srcStableTokenAddress;
                require(
                    swapDetails.srcStableTokenAmount >= exchangeFee,
                    "ERC20handler : provided fee is less than the amount"
                );
                swapDetails.srcStableTokenAmount = swapDetails.srcStableTokenAmount - exchangeFee;
                _reserve.releaseERC20(swapDetails.feeTokenAddress, address(feeManager), exchangeFee);
                if (_burnList[address(swapDetails.srcStableTokenAddress)]) {
                    _reserve.burnERC20(
                        address(swapDetails.srcStableTokenAddress),
                        address(_reserve),
                        swapDetails.srcStableTokenAmount
                    );
                }
            }
        }
        uint256 destStableTokenAmount = changePrecision(
            address(swapDetails.srcStableTokenAddress), 
            destinationChainID, 
            swapDetails.srcStableTokenAmount
        );
        require(destStableTokenAmount > 0, "Transfer amount too low");
        _depositRecords[destinationChainID][depositNonce] = DepositRecord(
            destinationChainID,
            address(swapDetails.srcTokenAddress),
            swapDetails.srcStableTokenAddress,
            swapDetails.srcStableTokenAmount,
            address(swapDetails.destStableTokenAddress),
            destStableTokenAmount,
            address(swapDetails.destTokenAddress),
            swapDetails.destTokenAmount,
            resourceID,
            swapDetails.recipient,
            swapDetails.depositer,
            swapDetails.srcTokenAmount,
            swapDetails.feeTokenAddress,
            feeAmount,
            swapDetails.isDestNative ? 1 : 0
        );
    }

    /**
        @notice Proposal execution should be initiated when a proposal is finalized in the Bridge contract.
        by a relayer on the deposit's destination chain.
        @notice Data passed into the function should be constructed as follows:
        amount                                 uint256     bytes  0 - 32
        destinationRecipientAddress length     uint256     bytes  32 - 64
        destinationRecipientAddress            bytes       bytes  64 - END
     */
    function executeProposal(SwapInfo memory swapDetails, bytes32 resourceID)
        public
        virtual
        override
        onlyRole(BRIDGE_ROLE)
        returns (address settlementToken, uint256 settlementAmount)
    {
        swapDetails.destStableTokenAddress = _resourceIDToTokenContractAddress[resourceID];
        require(_contractWhitelist[swapDetails.destStableTokenAddress], "provided tokenAddress is not whitelisted");

        if (address(swapDetails.destTokenAddress) == swapDetails.destStableTokenAddress) {
            // just release destStable tokens
            (settlementToken, settlementAmount) = handleExecuteForReserveToken(swapDetails);
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        } else if (
            _reserve._contractToLP(swapDetails.destStableTokenAddress) == address(swapDetails.destTokenAddress)
        ) {
            // release LP is destToken is LP of destStableToken
            handleExecuteForLPToken(swapDetails);
            settlementToken = address(swapDetails.destTokenAddress);
            settlementAmount = swapDetails.destStableTokenAmount;
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        } else {
            // exchange destStable to destToken and release tokens
            (settlementToken, settlementAmount) = handleExecuteForNonReserveToken(swapDetails);
            setExecuteRecord(swapDetails.index, swapDetails.depositNonce);
        }
    }

    /**
        @notice Used to manually release ERC20 tokens from ERC20Safe.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amount The amount of ERC20 tokens to release.
     */
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.releaseERC20(tokenAddress, recipient, amount);
    }

    /**
        @notice Used to manually release ERC20 tokens from FeeManager.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amount The amount of ERC20 tokens to release.
     */
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        feeManager.withdrawFee(tokenAddress, recipient, amount);
    }

    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.stake(depositor, tokenAddress, amount);
    }

    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        assert(IWETH(_WETH).transfer(address(_reserve), amount));
        _reserve.stakeETH(depositor, tokenAddress, amount);
    }

    /**
        @notice Staking should be done by using bridge contract.
        @param unstaker removes liquidity from the pool.
        @param tokenAddress staking token of which liquidity needs to be removed.
        @param amount Amount that needs to be unstaked.
     */

    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.unstake(unstaker, tokenAddress, amount);
    }

    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve.unstakeETH(unstaker, tokenAddress, amount, _WETH);
    }

    function getStakedRecord(address account, address tokenAddress) public view virtual returns (uint256) {
        return _reserve.getStakedRecord(account, tokenAddress);
    }

    function handleDepositForReserveToken(SwapInfo memory swapDetails) internal {
        if (_burnList[address(swapDetails.srcTokenAddress)]) {
            _reserve.burnERC20(address(swapDetails.srcTokenAddress), swapDetails.depositer, swapDetails.srcTokenAmount);
        } else {
            _reserve.lockERC20(
                address(swapDetails.srcTokenAddress),
                swapDetails.depositer,
                address(_reserve),
                swapDetails.srcTokenAmount
            );
        }
    }

    function deductFeeAndHandleDepositForLPToken(
        SwapInfo memory swapDetails, 
        uint8 destinationChainID
    ) internal returns (uint256 transferFee){
        if (swapDetails.feeTokenAddress == address(0)) {
            swapDetails.feeTokenAddress = address(swapDetails.srcTokenAddress);
            (transferFee, ) = getBridgeFee(destinationChainID, swapDetails.srcStableTokenAddress);
        }else{
            (transferFee, ) = getBridgeFee(destinationChainID, swapDetails.feeTokenAddress);
        }
        // Fees of stable token address
        _reserve.deductFee(
            swapDetails.feeTokenAddress,
            swapDetails.depositer,
            // swapDetails.providedFee,
            transferFee,
            // _ETH,
            _isFeeEnabled,
            address(feeManager)
        );
        _reserve.burnERC20(address(swapDetails.srcTokenAddress), swapDetails.depositer, swapDetails.srcTokenAmount);
    }

    function handleDepositForNonReserveToken(SwapInfo memory swapDetails) internal {
        if (swapDetails.path.length > 2) {
            //swapMulti
            swapDetails.srcStableTokenAmount = _reserve.swapMulti(
                _oneSplitAddress,
                swapDetails.path,
                swapDetails.srcTokenAmount,
                swapDetails.srcStableTokenAmount,
                swapDetails.distribution,
                swapDetails.flags
            );
        } else {
            swapDetails.srcStableTokenAmount = _reserve.swap(
                _oneSplitAddress,
                address(swapDetails.srcTokenAddress),
                swapDetails.srcStableTokenAddress,
                swapDetails.srcTokenAmount,
                swapDetails.srcStableTokenAmount,
                swapDetails.distribution,
                swapDetails.flags[0]
            );
        }
    }

    function handleExecuteForReserveToken(SwapInfo memory swapDetails) internal returns (address, uint256) {
        if (_burnList[address(swapDetails.destTokenAddress)]) {
            _reserve.mintERC20(
                address(swapDetails.destTokenAddress),
                swapDetails.recipient,
                swapDetails.destStableTokenAmount
            );
        } else {
            uint256 reserveBalance = IERC20(address(swapDetails.destStableTokenAddress)).balanceOf(address(_reserve));
            if (reserveBalance < swapDetails.destStableTokenAmount) {
                _reserve.mintWrappedERC20(
                    address(swapDetails.destStableTokenAddress),
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (
                    _reserve._contractToLP(address(swapDetails.destStableTokenAddress)),
                    swapDetails.destStableTokenAmount
                );
            } else {
                if (address(swapDetails.destStableTokenAddress) == _WETH && swapDetails.isDestNative) {
                    _reserve.withdrawWETH(_WETH, swapDetails.destStableTokenAmount);
                    _reserve.safeTransferETH(swapDetails.recipient, swapDetails.destStableTokenAmount);
                } else {
                    _reserve.releaseERC20(
                        address(swapDetails.destStableTokenAddress),
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    );
                }
            }
        }
        return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
    }

    function handleExecuteForLPToken(SwapInfo memory swapDetails) internal {
        _reserve.mintWrappedERC20(
            address(swapDetails.destStableTokenAddress),
            swapDetails.recipient,
            swapDetails.destStableTokenAmount
        );
    }

    function handleExecuteForNonReserveToken(SwapInfo memory swapDetails) internal returns (address, uint256) {
        if (_burnList[swapDetails.destStableTokenAddress]) {
            _reserve.mintERC20(swapDetails.destStableTokenAddress, _oneSplitAddress, swapDetails.destStableTokenAmount);
        } else {
            uint256 reserveBalance = IERC20(address(swapDetails.destStableTokenAddress)).balanceOf(address(_reserve));
            if (reserveBalance < swapDetails.destStableTokenAmount) {
                _reserve.mintWrappedERC20(
                    address(swapDetails.destStableTokenAddress),
                    swapDetails.recipient,
                    swapDetails.destStableTokenAmount
                );
                return (
                    _reserve._contractToLP(address(swapDetails.destStableTokenAddress)),
                    swapDetails.destStableTokenAmount
                );
            } else {
                _reserve.releaseERC20(
                    swapDetails.destStableTokenAddress,
                    _oneSplitAddress,
                    swapDetails.destStableTokenAmount
                );
            }
        }
        if (swapDetails.path.length > 2) {
            //solhint-disable avoid-low-level-calls
            (bool success, bytes memory returnData) = address(_reserve).call(
                abi.encodeWithSelector(
                    0x8da61307, // swapMulti(address,address[],uint256,uint256,uint256[],uint256[])
                    _oneSplitAddress,
                    swapDetails.path,
                    swapDetails.destStableTokenAmount,
                    swapDetails.destTokenAmount,
                    swapDetails.distribution,
                    swapDetails.flags
                )
            );
            if (success) {
                swapDetails.returnAmount = abi.decode(returnData, (uint256));
            } else {
                require(
                    IOneSplitWrap(_oneSplitAddress).withdraw(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    )
                );
                return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
            }
        } else {
            (bool success, bytes memory returnData) = address(_reserve).call(
                abi.encodeWithSelector(
                    0x951db637, // swap(address,address,address,uint256,uint256,uint256[],uint256)
                    _oneSplitAddress,
                    swapDetails.destStableTokenAddress,
                    address(swapDetails.destTokenAddress),
                    swapDetails.destStableTokenAmount,
                    swapDetails.destTokenAmount,
                    swapDetails.distribution,
                    swapDetails.flags[0]
                )
            );
            if (success) {
                swapDetails.returnAmount = abi.decode(returnData, (uint256));
            } else {
                require(
                    IOneSplitWrap(_oneSplitAddress).withdraw(
                        swapDetails.destStableTokenAddress,
                        swapDetails.recipient,
                        swapDetails.destStableTokenAmount
                    )
                );
                return (address(swapDetails.destStableTokenAddress), swapDetails.destStableTokenAmount);
            }
        }
        if (address(swapDetails.destTokenAddress) == _WETH && swapDetails.isDestNative) {
            _reserve.withdrawWETH(_WETH, swapDetails.returnAmount);
            _reserve.safeTransferETH(swapDetails.recipient, swapDetails.returnAmount);
        } else {
            _reserve.releaseERC20(
                address(swapDetails.destTokenAddress),
                swapDetails.recipient,
                swapDetails.returnAmount
            );
        }
        return (address(swapDetails.destTokenAddress), swapDetails.returnAmount);
    }
}
