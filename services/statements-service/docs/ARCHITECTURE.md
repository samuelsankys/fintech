# Architecture — statements-service

## Role

Account statement as a read-model built purely from events —
search/export over transfer and ledger history. Owns no write path of
its own; it projects and can replay.

## Position in the system

- Synchronous: serves `bff-gateway` for statement search/export reads
  (contract in `contracts/openapi/`).
- Asynchronous: consumes `ledger.entries-posted`, `transfer.completed`,
  `transfer.failed` to build/update the statement projection.

```
ledger-service --(ledger.entries-posted)--> statements-service
payments-service --(transfer.completed | transfer.failed)--> statements-service
bff-gateway --(sync read: search/export)--> statements-service
```

## Data ownership

- PostgreSQL, owned by this service: the statement projection
  (transaction history per account, denormalized for search/export).
  Entirely derived state — must be reconstructible from a full replay of
  the consumed topics from the beginning.

## Layering (NestJS)

```
src/main.ts         -> bootstrap, listens on process.env.PORT
src/app.module.ts    -> root module
src/events/           -> Kafka consumers, one handler per consumed topic
src/statements/       -> query module: search/export endpoints for bff-gateway
```

Current scaffold has only the Nest CLI default `app.*` files and
`GET /health` — the module layout above is the target shape.

## Dependencies

Only `contracts/events/` and `contracts/openapi/`. No import of
`ledger-service` or `payments-service` code — statement data arrives only
as events.

## Invariant enforced here

Event projection/replay correctness: the statement view must always be
derivable by replaying the consumed topics, and must stay consistent
with the ledger's append-only history it's projecting (never show a
transaction that wasn't actually posted, never miss one that was).
