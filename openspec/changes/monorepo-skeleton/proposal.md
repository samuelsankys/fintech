# Proposal

## Why

The repo currently has no code — only the planning document and the
OpenSpec/Claude Code setup. Every later phase (ledger invariants, saga,
harness guardrails/sensors) needs a monorepo to land in: folder layout,
per-service scaffolds that build and start, local infra via docker compose,
and the contracts/ boundary. Phase 1 of the plan ("Esqueleto do monorepo")
calls for exactly this, with harness v0 limited to a root `AGENTS.md`.

## What Changes

- Create the monorepo folder structure: `services/`, `contracts/{events,openapi}`,
  `platform/`, `harness/{skills,guardrails,sensors}`.
- Scaffold all 8 MVP services as empty-but-runnable projects (no business
  logic), one per stack:
  - Java/Spring Boot: `ledger-service`, `accounts-service`, `identity-service`
  - Go: `payments-service`, `fraud-service`
  - Node/NestJS: `bff-gateway`, `statements-service`, `notification-service`
  - Each service gets its own `AGENTS.md` placeholder (responsibility,
    stack, build/test/lint commands) and a `Dockerfile`.
- Add `platform/docker-compose.yml` wiring Kafka, PostgreSQL, Redis, and
  MongoDB for local development.
- Add a root `platform/Makefile` with common targets (`up`, `down`, `build`,
  `test`) that fan out to per-service build tools.
- Add a root `AGENTS.md` (harness v0): system purpose, service/stack map,
  global commands, and the no-cross-service-import rule.
- Add a placeholder `contracts/events/` and `contracts/openapi/` layout
  (empty or with a single example file) so later phases have a home for
  schemas.
- **Not included**: no business logic, no real event schemas, no ledger
  invariants, no harness guardrails/sensors scripts, no CI wiring, no
  `cards-service`/`reconciliation-service` (phase 2).

## Capabilities

### New Capabilities

(none — this change is pure scaffolding/tooling: folder structure, build
configuration, and empty service skeletons. No application-observable
behavior is introduced, so no spec deltas apply. `skip_specs: true` is set
in `.openspec.yaml`.)

### Modified Capabilities

(none)

## Impact

- Affected paths: repo root (new `services/`, `contracts/`, `platform/`,
  `harness/`, `AGENTS.md`).
- New local dependencies to run the stack: Docker/Docker Compose, JDK +
  Maven or Gradle (Java services), Go toolchain (Go services), Node.js +
  npm (Node services).
- No existing code is touched (none exists yet).
- Establishes the "no cross-service imports" convention that later harness
  sensors will enforce — not enforced by automation in this change.
