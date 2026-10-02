# Testing — ledger-service

## Levels

1. **Unit** — posting rules, balance invariant, rejection conditions, pure
   domain logic. No Spring context (`./mvnw test` without
   `@SpringBootTest`).
2. **Property-based** — this is the harness's primary guardrail sensor for
   this service: generate arbitrary sequences of debit/credit postings and
   assert (a) sum of entries per transfer is always zero, (b) no entry is
   ever mutated after commit, (c) total ledger balance equals sum of all
   entries at any point in time. Add a property-testing dependency
   (e.g. jqwik) when business logic lands — none is wired up yet.
3. **Integration** — outbox write + Kafka publish, using Testcontainers for
   PostgreSQL (and Kafka if the relay is tested in-process). Verify the
   entry insert and outbox insert commit atomically (kill the process
   between them in a test and confirm no half-applied state).
4. **Contract** — validate produced events (`ledger.entries-posted`,
   `ledger.post-rejected`) against the schema in `contracts/events/`.

## Idempotency

`ledger.post-requested` must be safe to redeliver: posting the same
`eventId` twice must not double-post. Write an explicit test that replays
the same command twice and asserts a single set of entries exists.

## Current state

`LedgerServiceApplicationTests` is a placeholder context-load test only —
no business logic exists yet. Replace/extend it once posting logic lands;
don't leave it as the only test once there's a domain to cover.

## Running

```bash
./mvnw test
```
