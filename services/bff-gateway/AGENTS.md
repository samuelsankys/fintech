# AGENTS.md — bff-gateway

## Responsibility

Single API entry point for the system: JWT auth, request composition
across backend services, rate limiting. Synchronous calls to other
services happen only at this edge (see root `AGENTS.md`).

## Stack & version

- Node.js 22 (LTS)
- NestJS 10.x
- Package manager: npm

## Build / test / lint commands

```bash
npm install      # install dependencies
npm run build    # compile TypeScript -> dist/
npm test         # unit tests (Jest)
npm run lint     # ESLint
```

## Package layout

Standard Nest CLI layout:
- `src/main.ts` — bootstrap, listens on `process.env.PORT ?? 3000`
- `src/app.module.ts` — root module
- `src/app.controller.ts` — root controller, includes `GET /health`
- `src/app.service.ts` — root service
- `test/` — e2e tests

## Events produced / consumed

(none yet — this is a scaffold; bff-gateway is synchronous-only per the
architecture, so it is not expected to produce/consume Kafka events)

## What not to touch

(none yet)
