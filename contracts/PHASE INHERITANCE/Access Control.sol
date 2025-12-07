// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract AccessControl{
    address owner;
    //Events
    event OwnerSet(address owner, address newOwner);
    modifier onlyOwner(){
        require(msg.sender == owner, "Not Owner");
        _;
    }
    constructor(){
        owner = msg.sender;
    }
    function setOwner(address _newOwner) public virtual onlyOwner{
        owner = _newOwner;
        emit OwnerSet(msg.sender, _newOwner);
    }
    function getOwner() public view returns(address){
        return owner;
    }
}

contract AdminControl is AccessControl{
    address[] public adminsArr;
    mapping(address => bool) admins;
    //Events
    event AdminAdded(address owner, address newAdmin);
    event AdminRemoved(address owner, address admin);

    function addAdmin(address _newAdmin) public onlyOwner{
        require(!admins[_newAdmin], "Already an admin");
        admins[_newAdmin] = true;
        adminsArr.push(_newAdmin);
        emit AdminAdded(msg.sender, _newAdmin);
    }
    function removeAdmin(address _admin) public onlyOwner{
        require(admins[_admin] == true, "Not Admin");
        admins[_admin] = false;
        emit AdminRemoved(msg.sender, _admin);
    }
    function isAdmin(address _admin) public view returns(bool){
        return admins[_admin];
    }
}

contract UserControl is AdminControl{
    mapping(address => bool) users;
    //Events
    event userAdded(address admin, address newUser);
    event userRemoved(address admin, address user);
    modifier onlyAdmin(){
        require(admins[msg.sender] == true, "Not Admin");
        _;
    }

    function addUser(address _newUser) public onlyAdmin{
        require(!users[_newUser], "Already a user");
        users[_newUser] = true;
        emit userAdded(msg.sender, _newUser);
    }
    function removeUser(address _user) public onlyAdmin{
        require (users[_user] == true, "Not User");
        users[_user] = false;
        emit userRemoved(msg.sender, _user);
    }
    function isUser(address _user) public view returns(bool){
        return users[_user];
    }
    function setOwner(address _newOwner) public override onlyOwner {
        require(adminsArr.length == 0, "Cannot transfer ownership with active admins");
        super.setOwner(_newOwner);
        emit OwnerSet(msg.sender, _newOwner);
    }
}