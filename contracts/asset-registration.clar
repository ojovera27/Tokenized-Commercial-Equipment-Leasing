;; Asset Registration Contract
;; Records details of available equipment

;; Define data variables
(define-data-var last-asset-id uint u0)

;; Define data maps
(define-map assets
  { asset-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    serial-number: (string-ascii 50),
    acquisition-date: uint,
    acquisition-cost: uint,
    owner: principal,
    status: (string-ascii 20),  ;; available, leased, maintenance, retired
    current-value: uint
  }
)

;; Define public functions
(define-public (register-asset (name (string-ascii 100))
                              (description (string-ascii 500))
                              (serial-number (string-ascii 50))
                              (acquisition-cost uint)
                              (current-value uint))
  (let ((new-asset-id (+ (var-get last-asset-id) u1)))
    (begin
      (var-set last-asset-id new-asset-id)
      (map-set assets
        { asset-id: new-asset-id }
        {
          name: name,
          description: description,
          serial-number: serial-number,
          acquisition-date: block-height,
          acquisition-cost: acquisition-cost,
          owner: tx-sender,
          status: "available",
          current-value: current-value
        }
      )
      (ok new-asset-id)
    )
  )
)

(define-public (update-asset-status (asset-id uint) (new-status (string-ascii 20)))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err u404))))
    (if (is-eq tx-sender (get owner asset))
      (begin
        (map-set assets
          { asset-id: asset-id }
          (merge asset { status: new-status })
        )
        (ok true)
      )
      (err u403)
    )
  )
)

(define-public (update-asset-value (asset-id uint) (new-value uint))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err u404))))
    (if (is-eq tx-sender (get owner asset))
      (begin
        (map-set assets
          { asset-id: asset-id }
          (merge asset { current-value: new-value })
        )
        (ok true)
      )
      (err u403)
    )
  )
)

;; Define read-only functions
(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-asset-count)
  (var-get last-asset-id)
)
