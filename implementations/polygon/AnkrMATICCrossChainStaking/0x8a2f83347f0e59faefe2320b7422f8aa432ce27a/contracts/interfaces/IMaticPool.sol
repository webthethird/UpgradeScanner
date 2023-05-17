//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IMaticPool {
    /**
     * Events
     */

    event ReceivedRewards(address indexed sender, uint256 rewards);

    event Staked(
        address indexed staker,
        uint256 amount,
        bool indexed isRebasing
    );

    event Unstaked(
        address indexed claimer,
        uint256 amount,
        uint256 receiveAmount,
        bool indexed isRebasing
    );

    event CommissionWithdrawn(uint256 amount);

    event RewardsDistributed(address[] claimers, uint256[] amounts);

    event ManualDistributeExpected(
        address indexed claimer,
        uint256 amount,
        uint256 indexed id
    );

    event GasLimitChanged(uint256 indexed gasLimit);

    event ToChainChanged(uint256 indexed toChain);

    event CommissionsChanged(
        uint256 indexed stakeCommission,
        uint256 indexed unstakeCommission
    );

    event MinimumStakeChanged(uint256 indexed minimumStake);

    event BondTokenChanged(address indexed bondToken);

    event CertTokenChanged(address indexed certToken);

    event OperatorChanged(address indexed operator);

    event PendingGapReseted();

    /**
     * Methods
     */

    function stake(bool isRebasing) external payable;

    function unstake(uint256 amount, bool isRebasing) external payable;
}
