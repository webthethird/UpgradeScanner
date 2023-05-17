/**
 * File: ReentrancyGuard.sol
 */

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


/**
 * File: EIP20Interface.sol
 */

pragma solidity 0.6.12;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return success Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return  remaining The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}


/**
 * File: SafeMath.sol
 */

pragma solidity 0.6.12;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * File: QiTokenSaleDistributorProxyStorage.sol
 */

pragma solidity 0.6.12;


contract QiTokenSaleDistributorProxyStorage {
    // Current contract admin address
    address public admin;

    // Requested new admin for the contract
    address public pendingAdmin;

    // Current contract implementation address
    address public implementation;

    // Requested new contract implementation address
    address public pendingImplementation;
}


/**
 * File: QiTokenSaleDistributorStorage.sol
 */

pragma solidity 0.6.12;



contract QiTokenSaleDistributorStorage is QiTokenSaleDistributorProxyStorage {
    // Token release interval in seconds
    uint constant public releasePeriodLength = 2628000; // = 60 * 60 * 24 * 365 / 12 = 1 month

    // Block time when the purchased tokens were initially released for claiming
    uint constant public vestingScheduleEpoch = 1629356400;

    address public dataAdmin;

    address public qiContractAddress;

    // Number of release periods in the vesting schedule; i.e.,
    // releasePeriods * releasePeriodLength = vesting period length
    // address => purchase round => release periods
    mapping(address => mapping(uint => uint)) public releasePeriods;

    // The percentage of tokens released on vesting schedule start (0-100)
    // address => purchase round => initial release percentage
    mapping(address => mapping(uint => uint)) public initialReleasePercentages;

    // Total number of purchased QI tokens by user
    // address => purchase round => purchased tokens
    mapping(address => mapping(uint => uint)) public purchasedTokens;

    // Total number of claimed QI tokens by user
    // address => purchase round => claimed tokens
    mapping(address => mapping(uint => uint)) public claimedTokens;

    // Number of purchase rounds completed by the user
    mapping(address => uint) public completedPurchaseRounds;
}


/**
 * File: QiTokenSaleDistributorProxy.sol
 */

pragma solidity 0.6.12;



contract QiTokenSaleDistributorProxy is ReentrancyGuard, QiTokenSaleDistributorProxyStorage {
    constructor() public {
        admin = msg.sender;
    }

    /**
     * Request a new admin to be set for the contract.
     *
     * @param newAdmin New admin address
     */
    function setPendingAdmin(address newAdmin) public adminOnly {
        pendingAdmin = newAdmin;
    }

    /**
     * Accept admin transfer from the current admin to the new.
     */
    function acceptPendingAdmin() public {
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Caller must be the pending admin");

        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /**
     * Request a new implementation to be set for the contract.
     *
     * @param newImplementation New contract implementation contract address
     */
    function setPendingImplementation(address newImplementation) public adminOnly {
        pendingImplementation = newImplementation;
    }

    /**
     * Accept pending implementation change
     */
    function acceptPendingImplementation() public {
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "Only the pending implementation contract can call this");

        implementation = pendingImplementation;
        pendingImplementation = address(0);
    }

    fallback() payable external {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(free_mem_ptr, 0, size)

            switch success
            case 0 { revert(free_mem_ptr, size) }
            default { return(free_mem_ptr, size) }
        }
    }

    /********************************************************
     *                                                      *
     *                      MODIFIERS                       *
     *                                                      *
     ********************************************************/

    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}


/**
 * File: QiTokenSaleDistributor.sol
 */

pragma solidity 0.6.12;



