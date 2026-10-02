# Testing — fraud-service

## Levels

1. **Unit** — sliding-window scoring logic as pure functions: given a
   sequence of timestamped events, assert the computed score. Table-
   driven, covering window boundaries (event exactly at window edge),
   empty history, burst activity.
2. **Integration** — Redis (via Testcontainers or a local instance)
   backing the window state; verify state expiry/eviction matches the
   intended window size.
3. **Idempotency** — redelivering the same `transfer.requested` (same
   `eventId`) must not double-count it in the sliding window.
4. **Latency** — since latency is this service's explicit test
   dimension, add a benchmark or load test asserting `fraud.assessed` is
   emitted within the target budget under realistic throughput, once a
   budget is defined.
5. **Contract** — consumed/produced events validated against
   `contracts/events/`.

## Running

```bash
go test ./...
go vet ./...
```

## Current state

No business-logic tests exist yet — add scoring unit tests first, since
they're pure and don't need Redis to start.
