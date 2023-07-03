// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IERC721 {

    // @notice Find the owner of an NFT
    // @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
    // @param _tokenId The identifier for an NFT
    // @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

}