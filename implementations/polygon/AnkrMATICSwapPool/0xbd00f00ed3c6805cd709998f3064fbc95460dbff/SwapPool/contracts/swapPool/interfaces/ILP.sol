// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILP is IERC20Upgradeable {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}