A unified smart contract for the **Proof-of-Skill** platform. This protocol issues **Soul-Bound Tokens (SBTs)** to certify developer achievements and manages a decentralized STX vault for distributing **monthly rewards** to certified developers.

---

## 📜 Contract Overview

- **Contract Name**: `proof-of-skill-protocol.clar`
- **Purpose**: 
  - Certify developer skills via non-transferable NFTs.
  - Distribute recurring STX-based rewards to certified users.

---

## 🏗️ Features

### ✅ Soul-Bound Certification (SBT)
- Non-transferable NFTs (following [SIP-009](https://github.com/stacksgov/sips/blob/main/sips/sip-009/sip-009-nft-standard.md)) are minted as proof of skills.
- Each SBT includes:
  - `course-name`: The name of the completed course.
  - `issued-at`: The block height when the token was minted.
- Tokens are soul-bound — transfers are permanently disabled.

### 💰 Monthly Rewards
- A decentralized vault (STX) distributes `10 STX` per certified user **per month**.
- Rewards are claimable once per cycle (every ~30 days).
- Claims are recorded and cannot be duplicated for a cycle.

### 🔐 Admin Functions
- Only the `contract-owner` can:
  - Mint SBTs using `award-certificate`.
  - Fund the reward pool via `deposit-rewards`.

---

## 🚀 Public Functions

| Function | Description |
|---------|-------------|
| `award-certificate(recipient, course-name)` | Mint an SBT to a user with metadata. *(Admin only)* |
| `deposit-rewards(amount)` | Deposit STX to the contract’s reward vault. *(Admin only)* |
| `claim-reward()` | Allows certified users to claim their monthly reward. |
| `get-certificate-details(token-id)` | View metadata of a given SBT. |
| `get-owner(token-id)` | Returns the owner of an SBT. |
| `get-last-token-id()` | Returns the latest token ID issued. |
| `get-current-cycle()` | View the current reward cycle. |
| `get-token-uri(token-id)` | Returns a fixed metadata URI. |
| `transfer(...)` | Disabled: Always returns `err u102`. |

---

## 📦 SIP-009 Compliance

Implements the following trait methods for NFT compatibility:

```
(get-last-token-id () (response uint uint))
(get-token-uri (uint) (response (optional (string-ascii 256)) uint))
(get-owner (uint) (response (optional principal) uint))
(transfer (uint principal principal) (response bool uint)) ;; Disabled
⚠️ Transfer is always disabled to ensure SBTs remain soul-bound.

⚠️ Error Codes
Code	Meaning
err u101	Not authorized (admin only).
err u102	Transfer is disabled.
err u202	User not certified.
err u203	Reward already claimed this cycle.
err u204	Insufficient funds in the reward vault.
err u205	No tokens minted yet.

🛠️ Configuration
Constant	Value	Description
BLOCKS-PER-CYCLE	u4320	~30-day cycle (assuming 10-min blocks)
REWARD-AMOUNT	u10000000	10 STX (in micro-STX) per reward

📂 Project Structure
swift
.
├── contracts/
│   └── proof-of-skill-protocol.clar
├── README.md
📜 License
MIT License. See LICENSE for details.

✨ Example Usage
;; Admin mints a certificate
(award-certificate tx-sender "Clarity Masterclass")

;; Certified developer claims their monthly reward
(claim-reward)
🌐 External Metadata
The get-token-uri function returns a fixed URI:

https://api.proofofskill.com/metadata/token
You may update this in production to point to dynamic, token-specific metadata.

🙌 Contributions
PRs welcome! Please open an issue or pull request if you'd like to help improve the protocol or expand features.

🧪 Testing
To test the contract locally:

Use Clarinet for local development.

Write test cases for minting, claiming, and access control.

Simulate multiple reward cycles and claim attempts.

Voice

Ch
