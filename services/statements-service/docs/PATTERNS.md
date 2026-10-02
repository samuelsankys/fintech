# Patterns — statements-service

## Event-sourced read-model

The statement is a materialized view over `ledger.entries-posted` and
`transfer.completed`/`transfer.failed` — not an independent write path.
This service's entire reason for existing in the harness is to exercise
"event projection/replay" (per root `AGENTS.md`); treat replayability as
a first-class requirement, not an afterthought.

## Idempotent consumer

Every consumed event is deduped by `eventId` before updating the
projection, consistent with every other consumer in the system.

## Pure projection function

Model projection updates as `(state, event) -> newState` so the same
function handles both live incremental updates and full replay from
topic start — two code paths computing the same logic differently is how
replay and live state silently diverge.

## Query/ingestion separation

Ingestion (event handlers updating the projection) and querying (serving
`bff-gateway` reads) are separate modules with no shared mutable state
beyond the projection store itself — query code never mutates, ingestion
code never serves a read request directly.

## No reverse dependency

`statements-service` depends on events from `ledger-service` and
`payments-service`; it is never depended on by them, and never calls into
their code.
