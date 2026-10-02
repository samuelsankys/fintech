# Testing — statements-service

## Levels

1. **Unit** — Jest, projection update logic: given a current projection
   state + an incoming event, assert the resulting state. Pure functions
   where possible, no NestJS context needed.
2. **Idempotency** — redeliver the same `ledger.entries-posted` /
   `transfer.completed` / `transfer.failed` event (same `eventId`) twice;
   projection must be identical to a single delivery.
3. **Replay correctness** — this is the required guardrail sensor for
   this service ("event projection/replay" per root `AGENTS.md`): rebuild
   the projection from a full replay of recorded events and compare
   against the incrementally-built version; they must match exactly. Add
   this as an explicit integration test once event consumption exists.
4. **Integration** — e.g. Testcontainers PostgreSQL for the projection
   store; consume a sequence of events end to end and assert query
   results.
5. **Contract** — statement search/export endpoints validated against
   `contracts/openapi/`.

## Running

```bash
npm install
npm test
npm run lint
```

## Current state

`app.controller.spec.ts` / `test/app.e2e-spec.ts` cover only the
scaffold's `GET /health`. Add projection and replay tests as the first
priority once event consumption lands — this service's entire value is
the correctness of that projection.
