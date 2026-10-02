# Code style — ledger-service

## Language & formatting

- Java 17, Spring Boot 4.1.1. Standard Google Java Format conventions
  (4-space indent, 100-col soft wrap) until a linter is wired up — there is
  none configured yet (`./mvnw` has no `spotless`/`checkstyle` plugin), so
  this is enforced by review, not CI.
- Package root: `com.fintech.ledgerservice`. Sub-package by layer
  (`domain`, `application`, `infrastructure`, `controller`/`messaging`), not
  by technical type (no `com.fintech.ledgerservice.entities` dumping
  ground).

## Naming

- Domain types use ledger vocabulary, not DB vocabulary: `LedgerEntry`, not
  `LedgerEntryRow` / `LedgerEntryDTO` unless a DTO genuinely crosses a
  boundary (REST/Kafka payload vs. domain object).
- Money is never a primitive `double`/`float`. Use `BigDecimal` with a
  fixed `MathContext`/scale, or an integer minor-unit type — pick one and
  apply it everywhere in this service; do not mix representations.

## Spring conventions

- Constructor injection only, no field `@Autowired`.
- Keep `@Transactional` boundaries at the application/use-case layer, not
  scattered across repositories.
- Configuration via `application.properties` (current convention in this
  service) — don't introduce YAML in parallel without a reason.

## Commits

- Business logic changes to posting rules should reference the
  `contracts/events/` schema version they target, since ledger behavior is
  the contract other services build invariants on top of.
