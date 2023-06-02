// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../pool/PausableAssets.sol';

contract TestPausableAssets is PausableAssets {
    function testRequireAssetNotPaused(address asset) external {
        return requireAssetNotPaused(asset);
    }

    function testRequireAssetPaused(address asset) external {
        return requireAssetPaused(asset);
    }

    function test_pauseAsset(address asset) external {
        return _pauseAsset(asset);
    }

    function test_unpauseAsset(address asset) external {
        return _unpauseAsset(asset);
    }
}
