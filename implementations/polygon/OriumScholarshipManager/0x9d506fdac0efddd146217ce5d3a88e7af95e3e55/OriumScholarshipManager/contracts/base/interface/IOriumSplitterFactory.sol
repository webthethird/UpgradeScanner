// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

interface IOriumSplitterFactory {
    function deploySplitter(uint256 _programId, address _vaultAddress) external returns (address);

    function isValidSplitterAddress(address _splitter) external view returns (bool);

    function getPlatformSupportsSplitter(uint256 _platform) external view returns (bool);

    function splitterOf(uint256 _programId, address _vaultAddress) external view returns (address);

    function splittersOfVault(address _vaultAddress) external view returns (address[] memory);

    function splittersOfProgram(uint256 _programId) external view returns (address[] memory);
}
