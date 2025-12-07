// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract AccessControl{
    address owner;
    //Custom Errors
    error NotOwner();
    error InvalidAddress();
    //Events
    event OwnerSet(address owner, address newOwner);
    modifier onlyOwner(){
        if(msg.sender != owner) revert NotOwner();
        _;
    }
    modifier validAddress(address _addr) {
        if(_addr == msg.sender) revert InvalidAddress();
        _;
    }
    constructor(){
        owner = msg.sender;
    }
    function setOwner(address _newOwner) public virtual onlyOwner{
        owner = _newOwner;
        emit OwnerSet(msg.sender, _newOwner);
    }
    function getOwner() external view returns(address){
        return owner;
    }
}

contract AdminControl is AccessControl{
    mapping(address => bool) admins;
    uint256 counter;
    //Custom Errors
    error AlreadyAdmin();
    error NotAdmin();
    //Events
    event AdminAdded(address owner, address newAdmin);
    event AdminRemoved(address owner, address admin);

    function addAdmin(address _newAdmin) external onlyOwner validAddress(_newAdmin){
        if(admins[_newAdmin]) revert AlreadyAdmin();
        admins[_newAdmin] = true;
        counter++;
        emit AdminAdded(msg.sender, _newAdmin);
    }
    function removeAdmin(address _admin) external onlyOwner{
        if(!admins[_admin]) revert NotAdmin(); 
        admins[_admin] = false;
        counter--;
        emit AdminRemoved(msg.sender, _admin);
    }
    function isAdmin(address _admin) external view returns(bool){
        return admins[_admin];
    }
}

contract UserControl is AdminControl{
    mapping(address => bool) users;
    //Custom Errors
    error AlreadyUser();
    error NotUser();
    error ActiveAdminsPresent();

    //Events
    event userAdded(address admin, address newUser);
    event userRemoved(address admin, address user);
    modifier onlyAdmin(){
        if(!admins[msg.sender]) revert NotAdmin();
        _;
    }

    function addUser(address _newUser) external onlyAdmin validAddress(_newUser){
        if(users[_newUser])revert AlreadyUser();
        users[_newUser] = true;
        emit userAdded(msg.sender, _newUser);
    }
    function removeUser(address _user) external onlyAdmin{
        if(!users[_user]) revert NotUser();
        users[_user] = false;
        emit userRemoved(msg.sender, _user);
    }
    function isUser(address _user) external view returns(bool){
        return users[_user];
    }
    function setOwner(address _newOwner) public override onlyOwner validAddress(_newOwner){
        if(counter != 0) revert ActiveAdminsPresent();
        super.setOwner(_newOwner);
    }
}