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

(define-public (set-starting-reputation (new-value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (<= new-value MAX-REPUTATION-SCORE) (err ERR-INVALID-PARAMETERS))
    (var-set starting-reputation new-value)
    (ok true)
  )
)

;; REPUTATION ACTION MANAGEMENT
(define-public (add-reputation-action 
  (action-type (string-ascii 50))
  (multiplier uint)
  (description (string-ascii 100))
)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (is-none (map-get? reputation-actions {action-type: action-type})) 
      (err ERR-ACTION-EXISTS))
    
    (map-set reputation-actions 
      {action-type: action-type} 
      {
        multiplier: multiplier,
        description: description,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (update-reputation-action
  (action-type (string-ascii 50))
  (multiplier uint)
  (description (string-ascii 100))
  (active bool)
)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    (asserts! (is-some (map-get? reputation-actions {action-type: action-type})) 
      (err ERR-ACTION-NOT-FOUND))
    
    (map-set reputation-actions 
      {action-type: action-type} 
      {
        multiplier: multiplier,
        description: description,
        active: active
      }
    )
    (ok true)
  )
)

;; INITIALIZATION
(define-public (initialize-reputation-actions)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-ADMIN))
    
    (map-set reputation-actions 
      {action-type: "governance-vote"} 
      {
        multiplier: u5,
        description: "Participation in governance voting",
        active: true
      }
    )
    (map-set reputation-actions 
      {action-type: "contract-fulfillment"} 
      {
        multiplier: u10,
        description: "Successful completion of a smart contract agreement",
        active: true
      }
    )
    (map-set reputation-actions 
      {action-type: "community-contribution"} 
      {
        multiplier: u7,
        description: "Contribution to community projects or initiatives",
        active: true
      }
    )
    (map-set reputation-actions 
      {action-type: "validation"} 
      {
        multiplier: u3,
        description: "Validation of network transactions or data",
        active: true
      }
    )
    (map-set reputation-actions 
      {action-type: "content-creation"} 
      {
        multiplier: u6,
        description: "Creation of valuable content on the platform",
        active: true
      }
    )
    (ok true)
  )
)

;; HELPER FUNCTIONS
(define-private (is-valid-owner (owner principal))
  (and 
    (is-some (map-get? identities {owner: owner}))
    (is-eq owner tx-sender)
  )
)

(define-private (log-reputation-change 
  (owner principal) 
  (action-type (string-ascii 50))
  (previous-score uint)
  (new-score uint)
)
  (map-set reputation-history
    {owner: owner, tx-id: stacks-block-height}
    {
      action-type: action-type,
      previous-score: previous-score,
      new-score: new-score,
      timestamp: burn-block-height,
      block-height: stacks-block-height
    }
  )
)

(define-private (get-action-multiplier (action-type (string-ascii 50)))
  (default-to u0 
    (get multiplier 
      (map-get? reputation-actions {action-type: action-type})
    )
  )
)

(define-private (is-action-active (action-type (string-ascii 50)))
  (default-to false
    (get active
      (map-get? reputation-actions {action-type: action-type})
    )
  )
)

(define-private (get-identity-field (owner principal))
  (map-get? identities {owner: owner})
)

(define-private (should-decay (last-decay uint))
  (>= (- stacks-block-height last-decay) (var-get decay-period))
)

;; IDENTITY MANAGEMENT
(define-public (create-identity (did (string-ascii 50)))
  (let 
    (
      (sender tx-sender)
      (current-block-height stacks-block-height)
    )
    (begin
      ;; Check contract is active
      (asserts! (var-get contract-active) (err ERR-NOT-ACTIVE))
      
      ;; Check if identity already exists
      (asserts! (is-none (map-get? identities {owner: sender})) 
        (err ERR-IDENTITY-EXISTS))
      
      ;; Validate DID
      (asserts! (> (len did) MINIMUM_DID_LENGTH) 
        (err ERR-INVALID-PARAMETERS))
      
      ;; Create identity
      (map-set identities 
        {owner: sender}
        {
          did: did,
          reputation-score: (var-get starting-reputation),
          created-at: current-block-height,
          last-updated: current-block-height,
          last-decay: current-block-height,
          total-actions: u0,
          active: true
        }
      )
      (ok did)
    )
  )
)

(define-public (update-identity-status (active bool))
  (let
    (
      (sender tx-sender)
      (current-identity 
        (unwrap! 
          (map-get? identities {owner: sender}) 
          (err ERR-IDENTITY-NOT-FOUND)
        )
      )
    )
    (begin
      (map-set identities 
        {owner: sender}
        (merge current-identity {
          active: active,
          last-updated: stacks-block-height
        })
      )
      (ok true)
    )
  )
)

