// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol";

interface ICertificateNFT {
    function issueCertificate(address, string memory, string memory, string memory, uint256) external returns (uint256);
    function revokeCertificate(uint256, string memory) external;
}

contract VerificationDAO is Ownable {

    ICertificateNFT public certificateContract;

    uint256 public quorum = 2;
    uint256 public votingDuration = 3 days;
    uint256 public memberCount;
    uint256 public proposalCount;

    enum ProposalType { ISSUE, REVOKE }
    enum ProposalStatus { PENDING, APPROVED, REJECTED, EXECUTED }

    struct ProposalMeta {
        ProposalType proposalType;
        ProposalStatus status;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
    }

    struct ProposalData {
        address studentWallet;
        string studentName;
        string degree;
        string department;
        uint256 graduationYear;
        uint256 tokenId;
        string revokeReason;
    }

    mapping(uint256 => ProposalMeta) public proposalMeta;
    mapping(uint256 => ProposalData) public proposalData;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public isMember;

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool inFavor);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status);

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a DAO member");
        _;
    }

    modifier proposalExists(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCount, "Proposal does not exist");
        _;
    }

    function setCertificateContract(address _contract) external onlyOwner {
        certificateContract = ICertificateNFT(_contract);
    }

    function addMember(address member) external onlyOwner {
        require(!isMember[member], "Already a member");
        isMember[member] = true;
        memberCount++;
    }

    function removeMember(address member) external onlyOwner {
        require(isMember[member], "Not a member");
        isMember[member] = false;
        memberCount--;
    }

    function setVotingDuration(uint256 durationInSeconds) external onlyOwner {
        votingDuration = durationInSeconds;
    }

    function setQuorum(uint256 _quorum) external onlyOwner {
        quorum = _quorum;
    }

    function proposeIssueCertificate(
        address studentWallet,
        string memory studentName,
        string memory degree,
        string memory department,
        uint256 graduationYear
    ) external onlyMember returns (uint256) {
        proposalCount++;

        proposalMeta[proposalCount] = ProposalMeta({
            proposalType: ProposalType.ISSUE,
            status: ProposalStatus.PENDING,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            votingDeadline: block.timestamp + votingDuration
        });

        proposalData[proposalCount] = ProposalData({
            studentWallet: studentWallet,
            studentName: studentName,
            degree: degree,
            department: department,
            graduationYear: graduationYear,
            tokenId: 0,
            revokeReason: ""
        });

        emit ProposalCreated(proposalCount, ProposalType.ISSUE, msg.sender);
        return proposalCount;
    }

    function proposeRevokeCertificate(uint256 tokenId, string memory reason)
        external onlyMember returns (uint256) {
        proposalCount++;

        proposalMeta[proposalCount] = ProposalMeta({
            proposalType: ProposalType.REVOKE,
            status: ProposalStatus.PENDING,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            votingDeadline: block.timestamp + votingDuration
        });

        proposalData[proposalCount] = ProposalData({
            studentWallet: address(0),
            studentName: "",
            degree: "",
            department: "",
            graduationYear: 0,
            tokenId: tokenId,
            revokeReason: reason
        });

        emit ProposalCreated(proposalCount, ProposalType.REVOKE, msg.sender);
        return proposalCount;
    }

    function vote(uint256 proposalId, bool inFavor)
        external onlyMember proposalExists(proposalId) {
        ProposalMeta storage meta = proposalMeta[proposalId];
        require(meta.status == ProposalStatus.PENDING, "Proposal not pending");
        require(block.timestamp < meta.votingDeadline, "Voting period ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        hasVoted[proposalId][msg.sender] = true;
        if (inFavor) { meta.votesFor++; } else { meta.votesAgainst++; }
        emit VoteCast(proposalId, msg.sender, inFavor);
    }

    function executeProposal(uint256 proposalId) external proposalExists(proposalId) {
        ProposalMeta storage meta = proposalMeta[proposalId];
        ProposalData storage data = proposalData[proposalId];

        require(meta.status == ProposalStatus.PENDING, "Already executed");
        require(block.timestamp >= meta.votingDeadline, "Voting still ongoing");

        uint256 totalVotes = meta.votesFor + meta.votesAgainst;

        if (totalVotes >= quorum && meta.votesFor > meta.votesAgainst) {
            meta.status = ProposalStatus.APPROVED;
            if (meta.proposalType == ProposalType.ISSUE) {
                certificateContract.issueCertificate(
                    data.studentWallet, data.studentName,
                    data.degree, data.department, data.graduationYear
                );
            } else {
                certificateContract.revokeCertificate(data.tokenId, data.revokeReason);
            }
        } else {
            meta.status = ProposalStatus.REJECTED;
        }
        emit ProposalExecuted(proposalId, meta.status);
    }

    function getVotes(uint256 proposalId) external view proposalExists(proposalId)
        returns (uint256 votesFor, uint256 votesAgainst) {
        return (proposalMeta[proposalId].votesFor, proposalMeta[proposalId].votesAgainst);
    }
}