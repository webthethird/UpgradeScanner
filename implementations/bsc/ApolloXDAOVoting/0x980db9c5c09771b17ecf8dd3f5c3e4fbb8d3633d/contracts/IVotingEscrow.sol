// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    function nftPointEpoch(uint tokenId) external view returns (uint);
    function currentEpoch() external view returns (uint);
    function nftPointHistory(uint tokenId, uint loc) external view returns (Point memory);
    function pointHistory(uint loc) external view returns (Point memory);
    function checkpoint() external;
    function token() external view returns (address);
    function nftOwner(uint tokenId) external view returns (address);
}
