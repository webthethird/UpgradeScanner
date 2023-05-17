// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IFeeVault {
    function claimStkBNB(address recipient, uint256 amount) external;
}
