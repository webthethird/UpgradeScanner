// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.18;

/**
 * @title Interface for routing calls to the NFT Market to create reserve auctions.
 * @author HardlyDifficult & reggieag
 */
interface INFTMarketReserveAuction {
  function createReserveAuctionV3(
    address nftContract,
    uint256 tokenId,
    uint256 exhibitionId,
    uint256 reservePrice,
    uint256 duration
  ) external returns (uint256 auctionId);
}
