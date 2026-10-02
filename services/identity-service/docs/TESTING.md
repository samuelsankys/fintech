# Testing — identity-service

## Levels

1. **Unit** — token issuance/validation, transfer-key resolution, KYC
   status transitions.
2. **Integration** — Testcontainers PostgreSQL; registration flow end to
   end (create customer -> event published -> DB state correct).
3. **Log-lint test (required guardrail)** — assert that no PII field
   (name, document number, address, etc.) ever appears in a log line
   produced by this service. This is the sensor for the root `CLAUDE.md`
   guardrail "No PII in logs." Implement as a test that captures log
   output for representative code paths (registration, login, KYC check)
   and asserts PII patterns are absent.
4. **Event payload test** — assert `customer.registered` payload contains
   only the minimal fields `accounts-service` needs (e.g. customer id,
   not raw KYC data); fail the build if a new PII field is added to the
   event without an explicit, reviewed opt-in.
5. **Contract** — auth/KYC/transfer-key REST endpoints validated against
   `contracts/openapi/`.

## Current state

`IdentityServiceApplicationTests` is a placeholder context-load test —
replace/extend once auth/KYC logic exists, and add the log-lint test
before any PII-bearing code path ships.

## Running

```bash
./mvnw test
```
