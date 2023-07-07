// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

error RouterContext_Not_A_Contract();

/**
 * @title Enables a trusted router contract to override the usual msg.sender address.
 * @author HardlyDifficult
 */
abstract contract RouterContext is ContextUpgradeable {
  using AddressUpgradeable for address;

  address private immutable approvedRouter;

  constructor(address router) {
    if (!router.isContract()) {
      revert RouterContext_Not_A_Contract();
    }
    approvedRouter = router;
  }

  /**
   * @notice Returns the router contract which is able to override the msg.sender address.
   * @return router The address of the trusted router.
   */
  function getApprovedRouterAddress() external view returns (address router) {
    router = approvedRouter;
  }

  /**
   * @notice Returns the sender of the transaction.
   * @dev If the msg.sender is the trusted router contract, then the last 20 bytes of the calldata is the authorized
   * sender.
   */
  function _msgSender() internal view virtual override returns (address sender) {
    sender = super._msgSender();
    if (sender == approvedRouter) {
      assembly {
        // The router appends the msg.sender to the end of the calldata
        // source: https://github.com/opengsn/gsn/blob/v3.0.0-beta.3/packages/contracts/src/ERC2771Recipient.sol#L48
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
  }
}
