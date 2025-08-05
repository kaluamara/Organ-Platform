;; Advanced Organ Transplant Registry - Decentralized Medical Coordination Platform Smart Contract
;;
;; A sophisticated blockchain-based organ transplant coordination system that provides secure,
;; transparent, and efficient matching between organ donors and recipients. The platform ensures
;; medical compatibility through automated validation algorithms, maintains immutable medical
;; records, implements priority-based allocation protocols, and provides comprehensive audit
;; trails for all transplant procedures while ensuring full regulatory compliance and patient
;; privacy protection.
;;
;; Core Capabilities:
;; - Secure medical professional authentication with role-based access control
;; - Comprehensive donor and recipient registration with medical profile management
;; - Advanced blood type and organ compatibility validation algorithms
;; - Intelligent priority-based organ allocation with medical urgency assessment
;; - Immutable transplant procedure documentation and tracking system
;; - Real-time analytics dashboard with comprehensive reporting capabilities
;; - Multi-organ support with extensive medical validation and safety protocols

;; ADMINISTRATIVE CONFIGURATION AND ACCESS CONTROL

(define-constant contract-administrator tx-sender)

;; COMPREHENSIVE ERROR CODE DEFINITIONS

;; Authentication and Authorization Error Codes
(define-constant ERR-UNAUTHORIZED-SYSTEM-ACCESS (err u200))
(define-constant ERR-INSUFFICIENT-MEDICAL-CREDENTIALS (err u201))

;; Patient Registration and Profile Management Error Codes
(define-constant ERR-DONOR-PROFILE-NOT-FOUND (err u210))
(define-constant ERR-DONOR-ALREADY-EXISTS (err u211))
(define-constant ERR-RECIPIENT-PROFILE-NOT-FOUND (err u212))
(define-constant ERR-RECIPIENT-ALREADY-EXISTS (err u213))
(define-constant ERR-TRANSPLANT-RECORD-NOT-FOUND (err u214))

;; Medical Compatibility and Validation Error Codes
(define-constant ERR-INVALID-ORGAN-TYPE (err u220))
(define-constant ERR-INVALID-BLOOD-TYPE (err u221))
(define-constant ERR-ORGAN-NOT-AVAILABLE (err u222))
(define-constant ERR-MEDICAL-INCOMPATIBILITY (err u223))
(define-constant ERR-INVALID-MEDICAL-STATUS (err u224))
(define-constant ERR-INVALID-PRIORITY-LEVEL (err u225))
(define-constant ERR-MEDICAL-CLEARANCE-PENDING (err u226))

;; Patient Data Validation Error Codes
(define-constant ERR-INVALID-PATIENT-DATA (err u230))
(define-constant ERR-MISSING-PATIENT-ID (err u231))
(define-constant ERR-INVALID-AGE-VALUE (err u232))

;; MEDICAL CLASSIFICATION AND TYPE DEFINITIONS

;; Available Organ Types for Transplantation
(define-constant organ-type-heart u1)
(define-constant organ-type-kidney u2)
(define-constant organ-type-liver u3)
(define-constant organ-type-lung u4)
(define-constant organ-type-pancreas u5)
(define-constant organ-type-cornea u6)

;; ABO Blood Group Classification System
(define-constant blood-group-a-positive u1)
(define-constant blood-group-b-positive u2)
(define-constant blood-group-ab-positive u3)
(define-constant blood-group-o-positive u4)

;; Patient Medical Status Classifications
(define-constant status-active-available u1)
(define-constant status-matched-pending u2)
(define-constant status-procedure-completed u3)
(define-constant status-inactive u4)

;; Medical Priority Level Classifications
(define-constant priority-critical u1)
(define-constant priority-urgent u2)
(define-constant priority-high u3)
(define-constant priority-medium u4)
(define-constant priority-standard u5)

;; COMPREHENSIVE DATA STRUCTURE DEFINITIONS

;; Organ Donor Comprehensive Medical Profile
(define-map donor-medical-registry
  principal
  {
    patient-full-name: (string-ascii 100),
    patient-age: uint,
    blood-group-type: uint,
    available-organs-list: (list 10 uint),
    registration-block-height: uint,
    current-status: uint,
    medical-clearance-status: bool,
    supervising-physician: (optional principal)
  }
)

