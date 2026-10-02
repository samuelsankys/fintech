# Testing — accounts-service

## Levels

1. **Unit** — limit rules, projection update logic (given an existing
   projection state + a `ledger.entries-posted` payload, assert the
   resulting state), account-opening logic from `customer.registered`.
2. **Integration** — Testcontainers PostgreSQL; consume a sequence of
   events and assert the projection table matches expectations after
   replay.
3. **Idempotency** — redeliver the same `ledger.entries-posted` /
   `customer.registered` event twice (same `eventId`); projection state
   must be identical to a single delivery. This is a required guardrail
   sensor per root `CLAUDE.md` ("consumers are idempotent").
4. **Contract** — bff-gateway-facing REST responses validated against
   `contracts/openapi/`.
5. **Replay/rebuild** — since the balance projection is derived state,
   include a test that rebuilds it from a full event replay and compares
   against the incrementally-updated version; they must match exactly.

## Current state

`AccountsServiceApplicationTests` is a placeholder context-load test —
replace/extend once projection logic exists.

## Running

```bash
./mvnw test
```
