// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../asset/DynamicAsset.sol';

contract MockStakedEth is DynamicAsset {
    uint256 relativePrice = 1e18; // in WAD

    constructor(
        address underlyingToken_,
        string memory name_,
        string memory symbol_
    ) DynamicAsset(underlyingToken_, name_, symbol_) {}

    function setRelativePrice(uint256 relativePrice_) external {
        relativePrice = relativePrice_;
    }

    function getRelativePrice() external view override returns (uint256) {
        return relativePrice;
    }
}
