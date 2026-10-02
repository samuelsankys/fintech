# Security — identity-service

This service has the highest sensitivity in the system: it is the only
holder of customer PII and the issuer of auth tokens. Treat everything
below as binding, not aspirational.

## PII handling

- PII (name, document numbers, address, KYC documents) is stored only
  here, never copied into other services' databases.
- `customer.registered` and any other published event must carry the
  minimum fields needed by consumers (e.g. a customer id), never raw KYC
  data. Review every new field added to an event payload for PII before
  merging.
- **No PII in logs, at any level**, including `DEBUG` and exception
  stack traces (don't let a PII field end up in an exception message
  that gets logged). This is a root-level guardrail with a required
  sensor — see `TESTING.md`.

## AuthN/AuthZ

- Token signing keys/secrets come from environment/secret store, never
  committed to `application.properties`.
- Tokens should be short-lived; refresh/rotation logic (once implemented)
  must invalidate old tokens, not just issue new ones alongside valid old
  ones.
- Credential storage: hash with a modern algorithm (e.g. bcrypt/argon2)
  with per-record salt — never store or log plaintext credentials.

## KYC simulation

Even simulated KYC data should be handled as if real: don't use real
production-like PII in test fixtures or seed data beyond what's clearly
synthetic (e.g. obviously fake names/document numbers), since fixtures
tend to leak into examples, screenshots, and logs over time.

## Transfer keys

Transfer-key → account-id resolution is a sensitive lookup (enables
targeting a specific account); rate-limit and audit it like a
credential-adjacent endpoint, enforced at `bff-gateway` and validated
here too (defense in depth).

## Dependency hygiene

This service is a prime target for credential-theft/PII-exfiltration
attacks — keep Spring Security and crypto-related dependencies current
with security advisories.
