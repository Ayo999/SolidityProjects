//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract VotingSystem {
    uint totalVotes;
    address owner;
    struct Candidate {
        string name;
        uint voteCount;
    }
    Candidate[] candidatesArr;
    mapping(string => uint) CandidateIndex;
    mapping(address => bool) voted;
    enum Status {Created, Ongoing, Ended}
    Status voteStatus;
    //Events
    event CandidateRegistered(string _name);
    event votingStarted();
    event votingEnded();
    event Votecast(address indexed voter, string candidateName);
    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    modifier voteOngoing() {
        require(voteStatus == Status.Ongoing, "Voting not in progress");
        _;
    }
    modifier voteInactive() {
        require(voteStatus != Status.Ongoing, "Voting already in progress");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    //Admin-only actions
    function addCandidate(string calldata _name) public onlyOwner voteInactive {
        Candidate memory candidates = Candidate(_name, 0);
        candidatesArr.push(candidates);
        CandidateIndex[_name] = candidatesArr.length - 1;
        emit CandidateRegistered(_name);
    }
    function startVoting() public onlyOwner voteInactive {
        require(candidatesArr.length > 1, "Input Candidates");
        voteStatus = Status.Ongoing;
        emit votingStarted();
    }
    function closeVoting() public onlyOwner voteOngoing{
        require(totalVotes > 1, "Total votes should be more than 0");
        voteStatus = Status.Ended;
        emit votingEnded();
    }
    //Voting Phase
    function vote(string calldata _name) public voteOngoing{
        require (msg.sender != owner, "Owner cannot vote");
        require(voted[msg.sender] == false);
        uint index = CandidateIndex[_name];
        candidatesArr[index].voteCount++;
        voted[msg.sender] = true;
        totalVotes++;
        emit Votecast(msg.sender, _name);
    }
    //Results Phase
    function getCandidates() public voteInactive view returns(Candidate[] memory){
        return candidatesArr;
    }
    function getTotalVotes() public voteInactive view returns(uint){
        return totalVotes;
    }
    function getVoterStatus(address _voter) public view returns(bool) {
        return voted[_voter];
    }
    function getElectionState() public view returns(Status){
        return voteStatus;
    }
    function getWinner() public voteInactive view returns(string memory winnerName, uint winnerVotes){
        uint highestCount;
        uint winnerIndex;
        for(uint i = 0; i < candidatesArr.length; i++){
            if(candidatesArr[i].voteCount > highestCount){
                highestCount = candidatesArr[i].voteCount;
                winnerIndex = i;
            }
        }
        winnerName = candidatesArr[winnerIndex].name;
        winnerVotes = candidatesArr[winnerIndex].voteCount;
    }
}

