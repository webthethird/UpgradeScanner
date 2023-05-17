// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ITokenHub {
    function getMiniRelayFee() external view returns (uint256);

    function getBoundContract(string memory bep2Symbol) external view returns (address);

    function getBoundBep2Symbol(address contractAddr) external view returns (string memory);

    function transferOut(
        address contractAddr,
        address recipient,
        uint256 amount,
        uint64 expireTime
    ) external payable returns (bool);
}
