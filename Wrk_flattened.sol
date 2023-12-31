
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Work.sol


pragma solidity ^0.8.23;



contract WorkOfficially is Ownable(msg.sender), ReentrancyGuard {

    string public constant name = "WorkOfficially";
    string public constant symbol = "WRK";
    string public domainName = "https://www.workofficially.com";

    uint8 public constant decimals = 6;
    uint256 public constant initialSupply = 9e9 * 10**uint256(decimals);
    uint256 public totalSupply = initialSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => Vesting) public vestings;
    mapping(uint256 => mapping(address => uint256)) private snapshotBalances;
    mapping(uint256 => uint256) public snapshotIds;

    struct Vesting {
        uint256 amount;
        uint256 releaseTime;
    }

    bool public paused = false;

    uint256 private currentSnapshotId;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event TokensVested(address indexed beneficiary, uint256 amount, uint256 releaseTime);
    event Snapshot(uint256 id);

    constructor() {
        balances[msg.sender] = totalSupply;

        uint256 lockedAmount = 1e9 * 10**uint256(decimals);
        uint256 releaseTime = 2524608000; 
        createVesting(msg.sender, lockedAmount, releaseTime);
    }

    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender] - _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "Transfer from the zero address");
        require(_recipient != address(0), "Transfer to the zero address");
        require(balances[_sender] >= _amount, "Insufficient balance");

        balances[_sender] -= _amount;
        balances[_recipient] += _amount;
        updateSnapshot(_sender);
        updateSnapshot(_recipient);
        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(_spender != address(0), "Approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] - _subtractedValue);
        return true;
    }

    function burn(uint256 _amount) public {
        require(_amount > 0, "Burn amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Burn amount exceeds balance");

        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        updateSnapshot(msg.sender);
        emit Burn(msg.sender, _amount);
    }

    function createVesting(address _beneficiary, uint256 _amount, uint256 _releaseTime) internal {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(_amount > 0, "Vesting amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");

        vestings[_beneficiary] = Vesting(_amount, _releaseTime);
        balances[msg.sender] -= _amount;
        emit TokensVested(_beneficiary, _amount, _releaseTime);
    }

    function releaseVestedTokens(address _beneficiary) public {
        Vesting memory vesting = vestings[_beneficiary];
        require(block.timestamp >= vesting.releaseTime, "Tokens are not yet releasable");
        require(vesting.amount > 0, "No vested tokens available");

        balances[_beneficiary] += vesting.amount;
        vestings[_beneficiary].amount = 0;
        updateSnapshot(_beneficiary);
        emit Transfer(address(0), _beneficiary, vesting.amount);
    }

    function takeSnapshot() public onlyOwner returns (uint256) {
        currentSnapshotId++;
        snapshotIds[currentSnapshotId] = block.number;
        emit Snapshot(currentSnapshotId);
        return currentSnapshotId;
    }

    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        require(snapshotId > 0 && snapshotId <= currentSnapshotId, "Invalid snapshot id");
        return snapshotBalances[snapshotId][account];
    }

    function updateSnapshot(address account) internal {
        if (currentSnapshotId > 0) {
            snapshotBalances[currentSnapshotId][account] = balances[account];
        }
    }
}