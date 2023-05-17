// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC1820RegistryUpgradeable.sol";
import "./interfaces/IFeeVault.sol";
import "./interfaces/IAddressStore.sol";
import "./interfaces/IStakedBNBToken.sol";

contract FeeVault is IFeeVault, IERC777RecipientUpgradeable, Initializable, OwnableUpgradeable {
    IERC1820RegistryUpgradeable private constant _ERC1820_REGISTRY =
        IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    /*********************
     * STATE VARIABLES
     ********************/

    /**
     * @dev addressStore: The Address Store. Used to fetch addresses of the other contracts in the system.
     */
    IAddressStore private _addressStore;

    /*********************
     * EVENTS
     ********************/

    event Deposit(address from, uint256 amount); // emitted when stkBNB is sent to this contract
    event Withdraw(address from, address to, uint256 amount); // emitted when stkBNB is claimed from this contract

    /*********************
     * ERRORS
     ********************/
    error UnstakingFeeTokensIsntSupported();
    error ReceivedUnknownToken();
    error UnexpectedSender(address from);
    error UnexpectedlyReceivedTokensForSomeoneElse(address to);

    /*********************
     * INIT FUNCTIONS
     ********************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IAddressStore addressStore_) public initializer {
        __FeeVault_init(addressStore_);
    }

    function __FeeVault_init(IAddressStore addressStore_) internal onlyInitializing {
        // Need to call initializers for each parent without calling anything twice.
        __Context_init_unchained();
        __Ownable_init_unchained();
        // Finally, initialize this contract.
        __FeeVault_init_unchained(addressStore_);
    }

    function __FeeVault_init_unchained(IAddressStore addressStore_) internal onlyInitializing {
        _addressStore = addressStore_;
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC777TokensRecipient"),
            address(this)
        );
    }

    /**
     * @dev claim: Called by a multisig account to transfer stkBNB from vault to another account.
     *
     * Requirements:
     * - Only owner can call
     */
    function claimStkBNB(address recipient, uint256 amount) external override onlyOwner {
        if (recipient == _addressStore.getStakePool()) {
            // No point supporting this, and make things complicated.
            // One can just send tokens to an EOA address, which can do the unstaking, if needed.
            revert UnstakingFeeTokensIsntSupported();
        }
        IStakedBNBToken(_addressStore.getStkBNB()).send(recipient, amount, "");

        emit Withdraw(msg.sender, recipient, amount);
    }

    /**
     * @dev tokensReceived: hook call while tokens transfer to this contract.
     *
     * Requirements:
     * - Only accept stkBNB token.
     * - Only accept minted tokens OR tokens transferred from StakePool contract.
     * - `to` should always be the address of this contract.
     */
    function tokensReceived(
        address, /*operator*/
        address from,
        address to,
        uint256 amount,
        bytes calldata, /*userData*/
        bytes calldata /*operatorData*/
    ) external override {
        if (msg.sender != _addressStore.getStkBNB()) {
            revert ReceivedUnknownToken();
        }
        if (from != address(0) && from != _addressStore.getStakePool()) {
            revert UnexpectedSender(from);
        }
        if (to != address(this)) {
            revert UnexpectedlyReceivedTokensForSomeoneElse(to);
        }

        emit Deposit(from, amount);
    }

    /**
     * @return the address store
     */
    function addressStore() external view returns (IAddressStore) {
        return _addressStore;
    }
}
