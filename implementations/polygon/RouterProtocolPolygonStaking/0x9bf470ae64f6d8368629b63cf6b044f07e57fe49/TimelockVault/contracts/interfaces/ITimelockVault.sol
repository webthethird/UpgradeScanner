// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface ITimelockVault {
    // Views

    function rewardPerToken() external view returns (uint256);

    function earned(address account, uint256 index) external view returns (uint256);

    function calculateWeightFactor(uint256 lockPeriod) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // Mutative

    function stake(uint256 amount, uint256 lockPeriod) external;

    function withdraw(uint256 index) external;

    function withdrawEmergency(uint256 amount, uint256 index) external;

    function claimReward(uint256 index) external;

    function claimAllRewards() external;

    // function getRewardRestricted(address account) external;

    // function exit() external;
}
