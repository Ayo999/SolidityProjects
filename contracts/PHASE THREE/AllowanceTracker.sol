//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract AllowanceTracker{
    address owner;
    uint minAllowance;
    uint allowanceAmount;
    bool paused;
    bool private locked;
    constructor(uint _minAllowance){
        owner = msg.sender;
        minAllowance = _minAllowance;
    }
    //Events
    event BeneficiariesSet(address beneficiary, uint amount);
    event AllowanceIncreased(address beneficiary, uint amount);
    event AllowanceDecreased(address beneficiary, uint amount);
    event AllowanceRevoked(address beneficiary, string reason);
    event Deposit(address sender, uint amount);
    event Withdraw(address beneficiary, uint amount, uint remainder);
    //Modifiers
    modifier onlyOwner{
        require(msg.sender == owner, "Not Owner");
        _;
    }
    modifier nonReentrant{
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    modifier notPaused{
        require(!paused, "Withdrawals paused");
        _;
    }
    modifier beneficiariesSet{
        require(beneficiaries.length > 0, "Set the beneficiaries");
        _;
    }
    mapping(address beneficiary => uint amount) allowance;
    mapping(address beneficiary => uint amount) amountWithdrawn;
    address[] beneficiaries;
    uint[] totalAllowances;
    //Admin-only
    function setBeneficiaries(address _beneficiary, uint _amount) external onlyOwner {
        require(_amount >= minAllowance, "Amount should be greater than min. allowance");
        allowance[_beneficiary] = _amount;
        beneficiaries.push(_beneficiary);
        totalAllowances.push(_amount);
        emit BeneficiariesSet(_beneficiary, _amount);
    }
    function increaseAllowance(address _beneficiary, uint _amount) external onlyOwner beneficiariesSet {
        allowance[_beneficiary] += _amount;
        emit AllowanceIncreased(_beneficiary, _amount);
    }
    function decreaseAllowance(address _beneficiary, uint _amount) external onlyOwner beneficiariesSet {
        allowance[_beneficiary] -= _amount;
        emit AllowanceDecreased(_beneficiary, _amount);
    }
    function revokeAllowance(address _beneficiary, string calldata _reason) external onlyOwner beneficiariesSet {
        allowance[_beneficiary] = 0;
        emit AllowanceRevoked(_beneficiary, _reason);
    }
    function pause() external onlyOwner notPaused beneficiariesSet{
        paused = true;
    }
    function unpause() external onlyOwner beneficiariesSet{
        require(paused, "Withdrawals not paused");
        paused = false;
    }
    //AdminDeposit
    function deposit() external payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }
    receive() external payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }
    fallback() external payable onlyOwner {
        emit Deposit(msg.sender, msg.value);
    }
    //Beneficiaries
    function withdraw(uint _amount) external nonReentrant notPaused{
        require(msg.sender != owner, "Owner cannot withdraw");
        require(allowance[msg.sender] > 0, "You have no allowance");
        require(allowance[msg.sender] >= _amount, "Insufficient allowance");
        require(_amount > 0, "Withdrawal amount cannot be 0");
        allowance[msg.sender]-= _amount;
        amountWithdrawn[msg.sender] += _amount;
        (bool success, ) = msg.sender.call{value: _amount * 1 ether}("");
        require(success, "Withdrawal Failed");
        emit Withdraw(msg.sender, _amount, allowance[msg.sender]);
    }
    //Tracking
    function getBeneficiaries() external view returns(address[] memory) {
        return beneficiaries;
    }
    function getAllowances(address _beneficiary) external view returns(uint) {
        return allowance[_beneficiary];
    }
    function getAmountWithdrawn(address _beneficiary) external view returns(uint) {
        return amountWithdrawn[_beneficiary];
    }
    // function getTotalAllowances() external view returns(uint total) {
    //     for(uint i = 0; i < totalAllowances.length; i++){
    //        total += totalAllowances[i];
    //     }
    //     return total;
    // }

}