// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
import {IVault} from "./interfaces/IVault.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Vault
 * @notice Stores all the BEND kept for incentives, just giving approval to the different
 * systems that will pull BEND funds for their specific use case
 * @author Bend
 **/
contract Vault is OwnableUpgradeable, IVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public bendToken;

    function initialize(address _token) external initializer {
        __Ownable_init();
        bendToken = _token;
    }

    function approve(address recipient, uint256 amount)
        external
        override
        onlyOwner
    {
        IERC20Upgradeable(bendToken).safeApprove(recipient, amount);
    }
}
