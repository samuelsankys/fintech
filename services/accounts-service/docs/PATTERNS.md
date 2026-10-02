# Patterns — accounts-service

## CQRS (read projection)

This service is the canonical example of CQRS in this harness: writes to
balance happen elsewhere (`ledger-service`), this service only maintains a
read-optimized projection built from consumed events. Never add a code
path that writes balance here directly — that would create two sources of
truth.

## Idempotent consumer

Both `customer.registered` and `ledger.entries-posted` must be deduped by
`eventId` before mutating the projection, matching the harness-wide
idempotent-consumer guardrail.

## Event-sourced projection (partial)

The balance view is a materialized view over an event stream; it must be
rebuildable by replaying `ledger.entries-posted` from the beginning of the
topic (or from a snapshot + remaining events). Design the projection
update function as a pure fold: `(state, event) -> newState`, so replay and
incremental update share the same code path.

## No reverse dependency

`accounts-service` depends on events from `identity-service` and
`ledger-service`; it must never be depended on *by* them, and never calls
into their code — only consumes their published events via `contracts/
events/`.
