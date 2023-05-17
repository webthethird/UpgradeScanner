// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./NonTransferableERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract dMATIC is OwnableUpgradeable, NonTransferableERC20 {
    /**
     * Variables
     */

    address private _minter;

    /**
     * Events
     */

    event MinterChanged(address minter);

    /**
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == _minter, "Minter: not allowed");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
        __ERC20_init_unchained("Davos MATIC", "dMATIC");
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function changeMinter(address minter) external onlyOwner {
        require(minter != address(0));
        _minter = minter;
        emit MinterChanged(minter);
    }

    function getMinter() external view returns (address) {
        return _minter;
    }
}
