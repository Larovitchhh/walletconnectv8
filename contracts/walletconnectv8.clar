;; --------------------------------------------------
;; LEVEL 7 - THE FINAL VERSION (STRICT & TESTED)
;; --------------------------------------------------

;; 1. Definir el NFT
(define-non-fungible-token VIP-CARD uint)

;; 2. Variables de estado
(define-data-var last-id uint u0)
(define-data-var contract-owner principal tx-sender)

;; 3. Mapas
(define-map donations principal uint)
(define-map has-nft principal bool)

;; --- Funciones Públicas ---

;; Función para donar y ser VIP
(define-public (donate (amount uint))
    (begin
        ;; Transferencia de STX
        (try! (stx-transfer? amount tx-sender (var-get contract-owner)))
        ;; Guardar la donación
        (map-set donations tx-sender (+ (default-to u0 (map-get? donations tx-sender)) amount))
        (ok true)
    )
)

;; Función para reclamar el NFT
(define-public (claim-membership)
    (let 
        (
            (sender tx-sender)
            (total (default-to u0 (map-get? donations sender)))
            (new-id (+ (var-get last-id) u1))
        )
        ;; Requisitos: +10 STX y no tener el NFT
        (asserts! (>= total u10000000) (err u403))
        (asserts! (is-none (map-get? has-nft sender)) (err u406))
        
        ;; Minteo
        (try! (nft-mint? VIP-CARD new-id sender))
        
        ;; Actualizar estado
        (var-set last-id new-id)
        (map-set has-nft sender true)
        (ok new-id)
    )
)

;; --- Funciones de Lectura ---
(define-read-only (get-user-data (user principal))
    {
        total-donated: (default-to u0 (map-get? donations user)),
        has-nft: (default-to false (map-get? has-nft user))
    }
)
