# Architecture — bff-gateway

## Role

Single API entry point for the system: JWT authentication, request
composition across backend services, rate limiting. The only place in
the system where synchronous service-to-service calls happen.

## Position in the system

- Synchronous: calls `identity-service` (auth/KYC/transfer-key),
  `accounts-service` (balance/limits reads), `payments-service` (submit
  transfer), `statements-service` (statement reads) — each per the
  OpenAPI contract in `contracts/openapi/`.
- Asynchronous: none. `bff-gateway` is explicitly synchronous-only per
  the system architecture (see root `AGENTS.md`) — it does not produce or
  consume Kafka events.

```
client --(HTTPS + JWT)--> bff-gateway --(sync REST)--> identity-service, accounts-service, payments-service, statements-service
```

## Data ownership

- Redis, owned by this service: rate-limit counters and (if/when
  session-adjacent state is needed) short-lived cache. No durable
  business data lives here — `bff-gateway` is stateless with respect to
  the domain; it composes, it doesn't store.

## Layering (NestJS)

```
src/main.ts         -> bootstrap, listens on process.env.PORT
src/app.module.ts    -> root module, imports feature modules
src/<feature>/        -> one module per composed capability (auth, transfers,
                         accounts, statements), each with its own
                         controller/service/DTOs
```

Current scaffold has only the Nest CLI default `app.*` files and
`GET /health` — the per-feature module layout above is the target shape.

## Dependencies

Only `contracts/openapi/` (the contracts it composes against) and
whatever HTTP client library is chosen. No import of any service's
internal code — calls happen strictly over HTTP against the published
contract.

## Invariant enforced here

Synchronous API follows contract: every endpoint this service exposes,
and every downstream call it makes, must match `contracts/openapi/` —
this is the one service where a contract drift is immediately
user-visible.
