// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IOriumFactory } from "./interface/IOriumFactory.sol";
import { INftVaultPlatform, NftState, IOriumNftVault } from "./interface/IOriumNftVault.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IOriumSplitterFactory } from "./interface/IOriumSplitterFactory.sol";
import { IOriumSplitter } from "./interface/IOriumSplitter.sol";
import { LibScholarshipManager } from "./libraries/LibScholarshipManager.sol";

/**
 * @title Orium Scholarships Manager
 * @dev This contract is used to manage scholarships for Orium NFT Vault
 * @author Orium Network Team - security@orium.network
 */
contract OriumScholarshipManager is Initializable, OwnableUpgradeable {
    address public operator;
    IOriumFactory public factory;

    // Platform control variables
    mapping(uint256 => uint256[]) internal platformToScholarshipPrograms;

    // Programs control variables
    uint256[] public programs;

    // Ownership
    mapping(uint256 => address) internal programToGuildOwner;
    mapping(address => uint256[]) internal userToScholarshipPrograms;

    // Helpers
    mapping(uint256 => mapping(uint256 => uint256[])) internal programToEventIdToShares;
    mapping(uint256 => uint256) internal programToPlatform;
    mapping(uint256 => bool) public isValidScholarshipProgram;

    //Vault auxiliar variables
    mapping(uint256 => mapping(address => uint256[])) internal _programToTokenToIds;
    mapping(address => mapping(uint256 => uint256)) internal _delegatedTokenToIdToIndex;

    mapping(address => mapping(uint256 => uint256)) internal _delegatedTokenToIdToProgramId;
    mapping(address => mapping(uint256 => address)) internal _delegatedTokenToIdToVault;
    mapping(address => mapping(uint256 => bool)) internal _pausedNfts;

    // Events
    event ScholarshipProgramCreated(
        uint256 indexed programId,
        uint256 platform,
        EventShares[] shares,
        address indexed owner
    );

    event PausedNft(
        address indexed owner,
        address vault,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event UnPausedNft(
        address indexed owner,
        address vault,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event DelegatedScholarshipProgram(
        address owner,
        address vaultAddress,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 indexed programId,
        uint256 maxAllowedPeriod
    );
    event UnDelegatedScholarshipProgram(
        address owner,
        address vaultAddress,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    struct EventShares {
        uint256 eventId;
        uint256[] shares;
    }

    event RentalOfferCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId,
        bytes data
    );

    event RentalCreated(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId,
        bytes data
    );

    event RentalOfferCancelled(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId
    );
    event RentalEnded(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed vaultAddress,
        uint256 programId
    );

    event TransferredGHST(address indexed vaultAddress, uint256 amount);

    modifier onlyTrustedNft(address _nftAddress) {
        require(factory.isTrustedNft(_nftAddress), "OriumScholarshipManager:: NFT is not trusted");
        _;
    }

    modifier onlyNotPausedNft(address _nftAddress, uint256 _tokenId) {
        require(
            _pausedNfts[_nftAddress][_tokenId] == false,
            "OriumScholarshipManager:: NFT is paused"
        );
        _;
    }

    modifier onlyGuildOwner(uint256 _programId) {
        require(
            msg.sender == programToGuildOwner[_programId],
            "OriumScholarshipManager:: Only guild owner can call this function"
        );
        _;
    }

    modifier onlyNftVault() {
        require(
            factory.isNftVault(msg.sender),
            "OriumFactory: Only OriumNftVault can call this function"
        );
        _;
    }

    function onlyNftVaultOrSplitter() internal view {
        address _splitterFactory = factory.getOriumSplitterFactory();
        require(
            factory.isNftVault(msg.sender) ||
                IOriumSplitterFactory(_splitterFactory).isValidSplitterAddress(msg.sender),
            "OriumScholarshipManager: Only OriumNftVault or OriumSplitter can call this function"
        );
    }

    /**
     * @dev Initialize the contract
     * @param _operator The operator address
     * @param _factory Orium Factory address
     */
    function initialize(address _operator, address _factory) public initializer {
        require(_operator != address(0), "OriumScholarshipManager: Invalid operator");
        require(_factory != address(0), "OriumScholarshipManager: Invalid factory");

        operator = _operator;
        factory = IOriumFactory(_factory);

        programs.push(0); // 0 is not a valid program id

        __Ownable_init();
        transferOwnership(_operator);
    }

    /**
     * @notice Create a scholarship program
     * @dev each index of shares config will be used as event id
     * @param _platform The platform id
     * @param _sharesConfig The shares for each event
     */
    function createScholarshipProgram(
        uint256 _platform,
        uint256[][] memory _sharesConfig
    ) external {
        require(
            factory.isSupportedPlatform(_platform),
            "OriumScholarshipManager:: Platform not supported"
        );
        uint256 _programId = _addScholarshipProgram(_platform);
        EventShares[] memory _eventShares = new EventShares[](_sharesConfig.length);

        uint256[] memory _sharesLength = factory.getPlatformSharesLength(_platform);

        require(
            _sharesConfig.length == _sharesLength.length,
            "OriumScholarshipManager: Invalid shares config"
        );

        for (uint256 i = 0; i < _sharesConfig.length; i++) {
            require(
                _sharesConfig[i].length == _sharesLength[i],
                "OriumScholarshipManager: Invalid shares length"
            );
            require(
                LibScholarshipManager.isValidShares(_sharesConfig[i]),
                "OriumScholarshipManager: Invalid shares"
            );

            uint256 eventId = i + 1;
            programToEventIdToShares[_programId][eventId] = _sharesConfig[i];
            _eventShares[i] = EventShares(eventId, _sharesConfig[i]);
            programToPlatform[_programId] = _platform;
            programToGuildOwner[_programId] = msg.sender;
        }

        emit ScholarshipProgramCreated(_programId, _platform, _eventShares, msg.sender);
    }

    function _addScholarshipProgram(uint256 _platform) internal returns (uint256 _programId) {
        _programId = programs.length;

        programs.push(_programId);

        platformToScholarshipPrograms[_platform].push(_programId);
        userToScholarshipPrograms[msg.sender].push(_programId);

        isValidScholarshipProgram[_programId] = true;
    }

    /**
     * @notice Create Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param data bytes to create auxilary rental structs
     */
    function createRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        bytes[] memory data
    ) external {
        LibScholarshipManager.createRentalOffers(
            _tokenIds,
            _nftAddresses,
            data,
            address(factory),
            address(this)
        );
    }

    /**
     * @notice Cancel Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     */
    function cancelRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses
    ) external {
        LibScholarshipManager.cancelRentalOffers(
            _tokenIds,
            _nftAddresses,
            address(factory),
            address(this)
        );
    }

    /**
     * @notice End Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     */
    function endRentals(uint256[] memory _tokenIds, address[] memory _nftAddresses) external {
        LibScholarshipManager.endRentals(_tokenIds, _nftAddresses, address(factory), address(this));
    }

    /**
     * @notice End Rentals and Relist
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     */
    function endRentalsAndRelist(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        bytes[] memory _datas
    ) external {
        LibScholarshipManager.endRentalsAndRelist(
            _tokenIds,
            _nftAddresses,
            _datas,
            address(factory),
            address(this)
        );
    }

    function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds
    ) external {
        LibScholarshipManager.claimTokensOfRentals(
            _nftAddresses,
            _tokenIds,
            address(factory),
            address(this)
        );
    }

    function withdrawEarnings(uint256 _platformId, bytes memory _data) external {
        LibScholarshipManager.withdrawEarnings(_platformId, _data, address(factory));
    }

    //Getters
    /**
     * @notice Verify if a program is valid
     * @param _programId The program id
     * @return true if the program is valid
     */
    function isProgram(uint256 _programId) external view returns (bool) {
        return isValidScholarshipProgram[_programId];
    }

    /**
     * @notice Get shares of a program by event
     * @param _programId The program id
     * @param _eventId The event id
     * @return shares of the program for an event
     */
    function sharesOf(
        uint256 _programId,
        uint256 _eventId
    ) external view returns (uint256[] memory) {
        return programToEventIdToShares[_programId][_eventId];
    }

    /**
     * @notice Get a guild owner of a program
     * @param _programId The program id
     * @return guild owner address
     */
    function ownerOf(uint256 _programId) public view returns (address) {
        return programToGuildOwner[_programId];
    }

    /**
     * @notice Get a platform of a program
     * @param _programId The program id
     * @return platform id
     */
    function platformOf(uint256 _programId) external view returns (uint256) {
        return programToPlatform[_programId];
    }

    /**
     * @notice Get a delegated scholarship program of an nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function programOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (uint256 _programId) {
        _programId = _delegatedTokenToIdToProgramId[_nftAddress][_tokenId];
    }

    /**
     * @notice Check if an nft is paused
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     * @return true if the nft is paused
     */
    function isNftPaused(address _nftAddress, uint256 _tokenId) external view returns (bool) {
        return _pausedNfts[_nftAddress][_tokenId];
    }

    function vaultOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (address _vaultAddress) {
        _vaultAddress = _delegatedTokenToIdToVault[_nftAddress][_tokenId];
    }

    //Notifiers
    function _addDelegatedToken(
        uint256 _programId,
        address _nftAddress,
        uint256 _tokenId,
        address _vaultAddress
    ) internal {
        if (_programToTokenToIds[_programId][_nftAddress].length == 0) {
            _programToTokenToIds[_programId][_nftAddress].push(0); // 0 is not a valid token index
        }
        _programToTokenToIds[_programId][_nftAddress].push(_tokenId);
        _delegatedTokenToIdToIndex[_nftAddress][_tokenId] =
            _programToTokenToIds[_programId][_nftAddress].length -
            1;
        _delegatedTokenToIdToProgramId[_nftAddress][_tokenId] = _programId;
        _delegatedTokenToIdToVault[_nftAddress][_tokenId] = _vaultAddress;
    }

    function _removeDelegatedToken(address _nftAddress, uint256 _tokenId) internal {
        uint256 _programId = _delegatedTokenToIdToProgramId[_nftAddress][_tokenId];
        uint256[] storage tokenIds = _programToTokenToIds[_programId][_nftAddress];

        uint256 index = _delegatedTokenToIdToIndex[_nftAddress][_tokenId];
        require(index != 0, "OriumScholarshipManager:: Token is not delegated to any program");

        uint256 lastTokenId = tokenIds[tokenIds.length - 1];

        if (lastTokenId != _tokenId) {
            tokenIds[index] = lastTokenId;
            _delegatedTokenToIdToIndex[_nftAddress][lastTokenId] = index;
        }

        tokenIds.pop();
        delete _delegatedTokenToIdToIndex[_nftAddress][_tokenId];
        delete _delegatedTokenToIdToProgramId[_nftAddress][_tokenId];
        delete _delegatedTokenToIdToVault[_nftAddress][_tokenId];
    }

    //Notifiers
    /**
     * @notice Notify when a new program is delegated to an nft in a vault
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function onUnDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyNftVault {
        emit UnDelegatedScholarshipProgram(_owner, msg.sender, _nftAddress, _tokenId);
        _removeDelegatedToken(_nftAddress, _tokenId);
    }

    /**
     * @notice Notify when a scholarship program is un delegated to an nft in a vault
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     * @param _programId The program id
     * @param _maxAllowedPeriod The max allowed period
     */
    function onDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedPeriod
    ) external onlyNftVault {
        emit DelegatedScholarshipProgram(
            _owner,
            msg.sender,
            _nftAddress,
            _tokenId,
            _programId,
            _maxAllowedPeriod
        );
        _addDelegatedToken(_programId, _nftAddress, _tokenId, msg.sender);
    }

    /**
     * @notice Notify when a nft is paused
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function onPausedNft(
        address _owner,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyNftVault {
        _pausedNfts[_nftAddress][_tokenId] = true;
        emit PausedNft(_owner, msg.sender, _nftAddress, _tokenId);
    }

    /**
     * @notice Notify when a nft is unpaused
     * @dev This function is called only by an OriumNftVault
     * @param _owner The owner of the nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function onUnPausedNft(
        address _owner,
        address _nftAddress,
        uint256 _tokenId
    ) external onlyNftVault {
        delete _pausedNfts[_nftAddress][_tokenId];
        emit UnPausedNft(_owner, msg.sender, _nftAddress, _tokenId);
    }

    function onTransferredGHST(address _vault, uint256 _amount) external onlyNftVault {
        emit TransferredGHST(_vault, _amount);
    }

    function onRentalEnded(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external {
        onlyNftVaultOrSplitter();
        emit RentalEnded(nftAddress, tokenId, vaultAddress, programId);
    }

    function onRentalOfferCancelled(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external {
        onlyNftVaultOrSplitter();
        emit RentalOfferCancelled(nftAddress, tokenId, vaultAddress, programId);
    }
}
