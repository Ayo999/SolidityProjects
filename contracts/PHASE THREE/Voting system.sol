//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract VotingSystem {
    uint totalVotes;
    uint count;
    address owner;
    struct Candidate {
        string name;
        uint voteCount;
    }
    mapping(uint => Candidate) candidate;
    mapping(uint => uint) idtoIndex;
    mapping(address => bool) voted;
    enum Status {Created, Ongoing, Ended}
    Status voteStatus;
    //Custom Errors
    error NotOwner();
    error votingInProgress();
    error votingInactive();
    error NullCandidates();
    error InsufficientVotes();
    error InvalidVoter();
    error AlreadyVoted();
    //Events
    event CandidateRegistered(string _name);
    event votingStarted(uint timestamp);
    event votingEnded(uint timestamp);
    event Votecast(address indexed voter, uint candidateId);
    //Modifiers
    modifier onlyOwner() {
        if(msg.sender != owner) revert NotOwner();
        _;
    }
    modifier voteOngoing() {
        if(voteStatus != Status.Ongoing) revert votingInactive();
        _;
    }
    modifier voteInactive() {
        if(voteStatus == Status.Ongoing) revert votingInProgress();
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    //Admin-only actions
    function addCandidate(string calldata _name, uint _id) external onlyOwner voteInactive {
        Candidate memory candidates = Candidate(_name, 0);
        candidate[count] = candidates;
        idtoIndex[_id] = count;
        count++;
        // CandidateIndex[_name] = candidatesArr.length - 1;
        emit CandidateRegistered(_name);
    }
    function startVoting() external onlyOwner voteInactive {
        if(count == 0) revert NullCandidates();
        voteStatus = Status.Ongoing;
        emit votingStarted(block.timestamp);
    }
    function closeVoting() external onlyOwner voteOngoing{
        if(totalVotes == 0) revert InsufficientVotes();
        voteStatus = Status.Ended;
        emit votingEnded(block.timestamp);
    }
    //Voting Phase
    function vote(uint _id) external voteOngoing{
        if(msg.sender == owner) revert InvalidVoter();
        if(voted[msg.sender]) revert AlreadyVoted();
        uint index = idtoIndex[_id];
        candidate[index].voteCount++;
        voted[msg.sender] = true;
        totalVotes++;
        emit Votecast(msg.sender, _id);
    }
    //Results Phase
    function getCandidates() external voteInactive view returns(Candidate[] memory){
        Candidate[] memory Candidates = new Candidate[](count);
        for(uint i; i < count; ++i){
            Candidates[i] = candidate[i];
        }
        return Candidates;
    }
    function getTotalVotes() external voteInactive view returns(uint){
        return totalVotes;
    }
    function getVoterStatus(address _voter) external view returns(bool) {
        return voted[_voter];
    }
    function getElectionState() external view returns(Status){
        return voteStatus;
    }
    function getWinner() external voteInactive view returns(string memory winnerName, uint winnerVotes){
        uint highestCount;
        uint winnerIndex;
        for(uint i; i < count; i++){
            if(candidate[i].voteCount > highestCount){
                highestCount = candidate[i].voteCount;
                winnerIndex = i;
            }
        }
        winnerName = candidate[winnerIndex].name;
        winnerVotes = candidate[winnerIndex].voteCount;
    }
}

