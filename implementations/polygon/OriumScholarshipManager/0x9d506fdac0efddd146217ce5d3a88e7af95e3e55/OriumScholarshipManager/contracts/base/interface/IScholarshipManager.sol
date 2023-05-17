// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IScholarshipManager {
    function platformOf(uint256 _programId) external view returns (uint256);

    function isProgram(uint256 _programId) external view returns (bool);

    function onDelegatedScholarshipProgram(
        address _owner,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _programId,
        uint256 _maxAllowedPeriod
    ) external;

    function onUnDelegatedScholarshipProgram(
        address owner,
        address nftAddress,
        uint256 tokenId
    ) external;

    function onPausedNft(address _owner, address _nftAddress, uint256 _tokenId) external;

    function onUnPausedNft(address _owner, address _nftAddress, uint256 _tokenId) external;

    function sharesOf(
        uint256 _programId,
        uint256 _eventId
    ) external view returns (uint256[] memory);

    function programOf(address _nftAddress, uint256 _tokenId) external view returns (uint256);

    function onTransferredGHST(address _vault, uint256 _amount) external;

    function ownerOf(uint256 _programId) external view returns (address);

    function vaultOf(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (address _vaultAddress);

    function isNftPaused(address _nftAddress, uint256 _tokenId) external view returns (bool);

    function onRentalEnded(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external;

    function onRentalOfferCancelled(
        address nftAddress,
        uint256 tokenId,
        address vaultAddress,
        uint256 programId
    ) external;
}