;; REPUTATION MANAGEMENT
(define-public (update-reputation-score 
  (action-type (string-ascii 50))
)
  (let 
    (
      (owner tx-sender)
      (current-identity 
        (unwrap! 
          (map-get? identities {owner: owner}) 
          (err ERR-IDENTITY-NOT-FOUND)
        )
      )
      (current-score (get reputation-score current-identity))
      (action-multiplier (get-action-multiplier action-type))
      (total-actions (+ (get total-actions current-identity) u1))
    )
    (begin
      ;; Check contract is active
      (asserts! (var-get contract-active) (err ERR-NOT-ACTIVE))
      
      ;; Check identity is active
      (asserts! (get active current-identity) (err ERR-UNAUTHORIZED))
      
      ;; Validate action type exists and is active
      (asserts! (is-some (map-get? reputation-actions {action-type: action-type}))
        (err ERR-INVALID-PARAMETERS))
      (asserts! (is-action-active action-type)
        (err ERR-INVALID-PARAMETERS))
      
      ;; Apply decay if needed
      (if (should-decay (get last-decay current-identity))
          (decay-reputation-internal owner)
          true
      )
      
      ;; Get updated score after possible decay
      (let
        (
          (updated-identity (unwrap! (map-get? identities {owner: owner}) (err ERR-IDENTITY-NOT-FOUND)))
          (updated-current-score (get reputation-score updated-identity))
          (new-score 
            (if (< (+ updated-current-score action-multiplier) MAX-REPUTATION-SCORE)
                (+ updated-current-score action-multiplier)
                MAX-REPUTATION-SCORE
            )
          )
        )
        (begin
          ;; Update identity record
          (map-set identities 
            {owner: owner}
            (merge updated-identity {
              reputation-score: new-score,
              last-updated: stacks-block-height,
              total-actions: total-actions
            })
          )
          
          ;; Log the reputation change
          (log-reputation-change owner action-type updated-current-score new-score)
          
          (ok new-score)
        )
      )
    )
  )
)

;; REPUTATION DECAY
;; Decay Reputation Over Time (internal function)
(define-private (decay-reputation-internal (owner principal))
  (let 
    (
      (current-identity 
        (default-to
          {
            did: "", 
            reputation-score: u0, 
            created-at: u0, 
            last-updated: u0,
            last-decay: u0,
            total-actions: u0,
            active: false
          }
          (map-get? identities {owner: owner})
        )
      )
      (current-score (get reputation-score current-identity))
      (decay-amount 
        (/ (* current-score (var-get decay-rate)) u100)
      )
      (updated-score 
        (if (> current-score decay-amount)
            (- current-score decay-amount)
            MIN-REPUTATION-SCORE
        )
      )
    )
    (begin
      (map-set identities 
        {owner: owner}
        (merge current-identity {
          reputation-score: updated-score,
          last-updated: stacks-block-height,
          last-decay: stacks-block-height
        })
      )
      
      ;; Log the reputation change
      (log-reputation-change owner "decay" current-score updated-score)
      
      true
    )
  )
)

;; Public decay function
(define-public (decay-reputation)
  (let 
    (
      (owner tx-sender)
      (current-identity 
        (unwrap! 
          (map-get? identities {owner: owner}) 
          (err ERR-IDENTITY-NOT-FOUND)
        )
      )
    )
    (begin
      ;; Check contract is active
      (asserts! (var-get contract-active) (err ERR-NOT-ACTIVE))
      
      ;; Check identity is active
      (asserts! (get active current-identity) (err ERR-UNAUTHORIZED))
      
      ;; Validate decay period has passed
      (asserts! (should-decay (get last-decay current-identity))
        (err ERR-INVALID-PARAMETERS))
      
      (decay-reputation-internal owner)
      
      (let
        ((updated-identity (unwrap! (map-get? identities {owner: owner}) (err ERR-IDENTITY-NOT-FOUND)))
         (updated-score (get reputation-score updated-identity)))
        (ok updated-score)
      )
    )
  )
)

;; REPUTATION VERIFICATION FUNCTIONS
(define-read-only (get-reputation (owner principal))
  (let
    ((identity (get-identity-field owner)))
    (if (is-some identity)
        (some (get reputation-score (unwrap! identity none)))
        none
    )
  )
)

(define-read-only (get-full-identity (owner principal))
  (get-identity-field owner)
)

(define-read-only (verify-reputation 
  (owner principal) 
  (min-reputation-threshold uint)
)
  (match 
    (map-get? identities {owner: owner})
    identity 
      (if (and 
            (get active identity)
            (>= (get reputation-score identity) min-reputation-threshold)
          )
          (some true)
          none
      )
    none
  )
)

(define-read-only (get-reputation-action (action-type (string-ascii 50)))
  (map-get? reputation-actions {action-type: action-type})
)

(define-read-only (get-reputation-history (owner principal) (tx-id uint))
  (map-get? reputation-history {owner: owner, tx-id: tx-id})
)

(define-read-only (get-contract-parameters)
  {
    max-reputation: MAX-REPUTATION-SCORE,
    min-reputation: MIN-REPUTATION-SCORE,
    starting-reputation: (var-get starting-reputation),
    decay-rate: (var-get decay-rate),
    decay-period: (var-get decay-period),
    owner: (var-get contract-owner),
    active: (var-get contract-active)
  }
)

;; Initialize the contract if not initialized
(initialize-reputation-actions)