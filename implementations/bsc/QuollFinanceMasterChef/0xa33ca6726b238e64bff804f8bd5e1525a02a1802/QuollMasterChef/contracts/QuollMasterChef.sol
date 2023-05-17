// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/IQuollMasterChef.sol";

contract QuollMasterChef is IQuollMasterChef, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of QUOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accQuoPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accQuoPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. QUO to distribute per block.
        uint256 lastRewardBlock; // Last block number that QUOs distribution occurs.
        uint256 accQuoPerShare; // Accumulated QUOs per share, times 1e12. See below.
        IRewarder rewarder;
    }

    //quo
    IERC20 public quo;
    // The block number when QUO mining starts.
    uint256 public startBlock;
    // Block number when bonus QUO period ends.
    uint256 public bonusEndBlock;
    // QUO tokens created per block.
    uint256 public rewardPerBlock;
    // Bonus muliplier for early quo makers.
    uint256 public constant BONUS_MULTIPLIER = 2;

    // Info of each pool.
    PoolInfo[] public override poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public override userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(
        IERC20 _quo,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(address(quo) == address(0), "!init");

        require(address(_quo) != address(0), "invalid _quo!");
        require(
            _bonusEndBlock >= _startBlock,
            "invalid _startBlock or _bonusEndBlock"
        );

        quo = _quo;
        rewardPerBlock = _rewardPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder,
        bool _withUpdate
    ) external onlyOwner {
        require(address(_lpToken) != address(0), "invalid _lpToken!");
        _checkDuplicate(_lpToken);
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accQuoPerShare: 0,
                rewarder: _rewarder
            })
        );
    }

    function _checkDuplicate(IERC20 _lpToken) internal view {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            require(_lpToken != poolInfo[i].lpToken, "existing _lpToken!");
        }
    }

    // Update the given pool's QUO allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool _updateRewarder
    ) external onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        if (_updateRewarder) {
            poolInfo[_pid].rewarder = _rewarder;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    // View function to see pending QUOs on frontend.
    function pendingQuo(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accQuoPerShare = pool.accQuoPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 quoReward = multiplier
                .mul(rewardPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accQuoPerShare = accQuoPerShare.add(
                quoReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accQuoPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 quoReward = multiplier
            .mul(rewardPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accQuoPerShare = pool.accQuoPerShare.add(
            quoReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for QUO allocation.
    function deposit(uint256 _pid, uint256 _amount) external override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = 0;
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accQuoPerShare).div(1e12).sub(
                user.rewardDebt
            );
            safeRewardTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accQuoPerShare).div(1e12);

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(
                _pid,
                msg.sender,
                msg.sender,
                pending,
                user.amount
            );
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accQuoPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeRewardTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accQuoPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(
                _pid,
                msg.sender,
                msg.sender,
                pending,
                user.amount
            );
        }

        emit RewardPaid(msg.sender, _pid, pending);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claim(uint256 _pid, address _account) external override {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accQuoPerShare).div(1e12).sub(
            user.rewardDebt
        );
        safeRewardTransfer(_account, pending);
        user.rewardDebt = user.amount.mul(pool.accQuoPerShare).div(1e12);

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(_pid, _account, _account, pending, user.amount);
        }

        emit RewardPaid(_account, _pid, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;

        //extra rewards
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onReward(_pid, msg.sender, msg.sender, 0, 0);
        }
    }

    // Safe quo transfer function, just in case if rounding error causes pool to not have enough QUOs.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 quoBal = quo.balanceOf(address(this));
        if (_amount > quoBal) {
            quo.safeTransfer(_to, quoBal);
        } else {
            quo.safeTransfer(_to, _amount);
        }
    }
}
