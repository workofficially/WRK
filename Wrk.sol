// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
