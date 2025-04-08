;; Lessee Verification Contract
;; Validates qualified business entities

;; Define data maps
(define-map verified-lessees
  { lessee-principal: principal }
  {
    business-name: (string-ascii 100),
    business-id: (string-ascii 50),
    credit-score: uint,
    verification-date: uint,
    verification-expiry: uint,
    status: (string-ascii 20)  ;; active, suspended, expired
  }
)

(define-map verification-authorities
  { authority-principal: principal }
  { is-active: bool }
)

;; Define data variables
(define-data-var verification-period uint u52560)  ;; Default 1 year in blocks (assuming 10 min blocks)

;; Define public functions
(define-public (register-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (map-set verification-authorities
      { authority-principal: authority }
      { is-active: true }
    )
    (ok true)
  )
)

(define-public (verify-lessee (lessee principal)
                             (business-name (string-ascii 100))
                             (business-id (string-ascii 50))
                             (credit-score uint))
  (begin
    (asserts! (is-authority tx-sender) (err u403))
    (map-set verified-lessees
      { lessee-principal: lessee }
      {
        business-name: business-name,
        business-id: business-id,
        credit-score: credit-score,
        verification-date: block-height,
        verification-expiry: (+ block-height (var-get verification-period)),
        status: "active"
      }
    )
    (ok true)
  )
)

(define-public (update-lessee-status (lessee principal) (new-status (string-ascii 20)))
  (let ((lessee-data (unwrap! (map-get? verified-lessees { lessee-principal: lessee }) (err u404))))
    (begin
      (asserts! (is-authority tx-sender) (err u403))
      (map-set verified-lessees
        { lessee-principal: lessee }
        (merge lessee-data { status: new-status })
      )
      (ok true)
    )
  )
)

(define-public (update-credit-score (lessee principal) (new-score uint))
  (let ((lessee-data (unwrap! (map-get? verified-lessees { lessee-principal: lessee }) (err u404))))
    (begin
      (asserts! (is-authority tx-sender) (err u403))
      (map-set verified-lessees
        { lessee-principal: lessee }
        (merge lessee-data { credit-score: new-score })
      )
      (ok true)
    )
  )
)

;; Define read-only functions
(define-read-only (get-lessee-verification (lessee principal))
  (map-get? verified-lessees { lessee-principal: lessee })
)

(define-read-only (is-verified-lessee (lessee principal))
  (let ((lessee-data (default-to
                      {
                        business-name: "",
                        business-id: "",
                        credit-score: u0,
                        verification-date: u0,
                        verification-expiry: u0,
                        status: "none"
                      }
                      (map-get? verified-lessees { lessee-principal: lessee }))))
    (and
      (is-eq (get status lessee-data) "active")
      (< block-height (get verification-expiry lessee-data))
    )
  )
)

(define-read-only (is-authority (principal principal))
  (default-to false (get is-active (map-get? verification-authorities { authority-principal: principal })))
)

;; Contract owner
(define-constant contract-owner tx-sender)
