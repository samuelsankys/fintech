# AGENTS.md — fraud-service

## Responsibility

Consumes transfer events, computes a fraud score over a sliding window,
and approves or blocks the transfer.

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

(none yet — placeholder; see `contracts/events/` once implemented:
consumes `transfer.requested`; produces `fraud.assessed`. State is kept in
Redis per the design.)

## What not to touch

(none yet)
