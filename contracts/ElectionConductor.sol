// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import Election.sol
import "./Election.sol";

// ! errors
error NotAuthorized();
error ElectionNotFound();

contract ElectionConductor {
    mapping(address => Election) public authorityEmail;

    // ! anybody should be able to create election
    function createElection(
        string memory _electionName,
        string memory _electionDescription
    ) public {
        Election election = new Election(
            address(this),
            _electionName,
            _electionDescription
        );
        authorityEmail[msg.sender] = election;
    }

    function getRegisteredElection(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (
            address electionAddress,
            string memory electionName,
            string memory electionDescription
        )
    {
        return (
            authorityEmail[_authorityAddress].getElectionAddress(),
            authorityEmail[_authorityAddress].getElectionName(),
            authorityEmail[_authorityAddress].getElectionDescription()
        );
    }

    // ! ELECTION CONTRACT SPECIFIC FUNCTIONS

    // ! modifier onlyAuthority makes sure that only the authority can add a candidate
    function addCandidate(
        address _authorityAddress,
        string memory _name,
        string memory _imgUrl,
        string memory _email
    ) public isExist(_authorityAddress) onlyAuthority(_authorityAddress) {
        authorityEmail[_authorityAddress].addCandidate(_name, _imgUrl, _email);
    }

    function registerVoter(
        address _authorityAddress,
        address _address,
        uint8 _id_voted
    ) public isExist(_authorityAddress) {
        authorityEmail[_authorityAddress].registerVoter(_address, _id_voted);
    }

    // ! modifier onlyAuthority makes sure that only the authority can add a voter
    function addVoters(address _authorityAddress, address _voterAddress)
        public
        isExist(_authorityAddress)
        onlyAuthority(_authorityAddress)
    {
        authorityEmail[_authorityAddress].addVoters(_voterAddress);
    }

    function vote(
        address _authorityAddress,
        address _voterAddress,
        uint8 _candidateId
    ) public isExist(_authorityAddress) {
        authorityEmail[_authorityAddress].vote(_voterAddress, _candidateId);
    }

    function declareWinnerCandidate(address _authorityAddress)
        public
        isExist(_authorityAddress)
        onlyAuthority(_authorityAddress)
        returns (uint8 winnerId)
    {
        return authorityEmail[_authorityAddress].declareWinnerCandidate();
    }

    // ! modifier onlyAuthority makes sure that only the authority can start the election
    function startElection(address _authorityAddress)
        public
        isExist(_authorityAddress)
        onlyAuthority(_authorityAddress)
    {
        authorityEmail[_authorityAddress].startElection();
    }

    // ! modifier onlyAuthority makes sure that only the authority can end the election
    function endElection(address _authorityAddress)
        public
        isExist(_authorityAddress)
        onlyAuthority(_authorityAddress)
    {
        authorityEmail[_authorityAddress].endElection();
    }

    // ! ELECTION CONTRACT SPECIFIC VIEW FUNCTIONS
    function getElectionAddress(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (address)
    {
        return authorityEmail[_authorityAddress].getElectionAddress();
    }

    function getElectionName(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (string memory)
    {
        return authorityEmail[_authorityAddress].getElectionName();
    }

    function getElectionDescription(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (string memory)
    {
        return authorityEmail[_authorityAddress].getElectionDescription();
    }

    function getNumofCandidates(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (uint8)
    {
        return authorityEmail[_authorityAddress].getNumofCandidates();
    }

    function getNumofVoters(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (uint32)
    {
        return authorityEmail[_authorityAddress].getNumofVoters();
    }

    function getAuthorityAddress(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        returns (address)
    {
        return authorityEmail[_authorityAddress].getAuthorityAddress();
    }

    function getPendingVoter(address _authorityAddress, address _voterAddress)
        public
        view
        isExist(_authorityAddress)
        returns (
            address,
            uint8,
            bool
        )
    {
        return authorityEmail[_authorityAddress].getPendingVoter(_voterAddress);
    }

    function getWinnerCandidateId(address _authorityAddress)
        public
        view
        isExist(_authorityAddress)
        onlyAuthority(_authorityAddress)
        returns (uint8)
    {
        return authorityEmail[_authorityAddress].getWinnerCandidateId();
    }

    function getCandidateDetails(address _authorityAddress, uint8 _candidateId)
        public
        view
        isExist(_authorityAddress)
        returns (
            string memory name,
            string memory imgUrl,
            string memory email
        )
    {
        return
            authorityEmail[_authorityAddress].getCandidateDetails(_candidateId);
    }

    function getVoterDetails(address _authorityAddress, address _voterAddress)
        public
        view
        isExist(_authorityAddress)
        returns (
            address,
            uint8,
            bool
        )
    {
        return authorityEmail[_authorityAddress].getVoterDetails(_voterAddress);
    }

    modifier isExist(address _authorityAddress) {
        if (authorityEmail[_authorityAddress] == Election(address(0))) {
            revert ElectionNotFound();
        }
        _;
    }
    modifier onlyAuthority(address _authorityAddress) {
        if (msg.sender != _authorityAddress) {
            revert NotAuthorized();
        }
        _;
    }
}
