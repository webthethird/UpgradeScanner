// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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

// File: contracts/earnV2/tokens/StrategyToken.sol

pragma solidity 0.6.12;




abstract contract StrategyToken is ERC20, ReentrancyGuard, Ownable {
    address public token;

    address public govAddress;

    uint256 public entranceFeeNumer;

    uint256 public entranceFeeDenom;

    bool public depositPaused;

    bool public withdrawPaused;
}

// File: contracts/earnV2/tokens/MultiStrategyTokenStorage.sol

pragma solidity 0.6.12;


abstract contract MultiStrategyTokenStorage is StrategyToken {
    // bsc wbnb
    address public constant wbnbAddress =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // heco wht
    // address public constant wbnbAddress =
    //     0x5545153CCFcA01fbd7Dd11C0b23ba694D9509A6F;

    bool public isWbnb;

    address[] public strategies;

    mapping(address => uint256) public ratios;

    mapping (address => bool) public depositActive;
    
    mapping (address => bool) public withdrawActive;
    
    uint256 public depositActiveCount;
    
    uint256 public withdrawActiveCount;

    uint256 public ratioTotal;

    uint256 public rebalanceThresholdNumer;

    uint256 public rebalanceThresholdDenom;

    address public bnbHelper;

    address public policyAdmin;
}

// File: contracts/interfaces/Wrapped.sol

pragma solidity 0.6.12;


// do not inherit these interfaces 

interface Wrapped is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

interface IWBNB is Wrapped {
}

interface IWHT is Wrapped {
}


interface IUnwrapper {
    function unwrapBNB(uint256) external;
}

// File: contracts/interfaces/IStrategyToken.sol

pragma solidity 0.6.12;


// do not inherit these interfaces 

interface IStrategyToken is IERC20 {    
    function balance() external view returns (uint256);
    function balanceStrategy() external view returns (uint256);
    function calcPoolValueInToken() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function sharesToAmount(uint256 _shares) external view returns (uint256);
    function amountToShares(uint256 _amount) external view returns (uint256);
    function isWbnb() external view returns (bool);
    function token() external view returns (address);
    function govAddress() external view returns (address);
    function entranceFeeNumer() external view returns (uint256);
    function entranceFeeDenom() external view returns (uint256);
    function depositPaused() external view returns (bool);
    function withdrawPaused() external view returns (bool);

    
    function deposit(uint256 _amount, uint256 _minShares) external;
    function withdraw(uint256 _shares, uint256 _minAmount) external;

    function setGovAddress(address _govAddress) external;
    function pauseDeposit() external;
    function unpauseDeposit() external;
    function pauseWithdraw() external;
    function unpauseWithdraw() external;
}


interface ISingleStrategyToken is IStrategyToken {
    function strategy() external view returns (address);

    function supplyStrategy() external;
    function updateStrategy() external;
    function setEntranceFee(uint256 _entranceFeeNumer, uint256 _entranceFeeDenom) external;
}

interface ISingleStrategyToken2 is IStrategyToken {
    function strategy() external view returns (address);

    function updateStrategy() external;
}

interface IMultiStrategyToken is IStrategyToken {
    function strategies(uint256 idx) external view returns (address);
    function depositActiveCount() external view returns (uint256);
    function withdrawActiveCount() external view returns (uint256);
    function strategyCount() external view returns (uint256);
    function ratios(address _strategy) external view returns (uint256);
    function depositActive(address _strategy) external view returns (bool);
    function withdrawActive(address _strategy) external view returns (bool);
    function ratioTotal() external view returns (uint256);
    function findMostOverLockedStrategy(uint256 withdrawAmt) external view returns (address, uint256);
    function findMostLockedStrategy() external view returns (address, uint256);
    function findMostInsufficientStrategy() external view returns (address, uint256);
    function getBalanceOfOneStrategy(address strategyAddress) external view returns (uint256 bal);

