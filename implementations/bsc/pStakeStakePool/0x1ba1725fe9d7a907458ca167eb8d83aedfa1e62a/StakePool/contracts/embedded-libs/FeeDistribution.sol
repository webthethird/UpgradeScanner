// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BasisFee.sol";

library FeeDistribution {
    using BasisFee for uint256;

    struct Data {
        uint256 reward;
        uint256 deposit;
        uint256 withdraw;
    }

    function _checkValid(Data calldata self) internal pure {
        self.reward._checkValid();
        self.deposit._checkValid();
        self.withdraw._checkValid();
    }

    function _set(Data storage self, Data calldata obj) internal {
        self.reward = obj.reward;
        self.deposit = obj.deposit;
        self.withdraw = obj.withdraw;
    }
}