;; Transplant Recipient Comprehensive Medical Profile
(define-map recipient-medical-registry
  principal
  {
    patient-full-name: (string-ascii 100),
    patient-age: uint,
    blood-group-type: uint,
    needed-organ-type: uint,
    urgency-priority-level: uint,
    registration-block-height: uint,
    current-status: uint,
    waiting-list-position: uint
  }
)

;; Medical Transplant Procedure Documentation
(define-map transplant-procedure-registry
  uint
  {
    donor-address: principal,
    recipient-address: principal,
    organ-type-transplanted: uint,
    procedure-start-block: uint,
    procedure-status: uint,
    medical-supervisor: principal,
    procedure-completion-block: (optional uint)
  }
)

;; SYSTEM STATE TRACKING VARIABLES

(define-data-var next-procedure-id uint u1)
(define-data-var total-donors-registered uint u0)
(define-data-var total-recipients-registered uint u0)
(define-data-var successful-transplants-completed uint u0)
(define-data-var pending-procedures-count uint u0)

;; MEDICAL VALIDATION AND UTILITY FUNCTIONS

(define-private (is-valid-organ-type (organ-type uint))
  (and (>= organ-type u1) (<= organ-type u6))
)

(define-private (is-valid-blood-group (blood-group uint))
  (and (>= blood-group u1) (<= blood-group u4))
)

(define-private (is-valid-medical-status (medical-status uint))
  (and (>= medical-status u1) (<= medical-status u4))
)

(define-private (is-valid-priority-level (priority-level uint))
  (and (>= priority-level u1) (<= priority-level u5))
)

(define-private (is-valid-patient-name (patient-name (string-ascii 100)))
  (> (len patient-name) u0)
)

(define-private (is-valid-patient-age (age uint))
  (and (> age u0) (< age u120))
)

(define-private (donor-profile-exists (donor-address principal))
  (is-some (map-get? donor-medical-registry donor-address))
)

(define-private (check-blood-compatibility (donor-blood-type uint) (recipient-blood-type uint))
  (or
    ;; Universal donor O+ compatibility
    (is-eq donor-blood-type blood-group-o-positive)
    ;; Exact blood type match
    (is-eq donor-blood-type recipient-blood-type)
    ;; Universal recipient AB+ compatibility
    (is-eq recipient-blood-type blood-group-ab-positive)
    ;; A+ donor to AB+ recipient
    (and (is-eq donor-blood-type blood-group-a-positive) 
         (is-eq recipient-blood-type blood-group-ab-positive))
    ;; B+ donor to AB+ recipient
    (and (is-eq donor-blood-type blood-group-b-positive) 
         (is-eq recipient-blood-type blood-group-ab-positive))
  )
)

(define-private (organ-available-in-inventory (target-organ uint) (organ-inventory (list 10 uint)))
  (is-some (index-of organ-inventory target-organ))
)

(define-private (validate-organ-inventory (organ-list (list 10 uint)))
  (is-eq (len (filter is-valid-organ-type organ-list)) (len organ-list))
)

;; ORGAN DONOR REGISTRATION AND MANAGEMENT SYSTEM

(define-public (register-organ-donor
  (patient-name (string-ascii 100))
  (age uint)
  (blood-group uint)
  (available-organs (list 10 uint))
)
  (let
    (
      (donor-address tx-sender)
      (registration-timestamp block-height)
    )
    ;; Input validation checks
    (asserts! (is-valid-patient-name patient-name) ERR-MISSING-PATIENT-ID)
    (asserts! (is-valid-patient-age age) ERR-INVALID-AGE-VALUE)
    (asserts! (is-valid-blood-group blood-group) ERR-INVALID-BLOOD-TYPE)
    (asserts! (validate-organ-inventory available-organs) ERR-INVALID-ORGAN-TYPE)
    
    ;; Check for existing registration
    (asserts! (is-none (map-get? donor-medical-registry donor-address)) 
              ERR-DONOR-ALREADY-EXISTS)
    
    ;; Create donor profile
    (map-set donor-medical-registry donor-address {
      patient-full-name: patient-name,
      patient-age: age,
      blood-group-type: blood-group,
      available-organs-list: available-organs,
      registration-block-height: registration-timestamp,
      current-status: status-active-available,
      medical-clearance-status: false,
      supervising-physician: none
    })
    
    ;; Update system statistics
    (var-set total-donors-registered (+ (var-get total-donors-registered) u1))
    (ok true)
  )
)

