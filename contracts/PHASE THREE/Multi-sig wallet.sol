// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract MultisigWallet{
    //State Variables
    uint requiredApprovals;
    struct Transaction{
        uint id;
        address to;
        uint value;
        uint approvalCounts;
        bool executed;
    }
    mapping(address => bool) isOwner;
    mapping(address => bool) isAdded;
    // mapping(uint => Transaction) checkId;
    mapping (uint => mapping (address => bool)) approved;
    address[] public owners;
    Transaction[] transactions;
    //Events
    event TransactionSubmitted(uint id, address to, uint value);
    event Fallback(address indexed, uint value, bytes data, uint timestamp);
    event Receive(address indexed, uint value, uint timestamp);
    event DepositReceived(address indexed, uint value, uint timestamp);
    event ApprovalReceived(address indexed, uint id);
    event ApprovalRevoked(address indexed, uint id);
    event TransactionExecuted(uint id, address indexed executor);
    // event OwnerAdded(address indexed newOwner, uint timestamp);
    // event OwnerRemoved(address indexed removedOwner, uint timestamp);
    //Modifiers
    modifier onlyOwner(){
        require(isOwner[msg.sender], "Not Owner");
        _;
    }

    modifier validTx(uint _id){
        require(_id < transactions.length, "Invalid transaction");
        require(!transactions[_id].executed, "Already executed");
        _;
    }
    //Constructor
    constructor(address[] memory _owners, uint _approvals) {
        owners.push(msg.sender);
        isOwner[msg.sender] = true;
        for(uint i=0; i < _owners.length; i++){
            address owner = _owners[i];
            require(!isOwner[owner], "Owner not unique");
            owners.push(owner);
            isOwner[owner] = true;
        }
        require(_approvals >=2 && _approvals <= owners.length, "Required approvals cannot be more than owners");
        requiredApprovals = _approvals;
        
    }
    // Deposit ETH
    fallback() external payable {
        emit Fallback(msg.sender, msg.value, msg.sender.code, block.timestamp);
    }
    receive() external payable {
        emit Receive(msg.sender, msg.value, block.timestamp);
    }
    function deposit() external payable {
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
    }

    //Only Admin functions
    function submitTx(address to, uint value) external onlyOwner{
        Transaction memory transaction = Transaction(0, to, value * 1 ether, 0, false);
        transactions.push(transaction);
        uint txId = transactions.length - 1;
        transactions[txId].id = txId;
        // checkId[_id] = transaction;
        emit TransactionSubmitted(transactions.length, to, value);
    }
    function approveTx(uint _id) external onlyOwner validTx(_id){
        require(!approved[_id][msg.sender], "Already approved");
        approved[_id][msg.sender] = true;
        // checkId[_id].approvalCounts++;
        transactions[_id].approvalCounts++;
        emit ApprovalReceived(msg.sender, _id);
    }
    function revokeApproval(uint _id) external onlyOwner validTx(_id){
        require(approved[_id][msg.sender], "Not approved");
        approved[_id][msg.sender] = false;
        // checkId[_id].approvalCounts--;
        transactions[_id].approvalCounts--;
        emit ApprovalRevoked(msg.sender, _id);
    }
    function executeTx(uint _id) external onlyOwner{
        Transaction storage txs = transactions[_id];
        require(txs.executed == false, "Already executed");
        require(txs.approvalCounts >= requiredApprovals, "Insufficient approvals");
        require(address(this).balance > txs.value, "Insufficient funds");
        txs.executed = true;
        (bool success, ) = txs.to.call{value:txs.value}("amount");
        require(success, "Transaction failed");
        emit TransactionExecuted(_id, msg.sender);
    }
    // function addOwner(address _newOwner) external onlyOwner {
    //     require(!isOwner[_newOwner], "Owner not unique");
    //         owners.push(_newOwner);
    //         isOwner[_newOwner] = true;
    //         emit OwnerAdded(_newOwner, block.timestamp);

    // }
    //View functions
    function viewTx(uint _id) external view returns(Transaction memory) {
        return transactions[_id];
    }

    function getOwners() external view returns (address[] memory){
        return owners;
    }
    function getOwnersNo() external view returns(uint){
        return owners.length;
    }
}
//["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]
//["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]