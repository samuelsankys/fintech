# Architecture — ledger-service

## Role

Source of truth for account balance. Double-entry, append-only ledger.
Every transfer becomes a pair of entries (debit + credit) that must net to
zero. This service owns the invariant the whole harness is built to test:
**ledger entries are never updated or deleted, and debits always equal
credits.**

## Position in the system

- Synchronous: none (no HTTP calls from other services; `bff-gateway` never
  calls this service directly). Only `GET /health` / actuator endpoints are
  synchronous, for ops.
- Asynchronous: this is a pure event-driven service. It is the last writer
  in the transfer saga before the saga either completes or compensates.

```
payments-service --(ledger.post-requested)--> ledger-service
ledger-service --(ledger.entries-posted)--> payments-service, accounts-service, statements-service
ledger-service --(ledger.post-rejected)--> payments-service
```

## Data ownership

- PostgreSQL, owned exclusively by this service. No other service reads
  this database directly — `accounts-service` and `statements-service` get
  ledger data only via `ledger.entries-posted`.
- Write model: an append-only `ledger_entries` table (or equivalent),
  partitioned/indexed by account id. No `UPDATE`/`DELETE` statements
  against entry rows, ever — corrections are new compensating entries.
- Outbox table in the same transaction as the entry insert; a relay
  publishes to Kafka. Never dual-write (DB commit + direct Kafka produce in
  two separate transactions).

## Layering (Spring Boot)

```
controller/   -> inbound Kafka listener (or REST for health/ops only)
application/  -> use case: "post ledger entries for a transfer"
domain/       -> LedgerEntry, Account balance invariant, posting rules
infrastructure/ -> JPA repositories, outbox table, Kafka producer
```

Domain layer has no framework imports (no `@Entity` reaching into business
rule code beyond simple JPA annotations); posting/validation logic must be
testable without Spring context.

## Dependencies

Only `contracts/events/` (event schemas) and `contracts/openapi/` if a
synchronous admin endpoint is ever added. No imports from
`accounts-service`, `payments-service`, or any other service module.

## Invariant enforced here

Debits = credits per transfer, entries immutable once committed. A
violation attempt (e.g. insufficient funds, duplicate posting) must result
in `ledger.post-rejected`, never a silently dropped or partially-applied
entry.
