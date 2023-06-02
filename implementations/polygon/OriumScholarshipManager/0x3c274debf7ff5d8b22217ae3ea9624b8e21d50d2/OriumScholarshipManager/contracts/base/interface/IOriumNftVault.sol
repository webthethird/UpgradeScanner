// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

enum NftState {
    NOT_DEPOSITED,
    IDLE,
    LISTED,
    BORROWED,
    CLAIMABLE
}

interface IOriumNftVault {
    function initialize(
        address _owner,
        address _factory,
        address _scholarshipManager,
        uint256 _platform
    ) external;

    function getNftState(address _nft, uint256 tokenId) external view returns (NftState _nftState);

    function isPausedForListing(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function setPausedForListings(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        bool[] memory _isPauseds
    ) external;

    function withdrawNfts(address[] memory _nftAddresses, uint256[] memory _tokenIds) external;

    function maxRentalPeriodAllowedOf(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (uint256);

    function setMaxAllowedRentalPeriod(
        address[] memory _nftAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _maxAllowedPeriods
    ) external;

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);
}

interface INftVaultPlatform {
    function platform() external view returns (uint256);

    function owner() external view returns (address);

    function createRentalOffer(
        uint256 _tokenId,
        address _nftAddress,
        bytes memory data
    ) external;

    function cancelRentalOffer(uint256 _tokenId, address _nftAddress) external;

    function endRental(address _nftAddress, uint32 _tokenId) external;

    function endRentalAndRelist(
        address _nftAddress,
        uint32 _tokenId,
        bytes memory data
    ) external;

    function claimTokensOfRentals(address[] memory _nftAddresses, uint256[] memory _tokenIds)
        external;
}
