# Code style — identity-service

## Language & formatting

- Java 17, Spring Boot 4.1.1, same formatting convention as the other Java
  services (Google Java Format style, 4-space indent, ~100 cols; no
  linter wired up yet — enforced by review).
- Package root: `com.fintech.identityservice`, same layering as
  `ledger-service`/`accounts-service` (`domain`, `application`,
  `infrastructure`, `controller`).

## Naming

- Keep PII-bearing types explicitly named and segregated (e.g.
  `CustomerPiiRecord` vs. `CustomerPublicView`) so it's obvious at a
  glance which objects must never cross a log line, event payload, or
  API response unfiltered.
- Token/credential handling code lives in its own package
  (`infrastructure.auth` or similar), not scattered inside controllers.

## Spring conventions

- Constructor injection only.
- Any `@RestController` returning customer data must return an explicit
  DTO/view type mapped from the domain entity — never serialize the JPA
  entity directly, to avoid accidentally exposing a PII field added later.

## Commits

- A change that adds a new field to the customer domain model must state
  explicitly whether that field is PII and, if so, confirm it is excluded
  from logs, events, and any non-KYC-scoped API response.