contract QiTokenSaleDistributor is ReentrancyGuard, QiTokenSaleDistributorStorage {
    using SafeMath for uint256;

    event Claim(address recipient, uint amount);

    constructor() public {
        admin = msg.sender;
    }


    /********************************************************
     *                                                      *
     *                   PUBLIC FUNCTIONS                   *
     *                                                      *
     ********************************************************/

    /*
     * Claim all available tokens for the invoking user.
     */
    function claim() public nonReentrant {
        uint availableTokensToClaim = 0;
        for (uint round = 0; round < completedPurchaseRounds[msg.sender]; round += 1) {
            uint claimableRoundTokens = _getClaimableTokenAmountPerRound(msg.sender, round);
            availableTokensToClaim = availableTokensToClaim.add(claimableRoundTokens);
            claimedTokens[msg.sender][round] = claimedTokens[msg.sender][round].add(claimableRoundTokens);
        }

        require(availableTokensToClaim > 0, "No available tokens to claim");

        EIP20Interface qi = EIP20Interface(qiContractAddress);
        qi.transfer(msg.sender, availableTokensToClaim);

        emit Claim(msg.sender, availableTokensToClaim);
    }

    /**
     * Get the amount of QI tokens available for the caller to claim.
     *
     * @return Number of QI tokens available for claiming
     */
    function getClaimableTokenAmount() public view returns (uint) {
        return _getClaimableTokenAmount(msg.sender);
    }

    /**
     * Get the amount of QI tokens available for the caller to claim from
     * the given purchase round.
     *
     * @param round Purchase round number
     * @return Number of QI tokens available for claiming from the given round
     */
    function getRoundClaimableTokenAmount(uint round) public view returns (uint) {
        return _getClaimableTokenAmountPerRound(msg.sender, round);
    }

    /**
     * Get the total number of claimed tokens by the user.
     *
     * @return Number of claimed QI tokens
     */
    function getClaimedTokenAmount() public view returns (uint) {
        uint claimedTokenAmount = 0;
        for (uint round = 0; round < completedPurchaseRounds[msg.sender]; round += 1) {
            claimedTokenAmount = claimedTokenAmount.add(claimedTokens[msg.sender][round]);
        }

        return claimedTokenAmount;
    }

    /**
     * Get the number of claimed tokens in a specific round by the user.
     *
     * @param round Purchase round number
     * @return Number of claimed QI tokens
     */
    function getRoundClaimedTokenAmount(uint round) public view returns (uint) {
        return claimedTokens[msg.sender][round];
    }

    /********************************************************
     *                                                      *
     *               ADMIN-ONLY FUNCTIONS                   *
     *                                                      *
     ********************************************************/

    /**
     * Set the QI token contract address.
     *
     * @param newQiContractAddress New address of the QI token contract
     */
    function setQiContractAddress(address newQiContractAddress) public adminOnly {
        qiContractAddress = newQiContractAddress;
    }

    /**
     * Set the amount of purchased QI tokens per user.
     *
     * @param recipients QI token recipients
     * @param rounds Purchase round number
     * @param tokenInitialReleasePercentages Initial token release percentages
     * @param tokenReleasePeriods Number of token release periods
     * @param amounts Purchased token amounts
     */
    function setPurchasedTokensByUser(
        address[] memory recipients,
        uint[] memory rounds,
        uint[] memory tokenInitialReleasePercentages,
        uint[] memory tokenReleasePeriods,
        uint[] memory amounts
    )
        public
        adminOrDataAdminOnly
    {
        require(recipients.length == rounds.length);
        require(recipients.length == tokenInitialReleasePercentages.length);
        require(recipients.length == tokenReleasePeriods.length);
        require(recipients.length == amounts.length);

        for (uint i = 0; i < recipients.length; i += 1) {
            address recipient = recipients[i];

            require(tokenInitialReleasePercentages[i] <= 100, "Invalid percentage");
            require(rounds[i] == completedPurchaseRounds[recipient], "Invalid round number");

            initialReleasePercentages[recipient][rounds[i]] = tokenInitialReleasePercentages[i].mul(1e18);
            releasePeriods[recipient][rounds[i]] = tokenReleasePeriods[i];
            purchasedTokens[recipient][rounds[i]] = amounts[i];
            completedPurchaseRounds[recipient] = rounds[i] + 1;
            claimedTokens[recipient][rounds[i]] = tokenInitialReleasePercentages[i].mul(1e18).mul(amounts[i]).div(100e18);
        }
    }

    /**
     * Reset all data for the given addresses.
     *
     * @param recipients Addresses whose data to reset
     */
    function resetPurchasedTokensByUser(address[] memory recipients) public adminOrDataAdminOnly {
        for (uint i = 0; i < recipients.length; i += 1) {
            address recipient = recipients[i];

            for (uint round = 0; round < completedPurchaseRounds[recipient]; round += 1) {
                initialReleasePercentages[recipient][round] = 0;
                releasePeriods[recipient][round] = 0;
                purchasedTokens[recipient][round] = 0;
                claimedTokens[recipient][round] = 0;
            }

            completedPurchaseRounds[recipient] = 0;
        }
    }

    /**
     * Withdraw deposited QI tokens from the contract.
     *
     * @param amount QI amount to withdraw from the contract balance
     */
    function withdrawQi(uint amount) public adminOnly {
        EIP20Interface qi = EIP20Interface(qiContractAddress);
        qi.transfer(msg.sender, amount);
    }

    /**
     * Accept this contract as the implementation for a proxy.
     *
     * @param proxy QiTokenSaleDistributorProxy
     */
    function becomeImplementation(QiTokenSaleDistributorProxy proxy) external {
        require(msg.sender == proxy.admin(), "Only proxy admin can change the implementation");
        proxy.acceptPendingImplementation();
    }

    /**
     * Set the data admin.
     *
     * @param newDataAdmin New data admin address
     */
    function setDataAdmin(address newDataAdmin) public adminOnly {
        dataAdmin = newDataAdmin;
    }


    /********************************************************
     *                                                      *
     *                  INTERNAL FUNCTIONS                  *
     *                                                      *
     ********************************************************/

    /**
     * Get the number of claimable QI tokens for a user at the time of calling.
     *
     * @param recipient Claiming user
     * @return Number of QI tokens
     */
    function _getClaimableTokenAmount(address recipient) internal view returns (uint) {
        if (completedPurchaseRounds[recipient] == 0) {
            return 0;
        }

        uint remainingClaimableTokensToDate = 0;
        for (uint round = 0; round < completedPurchaseRounds[recipient]; round += 1) {
            uint remainingRoundClaimableTokensToDate = _getClaimableTokenAmountPerRound(recipient, round);
            remainingClaimableTokensToDate = remainingClaimableTokensToDate.add(remainingRoundClaimableTokensToDate);
        }

        return remainingClaimableTokensToDate;
    }

    /**
     * Get the number of claimable QI tokens from a specific purchase round
     * for a user at the time of calling.
     *
     * @param recipient Recipient address
     * @param round Purchase round number
     * @return Available tokens to claim from the round
     */
    function _getClaimableTokenAmountPerRound(address recipient, uint round) internal view returns (uint) {
        require(round < completedPurchaseRounds[recipient], "Invalid round");

        if (completedPurchaseRounds[recipient] == 0) {
            return 0;
        }

        uint initialClaimableTokens = initialReleasePercentages[recipient][round].mul(purchasedTokens[recipient][round]).div(100e18);

        uint elapsedSecondsSinceEpoch = block.timestamp.sub(vestingScheduleEpoch);
        // Number of elapsed release periods after the initial release
        uint elapsedVestingReleasePeriods = elapsedSecondsSinceEpoch.div(releasePeriodLength);

        uint claimableTokensToDate = 0;
        if (elapsedVestingReleasePeriods.add(1) >= releasePeriods[recipient][round]) {
            claimableTokensToDate = purchasedTokens[recipient][round];
        } else {
            uint claimableTokensPerPeriod = purchasedTokens[recipient][round].sub(initialClaimableTokens).div(releasePeriods[recipient][round].sub(1));
            claimableTokensToDate = claimableTokensPerPeriod.mul(elapsedVestingReleasePeriods).add(initialClaimableTokens);
            if (claimableTokensToDate > purchasedTokens[recipient][round]) {
                claimableTokensToDate = purchasedTokens[recipient][round];
            }
        }

        uint remainingClaimableTokensToDate = claimableTokensToDate.sub(claimedTokens[recipient][round]);

        return remainingClaimableTokensToDate;
    }


    /********************************************************
     *                                                      *
     *                      MODIFIERS                       *
     *                                                      *
     ********************************************************/

    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }

    modifier adminOrDataAdminOnly {
        require(msg.sender == admin || (dataAdmin != address(0) && msg.sender == dataAdmin), "admin only");
        _;
    }
}