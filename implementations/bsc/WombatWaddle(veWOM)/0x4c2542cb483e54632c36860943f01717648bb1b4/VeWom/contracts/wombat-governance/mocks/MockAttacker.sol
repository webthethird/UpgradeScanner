// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '../interfaces/IVeWom.sol';
import '../interfaces/IWom.sol';

contract MockAttacker {
    IVeWom public veWom;
    IWom public wom;

    constructor(IWom _wom, IVeWom _veWom) {
        wom = _wom;
        veWom = _veWom;
    }

    function mint(uint256 amount, uint256 lockDays) public {
        veWom.mint(amount, lockDays);
    }

    function approve(uint256 _amount) public {
        wom.approve(address(veWom), _amount);
    }
}
