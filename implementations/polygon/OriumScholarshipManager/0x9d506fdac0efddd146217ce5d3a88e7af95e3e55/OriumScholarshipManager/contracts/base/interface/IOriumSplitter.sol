// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumSplitter {
    function initialize(
        address _oriumTreasury,
        address _guildOwner,
        uint256 _scholarshipProgramId,
        address _factory,
        uint256 _platformId,
        address _scholarshipManager,
        address _vaultAddress,
        address _vaultOwner
    ) external;

    function getSharesWithOriumFee(
        uint256[] memory _shares
    ) external view returns (uint256[] memory _sharesWithOriumFee);

    function split() external;
}
