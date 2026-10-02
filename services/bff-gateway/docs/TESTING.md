# Testing — bff-gateway

## Levels

1. **Unit** — Jest, per-service logic: request/response mapping,
   composition logic (e.g. combining an accounts read with a statements
   read for one endpoint), validation DTOs.
2. **E2E** (`test/*.e2e-spec.ts`, already scaffolded) — boot the Nest app
   and hit real HTTP routes, with downstream service calls mocked/stubbed
   at the HTTP boundary (e.g. nock, MSW, or a test double server) rather
   than importing another service's code.
3. **Contract** — this is the required guardrail sensor for this
   service per root `CLAUDE.md` ("Synchronous API follows contract"):
   validate both inbound request shapes and outbound calls to each
   downstream service against `contracts/openapi/`. A contract test
   failure here should block merges once CI exists.
4. **Auth/rate-limit** — explicit tests for JWT rejection (missing/
   expired/invalid token) and rate-limit enforcement (burst beyond
   threshold gets throttled), since this is the only service enforcing
   either.

## Running

```bash
npm install
npm test          # unit
npm run lint
```

E2E config already present at `test/jest-e2e.json` — run via the Nest
CLI's e2e script once defined in `package.json`.

## Current state

`app.controller.spec.ts` and `test/app.e2e-spec.ts` cover only the
scaffold's `GET /health`. Extend per feature module as real composition
endpoints land.
