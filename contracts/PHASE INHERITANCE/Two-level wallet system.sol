// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract BaseWallet{
    mapping(address => uint) balanceOf;
    //Events
    event Deposit(address indexed sender, uint value);
    event Send(address indexed recipient, uint value);
    function deposit() payable public virtual {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function _send(address recipient, uint _amount) internal virtual{
        uint amount = _amount * 1 ether;
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Send failed");
        emit Send(recipient, amount);
    }
}

contract TimeLockWallet is BaseWallet{
    uint unlockDuration;
    mapping(address => uint) unlockTime;
    constructor(uint _unlockDuration){
        unlockDuration = _unlockDuration;
    }
    function deposit() payable public virtual override {
        uint unlock = unlockDuration * 1 minutes;
        super.deposit();
        unlockTime[msg.sender] = block.timestamp + unlock;
    }
    function withdraw(uint _amount) public virtual {
        require(block.timestamp >= unlockTime[msg.sender], "Funds not unlocked yet");
        _send(msg.sender, _amount);
    }
}

contract ParentWallet is TimeLockWallet{
    mapping(address => mapping(address => bool)) isParent;
    constructor(uint _unlockDuration)
    TimeLockWallet(_unlockDuration){

    }
    function setChild(address _child) public {
        require(!isParent[msg.sender][_child], "Already a child");
        isParent[msg.sender][_child] = true;
    }
    function depositFor(address _child) payable public{
        require(isParent[msg.sender][_child], "Not child");
        balanceOf[_child] += msg.value;

    }
    function withdrawFromChild(address _child, uint _amount)
}