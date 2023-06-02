// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

struct TokenIdsWithKinship {
    uint256 tokenId;
    uint256 kinship;
    uint256 lastInteracted;
}

interface IAavegotchiDiamond {

    event PetOperatorApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // @notice Enable or disable approval for a third party("operator") to help pet LibMeta.msgSender()'s gotchis
    // @dev Emits the PetOperatorApprovalForAll event
    // @param _operator Address to disable/enable as a pet operator
    // @param _approved True if operator is approved,False if approval is revoked
    function setPetOperatorForAll(address _operator, bool _approved) external;

    // @notice Query the tokenId,kinship and lastInteracted values of a set of NFTs belonging to an address
    // @dev Will throw if `_count` is greater than the number of NFTs owned by `_owner`
    // @param _owner Address to query
    // @param _count Number of NFTs to check
    // @param _skip Number of NFTs to skip while querying
    // @param all If true, query all NFTs owned by `_owner`; if false, query `_count` NFTs owned by `_owner`
    // @return tokenIdsWithKinship_ An array of structs where each struct contains the `tokenId`,`kinship`and `lastInteracted` of each NFT
    function tokenIdsWithKinship(
        address _owner, uint256 _count, uint256 _skip, bool all
    ) external view returns (TokenIdsWithKinship[] memory tokenIdsWithKinship_);

    // @notice Check if an address `_operator` is an authorized pet operator for another address `_owner`
    // @param _owner address of the lender of the NFTs
    // @param _operator address that acts pets the gotchis on behalf of the owner
    // @return approved_ true if `operator` is an approved pet operator, False if otherwise
    function isPetOperatorForAll(address _owner, address _operator) external view returns (bool approved_);

    // @notice Allow the owner of an NFT to interact with them.thereby increasing their kinship(petting)
    // @dev only valid for claimed aavegotchis
    // @dev Kinship will only increase if the lastInteracted minus the current time is greater than or equal to 12 hours
    // @param _tokenIds An array containing the token identifiers of the claimed aavegotchis that are to be interacted with
    function interact(uint256[] calldata _tokenIds) external;

}
