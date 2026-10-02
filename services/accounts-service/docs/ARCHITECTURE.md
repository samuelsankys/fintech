# Architecture — accounts-service

## Role

Owns accounts and limits; exposes balance as a **read projection** (CQRS),
not as a write-owning source of truth — `ledger-service` owns the real
balance truth via entries. This service's job is to keep a fast, queryable
view in sync with ledger events.

## Position in the system

- Synchronous: serves `bff-gateway` with account/balance/limit reads
  (contract in `contracts/openapi/`).
- Asynchronous: consumes `customer.registered` (opens the account) and
  `ledger.entries-posted` (projects balance changes). Produces no events
  in the core saga today.

```
identity-service --(customer.registered)--> accounts-service
ledger-service --(ledger.entries-posted)--> accounts-service
bff-gateway --(sync read)--> accounts-service
```

## Data ownership

- PostgreSQL, owned by this service: accounts, limits, and a balance
  projection table rebuilt/updated from consumed events.
- The projection is derived state — it must always be reconstructible by
  replaying `ledger.entries-posted` from the start. Treat it as a cache
  over the ledger, not as independent truth: if projection and ledger ever
  disagree, the ledger wins.

## Layering (Spring Boot)

```
controller/   -> REST read endpoints for bff-gateway
application/  -> query handlers, projection update handlers
domain/       -> Account, Limit, balance-projection rules
infrastructure/ -> JPA repositories, Kafka consumer
```

## Dependencies

Only `contracts/events/` and `contracts/openapi/`. No import of
`ledger-service` or `identity-service` code — account-opening and balance
facts arrive only as events.

## Invariant enforced here

Read/write separation: accounts-service must never attempt to directly
mutate the ledger or treat its own projection as authoritative over a
conflicting ledger entry.