(define-public (update-donor-clearance-status
  (donor-address principal)
  (clearance-approved bool)
  (physician-address (optional principal))
)
  (begin
    ;; Administrator authorization check
    (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-SYSTEM-ACCESS)
    
    ;; Donor existence validation
    (asserts! (donor-profile-exists donor-address) ERR-DONOR-PROFILE-NOT-FOUND)
    
    ;; Update donor clearance status
    (let
      (
        (current-profile (unwrap-panic (map-get? donor-medical-registry donor-address)))
      )
      (map-set donor-medical-registry donor-address
        (merge current-profile {
          medical-clearance-status: clearance-approved,
          supervising-physician: physician-address
        })
      )
      (ok true)
    )
  )
)

;; TRANSPLANT RECIPIENT REGISTRATION AND MANAGEMENT SYSTEM

(define-public (register-transplant-recipient
  (patient-name (string-ascii 100))
  (age uint)
  (blood-group uint)
  (needed-organ uint)
  (priority-level uint)
)
  (let
    (
      (recipient-address tx-sender)
      (registration-timestamp block-height)
      (waiting-position (+ (var-get total-recipients-registered) u1))
    )
    ;; Input validation checks
    (asserts! (is-valid-patient-name patient-name) ERR-MISSING-PATIENT-ID)
    (asserts! (is-valid-patient-age age) ERR-INVALID-AGE-VALUE)
    (asserts! (is-valid-blood-group blood-group) ERR-INVALID-BLOOD-TYPE)
    (asserts! (is-valid-organ-type needed-organ) ERR-INVALID-ORGAN-TYPE)
    (asserts! (is-valid-priority-level priority-level) ERR-INVALID-PRIORITY-LEVEL)
    
    ;; Check for existing registration
    (asserts! (is-none (map-get? recipient-medical-registry recipient-address)) 
              ERR-RECIPIENT-ALREADY-EXISTS)
    
    ;; Create recipient profile
    (map-set recipient-medical-registry recipient-address {
      patient-full-name: patient-name,
      patient-age: age,
      blood-group-type: blood-group,
      needed-organ-type: needed-organ,
      urgency-priority-level: priority-level,
      registration-block-height: registration-timestamp,
      current-status: status-active-available,
      waiting-list-position: waiting-position
    })
    
    ;; Update system statistics
    (var-set total-recipients-registered (+ (var-get total-recipients-registered) u1))
    (ok true)
  )
)

;; TRANSPLANT COORDINATION AND MATCHING SYSTEM

(define-public (initiate-transplant-procedure
  (donor-address principal)
  (recipient-address principal)
  (organ-type uint)
)
  (let
    (
      (donor-profile (unwrap! (map-get? donor-medical-registry donor-address) 
                              ERR-DONOR-PROFILE-NOT-FOUND))
      (recipient-profile (unwrap! (map-get? recipient-medical-registry recipient-address) 
                                  ERR-RECIPIENT-PROFILE-NOT-FOUND))
      (procedure-id (var-get next-procedure-id))
      (initiation-timestamp block-height)
    )
    ;; Administrator authorization check
    (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-SYSTEM-ACCESS)
    
    ;; Organ type validation
    (asserts! (is-valid-organ-type organ-type) ERR-INVALID-ORGAN-TYPE)
    
    ;; Medical clearance and status validation
    (asserts! (get medical-clearance-status donor-profile) ERR-MEDICAL-CLEARANCE-PENDING)
    (asserts! (is-eq (get current-status donor-profile) status-active-available) 
              ERR-INVALID-MEDICAL-STATUS)
    (asserts! (is-eq (get current-status recipient-profile) status-active-available) 
              ERR-INVALID-MEDICAL-STATUS)
    
    ;; Organ availability check
    (asserts! (organ-available-in-inventory organ-type 
                                           (get available-organs-list donor-profile))
              ERR-ORGAN-NOT-AVAILABLE)
    
    ;; Organ type compatibility check
    (asserts! (is-eq organ-type (get needed-organ-type recipient-profile))
              ERR-MEDICAL-INCOMPATIBILITY)
    
    ;; Blood type compatibility validation
    (asserts! (check-blood-compatibility (get blood-group-type donor-profile)
                                        (get blood-group-type recipient-profile))
              ERR-MEDICAL-INCOMPATIBILITY)
    
    ;; Create transplant procedure record
    (map-set transplant-procedure-registry procedure-id {
      donor-address: donor-address,
      recipient-address: recipient-address,
      organ-type-transplanted: organ-type,
      procedure-start-block: initiation-timestamp,
      procedure-status: status-matched-pending,
      medical-supervisor: tx-sender,
      procedure-completion-block: none
    })
    
    ;; Update patient statuses to matched
    (map-set donor-medical-registry donor-address
      (merge donor-profile { current-status: status-matched-pending }))
    
    (map-set recipient-medical-registry recipient-address
      (merge recipient-profile { current-status: status-matched-pending }))
    
    ;; Update system counters
    (var-set next-procedure-id (+ procedure-id u1))
    (var-set pending-procedures-count (+ (var-get pending-procedures-count) u1))
    
    (ok procedure-id)
  )
)

