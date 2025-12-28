;; --------------------------------------------------
;; LEVEL 7 - FIX (Functional NFT & Tipping)
;; --------------------------------------------------

;; Definición del NFT
(define-non-fungible-token MEMBERSHIP-NFT uint)

;; Variables de estado
(define-data-var last-id uint u0)
(define-data-var contract-owner principal tx-sender)

;; Mapas
(define-map donations principal uint)
(define-map has-minted-nft principal bool)

;; --- Funciones Públicas ---

;; 1. DONAR (Ahora usa un flujo más robusto)
(define-public (donate (amount uint))
    (let (
        (sender tx-sender)
        (current-donations (default-to u0 (map-get? donations sender)))
    )
        ;; Validar que el monto sea mayor a 0
        (asserts! (> amount u0) (err u100))
        
        ;; Transferir STX al dueño del contrato
        (try! (stx-transfer? amount sender (var-get contract-owner)))
        
        ;; Actualizar el mapa de donaciones
        (map-set donations sender (+ current-donations amount))
        (ok true)
    )
)

;; 2. RECLAMAR NFT (Corregida la validación)
(define-public (claim-membership)
    (let (
        (sender tx-sender)
        (total-donated (default-to u0 (map-get? donations sender)))
        (next-id (+ (var-get last-id) u1))
    )
        ;; Check 1: ¿Ha llegado a 10 STX (10,000,000 uSTX)?
        (asserts! (>= total-donated u10000000) (err u403))
        
        ;; Check 2: ¿Ya tiene el NFT?
        (asserts! (is-none (map-get? has-minted-nft sender)) (err u406))

        ;; Mintear el NFT
        (try! (nft-mint? MEMBERSHIP-NFT next-id sender))
        
        ;; Actualizar estado
        (var-set last-id next-id)
        (map-set has-minted-nft sender true)
        (ok next-id)
    )
)

;; --- Funciones de Lectura para AppKit ---

(define-read-only (get-user-data (user principal))
    {
        total-stx: (default-to u0 (map-get? donations user)),
        is-member: (default-to false (map-get? has-minted-nft user))
    }
)
