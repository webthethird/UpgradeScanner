// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

interface IERC721 {

    // @notice Find the owner of an NFT
    // @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
    // @param _tokenId The identifier for an NFT
    // @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);
    
      /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
     function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}