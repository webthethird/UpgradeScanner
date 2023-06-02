// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(address account) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    function withdrawTokenRewards(address _to) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        bytes32 merkleRoot,
        uint256 index,
        address account,
        uint256 amount
    );
    event MerkleRootSet(bytes32 merkleRoot);
    event EndTimestampSet(uint256 endTimestamp);
    event TokensWithdrawn(uint256 amount);
}
