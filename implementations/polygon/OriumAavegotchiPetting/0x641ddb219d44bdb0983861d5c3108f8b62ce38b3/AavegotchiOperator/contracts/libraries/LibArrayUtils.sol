// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

library LibArrayUtils {

    function shortenArray(uint256[] memory array, uint256 length) internal pure returns (uint256[] memory array_) {
        array_ = new uint256[](length);
        for (uint256 i; i < length; i++) {
            array_[i] = array[i];
        }
    }

    function shortenArray(address[] memory array, uint256 length) internal pure returns (address[] memory array_) {
        array_ = new address[](length);
        for (uint256 i; i < length; i++) {
            array_[i] = array[i];
        }
    }

}
