// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISvgBuilderClient {

    function buildSvg(uint256 tokenId, uint256 lockAmount, uint256 unlockTime) external pure returns (string memory);

}
