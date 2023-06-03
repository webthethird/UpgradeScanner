// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

library LibAavegotchiUtils {

    function isAavegotchiPetAble(uint256 lastInteracted) internal view returns (bool isPetAble_) {
        isPetAble_ = block.timestamp > lastInteracted + 12 hours;
    }

}
