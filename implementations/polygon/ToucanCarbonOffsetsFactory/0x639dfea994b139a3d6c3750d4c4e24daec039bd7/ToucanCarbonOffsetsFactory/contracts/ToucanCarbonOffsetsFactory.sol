// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity ^0.8.0;

import 'hardhat/console.sol'; // dev & testing
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';

import './ToucanCarbonOffsets.sol';
import './IToucanContractRegistry.sol';
import './ICarbonOffsetBatches.sol';
import './CarbonProjects.sol';
import './ToucanCarbonOffsetsFactoryStorage.sol';
import './libraries/ProjectUtils.sol';
import './libraries/ProjectVintageUtils.sol';
import './libraries/Modifiers.sol';

/// @notice Project-Vintage ERC20 Factory contract for BatchNFT fractionalization
/// Locks in received ERC721 BatchNFTs and can mint corresponding quantity of ERC20s
/// Permissionless, anyone can deploy new ERC20s unless they do not yet exist and pid exists
contract ToucanCarbonOffsetsFactory is
    ToucanCarbonOffsetsFactoryStorage,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ProjectUtils,
    ProjectVintageUtils,
    Modifiers
{
    event TokenCreated(uint256 vintageTokenId, address tokenAddress);

    // ----------------------------------------
    //      Upgradable related functions
    // ----------------------------------------

    function initialize(address _contractRegistry) public virtual initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        contractRegistry = _contractRegistry;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyOwner
    {}

    address public beacon;

    /// @dev sets the Beacon that tracks the current implementation logic of the TCO2s
    function setBeacon(address _beacon) external virtual onlyOwner {
        beacon = _beacon;
    }

    // ------------------------
    //      Admin functions
    // ------------------------

    /// @notice Emergency function to disable contract's core functionality
    /// @dev wraps _pause(), only Admin
    function pause() public virtual onlyBy(contractRegistry, owner()) {
        _pause();
    }

    /// @dev unpause the system, wraps _unpause(), only Admin
    function unpause() public virtual onlyBy(contractRegistry, owner()) {
        _unpause();
    }

    function setToucanContractRegistry(address _address)
        public
        virtual
        onlyOwner
    {
        contractRegistry = _address;
    }

    // ------------------------
    // Permissionless functions
    // ------------------------

    // Function to deploy new pERC20s
    // Note: Function could be internal, but that would disallow pre-deploying ERC20s without existing NFTs
    function deployNewProxy(uint256 projectVintageTokenId)
        internal
        virtual
        whenNotPaused
    {
        require(beacon != address(0), 'Error: Beacon for proxy not set');
        require(
            !checkExistence(projectVintageTokenId),
            'pvERC20 already exists'
        );
        checkProjectVintageTokenExists(contractRegistry, projectVintageTokenId);

        /// @dev generate payload for initialize function
        string memory signature = 'initialize(string,string,uint256,address)';
        bytes memory payload = abi.encodeWithSignature(
            signature,
            'Toucan Protocol: TCO2',
            'TCO2',
            projectVintageTokenId,
            contractRegistry
        );

        /// @dev deploy new proxyTCO2 contract
        BeaconProxy proxyTCO2 = new BeaconProxy(beacon, payload);

        IToucanContractRegistry(contractRegistry).addERC20(address(proxyTCO2));

        deployedContracts.push(address(proxyTCO2));
        pvIdtoERC20[projectVintageTokenId] = address(proxyTCO2);

        emit TokenCreated(projectVintageTokenId, address(proxyTCO2));
    }

    /// @dev Deploys a TCO2 contract based on a project vintage
    /// @param projectVintageTokenId numeric tokenId from vintage in `CarbonProjectVintages`
    function deployFromVintage(uint256 projectVintageTokenId)
        public
        virtual
        whenNotPaused
    {
        deployNewProxy(projectVintageTokenId);
    }

    /// @dev Checks if same project vintage has already been deployed
    function checkExistence(uint256 projectVintageTokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (pvIdtoERC20[projectVintageTokenId] == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    /// @dev Lists addresses of deployed TCO2 contracts
    function getContracts() public view virtual returns (address[] memory) {
        return deployedContracts;
    }
}
