// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract SimpleMarketplace{
    struct Product{
        uint id;
        string name;
        string description;
        uint price;
        Status status;
        address seller;
        address buyer;
    }
    Product[] productsArr;
    enum Status{Listed, Sold, Cancelled, Completed, Disputed}
    mapping(uint id => uint index) productIdtoIndex;
    //Events
    event ProductListed(uint productId, address seller, uint price);
    event ProductPurchased(uint productId, address buyer, uint price);
    event DeliveryConfirmed(uint productId, address buyer, address seller, uint amount);
    event DisputeRaised(uint productId, address buyer, string reason);
    event RefundIssued(uint productId, address buyer, uint amount);
    //Modifiers

    //Seller
    function listProduct(uint _id, string calldata _name, string calldata _description, uint _price) external {
        Product memory product = Product(_id, _name, _description, _price, Status.Listed, msg.sender, address(0));
        productsArr.push(product);
        uint index = productsArr.length - 1;
        productIdtoIndex[_id] = index;
        emit ProductListed(productsArr[index].id, msg.sender, productsArr[index].price);
    }
    function purchase(uint _id) external payable{
        Product storage prod = productsArr[productIdtoIndex[_id]];
        require(prod.status == Status.Listed);
        require(msg.value == prod.price);
        prod.status = Status.Sold;
        prod.buyer = msg.sender;
        emit ProductPurchased(_id, msg.sender, prod.price);
    }
    function confirmDelivery(uint _id) external {
        Product storage prod = productsArr[productIdtoIndex[_id]];
        require(msg.sender == prod.buyer);
        prod.status = Status.Completed;
        (bool success, ) = prod.seller.call{value:prod.price}("");
        require(success, "Transfer failed");
        emit DeliveryConfirmed(_id, prod.buyer, prod.seller, prod.price);
    }
    function raiseDispute(uint _id, string calldata _reason) external {
        Product storage prod = productsArr[productIdtoIndex[_id]];
        require(msg.sender == prod.buyer);
        require(prod.status == Status.Sold);
        prod.status = Status.Disputed;
        emit DisputeRaised(_id, prod.buyer, _reason);

    }
}