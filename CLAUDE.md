# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

This repo currently has no implemented code. It holds the planning document
`Harness-first sistema distribuído poliglota — documento inicial.md` (pt-BR)
and an OpenSpec setup (`openspec/`). Everything architectural below describes
the **planned** system, not yet-built code — treat it as the target shape to
build toward, and update this file once real services, build tooling, and
tests exist.

## Project purpose

This is not a product — it's a testbed for evaluating an AI-agent harness.
The services exist to give an agent something with real invariants to
violate, so the central question can be measured: *can an agent change one
service without breaking contracts, invariants, or conventions of its
neighbors, using only the context the harness provides?*

Chosen domain: a digital bank with instant (Pix-style) transfers — strong,
verifiable invariants (ledger balance, idempotency, event ordering) and a
natural fit for a polyglot stack.

## Spec-driven workflow (OpenSpec)

This repo uses OpenSpec (`openspec/`, schema `spec-driven`) to manage specs
and changes before code is written. Claude Code integration lives in
`.claude/commands/opsx/` and `.claude/skills/openspec-*`.

- `/opsx:propose "idea"` — start a new change proposal
- `/opsx:explore` — explore/research before proposing
- `/opsx:update` — update an in-progress change
- `/opsx:apply` — apply an approved change (write the code)
- `/opsx:sync` — sync specs after changes land
- `/opsx:archive` — archive a completed change

Specs live in `openspec/specs/`; in-flight change proposals in
`openspec/changes/`; completed ones move to `openspec/changes/archive/`.
Prefer routing non-trivial work (new service, new saga step, new event)
through an OpenSpec change rather than editing code ad hoc.

## Planned monorepo structure

```
fintech/
├── AGENTS.md                  # root harness context (not yet created)
├── harness/                   # skills, guardrails, sensors (not yet created)
├── contracts/
│   ├── events/                # Kafka event schemas
│   └── openapi/               # synchronous API contracts
├── platform/
│   ├── docker-compose.yml     # Kafka, PostgreSQL, Redis, MongoDB
│   └── Makefile
└── services/
    ├── ledger-service/        # each service folder: own build, tests, Dockerfile, AGENTS.md
    ├── payments-service/
    ├── accounts-service/
    ├── identity-service/
    ├── fraud-service/
    ├── bff-gateway/
    ├── statements-service/
    └── notification-service/
```

**Hard rule to enforce once services exist:** a service never imports code
from another service — only shared contracts from `contracts/`. This
simulates a multirepo inside a monorepo; a CI sensor is meant to fail the
build on violation.

## Planned services

Minimal core (5 services, 3 stacks) if scoping down from the full 8:
`bff-gateway`, `accounts-service`, `ledger-service`, `payments-service`,
`notification-service`.

| Service | Stack | Responsibility | Data | Key invariant |
|---|---|---|---|---|
| ledger-service | Java Spring Boot | Double-entry ledger, immutable, source of truth for balance | PostgreSQL | Append-only; debits = credits, never update |
| payments-service | Go | Orchestrates transfer saga: idempotency, states, compensation | PostgreSQL + outbox | Cross-service ordering, retry |
| accounts-service | Java Spring Boot | Accounts, limits, balance as projection (CQRS) | PostgreSQL | Write/read separation |
| fraud-service | Go | Consumes events, sliding-window score, approve/block | Redis | Streaming state + latency |
| identity-service | Java Spring Boot | Customers, simulated KYC, tokens, transfer keys | PostgreSQL | PII must not leak into logs |
| bff-gateway | Node.js (NestJS) | Single API entry point: JWT, composition, rate limiting | Redis | OpenAPI contract consumed by multiple services |
| statements-service | Node.js | Statement as a read-model of events, search/export | PostgreSQL | Event projection/replay |
| notification-service | Node.js | Templates, simulated channels, retry + DLQ | MongoDB | Idempotent consumer (harness baseline) |
| *cards-service* (phase 2) | Java Spring Boot | Card authorization with balance hold | PostgreSQL | New saga reusing ledger + accounts |
| *reconciliation-service* (phase 2) | Go | Batch reconciliation of ledger vs. external statement | PostgreSQL | Batch jobs + divergence detection |

Stack split follows the role: Java where business rules are dense (ledger,
accounts, identity), Go where it's orchestration/throughput (payments,
fraud), Node where it's composition/I/O (bff, statements, notification).

## Planned architecture

- Synchronous calls only at the edge (BFF → services). Between services,
  everything is an event on Kafka.
- Any service that owns a database publishes via the **outbox pattern** —
  never a direct dual-write.
- Services (except `bff-gateway`) are named `*-service`.

### Transfer saga (event flow)

| Topic | Producer | Consumers | Role |
|---|---|---|---|
| `transfer.requested` | payments | fraud | Saga start |
| `fraud.assessed` | fraud | payments | Approve/block |
| `ledger.post-requested` | payments | ledger | Command to post debit+credit |
| `ledger.entries-posted` | ledger | payments, accounts, statements | Entries recorded |
| `ledger.post-rejected` | ledger | payments | Invariant violated → triggers compensation |
| `transfer.completed` | payments | notification, statements | Happy path end |
| `transfer.failed` | payments | notification, statements | Compensated end |
| `customer.registered` | identity | accounts | Opens customer's account |

Saga is orchestrator-style (payments-service is the orchestrator), not
choreography.

**Event conventions:** partition key = account id (per-account ordering);
every message carries `eventId` and `correlationId`; consumers must be
idempotent on `eventId`; schemas are versioned in `contracts/events/`.

## Harness design (for when `harness/` is built)

Four context layers + a sensor layer that checks agent output:

- `AGENTS.md` (root) — system purpose, service/stack map, global commands,
  the no-cross-service-imports rule, links to skills.
- `services/*/AGENTS.md` — responsibility, stack/version, build/test/lint
  commands, package layout, local invariants, events produced/consumed,
  what not to touch.
- `harness/skills/` — repeatable procedures (change an event schema, add a
  saga step, add an endpoint, scaffold a service from template).
- `harness/guardrails/` — rules written to be machine-verifiable, each tied
  to a sensor.
- `harness/sensors/` — scripts the agent runs itself and reads the result of.
- `contracts/` — source of truth for events/APIs; code follows the
  contract, never the reverse.

Guardrail → sensor pairs to implement:

| Guardrail | Sensor |
|---|---|
| Ledger is append-only, debits = credits | Property-based tests in ledger-service |
| Published events change only compatibly | Schema compatibility check in `contracts/events/` |
| No service imports another service's code | Dependency/import scan script |
| No PII in logs | Log lint + test in identity-service |
| Consumers are idempotent | Test that redelivers the same `eventId` twice |
| Synchronous API follows contract | bff-gateway contract test against services |

## Build/test/lint commands

Not yet defined — no code exists. Once `platform/Makefile` and per-service
build tooling exist, document the actual commands here (and in each
`services/*/AGENTS.md`), e.g. `docker compose up`, per-stack build/test/lint,
and how to run a single test per language.
