// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../VeWom.sol';
import '../MasterWombat.sol';

contract MockVeWom is Initializable, VeWom {
    function faucet(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }

    function mint(uint256 amount, uint256 lockDays) external override returns (uint256 veWomAmount) {
        _mint(msg.sender, amount);
    }

    // burn is already declared in VeWom.sol
    function burn2(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
