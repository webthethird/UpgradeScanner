// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IMerkleRedeem {
    event Claimed(address _claimant, uint256 _balance);

    struct Claim {
        uint256 week;
        uint256 balance;
        bytes32[] merkleProof;
    }

    function claimWeek(
        address _liquidityProvider,
        uint256 _week,
        uint256 _claimedBalance,
        bytes32[] calldata _merkleProof
    ) external;

    function claimWeeks(address _liquidityProvider, Claim[] calldata claims) external;

    function claimStatus(
        address _liquidityProvider,
        uint256 _begin,
        uint256 _end
    ) external view returns (bool[] memory);

    function merkleRoots(uint256 _begin, uint256 _end) external view returns (bytes32[] memory);

    function seedAllocations(
        uint256 _week,
        bytes32 _merkleRoot,
        uint256 _totalAllocation
    ) external;

    function verifyClaim(
        address _liquidityProvider,
        uint256 _week,
        uint256 _claimedBalance,
        bytes32[] memory _merkleProof
    ) external view returns (bool valid);

    function getToken() external view returns (address token);
}
