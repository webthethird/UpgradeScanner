pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeMathUInt128.sol";
import "./SafeCast.sol";
import "./Utils.sol";

import "./Storage.sol";
import "./Config.sol";
import "./Events.sol";

import "./Bytes.sol";
import "./Operations.sol";

import "./UpgradeableMaster.sol";
import "./uniswap/UniswapV2Factory.sol";
import "./nft/ZKSeaNFT.sol";

import "./PairTokenManager.sol";

/// @title zkSync main contract
/// @author Matter Labs
/// @author ZKSwap L2 Labs
contract ZkSync is PairTokenManager, UpgradeableMaster, Storage, Config, Events, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;

    bytes32 public constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    //create pair
    function createPair(address _tokenA, address _tokenB) external nonReentrant {
        requireActive();
        governance.requireTokenLister(msg.sender);
        //check _tokenA is registered or not
        uint16 tokenAID = governance.validateTokenAddress(_tokenA);

        //check _tokenB is registered or not
        uint16 tokenBID = governance.validateTokenAddress(_tokenB);

        //make sure _tokenA is fee token
        require(tokenAID <= MAX_AMOUNT_OF_REGISTERED_FEE_TOKENS, "tokenA should be fee token");

        //create pair
        address pair = pairmanager.createPair(_tokenA, _tokenB);
        require(pair != address(0), "pair is invalid");

        addPairToken(pair);

        registerCreatePair(
            tokenAID,
            _tokenA,
            tokenBID,
            _tokenB,
            validatePairTokenAddress(pair),
            pair
        );
    }

    //create pair including ETH
    function createETHPair(address _tokenERC20) external nonReentrant {
        requireActive();
        governance.requireTokenLister(msg.sender);
        //check _tokenERC20 is registered or not
        uint16 erc20ID = governance.validateTokenAddress(_tokenERC20);

        //create pair
        address pair = pairmanager.createPair(address(0), _tokenERC20);
        require(pair != address(0), "pair is invalid");

        addPairToken(pair);

        registerCreatePair(
            0,
            address(0),
            erc20ID,
            _tokenERC20,
            validatePairTokenAddress(pair),
            pair
        );
    }

    function registerCreatePair(uint16 _tokenAID, address _tokenA, uint16 _tokenBID, address _tokenB, uint16 _tokenPair, address _pair) internal {
        // Priority Queue request
        Operations.CreatePair memory op = Operations.CreatePair({
            accountId : 0, //unknown at this point
            tokenA : _tokenAID,
            tokenB : _tokenBID,
            tokenPair : _tokenPair,
            pair : _pair
        });
        bytes memory pubData = Operations.writeCreatePairPubdata(op);
        bytes memory userData = abi.encodePacked(
            _tokenA,	// tokenA address
            _tokenB	// tokenB address
        );
        addPriorityRequest(Operations.OpType.CreatePair, pubData, userData);

        emit OnchainCreatePair(_tokenAID, _tokenBID, _tokenPair, _pair);
    }

    // Upgrade functional

    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external returns (uint) {
        return UPGRADE_NOTICE_PERIOD;
    }

    /// @notice Notification that upgrade notice period started
    function upgradeNoticePeriodStarted() external {

    }

    /// @notice Notification that upgrade preparation status is activated
    function upgradePreparationStarted() external {
        upgradePreparationActive = true;
        upgradePreparationActivationTime = now;
    }

    /// @notice Notification that upgrade canceled
    function upgradeCanceled() external {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
    }

    /// @notice Notification that upgrade finishes
    function upgradeFinishes() external {
        upgradePreparationActive = false;
        upgradePreparationActivationTime = 0;
    }

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external returns (bool) {
        return !exodusMode;
    }

    constructor() public {
        governance = Governance(msg.sender);
        zkSyncCommitBlockAddress = address(this);
        zkSyncExitAddress = address(this);
        zkSeaAddress = address(this);
    }

    /// @notice Franklin contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    /// _governanceAddress The address of Governance contract
    /// _verifierAddress The address of Verifier contract
    /// _ // FIXME: remove _genesisAccAddress
    /// _genesisRoot Genesis blocks (first block) root
    function initialize(bytes calldata initializationParameters) external {
        require(address(governance) == address(0), "init0");
        initializeReentrancyGuard();

        (
            address _governanceAddress,
            address _verifierAddress,
            address _verifierExitAddress,
            address _pairManagerAddress,
            address _zkSeaNFT
        ) = abi.decode(initializationParameters, (address, address, address, address, address));

        verifier = Verifier(_verifierAddress);
        verifierExit = VerifierExit(_verifierExitAddress);
        governance = Governance(_governanceAddress);
        pairmanager = UniswapV2Factory(_pairManagerAddress);
        zkSeaNFT = IZKSeaNFT(_zkSeaNFT);

        maxDepositAmount = DEFAULT_MAX_DEPOSIT_AMOUNT;
        withdrawGasLimit = ERC20_WITHDRAWAL_GAS_LIMIT;
        withdrawNFTGasLimit = ERC721_WITHDRAWAL_GAS_LIMIT;

    }

    /// @notice Config amount limit for each ERC20 deposit
    /// @param _amount Max deposit amount
    function setMaxDepositAmount(uint128 _amount) external {
        governance.requireGovernor(msg.sender);
        maxDepositAmount = _amount;
    }

    /// @notice Config gas limit for withdraw erc20 token
    /// @param _gasLimit withdraw erc20 gas limit
    function setWithdrawGasLimit(uint256 _gasLimit) external {
        governance.requireGovernor(msg.sender);
        withdrawGasLimit = _gasLimit;
    }

    /// @notice Config gas limit for withdraw nft token
    /// @param _gasLimit withdraw erc20 gas limit
    function setWithdrawNFTGasLimit(uint256 _gasLimit) external {
        governance.requireGovernor(msg.sender);
        withdrawNFTGasLimit = _gasLimit;
    }

    function setGenesisRootAndAddresses(bytes32 _genesisRoot, address _zkSyncCommitBlockAddress,
        address _zkSyncExitAddress, address _zkSeaAddress) external {
        // This function cannot be called twice as long as
        // _zkSyncCommitBlockAddress and _zkSyncExitAddress have been set to
        // non-zero.
        require(zkSyncCommitBlockAddress == address(0), "sraa1");
        require(zkSyncExitAddress == address(0), "sraa2");
        blocks[0].stateRoot = _genesisRoot;
        zkSyncCommitBlockAddress = _zkSyncCommitBlockAddress;
        zkSyncExitAddress = _zkSyncExitAddress;
        zkSeaAddress = _zkSeaAddress;
    }

    /// @notice zkSync contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    /// @notice Sends tokens
    /// @dev NOTE: will revert if transfer call fails or rollup balance difference (before and after transfer) is bigger than _maxAmount
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @param _maxAmount Maximum possible amount of tokens to transfer to this account
    function withdrawERC20Guarded(IERC20 _token, address _to, uint128 _amount, uint128 _maxAmount) external returns (uint128 withdrawnAmount) {
        require(msg.sender == address(this), "wtg10");
        // wtg10 - can be called only from this contract as one "external" call (to revert all this function state changes if it is needed)

        uint16 lpTokenId = tokenIds[address(_token)];
        uint256 balance_before = _token.balanceOf(address(this));
        if (lpTokenId > 0) {
            validatePairTokenAddress(address(_token));
            pairmanager.mint(address(_token), _to, _amount);
        } else {
            require(Utils.sendERC20(_token, _to, _amount), "wtg11");
            // wtg11 - ERC20 transfer fails
        }
        uint256 balance_after = _token.balanceOf(address(this));
        uint256 balance_diff = balance_before.sub(balance_after);
        require(balance_diff <= _maxAmount, "wtg12");
        // wtg12 - rollup balance difference (before and after transfer) is bigger than _maxAmount

        return SafeCast.toUint128(balance_diff);
    }

    /// @notice executes pending withdrawals
    /// @param _n The number of withdrawals to complete starting from oldest
    function completeWithdrawals(uint32 _n) external nonReentrant {
        // TODO: when switched to multi validators model we need to add incentive mechanism to call complete.
        uint32 toProcess = Utils.minU32(_n, numberOfPendingWithdrawals);
        uint32 startIndex = firstPendingWithdrawalIndex;
        numberOfPendingWithdrawals -= toProcess;
        firstPendingWithdrawalIndex += toProcess;

        for (uint32 i = startIndex; i < startIndex + toProcess; ++i) {
            uint16 tokenId = pendingWithdrawals[i].tokenId;
            address to = pendingWithdrawals[i].to;
            // send fails are ignored hence there is always a direct way to withdraw.
            delete pendingWithdrawals[i];

            bytes22 packedBalanceKey = packAddressAndTokenId(to, tokenId);
            uint128 amount = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
            // amount is zero means funds has been withdrawn with withdrawETH or withdrawERC20
            if (amount != 0) {
                balancesToWithdraw[packedBalanceKey].balanceToWithdraw = 0;
                bool sent = false;
                if (tokenId == 0) {
                    address payable toPayable = address(uint160(to));
                    sent = Utils.sendETHNoRevert(toPayable, amount);
                } else {
                    address tokenAddr = address(0);
                    if (tokenId < PAIR_TOKEN_START_ID) {
                        // It is normal ERC20
                        tokenAddr = governance.tokenAddresses(tokenId);
                    } else {
                        // It is pair token
                        tokenAddr = tokenAddresses[tokenId];
                    }
                    // tokenAddr cannot be 0
                    require(tokenAddr != address(0), "cwt0");
                    // we can just check that call not reverts because it wants to withdraw all amount
                    (sent,) = address(this).call.gas(withdrawGasLimit)(
                        abi.encodeWithSignature("withdrawERC20Guarded(address,address,uint128,uint128)", tokenAddr, to, amount, amount)
                    );
                }
                if (!sent) {
                    balancesToWithdraw[packedBalanceKey].balanceToWithdraw = amount;
                }
            }
        }
        if (toProcess > 0) {
            emit PendingWithdrawalsComplete(startIndex, startIndex + toProcess);
        }
    }


    /// @notice Accrues users balances from deposit priority requests in Exodus mode
    /// @dev WARNING: Only for Exodus mode
    /// @dev Canceling may take several separate transactions to be completed
    /// @param _n number of requests to process
    function cancelOutstandingDepositsForExodusMode(uint64 _n) external nonReentrant {
        require(exodusMode, "coe01");
        // exodus mode not active
        uint64 toProcess = Utils.minU64(totalOpenPriorityRequests, _n);
        require(toProcess > 0, "coe02");
        // no deposits to process
        for (uint64 id = firstPriorityRequestId; id < firstPriorityRequestId + toProcess; id++) {
            if (priorityRequests[id].opType == Operations.OpType.Deposit) {
                Operations.Deposit memory op = Operations.readDepositPubdata(priorityRequests[id].pubData);
                bytes22 packedBalanceKey = packAddressAndTokenId(op.owner, op.tokenId);
                balancesToWithdraw[packedBalanceKey].balanceToWithdraw += op.amount;
            } else if (priorityRequests[id].opType == Operations.OpType.DepositNFT) {
                Operations.DepositNFT memory op = Operations.readDepositNFTPubdata(priorityRequests[id].pubData);
                zkSeaNFT.addWithdraw(Operations.WithdrawNFTData({
                    valid: true,
                    pendingWithdraw: false,
                    globalId: op.globalId,
                    creatorId: op.creatorId,
                    seqId: op.seqId,
                    target: op.owner,
                    uri: op.uri
                }));
            }
            delete priorityRequests[id];
        }
        firstPriorityRequestId += toProcess;
        totalOpenPriorityRequests -= toProcess;
    }

    /// @notice Deposit ETH to Layer 2 - transfer ether from user into contract, validate it, register deposit
    /// @param _franklinAddr The receiver Layer 2 address
    function depositETH(address _franklinAddr) external payable nonReentrant {
        requireActive();
        registerDeposit(0, SafeCast.toUint128(msg.value), _franklinAddr);
    }

    /// @notice Withdraw ETH to Layer 1 - register withdrawal and transfer ether to sender
    /// @param _amount Ether amount to withdraw
    function withdrawETH(uint128 _amount) external nonReentrant {
        registerWithdrawal(0, _amount, msg.sender);
        (bool success,) = msg.sender.call.value(_amount)("");
        require(success, "fwe11");
        // ETH withdraw failed
    }

    /// @notice Withdraw ETH to Layer 1 - register withdrawal and transfer ether to _to address
    /// @param _amount Ether amount to withdraw
    function withdrawETHWithAddress(uint128 _amount, address payable _to) external nonReentrant {
        require(_to != address(0), "ipa11");
        registerWithdrawal(0, _amount, _to);
        (bool success,) = _to.call.value(_amount)("");
        require(success, "fwe12");
        // ETH withdraw failed
    }

    /// @notice Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _franklinAddr Receiver Layer 2 address
    function depositERC20(IERC20 _token, uint104 _amount, address _franklinAddr) external nonReentrant {
        requireActive();

        // Get token id by its address
        uint16 lpTokenId = tokenIds[address(_token)];
        uint16 tokenId = 0;
        if (lpTokenId == 0) {
            // This means it is not a pair address
            tokenId = governance.validateTokenAddress(address(_token));
        } else {
            lpTokenId = validatePairTokenAddress(address(_token));
        }

        uint256 balance_before = 0;
        uint256 balance_after = 0;
        uint128 deposit_amount = 0;
        if (lpTokenId > 0) {
            // Note: For lp token, main contract always has no money
            balance_before = _token.balanceOf(msg.sender);
            pairmanager.burn(address(_token), msg.sender, SafeCast.toUint128(_amount));
            balance_after = _token.balanceOf(msg.sender);
            deposit_amount = SafeCast.toUint128(balance_before.sub(balance_after));
            require(deposit_amount <= maxDepositAmount, "fd011");
            registerDeposit(lpTokenId, deposit_amount, _franklinAddr);
        } else {
            balance_before = _token.balanceOf(address(this));
            require(Utils.transferFromERC20(_token, msg.sender, address(this), SafeCast.toUint128(_amount)), "fd012");
            // token transfer failed deposit
            balance_after = _token.balanceOf(address(this));
            deposit_amount = SafeCast.toUint128(balance_after.sub(balance_before));
            require(deposit_amount <= maxDepositAmount, "fd013");
            registerDeposit(tokenId, deposit_amount, _franklinAddr);
        }
    }

    /// @notice Withdraw ERC20 token to Layer 1 - register withdrawal and transfer ERC20 to sender
    /// @param _token Token address
    /// @param _amount amount to withdraw
    function withdrawERC20(IERC20 _token, uint128 _amount) external nonReentrant {
        uint16 lpTokenId = tokenIds[address(_token)];
        uint16 tokenId = 0;
        if (lpTokenId == 0) {
            // This means it is not a pair address
            tokenId = governance.validateTokenAddress(address(_token));
        } else {
            tokenId = validatePairTokenAddress(address(_token));
        }
        bytes22 packedBalanceKey = packAddressAndTokenId(msg.sender, tokenId);
        uint128 balance = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
        uint128 withdrawnAmount = this.withdrawERC20Guarded(_token, msg.sender, _amount, balance);
        registerWithdrawal(tokenId, withdrawnAmount, msg.sender);
    }

    /// @notice Withdraw ERC20 token to Layer 1 - register withdrawal and transfer ERC20 to _to address
    /// @param _token Token address
    /// @param _amount amount to withdraw
    /// @param _to address to withdraw
    function withdrawERC20WithAddress(IERC20 _token, uint128 _amount, address payable _to) external nonReentrant {
        require(_to != address(0), "ipa12");
        uint16 lpTokenId = tokenIds[address(_token)];
        uint16 tokenId = 0;
        if (lpTokenId == 0) {
            // This means it is not a pair address
            tokenId = governance.validateTokenAddress(address(_token));
        } else {
            tokenId = validatePairTokenAddress(address(_token));
        }
        bytes22 packedBalanceKey = packAddressAndTokenId(_to, tokenId);
        uint128 balance = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
        uint128 withdrawnAmount = this.withdrawERC20Guarded(_token, _to, _amount, balance);
        registerWithdrawal(tokenId, withdrawnAmount, _to);
    }


    /// @notice Register full exit request - pack pubdata, add priority request
    /// @param _accountId Numerical id of the account
    /// @param _token Token address, 0 address for ether
    function fullExit(uint32 _accountId, address _token) external nonReentrant {
        requireActive();
        require(_accountId <= MAX_ACCOUNT_ID, "fee11");

        uint16 tokenId;
        if (_token == address(0)) {
            tokenId = 0;
        } else {
            tokenId = governance.validateTokenAddress(_token);
            require(tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, "fee12");
        }

        // Priority Queue request
        Operations.FullExit memory op = Operations.FullExit({
            accountId : _accountId,
            owner : msg.sender,
            tokenId : tokenId,
            amount : 0 // unknown at this point
        });
        bytes memory pubData = Operations.writeFullExitPubdata(op);
        addPriorityRequest(Operations.OpType.FullExit, pubData, "");

        // User must fill storage slot of balancesToWithdraw(msg.sender, tokenId) with nonzero value
        // In this case operator should just overwrite this slot during confirming withdrawal
        bytes22 packedBalanceKey = packAddressAndTokenId(msg.sender, tokenId);
        balancesToWithdraw[packedBalanceKey].gasReserveValue = 0xff;
    }

    /// @notice Register deposit request - pack pubdata, add priority request and emit OnchainDeposit event
    /// @param _tokenId Token by id
    /// @param _amount Token amount
    /// @param _owner Receiver
    function registerDeposit(
        uint16 _tokenId,
        uint128 _amount,
        address _owner
    ) internal {
        // Priority Queue request
        Operations.Deposit memory op = Operations.Deposit({
            accountId : 0, // unknown at this point
            owner : _owner,
            tokenId : _tokenId,
            amount : _amount
        });
        bytes memory pubData = Operations.writeDepositPubdata(op);
        addPriorityRequest(Operations.OpType.Deposit, pubData, "");

        emit OnchainDeposit(
            msg.sender,
            _tokenId,
            _amount,
            _owner
        );
    }

    /// @notice Register withdrawal - update user balance and emit OnchainWithdrawal event
    /// @param _token - token by id
    /// @param _amount - token amount
    /// @param _to - address to withdraw to
    function registerWithdrawal(uint16 _token, uint128 _amount, address payable _to) internal {
        bytes22 packedBalanceKey = packAddressAndTokenId(_to, _token);
        uint128 balance = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
        balancesToWithdraw[packedBalanceKey].balanceToWithdraw = balance.sub(_amount);
        emit OnchainWithdrawal(
            _to,
            _token,
            _amount
        );
    }
    /// @notice Checks that current state not is exodus mode
    function requireActive() internal view {
        require(!exodusMode, "fre11");
        // exodus mode activated
    }

    // Priority queue
    /// @notice Saves priority request in storage
    /// @dev Calculates expiration block for request, store this request and emit NewPriorityRequest event
    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    function addPriorityRequest(
        Operations.OpType _opType,
        bytes memory _pubData,
        bytes memory _userData
    ) internal {
        // Expiration block is: current block number + priority expiration delta
        uint256 expirationBlock = block.number + PRIORITY_EXPIRATION;

        uint64 nextPriorityRequestId = firstPriorityRequestId + totalOpenPriorityRequests;

        priorityRequests[nextPriorityRequestId] = PriorityOperation({
            opType : _opType,
            pubData : _pubData,
            expirationBlock : expirationBlock
        });

        emit NewPriorityRequest(
            msg.sender,
            nextPriorityRequestId,
            _opType,
            _pubData,
            _userData,
            expirationBlock
        );

        totalOpenPriorityRequests++;
    }

    /// @notice Check withdrawls in verified block and generate pending withdraw if necessary
    /// @param _blockNumberFrom Block number from
    /// @param _blockNumberTo Block number to
    /// @param _withdrawalsData - withdraw data of next verified block
    function checkWithdrawals(uint32 _blockNumberFrom, uint32 _blockNumberTo, bytes[] calldata _withdrawalsData) external nonReentrant {
        require(_blockNumberFrom <= _blockNumberTo, "cw1");
        require(_blockNumberFrom == totalBlocksChecked + 1, "cw2");
        require(_blockNumberTo <= totalBlocksVerified, "cw3");

        for (uint32 _blockNumber = _blockNumberFrom; _blockNumber <= _blockNumberTo; _blockNumber++){
            processOnchainWithdrawals(_withdrawalsData[_blockNumber - _blockNumberFrom], blocks[_blockNumber].withdrawalsDataHash);
        }

        totalBlocksChecked = _blockNumberTo;
    }

    /// @notice Processes onchain withdrawals. Full exit withdrawals will not be added to pending withdrawals queue
    /// @dev NOTICE: must process only withdrawals which hash matches with expectedWithdrawalsDataHash.
    /// @param withdrawalsData Withdrawals data
    /// @param expectedWithdrawalsDataHash Expected withdrawals data hash
    function processOnchainWithdrawals(bytes memory withdrawalsData, bytes32 expectedWithdrawalsDataHash) internal {

        bytes32 withdrawalsDataHash = EMPTY_STRING_KECCAK;

        uint offset = 0;
        uint32 localNumberOfPendingWithdrawals = numberOfPendingWithdrawals;
        while (offset < withdrawalsData.length) {
            (bool isNFTWithdraw, uint128 amount, uint16 tokenId, Operations.WithdrawNFTData memory nftData) = Operations.readWithdrawalData(withdrawalsData, offset);
            if (!isNFTWithdraw) {
                bytes22 packedBalanceKey = packAddressAndTokenId(nftData.target, tokenId);

                uint128 balance = balancesToWithdraw[packedBalanceKey].balanceToWithdraw;
                // after this all writes to this slot will cost 5k gas
                balancesToWithdraw[packedBalanceKey] = BalanceToWithdraw({
                balanceToWithdraw: balance.add(amount),
                gasReserveValue: 0xff
                });

                if (nftData.pendingWithdraw) {
                    pendingWithdrawals[firstPendingWithdrawalIndex + localNumberOfPendingWithdrawals] = PendingWithdrawal(nftData.target, tokenId);
                    localNumberOfPendingWithdrawals++;
                }
                withdrawalsDataHash = keccak256(abi.encode(withdrawalsDataHash, nftData.pendingWithdraw, nftData.target, tokenId, amount));
                offset += ONCHAIN_WITHDRAWAL_BYTES;
            } else {
                zkSeaNFT.addWithdraw(nftData);
                withdrawalsDataHash = keccak256(abi.encode(withdrawalsDataHash, nftData.pendingWithdraw, nftData.target, nftData.globalId));
                offset += ONCHAIN_WITHDRAWAL_NFT_BYTES;
            }
        }
        require(withdrawalsDataHash == expectedWithdrawalsDataHash, "pow12"); // pow12 - withdrawals data hash not matches with expected value
        if (numberOfPendingWithdrawals != localNumberOfPendingWithdrawals) {
            emit PendingWithdrawalsAdd(firstPendingWithdrawalIndex + numberOfPendingWithdrawals, firstPendingWithdrawalIndex + localNumberOfPendingWithdrawals);
        }
        numberOfPendingWithdrawals = localNumberOfPendingWithdrawals;
    }

    // The contract is too large. Break some functions to zkSeaAddress
    function() external payable {
        address nextAddress = zkSeaAddress;
        require(nextAddress != address(0), "zkSeaAddress should be set");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), nextAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }
}
