# Tasks

## 1. Root structure

- [x] 1.1 Create top-level folders `services/`, `contracts/events/`, `contracts/openapi/`, `platform/`, `harness/skills/`, `harness/guardrails/`, `harness/sensors/` (with `.gitkeep` where empty) and verify `git status` shows them as new, trackable paths.
- [x] 1.2 Add `.gitattributes` forcing LF line endings for `*.sh` and `Makefile` and verify a freshly checked-out shell script has LF endings (`file <script>` or `git show HEAD:<path> | xxd | grep -c $'\r'` reports 0 after commit).
- [x] 1.3 Write root `AGENTS.md` (system purpose, service/stack map, global commands, no-cross-service-import rule, links to `harness/skills/`) per the structure in root `CLAUDE.md`, and verify it renders as valid Markdown with no broken relative links to folders created in 1.1.

## 2. Platform / local infra

- [x] 2.1 Write `platform/docker-compose.yml` with Kafka (KRaft mode, port 9092), PostgreSQL (port 5432, one DB per `ledger`/`accounts`/`identity`/`payments`/`statements` via an init script), Redis (port 6379), and MongoDB (port 27017), and verify `docker compose -f platform/docker-compose.yml up -d` starts all four containers healthy, then `docker compose -f platform/docker-compose.yml down` cleans up.
- [x] 2.2 Write the Postgres init script creating the five databases and verify `psql` (or `docker compose exec postgres psql -U postgres -c '\l'`) lists all five after `up`.
- [x] 2.3 Write root `platform/Makefile` with `up`, `down`, `build`, `test` targets (fanning out to each service directory) and verify `make -f platform/Makefile up` and `make -f platform/Makefile down` succeed against the compose file from 2.1.

## 3. Java services (ledger, accounts, identity)

- [x] 3.1 Scaffold `services/ledger-service` as a Maven/Spring Boot 3.3.x, Java 21 project with Web + Actuator starters, a `GET /health` endpoint returning `{"status":"ok","service":"ledger-service"}`, and a `Dockerfile` (multi-stage: Maven build, slim JRE runtime); verify `mvn -f services/ledger-service/pom.xml test` passes and `docker build -t ledger-service services/ledger-service` succeeds.
- [x] 3.2 Repeat 3.1 for `services/accounts-service` (service name `accounts-service`) and verify the same two checks.
- [x] 3.3 Repeat 3.1 for `services/identity-service` (service name `identity-service`) and verify the same two checks.
- [x] 3.4 Add `AGENTS.md` to each of the three services using the shared template from design.md (responsibility, stack/version, build/test/lint commands, package layout, empty "events" and "what not to touch" sections) and verify each file is present and non-empty.

## 4. Go services (payments, fraud)

- [x] 4.1 Scaffold `services/payments-service` as a Go 1.23 module (`go.mod`) with a `net/http` server exposing `GET /health` returning `{"status":"ok","service":"payments-service"}`, and a multi-stage `Dockerfile`; verify `go build ./...` and `go vet ./...` succeed from `services/payments-service`, and `docker build -t payments-service services/payments-service` succeeds.
- [x] 4.2 Repeat 4.1 for `services/fraud-service` (service name `fraud-service`) and verify the same checks.
- [x] 4.3 Add `AGENTS.md` to each of the two services using the shared template and verify each file is present and non-empty.

## 5. Node services (bff-gateway, statements, notification)

- [x] 5.1 Scaffold `services/bff-gateway` as a NestJS 10.x project (Node 22, npm) with a `GET /health` endpoint returning `{"status":"ok","service":"bff-gateway"}`, and a multi-stage `Dockerfile`; verify `npm install && npm run build` and `npm test` succeed from `services/bff-gateway`, and `docker build -t bff-gateway services/bff-gateway` succeeds.
- [x] 5.2 Repeat 5.1 for `services/statements-service` (service name `statements-service`) and verify the same checks.
- [x] 5.3 Repeat 5.1 for `services/notification-service` (service name `notification-service`) and verify the same checks.
- [x] 5.4 Add `AGENTS.md` to each of the three services using the shared template and verify each file is present and non-empty.

## 6. Integration check

- [x] 6.1 Add each service to `platform/docker-compose.yml` (depending on its infra: Postgres DB, Redis, Mongo, or none) with its port from design.md's allocation table, and verify `docker compose -f platform/docker-compose.yml up -d --build` starts all 8 services plus infra.
- [x] 6.2 Verify every service's `GET /health` responds 200 with the expected `{"status":"ok","service":"<name>"}` body when queried on its mapped host port (e.g. via `curl`), then tear down with `docker compose -f platform/docker-compose.yml down`.
