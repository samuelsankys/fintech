# Design

## Context

Greenfield repo, no code yet. This design covers the first concrete thing
being built: a monorepo skeleton across three stacks (Java/Spring Boot,
Go, Node/NestJS) that builds and starts locally via docker compose, with
no business logic. See `proposal.md` for the why/what; this covers the how
and the concrete choices needed because nothing in the repo constrains them
yet.

## Goals / Non-Goals

**Goals:**
- Every service folder is runnable (`build` succeeds, container starts,
  exposes a health endpoint) with no business logic inside.
- The three stacks each get one consistent internal layout, so later
  per-service work (and the harness) can rely on "all Java services look
  alike," "all Go services look alike," etc.
- `docker compose up` brings up all infra (Kafka, PostgreSQL, Redis,
  MongoDB) and all 8 services in one shot.
- Root `AGENTS.md` and per-service `AGENTS.md` placeholders exist, matching
  the structure already described in the root `CLAUDE.md`.

**Non-Goals:**
- No event schemas, no OpenAPI contracts beyond an empty folder — those are
  later phases (core money / entry-and-read phases in the plan).
- No harness guardrails/sensors scripts (phase 4 in the plan) — this change
  only creates the `harness/{skills,guardrails,sensors}` folders.
- No CI pipeline.
- No `cards-service` / `reconciliation-service` (phase 2 services).
- No real persistence logic — services connect to their datastore only
  enough to prove connectivity at startup, if at all.

## Decisions

**Build tool per stack**
- Java services (`ledger`, `accounts`, `identity`): Maven, compiled at
  `--release 17` (LTS), Spring Boot 4.1.x, Spring Web + Actuator starters
  only. Maven over Gradle: single declarative `pom.xml` is easier for an
  agent to read/diff than a Gradle Kotlin DSL build script, and the project
  values agent legibility over build-tool power. Each service ships the
  **Maven Wrapper** (`mvnw`/`mvnw.cmd` + `.mvn/wrapper/`) checked in, so
  building needs only a JDK (17+) on PATH, not a separately installed
  Maven — the dev machine used for this change has JDK 19 but no system
  Maven, and the wrapper avoids an environment-modifying global install.
  JDK 17 (not 21) is the compile target because that's the oldest LTS the
  available JDK (19) can target with `--release`; bump to 21 later is a
  one-line `pom.xml` change whenever a JDK 21 is available. Actual
  generated projects landed on **Spring Boot 4.1.1**, not 3.3.x as first
  assumed: start.spring.io now only serves Boot ≥4.0 and rejected the
  3.3.x compatibility range outright. Boot 4 still supports Java 17, but
  the Web starter is renamed `spring-boot-starter-webmvc` (was
  `spring-boot-starter-web` in Boot 3.x) — worth remembering once real
  business logic starts referencing Boot-version-specific APIs or docs.
- Go services (`payments`, `fraud`): Go 1.22 (matches the installed
  toolchain; was 1.23 in the initial decision, lowered so `go build` does
  not need to fetch a newer toolchain), plain Go modules (`go.mod` per
  service), standard library `net/http` for the health endpoint — no
  framework yet, since there's no business logic to justify one.
- Node services (`bff-gateway`, `statements`, `notification`): Node 22
  (LTS), NestJS 10.x scaffolded via `@nestjs/cli`, npm (not pnpm/yarn) to
  keep tooling uniform and avoid a workspace-wide package manager decision
  this change doesn't need to make.

**Health endpoint convention**
- Every service exposes `GET /health` returning HTTP 200 with a small JSON
  body (`{"status":"ok","service":"<name>"}`). Same shape across all three
  stacks so a future harness sensor can check "does the service start and
  answer health" generically, without per-stack logic.

**Port allocation (local dev, host-mapped)**

| Service | Port |
|---|---|
| ledger-service | 8081 |
| accounts-service | 8082 |
| identity-service | 8083 |
| payments-service | 8090 |
| fraud-service | 8091 |
| bff-gateway | 3000 |
| statements-service | 3001 |
| notification-service | 3002 |
| Kafka | 9092 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| MongoDB | 27017 |

Host-mapped Redis port was moved to `16379` after hitting a real port
conflict with an unrelated local project's Redis container already bound
to `6379` on this dev machine. This only affects host access (e.g.
`redis-cli` from Windows); inside the `fintech` docker network, services
still reach it at `redis:6379`.

**Infra shape in docker compose**
- Kafka runs in KRaft mode (no separate Zookeeper container) — fewer
  moving parts for local dev.
- One PostgreSQL container with one database per Java/Go service that
  needs it (`ledger`, `accounts`, `identity`, `payments`, `statements`),
  created via an init script, rather than 5 separate Postgres containers —
  keeps local resource usage reasonable; this is a local-dev simplification
  only, not a statement about production topology.
- One Redis container shared by `fraud-service` and `bff-gateway`, each
  using a distinct logical DB index (0 and 1) to avoid key collisions.
- One MongoDB container for `notification-service`.

**Dockerfile shape**
- Each service gets a multi-stage `Dockerfile` (build stage with the
  stack's SDK/toolchain, slim runtime stage) so images stay small and the
  pattern is copy-pasteable across services of the same stack.

**AGENTS.md placeholder**
- Every service's `AGENTS.md` follows one template (mirrors the
  `services/*/AGENTS.md` row in the root `CLAUDE.md`): responsibility,
  stack + versions, build/test/lint commands, package layout, "events
  produced/consumed" (empty for now), "what not to touch" (empty for now).
  Keeping the template identical across services is deliberate — the
  harness experiment wants result differences to come from content added
  later, not from format differences introduced now.

**Root Makefile**
- Targets: `up` / `down` (docker compose), `build` (fan out to each
  service's native build command), `test` (fan out similarly). No
  per-service logic beyond directory traversal — each service's own build
  tool is the source of truth for how it builds.

**No cross-service import rule**
- Documented in the root `AGENTS.md` (as already stated in `CLAUDE.md`)
  but not enforced by a script in this change — the enforcement sensor is
  explicitly phase-4 scope (harness/sensors).

## Risks / Trade-offs

- **Three build toolchains to keep working locally** (Maven/JDK, Go, Node)
  → Mitigation: docker compose is the primary way to run everything, so a
  contributor only needs Docker; native toolchains are only required for
  per-service dev loops.
- **Shared Postgres/Redis containers could let a bug cross a service
  boundary that should be invisible** (e.g., one service reading another's
  database) → Mitigation: separate databases/DB-indices per service now,
  and treat "service only touches its own schema" as a guardrail candidate
  for the harness phase.
- **Windows dev environment (CRLF line endings) could break shell scripts
  invoked from Linux containers** → Mitigation: add a `.gitattributes`
  forcing LF for `*.sh` and `Makefile`.
- **Scaffolds may drift from what a later "service template" skill
  produces**, since phase 1 doesn't yet define `harness/skills/` content →
  Mitigation: this is accepted for now; the plan already treats templates
  as a later deliverable, and keeping phase 1 scaffolds simple makes them
  cheap to regenerate if the template changes shape.

## Open Questions

- Avro/Schema Registry vs. JSON Schema for `contracts/events/` — explicitly
  left open in the planning doc; doesn't affect this change since no
  schemas are created here.
- Whether to add a Kafka UI / Redis Commander container for local
  debugging — convenience-only, deferred to whoever first needs it.
