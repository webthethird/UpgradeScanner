// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title VestingWallet (extended for WOM Token Vesting), from OpenZeppelin Contracts v4.4.0 (finance/VestingWallet.sol)
 * @dev This contract handles the vesting of WOM, a ERC20 token for a list of admin-settable beneficiaries.
 * This contract will release the token to the beneficiary following a given vesting schedule.
 * The vesting schedule is customizable through the {vestedAmount} function.
 *
 * WOM token transferred to this contract will follow the vesting schedule as if they were locked from the beginning.
 * Consequently, if the vesting has already started, any amount of tokens sent to this contract will (at least partly)
 * be immediately releasable.
 */
contract TokenVesting is Context, Ownable {
    event ERC20Released(address indexed token, uint256 amount);
    event BeneficiaryAdded(address indexed beneficiary, uint256 amount);
    event ReleasableAmount(address indexed beneficiary, uint256 amount);

    struct BeneficiaryInfo {
        uint256 _allocationBalance;
        uint256 _allocationReleased;
        uint256 _unlockIntervalsCount; // Number of unlock intervals
    }

    IERC20 public vestedToken;

    address[] private _beneficiaryAddresses;
    mapping(address => BeneficiaryInfo) private _beneficiaryInfo;

    uint256 private immutable _start; // start timestamp in seconds
    uint256 private immutable _duration; // end timestamp in seconds

    // Duration of unlock intervals, i.e. 6 months in seconds = (60 * 60 * 24 * 365) / 2 = 15768000
    uint256 private immutable _unlockDurationSeconds;

    // Total WOM allocated amongst beneficiaries
    uint256 private _totalAllocationBalance;

    /**
     * @dev Set the vested token address, start timestamp and vesting duration of the vesting period.
     */
    constructor(
        address vestedTokenAddress,
        uint256 startTimestamp,
        uint256 durationSeconds,
        uint256 unlockDurationSeconds
    ) {
        vestedToken = IERC20(vestedTokenAddress);
        _start = startTimestamp;
        _duration = durationSeconds;
        _unlockDurationSeconds = unlockDurationSeconds;
    }

    /**
     * @dev Getter for the number of beneficiaries.
     */
    function beneficiaryCount() external view returns (uint8) {
        return uint8(_beneficiaryAddresses.length);
    }

    /**
     * @dev Getter for the beneficiary allocation balance.
     */
    function beneficiaryBalance(address beneficiary) external view returns (uint256) {
        return _beneficiaryInfo[beneficiary]._allocationBalance;
    }

    /**
     * @dev Getter for the total allocation balance of vesting contract.
     */
    function totalAllocationBalance() external view returns (uint256) {
        return _totalAllocationBalance;
    }

    /**
     * @dev Getter for the total WOM tokens allocated for vesting contract.
     */
    function totalUnderlyingBalance() external view returns (uint256) {
        return IERC20(vestedToken).balanceOf(address(this));
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of token already released for a beneficiary
     */
    function released(address beneficiary) public view returns (uint256) {
        return _beneficiaryInfo[beneficiary]._allocationReleased;
    }

    /**
     * @dev Setter for adding a beneficiary address.
     */
    function setBeneficiary(address beneficiary, uint256 allocation) external onlyOwner {
        require(beneficiary != address(0), 'Beneficiary: address cannot be zero');
        require(_beneficiaryInfo[beneficiary]._allocationBalance == 0, 'Beneficiary: allocation already set');
        _beneficiaryInfo[beneficiary] = BeneficiaryInfo(allocation, 0, 0);
        _totalAllocationBalance += allocation;
        _beneficiaryAddresses.push(beneficiary);
        emit BeneficiaryAdded(beneficiary, allocation);
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address beneficiary) external {
        uint256 releasable = vestedAmount(beneficiary, block.timestamp) - released(beneficiary);
        _beneficiaryInfo[beneficiary]._allocationReleased += releasable;
        _beneficiaryInfo[beneficiary]._allocationBalance -= releasable;
        _beneficiaryInfo[beneficiary]._unlockIntervalsCount = _calculateInterval(block.timestamp);
        emit ERC20Released(address(vestedToken), releasable);
        SafeERC20.safeTransfer(vestedToken, beneficiary, releasable);
    }

    /**
     * @dev Calculates the amount of WOM tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address beneficiary, uint256 timestamp) public view returns (uint256) {
        uint256 _vestedAmount = _vestingSchedule(
            beneficiary,
            _beneficiaryInfo[beneficiary]._allocationBalance + released(beneficiary),
            timestamp
        );
        return _vestedAmount;
    }

    /**
     * @dev implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     * 10% of the Total Number of Tokens Purchased shall unlock every 6 months from the Network Launch,
     * with the Total Number * of Tokens Purchased becoming fully unlocked 5 years from the Network Launch.
     * i.e. 6 months cliff from TGE, 10% unlock at month 6, 10% unlock at month 12, and final 10% unlock at month 60
     */
    function _vestingSchedule(
        address beneficiary,
        uint256 totalAllocation,
        uint256 timestamp
    ) internal view returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        }

        uint256 currentInterval = _calculateInterval(timestamp);
        return (totalAllocation * currentInterval) / 10;
    }

    /**
     * @dev Calculates the number of intervals unlocked
     */
    function _calculateInterval(uint256 timestamp) internal view returns (uint256) {
        if (timestamp < start()) {
            return 0;
        } else {
            return (timestamp - start()) / _unlockDurationSeconds;
        }
    }
}