    // doesn"t guarantee that withdrawing shares returned by this function will always be successful.
    function getMaxWithdrawableShares() external view returns (uint256);

    
    function setPolicyAdmin(address _policyAdmin) external;
    function rebalance() external;
    function changeRatio(uint256 index, uint256 value) external;
    function setStrategyActive(uint256 index, bool isDeposit, bool b) external;
    function setRebalanceThreshold(uint256 _rebalanceThresholdNumer, uint256 _rebalanceThresholdDenom) external;
    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external;
    function updateAllStrategies() external;
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/earnV2/tokens/MultiStrategyTokenImpl.sol

pragma solidity 0.6.12;








contract MultiStrategyTokenImpl is MultiStrategyTokenStorage {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    event Deposit(address tokenAddress, uint256 depositAmount, uint256 sharesMinted, address strategyAddress);
    event Withdraw(address tokenAddress, uint256 withdrawAmount, uint256 sharesBurnt, address strategyAddress);
    event Rebalance(address strategyWithdrawn, address strategyDeposited, uint256 amountMoved);
    event RatioChanged(address strategyAddress, uint256 ratioBefore, uint256 ratioAfter);
    event StrategyActiveSet(address strategyAddress, bool isDeposit, bool value);
    event RebalanceThresholdSet(uint256 numer, uint256 denom);
    event StrategyAdded(address strategyAddress);
    event StrategyRemoved(address strategyAddress);
    event DepositPause(address account, bool paused);
    event WithdrawPause(address account, bool paused);
    
    constructor () public ERC20("", ""){}

    function setGovAddress(address _govAddress) external {
        require(msg.sender == govAddress || msg.sender == owner(), "Not authorized");
        govAddress = _govAddress;
    }

    function setPolicyAdmin(address _policyAdmin) external {
        require(msg.sender == govAddress || msg.sender == owner(), "Not authorized");
        policyAdmin = _policyAdmin;
    }

    function pauseDeposit() external {
        require(!depositPaused, "deposit paused");
        require(msg.sender == govAddress || msg.sender == owner(), "Not authorized");
        depositPaused = true;
        emit DepositPause(msg.sender, true);
    }

    function unpauseDeposit() external {
        require(depositPaused, "deposit not paused");
        require(msg.sender == govAddress || msg.sender == owner(), "Not authorized");
        depositPaused = false;
        emit DepositPause(msg.sender, false);
    }

    function pauseWithdraw() external virtual {
        require(!withdrawPaused, "withdraw paused");
        require(msg.sender == govAddress || msg.sender == owner(), "Not authorized");
        withdrawPaused = true;
        emit WithdrawPause(msg.sender, true);
    }

    function unpauseWithdraw() external virtual {
        require(withdrawPaused, "withdraw not paused");
        require(msg.sender == govAddress || msg.sender == owner(), "Not authorized");
        withdrawPaused = false;
        emit WithdrawPause(msg.sender, false);
    }

    function deposit(uint256 _amount, uint256 _minShares)
        external
    {
        require(!depositPaused, "deposit paused");
        require(_amount != 0, "deposit must be greater than 0");
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount, _minShares);
    }

    function depositBNB(uint256 _minShares) external payable {
        require(!depositPaused, "deposit paused");
        require(isWbnb, "not bnb");
        require(msg.value != 0, "deposit must be greater than 0");
        _wrapBNB(msg.value);
        _deposit(msg.value, _minShares);
    }

    function _deposit(uint256 _amount, uint256 _minShares)
        internal
        nonReentrant
    {
        updateAllStrategies();
        uint256 _pool = calcPoolValueInToken();
        
        address strategyAddress;
        (strategyAddress,) = findMostInsufficientStrategy();
        ISingleStrategyToken(strategyAddress).deposit(_amount, 0);
        uint256 sharesToMint = calcPoolValueInToken().sub(_pool);
        if (totalSupply() != 0 && _pool != 0) {
            sharesToMint = sharesToMint.mul(totalSupply())
                .div(_pool);
        }
        require(sharesToMint >= _minShares, "did not meet minimum shares requested");

        _mint(msg.sender, sharesToMint);

        emit Deposit(token, _amount, sharesToMint, strategyAddress);
    }
    

    function withdraw(uint256 _shares, uint256 _minAmount)
        external
    {
        uint r = _withdraw(_shares, _minAmount);
        IERC20(token).safeTransfer(msg.sender, r);
    }

    function withdrawBNB(uint256 _shares, uint256 _minAmount)
        external
    {
        require(isWbnb, "not bnb");
        uint256 r = _withdraw(_shares, _minAmount);
        _unwrapBNB(r);
        msg.sender.transfer(r);
    }

