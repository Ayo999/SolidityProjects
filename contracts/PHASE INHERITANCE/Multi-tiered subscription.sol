// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract PaymentModule {
    address owner;
    bool private locked;
    //Events
    event Deposit(address sender, uint value);
    event Receive(address sender, uint value);
    event Release(address recipient, uint value);
    constructor() {
            owner = msg.sender;
        }
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

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
    function release(address _to, uint _amount) public virtual onlyOwner{
        (bool success, ) = _to.call{value:_amount}("");
        require(success);
        emit Release(_to, _amount);
    }
}

contract SubscriptionManager is PaymentModule {
    address public platform;
    uint creatorShare;
    uint platformShare;
    struct Creator {
        address wallet;
        uint artistShare;
    }
    struct Tier {
        uint price;
        uint duration;
    }
    mapping(address => Creator) creators;
    mapping(uint => Tier) tierId;
    mapping(address => uint) userTier;
    mapping(address => uint) subscriptionEnd;

    constructor(address _platform, uint _creatorShare, uint _platformShare) {
        platform = _platform;
        creatorShare = _creatorShare;
        platformShare = _platformShare;
    }
    function registerCreator(address _creator, uint _share) public onlyOwner {
        creators[_creator] = Creator(_creator, _share);
    }
    function addTier(uint _id, uint _price, uint _duration) public onlyOwner {
        Tier memory tier = Tier(_price, _duration);
        tierId[_id] = tier;
    }  
    function subscribe(uint _id) public payable {
        require(msg.value == tierId[_id].price * 1 ether, "Deposit exact price for your desired tire");
        userTier[msg.sender] = _id;
    }
    function release(address _to, uint _amount) public override onlyOwner {
        uint amount = _amount * 1 ether;
        uint creatorCut = (amount * creatorShare) / 100;
        uint platformCut = (amount * platformShare) / 100;
        uint remainder = amount - (creatorCut + platformCut);

        (bool success, ) = creators.call{value: creatorCut}("");
        require(success, "Creator release failed");
        (bool success2, ) = platform.call{value: platformCut}("");
        require(success2, "Platform release failed");
        super.release(_to, remainder);

    }
}

contract AdvancedSubscriptionManager is SubscriptionManager {
    constructor(address _platform, uint _creatorShare, uint _platformShare) 
    SubscriptionManager(_platform, _creatorShare, _platformShare) {

    }
}