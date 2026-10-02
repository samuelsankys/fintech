# AGENTS.md — payments-service

## Responsibility

Orchestrates the instant-transfer saga: idempotency, state transitions, and
compensations across the ledger/fraud/accounts flow. Orchestrator-style
saga (this service drives the steps), not choreography.

## Stack & version

- Go 1.22, standard library only (`net/http`) — no framework yet, since
  there is no business logic in this scaffold.

## Build / test / lint

```bash
go build ./...
go test ./...
go vet ./...
```

## Package layout

- `main.go` — HTTP server entrypoint, currently just `GET /health`.
- `go.mod` — module definition.

## Events produced / consumed

(none yet — placeholder; see `contracts/events/` once the transfer saga
topics from the planning doc are implemented: produces
`transfer.requested`, `ledger.post-requested`, `transfer.completed`,
`transfer.failed`; consumes `fraud.assessed`, `ledger.entries-posted`,
`ledger.post-rejected`.)

## What not to touch

(none yet)