    function _withdraw(uint256 _shares, uint256 _minAmount)
        internal
        nonReentrant
        returns (uint256)
    {
        require(!withdrawPaused, "withdraw paused");
        require(_shares != 0, "shares must be greater than 0");

        uint256 ibalance = balanceOf(msg.sender);
        require(_shares <= ibalance, "insufficient balance");

        updateAllStrategies();
        uint256 pool = calcPoolValueInToken();

        uint256 r = pool.mul(_shares).div(totalSupply());
        _burn(msg.sender, _shares);

        address strategyToWithdraw;
        uint256 strategyAvailableAmount;
        (strategyToWithdraw, strategyAvailableAmount) = findMostOverLockedStrategy(r);
        if (r > strategyAvailableAmount) {
            (strategyToWithdraw, strategyAvailableAmount) = findMostLockedStrategy();
            require(r <= strategyAvailableAmount, "withdrawal amount too big");
        }
        uint256 _stratPool = ISingleStrategyToken(strategyToWithdraw).calcPoolValueInToken();
        uint256 stratShares = r
            .mul(
                IERC20(strategyToWithdraw).totalSupply()
            )
            .div(_stratPool);
        uint256 diff = balance();
        ISingleStrategyToken(strategyToWithdraw).withdraw(stratShares, 0/*strategyAvailableAmount*/);
        diff = balance().sub(diff);
        
        require(diff >= _minAmount, "did not meet minimum amount requested");

        emit Withdraw(token, diff, _shares, strategyToWithdraw);

        return diff;
    }

    function rebalance() public {
        require(msg.sender == govAddress || msg.sender == policyAdmin || msg.sender == owner(), "Not authorized");
        address strategyToWithdraw;
        uint256 strategyAvailableAmount;
        address strategyToDeposit;
        // uint256 strategyInsuffAmount;
        updateAllStrategies();
        (strategyToWithdraw, strategyAvailableAmount) = findMostOverLockedStrategy(0);
        (strategyToDeposit, /*strategyInsuffAmount*/) = findMostInsufficientStrategy();

        uint256 totalBalance = calcPoolValueInToken();
        uint256 optimal = totalBalance.mul(ratios[strategyToWithdraw]).div(ratioTotal);

        uint256 threshold = optimal.mul(
                rebalanceThresholdNumer
        ).div(rebalanceThresholdDenom);

        if (strategyAvailableAmount != 0 && threshold < strategyAvailableAmount) {
            uint256 _pool = ISingleStrategyToken(strategyToWithdraw).calcPoolValueInToken();
            uint256 stratShares = strategyAvailableAmount
                    .mul(
                        IERC20(strategyToWithdraw).totalSupply()
                    )
                    .div(_pool);
            uint256 diff = balance();
            ISingleStrategyToken(strategyToWithdraw).withdraw(stratShares, 0/*strategyAvailableAmount)*/);
            diff = balance().sub(diff);
            ISingleStrategyToken(strategyToDeposit).deposit(diff, 0);
            emit Rebalance(strategyToWithdraw, strategyToDeposit, diff);
        }
    }

    function findMostOverLockedStrategy(uint256 withdrawAmt) public view returns (address, uint256) {
        address[] memory strats = getAvailableStrategyList(false);

        uint256 totalBalance = calcPoolValueInToken().sub(withdrawAmt);

        address overLockedStrategy = strats[0];

        uint256 optimal = totalBalance.mul(ratios[strats[0]]).div(ratioTotal);
        uint256 current = getBalanceOfOneStrategy(strats[0]);   
        
        bool isLessThanOpt = current < optimal;
        uint256 overLockedBalance = isLessThanOpt ? optimal.sub(current) : current.sub(optimal);

        uint256 i = 1;
        for (; i < strats.length; i += 1) {
            optimal = totalBalance.mul(ratios[strats[i]]).div(ratioTotal);
            current = getBalanceOfOneStrategy(strats[i]); 
            if (isLessThanOpt && current >= optimal) {
                isLessThanOpt = false;
                overLockedBalance = current.sub(optimal);
                overLockedStrategy = strats[i];
            } else if (isLessThanOpt && current < optimal) {
                if (optimal.sub(current) < overLockedBalance) {
                    overLockedBalance = optimal.sub(current);
                    overLockedStrategy = strats[i];
                }
            } else if (!isLessThanOpt && current >= optimal) {
                if (current.sub(optimal) > overLockedBalance) {
                    overLockedBalance = current.sub(optimal);
                    overLockedStrategy = strats[i];
                }
            }
        }

        if (isLessThanOpt) {
            overLockedBalance = 0;
        }

        return (overLockedStrategy, overLockedBalance);
    }

    function findMostLockedStrategy() public view returns (address, uint256) {
        address[] memory strats = getAvailableStrategyList(false);

        uint256 current;
        address lockedMostAddr = strats[0];
        uint256 lockedBalance = getBalanceOfOneStrategy(strats[0]);

        uint256 i = 1;
        for (; i < strats.length; i += 1) {
            current = getBalanceOfOneStrategy(strats[i]); 
            if (current > lockedBalance) {
                lockedBalance = current;
                lockedMostAddr = strats[i];
            }
        }

        return (lockedMostAddr, lockedBalance);
    }

