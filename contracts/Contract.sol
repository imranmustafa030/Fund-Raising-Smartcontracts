// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CrowdFunding {
    mapping (address => uint) public contributers; // which will contribute in Funding
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContrubuters;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping (uint => Request) public requests;
    uint public numRequests;

    constructor(uint _target, uint _deadline){
        target=_target;
        deadline = block.timestamp + deadline; // in unix form
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable {
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value >= minimumContribution, "Minimum Contribution is no met");

        if (contributers[msg.sender]==0){
            noOfContrubuters++;
        }
        contributers[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount<target, "You are not eligible for refund");
        require(contributers[msg.sender]>0);
        address payable user = payable (msg.sender);
        user.transfer(contributers[msg.sender]);
        contributers[msg.sender] = 0;
    }

    modifier onlyManager(){
        require(msg.sender == manager, "Only managger can call this funtion");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributers[msg.sender] > 0, "You must be a contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false, "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage  thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "This request has been completed");
        require(thisRequest.noOfVoters > noOfContrubuters/2, "Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}