// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../pool/Pool.sol';

contract TestPoolV2 is Pool {
    uint256 dummy;

    function misc() external {
        ++dummy;
    }
}
