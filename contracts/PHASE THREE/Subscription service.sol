// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract SubscriptionService{
    uint amount;
    address owner;
    bool private locked;

    constructor(uint _amount) {
        amount = _amount * 1 ether;
        owner = msg.sender;
    }
    struct Subscription{
        address subscriber;
        uint startTime;
        uint expirationTime;
        State state;
    }
    enum State {Inactive, Active, Expired}
    Subscription[] Subscriptions;
    //Events
    event SubscriptionStarted(address indexed subscriber, uint expiry);
    event SubscriptionRenewed(address indexed subscriber, uint expiry);
    event SubscriptionExpired(address indexed subscriber);
    event FeeUpdated(uint newFee);
    event FundsWithdrawn(address indexed owner, uint amount);
    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier exactFee() {
        require(msg.value == amount, "Deposit exact fee");
        _;
    }
    modifier subscribed() {
        require(subscriptions[msg.sender].state != State.Inactive, "Not Subscribed");
        _;
    }
    modifier checkExpiry() {
        if(block.timestamp > subscriptions[msg.sender].expirationTime) {
            subscriptions[msg.sender].state = State.Expired;
            emit SubscriptionExpired(msg.sender);
            revert ("Subscription Expired");
        } 
        _;
    }
    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    mapping(address => Subscription) public subscriptions;
    function subscribe() external payable exactFee {
        require(subscriptions[msg.sender].state == State.Inactive, "Already a subscriber");
        Subscription memory subscription = Subscription(msg.sender, block.timestamp, block.timestamp + 30 days, State.Active);
        Subscriptions.push(subscription);
        subscriptions[msg.sender].state = State.Active;
        emit SubscriptionStarted(msg.sender, block.timestamp + 30 days);
    }
    function renewSubscription() external payable subscribed exactFee {
        Subscription storage sub = subscriptions[msg.sender];
        if(block.timestamp > sub.expirationTime){
            sub.expirationTime = block.timestamp + 30 days;
        }else{
            sub.expirationTime += 30 days;
        }
        emit SubscriptionRenewed(msg.sender, sub.expirationTime);
    }
    function accessContent() external subscribed checkExpiry returns(uint){
        return subscriptions[msg.sender].expirationTime - block.timestamp;
    }
    function updateFee(uint _amount) public onlyOwner {
        amount = _amount * 1 ether;
        emit FeeUpdated(amount);
    }
    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal Failed");
        emit FundsWithdrawn(msg.sender, address(this).balance);
    }
}