    function findMostInsufficientStrategy() public view returns (address, uint256) {
        address[] memory strats = getAvailableStrategyList(true);

        uint256 totalBalance = calcPoolValueInToken();

        address insuffStrategy = strats[0];

        uint256 optimal = totalBalance.mul(ratios[strats[0]]).div(ratioTotal);
        uint256 current = getBalanceOfOneStrategy(strats[0]);
        
        bool isGreaterThanOpt = current > optimal;
        uint256 insuffBalance = isGreaterThanOpt ? current.sub(optimal) : optimal.sub(current);

        uint256 i = 1;
        for (; i < strats.length; i += 1) {
            optimal = totalBalance.mul(ratios[strats[i]]).div(ratioTotal);
            current = getBalanceOfOneStrategy(strats[i]); 
            if (isGreaterThanOpt && current < optimal) {
                isGreaterThanOpt = false;
                insuffBalance = optimal.sub(current);
                insuffStrategy = strats[i];
            } else if (isGreaterThanOpt && current > optimal) {
                if (current.sub(optimal) < insuffBalance) {
                    insuffBalance = current.sub(optimal);
                    insuffStrategy = strats[i];
                }
            } else if (!isGreaterThanOpt && current <= optimal) {
                if (optimal.sub(current) > insuffBalance) {
                    insuffBalance = optimal.sub(current);
                    insuffStrategy = strats[i];
                }
            }
        }

        if (isGreaterThanOpt) {
            insuffBalance = 0;
        }

        return (insuffStrategy, insuffBalance);
    }

    function balance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getBalanceOfOneStrategy(address strategyAddress) public view returns (uint256 bal) {
            ISingleStrategyToken stToken = ISingleStrategyToken(strategyAddress);
            if (stToken.balanceOf(address(this)) != 0) {
                bal = stToken.calcPoolValueInToken().mul(
                    stToken.balanceOf(address(this))
                ).div(
                    stToken.totalSupply()
                );
            } else {
                bal = 0;
            }
    }

    function balanceStrategy() public view returns (uint256) {
        uint i = 0;
        uint sum = 0;
        for (; i < strategies.length; i += 1) {
            sum = sum.add(getBalanceOfOneStrategy(strategies[i]));
        }
        return sum;
    }

    function getAvailableStrategyList(bool isDeposit) internal view returns (address[] memory) {
        uint256 activeCnt = isDeposit ? depositActiveCount : withdrawActiveCount;
        require(activeCnt != 0, "none of the strategies are active");
        address[] memory addrArr = new address[](activeCnt);
        uint256 i = 0;
        uint256 cnt = 0;
        for (; i < strategies.length; i += 1) {
            if (isDeposit) {
                if (depositActive[strategies[i]]) {
                    addrArr[cnt] = strategies[i];
                    cnt += 1;
                }
            } else {
                if (withdrawActive[strategies[i]]) {
                    addrArr[cnt] = strategies[i];
                    cnt += 1;
                }
            }
        }

        return addrArr;
    }

    function calcPoolValueInToken() public view returns (uint256) {
        return balanceStrategy();
    }

    function getPricePerFullShare() public view returns (uint) {
        uint _pool = calcPoolValueInToken();
        return _pool.mul(1e18).div(totalSupply());
    }

    function changeRatio(uint256 index, uint256 value) external {
        require(msg.sender == govAddress || msg.sender == policyAdmin || msg.sender == owner(), "Not authorized");
        // require(index != 0);
        require(strategies.length > index, "invalid index");
        uint256 valueBefore = ratios[strategies[index]];
        ratios[strategies[index]] = value;    
        ratioTotal = ratioTotal.sub(valueBefore).add(value);

        emit RatioChanged(strategies[index], valueBefore, value);
    }

    // doesn"t guarantee that withdrawing shares returned by this function will always be successful.
    function getMaxWithdrawableShares() public view returns (uint256) {
        require(totalSupply() != 0, "total supply is 0");
        uint256 bal;
        (, bal) = findMostLockedStrategy();
        return amountToShares(bal);
    }

    function sharesToAmount(uint256 _shares) public view returns (uint256) {
        uint256 _pool = calcPoolValueInToken();
        return _shares.mul(_pool).div(totalSupply());
    }

