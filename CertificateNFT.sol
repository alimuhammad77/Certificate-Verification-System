// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/access/Ownable.sol";

contract CertificateNFT is ERC721, Ownable {

    uint256 private _tokenIdCounter;
    address public daoAddress;

    struct Certificate {
        string studentName;
        string degree;
        string department;
        uint256 graduationYear;
        bool isRevoked;
        uint256 issuedAt;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => uint256[]) public studentCertificates;

    event CertificateIssued(uint256 tokenId, address student, string studentName, string degree);
    event CertificateRevoked(uint256 tokenId, address student, string reason);

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    constructor() ERC721("UniversityCertificate", "UCERT") {}

    function setDAOAddress(address _dao) external onlyOwner {
        daoAddress = _dao;
    }

    function issueCertificate(
        address student,
        string memory studentName,
        string memory degree,
        string memory department,
        uint256 graduationYear
    ) external onlyDAO returns (uint256) {
        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _safeMint(student, newTokenId);

        certificates[newTokenId] = Certificate({
            studentName: studentName,
            degree: degree,
            department: department,
            graduationYear: graduationYear,
            isRevoked: false,
            issuedAt: block.timestamp
        });

        studentCertificates[student].push(newTokenId);
        emit CertificateIssued(newTokenId, student, studentName, degree);
        return newTokenId;
    }

    function revokeCertificate(uint256 tokenId, string memory reason)
        external onlyDAO tokenExists(tokenId) {
        certificates[tokenId].isRevoked = true;
        emit CertificateRevoked(tokenId, ownerOf(tokenId), reason);
    }

    function verifyCertificate(uint256 tokenId)
        external view tokenExists(tokenId)
        returns (
            address owner,
            string memory studentName,
            string memory degree,
            string memory department,
            uint256 graduationYear,
            bool isValid,
            uint256 issuedAt
        )
    {
        Certificate memory cert = certificates[tokenId];
        return (
            ownerOf(tokenId),
            cert.studentName,
            cert.degree,
            cert.department,
            cert.graduationYear,
            !cert.isRevoked,
            cert.issuedAt
        );
    }
}