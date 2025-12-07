//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract TodoList{
    struct Task {
        string description;
        string task;
        bool completed;
    }
    // enum Status {Pending, Completed}
    mapping(address user => Task[] todo) list;
    //Events
    event TaskCreated(address user, string description, bool completed);
    event TaskCompleted(address user, uint taskId);
    event TaskDeleted(address user, uint taskId);
    //Modifiers
    modifier onlyOwner(address _owner){
        require(msg.sender == _owner, "Not Owner");
        _;
    }
    modifier validIndex(uint index){
        require(index < list[msg.sender].length, "Task does not exist");
        _;
    }
    function addTask(string calldata _description, string calldata _task) external {
        Task memory task = Task(_description, _task, false);
        list[msg.sender].push(task);
        emit TaskCreated(msg.sender, _description, false);
    }
    function completeTask(address _owner, uint index) external onlyOwner(_owner) validIndex(index){
        list[_owner][index].completed = true;
        emit TaskCompleted(msg.sender, index);
    }
    function deleteTask(address _owner, uint index) external onlyOwner(_owner) validIndex(index){
        Task[] storage tasks = list[_owner];
        for(uint i = index; i < tasks.length - 1; i++){
            tasks[i] = tasks[i + 1];
        }
        tasks.pop();
        emit TaskDeleted(_owner, index);
    }
    function getTask(address _owner) external view returns(Task[] memory){
        return list[_owner];
    }
}