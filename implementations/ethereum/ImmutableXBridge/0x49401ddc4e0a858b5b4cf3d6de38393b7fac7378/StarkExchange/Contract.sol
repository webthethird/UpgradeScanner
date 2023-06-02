{"Common.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\n/*\n  Common Utility librarries.\n  I. Addresses (extending address).\n*/\nlibrary Addresses {\n    function isContract(address account) internal view returns (bool) {\n        uint256 size;\n        // solium-disable-next-line security/no-inline-assembly\n        assembly {\n            size := extcodesize(account)\n        }\n        return size \u003e 0;\n    }\n\n    function performEthTransfer(address recipient, uint256 amount) internal {\n        // solium-disable-next-line security/no-call-value\n        (bool success, ) = recipient.call.value(amount)(\"\"); // NOLINT: low-level-calls.\n        require(success, \"ETH_TRANSFER_FAILED\");\n    }\n\n    /*\n      Safe wrapper around ERC20/ERC721 calls.\n      This is required because many deployed ERC20 contracts don\u0027t return a value.\n      See https://github.com/ethereum/solidity/issues/4116.\n    */\n    function safeTokenContractCall(address tokenAddress, bytes memory callData) internal {\n        require(isContract(tokenAddress), \"BAD_TOKEN_ADDRESS\");\n        // NOLINTNEXTLINE: low-level-calls.\n        (bool success, bytes memory returndata) = tokenAddress.call(callData);\n        // solium-disable-previous-line security/no-low-level-calls\n        require(success, string(returndata));\n\n        if (returndata.length \u003e 0) {\n            require(abi.decode(returndata, (bool)), \"TOKEN_OPERATION_FAILED\");\n        }\n    }\n\n    /*\n      Similar to safeTokenContractCall, but always ignores the return value.\n\n      Assumes some other method is used to detect the failures\n      (e.g. balance is checked before and after the call).\n    */\n    function uncheckedTokenContractCall(address tokenAddress, bytes memory callData) internal {\n        // NOLINTNEXTLINE: low-level-calls.\n        (bool success, bytes memory returndata) = tokenAddress.call(callData);\n        // solium-disable-previous-line security/no-low-level-calls\n        require(success, string(returndata));\n    }\n\n}\n\n/*\n  II. StarkExTypes - Common data types.\n*/\nlibrary StarkExTypes {\n\n    // Structure representing a list of verifiers (validity/availability).\n    // A statement is valid only if all the verifiers in the list agree on it.\n    // Adding a verifier to the list is immediate - this is used for fast resolution of\n    // any soundness issues.\n    // Removing from the list is time-locked, to ensure that any user of the system\n    // not content with the announced removal has ample time to leave the system before it is\n    // removed.\n    struct ApprovalChainData {\n        address[] list;\n        // Represents the time after which the verifier with the given address can be removed.\n        // Removal of the verifier with address A is allowed only in the case the value\n        // of unlockedForRemovalTime[A] != 0 and unlockedForRemovalTime[A] \u003c (current time).\n        mapping (address =\u003e uint256) unlockedForRemovalTime;\n    }\n\n}\n"},"GovernanceStorage.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\n/*\n  Holds the governance slots for ALL entities, including proxy and the main contract.\n*/\ncontract GovernanceStorage {\n\n    struct GovernanceInfoStruct {\n        mapping (address =\u003e bool) effectiveGovernors;\n        address candidateGovernor;\n        bool initialized;\n    }\n\n    // A map from a Governor tag to its own GovernanceInfoStruct.\n    mapping (string =\u003e GovernanceInfoStruct) internal governanceInfo;\n}\n"},"Identity.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\ncontract Identity {\n\n    /*\n      Allows a caller, typically another contract,\n      to ensure that the provided address is of the expected type and version.\n    */\n    function identify()\n        external pure\n        returns(string memory);\n}\n"},"IDispatcher.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\n/*\n  Interface for generic dispatcher to use,\n  which the concrete dispatcher must implement.\n\n  I contains the functions that are specific to the concrete dispatcher instance.\n\n  The interface is implemented as contract, because interface implies all methods external.\n*/\ncontract IDispatcher {\n\n    function getSubContract(bytes4 selector) internal view returns (address);\n\n    function setSubContractAddress(uint256 index, address subContract) internal;\n\n    function getNumSubcontracts() internal pure returns (uint256);\n\n    function validateSubContractIndex(uint256 index, address subContract) internal pure;\n\n    /*\n      Ensures initializer can be called. Reverts otherwise.\n    */\n    function initializationSentinel() internal view;\n}\n"},"IFactRegistry.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\n/*\n  The Fact Registry design pattern is a way to separate cryptographic verification from the\n  business logic of the contract flow.\n\n  A fact registry holds a hash table of verified \"facts\" which are represented by a hash of claims\n  that the registry hash check and found valid. This table may be queried by accessing the\n  isValid() function of the registry with a given hash.\n\n  In addition, each fact registry exposes a registry specific function for submitting new claims\n  together with their proofs. The information submitted varies from one registry to the other\n  depending of the type of fact requiring verification.\n\n  For further reading on the Fact Registry design pattern see this\n  `StarkWare blog post \u003chttps://medium.com/starkware/the-fact-registry-a64aafb598b6\u003e`_.\n*/\ncontract IFactRegistry {\n    /*\n      Returns true if the given fact was previously registered in the contract.\n    */\n    function isValid(bytes32 fact)\n        external view\n        returns(bool);\n}\n"},"MainDispatcher.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\nimport \"SubContractor.sol\";\nimport \"IDispatcher.sol\";\nimport \"Common.sol\";\nimport \"StorageSlots.sol\";\n\n\ncontract MainDispatcher is IDispatcher, StorageSlots {\n\n    using Addresses for address;\n\n    function() external payable {\n        address subContractAddress = getSubContract(msg.sig);\n        require(subContractAddress != address(0x0), \"NO_CONTRACT_FOR_FUNCTION\");\n\n        // solium-disable-next-line security/no-inline-assembly\n        assembly {\n            // Copy msg.data. We take full control of memory in this inline assembly\n            // block because it will not return to Solidity code. We overwrite the\n            // Solidity scratch pad at memory position 0.\n            calldatacopy(0, 0, calldatasize)\n\n            // Call the implementation.\n            // out and outsize are 0 for now, as we don\"t know the out size yet.\n            let result := delegatecall(gas, subContractAddress, 0, calldatasize, 0, 0)\n\n            // Copy the returned data.\n            returndatacopy(0, 0, returndatasize)\n\n            switch result\n                // delegatecall returns 0 on error.\n                case 0 {\n                    revert(0, returndatasize)\n                }\n                default {\n                    return(0, returndatasize)\n                }\n        }\n    }\n\n    /*\n      1. Extract subcontracts.\n      2. Verify correct sub-contract initializer size.\n      3. Extract sub-contract initializer data.\n      4. Call sub-contract initializer.\n\n      The init data bytes passed to initialize are structed as following:\n      I. N slots (uin256 size) addresses of the deployed sub-contracts.\n      II. An address of an external initialization contract (optional, or ZERO_ADDRESS).\n      III. (Up to) N bytes sections of the sub-contracts initializers.\n\n      If already initialized (i.e. upgrade) we expect the init data to be consistent with this.\n      and if a different size of init data is expected when upgrading, the initializerSize should\n      reflect this.\n\n      If an external initializer contract is not used, ZERO_ADDRESS is passed in its slot.\n      If the external initializer contract is used, all the remaining init data is passed to it,\n      and internal initialization will not occur.\n\n      External Initialization Contract\n      --------------------------------\n      External Initialization Contract (EIC) is a hook for custom initialization.\n      Typically in an upgrade flow, the expected initialization contains only the addresses of\n      the sub-contracts. Normal initialization of the sub-contracts is such that is not needed\n      in an upgrade, and actually may be very dangerous, as changing of state on a working system\n      may corrupt it.\n\n      In the event that some state initialization is required, the EIC is a hook that allows this.\n      It may be deployed and called specifically for this purpose.\n\n      The address of the EIC must be provided (if at all) when a new implementation is added to\n      a Proxy contract (as part of the initialization vector).\n      Hence, it is considered part of the code open to reviewers prior to a time-locked upgrade.\n\n      When a custom initialization is performed using an EIC,\n      the main dispatcher initialize extracts and stores the sub-contracts addresses, and then\n      yields to the EIC, skipping the rest of its initialization code.\n\n\n      Flow of MainDispatcher initialize\n      ---------------------------------\n      1. Extraction and assignment of subcontracts addresses\n         Main dispatcher expects a valid and consistent set of addresses in the passed data.\n         It validates that, extracts the addresses from the data, and validates that the addresses\n         are of the expected type and order. Then those addresses are stored.\n\n      2. Extraction of EIC address\n         The address of the EIC is extracted from the data.\n         External Initializer Contract is optional. ZERO_ADDRESS indicates it is not used.\n\n      3a. EIC is used\n          Dispatcher calls the EIC initialize function with the remaining data.\n          Note - In this option 3b is not performed.\n\n      3b. EIC is not used\n          If there is additional initialization data then:\n          I. Sentitenl function is called to permit subcontracts initialization.\n          II. Dispatcher loops through the subcontracts and for each one it extracts the\n              initializing data and passes it to the subcontract\u0027s initialize function.\n\n    */\n    // NOLINTNEXTLINE: external-function.\n    function initialize(bytes memory data) public {\n        // Number of sub-contracts.\n        uint256 nSubContracts = getNumSubcontracts();\n\n        // We support currently 4 bits per contract, i.e. 16, reserving 00 leads to 15.\n        require(nSubContracts \u003c= 15, \"TOO_MANY_SUB_CONTRACTS\");\n\n        // Init data MUST include addresses for all sub-contracts.\n        require(data.length \u003e= 32 * (nSubContracts + 1), \"SUB_CONTRACTS_NOT_PROVIDED\");\n\n        // Ensure implementation is a valid contract.\n        require(implementation().isContract(), \"INVALID_IMPLEMENTATION\");\n\n        // Size of passed data, excluding sub-contract addresses.\n        uint256 additionalDataSize = data.length - 32 * (nSubContracts + 1);\n\n        // Sum of subcontract initializers. Aggregated for verification near the end.\n        uint256 totalInitSizes = 0;\n\n        // Offset (within data) of sub-contract initializer vector.\n        // Just past the sub-contract addresses.\n        uint256 initDataContractsOffset = 32 * (nSubContracts + 1);\n\n        // 1. Extract \u0026 update contract addresses.\n        for (uint256 nContract = 1; nContract \u003c= nSubContracts; nContract++) {\n            address contractAddress;\n\n            // Extract sub-contract address.\n            // solium-disable-next-line security/no-inline-assembly\n            assembly {\n                contractAddress := mload(add(data, mul(32, nContract)))\n            }\n\n            validateSubContractIndex(nContract, contractAddress);\n\n            // Contracts are indexed from 1 and 0 is not in use here.\n            setSubContractAddress(nContract, contractAddress);\n        }\n\n        // Check if we have an external initializer contract.\n        address externalInitializerAddr;\n\n        // 2. Extract sub-contract address, again. It\u0027s cheaper than reading from storage.\n        // solium-disable-next-line security/no-inline-assembly\n        assembly {\n            externalInitializerAddr := mload(add(data, mul(32, add(nSubContracts, 1))))\n        }\n\n        // 3(a). Yield to EIC initialization.\n        if (externalInitializerAddr != address(0x0)) {\n            callExternalInitializer(data, externalInitializerAddr, additionalDataSize);\n            return;\n        }\n\n        // 3(b). Subcontracts initialization.\n        // I. If no init data passed besides sub-contracts, return.\n        if (additionalDataSize == 0) {\n            return;\n        }\n\n        // Just to be on the safe side.\n        assert(externalInitializerAddr == address(0x0));\n\n        // II. Gate further initialization.\n        initializationSentinel();\n\n        // III. Loops through the subcontracts, extracts their data and calls their initializer.\n        for (uint256 nContract = 1; nContract \u003c= nSubContracts; nContract++) {\n            address contractAddress;\n\n            // Extract sub-contract address, again. It\u0027s cheaper than reading from storage.\n            // solium-disable-next-line security/no-inline-assembly\n            assembly {\n                contractAddress := mload(add(data, mul(32, nContract)))\n            }\n            // The initializerSize returns the expected size, with respect also to the state status.\n            // i.e. different size if it\u0027s a first init (clean state) or upgrade init (alive state).\n            // NOLINTNEXTLINE: calls-loop.\n\n            // The initializerSize is called via delegatecall, so that it can relate to the state,\n            // and not only to the new contract code. (e.g. return 0 if state-intialized else 192).\n            // solium-disable-next-line security/no-low-level-calls\n            // NOLINTNEXTLINE: reentrancy-events low-level-calls calls-loop.\n            (bool success, bytes memory returndata) = contractAddress.delegatecall(\n                abi.encodeWithSelector(SubContractor(contractAddress).initializerSize.selector));\n            require(success, string(returndata));\n            uint256 initSize = abi.decode(returndata, (uint256));\n            require(initSize \u003c= additionalDataSize, \"INVALID_INITIALIZER_SIZE\");\n            require(totalInitSizes + initSize \u003c= additionalDataSize, \"INVALID_INITIALIZER_SIZE\");\n\n            if (initSize == 0) {\n                continue;\n            }\n\n            // Extract sub-contract init vector.\n            bytes memory subContractInitData = new bytes(initSize);\n            for (uint256 trgOffset = 32; trgOffset \u003c= initSize; trgOffset += 32) {\n                // solium-disable-next-line security/no-inline-assembly\n                assembly {\n                    mstore(\n                        add(subContractInitData, trgOffset),\n                        mload(add(add(data, trgOffset), initDataContractsOffset))\n                    )\n                }\n            }\n\n            // Call sub-contract initializer.\n            // solium-disable-next-line security/no-low-level-calls\n            // NOLINTNEXTLINE: low-level-calls.\n            (success, returndata) = contractAddress.delegatecall(\n                abi.encodeWithSelector(this.initialize.selector, subContractInitData)\n            );\n            require(success, string(returndata));\n            totalInitSizes += initSize;\n            initDataContractsOffset += initSize;\n        }\n        require(\n            additionalDataSize == totalInitSizes,\n            \"MISMATCHING_INIT_DATA_SIZE\");\n    }\n\n    function callExternalInitializer(\n        bytes memory data,\n        address externalInitializerAddr,\n        uint256 dataSize)\n        private {\n        require(externalInitializerAddr.isContract(), \"NOT_A_CONTRACT\");\n        require(dataSize \u003c= data.length, \"INVALID_DATA_SIZE\");\n        bytes memory extInitData = new bytes(dataSize);\n\n        // Prepare memcpy pointers.\n        uint256 srcDataOffset = 32 + data.length - dataSize;\n        uint256 srcData;\n        uint256 trgData;\n\n        // solium-disable-next-line security/no-inline-assembly\n        assembly {\n            srcData := add(data, srcDataOffset)\n            trgData := add(extInitData, 32)\n        }\n\n        // Copy initializer data to be passed to the EIC.\n        for (uint256 seek = 0; seek \u003c dataSize; seek += 32) {\n            // solium-disable-next-line security/no-inline-assembly\n            assembly {\n                mstore(\n                    add(trgData, seek),\n                    mload(add(srcData, seek))\n                )\n            }\n        }\n\n        // solium-disable-next-line security/no-low-level-calls\n        // NOLINTNEXTLINE: low-level-calls.\n        (bool success, bytes memory returndata) = externalInitializerAddr.delegatecall(\n            abi.encodeWithSelector(this.initialize.selector, extInitData)\n        );\n        require(success, string(returndata));\n        require(returndata.length == 0, string(returndata));\n    }\n}\n"},"MainStorage.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\nimport \"IFactRegistry.sol\";\nimport \"ProxyStorage.sol\";\nimport \"Common.sol\";\n/*\n  Holds ALL the main contract state (storage) variables.\n*/\ncontract MainStorage is ProxyStorage {\n\n    IFactRegistry escapeVerifier_;\n\n    // Global dex-frozen flag.\n    bool stateFrozen;                               // NOLINT: constable-states.\n\n    // Time when unFreeze can be successfully called (UNFREEZE_DELAY after freeze).\n    uint256 unFreezeTime;                           // NOLINT: constable-states.\n\n    // Pending deposits.\n    // A map STARK key =\u003e asset id =\u003e vault id =\u003e quantized amount.\n    mapping (uint256 =\u003e mapping (uint256 =\u003e mapping (uint256 =\u003e uint256))) pendingDeposits;\n\n    // Cancellation requests.\n    // A map STARK key =\u003e asset id =\u003e vault id =\u003e request timestamp.\n    mapping (uint256 =\u003e mapping (uint256 =\u003e mapping (uint256 =\u003e uint256))) cancellationRequests;\n\n    // Pending withdrawals.\n    // A map STARK key =\u003e asset id =\u003e quantized amount.\n    mapping (uint256 =\u003e mapping (uint256 =\u003e uint256)) pendingWithdrawals;\n\n    // vault_id =\u003e escape used boolean.\n    mapping (uint256 =\u003e bool) escapesUsed;\n\n    // Number of escapes that were performed when frozen.\n    uint256 escapesUsedCount;                       // NOLINT: constable-states.\n\n    // Full withdrawal requests: stark key =\u003e vaultId =\u003e requestTime.\n    // stark key =\u003e vaultId =\u003e requestTime.\n    mapping (uint256 =\u003e mapping (uint256 =\u003e uint256)) fullWithdrawalRequests;\n\n    // State sequence number.\n    uint256 sequenceNumber;                         // NOLINT: constable-states uninitialized-state.\n\n    // Vaults Tree Root \u0026 Height.\n    uint256 vaultRoot;                              // NOLINT: constable-states uninitialized-state.\n    uint256 vaultTreeHeight;                        // NOLINT: constable-states uninitialized-state.\n\n    // Order Tree Root \u0026 Height.\n    uint256 orderRoot;                              // NOLINT: constable-states uninitialized-state.\n    uint256 orderTreeHeight;                        // NOLINT: constable-states uninitialized-state.\n\n    // True if and only if the address is allowed to add tokens.\n    mapping (address =\u003e bool) tokenAdmins;\n\n    // True if and only if the address is allowed to register users.\n    mapping (address =\u003e bool) userAdmins;\n\n    // True if and only if the address is an operator (allowed to update state).\n    mapping (address =\u003e bool) operators;\n\n    // Mapping of contract ID to asset data.\n    mapping (uint256 =\u003e bytes) assetTypeToAssetInfo;    // NOLINT: uninitialized-state.\n\n    // Mapping of registered contract IDs.\n    mapping (uint256 =\u003e bool) registeredAssetType;      // NOLINT: uninitialized-state.\n\n    // Mapping from contract ID to quantum.\n    mapping (uint256 =\u003e uint256) assetTypeToQuantum;    // NOLINT: uninitialized-state.\n\n    // This mapping is no longer in use, remains for backwards compatibility.\n    mapping (address =\u003e uint256) starkKeys_DEPRECATED;  // NOLINT: naming-convention.\n\n    // Mapping from STARK public key to the Ethereum public key of its owner.\n    mapping (uint256 =\u003e address) ethKeys;               // NOLINT: uninitialized-state.\n\n    // Timelocked state transition and availability verification chain.\n    StarkExTypes.ApprovalChainData verifiersChain;\n    StarkExTypes.ApprovalChainData availabilityVerifiersChain;\n\n    // Batch id of last accepted proof.\n    uint256 lastBatchId;                            // NOLINT: constable-states uninitialized-state.\n\n    // Mapping between sub-contract index to sub-contract address.\n    mapping(uint256 =\u003e address) subContracts;       // NOLINT: uninitialized-state.\n\n    // Onchain-data version configured for the system.\n    // TODO(zuphit,01/01/2021): wrap this with an attribute class.\n    uint256 onchainDataVersion;                     // NOLINT: constable-states uninitialized-state.\n}\n"},"ProxyStorage.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\nimport \"GovernanceStorage.sol\";\n\n/*\n  Holds the Proxy-specific state variables.\n  This contract is inherited by the GovernanceStorage (and indirectly by MainStorage)\n  to prevent collision hazard.\n*/\ncontract ProxyStorage is GovernanceStorage {\n\n    // Stores the hash of the initialization vector of the added implementation.\n    // Upon upgradeTo the implementation, the initialization vector is verified\n    // to be identical to the one submitted when adding the implementation.\n    mapping (address =\u003e bytes32) internal initializationHash;\n\n    // The time after which we can switch to the implementation.\n    mapping (address =\u003e uint256) internal enabledTime;\n\n    // A central storage of the flags whether implementation has been initialized.\n    // Note - it can be used flexibly enough to accommodate multiple levels of initialization\n    // (i.e. using different key salting schemes for different initialization levels).\n    mapping (bytes32 =\u003e bool) internal initialized;\n}\n"},"StarkExchange.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\nimport \"MainStorage.sol\";\nimport \"MainDispatcher.sol\";\n\ncontract StarkExchange is MainStorage, MainDispatcher {\n    string public constant VERSION = \"2.5.0\";\n\n    uint256 constant SUBCONTRACT_BITS = 4;\n\n    // Salt for a 7 bit unique spread of all relevant selectors. Pre-calculated.\n    // ---------- The following code was auto-generated. PLEASE DO NOT EDIT. ----------\n    uint256 constant MAGIC_SALT = 45733;\n    uint256 constant IDX_MAP_0 = 0x201220230201001000221220210222000000020303010211122120200003002;\n    uint256 constant IDX_MAP_1 = 0x2100003002200010003000000300100220220203000020000101022100011100;\n    // ---------- End of auto-generated code. ----------\n\n    function validateSubContractIndex(uint256 index, address subContract) internal pure{\n        string memory id = SubContractor(subContract).identify();\n        bytes32 hashed_expected_id = keccak256(abi.encodePacked(expectedIdByIndex(index)));\n        require(\n            hashed_expected_id == keccak256(abi.encodePacked(id)),\n            \"MISPLACED_INDEX_OR_BAD_CONTRACT_ID\");\n    }\n\n    function expectedIdByIndex(uint256 index)\n        private pure returns (string memory id) {\n        if (index == 1){\n            id = \"StarkWare_AllVerifiers_2020_1\";\n        } else if (index == 2){\n            id = \"StarkWare_TokensAndRamping_2020_1\";\n        } else if (index == 3){\n            id = \"StarkWare_StarkExState_2020_1\";\n        } else {\n            revert(\"UNEXPECTED_INDEX\");\n        }\n    }\n\n    function getNumSubcontracts() internal pure returns (uint256) {\n        return 3;\n    }\n\n    function getSubContract(bytes4 selector)\n        internal view returns (address) {\n        uint256 location = 0x7F \u0026 uint256(keccak256(abi.encodePacked(selector, MAGIC_SALT)));\n        uint256 subContractIdx;\n        uint256 offset = SUBCONTRACT_BITS * location % 256;\n        if (location \u003c 64) {\n            subContractIdx = (IDX_MAP_0 \u003e\u003e offset) \u0026 0xF;\n        } else {\n            subContractIdx = (IDX_MAP_1 \u003e\u003e offset) \u0026 0xF;\n        }\n        return subContracts[subContractIdx];\n    }\n\n    function setSubContractAddress(uint256 index, address subContractAddress) internal {\n        subContracts[index] = subContractAddress;\n    }\n\n    function initializationSentinel()\n        internal view {\n        string memory REVERT_MSG = \"INITIALIZATION_BLOCKED\";\n        // This initializer sets roots etc. It must not be applied twice.\n        // I.e. it can run only when the state is still empty.\n        require(vaultRoot == 0, REVERT_MSG);\n        require(vaultTreeHeight == 0, REVERT_MSG);\n        require(orderRoot == 0, REVERT_MSG);\n        require(orderTreeHeight == 0, REVERT_MSG);\n    }\n}\n"},"StorageSlots.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\n/**\n  StorageSlots holds the arbitrary storage slots used throughout the Proxy pattern.\n  Storage address slots are a mechanism to define an arbitrary location, that will not be\n  overlapped by the logical contracts.\n*/\ncontract StorageSlots {\n    /*\n      Returns the address of the current implementation.\n    */\n    // NOLINTNEXTLINE external-function.\n    function implementation() public view returns(address _implementation) {\n        bytes32 slot = IMPLEMENTATION_SLOT;\n        // solium-disable-next-line security/no-inline-assembly\n        assembly {\n            _implementation := sload(slot)\n        }\n    }\n\n    // Storage slot with the address of the current implementation.\n    // The address of the slot is keccak256(\"StarkWare2019.implemntation-slot\").\n    // We need to keep this variable stored outside of the commonly used space,\n    // so that it\u0027s not overrun by the logical implementation (the proxied contract).\n    bytes32 internal constant IMPLEMENTATION_SLOT =\n    0x177667240aeeea7e35eabe3a35e18306f336219e1386f7710a6bf8783f761b24;\n\n    // This storage slot stores the finalization flag.\n    // Once the value stored in this slot is set to non-zero\n    // the proxy blocks implementation upgrades.\n    // The current implementation is then referred to as Finalized.\n    // Web3.solidityKeccak([\u0027string\u0027], [\"StarkWare2019.finalization-flag-slot\"]).\n    bytes32 internal constant FINALIZED_STATE_SLOT =\n    0x7d433c6f837e8f93009937c466c82efbb5ba621fae36886d0cac433c5d0aa7d2;\n\n    // Storage slot to hold the upgrade delay (time-lock).\n    // The intention of this slot is to allow modification using an EIC.\n    // Web3.solidityKeccak([\u0027string\u0027], [\u0027StarkWare.Upgradibility.Delay.Slot\u0027]).\n    bytes32 public constant UPGRADE_DELAY_SLOT =\n    0xc21dbb3089fcb2c4f4c6a67854ab4db2b0f233ea4b21b21f912d52d18fc5db1f;\n}\n"},"SubContractor.sol":{"content":"/*\n  Copyright 2019,2020 StarkWare Industries Ltd.\n\n  Licensed under the Apache License, Version 2.0 (the \"License\").\n  You may not use this file except in compliance with the License.\n  You may obtain a copy of the License at\n\n  https://www.starkware.co/open-source-license/\n\n  Unless required by applicable law or agreed to in writing,\n  software distributed under the License is distributed on an \"AS IS\" BASIS,\n  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n  See the License for the specific language governing permissions\n  and limitations under the License.\n*/\npragma solidity ^0.5.2;\n\nimport \"Identity.sol\";\n\ncontract SubContractor is Identity {\n\n    function initialize(bytes calldata data)\n        external;\n\n    function initializerSize()\n        external view\n        returns(uint256);\n\n}\n"}}