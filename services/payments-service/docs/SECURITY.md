# Security — payments-service

## Threat surface

Public-facing indirectly via `bff-gateway`. Even though `bff-gateway`
handles JWT validation at the edge, `payments-service` must not assume a
request reaching it is fully authorized for the specific accounts
involved — validate that the authenticated customer actually owns/can
act on the source account before starting a saga.

## Idempotency as a security property

A missing or weak idempotency check isn't just a correctness bug here —
it's a double-spend risk (a replayed/retried request triggering two
transfers). Treat the idempotency key check as a hard gate before any
saga step runs, not best-effort.

## Data sensitivity

Saga state includes account ids and amounts — financial data, not raw
PII. Don't log full saga state payloads at `INFO`; log transfer id,
correlation id, and status transitions, not amounts, by default.

## Saga integrity

- Validate that `fraud.assessed` and `ledger.entries-posted`/`ledger.post-
  rejected` events actually correlate to a saga this service started
  (match on correlation id) before acting on them — don't process an
  event for an unknown or already-terminal saga.
- A saga must never be allowed to post to the ledger twice for the same
  transfer id, even under concurrent event delivery — guard with a
  state-machine check, not just a database unique constraint as the only
  line of defense.

## Secrets & config

DB and Kafka credentials via environment/config, not committed.
