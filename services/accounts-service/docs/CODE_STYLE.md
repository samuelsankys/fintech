# Code style — accounts-service

## Language & formatting

- Java 17, Spring Boot 4.1.1. Same convention as `ledger-service`: Google
  Java Format style (4-space indent, ~100 cols), no linter wired up yet —
  enforced by review.
- Package root: `com.fintech.accountsservice`, layered the same way as
  `ledger-service` (`domain`, `application`, `infrastructure`, `controller`).

## Naming

- Distinguish explicitly between the **write side** (account, limit
  entities this service owns) and the **read/projection side** (balance
  view derived from ledger events) in type names, e.g.
  `AccountBalanceProjection` vs. `Account`. Don't let the projection type
  masquerade as a general-purpose "Account" aggregate.

## Spring conventions

- Constructor injection only.
- Kafka consumer methods are part of the application layer (use-case:
  "apply ledger entry to projection"), not raw event-handling code sitting
  in infrastructure.
- REST controllers for `bff-gateway` reads should map directly to the
  OpenAPI contract in `contracts/openapi/` — don't add ad hoc fields not
  in the contract without updating the contract first.

## Commits

- Changes to the projection rebuild logic should note whether a full
  re-projection (replay from topic start) is required, since this affects
  ops runbooks once they exist.
