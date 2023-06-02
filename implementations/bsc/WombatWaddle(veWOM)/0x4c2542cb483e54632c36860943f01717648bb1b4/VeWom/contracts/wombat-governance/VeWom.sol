// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './libraries/DSMath.sol';
import './libraries/LogExpMath.sol';
import './interfaces/IWhitelist.sol';
import './interfaces/IMasterWombat.sol';
import './interfaces/IVeWom.sol';
import './VeERC20Upgradeable.sol';

/// @title VeWom
/// @notice Wombat Waddle: the staking contract for WOM, as well as the token used for governance.
/// Note Waddling does not seem to slow the Wombat, it only makes it sturdier.
/// Note that it's ownable and the owner wields tremendous power. The ownership
/// will be transferred to a governance smart contract once Wombat is sufficiently
/// distributed and the community can show to govern itself.
contract VeWom is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    VeERC20Upgradeable,
    IVeWom
{
    using SafeERC20 for IERC20;
    using DSMath for uint256;

    uint256 constant WAD = 1e18;

    /// @notice the wom token
    IERC20 public wom;

    /// @notice the masterWombat contract
    IMasterWombat public masterWombat;

    /// @notice whitelist wallet checker
    /// @dev contract addresses are by default unable to stake wom, they must be previously whitelisted to stake wom
    IWhitelist public whitelist;

    uint32 maxBreedingLength;
    uint32 minLockDays;
    uint32 maxLockDays;

    /// @notice user info mapping
    mapping(address => UserInfo) internal users;

    event Enter(address addr, uint256 unlockTime, uint256 womAmount, uint256 veWomAmount);
    event Exit(address addr, uint256 unlockTime, uint256 womAmount, uint256 veWomAmount);
    event SetMasterWombat(address addr);
    event SetWhiteList(address addr);
    event SetMaxBreedingLength(uint256 len);

    error VEWOM_OVERFLOW();

    function initialize(IERC20 _wom, IMasterWombat _masterWombat) external initializer {
        require(address(_masterWombat) != address(0), 'zero address');
        require(address(_wom) != address(0), 'zero address');

        // Initialize veWOM
        __ERC20_init('Wombat Waddle', 'veWOM');
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        masterWombat = _masterWombat;
        wom = _wom;

        // Note: one should pay attention to storage collision
        maxBreedingLength = 10000;
        minLockDays = 7;
        maxLockDays = 1461;
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice sets masterWombat address
    /// @param _masterWombat the new masterWombat address
    function setMasterWombat(IMasterWombat _masterWombat) external onlyOwner {
        require(address(_masterWombat) != address(0), 'zero address');
        masterWombat = _masterWombat;
        emit SetMasterWombat(address(_masterWombat));
    }

    /// @notice sets whitelist address
    /// @param _whitelist the new whitelist address
    function setWhitelist(IWhitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), 'zero address');
        whitelist = _whitelist;
        emit SetWhiteList(address(_whitelist));
    }

    function setMaxBreedingLength(uint256 _maxBreedingLength) external onlyOwner {
        if (_maxBreedingLength > type(uint32).max) revert VEWOM_OVERFLOW();
        maxBreedingLength = uint32(_maxBreedingLength);
        emit SetMaxBreedingLength(_maxBreedingLength);
    }

    /// @notice checks wether user _addr has wom staked
    /// @param _addr the user address to check
    /// @return true if the user has wom in stake, false otherwise
    function isUser(address _addr) external view override returns (bool) {
        return balanceOf(_addr) > 0;
    }

    function getUserInfo(address addr) external view override returns (UserInfo memory) {
        return users[addr];
    }

    /// @dev explicity override multiple inheritance
    function totalSupply() public view override(VeERC20Upgradeable, IVeWom) returns (uint256) {
        return super.totalSupply();
    }

    /// @dev explicity override multiple inheritance
    function balanceOf(address account) public view override(VeERC20Upgradeable, IVeWom) returns (uint256) {
        return super.balanceOf(account);
    }

    function _expectedVeWomAmount(uint256 amount, uint256 lockDays) internal pure returns (uint256) {
        // veWOM = 0.026 * lockDays^0.5
        return amount.wmul(26162237992630200).wmul(LogExpMath.pow(lockDays * WAD, 50e16));
    }

    /// @notice lock WOM into contract and mint veWOM
    function mint(uint256 amount, uint256 lockDays)
        external
        virtual
        override
        nonReentrant
        whenNotPaused
        returns (uint256 veWomAmount)
    {
        require(amount > 0, 'amount to deposit cannot be zero');
        if (amount > uint256(type(uint104).max)) revert VEWOM_OVERFLOW();

        // assert call is not coming from a smart contract
        // unless it is whitelisted
        _assertNotContract(msg.sender);

        require(lockDays >= uint256(minLockDays) && lockDays <= uint256(maxLockDays), 'lock days is invalid');
        require(users[msg.sender].breedings.length < uint256(maxBreedingLength), 'breed too much');

        uint256 unlockTime = block.timestamp + 86400 * lockDays; // seconds in a day = 86400
        veWomAmount = _expectedVeWomAmount(amount, lockDays);

        if (unlockTime > uint256(type(uint48).max)) revert VEWOM_OVERFLOW();
        if (veWomAmount > uint256(type(uint104).max)) revert VEWOM_OVERFLOW();

        users[msg.sender].breedings.push(Breeding(uint48(unlockTime), uint104(amount), uint104(veWomAmount)));

        // Request Wom from user
        wom.safeTransferFrom(msg.sender, address(this), amount);

        // event Mint(address indexed user, uint256 indexed amount) is emitted
        _mint(msg.sender, veWomAmount);

        emit Enter(msg.sender, unlockTime, amount, veWomAmount);
    }

    function burn(uint256 slot) external override nonReentrant whenNotPaused {
        uint256 length = users[msg.sender].breedings.length;
        require(slot < length, 'wut?');

        Breeding memory breeding = users[msg.sender].breedings[slot];
        require(uint256(breeding.unlockTime) <= block.timestamp, 'not yet meh');

        // remove slot
        if (slot != length - 1) {
            users[msg.sender].breedings[slot] = users[msg.sender].breedings[length - 1];
        }
        users[msg.sender].breedings.pop();

        wom.transfer(msg.sender, breeding.womAmount);

        // event Burn(address indexed user, uint256 indexed amount) is emitted
        _burn(msg.sender, breeding.veWomAmount);

        emit Exit(msg.sender, breeding.unlockTime, breeding.womAmount, breeding.veWomAmount);
    }

    /// @notice asserts addres in param is not a smart contract.
    /// @notice if it is a smart contract, check that it is whitelisted
    /// @param _addr the address to check
    function _assertNotContract(address _addr) private view {
        if (_addr != tx.origin) {
            require(
                address(whitelist) != address(0) && whitelist.check(_addr),
                'Smart contract depositors not allowed'
            );
        }
    }

    /// @notice hook called after token operation mint/burn
    /// @dev updates masterWombat
    /// @param _account the account being affected
    /// @param _newBalance the newVeWomBalance of the user
    function _afterTokenOperation(address _account, uint256 _newBalance) internal override {
        masterWombat.updateFactor(_account, _newBalance);
    }
}
