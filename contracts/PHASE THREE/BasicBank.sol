// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract BasicBank{
    address owner;
    uint minDeposit;
    bool paused;
    bool private locked;
//Events
    event Deposit(address _sender, uint _value);
    event Withdrawal(address _to, uint _value);

//Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier notPaused() {
        require(paused == false);
        _;
    }
    modifier nonReentrant() {
        require (!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    modifier suffBalance() {
        require(msg.value >= minDeposit, "Insufficient Deposit");
        _;
    }
    constructor(uint _minDeposit){
        owner = msg.sender;
        minDeposit = _minDeposit * 1 ether;
        paused = false;
    }
    mapping(address => uint) balanceOf;
    mapping(address => bool) deposited;

//Deposit
    function deposit() payable external suffBalance{
        balanceOf[msg.sender] += msg.value;
        deposited[msg.sender] = true;
        emit Deposit(msg.sender, msg.value);
    }
    receive() external payable suffBalance{
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable suffBalance{
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

//Withdrawal
    function Withdraw(uint _value) external notPaused nonReentrant{
        uint value = _value * 1 ether;
        require(deposited[msg.sender] == true, "Address has no deposit");
        require(balanceOf[msg.sender] >= value, "Insufficient Balance");
        balanceOf[msg.sender] -= value;
        (bool success, ) = payable(msg.sender).call{value: value }("");
        require(success, "Withdrawal failed");
        emit Withdrawal(msg.sender, value);
    }
    function checkBalances() view external returns (uint) {
        return balanceOf[msg.sender];
    }

//Owner controls
    function setMinDeposit(uint _newMin) external onlyOwner{
        minDeposit = _newMin * 1 ether;

    }
    function pause() external onlyOwner{
        paused = true;
    }
    function unpause() external onlyOwner{
        paused = false;
    }

}