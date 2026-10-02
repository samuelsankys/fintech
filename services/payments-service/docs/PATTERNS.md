# Patterns — payments-service

## Saga orchestration (not choreography)

This service is the single orchestrator of the transfer saga — it alone
decides what happens next given the current state and an incoming event.
`fraud-service` and `ledger-service` don't talk to each other directly and
don't know about the overall saga; they only respond to commands from
`payments-service` and emit facts back to it. Don't introduce a direct
event dependency between `fraud-service` and `ledger-service` — that
would turn this into choreography and split the saga logic across
services.

## Idempotency key

Every transfer request carries (or is assigned) an idempotency key that
maps 1:1 to a saga instance. All state transitions and side effects are
keyed off it. This is the mechanism that makes "retry the same request" a
safe default for callers.

## Compensating transaction

On fraud rejection or ledger rejection, the saga doesn't "undo" anything
that already succeeded — earlier steps in the happy path (none, since
fraud/ledger both gate forward progress) are compensated purely by
transitioning to `transfer.failed`. If a future saga step has a side
effect that needs explicit reversal, model it as an explicit compensating
action in the state machine, not an ad hoc rollback.

## Outbox pattern

Saga-state DB write + outbox row in the same transaction; a relay
publishes to Kafka. Same rule as the Java services: never produce
directly to Kafka in the same code path as the DB write without an
outbox in between.

## Command vs. event topics

`transfer.requested` and `ledger.post-requested` are commands this
service issues; `fraud.assessed`, `ledger.entries-posted`, `ledger.post-
rejected` are facts it reacts to. Keep that direction consistent when
adding new saga steps.