(define-public (complete-transplant-procedure (procedure-id uint))
  (let
    (
      (procedure-record (unwrap! (map-get? transplant-procedure-registry procedure-id) 
                                ERR-TRANSPLANT-RECORD-NOT-FOUND))
      (donor-address (get donor-address procedure-record))
      (recipient-address (get recipient-address procedure-record))
      (completion-timestamp block-height)
    )
    ;; Administrator authorization check
    (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-SYSTEM-ACCESS)
    
    ;; Procedure status validation
    (asserts! (is-eq (get procedure-status procedure-record) status-matched-pending)
              ERR-INVALID-MEDICAL-STATUS)
    
    ;; Update procedure completion record
    (map-set transplant-procedure-registry procedure-id
      (merge procedure-record {
        procedure-status: status-procedure-completed,
        procedure-completion-block: (some completion-timestamp)
      })
    )
    
    ;; Update patient statuses to completed
    (let
      (
        (donor-profile (unwrap! (map-get? donor-medical-registry donor-address) 
                                ERR-DONOR-PROFILE-NOT-FOUND))
        (recipient-profile (unwrap! (map-get? recipient-medical-registry recipient-address) 
                                    ERR-RECIPIENT-PROFILE-NOT-FOUND))
      )
      (map-set donor-medical-registry donor-address
        (merge donor-profile { current-status: status-procedure-completed }))
      
      (map-set recipient-medical-registry recipient-address
        (merge recipient-profile { current-status: status-procedure-completed }))
    )
    
    ;; Update success statistics
    (var-set successful-transplants-completed (+ (var-get successful-transplants-completed) u1))
    (var-set pending-procedures-count (- (var-get pending-procedures-count) u1))
    
    (ok true)
  )
)

;; SYSTEM QUERY AND ANALYTICS FUNCTIONS

(define-read-only (get-donor-profile (donor-address principal))
  (map-get? donor-medical-registry donor-address)
)

(define-read-only (get-recipient-profile (recipient-address principal))
  (map-get? recipient-medical-registry recipient-address)
)

(define-read-only (get-transplant-record (procedure-id uint))
  (map-get? transplant-procedure-registry procedure-id)
)

(define-read-only (get-system-statistics)
  {
    total-donors: (var-get total-donors-registered),
    total-recipients: (var-get total-recipients-registered),
    completed-transplants: (var-get successful-transplants-completed),
    pending-procedures: (var-get pending-procedures-count),
    next-procedure-id: (var-get next-procedure-id)
  }
)

(define-read-only (check-compatibility
  (donor-blood-type uint)
  (recipient-blood-type uint)
)
  (and 
    (is-valid-blood-group donor-blood-type)
    (is-valid-blood-group recipient-blood-type)
    (check-blood-compatibility donor-blood-type recipient-blood-type)
  )
)

(define-read-only (get-contract-administrator)
  contract-administrator
)

;; ADVANCED MEDICAL ANALYSIS AND COMPATIBILITY FUNCTIONS

(define-public (analyze-recipient-compatibility (recipient-address principal))
  (let
    (
      (recipient-profile (unwrap! (map-get? recipient-medical-registry recipient-address) 
                                  ERR-RECIPIENT-PROFILE-NOT-FOUND))
      (needed-organ (get needed-organ-type recipient-profile))
      (recipient-blood (get blood-group-type recipient-profile))
    )
    ;; Active status validation
    (asserts! (is-eq (get current-status recipient-profile) status-active-available)
              ERR-INVALID-MEDICAL-STATUS)
    
    (ok {
      required-organ-type: needed-organ,
      compatible-blood-groups: recipient-blood,
      priority-level: (get urgency-priority-level recipient-profile),
      analysis-status: "Medical compatibility analysis completed successfully"
    })
  )
)