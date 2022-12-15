// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ! errors
error VoterNotFound(address voterAddress);
error VoterAlreadyRegistered(address voterAddress);
error VoterAlreadyVoted(address voterAddress);
error CandidateNotFound();
error ElectionNotStarted();
error ElectionNotEnded();
error ElectionEnded();

contract Election {
    // ! Type declarations
    struct Candidate {
        string name;
        string imgUrl;
        string email;
        uint16 voteCount;
    }

    struct Voter {
        address voterAddress;
        uint8 id_voted;
        bool voted;
    }

    enum ElectionState {
        CREATED,
        STARTED,
        ENDED
    }

    // ! State variables
    address authorityAddress;
    string electionName;
    string electionDescription;
    ElectionState electionState;
    uint8 public candidateCount;
    uint32 votersCount;
    uint8 internal winningCandidateId;

    // ! mapping of Candidates - so only registered candidates can get voted
    mapping(uint8 => Candidate) internal candidates;

    // ! mapping of voters - so only registered voters can vote
    mapping(address => Voter) internal voters;

    // ! array of pending voters to be added
    mapping(address => Voter) pendingVoters;

    constructor(
        address _authorityAddress,
        string memory _name,
        string memory _description
    ) {
        authorityAddress = _authorityAddress;
        electionName = _name;
        electionDescription = _description;
        electionState = ElectionState.CREATED;
        winningCandidateId = 0;
        candidateCount = 0;
    }

    // ! Election related functions

    function addCandidate(
        string memory _name,
        string memory _imgUrl,
        string memory _email
    ) public {
        // ! don't allow adding candidates after the election has started or ended
        if (electionState == ElectionState.ENDED) {
            revert ElectionEnded();
        }
        if (electionState == ElectionState.STARTED) {
            revert ElectionNotStarted();
        }
        uint16 voteCount = 0;
        candidateCount += 1;
        uint8 candidateId = candidateCount;
        candidates[candidateId] = Candidate(_name, _imgUrl, _email, voteCount);
    }

    // ! user can call this function to register themselves as a voter
    // ! pushed to pendingVoters mapping - then upto the authority to approve
    function registerVoter(address _address, uint8 _id_voted) public {
        // ! don't allow adding voters after the election has started or ended
        if (electionState == ElectionState.ENDED) {
            revert ElectionEnded();
        }
        if (electionState == ElectionState.STARTED) {
            revert ElectionNotStarted();
        }
        if (voters[_address].voterAddress == _address) {
            revert VoterAlreadyRegistered(_address);
        }
        pendingVoters[_address] = Voter(_address, _id_voted, false);
    }

    function addVoters(address _voterAddress) public {
        if (pendingVoters[_voterAddress].voterAddress != _voterAddress) {
            revert VoterNotFound(_voterAddress);
        }
        voters[_voterAddress] = pendingVoters[_voterAddress];
        votersCount++;
        // ! remove the voter from pendingVoters
        delete pendingVoters[_voterAddress];
    }

    // ! user can call this function to vote for a candidate
    function vote(address _voterAddress, uint8 _candidateId) public {
        // ! don't allow voting after the election has ended or not started
        // ! or if the voter is not registered
        // ! or if the voter has already voted
        // ! or if the candidate is not registered
        if (electionState == ElectionState.ENDED) {
            revert ElectionEnded();
        }
        if (electionState == ElectionState.CREATED) {
            revert ElectionNotStarted();
        }
        if (voters[_voterAddress].voterAddress != _voterAddress) {
            revert VoterNotFound(_voterAddress);
        }
        if (bytes(candidates[_candidateId].name).length == 0) {
            revert CandidateNotFound();
        }
        if (voters[_voterAddress].voted) {
            revert VoterAlreadyVoted(_voterAddress);
        }
        voters[_voterAddress].id_voted = _candidateId;
        voters[_voterAddress].voted = true;
        candidates[_candidateId].voteCount++;
    }

    function declareWinnerCandidate() public returns (uint8 winnerId) {
        if (electionState == ElectionState.CREATED) {
            revert ElectionNotStarted();
        }
        if (electionState == ElectionState.STARTED) {
            revert ElectionNotEnded();
        }
        // find max voteCount and return the candidateId
        if (winningCandidateId != 0) {
            return winningCandidateId;
        } else {
            // make this gas efficient by using memory array
            uint16 maxVoteCount = 0;
            uint8 maxVoteCountCandidateId = 1;
            for (uint8 i = 1; i <= candidateCount; i++) {
                if (candidates[i].voteCount > maxVoteCount) {
                    maxVoteCount = candidates[i].voteCount;
                    maxVoteCountCandidateId = i;
                }
            }
            winningCandidateId = maxVoteCountCandidateId;
            return maxVoteCountCandidateId;
        }
    }

    function startElection() public {
        electionState = ElectionState.STARTED;
    }

    function endElection() public {
        electionState = ElectionState.ENDED;
    }

    // ! View / pure functions
    function getElectionAddress() public view returns (address) {
        return address(this);
    }

    function getElectionName() public view returns (string memory) {
        return electionName;
    }

    function getElectionDescription() public view returns (string memory) {
        return electionDescription;
    }

    function getNumofCandidates() public view returns (uint8) {
        return candidateCount;
    }

    function getNumofVoters() public view returns (uint32) {
        return votersCount;
    }

    function getAuthorityAddress() public view returns (address) {
        return authorityAddress;
    }

    function getPendingVoter(address _voterAddress)
        public
        view
        returns (
            address voterAddress,
            uint8 id_voted,
            bool voted
        )
    {
        if (pendingVoters[_voterAddress].voterAddress != _voterAddress) {
            revert VoterNotFound(_voterAddress);
        }
        return (
            pendingVoters[_voterAddress].voterAddress,
            pendingVoters[_voterAddress].id_voted,
            pendingVoters[_voterAddress].voted
        );
    }

    function getVoterDetails(address _voterAddress)
        public
        view
        returns (
            address voterAddress,
            uint8 id_voted,
            bool voted
        )
    {
        if (voters[_voterAddress].voterAddress != _voterAddress) {
            revert VoterNotFound(_voterAddress);
        }
        return (
            voters[_voterAddress].voterAddress,
            voters[_voterAddress].id_voted,
            voters[_voterAddress].voted
        );
    }

    function getWinnerCandidateId() public view returns (uint8) {
        return winningCandidateId;
    }

    // ! don't return voteCount as election might be in progress
    function getCandidateDetails(uint8 _candidateId)
        public
        view
        returns (
            string memory name,
            string memory imgUrl,
            string memory email
        )
    {
        if (bytes(candidates[_candidateId].name).length == 0) {
            revert CandidateNotFound();
        }
        return (
            candidates[_candidateId].name,
            candidates[_candidateId].imgUrl,
            candidates[_candidateId].email
        );
    }
}
