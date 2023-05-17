// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library ExchangeRate {
    struct Data {
        uint256 totalWei;
        uint256 poolTokenSupply;
    }
    enum UpdateOp {
        Add,
        Subtract
    }

    function _init(Data storage self) internal {
        self.totalWei = 0;
        self.poolTokenSupply = 0;
    }

    function _update(
        Data storage self,
        Data memory change,
        UpdateOp op
    ) internal {
        if (op == UpdateOp.Add) {
            self.totalWei += change.totalWei;
            self.poolTokenSupply += change.poolTokenSupply;
        } else {
            self.totalWei -= change.totalWei;
            self.poolTokenSupply -= change.poolTokenSupply;
        }
    }

    function _calcPoolTokensForDeposit(Data storage self, uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        if (self.totalWei == 0 || self.poolTokenSupply == 0) {
            return weiAmount;
        }
        return (weiAmount * self.poolTokenSupply) / self.totalWei;
    }

    function _calcWeiWithdrawAmount(Data storage self, uint256 poolTokens)
        internal
        view
        returns (uint256)
    {
        uint256 numerator = poolTokens * self.totalWei;
        uint256 denominator = self.poolTokenSupply;

        if (numerator < denominator || denominator == 0) {
            return 0;
        }
        // TODO: later also take remainder into consideration
        return numerator / denominator;
    }
}
