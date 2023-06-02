// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumFactory {
    function isTrustedNft(address _nft) external view returns (bool);

    function isPlatformTrustedNft(address _nft, uint256 _platform) external view returns (bool);

    function isNftVault(address _nftVault) external view returns (bool);

    function getPlatformNftType(uint256 _platform, address _nft) external view returns (uint256);

    function rentalImplementationOf(address _nftAddress) external view returns (address);

    function getOriumAavegotchiSplitter() external view returns (address);

    function oriumFee() external view returns (uint256);

    function getPlatformTokens(uint256 _platformId) external view returns (address[] memory);

    function getVaultInfo(
        address _nftVault
    ) external view returns (uint256 platform, address owner);

    function getScholarshipManagerAddress() external view returns (address);

    function getOriumAavegotchiPettingAddress() external view returns (address);

    function getAavegotchiDiamondAddress() external view returns (address);

    function isSupportedPlatform(uint256 _platform) external view returns (bool);

    function supportsRentalOffer(address _nftAddress) external view returns (bool);

    function getPlatformSharesLength(uint256 _platform) external view returns (uint256[] memory);

    function getAavegotchiGHSTAddress() external view returns (address);
}
