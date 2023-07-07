// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IOwnable {
  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);
}
