// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth

pragma solidity ^0.8.0;

contract ToucanCarbonOffsetsStorage {
    uint256 public projectVintageTokenId;
    address public contractRegistry;

    mapping(address => uint256) public minterToId;
    mapping(address => uint256) public retiredAmount;
}
