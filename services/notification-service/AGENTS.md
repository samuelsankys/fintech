# AGENTS.md — notification-service

## Responsibility

Notification templates, simulated delivery channels, retry and
dead-letter-queue handling. Idempotent consumer of saga outcome events
(the harness baseline consumer — see root `AGENTS.md`).

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
- `src/main.ts` — bootstrap, listens on `process.env.PORT ?? 3002`
- `src/app.module.ts` — root module
- `src/app.controller.ts` — root controller, includes `GET /health`
- `src/app.service.ts` — root service
- `test/` — e2e tests

## Events produced / consumed

(none yet — scaffold only; will consume `transfer.completed` and
`transfer.failed` per the planned saga)

## What not to touch

(none yet)
