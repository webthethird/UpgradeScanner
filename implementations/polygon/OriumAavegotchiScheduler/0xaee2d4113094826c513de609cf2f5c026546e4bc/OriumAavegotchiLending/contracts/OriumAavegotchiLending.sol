// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IERC721 } from "./interfaces/IERC721.sol";
import { IGotchiLendingFacet, AddGotchiListing } from "./interfaces/IGotchiLendingFacet.sol";
import { ILendingGetterAndSetterFacet } from "./interfaces/ILendingGetterAndSetterFacet.sol";
import { IAavegotchiFacet } from "./interfaces/IAavegotchiFacet.sol";
import { AavegotchiInfo, GotchiLending } from "./libraries/LibAavegotchiStorage.sol";

uint8 constant STATUS_AAVEGOTCHI = 3;

contract OriumAavegotchiLending is OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;

    uint32 public constant _30_DAYS = 30*24*60*60;

    uint8 public _fee;
    address[] public _tokens;
    address public _aavegotchiDiamondAddress;
    address public _gelatoAddress;
    uint256 public _maxActions;
    EnumerableSet.UintSet private _tokenIds;
    mapping(uint256 => AddGotchiListing) public _listingsParameters;

    event BatchSchedule(
        address indexed owner, uint32[] tokenIds, uint96 initialCost, uint32 period,
        uint8 lenderSplit, uint8 borrowerSplit, uint32 indexed whitelistId
    );
    event BatchUnschedule(address indexed owner, uint32[] tokenIds);

    modifier onlyGelato() {
        require(msg.sender == _gelatoAddress, "Only Gelato can invoke this function");
        _;
    }

    // @notice Proxy initializer function. Should be only callable once
    // @param aavegotchiDiamondContract The aavegotchi diamond contract
    // @param gelatoOps address for gelato executors smart contracts
    function initialize(
        address aavegotchiDiamondContract, address gelatoAddress, uint8 fee, uint256 maxActions, address[] memory tokens
    ) public initializer {
        _fee = fee;
        _maxActions = maxActions;
        _tokens = tokens;
        _gelatoAddress = gelatoAddress;
        _aavegotchiDiamondAddress = aavegotchiDiamondContract;
        __Ownable_init_unchained();
    }

    // == Owner Only Functions =========================================================================================

    // @notice Allow owner to update third-party share-profit fees
    // @param fees New fee schedule
    function updateFeeSchedule(uint8 fee) external onlyOwner {
        _fee = fee;
    }

    // @notice Allow owner to update Gelato address
    // @param gelato New Gelato address
    function updateGelatoAddress(address gelato) external onlyOwner {
        _gelatoAddress = gelato;
    }

    // @notice Allow owner to update Aavegotchi Diamond address
    // @param aavegotchiDiamondAddress New Aavegotchi Diamond address
    function updateAavegotchiDiamondAddress(address aavegotchiDiamondAddress) external onlyOwner {
        _aavegotchiDiamondAddress = aavegotchiDiamondAddress;
    }

    // @notice Allow owner to update token address list
    // @param tokens New token address list
    function updateTokenAddressList(address[] memory tokens) external onlyOwner {
        _tokens = tokens;
    }

    // @notice Allow owner to update max number of actions processed at a time
    // @param max_actions Number of actions
    function updateMaxNumberOfActions(uint256 max_actions) external onlyOwner {
        _maxActions = max_actions;
    }

    function withdrawTokens(address to) external onlyOwner {
        for (uint256 i ; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(to, balance);
            }
        }
    }

    // == Gelato Only Functions ========================================================================================

    // @notice Batch create lendings based on their scheduled parameters
    // @param tokenIds List of tokenIds to be listed
    function createLendings(uint32[] calldata tokenIds) private {
        AddGotchiListing[] memory listings = new AddGotchiListing[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            listings[i] = _listingsParameters[tokenIds[i]];
        }
        IGotchiLendingFacet(_aavegotchiDiamondAddress).batchAddGotchiListing(listings);
    }

    // @notice Remove lendings from the list. Only called when Lending Operator approval is revoked
    // @param tokenIds List of tokenIds to be removed
    function removeLendings(uint32[] calldata tokenIds) private {
        ILendingGetterAndSetterFacet lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress);
        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            address owner = IERC721(_aavegotchiDiamondAddress).ownerOf(tokenId);
            bool isLendingOperator = lendingGetterAndSetterFacet.isLendingOperator(owner, address(this), tokenId);
            if (isLendingOperator == false) {
                EnumerableSet.remove(_tokenIds, tokenId);
                delete _listingsParameters[tokenId];
            }
        }
    }

    // @notice Claims, list and remove Nft lendings
    // @param listNfts Ids of the tokens to be listed
    // @param claimAndListNfts Ids of the Nfts to be claimed and relisted
    // @param removeNfts Ids of the Nfts to be removed
    function manageLendings(
        uint32[] calldata listNfts, uint32[] calldata claimAndListNfts, uint32[] calldata removeNfts
    ) external onlyGelato {
        createLendings(listNfts);
        IGotchiLendingFacet(_aavegotchiDiamondAddress).batchClaimAndEndAndRelistGotchiLending(claimAndListNfts);
        removeLendings(removeNfts);
    }

    // == Public Functions =============================================================================================

    // @notice Get list of token addresses
    // @return List of token addresses
    function getTokens() external view returns (address[] memory) {
        return _tokens;
    }

    // @notice Retrieve all tokenIds of Aavegotchis scheduled
    // @return The list of tokenIds
    function getAllTokenIds() external view returns (uint256[] memory) {
        return EnumerableSet.values(_tokenIds);
    }

    // @notice Retrieves all listing parameters of an NFT
    // @return Returns all listing parameters
    function getListingByTokenId(uint256 tokenId) external view returns (AddGotchiListing memory) {
        return _listingsParameters[tokenId];
    }

    function getListingsByTokenIds(uint256[] memory tokenIds) external view returns (AddGotchiListing[] memory listings_) {
        listings_ = new AddGotchiListing[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            listings_[i] = _listingsParameters[tokenId];
        }
    }

    // @notice Retrieves all GotchiListing scheduled in the contract
    // @return listings_ Returns all listing schedules stored in the contract
    function getListings() external view returns (AddGotchiListing[] memory listings_) {
        uint256[] memory tokenIds = EnumerableSet.values(_tokenIds);
        listings_ = new AddGotchiListing[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = EnumerableSet.at(_tokenIds, i);
            listings_[i] = _listingsParameters[tokenId];
        }
    }
    
    function getAavegotchiState(uint32[] calldata tokenIds) public view returns (bool[] memory isAavegotchisLent, bool[] memory isAavegotchisListed){
        isAavegotchisLent = new bool[](tokenIds.length);
        isAavegotchisListed = new bool[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            isAavegotchisLent[i] = ILendingGetterAndSetterFacet(
                _aavegotchiDiamondAddress
            ).isAavegotchiLent(tokenId);
            isAavegotchisListed[i] = ILendingGetterAndSetterFacet(
                _aavegotchiDiamondAddress
            ).isAavegotchiListed(tokenId);
        }
    }

    // @notice Includes tokenIds on scheduling list, so that Gelato manages its listings
    // @param tokenIds tokenIds of the NFTs
    // @param initialCost Upfront GHST charge to borrowers
    // @param period Duration of the lending in seconds
    // @param revenueSplit Split of tokens. Should be revenueSplit[0] + revenueSplit[1] + revenueSplit[2] + fee = 100
    function batchSchedule(
        uint32[] memory tokenIds, uint96 initialCost, uint32 period, uint8 lenderSplit, uint8 borrowerSplit,
        uint32 whitelistId
    ) external {
        require(period > 0 && period <= _30_DAYS, "Period needs to be greater than 0, and lower or equal to 30 days");
        require(_fee + lenderSplit + borrowerSplit == 100, "Invalid split distribution");
        uint8[3] memory revenueSplit = [ lenderSplit, borrowerSplit, _fee ];
        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            AavegotchiInfo memory info = IAavegotchiFacet(_aavegotchiDiamondAddress).getAavegotchi(tokenId);
            require(info.owner == msg.sender, "Sender must be the owner of the NFT");
            require(info.locked == false, "NFT cannot be locked");
            require(info.status == STATUS_AAVEGOTCHI, "NFT is a portal");
            bool isLendingOperator = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress).isLendingOperator(msg.sender, address(this), tokenId);
            require(isLendingOperator, "Contract is not approved to manage this NFT");
            EnumerableSet.add(_tokenIds, tokenId);
            _listingsParameters[tokenId] = AddGotchiListing(
                tokenId, initialCost, period, revenueSplit, msg.sender, address(this), whitelistId, _tokens
            );
        }
        emit BatchSchedule(msg.sender, tokenIds, initialCost, period, lenderSplit, borrowerSplit, whitelistId);
    }

    // @notice Remove tokenIds from scheduling list
    // @param tokenIds The ids of the Aavegotchis ti be removed
    function batchUnschedule(uint32[] memory tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint32 tokenId = tokenIds[i];
            address originalOwner = getAavegotchiOriginalOwner(tokenId);
            require(originalOwner == msg.sender, "Sender must be the owner of the NFT");
            EnumerableSet.remove(_tokenIds, tokenId);
            delete _listingsParameters[tokenId];
            cancelListingIfPossible(tokenId);
        }
        emit BatchUnschedule(msg.sender, tokenIds);
    }

    function getAavegotchiOriginalOwner(uint32 tokenId) public view returns (address) {
        ILendingGetterAndSetterFacet lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress);
        if (lendingGetterAndSetterFacet.isAavegotchiLent(tokenId) == false) {
            return IERC721(_aavegotchiDiamondAddress).ownerOf(tokenId);
        } else {
            GotchiLending memory lending = lendingGetterAndSetterFacet.getGotchiLendingFromToken(tokenId);
            return lending.originalOwner;
        }
    }

    function cancelListingIfPossible(uint32 tokenId) private {
        ILendingGetterAndSetterFacet lendingGetterAndSetterFacet = ILendingGetterAndSetterFacet(_aavegotchiDiamondAddress);
        if (lendingGetterAndSetterFacet.isAavegotchiListed(tokenId) == true && lendingGetterAndSetterFacet.isAavegotchiLent(tokenId) == false) {
             IGotchiLendingFacet(_aavegotchiDiamondAddress).cancelGotchiLendingByToken(tokenId);
        }
    }

}
