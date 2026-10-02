# Architecture — payments-service

## Role

Orchestrates the instant-transfer saga end to end: receives the transfer
intent, drives fraud assessment and ledger posting in order, and decides
whether the saga completes or compensates. This is the only service that
knows the full saga state machine.

## Position in the system

- Synchronous: receives the transfer request from `bff-gateway`.
- Asynchronous: orchestrator-style saga (this service drives every step,
  no choreography between the other services).

```
bff-gateway --(sync: POST transfer)--> payments-service
payments-service --(transfer.requested)--> fraud-service
fraud-service --(fraud.assessed)--> payments-service
payments-service --(ledger.post-requested)--> ledger-service
ledger-service --(ledger.entries-posted | ledger.post-rejected)--> payments-service
payments-service --(transfer.completed | transfer.failed)--> notification-service, statements-service
```

## Data ownership

- PostgreSQL, owned by this service: saga state (transfer id, current
  step, idempotency key, status), plus an outbox table for published
  events.
- Idempotency key (e.g. client-supplied or derived) is the primary
  dedup key for an incoming transfer request — a retry of the same
  request must not start a second saga instance.

## Layering (Go)

```
cmd/           -> main.go, HTTP server bootstrap
internal/http/ -> handlers for bff-gateway-facing endpoints
internal/saga/ -> state machine: transfer.requested -> fraud -> ledger -> completed/failed
internal/kafka/-> producers/consumers for saga events
internal/store/-> saga state persistence (PostgreSQL)
```

Currently a flat `main.go` with only `GET /health` — this layout is the
target shape once saga logic lands, not the current state.

## Dependencies

Only `contracts/events/` and `contracts/openapi/`. No import of
`ledger-service`, `fraud-service`, or any other service's code — saga
steps communicate only via Kafka events per the topic table above.

## Invariant enforced here

Cross-service ordering and retry: the saga must never post to the ledger
before a fraud decision is received, and a failed/rejected step must
always resolve to `transfer.failed`, never leave the saga stuck in an
ambiguous state.
