# Architecture — fraud-service

## Role

Consumes `transfer.requested`, computes a fraud score over a sliding
window of recent activity, and emits an approve/block decision. Pure
streaming-state service — no durable system-of-record responsibility.

## Position in the system

- Synchronous: none (no HTTP calls from other services).
- Asynchronous: consumes `transfer.requested`, produces `fraud.assessed`.
  This is a single-hop, stateless-from-the-saga's-perspective step in the
  saga driven by `payments-service`.

```
payments-service --(transfer.requested)--> fraud-service
fraud-service --(fraud.assessed)--> payments-service
```

## Data ownership

- Redis, owned by this service: sliding-window counters/state per
  account (or per customer), used to compute the fraud score. This is
  ephemeral derived state, not a system of record — it can be rebuilt
  from a window of recent events if lost, within the window's time
  horizon (older history is genuinely gone, which is an accepted
  trade-off for a sliding-window score).

## Layering (Go)

```
cmd/            -> main.go, HTTP server bootstrap (health only)
internal/kafka/ -> consumer for transfer.requested, producer for fraud.assessed
internal/score/ -> sliding-window scoring logic
internal/redis/ -> Redis client, window state read/write
```

Currently a flat `main.go` with only `GET /health` — target shape above,
not current state.

## Dependencies

Only `contracts/events/`. No import of `payments-service` or any other
service's code.

## Invariant enforced here

Streaming state correctness under latency pressure: the score must
reflect a genuine recent window (not stale or double-counted data), and
`fraud.assessed` must be emitted within whatever latency budget the saga
expects — a slow or stuck fraud assessment stalls the entire transfer.
