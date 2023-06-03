// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// Inheritance
import "./interfaces/ITimelockVault.sol";

/// @title Single asset timelock Vault
/// @author Router Protocol
/// @notice The longer user stake the more APR they receive.

contract TimelockVault is
    Initializable,
    UUPSUpgradeable,
    ITimelockVault,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /* ========== STATE VARIABLES ========== */

    struct UserVault {
        uint256 amount;
        uint256 reward;
        uint256 userRewardPerTokenPaid;
        uint256 lockingPeriod;
        uint256 endtime;
        uint256 weight;
    }

    IERC20Upgradeable public rewardsToken;
    IERC20Upgradeable public stakingToken;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public maxUserStakeLimit;
    uint256 public maxTotalStakedLimit;

    uint256 public lastUpdated;
    uint256 public penaltyFactor;
    uint256 public totalPenalty;

    mapping(address => UserVault[]) public userVaults;
    mapping(address => uint256) public userStaked;
    mapping(uint256 => uint256) public timeToWeight;

    uint256 private _totalSupply;
    uint256 private _totalWeightSupply;

    /* ========== Upgrade Section ========== */

    /**
        @notice Initializes TimelockVault
        @param _stakingToken Staking token address
        @param _rewardsToken Reward Token address
        @param _rewardRate Reward per epoch
     */
    function initialize(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Constructor Fx
        rewardsToken = IERC20Upgradeable(_rewardsToken);
        stakingToken = IERC20Upgradeable(_stakingToken);
        rewardRate = _rewardRate;
        lastUpdated = block.timestamp;
        penaltyFactor = 20 * 1e6;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /* ========== VIEWS ========== */

    /// @notice Returns the total staked amount
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the total weighted supply of staked amount
    function totalWeightSupply() external view returns (uint256) {
        return _totalWeightSupply;
    }

    /// @notice Returns the array of user positions in a vault
    /// @param account address
    function getUserVaultInfo(address account) external view returns (UserVault[] memory) {
        return userVaults[account];
    }

    /// @notice Returns the current reward paid for a staked token
    function rewardPerToken() public view override returns (uint256) {
        if (_totalWeightSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdated) * rewardRate * 1e18) / _totalWeightSupply);
    }

    /// @notice Returns the current unclaimed rewards of a user in provided position
    /// @param account address
    /// @param index of a user's position
    function earned(address account, uint256 index) public view override returns (uint256) {
        uint256 userVaultLength = userVaults[account].length;
        if (userVaultLength == index) {
            return 0;
        }
        UserVault memory userVault_ = userVaults[account][index];
        return
            ((userVault_.weight * (rewardPerToken() - userVault_.userRewardPerTokenPaid)) / 1e18) + userVault_.reward;
    }

    /// @notice Returns the cumulative rewards of a user in a vault
    /// @param account address
    function calculateAllRewards(address account) external view returns (uint256 rewards) {
        UserVault[] storage userVault_ = userVaults[account];
        uint256 len = userVault_.length;
        for (uint256 i = 0; i < len; i++) {
            rewards += earned(account, i);
        }
    }

    /// @notice Returns the weight of user staked amount depends on the time lock frame.
    /// @param lockPeriod epoch of number of days
    function calculateWeightFactor(uint256 lockPeriod) public view override returns (uint256) {
        return timeToWeight[lockPeriod];
    }

    /// @notice Returns all the global states at once
    function getGlobalStates()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (rewardRate, rewardPerTokenStored, maxUserStakeLimit, maxTotalStakedLimit, penaltyFactor);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Stake amount for a provided locktime
    /// @param amount amount caller wants to stake
    /// @param lockPeriod epoch of number of days
    function stake(uint256 amount, uint256 lockPeriod) external override nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(timeToWeight[lockPeriod] != 0, "lockPeriod must be whitelisted");
        require(_totalSupply + amount < maxTotalStakedLimit, "max User Stake Limit reached");
        require(userStaked[msg.sender] + amount < maxUserStakeLimit, "max User Stake Limit reached");
        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, userVaults[msg.sender].length);
        uint256 stakeFactor = (amount * calculateWeightFactor(lockPeriod)) / (1e18);
        UserVault memory userVault_ = UserVault({
            amount: amount,
            lockingPeriod: lockPeriod,
            endtime: lockPeriod + block.timestamp,
            reward: _earned,
            userRewardPerTokenPaid: _userRewardPerTokenPaid,
            weight: stakeFactor
        });
        userVaults[msg.sender].push(userVault_);
        _totalSupply += amount;
        userStaked[msg.sender] += amount;
        _totalWeightSupply += stakeFactor;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, lockPeriod);
    }

    /// @notice Withdraw staked token after tenure ends
    /// @param index of a caller's position
    function withdraw(uint256 index) public override nonReentrant {
        UserVault storage _userVault = userVaults[msg.sender][index];
        uint256 amount = _userVault.amount;
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= _userVault.endtime, "Cannot withdraw before lock time");

        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, index);
        _userVault.reward = _earned;
        _userVault.userRewardPerTokenPaid = _userRewardPerTokenPaid;

        _totalSupply -= amount;
        _totalWeightSupply -= _userVault.weight;

        _userVault.weight = 0;
        _userVault.amount = 0;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, false);
    }

    /// @notice Withdraw staked token before tenure ends but need to pay penalty fee
    /// @param amount amount caller wants to withdraw
    /// @param index of a caller's position
    function withdrawEmergency(uint256 amount, uint256 index) public override nonReentrant {
        UserVault storage _userVault = userVaults[msg.sender][index];
        require(amount > 0 && amount <= _userVault.amount, "not valid amount");
        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, index);
        _userVault.reward = _earned;
        _userVault.userRewardPerTokenPaid = _userRewardPerTokenPaid;

        uint256 _amount = (amount * (1e8 - penaltyFactor)) / 1e8;
        totalPenalty += (amount - _amount);
        _totalSupply -= _amount;
        uint256 weightFactor = _userVault.weight / _userVault.amount;
        _userVault.weight = _userVault.weight - (amount * weightFactor);
        _totalWeightSupply = _totalWeightSupply - (amount * weightFactor);
        _userVault.amount -= amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount, true);
    }

    /// @notice Claim the accumulated rewards
    /// @param index of a caller's position
    function claimReward(uint256 index) public override nonReentrant {
        UserVault storage _userVault = userVaults[msg.sender][index];
        uint256 reward = _getReward(index, _userVault);
        if (reward > 0) {
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Claim the cumulative rewards of a caller in a vault
    function claimAllRewards() public override nonReentrant {
        UserVault[] storage userVault_ = userVaults[msg.sender];

        uint256 len = userVault_.length;
        uint256 rewards;
        for (uint256 i = 0; i < len; i++) {
            rewards += _getReward(i, userVault_[i]);
        }
        if (rewards > 0) {
            rewardsToken.safeTransfer(msg.sender, rewards);
            emit RewardPaid(msg.sender, rewards);
        }
    }

    /// @notice Withdraw the principle & Claim the accumulated rewards
    /// @param index of a caller's position
    function exit(uint256 index) external {
        withdraw(index);
        claimReward(index);
    }

    function _getReward(uint256 index, UserVault storage _userVault) internal returns (uint256) {
        (uint256 _earned, uint256 _userRewardPerTokenPaid) = _updateReward(msg.sender, index);
        _userVault.userRewardPerTokenPaid = _userRewardPerTokenPaid;
        uint256 rewards = _earned;
        _userVault.reward = 0;
        return rewards;
    }

    function _updateReward(address account, uint256 i)
        internal
        returns (uint256 _earned, uint256 _userRewardPerTokenPaid)
    {
        rewardPerTokenStored = rewardPerToken();
        lastUpdated = block.timestamp;

        _earned = earned(account, i);
        _userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Admin set penalty factor and function scale it up by 10^6
    /// @param factor in percentage 0 < factor < 100 | 10 -> 10%
    function setPenaltyFactor(uint256 factor) external onlyOwner {
        require(factor > 0 && factor < 100, "wrong penalty factor");
        penaltyFactor = factor * 1e6;
    }

    /// @notice Admin set pre-fixed time to weight factor
    /// @param lockperiod epoch of number of days
    /// @param weight should be expended to decimal 18
    function setTimeToWeight(uint256 lockperiod, uint256 weight) external onlyOwner {
        timeToWeight[lockperiod] = weight;
    }

    /// @notice Admin set multiple pre-fixed time to weight factor
    /// @param lockperiod array of epoch of number of days
    /// @param weight should be expended to decimal 18 in array
    function setMultiTimeToWeight(uint256[] memory lockperiod, uint256[] memory weight) external onlyOwner {
        require(lockperiod.length == weight.length, "length mismatch");
        for (uint256 i = 0; i < lockperiod.length; i++) {
            timeToWeight[lockperiod[i]] = weight[i];
        }
    }

    /// @notice Admin sets per user limit for staked amount
    /// @param _maxUserStakeLimit  amount  in wei
    function setMaxUserStakeLimit(uint256 _maxUserStakeLimit) external onlyOwner {
        maxUserStakeLimit = _maxUserStakeLimit;
    }

    /// @notice Admin sets max limit for total staked amount
    /// @param _maxTotalStakedLimit  amount  in wei
    function setMaxTotalStakedLimit(uint256 _maxTotalStakedLimit) external onlyOwner {
        maxTotalStakedLimit = _maxTotalStakedLimit;
    }

    /// @notice Admin set rewards per epoch to be given
    /// @param _rewardRate reward amount per epoch in wei
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
        emit RewardRateUpdated(_rewardRate);
    }

    /// @notice Admin withdraw penalty collected by the time
    function withdrawPenalty() external onlyOwner {
        uint256 _totalPenalty;
        _totalPenalty = totalPenalty;
        totalPenalty = 0;
        _totalSupply -= _totalPenalty;
        stakingToken.safeTransfer(owner(), _totalPenalty);
    }

    function rescueFunds(address tokenAddress, address receiver) external onlyOwner {
        require(tokenAddress != address(stakingToken), "TimelockVault: rescue of staking token not allowed");
        IERC20Upgradeable(tokenAddress).transfer(receiver, IERC20Upgradeable(tokenAddress).balanceOf(address(this)));
    }

    /* ========== EVENTS ========== */

    /// @notice MaxTotalStakedLimitUpdated event is emitted when admin sets max limit for total staked amount
    /// @param _maxTotalStakedLimit amount in wei
    event MaxTotalStakedLimitUpdated(uint256 _maxTotalStakedLimit);

    /// @notice MaxUserStakeLimitUpdated event is emitted when admin sets per user limit for staked amount
    /// @param _maxUserStakeLimit amount in wei
    event MaxUserStakeLimitUpdated(uint256 _maxUserStakeLimit);

    /// @notice TimeToWeightUpdated event is emitted when admin set weight for a particular lock period
    /// @param lockperiod amount in wei
    /// @param weight expended to decimal 18
    event TimeToWeightUpdated(uint256 lockperiod, uint256 weight);

    /// @notice RewardRateUpdated event is emitted when admin set reward rate
    /// @param _rewardRate amount in wei
    event RewardRateUpdated(uint256 _rewardRate);

    /// @notice Staked event is emitted when user stake amount for specific lock period
    /// @param user address
    /// @param amount in wei
    /// @param lockPeriod in epoch
    event Staked(address indexed user, uint256 amount, uint256 lockPeriod);

    /// @notice Withdrawn event is emitted when user withdraw amount
    /// @param user address
    /// @param amount in wei
    /// @param emergency true if user withdraw before lock period otherwise false
    event Withdrawn(address indexed user, uint256 amount, bool emergency);

    /// @notice RewardPaid event is emitted when user claims reward amount
    /// @param user address
    /// @param reward amount in wei
    event RewardPaid(address indexed user, uint256 reward);
}
