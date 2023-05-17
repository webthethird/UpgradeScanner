// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IMaticPool.sol";
import "./interfaces/IChildChainManager.sol";
import "./interfaces/IChildToken.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IBondToken.sol";

contract MaticPool is
    IMaticPool,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    /**
     * Variables
     */

    uint256 private _ON_DISTRIBUTE_GAS_LIMIT;
    address private _operator;

    uint256 private _minimumStake;
    uint256 public stakeCommission;
    uint256 public unstakeCommission;
    uint256 private _totalCommission;

    IChildToken private _maticToken;
    IBridge private _bridge;

    uint256 private _toChain;

    address private _bondToken;
    address private _certToken;

    address[] private _pendingClaimers;
    mapping(address => uint256) public pendingClaimerUnstakes;

    uint256 private _pendingGap;

    uint256 public stashedForManualDistributes;
    mapping(uint256 => bool) public markedForManualDistribute;

    mapping(address => bool) private _claimersForManualDistribute;

    /**
     * Modifiers
     */

    modifier badClaimer() {
        require(
            !_claimersForManualDistribute[msg.sender],
            "the address has a request for manual distribution"
        );
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == _operator, "Access: only operator");
        _;
    }

    function initialize(
        address operator,
        address maticAddress,
        address bondToken,
        address certToken,
        address bridgeAddress,
        uint256 minimumStake,
        uint256 toChain
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _operator = operator;
        _maticToken = IChildToken(maticAddress);
        _minimumStake = minimumStake;
        _certToken = certToken;
        _bondToken = bondToken;
        _bridge = IBridge(bridgeAddress);
        _toChain = toChain;
        _ON_DISTRIBUTE_GAS_LIMIT = 300000;
    }

    function stake(bool isRebasing) external payable override nonReentrant {
        uint256 realAmount = msg.value - stakeCommission;
        address staker = msg.sender;
        require(
            realAmount >= _minimumStake,
            "value must be greater than min stake amount"
        );
        _totalCommission += stakeCommission;
        // send matic across into Ethereum chain via MATIC POS
        _maticToken.withdraw{value: realAmount}(realAmount);
        emit Staked(staker, realAmount, isRebasing);
    }

    function unstake(uint256 amount, bool isRebasing)
        external
        payable
        override
        badClaimer
        nonReentrant
    {
        require(msg.value >= unstakeCommission, "wrong commission");
        _totalCommission += msg.value;
        address claimer = msg.sender;
        address fromToken = _bondToken;
        uint256 ratio = IBondToken(_bondToken).ratio();
        uint256 amountOut = transferFromAmount(amount, ratio);
        uint256 realAmount = bondsToShares(amountOut, ratio);
        if (!isRebasing) {
            fromToken = _certToken;
            realAmount = sharesToBonds(amountOut, ratio);
        }
        require(
            IERC20Upgradeable(fromToken).balanceOf(claimer) >= amount,
            "can not claim more than have on address"
        );
        // add to the queue
        if (pendingClaimerUnstakes[claimer] == 0) {
            _pendingClaimers.push(claimer);
        }
        pendingClaimerUnstakes[claimer] += realAmount;
        // transfer tokens from claimer
        IERC20Upgradeable(fromToken).transferFrom(
            claimer,
            address(this),
            amount
        );
        // send pegTokens across the bridge into ethereum
        _bridge.deposit(fromToken, _toChain, address(this), amountOut);
        emit Unstaked(claimer, amount, realAmount, isRebasing);
    }

    function distributeRewards() external payable nonReentrant {
        uint256 poolBalance = address(this).balance -
            stashedForManualDistributes -
            _totalCommission;
        address[] memory claimers = new address[](
            _pendingClaimers.length - _pendingGap
        );
        uint256[] memory amounts = new uint256[](
            _pendingClaimers.length - _pendingGap
        );
        uint256 j = 0;
        uint256 gaps = 0;
        uint256 i = _pendingGap;
        while (
            poolBalance > 0 &&
            i < _pendingClaimers.length &&
            gasleft() > _ON_DISTRIBUTE_GAS_LIMIT
        ) {
            address claimer = _pendingClaimers[i];
            if (_claimersForManualDistribute[claimer]) {
                i++;
                continue;
            }
            uint256 toDistribute = pendingClaimerUnstakes[claimer];
            /* we might have gaps lets just skip them (we shrink them on full claim) */
            if (claimer == address(0) || toDistribute == 0) {
                i++;
                gaps++;
                continue;
            }
            if (poolBalance < toDistribute) {
                toDistribute = poolBalance;
            }
            address payable wallet = payable(address(claimer));
            bool success;
            assembly {
                success := call(10000, wallet, toDistribute, 0, 0, 0, 0)
            }
            /* when we delete items from array we generate new gap, lets remember how many gaps we did to skip them in next claim */
            if (!success) {
                gaps++;
                markedForManualDistribute[i] = true;
                _claimersForManualDistribute[claimer] = true;
                toDistribute = pendingClaimerUnstakes[claimer];
                stashedForManualDistributes += toDistribute;
                emit ManualDistributeExpected(claimer, toDistribute, i);
                i++;
                continue;
            }
            claimers[j] = claimer;
            amounts[j] = toDistribute;

            poolBalance -= toDistribute;
            pendingClaimerUnstakes[claimer] -= toDistribute;
            j++;
            if (pendingClaimerUnstakes[claimer] != 0) {
                break;
            }
            delete _pendingClaimers[i];
            i++;
            gaps++;
        }
        _pendingGap += gaps;
        /* decrease arrays */
        uint256 removeCells = claimers.length - j;
        if (removeCells > 0) {
            assembly {
                mstore(claimers, j)
            }
            assembly {
                mstore(amounts, j)
            }
        }
        emit RewardsDistributed(claimers, amounts);
    }

    function distributeManual(uint256 id) external nonReentrant {
        require(
            markedForManualDistribute[id],
            "not marked for manual distributing"
        );
        address[] memory claimers = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        address claimer = _pendingClaimers[id];
        address payable wallet = payable(claimer);
        uint256 amount = pendingClaimerUnstakes[claimer];

        markedForManualDistribute[id] = false;
        _claimersForManualDistribute[claimer] = false;

        require(
            address(this).balance >= stashedForManualDistributes,
            "insufficient pool balance"
        );

        markedForManualDistribute[id] = false;
        _claimersForManualDistribute[claimer] = false;
        stashedForManualDistributes -= amount;

        claimers[0] = claimer;
        amounts[0] = amount;
        pendingClaimerUnstakes[claimer] = 0;

        (bool result, ) = wallet.call{value: amount}("");
        require(result, "failed to send rewards to claimer");
        delete _pendingClaimers[id];
        emit RewardsDistributed(claimers, amounts);
    }

    function withdrawCommission(uint256 threshold)
        external
        nonReentrant
        onlyOperator
    {
        // check min amount
        require(
            _totalCommission >= threshold,
            "total commission less then threshold"
        );
        uint256 toWithdraw = _totalCommission;
        _totalCommission = 0;
        address payable wallet = payable(address(_operator));
        (bool result, ) = wallet.call{value: toWithdraw, gas: 10000}("");
        require(result, "transfer was failed");
        emit CommissionWithdrawn(toWithdraw);
    }

    function calcPendingGap() external onlyOwner {
        uint256 gaps = 0;
        for (uint256 i = 0; i < _pendingClaimers.length; i++) {
            address claimer = _pendingClaimers[i];
            if (
                claimer != address(0) && !_claimersForManualDistribute[claimer]
            ) {
                break;
            }
            gaps++;
        }
        _pendingGap = gaps;
    }

    function resetPendingGap() external onlyOwner {
        _pendingGap = 0;
        emit PendingGapReseted();
    }

    function getPendingGap() external view returns (uint256) {
        return _pendingGap;
    }

    function changeStakeCommission(uint256 commission) external onlyOwner {
        stakeCommission = commission;
        emit CommissionsChanged(stakeCommission, unstakeCommission);
    }

    function changeUnstakeCommission(uint256 commission) external onlyOwner {
        unstakeCommission = commission;
        emit CommissionsChanged(stakeCommission, unstakeCommission);
    }

    function changeDistributeGasLimit(uint256 gasLimit) external onlyOwner {
        _ON_DISTRIBUTE_GAS_LIMIT = gasLimit;
        emit GasLimitChanged(gasLimit);
    }

    function changeBondToken(address bondToken) external onlyOwner {
        require(bondToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(bondToken),
            "non-contract address"
        );
        _bondToken = bondToken;
        emit BondTokenChanged(bondToken);
    }

    function changeCertToken(address certToken) external onlyOwner {
        require(certToken != address(0), "zero address");
        require(
            AddressUpgradeable.isContract(certToken),
            "non-contract address"
        );
        _certToken = certToken;
        emit CertTokenChanged(certToken);
    }

    function changeToChain(uint256 toChain) external onlyOwner {
        require(toChain != 0, "zero chain id");
        _toChain = toChain;
        emit ToChainChanged(toChain);
    }

    function changeOperator(address operator) external onlyOwner {
        require(operator != address(0), "zero address");
        _operator = operator;
        emit OperatorChanged(operator);
    }

    function changeMinimumStake(uint256 minimumStake) external onlyOwner {
        _minimumStake = minimumStake;
        emit MinimumStakeChanged(minimumStake);
    }

    function transferFromAmount(uint256 amount, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        return
            multiplyAndDivideCeil(
                multiplyAndDivideFloor(amount, ratio, 1e18),
                1e18,
                ratio
            );
    }

    function sharesToBonds(uint256 amount, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        return multiplyAndDivideFloor(amount, 1e18, ratio);
    }

    function bondsToShares(uint256 amount, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        return multiplyAndDivideFloor(amount, ratio, 1e18);
    }

    function saturatingMultiply(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return type(uint256).max;
            return c;
        }
    }

    function saturatingAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b) / c // can't fail because of assumption 2.
            );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
            );
    }

    receive() external payable {
        emit ReceivedRewards(msg.sender, msg.value);
    }
}
