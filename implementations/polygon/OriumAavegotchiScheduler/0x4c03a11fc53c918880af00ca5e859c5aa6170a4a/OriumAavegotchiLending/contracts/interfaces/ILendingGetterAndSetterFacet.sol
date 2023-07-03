// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AavegotchiInfo, GotchiLending } from "../libraries/LibAavegotchiStorage.sol";

struct LendingOperatorInputs {
    uint32 _tokenId;
    bool _isLendingOperator;
}

interface ILendingGetterAndSetterFacet {

    function batchSetLendingOperator(address _lendingOperator, LendingOperatorInputs[] calldata _inputs) external;

    function isLendingOperator(address _lender, address _lendingOperator, uint32 _tokenId) external view returns (bool);

    // @notice Get an aavegotchi lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the lending like timeCreated etc
    // @return aavegotchiInfo_ A struct containing details about the aavegotchi
    function getGotchiLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_, AavegotchiInfo memory aavegotchiInfo_);

    // @notice Get an ERC721 lending details through an identifier
    // @dev Will throw if the lending does not exist
    // @param _listingId The identifier of the lending to query
    // @return listing_ A struct containing certain details about the ERC721 lending like timeCreated etc
    function getLendingListingInfo(uint32 _listingId) external view returns (GotchiLending memory listing_);

    // @notice Get an aavegotchi lending details through an NFT
    // @dev Will throw if the lending does not exist
    // @param _erc721TokenId The identifier of the NFT associated with the lending
    // @return listing_ A struct containing certain details about the lending associated with an NFT of contract identifier `_erc721TokenId`
    function getGotchiLendingFromToken(uint32 _erc721TokenId) external view returns (GotchiLending memory listing_);

    function getGotchiLendingIdByToken(uint32 _erc721TokenId) external view returns (uint32);

    function isAavegotchiLent(uint32 _erc721TokenId) external view returns (bool);

    function isAavegotchiListed(uint32 _erc721TokenId) external view returns (bool);

}
