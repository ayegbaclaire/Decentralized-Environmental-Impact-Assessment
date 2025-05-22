;; Project Verification Contract
;; Validates development initiatives and their legitimacy

(define-data-var contract-owner principal tx-sender)

;; Project status enum: 0-pending, 1-approved, 2-rejected
(define-map projects
  { project-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    location: (string-utf8 100),
    status: uint,
    verification-date: uint,
    verifier: (optional principal)
  }
)

(define-data-var next-project-id uint u1)

;; Register a new project
(define-public (register-project (name (string-utf8 100)) (description (string-utf8 500)) (location (string-utf8 100)))
  (let ((project-id (var-get next-project-id)))
    (begin
      (map-set projects
        { project-id: project-id }
        {
          owner: tx-sender,
          name: name,
          description: description,
          location: location,
          status: u0, ;; pending
          verification-date: u0,
          verifier: none
        }
      )
      (var-set next-project-id (+ project-id u1))
      (ok project-id)
    )
  )
)

;; Verify a project (only contract owner can verify)
(define-public (verify-project (project-id uint) (status uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (asserts! (or (is-eq status u1) (is-eq status u2)) (err u400))
    (match (map-get? projects { project-id: project-id })
      project (begin
        (map-set projects
          { project-id: project-id }
          (merge project {
            status: status,
            verification-date: block-height,
            verifier: (some tx-sender)
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Read-only function to get project details
(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
