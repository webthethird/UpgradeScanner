// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title StakePool Bot
 * @dev The functionalities required from the StakePool contract by the bot. This contract should
 * be implemented by the StakePool contract.
 */
interface IStakePoolBot {
    /**
     * @dev The amount that needs to be unbonded in the next unstaking epoch.
     * It increases on every user unstake operation, and decreases when the bot initiates unbonding.
     * This is queried by the bot in order to initiate unbonding.
     * It is int256, not uint256 because bnbUnbonding can be more than it and is subtracted from it.
     * So, if it is < 0, means we have already initiated unbonding for that much amount and eventually
     * that amount would be part of claimReserve. So, we don't need to unbond anything new on the BBC
     * side as long as this value is negative.
     *
     * Increase frequency: anytime
     * Decrease frequency & Bot query frequency:
     *      Mainnet: Weekly
     *      Testnet: Daily
     */
    function bnbToUnbond() external view returns (int256);

    /**
     * @dev The amount of BNB that is unbonding in the current unstaking epoch.
     * It increases when the bot initiates unbonding, and decreases when the unbonding is finished.
     * It is queried by the bot before calling unbondingFinished(), to figure out the amount that
     * needs to be moved from BBC to BSC.
     *
     * Increase, Decrease & Bot query frequency:
     *      Mainnet: Weekly
     *      Testnet: Daily
     */
    function bnbUnbonding() external view returns (uint256);

    /**
     * @dev A portion of the contract balance that is reserved in order to satisfy the claims
     * for which the cooldown period has finished. This will never be sent to BBC for staking.
     * It increases when the unbonding is finished, and decreases when any user actually claims
     * their BNB.
     *
     * Increase frequency:
     *      Mainnet: Weekly
     *      Testnet: Daily
     * Decrease frequency: anytime
     */
    function claimReserve() external view returns (uint256);

    /**
     * @dev This is called by the bot in order to transfer the stakable BNB from contract to the
     * staking address on BC.
     * Call frequency:
     *      Mainnet: Daily
     *      Testnet: Daily
     */
    function initiateDelegation() external;

    /**
     * @dev Called by the bot to update the exchange rate in contract based on the rewards
     * obtained in the BC staking address and accordingly mint fee tokens.
     * Call frequency:
     *      Mainnet: Daily
     *      Testnet: Daily
     *
     * @param bnbRewards: The amount of BNB which were received as staking rewards.
     */
    function epochUpdate(uint256 bnbRewards) external;

    /**
     * @dev This is called by the bot after it has executed the unbond transaction on BBC.
     * Call frequency:
     *      Mainnet: Weekly
     *      Testnet: Daily
     *
     * @param bnbUnbonding: The amount of BNB for which unbonding was initiated on BC.
     *                      It can be more than bnbToUnbond, but within a factor of min undelegation amount.
     */
    function unbondingInitiated(uint256 bnbUnbonding) external;

    /**
     * @dev Called by the bot after the unbonded amount for claim fulfilment is received in BBC
     * and has been transferred to the UndelegationHolder contract on BSC.
     * It calls UndelegationHolder.withdrawUnbondedBNB() to fetch the unbonded BNB to itself and
     * update `bnbUnbonding` and `claimReserve`.
     * Call frequency:
     *      Mainnet: Weekly
     *      Testnet: Daily
     */
    function unbondingFinished() external;
}
