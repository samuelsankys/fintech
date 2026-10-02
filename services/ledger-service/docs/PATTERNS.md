# Patterns — ledger-service

## Append-only ledger

Entries are immutable facts, not mutable state. Model the write path as
"insert new entries," never "find and update." This is the architectural
pattern the whole invariant table in root `CLAUDE.md` is built around for
this service.

## Outbox pattern

Entry insert + outbox row insert happen in one DB transaction; a separate
relay (polling publisher or CDC) reads the outbox and publishes to Kafka.
Never produce to Kafka directly inside the same code path that writes the
entry — that's a dual-write and can desync DB state from published events
on a crash.

## Command/event split

`ledger.post-requested` is a command (addressed to this service,
expresses intent). `ledger.entries-posted` / `ledger.post-rejected` are
events (broadcast facts about what happened). Don't conflate the two
topics or let a command topic have multiple producers.

## Idempotent consumer

Dedupe incoming `ledger.post-requested` by `eventId` before posting.
Store processed-event ids (or derive idempotency from a natural key like
transfer id) so redelivery from Kafka at-least-once semantics never
double-posts.

## Compensation, not rollback

When a posting is rejected, the saga compensates by having
`payments-service` emit `transfer.failed` — this service never reverses
its own correctly-committed entries; rejection happens before commit, not
after.
