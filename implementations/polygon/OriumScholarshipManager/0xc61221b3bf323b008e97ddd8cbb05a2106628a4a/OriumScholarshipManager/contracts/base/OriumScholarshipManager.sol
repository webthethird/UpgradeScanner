// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IOriumFactory } from "./interface/IOriumFactory.sol";
import { INftVaultPlatform, NftState, IOriumNftVault } from "./interface/IOriumNftVault.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
    function createScholarshipProgram(uint256 _platform, uint256[][] memory _sharesConfig)
        external
    {
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
            require(_isValidShares(_sharesConfig[i]), "OriumScholarshipManager: Invalid shares");

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

    function _isValidShares(uint256[] memory _shares) internal pure returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            sum += _shares[i];
        }
        return sum == 100 ether;
    }

    /**
     * @notice Create Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _programIds The program ids
     * @param data bytes to create auxilary rental structs
     */
    function createRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        uint256[] memory _programIds,
        bytes[] memory data
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length &&
                _tokenIds.length == data.length &&
                _tokenIds.length == _programIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _createRentalOffer(_tokenIds[i], _nftAddresses[i], _programIds[i], data[i]);
        }
    }

    function _createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _programId,
        bytes memory data
    )
        internal
        onlyTrustedNft(_nftAddress)
        onlyGuildOwner(_programId)
        onlyNotPausedNft(_nftAddress, _tokenId)
    {
        address _nftVault = _getVerifiedVault(_nftAddress, _tokenId, _programId);
        INftVaultPlatform(_nftVault).createRentalOffer(_tokenId, _nftAddress, data);
        if (factory.supportsRentalOffer(_nftAddress)) {
            emit RentalOfferCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
        } else {
            emit RentalCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
        }
    }

    /**
     * @notice Cancel Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _programIds The program ids
     */
    function cancelRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        uint256[] memory _programIds
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length && _tokenIds.length == _programIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _cancelRentalOffer(_tokenIds[i], _nftAddresses[i], _programIds[i]);
        }
    }

    function _cancelRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _programId
    ) internal onlyTrustedNft(_nftAddress) onlyGuildOwner(_programId) {
        address _nftVault = _getVerifiedVault(_nftAddress, _tokenId, _programId);
        INftVaultPlatform(_nftVault).cancelRentalOffer(_tokenId, _nftAddress);
        emit RentalOfferCancelled(_nftAddress, _tokenId, _nftVault, _programId);
    }

    /**
     * @notice End Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _nftVaults The nft vaults
     * @param _programIds The program ids
     */
    function endRentals(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        address[] memory _nftVaults,
        uint256[] memory _programIds
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length &&
                _tokenIds.length == _nftVaults.length &&
                _tokenIds.length == _programIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _endRental(_tokenIds[i], _nftAddresses[i], _nftVaults[i], _programIds[i]);
        }
    }

    function _endRental(
        uint256 _tokenId,
        address _nftAddress,
        address _nftVault,
        uint256 _programId
    ) internal onlyTrustedNft(_nftAddress) onlyGuildOwner(_programId) {
        require(factory.isNftVault(_nftVault), "OriumScholarshipManager:: Invalid vault");
        require(
            INftVaultPlatform(_nftVault).platform() == programToPlatform[_programId],
            "OriumScholarshipManager:: Vault and scholarship program platform are not the same"
        );
        require(
            IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId) == _programId,
            "OriumScholarshipManager:: NFT is not delegated to this program"
        );

        INftVaultPlatform(_nftVault).endRental(_nftAddress, uint32(_tokenId));
        emit RentalEnded(_nftAddress, _tokenId, _nftVault, _programId);
    }

    /**
     * @notice End Rentals and Relist
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     * @param _nftVaults The nft vaults
     * @param _programIds The program ids
     */
    function endRentalsAndRelist(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        address[] memory _nftVaults,
        uint256[] memory _programIds,
        bytes[] memory _datas
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length &&
                _tokenIds.length == _nftVaults.length &&
                _tokenIds.length == _programIds.length &&
                _tokenIds.length == _datas.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _endRentalAndRelist(
                _nftAddresses[i],
                _tokenIds[i],
                _nftVaults[i],
                _programIds[i],
                _datas[i]
            );
        }
    }

    function _endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        address _nftVault,
        uint256 _programId,
        bytes memory data
    ) internal onlyTrustedNft(_nftAddress) onlyGuildOwner(_programId) {
        require(factory.isNftVault(_nftVault), "OriumScholarshipManager:: Invalid vault");
        require(
            INftVaultPlatform(_nftVault).platform() == programToPlatform[_programId],
            "OriumScholarshipManager:: Vault and scholarship program platform are not the same"
        );
        require(
            IOriumNftVault(_nftVault).programOf(_nftAddress, _tokenId) == _programId,
            "OriumScholarshipManager:: NFT is not delegated to this program"
        );

        INftVaultPlatform(_nftVault).endRentalAndRelist(_nftAddress, uint32(_tokenId), data);
        emit RentalEnded(_nftAddress, _tokenId, _nftVault, _programId);

        if (factory.supportsRentalOffer(_nftAddress)) {
            emit RentalOfferCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
        } else {
            emit RentalCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
        }
    }

    // Nft's Managing
    function _getVerifiedVault(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId
    ) internal view returns (address _nftVault) {
        _nftVault = _delegatedTokenToIdToVault[_nftAddress][_tokenId];
        require(
            _nftVault != address(0),
            "OriumScholarshipManager:: NFT is not delegated to any program"
        );
        require(
            INftVaultPlatform(_nftVault).platform() == programToPlatform[_programId],
            "OriumScholarshipManager:: Vault and scholarship program platform are not the same"
        );
        require(
            _delegatedTokenToIdToProgramId[_nftAddress][_tokenId] == _programId,
            "OriumScholarshipManager:: NFT is not delegated to this program"
        );
    }

    //Getters
    /**
     * @notice Get scholarships programs of an platform
     * @param _platform The platform id
     * @return ids of the programs
     */
    function programsOfPlatform(uint256 _platform) external view returns (uint256[] memory) {
        return platformToScholarshipPrograms[_platform];
    }

    /**
     * @notice Verify if a program is valid
     * @param _programId The program id
     * @return true if the program is valid
     */
    function isProgram(uint256 _programId) external view returns (bool) {
        return isValidScholarshipProgram[_programId];
    }

    /**
     * @notice Get scholarship programs of an guild owner
     * @param _guildOwner The guild owner address
     * @return ids of the programs
     */
    function programsOfOwner(address _guildOwner) external view returns (uint256[] memory) {
        return userToScholarshipPrograms[_guildOwner];
    }

    /**
     * @notice Get shares of a program by event
     * @param _programId The program id
     * @param _eventId The event id
     * @return shares of the program for an event
     */
    function sharesOf(uint256 _programId, uint256 _eventId)
        external
        view
        returns (uint256[] memory)
    {
        return programToEventIdToShares[_programId][_eventId];
    }

    /**
     * @notice Get a guild owner of a program
     * @param _programId The program id
     * @return guild owner address
     */
    function ownerOf(uint256 _programId) external view returns (address) {
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
     * @notice Get a vault of an nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     * @return _nftVault address
     */
    function vaultOfDelegatedToken(address _nftAddress, uint256 _tokenId)
        public
        view
        onlyTrustedNft(_nftAddress)
        returns (address _nftVault)
    {
        _nftVault = _delegatedTokenToIdToVault[_nftAddress][_tokenId];
    }

    /**
     * @notice Get all scholarships programs
     * @return ids of the programs
     */
    function getAllScholarshipPrograms() external view returns (uint256[] memory) {
        return programs;
    }

    /**
     * @notice Get all tokens ids delegated to a scholarship program
     * @param _nftAddress The nft address
     * @param _programId The program id
     * @return ids of the tokens
     */
    function delegatedTokensOf(address _nftAddress, uint256 _programId)
        external
        view
        returns (uint256[] memory)
    {
        return _programToTokenToIds[_programId][_nftAddress];
    }

    /**
     * @notice Get a delegated scholarship program of an nft
     * @param _nftAddress The nft address
     * @param _tokenId The token id
     */
    function programOf(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (uint256 _programId)
    {
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
}
