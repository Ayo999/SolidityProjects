// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract BasicBank {
    address public owner;
    bool private locked;
    mapping(address => uint) public balanceOf;
    //Events
    event Deposit(address indexed sender, uint value);
    event Receive(address indexed sender, uint value);
    event Fallback(address indexed sender, uint value);
    event Withdraw(address indexed recipient, uint value);
    event FeeUpdated(uint newFee, uint timestamp);
    event PremiumUserAdded(address indexed user, uint timestamp);
    event PremiumUserRemoved(address indexed user, uint timestamp);
    event FeesWithdrawn(address recipient, uint value);
    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    modifier nonreentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    constructor() {
        owner = msg.sender;
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    receive() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Receive(msg.sender, msg.value);
    }
    fallback() external payable {
        balanceOf[msg.sender] += msg.value;
        emit Fallback(msg.sender, msg.value);
    }
    function withdraw(uint _amount) public virtual {
        uint amount = _amount * 1 ether;
        require(amount <= balanceOf[msg.sender], "Insufficient funds");
        balanceOf[msg.sender]-= _amount * 1 ether;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        emit Withdraw(msg.sender, amount);
    }
}

contract FeeBank is BasicBank{
    uint public feePercentage = 10;
    function withdraw(uint _amount, bool chargeFee) public virtual{
        if(!chargeFee) {
            super.withdraw(_amount);
            return;
        }
        uint amountInWei = _amount * 1 ether;
        uint fee = (_amount * feePercentage) / 100;
        uint payout = _amount - fee;
        require(balanceOf[msg.sender] >= amountInWei, "Insufficient funds");
        balanceOf[msg.sender] -= fee * 1 ether;
        super.withdraw(payout);

        uint feeInWei = fee * 1 ether;
        (bool success, ) = payable(owner).call{value:feeInWei}("");
        require(success, "Fees Withdrawal failed");
        emit FeesWithdrawn(msg.sender, feeInWei);

    }
    function updateFee(uint _newFeePerc) public onlyOwner {
        feePercentage = _newFeePerc;
        emit FeeUpdated(_newFeePerc, block.timestamp);
    }
}

contract PremiumBank is FeeBank{
    mapping(address => bool) public premiumUser;
    function addPremiumUser(address _user) public onlyOwner{
        require(!premiumUser[_user], "Already a premium user");
        premiumUser[_user] = true;
        emit PremiumUserAdded(_user, block.timestamp);
    }
    function removePremiumUser(address _user) public onlyOwner{
        require(premiumUser[_user], "Not a premium user");
        premiumUser[_user] = false;
        emit PremiumUserRemoved(_user, block.timestamp);
    }

    function withdraw(uint _amount) public override nonreentrant{
        bool isPremium = premiumUser[msg.sender];
        super.withdraw(_amount, !isPremium);
    }
}