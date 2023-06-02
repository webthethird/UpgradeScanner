// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

// @param _erc721TokenId The identifier of the NFT to lend
// @param _initialCost The lending fee of the aavegotchi in $GHST
// @param _period The lending period of the aavegotchi, unit: second
// @param _revenueSplit The revenue split of the lending, 3 values, sum of the should be 100
// @param _originalOwner The account for original owner, can be set to another address if the owner wishes to have profit split there.
// @param _thirdParty The 3rd account for receive revenue split, can be address(0)
// @param _whitelistId The identifier of whitelist for agree lending, if 0, allow everyone
struct AddGotchiListing {
    uint32 tokenId;
    uint96 initialCost;
    uint32 period;
    uint8[3] revenueSplit;
    address originalOwner;
    address thirdParty;
    uint32 whitelistId;
    address[] revenueTokens;
}

interface IGotchiLendingFacet {

    // @notice Allow aavegotchi lenders (msg sender) or their lending operators to add request for lending
    // @dev If the lending request exist, cancel it and replaces it with the new one
    // @dev If the lending is active, unable to cancel
    function batchAddGotchiListing(AddGotchiListing[] memory listings) external;

    // @notice Claim and end and relist gotchi lendings in batch by token ID
    function batchClaimAndEndAndRelistGotchiLending(uint32[] calldata _tokenIds) external;

    // @notice Allow a borrower to agree an lending for the NFT
    // @dev Will throw if the NFT has been lent or if the lending has been canceled already
    // @param _listingId The identifier of the lending to agree
    function agreeGotchiLending(
        uint32 _listingId, uint32 _erc721TokenId, uint96 _initialCost, uint32 _period, uint8[3] calldata _revenueSplit
    ) external;

    // @notice Allow an aavegotchi lender to cancel his NFT lending by providing the NFT contract address and identifier
    // @param _erc721TokenId The identifier of the NFT to be delisted from lending
    function cancelGotchiLendingByToken(uint32 _erc721TokenId) external;

}
