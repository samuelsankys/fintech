# Testing — payments-service

## Levels

1. **Unit** — saga state machine transitions, table-driven tests covering
   every (current state, incoming event) pair, including invalid
   transitions (must be rejected/logged, not silently accepted).
2. **Idempotency** — the same transfer request (same idempotency key)
   submitted twice must result in exactly one saga instance and one
   outcome event, not two. Same for redelivery of `fraud.assessed` /
   `ledger.entries-posted` with the same `eventId`.
3. **Compensation paths** — explicit tests for every failure branch:
   fraud rejects, ledger rejects, infra error mid-saga. Each must resolve
   to `transfer.failed`, never leave saga state stuck.
4. **Integration** — Testcontainers PostgreSQL (+ Kafka if tested
   in-process) driving a full saga from `transfer.requested` to
   `transfer.completed`/`transfer.failed`.
5. **Contract** — request/response against `contracts/openapi/`, produced
   events against `contracts/events/`.

## Running

```bash
go test ./...
go vet ./...
```

## Current state

No tests exist beyond what `go test ./...` trivially passes on an empty
package — add table-driven state machine tests as the first thing once
saga logic lands, since this is the highest-complexity service in the
system (per root `AGENTS.md`, it's the orchestrator).
