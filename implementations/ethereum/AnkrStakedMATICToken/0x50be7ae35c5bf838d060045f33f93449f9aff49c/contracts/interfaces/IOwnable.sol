// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

}
