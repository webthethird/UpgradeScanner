// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @dev Interface of the PoolValidators contract.
 */
interface IPoolValidators {
    /**
    * @dev Structure for storing operator data.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param committed - defines whether operator has committed its readiness to host validators.
    */
    struct Operator {
        bytes32 depositDataMerkleRoot;
        bool committed;
    }

    /**
    * @dev Structure for passing information about the validator deposit data.
    * @param operator - address of the operator.
    * @param withdrawalCredentials - withdrawal credentials used for generating the deposit data.
    * @param depositDataRoot - hash tree root of the deposit data, generated by the operator.
    * @param publicKey - BLS public key of the validator, generated by the operator.
    * @param signature - BLS signature of the validator, generated by the operator.
    */
    struct DepositData {
        address operator;
        bytes32 withdrawalCredentials;
        bytes32 depositDataRoot;
        bytes publicKey;
        bytes signature;
    }

    /**
    * @dev Event for tracking new operators.
    * @param operator - address of the operator.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param depositDataMerkleProofs - validators deposit data merkle proofs.
    */
    event OperatorAdded(
        address indexed operator,
        bytes32 indexed depositDataMerkleRoot,
        string depositDataMerkleProofs
    );

    /**
    * @dev Event for tracking operator's commitments.
    * @param operator - address of the operator that expressed its readiness to host validators.
    */
    event OperatorCommitted(address indexed operator);

    /**
    * @dev Event for tracking operators' removals.
    * @param sender - address of the transaction sender.
    * @param operator - address of the operator.
    */
    event OperatorRemoved(
        address indexed sender,
        address indexed operator
    );

    /**
    * @dev Constructor for initializing the PoolValidators contract.
    * @param _admin - address of the contract admin.
    * @param _pool - address of the Pool contract.
    * @param _oracles - address of the Oracles contract.
    */
    function initialize(address _admin, address _pool, address _oracles) external;

    /**
    * @dev Function for retrieving the operator.
    * @param _operator - address of the operator to retrieve the data for.
    */
    function getOperator(address _operator) external view returns (bytes32, bool);

    /**
    * @dev Function for checking whether validator is registered.
    * @param validatorId - hash of the validator public key to receive the status for.
    */
    function isValidatorRegistered(bytes32 validatorId) external view returns (bool);

    /**
    * @dev Function for adding new operator.
    * @param _operator - address of the operator to add or update.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param depositDataMerkleProofs - validators deposit data merkle proofs.
    */
    function addOperator(
        address _operator,
        bytes32 depositDataMerkleRoot,
        string calldata depositDataMerkleProofs
    ) external;

    /**
    * @dev Function for committing operator. Must be called by the operator address
    * specified through the `addOperator` function call.
    */
    function commitOperator() external;

    /**
    * @dev Function for removing operator. Can be called either by operator or admin.
    * @param _operator - address of the operator to remove.
    */
    function removeOperator(address _operator) external;

    /**
    * @dev Function for registering the validator.
    * @param depositData - deposit data of the validator.
    * @param merkleProof - an array of hashes to verify whether the deposit data is part of the merkle root.
    */
    function registerValidator(DepositData calldata depositData, bytes32[] calldata merkleProof) external;
}
