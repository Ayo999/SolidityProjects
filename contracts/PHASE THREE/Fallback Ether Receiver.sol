// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract Escrow{
    address buyer;
    address seller;
    address mediator;
    uint amount;
    bool delivered;
    uint deadline;
    bool private locked;
    enum State {Inactive, Active, Disputed, Released, Refunded, Closed}
    State public state;
    constructor(address _buyer, address _seller, address _mediator, uint _amount, uint _deadline) {
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
        amount = _amount * 1 ether;
        deadline = (_deadline * 1 minutes) + block.timestamp;
    }
    //Events
    event Deposited(address buyer, uint amount);
    event Released(address seller, uint amount);
    event Disputed(address buyer, uint timestamp);
    event ResolvedToSeller(address seller, address mediator);
    event ResolvedToBuyer(address buyer, address mediator);
    //Modifiers
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }
    modifier nonReentrant() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    modifier active() {
        require(state == State.Active, "Contract inactive");
        _;
    }
    modifier onlyMediator() {
        require(msg.sender == mediator, "Not mediator");
        _;
    }
    //Depositing Funds
    function deposit() external payable onlyBuyer{
        require(state == State.Inactive, "Cannot deposit in current state");
        require(msg.value == amount, "Buyer should deposit the exact amount agreed upon");
        state = State.Active;
        emit Deposited(msg.sender, msg.value);
    }
    //Buyer actions
    function confirmDelivery() public active onlyBuyer nonReentrant{
        state = State.Released;
        _sendToSeller();
        emit Released(seller, amount);
    }
    function dispute() external active onlyBuyer{
        require(block.timestamp < deadline, "Dispute window closed");
        state = State.Disputed;
        emit Disputed(msg.sender, block.timestamp);
    }
    //Auto Release
    function autorelease() external active{
        require(block.timestamp >= deadline, "Deadline not reached");
        confirmDelivery();
    }
    //Mediator only
    function resolveToSeller() external nonReentrant onlyMediator{
        require(state == State.Disputed, "Order is not disputed");
        state = State.Closed;
        _sendToSeller();
        emit ResolvedToSeller(seller, msg.sender);
    }
    function resolveToBuyer() external nonReentrant onlyMediator{
        require(state == State.Disputed, "Order is not disputed");
        state = State.Closed;
        (bool success, ) = buyer.call{value:amount}("");
        require(success, "Funds release failed");
        emit ResolvedToBuyer(buyer, msg.sender);
    }
    function _sendToSeller() internal {
        (bool success, ) = seller.call{value:amount}("");
        require(success, "Funds release failed");
    }
}