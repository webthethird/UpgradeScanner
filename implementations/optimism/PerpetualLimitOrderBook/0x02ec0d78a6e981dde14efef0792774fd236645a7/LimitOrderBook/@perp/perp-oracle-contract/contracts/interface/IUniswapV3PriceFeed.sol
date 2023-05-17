// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IUniswapV3PriceFeed {
    function getPrice() external view returns (uint256);

    function decimals() external pure returns (uint8);
}
