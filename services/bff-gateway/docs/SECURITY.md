# Security — bff-gateway

This is the system's only public-facing edge — it carries the highest
exposure to external attackers of any service in the stack.

## AuthN/AuthZ

- JWT validation happens here, on every request to a protected route —
  no route composes a downstream call without first validating the
  token, except explicitly public endpoints (e.g. `/health`, login).
- Downstream services should not be assumed to re-validate the JWT, but
  design for defense in depth anyway (see each service's own
  `SECURITY.md`) — `bff-gateway`'s validation is necessary, not
  sufficient, from the system's point of view, even though it's the only
  layer implemented today.
- Authorization (does this customer own this account/transfer) must be
  checked here before composing a response, not left entirely to
  downstream services.

## Rate limiting

Enforced here via Redis-backed counters — protects the whole backend
from a single edge chokepoint. Rate-limit by customer/token where
possible, not only by IP, since IP-based limiting alone is easy to evade
and easy to false-positive on shared NATs.

## Input validation

Every inbound DTO is validated (see `CODE_STYLE.md`) before it reaches
any composition logic or downstream call — this is the system's primary
defense against malformed/malicious input reaching internal services.

## Secrets & config

JWT signing/verification keys, downstream service URLs, and Redis
connection info via environment/config — never hardcoded, never logged.

## Logging

Don't log full request/response bodies at `INFO` — they may contain
tokens, PII forwarded from `identity-service` responses, or other
sensitive fields. Log method, route, status, correlation id, and latency
by default.

## Dependency hygiene

As the internet-facing surface, keep NestJS, its auth/rate-limit
middleware, and transitive dependencies current with security advisories
— `npm audit` should be part of the build once CI exists.
