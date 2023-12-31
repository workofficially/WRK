// Decoding WRK Token: Detailed Insight
// SPDX-License-Identifier: MIT
// License identifier for this Solidity file: MIT License.

pragma solidity ^0.8.23;
// This contract is compatible with Solidity version 0.8.23.

import "@openzeppelin/contracts/access/Ownable.sol";
// Imports the Ownable contract from OpenZeppelin for ownership management functionalities.

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// Imports ReentrancyGuard from OpenZeppelin to prevent reentrant calls to a function.

contract WorkOfficially is Ownable(msg.sender), ReentrancyGuard {
    
    
}
// Declares 'WorkOfficially' contract with Ownable and ReentrancyGuard features. 'Ownable(msg.sender)' sets the contract deployer as the owner.

    string public constant name = "WorkOfficially";
    // Sets the name of the token to "WorkOfficially".

    string public constant symbol = "WRK";
    // Sets the symbol of the token to "WRK".

    string public domainName = "https://www.workofficially.com";
    // Sets the official website or domain for the token to "https://www.workofficially.com".

    uint8 public constant decimals = 6;
    // Sets the number of decimal places used in token representation to 6.

    uint256 public constant initialSupply = 9e9 * 10**uint256(decimals);
    // Initializes the initial supply of the token to 9 billion, adjusted for decimal places.

    uint256 public totalSupply = initialSupply;
    // Sets the total supply of tokens equal to the initial supply.

    mapping(address => uint256) private balances;
    // Creates a mapping to store the token balance of each address.

    mapping(address => mapping(address => uint256)) private allowances;
    // Creates a nested mapping to store the allowance an address gives to another address.

    mapping(address => Vesting) public vestings;
    // Creates a mapping to store vesting information for each address.

    mapping(uint256 => mapping(address => uint256)) private snapshotBalances;
    // Creates a nested mapping to store the token balances of each address at each snapshot.

    mapping(uint256 => uint256) public snapshotIds;
    // Creates a mapping to store the block number of each snapshot taken.

    struct Vesting {
        uint256 amount;
        uint256 releaseTime;
    }
    // Defines a structure for vesting, including the amount of tokens and their release time.

    bool public paused = false;
    // Initializes the contract's paused state to false, meaning not paused.

    uint256 private currentSnapshotId;
    // Initializes a variable to keep track of the current snapshot ID.

    // Event declarations:
    event Transfer(address indexed from, address indexed to, uint256 value);
    // Logs token transfers.

    event Approval(address indexed owner, address indexed spender, uint256 value);
    // Logs approvals for token spending.

    event Burn(address indexed burner, uint256 value);
    // Logs token burning.

    event TokensVested(address indexed beneficiary, uint256 amount, uint256 releaseTime);
    // Logs token vesting schedules.

    event Snapshot(uint256 id);
    // Logs when a snapshot of balances is taken.

    constructor() {
        balances[msg.sender] = totalSupply;
        // Assigns the entire initial token supply to the contract creator.

        uint256 lockedAmount = 1e9 * 10**uint256(decimals);
        // Sets the amount of tokens to be locked for vesting to 1 billion.

        uint256 releaseTime = 2524608000; 
        // Sets the release time for the locked tokens to January 1, 2050, 00:00:00 GMT.

        createVesting(msg.sender, lockedAmount, releaseTime);
        // Calls the function to create a vesting schedule for the contract creator.
    }

    modifier whenNotPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }
    // A modifier that checks if the contract is paused; if so, it stops the function execution.

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }
    // Returns the token balance of a specified address.

    function transfer(address _recipient, uint256 _amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    // Transfers tokens from the sender to a recipient, provided the contract is not paused and is reentrancy-safe.

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }
    // Returns the amount of tokens that an owner allowed a spender to spend.

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }
    // Allows an owner to approve a spender to spend a specified amount of tokens.

    function transferFrom(address _sender, address _recipient, uint256 _amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender] - _amount);
        return true;
    }
    // Allows a spender to transfer an amount of tokens from an owner's account to a recipient, provided there's enough allowance.

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
    // Internal function that executes the token transfer, updates the snapshots, and emits the Transfer event.

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(_spender != address(0), "Approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    // Internal function that sets the amount of tokens an owner allows a spender to use and emits the Approval event.

    function pause() public onlyOwner {
        paused = true;
    }
    // Allows the contract owner to pause the contract.

    function unpause() public onlyOwner {
        paused = false;
    }
    // Allows the contract owner to unpause the contract.

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }
    // Increases the allowance a spender has from the caller by a specified amount.

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] - _subtractedValue);
        return true;
    }
    // Decreases the allowance a spender has from the caller by a specified amount.

    function burn(uint256 _amount) public {
        require(_amount > 0, "Burn amount must be greater than zero");
        require(balances[msg.sender] >= _amount, "Burn amount exceeds balance");

        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        updateSnapshot(msg.sender);
        emit Burn(msg.sender, _amount);
    }
    // Allows a user to burn a specified amount of their tokens, decreasing the total supply.

    function createVesting(address _beneficiary, uint256 _amount, uint256 _releaseTime) internal {
        require(_beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(_amount > 0, "Vesting amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");

        vestings[_beneficiary] = Vesting(_amount, _releaseTime);
        balances[msg.sender] -= _amount;
        emit TokensVested(_beneficiary, _amount, _releaseTime);
    }
    // Internal function to create a vesting schedule for a specified beneficiary.

    function releaseVestedTokens(address _beneficiary) public {
        Vesting memory vesting = vestings[_beneficiary];
        require(block.timestamp >= vesting.releaseTime, "Tokens are not yet releasable");
        require(vesting.amount > 0, "No vested tokens available");

        balances[_beneficiary] += vesting.amount;
        vestings[_beneficiary].amount = 0;
        updateSnapshot(_beneficiary);
        emit Transfer(address(0), _beneficiary, vesting.amount);
    }
    // Allows a beneficiary to claim their vested tokens once the vesting period is over.

    function takeSnapshot() public onlyOwner returns (uint256) {
        currentSnapshotId++;
        snapshotIds[currentSnapshotId] = block.number;
        emit Snapshot(currentSnapshotId);
        return currentSnapshotId;
    }
    // Allows the contract owner to take a snapshot of all current token balances, returning the ID of the new snapshot.

   function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
    // Function to get the balance of 'account' at a specific 'snapshotId'.
    // This is useful for checking historical balances.

    require(snapshotId > 0 && snapshotId <= currentSnapshotId, "Invalid snapshot id");
    // The 'require' statement ensures that the 'snapshotId' provided is valid.
    // It must be greater than 0 and less than or equal to the current snapshot ID.
    // If this condition is not met, the transaction is reverted with the message "Invalid snapshot id".

    return snapshotBalances[snapshotId][account];
    // Returns the balance of 'account' at the given 'snapshotId'.
    // 'snapshotBalances' is a nested mapping where the first key is the snapshot ID 
    // and the second key is the account address.
    }

function updateSnapshot(address account) internal {
    // Internal function to update the snapshot balance for an 'account'.
    // This function is called to record the current balance of an account at the time of a snapshot.

    if (currentSnapshotId > 0) {
        // Checks if 'currentSnapshotId' is greater than 0, ensuring that a snapshot has been taken.
        // This check is necessary to avoid updating snapshot balances before any snapshot is taken.

        snapshotBalances[currentSnapshotId][account] = balances[account];
        // Updates the 'snapshotBalances' mapping for the given 'account'.
        // Sets the balance of 'account' at 'currentSnapshotId' to its current balance.
        // This captures the state of the account's balance at the specific snapshot in time.
        }   
    }
}

