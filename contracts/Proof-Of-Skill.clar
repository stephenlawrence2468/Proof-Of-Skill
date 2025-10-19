;; Contract: proof-of-skill-protocol.clar

;; Description: A single, unified contract for the Proof-of-Skill platform.
;;              It mints non-transferable Soul-Bound Tokens (SBTs) to certify
;;              developer skills and manages a decentralized vault to distribute
;;              monthly rewards to certified developers.
;;



;; --- Trait for SIP-009 NFT Standard ---
(define-trait sip009-nft-trait
  (
    (get-last-token-id () (response uint uint))
    (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
    (get-owner (uint) (response (optional principal) uint))
    (transfer (uint principal principal) (response bool uint))
  )
)

;; --- Non-Fungible Token (NFT) Definition ---
(define-non-fungible-token proof-of-skill-sbt uint)

;; --- Constants ---
;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-TRANSFER-DISABLED (err u102))
(define-constant ERR-NOT-CERTIFIED (err u202))
(define-constant ERR-ALREADY-CLAIMED (err u203))
(define-constant ERR-INSUFFICIENT-FUNDS (err u204))
(define-constant ERR-NO-TOKENS-MINTED-YET (err u205))

;; Configuration
(define-constant BLOCKS-PER-CYCLE u4320) ;; ~30 days
(define-constant REWARD-AMOUNT u10000000) ;; 10 STX in micro-STX

;; --- Data Storage ---
(define-data-var contract-owner principal tx-sender)
(define-data-var last-token-id uint u0)

;; Metadata per token
(define-map token-metadata uint { course-name: (string-ascii 64), issued-at: uint })

;; Reward claims per cycle
(define-map claims-by-cycle { cycle: uint, user: principal } bool)

;; ---------------------------------------------------------
;; --- Administrative Functions (Owner Only)
;; ---------------------------------------------------------

(define-public (award-certificate (recipient principal) (course-name (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (let ((next-id (+ u1 (var-get last-token-id))))
      (try! (nft-mint? proof-of-skill-sbt next-id recipient))
      (map-set token-metadata next-id { course-name: course-name, issued-at: burn-block-height })
      (var-set last-token-id next-id)
      (print { action: "award-certificate", recipient: recipient, tokenId: next-id })
      (ok true)
    )
  )
)

(define-public (deposit-rewards (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

;; ---------------------------------------------------------
;; --- Public User Functions
;; ---------------------------------------------------------

(define-public (claim-reward)
  (let (
    (current-cycle (/ stacks-block-height BLOCKS-PER-CYCLE))
    (claim-key { cycle: (/ stacks-block-height BLOCKS-PER-CYCLE), user: tx-sender })
  )
    
   
    ;; 2. Must not have claimed already
    (asserts! (not (default-to false (map-get? claims-by-cycle claim-key))) ERR-ALREADY-CLAIMED)

    ;; 3. Contract must have funds
    (asserts! (>= (stx-get-balance (as-contract tx-sender)) REWARD-AMOUNT) ERR-INSUFFICIENT-FUNDS)

    ;; 4. Transfer reward
    (try! (stx-transfer? REWARD-AMOUNT (as-contract tx-sender) tx-sender))

    ;; 5. Mark as claimed
    (map-set claims-by-cycle claim-key true)

    (print { action: "claim-reward", claimant: tx-sender, cycle: current-cycle })
    (ok true)
  )
)

;; ---------------------------------------------------------
;; --- Read-Only & Helper Functions
;; ---------------------------------------------------------

;; ---------------------------------------------------------
;; --- Private Helper Function: Check Token Ownership
;; ---------------------------------------------------------



;; @desc Calculates the current reward cycle from the block height.
(define-read-only (get-current-cycle)
  (/ burn-block-height BLOCKS-PER-CYCLE)
)

(define-read-only (get-certificate-details (token-id uint))
  (map-get? token-metadata token-id)
)

;; ---------------------------------------------------------
;; --- SIP-009 Trait Implementation
;; ---------------------------------------------------------

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? proof-of-skill-sbt token-id))
)

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

;; @desc Returns a URI for token metadata (for marketplaces, wallets, etc.).
(define-read-only (get-token-uri (token-id uint))
  (ok (some "https://api.proofofskill.com/metadata/token")))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    ERR-TRANSFER-DISABLED
  )
)