    function amountToShares(uint256 _amount) public view returns (uint256) {
        uint256 _pool = calcPoolValueInToken();
        uint256 shares;
        if (totalSupply() == 0 || _pool == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply()))
                .div(_pool);
        }
        return shares;
    }
    
    function setStrategyActive(uint256 index, bool isDeposit, bool b) public {
        require(msg.sender == govAddress || msg.sender == policyAdmin || msg.sender == owner(), "Not authorized");
        mapping(address => bool) storage isActive = isDeposit ? depositActive : withdrawActive;
        require(index < strategies.length, "invalid index");
        require(isActive[strategies[index]] != b, b ? "already active" : "already inactive");
        if (isDeposit) {
            depositActiveCount = b ? depositActiveCount.add(1) : depositActiveCount.sub(1);
        } else {
            withdrawActiveCount = b ? withdrawActiveCount.add(1) : withdrawActiveCount.sub(1);
        }
        isActive[strategies[index]] = b;

        emit StrategyActiveSet(strategies[index], isDeposit, b);
    }

    function setRebalanceThreshold(uint256 _rebalanceThresholdNumer, uint256 _rebalanceThresholdDenom) external {
        require(msg.sender == govAddress || msg.sender == policyAdmin || msg.sender == owner(), "Not authorized");
        require(_rebalanceThresholdDenom != 0, "denominator should not be 0");
        require(_rebalanceThresholdDenom >= _rebalanceThresholdNumer, "denominator should be greater than or equal to the numerator");
        rebalanceThresholdNumer = _rebalanceThresholdNumer;
        rebalanceThresholdDenom = _rebalanceThresholdDenom;

        emit RebalanceThresholdSet(rebalanceThresholdNumer, rebalanceThresholdDenom);
    }

    function strategyCount() public view returns (uint256) {
        return strategies.length;
    }


    function _wrapBNB(uint256 _amount) internal {
        if (address(this).balance >= _amount) {
            IWBNB(wbnbAddress).deposit{value: _amount}();
        }
    }

    function _unwrapBNB(uint256 _amount) internal {
        uint256 wbnbBal = IERC20(wbnbAddress).balanceOf(address(this));
        if (wbnbBal >= _amount) {
            IERC20(wbnbAddress).safeApprove(bnbHelper, _amount);
            IUnwrapper(bnbHelper).unwrapBNB(_amount);
        }
    }

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) public {
        require(msg.sender == govAddress || msg.sender == owner(), "!gov");
        require(_token != address(this), "!safe");
        
        uint8 i = 0;
        for (; i < strategies.length; i += 1) {
            require(_token != strategies[i], "!safe");
        }
        
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "amount greater than holding");
            _wrapBNB(_amount);
            _token = wbnbAddress;
        } else if (_token == token) { 
            require(balance() >= _amount, "amount greater than holding");
        }
        IERC20(_token).safeTransfer(_to, _amount);
    }

    function getProxyAdmin() public view returns (address adm) {
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    function setBNBHelper(address _helper) public {
        require(msg.sender == govAddress || msg.sender == owner(), "!gov");
        require(_helper != address(0));

        bnbHelper = _helper;
    }

    function updateAllStrategies() public {
        uint8 i = 0;
        for (; i < strategies.length; i += 1) {
            ISingleStrategyToken(strategies[i]).updateStrategy();
        }
    }

    function getStrategyIndex(address strategyAddress) public view returns (uint8) {
        for (uint8 i = 0; i < strategies.length; i++) {
            if (strategies[i] == strategyAddress) return i;
        }
        revert("invalid strategy address");
    }

    function addStrategy(address strategyAddress) internal {
        uint8 i = 0;
        for (; i < strategies.length; i += 1) {
            require(strategies[i] != strategyAddress, "Strategy Already Exists");
        }
        strategies.push(strategyAddress);
        IERC20(token).safeApprove(strategyAddress, uint(-1));
        emit StrategyAdded(strategyAddress);
    }

    function removeStrategy(address strategyAddress) internal {
        uint8 index = getStrategyIndex(strategyAddress);
        require(index < strategies.length);

        address strategyToRemove = strategies[index];
        for (uint8 i = index + 1; i < strategies.length; i++) {
            strategies[i - 1] = strategies[i];
        }
        
        IERC20(token).safeApprove(strategyToRemove, 0);
        
        strategies[strategies.length - 1] = strategyToRemove;
        strategies.pop();

        ratioTotal = ratioTotal.sub(ratios[strategyToRemove]);
        ratios[strategyToRemove] = 0;
        
        if (depositActive[strategyToRemove]) {
            depositActiveCount = depositActiveCount.sub(1);
            depositActive[strategyToRemove] = false;
        }
        if (withdrawActive[strategyToRemove]) {
            withdrawActiveCount = withdrawActiveCount.sub(1);
            withdrawActive[strategyToRemove] = false;
        }
        emit StrategyRemoved(strategyToRemove);
    }

    function updateStrategyList() public {
        require(msg.sender == govAddress || msg.sender == owner(), "!gov");
    }

    fallback() external payable {}
    receive() external payable {}
}