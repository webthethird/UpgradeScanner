// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * BasisFee uses a constant denominator of 1e11, in the fee percentage formula:
 * fee % = numerator / denominator * 100
 * So, if you want to set 2% fee, you should be supplying (2/100)*1e11 = 2*1e9 as the numerator.
 * BasisFee allows you to have a precision of 9 digits while setting the fee %,
 * i.e., you can set 0.123456789% as a fee rate and be sure that the fee calculations will work.
 * This should suffice for most of the use-cases.
 */
library BasisFee {
    error NumeratorMoreThanBasis();
    error CantSetMoreThan30PercentFee();

    uint256 internal constant _BASIS = 1e11;

    function _checkValid(uint256 self) internal pure {
        if (self > _BASIS) {
            revert NumeratorMoreThanBasis();
        }
        if (self > (_BASIS / 100) * 30) {
            revert CantSetMoreThan30PercentFee();
        }
    }

    function _apply(uint256 self, uint256 amount) internal pure returns (uint256) {
        return (amount * self) / _BASIS;
    }
}
