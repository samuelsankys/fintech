# Patterns — fraud-service

## Sliding-window streaming state

Fraud scoring is modeled as a sliding window over recent events per
account, held in Redis (sorted sets or similar with TTL/expiry), not a
durable relational history. This service is deliberately scoped to
"recent behavior," not "all-time history" — don't reach for PostgreSQL
here; that would change the service's whole performance/consistency
profile away from what it's meant to test.

## Idempotent consumer

Dedupe `transfer.requested` by `eventId` before updating window state,
same as every other consumer in the system.

## Stateless decision, stateful input

The scoring *decision* for a given request is a pure function of the
current window state at request time; don't let the decision depend on
anything outside the window (e.g. a separate out-of-band call to another
service) — that would reintroduce synchronous coupling this service is
meant to avoid.

## Single-hop event responder

`fraud-service` only ever responds to `transfer.requested` with exactly
one `fraud.assessed`. It does not participate in multi-step choreography
and does not call back into `payments-service` synchronously — the
orchestrator pattern lives entirely in `payments-service` (see its
`PATTERNS.md`).
