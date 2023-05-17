//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IChildToken is IERC20Upgradeable {
    function withdraw(uint256 amount) external payable;
}
