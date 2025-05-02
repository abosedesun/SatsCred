;; Title: SatsCred - Decentralized Reputation Protocol for Bitcoin & Stacks

;; SUMMARY
;; SatsCred is a decentralized reputation management system built on the 
;; Stacks Layer 2 blockchain, enabling trustless reputation scoring for 
;; Bitcoin and Stacks ecosystem participants. The protocol uses on-chain 
;; activity to calculate and manage reputation scores that decay over time,
;; incentivizing continued participation and contributions.
;; 
;; DESCRIPTION
;; This smart contract implements a comprehensive reputation system with:
;; - Decentralized Identity (DID) integration
;; - Action-based reputation scoring with configurable multipliers
;; - Time-based reputation decay to prevent score inflation
;; - Transparent reputation history tracking
;; - Verification functions for external contract integration
;; 
;; The system provides a foundation for trust and reputation in 
;; decentralized applications, governance systems, and financial services
;; within the Bitcoin and Stacks ecosystem.

;; ERROR CONSTANTS
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PARAMETERS (err u101))
(define-constant ERR-IDENTITY-EXISTS (err u102))
(define-constant ERR-IDENTITY-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u104))
(define-constant ERR-MAX-REPUTATION-REACHED (err u105))
(define-constant ERR-ACTION-EXISTS (err u106))
(define-constant ERR-ACTION-NOT-FOUND (err u107))
(define-constant ERR-NOT-ADMIN (err u108))
(define-constant ERR-NOT-ACTIVE (err u109))

;; SYSTEM CONSTANTS
(define-constant MAX-REPUTATION-SCORE u1000)
(define-constant MIN-REPUTATION-SCORE u0)
(define-constant DEFAULT-STARTING-REPUTATION u50)
(define-constant DEFAULT-DECAY-RATE u10)  ;; 10% decay per period
(define-constant MINIMUM_DID_LENGTH u5)

;; CONTRACT CONFIGURATION
(define-data-var contract-owner principal tx-sender)
(define-data-var contract-active bool true)
(define-data-var decay-rate uint DEFAULT-DECAY-RATE)
(define-data-var decay-period uint u10000) ;; In blocks
(define-data-var starting-reputation uint DEFAULT-STARTING-REPUTATION)

;; STORAGE MAPS
(define-map identities 
  {owner: principal}
  {
    did: (string-ascii 50),  ;; Decentralized Identity
    reputation-score: uint,
    created-at: uint,
    last-updated: uint,
    last-decay: uint,
    total-actions: uint,
    active: bool
  }
)

(define-map reputation-actions
  {action-type: (string-ascii 50)}
  {
    multiplier: uint,
    description: (string-ascii 100),
    active: bool
  }
)

(define-map reputation-history
  {owner: principal, tx-id: uint}
  {
    action-type: (string-ascii 50),
    previous-score: uint,
    new-score: uint,
    timestamp: uint,
    block-height: uint
  }
)

;; ADMINISTRATIVE FUNCTIONS
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (var-set contract-owner new-owner)
    (ok true)
  )
)

(define-public (set-contract-active (active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (var-set contract-active active)
    (ok true)
  )
)

(define-public (set-decay-parameters (new-rate uint) (new-period uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (<= new-rate u100) (err ERR-INVALID-PARAMETERS))
    (asserts! (> new-period u0) (err ERR-INVALID-PARAMETERS))
    (var-set decay-rate new-rate)
    (var-set decay-period new-period)
    (ok true)
  )
)
