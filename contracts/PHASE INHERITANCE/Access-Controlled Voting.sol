// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract BaseVoting{
    struct Proposal {
        string name;
        uint voteCount;
    }
    Proposal[] public proposals;
    mapping(uint => Proposal) id;
    mapping (uint => mapping(address => bool)) hasVoted;
    //Events
    event ProposalCreated(address indexed creator, uint id, uint timestamp);
    event VoteCasted(address indexed voter, uint id, uint timestamp);
    function createProposal(string memory _name) public virtual {
        Proposal memory proposal = Proposal(_name, 0);
        proposals.push(proposal);
        uint index = proposals.length - 1;
        id[index] = proposal;
        emit ProposalCreated(msg.sender, index, block.timestamp);
    }
    function vote(uint _id) public virtual{
        require(proposals.length > 0, "No proposals available");
        require(!hasVoted[_id][msg.sender], "Already voted on this proposal");
        proposals[_id].voteCount ++;
        hasVoted[_id][msg.sender] = true;
        emit VoteCasted(msg.sender, _id, block.timestamp);
    }
}

contract AdminVoting is BaseVoting{
    address public admin;
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not Admin");
        _;
    }
    constructor() {
        admin = msg.sender;
    }
    function createProposal(string memory _name) public override onlyAdmin{
        super.createProposal(_name);
    }

}

contract RestrictedVoting is AdminVoting {
    mapping(address => bool) canVote;
    event VoterAdded(address voter, uint timestamp);
    function addVoter(address _voter) public onlyAdmin {
        require(!canVote[_voter], "Already a voter");
        canVote[_voter] = true;
        emit VoterAdded(_voter, block.timestamp);
    }
    function vote(uint _id) public override {
        require(canVote[msg.sender], "Not a whitelisted voter");
        super.vote(_id);
    }
}