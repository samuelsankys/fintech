# Testing — notification-service

## Levels

1. **Unit** — Jest: template rendering, channel dispatch (mocked
   channel), retry/backoff policy logic.
2. **Idempotency (required guardrail)** — this service is the system's
   baseline idempotent-consumer test case per root `CLAUDE.md`
   ("consumers are idempotent... test that redelivers the same `eventId`
   twice"). Write an explicit test: redeliver the same
   `transfer.completed`/`transfer.failed` `eventId` twice and assert
   exactly one notification was sent/recorded.
3. **Retry/DLQ** — simulate repeated channel failures and assert the
   event is retried per policy, then lands in the DLQ after exhausting
   retries — not dropped silently.
4. **Integration** — Testcontainers MongoDB (or local instance) for
   delivery-record/DLQ persistence.
5. **Contract** — consumed events validated against `contracts/events/`.

## Running

```bash
npm install
npm test
npm run lint
```

## Current state

`app.controller.spec.ts` / `test/app.e2e-spec.ts` cover only the
scaffold's `GET /health`. The idempotency test above should be the first
real test added once consumption logic exists, since this service is the
harness's reference idempotent-consumer sensor.
