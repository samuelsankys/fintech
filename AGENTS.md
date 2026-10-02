# AGENTS.md — fintech (harness root context)

This file is the root-level context for an AI agent working in this
monorepo. It exists to test a harness, not to ship a product: see
`CLAUDE.md` and `Harness-first sistema distribuído poliglota — documento
inicial.md` for the full rationale.

## System purpose

A digital-bank / instant-transfer (Pix-style) backend, chosen because it
has strong, verifiable invariants (ledger balance, idempotency, event
ordering) that give an agent concrete rules to either respect or break.

## Services and stacks

| Service | Stack | Responsibility |
|---|---|---|
| `services/ledger-service` | Java / Spring Boot | Double-entry ledger, append-only, source of truth for balance |
| `services/accounts-service` | Java / Spring Boot | Accounts, limits, balance as projection (CQRS) |
| `services/identity-service` | Java / Spring Boot | Customers, simulated KYC, tokens, transfer keys |
| `services/payments-service` | Go | Orchestrates the transfer saga: idempotency, states, compensation |
| `services/fraud-service` | Go | Consumes events, sliding-window score, approve/block |
| `services/bff-gateway` | Node.js / NestJS | Single API entry point: JWT, composition, rate limiting |
| `services/statements-service` | Node.js | Statement as a read-model of events, search/export |
| `services/notification-service` | Node.js | Templates, simulated channels, retry + DLQ |

Each service folder has its own `AGENTS.md` with responsibility, stack
version, build/test/lint commands, package layout, events produced/
consumed, and what not to touch there.

## Global commands

Run from the repo root (see `platform/Makefile`):

```bash
make -f platform/Makefile up     # start Kafka, PostgreSQL, Redis, MongoDB + all services (docker compose)
make -f platform/Makefile down   # stop everything
make -f platform/Makefile build  # build every service with its own toolchain
make -f platform/Makefile test   # run every service's test suite
```

## Hard rule: no cross-service imports

A service never imports code from another service — only the shared
contracts in `contracts/`. This simulates a multirepo inside a monorepo.
There is no automated sensor for this yet (planned in `harness/sensors/`);
until it exists, treat the rule as binding anyway.

## Architecture

- Synchronous calls only at the edge (`bff-gateway` → services).
- Everything between services is an event on Kafka.
- Any service with a database publishes via the outbox pattern.
- Event contracts live in `contracts/events/`; synchronous API contracts in
  `contracts/openapi/`. Code follows the contract, never the reverse.

## Harness layout

- `harness/skills/` — repeatable procedures (change an event schema, add a
  saga step, add an endpoint, scaffold a service from a template).
- `harness/guardrails/` — machine-verifiable rules, each tied to a sensor.
- `harness/sensors/` — scripts an agent runs itself and reads the result of.

These three folders are currently empty placeholders (harness v0 is this
file only); they get populated in a later phase of the plan in
`Harness-first sistema distribuído poliglota — documento inicial.md`.
