//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract Crowdfunding{
    address owner;
    uint fundingGoal;
    uint deadline;
    bool private locked;
    // bool refunds;
    mapping(address contributor => uint amount) contribution;
    enum State {Active, Successful, Failed}
    State public contibutionState;
    constructor(uint _fundingGoal, uint _deadline) {
        owner = msg.sender;
        fundingGoal = _fundingGoal * 1 ether;
        deadline = (_deadline * 1 minutes) + block.timestamp;
    }
    //Events
    event Deposit(address indexed contributor, uint amount);
    event Withdraw(address recipient, uint amount);
    event Refund(address indexed contributor, uint amount);
    event ContibutionState(string state);

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    modifier notOwner() {
        require(msg.sender != owner, "Owner cannot call");
        _;
    }
    //Contributions
    function deposit() external payable notOwner{
        if(address(this).balance >= fundingGoal && block.timestamp < deadline){
            contibutionState = State.Successful;
            emit ContibutionState("Contribution successful");
        }else if(block.timestamp > deadline && address(this).balance > 0){
            contibutionState = State.Failed;
            emit ContibutionState("Contribution failed");
        }else{
            require(contibutionState == State.Active);
            contribution[msg.sender] += msg.value;
            emit Deposit(msg.sender, msg.value);
        }
    }
    //GoalChecking
    //Owner only
    function withdraw() external onlyOwner {
        require(contibutionState == State.Successful, "Contribution unsuccessful");
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
        emit Withdraw(msg.sender, address(this).balance);
    }
    //Contributors refund
    function refund() external nonReentrant notOwner{
        require(contibutionState == State.Failed, "No refunds to claim");
        uint amount = contribution[msg.sender];
        contribution[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Refund failed");
        emit Refund(msg.sender, amount);

    }

}