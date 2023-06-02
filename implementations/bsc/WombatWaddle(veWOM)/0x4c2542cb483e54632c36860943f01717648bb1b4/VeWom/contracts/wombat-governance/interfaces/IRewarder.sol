// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IRewarder {
    function onReward(address user, uint256 newLpAmount) external returns (uint256);

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20Metadata);
}
