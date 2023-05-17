//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IChildChainManager {
    function childToRootToken(address rootToken) external returns (address);
}
