// SPDX-FileCopyrightText: 2021 Toucan Labs
//
// SPDX-License-Identifier: UNLICENSED

// If you encounter a vulnerability or an issue, please contact <security@toucan.earth> or visit security.toucan.earth
pragma solidity 0.8.14;

import '../interfaces/IToucanContractRegistry.sol';
import '../interfaces/ICarbonProjects.sol';

contract ProjectUtils {
    function checkProjectTokenExists(address contractRegistry, uint256 tokenId)
        internal
        virtual
    {
        address c = IToucanContractRegistry(contractRegistry)
            .carbonProjectsAddress();
        bool isValidProjectTokenId = ICarbonProjects(c).isValidProjectTokenId(
            tokenId
        );
        require(isValidProjectTokenId == true, 'Error: Project does not exist');
    }
}
