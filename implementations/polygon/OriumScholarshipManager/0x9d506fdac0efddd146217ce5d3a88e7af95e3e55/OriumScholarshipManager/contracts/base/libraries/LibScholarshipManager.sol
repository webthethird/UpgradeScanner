// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import { IOriumFactory } from "../interface/IOriumFactory.sol";
import { IScholarshipManager } from "../interface/IScholarshipManager.sol";
import { INftVaultPlatform, IOriumNftVault } from "../interface/IOriumNftVault.sol";
import { IOriumSplitterFactory } from "../interface/IOriumSplitterFactory.sol";
import { IOriumSplitter } from "../interface/IOriumSplitter.sol";

library LibScholarshipManager {
    uint256 public constant COMETH_PLATFORM_ID = 2;
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

    function onlyTrustedNft(address _nftAddress, address _factory) public view {
        require(
            IOriumFactory(_factory).isTrustedNft(_nftAddress),
            "OriumScholarshipManager:: NFT is not trusted"
        );
    }

    function onlyNotPausedNft(
        address _nftAddress,
        uint256 _tokenId,
        address _scholarshipManager
    ) public view {
        require(
            IScholarshipManager(_scholarshipManager).isNftPaused(_nftAddress, _tokenId) == false,
            "OriumScholarshipManager:: NFT is paused"
        );
    }

    function onlyGuildOwner(uint256 _programId, address _scholarshipManager) public view {
        require(_programId != 0, "OriumScholarshipManager:: NFT is not delegated to any program");
        require(
            msg.sender == IScholarshipManager(_scholarshipManager).ownerOf(_programId),
            "OriumScholarshipManager:: Only guild owner can call this function"
        );
    }

    modifier onlyNftVault(address _factory) {
        require(
            IOriumFactory(_factory).isNftVault(msg.sender),
            "OriumFactory: Only OriumNftVault can call this function"
        );
        _;
    }

    function isValidShares(uint256[] memory _shares) public pure returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            sum += _shares[i];
        }
        return sum == 100 ether;
    }

    function createRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        bytes[] memory data,
        address _factory,
        address _scholarshipManager
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length && _tokenIds.length == data.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _createRentalOffer(
                _tokenIds[i],
                _nftAddresses[i],
                data[i],
                _factory,
                _scholarshipManager
            );
        }
    }

    function _createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data,
        address _factory,
        address _scholarshipManager
    ) internal {
        onlyNotPausedNft(_nftAddress, _tokenId, _scholarshipManager);

        (address _nftVault, uint256 _programId) = vaultAndProgramOfNft(
            _scholarshipManager,
            _nftAddress,
            _tokenId,
            _factory
        );
        INftVaultPlatform(_nftVault).createRentalOffer(_tokenId, _nftAddress, data);

        emitRentalEvent(_factory, _nftAddress, _tokenId, _nftVault, _programId, data);
    }

    /**
     * @notice Cancel Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     */
    function cancelRentalOffers(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        address _factory,
        address _scholarshipManager
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _cancelRentalOffer(_tokenIds[i], _nftAddresses[i], _factory, _scholarshipManager);
        }
    }

    function _cancelRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        address _factory,
        address _scholarshipManager
    ) internal {
        (address _nftVault, uint256 _programId) = vaultAndProgramOfNft(
            _scholarshipManager,
            _nftAddress,
            _tokenId,
            _factory
        );

        INftVaultPlatform(_nftVault).cancelRentalOffer(_tokenId, _nftAddress);
        emit RentalOfferCancelled(_nftAddress, _tokenId, _nftVault, _programId);
    }

    /**
     * @notice End Rental Offers
     * @dev This function is called by guild owner
     * @param _tokenIds The token ids
     * @param _nftAddresses The nft addresses
     */
    function endRentals(
        uint256[] memory _tokenIds,
        address[] memory _nftAddresses,
        address _factory,
        address _scholarshipManager
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _endRental(_tokenIds[i], _nftAddresses[i], _factory, _scholarshipManager);
        }
    }

    function _endRental(
        uint256 _tokenId,
        address _nftAddress,
        address _factory,
        address _scholarshipManager
    ) internal {
        (address _nftVault, uint256 _programId) = vaultAndProgramOfNft(
            _scholarshipManager,
            _nftAddress,
            _tokenId,
            _factory
        );

        INftVaultPlatform(_nftVault).endRental(_nftAddress, _tokenId);
        emit RentalEnded(_nftAddress, _tokenId, _nftVault, _programId);
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
        bytes[] memory _data,
        address _factory,
        address _scholarshipManager
    ) external {
        require(
            _tokenIds.length == _nftAddresses.length && _tokenIds.length == _data.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _endRentalAndRelist(
                _nftAddresses[i],
                _tokenIds[i],
                _data[i],
                _factory,
                _scholarshipManager
            );
        }
    }

    function _endRentalAndRelist(
        address _nftAddress,
        uint256 _tokenId,
        bytes memory data,
        address _factory,
        address _scholarshipManager
    ) internal {
        (address _nftVault, uint256 _programId) = vaultAndProgramOfNft(
            _scholarshipManager,
            _nftAddress,
            _tokenId,
            _factory
        );

        INftVaultPlatform(_nftVault).endRentalAndRelist(_nftAddress, _tokenId, data);
        emit RentalEnded(_nftAddress, _tokenId, _nftVault, _programId);

        emitRentalEvent(_factory, _nftAddress, _tokenId, _nftVault, _programId, data);
    }

    function claimTokensOfRentals(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        address _factory,
        address _scholarshipManager
    ) external {
        require(
            _nftAddresses.length == _tokenIds.length,
            "OriumScholarshipManager:: Array lengths are not equal"
        );

        for (uint256 i = 0; i < _nftAddresses.length; i++) {
            _claimTokensOfRental(_nftAddresses[i], _tokenIds[i], _factory, _scholarshipManager);
        }
    }

    function _claimTokensOfRental(
        address _nftAddress,
        uint256 _tokenId,
        address _factory,
        address _scholarshipManager
    ) internal {
        (address _nftVault, uint256 _programId) = vaultAndProgramOfNft(
            _scholarshipManager,
            _nftAddress,
            _tokenId,
            _factory
        );

        address[] memory _nftAddresses = new address[](1);
        _nftAddresses[0] = _nftAddress;

        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = _tokenId;

        INftVaultPlatform(_nftVault).claimTokensOfRentals(_nftAddresses, _tokenIds);
    }

    function getPlatformVerifiedVault(
        address _nftAddress,
        uint256 _tokenId,
        address _scholarshipManager
    ) public view returns (address _nftVault) {
        _nftVault = IScholarshipManager(_scholarshipManager).vaultOf(_nftAddress, _tokenId);
        require(
            _nftVault != address(0),
            "OriumScholarshipManager:: NFT is not deposited in any vault"
        );
    }

    function withdrawEarnings(uint256 _platformId, bytes memory _data, address _factory) external {
        if (_platformId == COMETH_PLATFORM_ID) {
            address[] memory _splitters = abi.decode(_data, (address[]));
            withdrawFromComethSplitters(_splitters, _factory);
        } else {
            //TODO: map Aavegotchi here in the future as well
            revert("OriumScholarshipManager:: Invalid platform");
        }
    }

    function withdrawFromComethSplitters(address[] memory _splitters, address _factory) public {
        address _splitterFactory = IOriumFactory(_factory).getOriumSplitterFactory();

        for (uint256 i = 0; i < _splitters.length; i++) {
            require(
                IOriumSplitterFactory(_splitterFactory).isValidSplitterAddress(_splitters[i]),
                "OriumScholarshipManager:: Invalid splitter address"
            );
            IOriumSplitter(_splitters[i]).split();
        }
    }

    function emitRentalEvent(
        address _factory,
        address _nftAddress,
        uint256 _tokenId,
        address _nftVault,
        uint256 _programId,
        bytes memory data
    ) public {
        if (IOriumFactory(_factory).supportsRentalOffer(_nftAddress)) {
            emit RentalOfferCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
        } else {
            emit RentalCreated(_nftAddress, _tokenId, _nftVault, _programId, data);
        }
    }

    function vaultAndProgramOfNft(
        address _scholarshipManager,
        address _nftAddress,
        uint256 _tokenId,
        address _factory
    ) public view returns (address _nftVault, uint256 _programId) {
        onlyTrustedNft(_nftAddress, _factory);

        _programId = IScholarshipManager(_scholarshipManager).programOf(_nftAddress, _tokenId);

        onlyGuildOwner(_programId, _scholarshipManager);

        _nftVault = getPlatformVerifiedVault(_nftAddress, _tokenId, _scholarshipManager);
    }
}
