// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @title Undelegation Holder interface
 *
 * @dev This contract temporarily holds the undelegated amount transferred from the BC staking
 * address before it is transferred to the StakePool contract to fulfil claimReserve. This is
 * needed to ensure that all the amount transferred from the BC staking address to BSC gets
 * correctly reflected in the StakePool claimReserve without any loss of funds in-between.
 * This has following benefits:
 * - Less dependence on bot. Lesser the amount of time funds remain with a custodial address managed
 *   by the bot, greater the security.
 * - In case of an emergency situation like bot failing to undelegate timely, or some security
 *   mishap with the staking address on BC, funds can be added directly to this contract to
 *   satisfy user claims.
 * - Possibility to replace this contract with a TSS managed address in future, if needed.
 */
interface IUndelegationHolder {
    // @dev Emitted when receive function is called.
    event Received(address sender, uint256 amount);

    /**
     * @dev Called by the TokenHub contract when undelegated funds are transferred cross-chain by
     * bot from BC staking address to this contract on BSC.
     */
    receive() external payable;

    /**
     * @dev Called by the StakePool contract to withdraw the undelegated funds. It sends all its
     * funds to StakePool.
     *
     * Requirements:
     * - The caller must be the StakePool contract.
     *
     * @return The current balance, all of which it will be sending to the StakePool.
     */
    function withdrawUnbondedBNB() external returns (uint256);
}
