// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./IVotingEscrow.sol";
import "./ApolloxERC721EnumerableUpgradeable.sol";
import "./ISvgBuilderClient.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years)
*/
contract VotingEscrow is IVotingEscrow, ApolloxERC721EnumerableUpgradeable, UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable{

    using Strings for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant DEV_OPERATOR = keccak256("DEV_OPERATOR");
    bytes32 public constant POINT_CHECKER_ROLE = keccak256("POINT_CHECKER");

    enum DepositType {
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    event Deposit(
        address indexed provider,
        uint tokenId,
        uint value,
        uint indexed locktime,
        DepositType _depositType,
        uint ts
    );
    event Withdraw(address indexed provider, uint tokenId, uint value, uint ts);
    event Supply(uint prevSupply, uint supply);
    event CanTransfer(bool prevStat, bool afterStat);

    uint internal constant WEEK = 1 weeks;
    uint public constant MAX_TIME = 4 * 365 * 86400;
    int128 internal constant iMAX_TIME = 4 * 365 * 86400;
    uint internal constant MULTIPLIER = 1 ether; //1e18
    uint256 public constant MIN_LOCK_AMOUNT = 1e17;

    ISvgBuilderClient private _svgBuilderClient;
    IERC20Upgradeable public _lockToken;
    uint public _totalLocked;
    mapping(uint => LockedBalance) public _lockedBalances;

    uint public _epoch;
    mapping(uint => Point) public _pointHistory; // epoch -> unsigned point
    mapping(uint => Point[1000000000]) public _nftPointHistory; // user -> Point[user_epoch]

    //epoch of NFT
    mapping(uint => uint) public _nftPointEpoch;
    mapping(uint => int128) public _slopeChanges; // time -> signed slope change

    /// @dev Current count of token
    uint256 public _maxTokenId;
    uint256 public _sumLockedTime;
    bool public _canTransfer;

    mapping(address => uint256) private _lastBlockNumberCalled;
    // the final owner (for burnt NFT)
    mapping(uint256 => address) public _latestOwner;


    function initialize(IERC20Upgradeable lockToken, ISvgBuilderClient svgBuilderClient) public initializer {
        __ERC721_init("veNFT", "veNFT");
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_OPERATOR, msg.sender);
        _setupRole(POINT_CHECKER_ROLE, msg.sender);
        _lockToken = lockToken;
        _svgBuilderClient = svgBuilderClient;
        _pointHistory[0].blk = block.number;
        _pointHistory[0].ts = block.timestamp;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEV_OPERATOR) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ApolloxERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if(from != address(0) && to != address(0)){
            require(_canTransfer, "Transfer not support");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /* ========== MODIFIERS ========== */
    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }
    function _oncePerBlock(address user) internal {
        require(_lastBlockNumberCalled[user] < block.number, "once per block");
        _lastBlockNumberCalled[user] = block.number;
    }

    /* ========== WRITE FUNCTIONS ========== */
    function createLock(uint lockAmount, uint lockDuration) external whenNotPaused nonReentrant oncePerBlock(msg.sender) returns (uint) {
        require(lockDuration > 0 && lockDuration<=MAX_TIME, 'Invalid duration');
        uint unlockTime = (block.timestamp + lockDuration) / WEEK * WEEK; // LockTime is Can only increase lock duration rounded down to weeks

        require(lockAmount >= MIN_LOCK_AMOUNT, 'Invalid amount'); //need more than 0.1
        require(unlockTime > block.timestamp, 'Can only lock until time in the future');

        ++_maxTokenId;
        _sumLockedTime = _sumLockedTime + (unlockTime - block.timestamp); // add locked time
        uint tokenId = _maxTokenId;
        _safeMint(msg.sender, tokenId);
        _depositFor(tokenId, lockAmount, unlockTime, _lockedBalances[tokenId], DepositType.CREATE_LOCK_TYPE);
        return tokenId;
    }

    function increaseAmount(uint tokenId, uint addAmount) external whenNotPaused nonReentrant{
        require(ownerOf(tokenId) == msg.sender, "ERC721: transfer caller is not owner");
        require(addAmount >= MIN_LOCK_AMOUNT, 'Invalid amount'); //need more than 0.1

        LockedBalance memory lockedBalance = _lockedBalances[tokenId];

        require(lockedBalance.amount > 0, 'No existing lock found');
        require(lockedBalance.end > block.timestamp, 'Cannot add to expired lock. Withdraw');

        _depositFor(tokenId, addAmount, 0, lockedBalance, DepositType.INCREASE_LOCK_AMOUNT);
    }

    function increaseUnlockTime(uint tokenId, uint lockDuration) external whenNotPaused nonReentrant{
        require(lockDuration > 0 && lockDuration<=MAX_TIME, 'Invalid duration');
        require(ownerOf(tokenId) == msg.sender, "ERC721: transfer caller is not owner");

        LockedBalance memory lockedBalance = _lockedBalances[tokenId];
        uint unlockTime = (block.timestamp + lockDuration) / WEEK * WEEK; // Locktime is rounded down to weeks

        require(lockedBalance.end > block.timestamp, 'Lock expired');
        require(lockedBalance.amount > 0, 'Nothing is locked');
        require(unlockTime > lockedBalance.end, 'Can only increase lock duration');
        require(unlockTime <= block.timestamp + MAX_TIME, 'Voting lock can be 4 years max');

        _sumLockedTime = _sumLockedTime + (unlockTime - lockedBalance.end); // add locked time

        _depositFor(tokenId, 0, unlockTime, lockedBalance, DepositType.INCREASE_UNLOCK_TIME);
    }

    function _depositFor(
        uint tokenId,
        uint lockAmount,
        uint unlockTime,
        LockedBalance memory lockedBalance,
        DepositType depositType
    ) internal {
        uint totalLockedBefore = _totalLocked;
        _totalLocked = totalLockedBefore + lockAmount;

        LockedBalance memory oldLockedBalance;

        (oldLockedBalance.amount, oldLockedBalance.end) = (lockedBalance.amount, lockedBalance.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        lockedBalance.amount += int128(int256(lockAmount));
        if (unlockTime != 0) {
            lockedBalance.end = unlockTime;
        }
        _lockedBalances[tokenId] = lockedBalance;

        // Possibilities:
        // Both oldLockedBalance.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(tokenId, oldLockedBalance, lockedBalance);

        address from = msg.sender;
        if (lockAmount > 0) {
            _lockToken.safeTransferFrom(from, address(this), lockAmount);
        }

        emit Deposit(from, tokenId, lockAmount, lockedBalance.end, depositType, block.timestamp);
        emit Supply(totalLockedBefore, _totalLocked);
    }



    /* ========== INTERNAL FUNCTIONS ========== */
    // Record global and per-user data to checkpoint
    function _checkpoint(
        uint tokenId,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint epoch = _epoch;

        if (tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                u_old.slope = oldLocked.amount / iMAX_TIME;
                u_old.bias = u_old.slope * int128(int256(oldLocked.end - block.timestamp));
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                u_new.slope = newLocked.amount / iMAX_TIME;
                u_new.bias = u_new.slope * int128(int256(newLocked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // oldLocked.end can be in the past and in the future
            // newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = _slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = _slopeChanges[newLocked.end];
                }
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (epoch > 0) {
            last_point = _pointHistory[epoch];
        }
        uint last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number(approximately, for *At methods) and save them
        // Deep copy (share same reference with last_point will cause dirty memory)
        Point memory initial_last_point = Point({bias: last_point.bias, slope: last_point.slope, ts: last_point.ts, blk: last_point.blk});

        uint block_slope = 0; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint t_i = (last_checkpoint / WEEK) * WEEK;
            for (uint i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = _slopeChanges[t_i];
                }
                last_point.bias -= last_point.slope * int128(int256(t_i - last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk = initial_last_point.blk + (block_slope * (t_i - initial_last_point.ts)) / MULTIPLIER;
                epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else {
                    _pointHistory[epoch] = last_point;
                }
            }
        }

        _epoch = epoch;
        // Now _pointHistory is filled until t=now

        if (tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        _pointHistory[epoch] = last_point;

        if (tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [newLocked.end]
            // and add old_user_slope to [oldLocked.end]
            if (oldLocked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (newLocked.end == oldLocked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                _slopeChanges[oldLocked.end] = old_dslope;
            }

            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    _slopeChanges[newLocked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }
            // Now handle user history
            uint nft_epoch = _nftPointEpoch[tokenId] + 1;

            _nftPointEpoch[tokenId] = nft_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            _nftPointHistory[tokenId][nft_epoch] = u_new;
        }
    }

    function checkpoint() external whenNotPaused onlyRole(POINT_CHECKER_ROLE){
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }

    /// @notice Withdraw all tokens for `tokenId`
    /// @dev Only possible if the lock has expired
    function withdraw(uint tokenId) external whenNotPaused nonReentrant oncePerBlock(msg.sender){
        require(ownerOf(tokenId) == msg.sender, "ERC721: transfer caller is not owner");

        LockedBalance memory locked = _lockedBalances[tokenId];
        require(block.timestamp >= locked.end, "Lock not expired");
        uint value = uint(int256(locked.amount));

        _lockedBalances[tokenId] = LockedBalance(0,0);
        uint supplyBefore = _totalLocked;
        _totalLocked = supplyBefore - value;

        // old_locked can have either expired <= timestamp or zero end
        // locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(tokenId, locked, LockedBalance(0,0));

        _lockToken.safeTransfer(msg.sender, value);
        // Burn the NFT
        _burn(msg.sender, tokenId);
        // save latest owner
        _latestOwner[tokenId] = msg.sender;
        emit Withdraw(msg.sender, tokenId, value, block.timestamp);
        emit Supply(supplyBefore, _totalLocked);
    }

    function configSvgBuilderClient(ISvgBuilderClient svgBuilderClient) external onlyRole(DEFAULT_ADMIN_ROLE){
        _svgBuilderClient = svgBuilderClient;
    }

    function configTransfer(bool canTransfer) external onlyRole(DEFAULT_ADMIN_ROLE){
        bool old = _canTransfer;
        require(old != canTransfer, "Same state");
        _canTransfer = canTransfer;
        emit CanTransfer(old, _canTransfer);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /* ========== VIEW FUNCTIONS ========== */
    function nftPointEpoch(uint tokenId) external view returns (uint){
        return _nftPointEpoch[tokenId];
    }

    function currentEpoch() external view returns (uint){
        return _epoch;
    }

    function nftPointHistory(uint tokenId, uint loc) external view returns (Point memory){
        return _nftPointHistory[tokenId][loc];
    }

    function pointHistory(uint loc) external view returns (Point memory){
        return _pointHistory[loc];
    }

    function token() external view returns (address){
        return address(_lockToken);
    }

    // return NFT owner or latest owner
    function nftOwner(uint tokenId) external view returns (address){
        address latestOwner = _latestOwner[tokenId];
        if(latestOwner == address(0)){
            latestOwner = ownerOf(tokenId);
        }
        return latestOwner;
    }

    function getLockedDetail(uint tokenId) external view returns(LockedBalance memory){
        return _lockedBalances[tokenId];
    }

    function userLocked(address account) external view returns(uint256){
        uint256[] memory tokenIds = tokensOfOwner(account);
        uint256 userLockedAmt = 0;
        for(uint i=0; i<tokenIds.length; i++){
            LockedBalance memory lockedBalance = _lockedBalances[tokenIds[i]];
            userLockedAmt += uint256(int256(lockedBalance.amount));
        }
        return userLockedAmt;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        LockedBalance memory lockedBalance = _lockedBalances[tokenId];
        string memory output = _svgBuilderClient.buildSvg(tokenId, uint256(uint128(lockedBalance.amount)), lockedBalance.end);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', tokenId.toString(), '", "description": "Apollox DAO VE", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    // voting power of NFT
    function powerOfNft(uint tokenId) external view returns (int256){
        return powerOfNftAt(tokenId, block.timestamp);
    }

    function powerOfNftAt(uint tokenId, uint timestamp) public view returns (int256){
        uint thisEpoch = _nftPointEpoch[tokenId];
        if (thisEpoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = _nftPointHistory[tokenId][thisEpoch];
            require(timestamp >= lastPoint.ts, "Invalid timestamp");

            lastPoint.bias -= lastPoint.slope * int128(int256(timestamp) - int256(lastPoint.ts));
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return int256(lastPoint.bias);
        }
    }

    function powerOfNftAtBlock(uint tokenId, uint blockNo) public view returns (int256){
        require(blockNo <= block.number, "Invalid block");
        // Binary search for nearest point
        uint _min = 0;
        uint _max = _nftPointEpoch[tokenId];
        if(_max == 0){
            return 0;
        }
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (_nftPointHistory[tokenId][_mid].blk <= blockNo) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        Point memory upoint = _nftPointHistory[tokenId][_min];
        //calculate block time
        uint target_epoch = findBlockEpoch(blockNo, _epoch);
        Point memory point_0 = _pointHistory[target_epoch];
        uint d_block = 0;
        uint d_t = 0;
        if (target_epoch < _epoch) {
            Point memory point_1 = _pointHistory[target_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (blockNo - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int256(block_time - upoint.ts));
        if (upoint.bias >= 0) {
            return int256(upoint.bias);
        } else {
            return 0;
        }
    }

    // sum voting power of account
    function powerOfAccount(address account) external view returns (int256){
        uint256[] memory tokenIds = tokensOfOwner(account);
        int256 power = 0;
        for(uint i=0; i<tokenIds.length; i++){
            power = power + powerOfNftAt(tokenIds[i], block.timestamp);
        }
        return power;
    }

    function powerOfAccountAt(address account, uint timestamp) external view returns (int256){
        uint256[] memory tokenIds = tokensOfOwner(account);
        int256 power = 0;
        for(uint i=0; i<tokenIds.length; i++){
            power = power + powerOfNftAt(tokenIds[i], timestamp);
        }
        return power;
    }

    function powerOfAccountAtBlock(address account, uint blockNo) external view returns (int256){
        require(blockNo <= block.number, "Invalid block");
        uint256[] memory tokenIds = tokensOfOwner(account);
        int256 power = 0;
        for(uint i=0; i<tokenIds.length; i++){
            power = power + powerOfNftAtBlock(tokenIds[i], blockNo);
        }
        return power;
    }

    function totalPower() external view returns (int256){
        return totalPowerAt(block.timestamp);
    }

    function totalPowerAt(uint timestamp) public view returns (int256){
        uint thisEpoch = _epoch;
        Point memory lastPoint = _pointHistory[thisEpoch];
        require(timestamp >= lastPoint.ts, "Invalid timestamp");
        // calculate power
        uint t_i = (lastPoint.ts / WEEK) * WEEK;
        for (uint i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > timestamp) {
                t_i = timestamp;
            } else {
                d_slope = _slopeChanges[t_i];
            }
            lastPoint.bias -= lastPoint.slope * int128(int256(t_i - lastPoint.ts));
            if (t_i == timestamp) {
                break;
            }
            lastPoint.slope += d_slope;
            lastPoint.ts = t_i;
        }

        if (lastPoint.bias < 0) {
            lastPoint.bias = 0;
        }
        return int256(lastPoint.bias);
    }

    function totalPowerAtBlock(uint blockNo) external view returns (int256){
        require(blockNo <= block.number, "Invalid block");
        // find point
        uint targetEpoch = findBlockEpoch(blockNo, _epoch);
        Point memory targetPoint = _pointHistory[targetEpoch];
        uint dt = 0;
        // calculate time gap
        if (targetEpoch < _epoch) {
            Point memory nextPoint = _pointHistory[targetEpoch + 1];
            if (targetPoint.blk != nextPoint.blk) {
                dt = ((blockNo - targetPoint.blk) * (nextPoint.ts - targetPoint.ts)) / (nextPoint.blk - targetPoint.blk);
            }
        } else {
            if (targetPoint.blk != block.number) {
                dt = ((blockNo - targetPoint.blk) * (block.timestamp - targetPoint.ts)) / (block.number - targetPoint.blk);
            }
        }
        uint targetTime = targetPoint.ts + dt;
        // calculate power
        uint t_i = (targetPoint.ts / WEEK) * WEEK;
        for (uint i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > targetTime) {
                t_i = targetTime;
            } else {
                d_slope = _slopeChanges[t_i];
            }
            targetPoint.bias -= targetPoint.slope * int128(int256(t_i - targetPoint.ts));
            if (t_i == targetTime) {
                break;
            }
            targetPoint.slope += d_slope;
            targetPoint.ts = t_i;
        }

        if (targetPoint.bias < 0) {
            targetPoint.bias = 0;
        }
        return int256(targetPoint.bias);
    }

    // Binary search to estimate timestamp for block number
    function findBlockEpoch(uint blockNo, uint maxEpoch) internal view returns (uint) {
        // Binary search
        uint min = 0;
        uint max = maxEpoch;
        for (uint i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (min >= max) {
                break;
            }
            uint mid = (min + max + 1) / 2;
            if (_pointHistory[mid].blk <= blockNo) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }
}
