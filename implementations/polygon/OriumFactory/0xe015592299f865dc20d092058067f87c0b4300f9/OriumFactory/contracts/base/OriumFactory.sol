// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { IOriumNftVault, INftVaultPlatform } from "./interface/IOriumNftVault.sol";

/**
 * @title Factory contract for creating NFT vaults
 * @author Orium Network Team - security@orium.network
 */
contract OriumFactory is Initializable, AccessControlUpgradeable {
    //Helpers variables
    address public operator;
    address public oriumAavegotchiSplitter;
    address public scholarshipManager;
    address public oriumAavegotchiPetting;
    address public aavegotchiDiamond;

    uint256 public _oriumFee;

    // Vault  control variables
    mapping(address => bool) public isValidNftVault;
    mapping(address => address[]) internal userToNftVaults;
    address[] public allNftVaults;

    mapping(address => mapping(uint256 => address)) internal userToPlatformToNftVault;

    // Platform Templates control variables
    mapping(uint256 => address[]) internal platformToNftVaults;
    mapping(uint256 => mapping(address => uint256)) internal platformToNftType;
    mapping(address => bool) public trustedNFTs;
    mapping(uint256 => address) public platformToNftVaultImplementation;

    // Vault Helper variables
    mapping(address => address) public nftToRentalImplementation;
    mapping(uint256 => address[]) public platformTokens;

    // Structs
    struct ShareConfig {
        uint256 eventId;
        uint256[] shares;
    }

    //Events
    event NftVaultCreated(address indexed vault, uint256 platform, address indexed owner);
    event PlatformAdded(uint256 indexed platform, address indexed nftVaultImplementation);
    event PlatformRemoved(uint256 indexed platform);
    event TrustedNFTAdded(
        address indexed nft,
        uint256 indexed platform,
        address indexed rentalImplementation
    );
    event TrustedNFTRemoved(address indexed nft, uint256 indexed platform);

    mapping(address => bool) public nftToSupportRentalOffer;
    mapping(uint256 => uint256[]) public platformToSharesLength;

    /**
     * @notice initialize the factory
     * @param _operator address of the operator
     */
    function initialize(
        address _operator,
        address _aavegotchiDiadmond,
        address _oriumAavegotchiPetting
    ) external initializer {
        require(_operator != address(0), "OriumFactory:: Invalid operator");

        operator = _operator;
        aavegotchiDiamond = _aavegotchiDiadmond;
        oriumAavegotchiPetting = _oriumAavegotchiPetting;

        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _operator);
    }

    // Logic functions
    /**
     * @notice create a new NFT Vault
     * @dev create only one vault per platform per user
     * @param _platform platform of the NFT Vault
     * @return vault address of the new NFT Vault
     */
    function createNftVault(uint256 _platform) external returns (address) {
        require(
            address(platformToNftVaultImplementation[_platform]) != address(0),
            "OriumFactory:: Invalid platform"
        );
        require(
            userToPlatformToNftVault[msg.sender][_platform] == address(0),
            "OriumFactory:: OriumNftVault already exists for this platform"
        );

        address newNftVaultAddress = address(
            new BeaconProxy(
                platformToNftVaultImplementation[_platform],
                abi.encodeWithSelector(
                    IOriumNftVault.initialize.selector,
                    msg.sender,
                    address(this),
                    scholarshipManager,
                    _platform
                )
            )
        );

        _addNftVault(_platform, newNftVaultAddress);

        emit NftVaultCreated(newNftVaultAddress, _platform, msg.sender);

        return newNftVaultAddress;
    }

    function _addNftVault(uint256 _platform, address _vault) internal {
        platformToNftVaults[_platform].push(_vault);
        allNftVaults.push(_vault);
        userToPlatformToNftVault[msg.sender][_platform] = _vault;
        userToNftVaults[msg.sender].push(_vault);
        isValidNftVault[_vault] = true;
    }

    // Setters
    /**
     * @notice set orium aavegotchi splitter
     * @dev splitter is used to split earnings from aavegotchi
     * @param _oriumAavegotchiSplitter address of the splitter
     */
    function setOriumAavegotchiSplitter(address _oriumAavegotchiSplitter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        oriumAavegotchiSplitter = _oriumAavegotchiSplitter;
    }

    /**
     * @notice set orium fee
     * @dev fee is used when spliting earnings from aavegotchi
     * @param oriumFee_ fee
     */
    function setOriumFee(uint256 oriumFee_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _oriumFee = oriumFee_;
    }

    /**
     * @notice set scholarships manager
     * @dev scholarships manager is used to split earnings from aavegotchi
     * @param _scholarshipManager address of the scholarships manager
     */
    function setScholarshipManagerAddress(address _scholarshipManager)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        scholarshipManager = _scholarshipManager;
    }

    /**
     * @notice set orium aavegotchi petting
     * @dev petting is used in nft vault to pet aavegotchi
     * @param _oriumAavegotchiPetting address of the petting
     */
    function setOriumAavegotchiPettingAddress(address _oriumAavegotchiPetting)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        oriumAavegotchiPetting = _oriumAavegotchiPetting;
    }

    /**
     * @notice set aavegotchi diamond
     * @dev diamond is used in nft vault to pet aavegotchi
     * @param _aavegotchiDiamondAddress address of the diamond
     */
    function setAavegotchiDiamondAddress(address _aavegotchiDiamondAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        aavegotchiDiamond = _aavegotchiDiamondAddress;
    }

    /**
     * @notice add a new platform
     * @dev only the operator can add a new platform
     * @param _platform platform to add
     * @param _vaultImplementation implementation of the NFT Vault
     */
    function addPlatform(
        uint256 _platform,
        address _vaultImplementation,
        address[] memory _tokens,
        uint256[] memory _sharesLength
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_vaultImplementation != address(0), "OriumFactory:: Invalid vault implementation");
        require(_platform != 0, "OriumFactory:: Invalid platform");

        platformTokens[_platform] = _tokens;
        platformToNftVaultImplementation[_platform] = _vaultImplementation;

        for (uint256 i = 0; i < _sharesLength.length; i++) {
            platformToSharesLength[_platform] = _sharesLength;
        }

        emit PlatformAdded(_platform, _vaultImplementation);
    }

    /**
     * @notice remove a platform
     * @dev only the operator can remove a platform
     * @param _platform platform to remove
     */
    function removePlatform(uint256[] calldata _platform) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _platform.length; i++) {
            require(_platform[i] != 0, "OriumFactory:: Invalid platform");

            delete platformToNftVaultImplementation[_platform[i]];
            delete platformTokens[_platform[i]];
            delete platformToSharesLength[_platform[i]];
            emit PlatformRemoved(_platform[i]);
        }
    }

    /**
     * @notice add a new trusted NFT to and platform
     * @dev only the operator can add a new trusted NFT
     * @param _platform platform of the NFT
     * @param _nfts nfts to be trusted
     * @param _rentalImplementations implementation of the rental
     */
    function addTrustedNFTs(
        uint256 _platform,
        address[] memory _nfts,
        address[] memory _rentalImplementations,
        bool[] memory _supportRentalOffer
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _nfts.length; i++) {
            require(_nfts[i] != address(0), "OriumFactory:: Invalid NFT");
            require(
                _rentalImplementations[i] != address(0),
                "OriumFactory:: Invalid rental implementation"
            );

            platformToNftType[_platform][_nfts[i]] = i + 1;
            trustedNFTs[_nfts[i]] = true;
            nftToRentalImplementation[_nfts[i]] = _rentalImplementations[i];
            nftToSupportRentalOffer[_nfts[i]] = _supportRentalOffer[i];
            emit TrustedNFTAdded(_nfts[i], _platform, _rentalImplementations[i]);
        }
    }

    /**
     * @notice remove trusted NFTs
     * @dev only the operator can remove trusted NFTs
     * @param _platform platform of the NFT
     * @param _nfts nfts to be removed
     */
    function removeTrustedNFT(uint256 _platform, address[] memory _nfts)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _nfts.length; i++) {
            require(_nfts[i] != address(0), "OriumFactory:: Invalid NFT");

            platformToNftType[_platform][_nfts[i]] = 0;
            trustedNFTs[_nfts[i]] = false;
            nftToRentalImplementation[_nfts[i]] = address(0);
            nftToSupportRentalOffer[_nfts[i]] = false;
            emit TrustedNFTRemoved(_nfts[i], _platform);
        }
    }

    // Getters
    /**
     * @notice get all NFT vaults of an platform
     * @param _platform platform of the NFT vaults
     * @return all NFT vaults
     */
    function getNftVaultsOfPlatform(uint256 _platform) external view returns (address[] memory) {
        return platformToNftVaults[_platform];
    }

    /**
     * @notice get all NFT vaults of all platforms
     * @return all NFT vaults
     */
    function getAllNftVaults() external view returns (address[] memory) {
        return allNftVaults;
    }

    /**
     * @notice get all NFT vaults of an user
     * @param _user user of the NFT vaults
     * @return all NFT vaults
     */
    function nftVaultsOfOwner(address _user) external view returns (address[] memory) {
        return userToNftVaults[_user];
    }

    /**
     *@notice get all Nft vault of an user of a platform
     *@param _user user of the NFT vaults
     */
    function platformNftVaultOfOwner(address _user, uint256 _platform)
        external
        view
        returns (address)
    {
        return userToPlatformToNftVault[_user][_platform];
    }

    /**
     * @notice check if a NFT is trusted
     * @param _nft nft to check
     * @return true if the NFT is trusted
     */
    function isTrustedNft(address _nft) external view returns (bool) {
        return trustedNFTs[_nft];
    }

    /**
     * @notice verify if platform is already supported
     * @param _platform platform to check
     * @return true if platform is supported
     */
    function isSupportedPlatform(uint256 _platform) external view returns (bool) {
        return platformToNftVaultImplementation[_platform] != address(0);
    }

    /**
     * @notice verify if Nft is trusted by a platform
     * @param _nft nft to check
     * @param _platform platform to check
     * @return true if Nft is trusted by a platform
     */
    function isPlatformTrustedNft(address _nft, uint256 _platform) external view returns (bool) {
        return platformToNftType[_platform][_nft] != 0;
    }

    /**
     * @notice check if an address is a NFT vault
     * @param _vault address to check
     * @return true if the address is a NFT vault
     */
    function isNftVault(address _vault) public view returns (bool) {
        return isValidNftVault[_vault];
    }

    /**
     * @notice get nft type id of a nft and platform
     * @param _platform platform of the NFT
     * @param _nft nft to check
     * @return nft type id
     */
    function getPlatformNftType(uint256 _platform, address _nft) external view returns (uint256) {
        return platformToNftType[_platform][_nft];
    }

    /**
     * @notice get platform shares length
     * @param _platform platform of the NFT
     * @return platform shares length array
     */
    function getPlatformSharesLength(uint256 _platform) external view returns (uint256[] memory) {
        return platformToSharesLength[_platform];
    }

    /**
     * @notice get the implementation of the NFT vault
     * @param _nftAddress address of the NFT
     * @return implementation address of the NFT vault
     */
    function rentalImplementationOf(address _nftAddress) external view returns (address) {
        return nftToRentalImplementation[_nftAddress];
    }

    /**
     * @notice get orium aavegotchi splitter
     * @return orium aavegotchi splitter address
     */
    function getOriumAavegotchiSplitter() external view returns (address) {
        return oriumAavegotchiSplitter;
    }

    /**
     * @notice get aavegotchi alchemica tokens
     * @return array of alchemica tokens address
     */
    function getPlatformTokens(uint256 _platformId) external view returns (address[] memory) {
        return platformTokens[_platformId];
    }

    /**
     * @notice get nft vault info
     * @param _vaultAddress nft vault address
     * @return _platform platform of the NFT vault
     * @return _owner owner of the NFT vault
     */
    function getVaultInfo(address _vaultAddress)
        external
        view
        returns (uint256 _platform, address _owner)
    {
        require(isValidNftVault[_vaultAddress], "OriumFactory:: Invalid NFT vault");
        return (
            INftVaultPlatform(_vaultAddress).platform(),
            INftVaultPlatform(_vaultAddress).owner()
        );
    }

    /**
     * @notice get orium aavegotchi petting
     * @return orium aavegotchi petting address
     */
    function getOriumAavegotchiPettingAddress() external view returns (address) {
        return oriumAavegotchiPetting;
    }

    /**
     * @notice get aavegotchi diamond
     * @return aavegotchi diamond address
     */
    function getAavegotchiDiamondAddress() external view returns (address) {
        return aavegotchiDiamond;
    }

    /**
     * @notice get scholarships manager
     * @return scholarships manager address
     */
    function getScholarshipManagerAddress() external view returns (address) {
        return scholarshipManager;
    }

    /**
     * @notice get orium fee for scholarships
     * @return orium fee
     */
    function oriumFee() external view returns (uint256) {
        return _oriumFee;
    }

    function supportsRentalOffer(address _nftAddress) external view returns (bool) {
        return nftToSupportRentalOffer[_nftAddress];
    }
}
