// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {AbacusConnectionClient} from "./AbacusConnectionClient.sol";
import {IAbacusConnectionManager} from "@abacus-network/core/interfaces/IAbacusConnectionManager.sol";
import {IInterchainGasPaymaster} from "@abacus-network/core/interfaces/IInterchainGasPaymaster.sol";
import {IMessageRecipient} from "@abacus-network/core/interfaces/IMessageRecipient.sol";
import {IOutbox} from "@abacus-network/core/interfaces/IOutbox.sol";

abstract contract Router is AbacusConnectionClient, IMessageRecipient {
    // ============ Mutable Storage ============

    mapping(uint32 => bytes32) public routers;
    uint256[49] private __GAP; // gap for upgrade safety

    // ============ Events ============

    /**
     * @notice Emitted when a router is set.
     * @param domain The domain of the new router
     * @param router The address of the new router
     */
    event RemoteRouterEnrolled(uint32 indexed domain, bytes32 indexed router);

    // ============ Modifiers ============
    /**
     * @notice Only accept messages from a remote Router contract
     * @param _origin The domain the message is coming from
     * @param _router The address the message is coming from
     */
    modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
        require(_isRemoteRouter(_origin, _router), "!router");
        _;
    }

    // ======== Initializer =========
    function __Router_initialize(address _abacusConnectionManager)
        internal
        onlyInitializing
    {
        __AbacusConnectionClient_initialize(_abacusConnectionManager);
    }

    function __Router_initialize(
        address _abacusConnectionManager,
        address _interchainGasPaymaster
    ) internal onlyInitializing {
        __AbacusConnectionClient_initialize(
            _abacusConnectionManager,
            _interchainGasPaymaster
        );
    }

    // ============ External functions ============

    /**
     * @notice Register the address of a Router contract for the same Application on a remote chain
     * @param _domain The domain of the remote Application Router
     * @param _router The address of the remote Application Router
     */
    function enrollRemoteRouter(uint32 _domain, bytes32 _router)
        external
        virtual
        onlyOwner
    {
        _enrollRemoteRouter(_domain, _router);
    }

    /**
     * @notice Handles an incoming message
     * @param _origin The origin domain
     * @param _sender The sender address
     * @param _message The message
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) external virtual override onlyInbox onlyRemoteRouter(_origin, _sender) {
        // TODO: callbacks on success/failure
        _handle(_origin, _sender, _message);
    }

    // ============ Virtual functions ============
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) internal virtual;

    // ============ Internal functions ============

    /**
     * @notice Set the router for a given domain
     * @param _domain The domain
     * @param _router The new router
     */
    function _enrollRemoteRouter(uint32 _domain, bytes32 _router) internal {
        routers[_domain] = _router;
        emit RemoteRouterEnrolled(_domain, _router);
    }

    /**
     * @notice Return true if the given domain / router is the address of a remote Application Router
     * @param _domain The domain of the potential remote Application Router
     * @param _router The address of the potential remote Application Router
     */
    function _isRemoteRouter(uint32 _domain, bytes32 _router)
        internal
        view
        returns (bool)
    {
        return routers[_domain] == _router;
    }

    /**
     * @notice Assert that the given domain has a Application Router registered and return its address
     * @param _domain The domain of the chain for which to get the Application Router
     * @return _router The address of the remote Application Router on _domain
     */
    function _mustHaveRemoteRouter(uint32 _domain)
        internal
        view
        returns (bytes32 _router)
    {
        _router = routers[_domain];
        require(_router != bytes32(0), "!router");
    }

    /**
     * @notice Dispatches a message to an enrolled router via the local router's Outbox.
     * @notice Does not pay interchain gas.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _msg The message to dispatch.
     */
    function _dispatch(uint32 _destinationDomain, bytes memory _msg)
        internal
        returns (uint256)
    {
        return _dispatch(_outbox(), _destinationDomain, _msg);
    }

    /**
     * @notice Dispatches a message to an enrolled router via the local router's Outbox
     * and pays for it to be relayed to the destination.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _msg The message to dispatch.
     * @param _gasPayment The amount of native tokens to pay for the message to be relayed.
     */
    function _dispatchWithGas(
        uint32 _destinationDomain,
        bytes memory _msg,
        uint256 _gasPayment
    ) internal {
        IOutbox _outbox = _outbox();
        uint256 _leafIndex = _dispatch(_outbox, _destinationDomain, _msg);
        if (_gasPayment > 0) {
            interchainGasPaymaster.payGasFor{value: _gasPayment}(
                address(_outbox),
                _leafIndex,
                _destinationDomain
            );
        }
    }

    // ============ Private functions ============

    /**
     * @notice Dispatches a message to an enrolled router via the provided Outbox.
     * @dev Does not pay interchain gas.
     * @dev Reverts if there is no enrolled router for _destinationDomain.
     * @param _outbox The outbox contract to dispatch the message through.
     * @param _destinationDomain The domain of the chain to which to send the message.
     * @param _msg The message to dispatch.
     */
    function _dispatch(
        IOutbox _outbox,
        uint32 _destinationDomain,
        bytes memory _msg
    ) private returns (uint256) {
        // Ensure that destination chain has an enrolled router.
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return _outbox.dispatch(_destinationDomain, _router, _msg);
    }
}
