// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../libraries/SignedSafeMath.sol';

contract TestSignedSafeMath {
    using SignedSafeMath for int256;
    int256 public constant WAD = 10**18;

    function add(int256 a, int256 b) external pure returns (int256) {
        return a + b;
    }

    function sub(int256 a, int256 b) external pure returns (int256) {
        return a - b;
    }

    function mul(int256 a, int256 b) external pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) external pure returns (int256) {
        return a / b;
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(int256 x, int256 y) external pure returns (int256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(int256 x, int256 y) external pure returns (int256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    // Babylonian Method (typecast as int) as used also from Uniswap v2
    // https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
    function sqrt(int256 y) external pure returns (int256 z) {
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
