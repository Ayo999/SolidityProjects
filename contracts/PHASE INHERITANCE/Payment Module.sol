//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract PaymentModule{
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

contract RoyaltySplitter is PaymentModule{
    address platform;
    uint artistShare;
    uint platformShare;
    constructor(address _platform, uint _platformShare) 
    {
        platform = _platform;
        platformShare = _platformShare;

    }
    function release(address _to, address artist, uint _amount, uint _artistShare) public virtual onlyOwner{
        uint amount = _amount * 1 ether;
        uint artistCut = (amount * _artistShare) / 100;
        uint platformCut = (amount * platformShare) / 100;
        uint remainder = amount - (artistCut + platformCut);
        (bool success, ) = artist.call{value:artistCut}("");
        require(success);
        (bool success2, ) = platform.call{value:platformCut}("");
        require(success2);
        super.release(_to, remainder);
    }
}

contract RoyaltySplitterV2 is RoyaltySplitter {
    mapping(address => uint) customArtistShare;
    constructor(address _artist, address _platform, uint _platformShare)
        RoyaltySplitter(_artist, _platform, _platformShare) {

        }
    function setCustomRoyalty(address _artist, uint _share) external onlyOwner {
        customArtistShare[_artist] = _share;
    }
    function release(address _to, uint _amount) public override onlyOwner nonreentrant{
        uint shareToUse = customArtistShare[artist] > 0 ? customArtistShare[artist] : 10;
        super.release(_to, _amount, shareToUse);
    }

}