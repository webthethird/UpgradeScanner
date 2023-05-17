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

    /// @notice Query all details relating to an NFT
    /// @param _tokenId the identifier of the NFT to query
    /// @return aavegotchiInfo_ a struct containing all details about
    function getAavegotchi(uint256 _tokenId) external view returns (AavegotchiInfo memory aavegotchiInfo_);

    /// @notice Get all the Ids of NFTs owned by an address
    /// @param _owner The address to check for the NFTs
    /// @return tokenIds_ an array of unsigned integers,each representing the tokenId of each NFT
    function tokenIdsOfOwner(address _owner) external view returns (uint32[] memory tokenIds_);

    function getLentTokenIdsOfLender(address _lender) external view returns (uint32[] memory tokenIds_);

}

uint256 constant NUMERIC_TRAITS_NUM = 6;
uint256 constant EQUIPPED_WEARABLE_SLOTS = 16;

struct AavegotchiInfo {
    uint256 tokenId;
    string name;
    address owner;
    uint256 randomNumber;
    uint256 status;
    int16[NUMERIC_TRAITS_NUM] numericTraits;
    int16[NUMERIC_TRAITS_NUM] modifiedNumericTraits;
    uint16[EQUIPPED_WEARABLE_SLOTS] equippedWearables;
    address collateral;
    address escrow;
    uint256 stakedAmount;
    uint256 minimumStake;
    uint256 kinship; //The kinship value of this Aavegotchi. Default is 50.
    uint256 lastInteracted;
    uint256 experience; //How much XP this Aavegotchi has accrued. Begins at 0.
    uint256 toNextLevel;
    uint256 usedSkillPoints; //number of skill points used
    uint256 level; //the current aavegotchi level
    uint256 hauntId;
    uint256 baseRarityScore;
    uint256 modifiedRarityScore;
    bool locked;
    ItemTypeIO[] items;
}

struct ItemTypeIO {
    uint256 balance;
    uint256 itemId;
    ItemType itemType;
}

struct Dimensions {
    uint8 x;
    uint8 y;
    uint8 width;
    uint8 height;
}

struct ItemType {
    string name; //The name of the item
    string description;
    string author;
    // treated as int8s array
    // [Experience, Rarity Score, Kinship, Eye Color, Eye Shape, Brain Size, Spookiness, Aggressiveness, Energy]
    int8[NUMERIC_TRAITS_NUM] traitModifiers; //[WEARABLE ONLY] How much the wearable modifies each trait. Should not be more than +-5 total
    //[WEARABLE ONLY] The slots that this wearable can be added to.
    bool[EQUIPPED_WEARABLE_SLOTS] slotPositions;
    // this is an array of uint indexes into the collateralTypes array
    uint8[] allowedCollaterals; //[WEARABLE ONLY] The collaterals this wearable can be equipped to. An empty array is "any"
    // SVG x,y,width,height
    Dimensions dimensions;
    uint256 ghstPrice; //How much GHST this item costs
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    uint32 svgId; //The svgId of the item
    uint8 rarityScoreModifier; //Number from 1-50.
    // Each bit is a slot position. 1 is true, 0 is false
    bool canPurchaseWithGhst;
    uint16 minLevel; //The minimum Aavegotchi level required to use this item. Default is 1.
    bool canBeTransferred;
    uint8 category; // 0 is wearable, 1 is badge, 2 is consumable
    int16 kinshipBonus; //[CONSUMABLE ONLY] How much this consumable boosts (or reduces) kinship score
    uint32 experienceBonus; //[CONSUMABLE ONLY]
}
