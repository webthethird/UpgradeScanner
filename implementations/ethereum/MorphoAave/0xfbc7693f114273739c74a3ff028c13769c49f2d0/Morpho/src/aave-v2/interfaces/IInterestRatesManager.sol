// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0;

interface IInterestRatesManager {
    function updateIndexes(address _marketAddress) external;
}
