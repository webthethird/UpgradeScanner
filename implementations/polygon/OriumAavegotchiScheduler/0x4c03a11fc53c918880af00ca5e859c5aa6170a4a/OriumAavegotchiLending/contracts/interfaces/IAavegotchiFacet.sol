// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import { AavegotchiInfo } from "../libraries/LibAavegotchiStorage.sol";

interface IAavegotchiFacet {

    // @notice Query all details relating to an NFT
    // @param _tokenId the identifier of the NFT to query
    // @return aavegotchiInfo_ a struct containing all details about
    function getAavegotchi(uint256 _tokenId) external view returns (AavegotchiInfo memory aavegotchiInfo_);

}
