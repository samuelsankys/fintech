# Architecture — identity-service

## Role

Owns customers, simulated KYC, auth tokens, and transfer keys (Pix-style
aliases resolving to accounts). Source of truth for "who is this customer"
and "what account does this transfer key point to."

## Position in the system

- Synchronous: serves `bff-gateway` for login/token/customer-lookup/
  transfer-key-resolution reads (contract in `contracts/openapi/`).
- Asynchronous: produces `customer.registered`, consumed by
  `accounts-service` to open the projected account record.

```
bff-gateway --(sync: auth, KYC, transfer-key lookup)--> identity-service
identity-service --(customer.registered)--> accounts-service
```

## Data ownership

- PostgreSQL, owned exclusively by this service: customers, KYC status,
  tokens/credentials (hashed), transfer-key → account-id mappings.
- This is the only service allowed to hold raw PII. Every other service
  that needs "is this a known customer" gets it via `customer.registered`
  or a token claim, never by reading this DB or re-deriving PII.

## Layering (Spring Boot)

```
controller/   -> REST auth/KYC/transfer-key endpoints
application/  -> use cases: register customer, issue token, resolve key
domain/       -> Customer, KycStatus, TransferKey
infrastructure/ -> JPA repositories, Kafka producer, token signing
```

## Dependencies

Only `contracts/events/` and `contracts/openapi/`. No other service may
import this service's code, and this service must not leak PII fields
into the `customer.registered` event payload beyond what
`accounts-service` genuinely needs (e.g. customer id, not full KYC
document data).

## Invariant enforced here

PII must never leak outside this service's boundary except through
explicitly minimized event/token payloads — see `SECURITY.md`.
