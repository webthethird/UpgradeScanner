// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    // @dev Gets the balance of the specified address.
    // @param _owner The address to query the balance of.
    // @return An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) external view returns (uint256);

    // @dev Transfer token for a specified address
    // @param _to The address to transfer to.
    // @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) external returns (bool);

}
