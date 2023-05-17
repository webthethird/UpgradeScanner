// source: https://github.com/balancer-labs/erc20-redeemable/blob/master/merkle/contracts/MerkleRedeem.sol
// changes:
// 1. add license and update solidity version to 0.7.6
// 2. make it upgradeable

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { MerkleProofUpgradeable } from "@openzeppelin/contracts-upgradeable/cryptography/MerkleProofUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PerpOwnableUpgrade } from "../utils/PerpOwnableUpgrade.sol";
import { IMerkleRedeem } from "../interface/IMerkleRedeem.sol";

contract MerkleRedeemUpgradeSafe is IMerkleRedeem, PerpOwnableUpgrade {
    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//
    // Recorded weeks
    mapping(uint256 => bytes32) public weekMerkleRoots;
    mapping(uint256 => mapping(address => bool)) public claimed;

    IERC20 internal token;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // FUNCTIONS
    //

    function __MerkleRedeem_init(address _token) internal initializer {
        __Ownable_init();
        __MerkleRedeem_init_unchained(_token);
    }

    function __MerkleRedeem_init_unchained(address _token) internal initializer {
        token = IERC20(_token);
    }

    function disburse(address _liquidityProvider, uint256 _balance) private {
        if (_balance > 0) {
            emit Claimed(_liquidityProvider, _balance);
            require(token.transfer(_liquidityProvider, _balance), "ERR_TRANSFER_FAILED");
        }
    }

    function claimWeek(
        address _liquidityProvider,
        uint256 _week,
        uint256 _claimedBalance,
        bytes32[] calldata _merkleProof
    ) public virtual override {
        require(!claimed[_week][_liquidityProvider], "Claimed already");
        require(verifyClaim(_liquidityProvider, _week, _claimedBalance, _merkleProof), "Incorrect merkle proof");

        claimed[_week][_liquidityProvider] = true;
        disburse(_liquidityProvider, _claimedBalance);
    }

    function claimWeeks(address _liquidityProvider, Claim[] calldata claims) public virtual override {
        uint256 totalBalance = 0;
        Claim calldata claim;
        for (uint256 i = 0; i < claims.length; i++) {
            claim = claims[i];

            require(!claimed[claim.week][_liquidityProvider], "Claimed already");
            require(
                verifyClaim(_liquidityProvider, claim.week, claim.balance, claim.merkleProof),
                "Incorrect merkle proof"
            );

            totalBalance += claim.balance;
            claimed[claim.week][_liquidityProvider] = true;
        }
        disburse(_liquidityProvider, totalBalance);
    }

    function claimStatus(
        address _liquidityProvider,
        uint256 _begin,
        uint256 _end
    ) external view override returns (bool[] memory) {
        uint256 size = 1 + _end - _begin;
        bool[] memory arr = new bool[](size);
        for (uint256 i = 0; i < size; i++) {
            arr[i] = claimed[_begin + i][_liquidityProvider];
        }
        return arr;
    }

    function merkleRoots(uint256 _begin, uint256 _end) external view override returns (bytes32[] memory) {
        uint256 size = 1 + _end - _begin;
        bytes32[] memory arr = new bytes32[](size);
        for (uint256 i = 0; i < size; i++) {
            arr[i] = weekMerkleRoots[_begin + i];
        }
        return arr;
    }

    function verifyClaim(
        address _liquidityProvider,
        uint256 _week,
        uint256 _claimedBalance,
        bytes32[] memory _merkleProof
    ) public view virtual override returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(_liquidityProvider, _claimedBalance));
        return MerkleProofUpgradeable.verify(_merkleProof, weekMerkleRoots[_week], leaf);
    }

    function seedAllocations(
        uint256 _week,
        bytes32 _merkleRoot,
        uint256 _totalAllocation
    ) public virtual override {
        require(weekMerkleRoots[_week] == bytes32(0), "cannot rewrite merkle root");
        weekMerkleRoots[_week] = _merkleRoot;

        require(token.transferFrom(msg.sender, address(this), _totalAllocation), "ERR_TRANSFER_FAILED");
    }

    function getToken() external view override returns (address) {
        return address(token);
    }
}
