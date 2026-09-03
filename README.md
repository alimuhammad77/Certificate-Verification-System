# 🎓 Certificate Verification System

A decentralized university certificate issuance and verification system built on Ethereum. Certificates are minted as **ERC-721 NFTs** tied to student wallet addresses, with issuance and revocation controlled by a **DAO governance contract** requiring multi-member quorum approval — removing single-point-of-failure control over academic credentialing.

---

## ✨ Features

- **NFT-based certificates** — each certificate is a unique ERC-721 token minted directly to a student's wallet address
- **Instant public verification** — anyone can check a certificate's authenticity and revocation status on-chain, with no admin lookup required
- **DAO-governed issuance** — certificate issuance and revocation proposals require multi-member quorum voting before execution
- **Automated on-chain actions** — once a proposal passes quorum, minting or revocation is triggered automatically, with no manual step in between
- **No single point of failure** — no single administrator can unilaterally issue or revoke a certificate

---

## 🏗️ Architecture

| Contract | Purpose |
|---|---|
| `CertificateNFT.sol` | ERC-721 contract that mints, stores, and exposes verification/revocation status for each certificate |
| `VerificationDAO.sol` | Governance contract managing quorum-based voting on issuance/revocation proposals, and triggering the corresponding action on `CertificateNFT` once approved |

**Flow:**
1. A proposal to issue (or revoke) a certificate is submitted to `VerificationDAO`
2. DAO members vote on the proposal
3. Once quorum is reached, the DAO automatically calls the appropriate function on `CertificateNFT`
4. `CertificateNFT` mints the certificate to the student's wallet (or flags it as revoked)
5. Anyone can call the public verification function to confirm a certificate's authenticity and status

---

## 🛠️ Tech Stack

- **Solidity** — smart contract language
- **OpenZeppelin** — ERC-721 and access-control base contracts
- **Remix IDE** — contract development and deployment
- **MetaMask** — wallet connection and transaction signing
- **Sepolia Testnet** — deployment network

---

## 🚀 Deployment

Contracts are deployed and tested on the **Sepolia testnet** using **Remix IDE**, with **MetaMask** used to sign deployment and interaction transactions.

To deploy your own instance:

1. Open [Remix IDE](https://remix.ethereum.org)
2. Import `CertificateNFT.sol` and `VerificationDAO.sol` from this repo
3. Compile both contracts (ensure your OpenZeppelin import versions match the compiler version configured in Remix)
4. Connect MetaMask to the Sepolia testnet and fund it with Sepolia ETH from a faucet
5. Deploy `CertificateNFT.sol` first, then deploy `VerificationDAO.sol` with the deployed `CertificateNFT` address as a constructor argument
6. Set `VerificationDAO` as an authorized minter/revoker on `CertificateNFT` (if configured as a separate step)

> **Note:** This project was built against OpenZeppelin v5 — if you're using a different version, watch for breaking changes in constructor signatures and access-control patterns.

---

## 📖 Usage

- **Submit a proposal** — a DAO member proposes issuing or revoking a certificate for a given student address
- **Vote** — DAO members vote on the open proposal
- **Automatic execution** — once quorum is met, the contract automatically mints/revokes on `CertificateNFT`
- **Verify a certificate** — call the public verification function with a token ID or student address to check authenticity and revocation status

---

## 📌 Roadmap / Possible Extensions

- Front-end dApp for students and institutions to interact with the contracts without Remix
- IPFS-based metadata storage for certificate details (course, grade, issue date)
- Mainnet/L2 deployment for production use
