// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVlQuoV2 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function lock(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external;
}
