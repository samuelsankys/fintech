# Patterns — bff-gateway

## Backend-for-frontend / composition edge

This service exists to compose multiple backend services' responses into
client-shaped responses, and to be the single place synchronous calls are
allowed per the architecture. Don't let any other service grow its own
synchronous inter-service HTTP client "just this once" — that's the
pattern this service exists to contain.

## Edge authentication, not service authentication

JWT validation is a gateway concern. Downstream services should receive
already-validated identity (e.g. a forwarded/derived claim), not raw
credentials — but see `SECURITY.md`: this doesn't mean downstream
services should skip their own authorization checks.

## Client-per-service

Each downstream service gets its own typed HTTP client wrapper
(`IdentityClient`, `AccountsClient`, `PaymentsClient`,
`StatementsClient`), isolating retry/timeout/error-mapping policy per
target rather than a single generic HTTP-call-everything helper that
hides which service is actually being called.

## No event production/consumption here

By design, `bff-gateway` stays out of the Kafka-based saga entirely.
Resist the temptation to have it consume `transfer.completed` for a
"real-time update to the client" feature without a deliberate
architecture decision (e.g. WebSocket/SSE gateway) — that would blur the
sync/async boundary the whole system is organized around.

## Rate limiting as a cross-cutting concern

Implemented as a Nest guard/interceptor applied broadly (globally or per
module), not re-implemented per route.
