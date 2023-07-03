// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../StakedAvax/StakedAvax.sol";


contract MockStakedAvax is StakedAvax {
    function getExchangeRateByUnlockTimestamp(uint unlockTimestamp) external view returns (bool, uint) {
        return _getExchangeRateByUnlockTimestamp(unlockTimestamp);
    }

    function dropExpiredExchangeRateEntries() external {
        _dropExpiredExchangeRateEntries();
    }

    function setTotalPooledAvax(uint value) external {
        totalPooledAvax = value;
    }
}
