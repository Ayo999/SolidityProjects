// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
abstract contract PaymentProcessor{
    uint public totalProcessed;
    function processPayment(uint amount) internal virtual;
    function deposit() public payable {
        processPayment(msg.value);
    } 

}

contract FixedChargeProcessor is PaymentProcessor {
    uint fee;
    constructor(uint _fee) {
        fee = _fee * 1 ether;
    }
    function processPayment(uint amount) internal virtual override {
        uint remainder = amount - fee;
        totalProcessed += remainder;
        (bool success, ) = msg.sender.call{value:remainder}("");
        require(success, "Withdrawal failed");
    }
}

contract PercentageChargeProcessor is FixedChargeProcessor {
    constructor(uint _fee)
    FixedChargeProcessor(_fee){

    }
    function processPayment(uint amount) internal override {
        uint PercentageFee = 5;
        uint fee = (PercentageFee * amount) / 100;
        uint remainder = amount - fee;
        totalProcessed += remainder;
        (bool success, ) = msg.sender.call{value:remainder}("");
        require(success, "Withdrawal failed");
    }
}