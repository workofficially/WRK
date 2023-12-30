// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// Importing OpenZeppelin's contracts for ownership, safety checks, and reentrancy protection.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Declaring the MyToken contract, inheriting from Ownable and ReentrancyGuard.
contract MyToken is Ownable(msg.sender), ReentrancyGuard {
    // Using the SafeMath library for all uint256 types to prevent arithmetic overflow/underflow.
    using SafeMath for uint256;

    // Public constant variables to define the token's basic information.
    string public constant name = "WORKOFFICIALLY";
    string public constant symbol = "WRK";
    uint8 public constant decimals = 5;
    uint256 public constant initialSupply = 9e9 * 10**uint256(decimals);
    uint256 public totalSupply = initialSupply;

    // State variables to store token balances, allowances, and vesting schedules.
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => Vesting) public vestings;
    mapping(uint256 => mapping(address => uint256)) private snapshotBalances;
    mapping(uint256 => uint256) public snapshotIds;

    // Struct to define vesting properties.
    struct Vesting {
        uint256 amount;
        uint256 releaseTime;
    }

    // State variable for pausing/unpausing the contract.
    bool public paused = false;

    // Variable to track the current snapshot ID.
    uint256 private currentSnapshotId;

    // Events for logging various contract activities.
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event TokensVested(address indexed beneficiary, uint256 amount, uint256 releaseTime);
    event Snapshot(uint256 id);

    // Constructor to initialize the contract with the total supply and create a vesting schedule.
    constructor() {
        balances[msg.sender] = totalSupply;
        // Lock 1 billion tokens until January 1, 2050.
        uint256 lockedAmount = 1e9 * 10**uint256(decimals);
        uint256 releaseTime = 2524608000; // Unix timestamp for January 1, 2050
        createVesting(msg.sender, lockedAmount, releaseTime);
    }

    // Modifier to check if the contract is not paused.
    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    // Function to return the balance of a given account.
    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    // Function to transfer tokens to a specified address.
    function transfer(address _recipient, uint256 _amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    // Function to check the number of tokens that an owner allowed to a spender.
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    // Function to approve a spender to spend a certain amount of tokens.
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    // Function to transfer tokens on behalf of the owner to another address.
    function transferFrom(address _sender, address _recipient, uint256 _amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender].sub(_amount));
        return true;
    }

    // Internal function to handle the transfer logic.
    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_sender != address(0), "Transfer from the zero address");
        require(_recipient != address(0), "Transfer to the zero address");
        require(balances[_sender] >= _amount, "Insufficient balance");

        balances[_sender] = balances[_sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        updateSnapshot(_sender);
        updateSnapshot(_recipient);
        emit Transfer(_sender, _recipient, _amount);
    }

    // Internal function to handle approval logic.
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(_spender != address(0), "Approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    // Function to pause the contract. Only the owner can call this.
    function pause() public onlyOwner {
        paused = true;
    }

    // Function to unpause the contract. Only the owner can call this.
    function unpause() public onlyOwner {
        paused = false;
    }

    // Function to increase the allowance for a given spender.
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue));
        return true;
    }

    // Function to decrease the allowance for a given spender.
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].sub(_subtractedValue));
        return true;
    }

    // Function to burn a certain amount of tokens. This reduces the total supply.
    function burn(uint256 _amount) public {
        require(_amount > 0, "Burn amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Burn amount exceeds balance");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        updateSnapshot(msg.sender);
        emit Burn(msg.sender, _amount);
    }

    // Internal function to create a vesting schedule for a given beneficiary.
    function createVesting(address _beneficiary, uint256 _amount, uint256 _releaseTime) internal {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(_amount > 0, "Vesting amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");

        vestings[_beneficiary] = Vesting(_amount, _releaseTime);
        balances[msg.sender] = balances[msg.sender].sub(_amount, "Insufficient balance for vesting");
        emit TokensVested(_beneficiary, _amount, _releaseTime);
    }

    // Function to release vested tokens to a beneficiary.
    function releaseVestedTokens(address _beneficiary) public {
        Vesting memory vesting = vestings[_beneficiary];
        require(block.timestamp >= vesting.releaseTime, "Tokens are not yet releasable");
        require(vesting.amount > 0, "No vested tokens available");

        balances[_beneficiary] = balances[_beneficiary].add(vesting.amount);
        vestings[_beneficiary].amount = 0;
        updateSnapshot(_beneficiary);
        emit Transfer(address(0), _beneficiary, vesting.amount);
    }

    // Function to take a snapshot of current token balances. Only the owner can call this.
    function takeSnapshot() public onlyOwner returns (uint256) {
        currentSnapshotId = currentSnapshotId.add(1);
        snapshotIds[currentSnapshotId] = block.number;
        emit Snapshot(currentSnapshotId);
        return currentSnapshotId;
    }

    // Function to get the balance of an account at a specific snapshot.
    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        require(snapshotId > 0 && snapshotId <= currentSnapshotId, "Invalid snapshot id");
        return snapshotBalances[snapshotId][account];
    }

    // Internal function to update the snapshot balance for a given account.
    function updateSnapshot(address account) internal {
        if (currentSnapshotId > 0) {
            snapshotBalances[currentSnapshotId][account] = balances[account];
        }
    }
}
