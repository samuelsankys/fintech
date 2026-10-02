# Security — ledger-service

## Threat surface

This service has no public ingress (no direct calls from `bff-gateway` or
the internet) — its only inputs are Kafka messages from `payments-service`
and its own actuator/health endpoints. Treat Kafka messages as untrusted
input anyway: validate schema and business invariants before acting, don't
assume an upstream service always sends well-formed commands.

## Data sensitivity

Ledger entries reference account ids and amounts, not customer PII
directly. Still: do not log full entry payloads at `INFO` in production
profiles — amounts and account identifiers are sensitive financial data.
Log entry ids/correlation ids, not raw balances, at `INFO`; full payloads
only at `DEBUG` and never in a shipped/aggregated log sink.

## Integrity

- No endpoint or code path may `UPDATE`/`DELETE` a posted ledger entry.
  Any "correction" is a new, auditable compensating entry referencing the
  original.
- Reject (via `ledger.post-rejected`), don't silently clamp or auto-correct,
  any posting that would violate debits=credits.

## Secrets & config

- DB credentials and Kafka connection info via environment/config, never
  hardcoded in `application.properties` committed to the repo.
- Actuator endpoints beyond `/health` (e.g. `/actuator/env`,
  `/actuator/beans`) must not be exposed outside the internal network —
  restrict via Spring Security or network policy once more actuator
  endpoints are enabled.

## Dependency hygiene

Spring Boot/Java dependency versions should track security advisories;
this service is the financial source of truth, so it's the highest-value
target for a supply-chain or RCE issue in the stack.
