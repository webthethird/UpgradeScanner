/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/presets/ERC20PresetMinterPauserUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract InsurAceToken is ERC20PresetMinterPauserUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    mapping(address => uint256) public transferFromAllowedList;
    address[] public membersFrom;

    mapping(address => address) public delegates;
    mapping(address => uint256) public numCheckpoints;
    struct Checkpoint {
        uint256 fromBlock;
        uint256 votes;
    }
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    function initializeINSUR() public initializer {
        super.initialize("InsurAce", "INSUR");
        uint256 totalAmount = (10**18) * (10**8);
        _mint(_msgSender(), totalAmount);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "onlyAdmin");
        _;
    }

    function addSender(address _from) external onlyAdmin {
        if (1 == transferFromAllowedList[_from]) {
            return;
        }
        membersFrom.push(_from);
        transferFromAllowedList[_from] = 1;
    }

    function getSenders() external view onlyAdmin returns (address[] memory) {
        return membersFrom;
    }

    function removeSender(address _from) external onlyAdmin {
        uint256 arrayLength = membersFrom.length;
        uint256 indexToBeDeleted;
        bool toDelete = false;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (membersFrom[i] == _from) {
                indexToBeDeleted = i;
                toDelete = true;
                break;
            }
        }
        if (!toDelete) {
            return;
        }
        // if index to be deleted is not the last index, swap position.
        if (indexToBeDeleted < arrayLength - 1) {
            membersFrom[indexToBeDeleted] = membersFrom[arrayLength - 1];
        }
        // we can now reduce the array length by 1
        membersFrom.pop();
        delete transferFromAllowedList[_from];
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);
        require(_validSender(_from), "InsurAceToken: invalid sender");
        _moveDelegates(delegates[_from], delegates[_to], _amount);
    }

    function _validSender(address _from) private view returns (bool) {
        if (membersFrom.length == 0) {
            return true;
        }
        if (1 == transferFromAllowedList[_from]) {
            return true;
        }
        return false;
    }

    function delegate(address _delegatee) external {
        return _delegate(_msgSender(), _delegatee);
    }

    event DelegateChanged(address indexed _delegator, address indexed _fromDelegate, address indexed _toDelegate);

    function _delegate(address _delegator, address _delegatee) private {
        address currentDelegate = delegates[_delegator];
        uint256 delegatorBalance = balanceOf(_delegator);
        delegates[_delegator] = _delegatee;

        emit DelegateChanged(_delegator, currentDelegate, _delegatee);

        _moveDelegates(currentDelegate, _delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address _srcRep,
        address _dstRep,
        uint256 _amount
    ) private {
        if (_srcRep != _dstRep && _amount > 0) {
            if (_srcRep != address(0)) {
                uint256 srcRepNum = numCheckpoints[_srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[_srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(_amount);

                _writeCheckpoint(_srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (_dstRep != address(0)) {
                uint256 dstRepNum = numCheckpoints[_dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[_dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(_amount);

                _writeCheckpoint(_dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function _writeCheckpoint(
        address _delegatee,
        uint256 _nCheckpoints,
        uint256 _oldVotes,
        uint256 _newVotes
    ) private {
        uint256 blockNumber = block.number;

        if (_nCheckpoints > 0 && checkpoints[_delegatee][_nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[_delegatee][_nCheckpoints - 1].votes = _newVotes;
        } else {
            checkpoints[_delegatee][_nCheckpoints] = Checkpoint(blockNumber, _newVotes);
            numCheckpoints[_delegatee] = _nCheckpoints + 1;
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    function getPriorVotes(address _account, uint256 _blockNumber) public view returns (uint256) {
        require(_blockNumber < block.number, "INSUR::GPV:1");

        uint256 nCheckpoints = numCheckpoints[_account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][nCheckpoints - 1].fromBlock <= _blockNumber) {
            return checkpoints[_account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].fromBlock > _blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints.sub(1);
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.fromBlock == _blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }
}
