// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { LibArrayUtils } from "./libraries/LibArrayUtils.sol";
import { LibAavegotchiUtils } from "./libraries/LibAavegotchiUtils.sol";
import { IAavegotchiDiamond, TokenIdsWithKinship } from "./interfaces/IAavegotchiDiamond.sol";

contract AavegotchiOperator is OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    struct AavegotchiOwner {
        address owner;
        bool isApproved;
        uint32[] tokenIds;
    }

    uint256 public _maxNumberOfAavegotchis;
    address public _aavegotchiDiamondAddress;
    address public _gelatoAddress;
    EnumerableSet.AddressSet private _approvedAddresses;

    event EnablePetOperator(address indexed owner);
    event DisablePetOperator(address indexed owner);
    event InteractAavegotchis(uint256[] tokenIds);

    mapping(address => bool) public _gelatoAddresses;
    uint256 public _lastPetBlockNumber;
    
    modifier onlyGelato() {
        require(_gelatoAddresses[msg.sender] || msg.sender == _gelatoAddress, "Only Gelato can invoke this function");
        _;
    }

    // @notice Proxy initializer function. Should be only callable once
    // @param aavegotchiDiamondContract The aavegotchi diamond contract
    // @param max_number_aavegotchis Maximum number of aavegotchis pet at a time
    // @param gelatoOps address for gelato executors smart contracts
    function initialize(address aavegotchiDiamondContract, uint256 max_number_aavegotchis, address gelatoAddress) public initializer {
        _gelatoAddress = gelatoAddress;
        _maxNumberOfAavegotchis = max_number_aavegotchis;
        _aavegotchiDiamondAddress = aavegotchiDiamondContract;
        __Ownable_init_unchained();
    }

    // @notice Fetch all approved and revoked addresses
    // @return approvedAddresses_ The list of approved addresses
    function listApprovedAddresses() external view returns (address[] memory approvedAddresses_) {
        address[] memory enabledAddresses = listEnabledAddresses();
        address[] memory approvedAddresses = new address[](enabledAddresses.length);
        uint256 numberOfApprovedAddresses;
        for (uint256 i; i < enabledAddresses.length; i++) {
            address enabledAddress = enabledAddresses[i];
            bool isApproved = IAavegotchiDiamond(_aavegotchiDiamondAddress).isPetOperatorForAll(enabledAddress, address(this));
            if (isApproved) {
                approvedAddresses[numberOfApprovedAddresses] = enabledAddress;
                numberOfApprovedAddresses++;
            }
        }
        approvedAddresses_ = LibArrayUtils.shortenArray(approvedAddresses, numberOfApprovedAddresses);
    }

    // @notice Fetch all approved and revoked addresses
    // @return revokedAddresses_ The list of revoked addresses
    function listRevokedAddresses() external view returns (address[] memory revokedAddresses_) {
        address[] memory enabledAddresses = listEnabledAddresses();
        address[] memory revokedAddresses = new address[](enabledAddresses.length);
        uint256 numberOfRevokedAddresses;
        for (uint256 i; i < enabledAddresses.length; i++) {
            address enabledAddress = enabledAddresses[i];
            bool isApproved = IAavegotchiDiamond(_aavegotchiDiamondAddress).isPetOperatorForAll(enabledAddress, address(this));
            if (!isApproved) {
                revokedAddresses[numberOfRevokedAddresses] = enabledAddress;
                numberOfRevokedAddresses++;
            }
        }
        revokedAddresses_ = LibArrayUtils.shortenArray(revokedAddresses, numberOfRevokedAddresses);
    }


    // @notice Retrieve the token ids of all aavegotchis to pet, and list all address to remove. The number of aavegotchis is capped to fit in a single transaction
    // @return tokenIds_ The token ids of all aavegotchis to pet
    // @return revokedAddresses_ The addresses that revoked pet approvals
    function listAavegotchisToPetAndAddressesToRemove() external view returns (uint256[] memory tokenIds_, address[] memory revokedAddresses_) {
        uint256 numberOfAavegotchis;
        uint256 numberOfRevokedAddresses;
        uint256 numberOfApprovedAddresses;
        address[] memory enabledAddresses = listEnabledAddresses();
        address[] memory revokedAddresses = new address[](enabledAddresses.length);
        uint256[][] memory tokenIdsOfOwners = new uint256[][](enabledAddresses.length);
        IAavegotchiDiamond aavegotchiDiamond = IAavegotchiDiamond(_aavegotchiDiamondAddress);
        for (uint256 i; i < enabledAddresses.length && numberOfAavegotchis < _maxNumberOfAavegotchis; i++) {
            address enabledAddress = enabledAddresses[i];
            bool isApproved = aavegotchiDiamond.isPetOperatorForAll(enabledAddress, address(this));
            if (isApproved == false) {
                revokedAddresses[numberOfRevokedAddresses] = enabledAddress;
                numberOfRevokedAddresses++;
            } else {
                uint256 aavegotchiCounter;
                TokenIdsWithKinship[] memory aavegotchis = aavegotchiDiamond.tokenIdsWithKinship(enabledAddress, 0, 0, true);
                uint256[] memory tokenIds = new uint256[](aavegotchis.length);
                for (uint256 j; j < aavegotchis.length && numberOfAavegotchis < _maxNumberOfAavegotchis; j++) {
                    TokenIdsWithKinship memory info = aavegotchis[j];
                    if (info.tokenId != 0 && LibAavegotchiUtils.isAavegotchiPetAble(info.lastInteracted) == true) {
                        tokenIds[aavegotchiCounter] = info.tokenId;
                        aavegotchiCounter++;
                        numberOfAavegotchis++;
                    }
                }
                tokenIdsOfOwners[numberOfApprovedAddresses] = LibArrayUtils.shortenArray(tokenIds, aavegotchiCounter);
                numberOfApprovedAddresses++;
            }
        }

        uint tokenIdCounter;
        tokenIds_ = new uint256[](numberOfAavegotchis);
        for (uint256 i; i < numberOfApprovedAddresses; i++) {
            uint256[] memory tokenIds = tokenIdsOfOwners[i];
            for (uint256 j; j < tokenIds.length; j++) {
                uint256 tokenId = tokenIds[j];
                tokenIds_[tokenIdCounter] = tokenId;
                tokenIdCounter++;
            }
        }

        revokedAddresses_ = LibArrayUtils.shortenArray(revokedAddresses, numberOfRevokedAddresses);
    }

    // @notice Pet aavegotchis
    // @param tokenIds Array of aavegotchi token ids that are going to be pet
    // @dev Emits event InteractAavegotchis
    function petAavegotchis(uint256[] calldata tokenIds) external {
        IAavegotchiDiamond(_aavegotchiDiamondAddress).interact(tokenIds);
        emit InteractAavegotchis(tokenIds);
        _lastPetBlockNumber = block.number;
    }

    // @notice Pet aavegotchis of approved addresses and remove those that revoked
    // @param tokenIds Array of aavegotchi token ids that are going to be pet
    // @param revokedAddresses Array of address that are going to be removed from the approvals set
    // @dev Emits event InteractAavegotchis
    function petAavegotchisAndRemoveRevoked(uint256[] calldata tokenIds, address[] calldata revokedAddresses) external onlyGelato {
        IAavegotchiDiamond aavegotchiDiamond = IAavegotchiDiamond(_aavegotchiDiamondAddress);
        if (tokenIds.length > 0) {
            aavegotchiDiamond.interact(tokenIds);
            emit InteractAavegotchis(tokenIds);
            _lastPetBlockNumber = block.number;
        }
        for (uint256 i; i < revokedAddresses.length; i++) {
            address revokedAddress = revokedAddresses[i];
            bool isApproved = aavegotchiDiamond.isPetOperatorForAll(revokedAddress, address(this));
            if (isApproved == false) {
                disablePetOperatorForOwner(revokedAddress);
            }
        }
    }

    // @notice Enable this contract to pet all msg.sender aavegotchis
    // @dev Emits EnablePetOperator
    function enablePetOperator() external {
        IAavegotchiDiamond aavegotchiDiamond = IAavegotchiDiamond(_aavegotchiDiamondAddress);
        bool isApproved = aavegotchiDiamond.isPetOperatorForAll(msg.sender, address(this));
        require(isApproved == true, "AavegotchiOperator is not approved, please call setPetOperatorForAll");
        EnumerableSet.add(_approvedAddresses, msg.sender);
        emit EnablePetOperator(msg.sender);
    }

    // @notice Remove this contract's ability to pet msg.sender aavegotchis
    // @dev Emits DisablePetOperator if msg.sender was removed
    // @return true if msg.sender was removed
    function disablePetOperator() external {
        disablePetOperatorForOwner(msg.sender);
    }

    // @notice Remove this contract's ability to pet owner's aavegotchis
    // @dev Emits DisablePetOperator if owner was removed
    // @param owner The address approved for petting
    // @return true if msg.sender was removed
    function disablePetOperatorForOwner(address owner) private {
        bool removed = EnumerableSet.remove(_approvedAddresses, owner);
        if (removed == true) {
            emit DisablePetOperator(owner);
        }
    }

    // @notice Lists all address this contract is able to interact
    // @return approvedAddresses_ array of approved addresses
    function listEnabledAddresses() public view returns (address[] memory approvedAddresses_) {
        approvedAddresses_ = EnumerableSet.values(_approvedAddresses);
    }

    // @notice Changes Gelato address
    // @dev array length must be the same
    // @param address array of gelatoAddress Gelato addresses
    // @param bool array for addresses to be enabled or disabled
    function setGelatoAddresses(address[] calldata gelatoAddress, bool[] calldata isValid) public onlyOwner {
        require(gelatoAddress.length == isValid.length, "AavegotchiOperator: array length mismatch");
        for(uint256 i; i < gelatoAddress.length; i++) {
            _gelatoAddresses[gelatoAddress[i]] = isValid[i];
        }
    }

    function getLastPetBlockNumber() external view returns (uint256) {
        return _lastPetBlockNumber;
    }

}
