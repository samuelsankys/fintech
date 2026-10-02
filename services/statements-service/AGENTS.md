# AGENTS.md — statements-service

## Responsibility

Account statement as a read-model built from ledger/payment events; search
and export. Projects and replays events rather than owning source-of-truth
data (see root `AGENTS.md`).

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
- `src/main.ts` — bootstrap, listens on `process.env.PORT ?? 3001`
- `src/app.module.ts` — root module
- `src/app.controller.ts` — root controller, includes `GET /health`
- `src/app.service.ts` — root service
- `test/` — e2e tests

## Events produced / consumed

(none yet — scaffold only; will consume `ledger.entries-posted`,
`transfer.completed`, `transfer.failed` per the planned saga)

## What not to touch

(none yet)
