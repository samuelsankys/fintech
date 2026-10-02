# Architecture — notification-service

## Role

Notification templates, simulated delivery channels, retry and
dead-letter-queue handling. This is the harness's **baseline idempotent
consumer** — the simplest service, deliberately kept simple so the
idempotent-consumer guardrail can be exercised cleanly without saga
complexity.

## Position in the system

- Synchronous: none today (no reads from `bff-gateway` in the current
  design).
- Asynchronous: consumes `transfer.completed` and `transfer.failed`,
  triggers a simulated notification send per template, retries on
  failure, routes to a dead-letter queue after exhausting retries.

```
payments-service --(transfer.completed | transfer.failed)--> notification-service
```

## Data ownership

- MongoDB, owned by this service: notification templates, delivery
  attempt/outcome records, DLQ entries. No other service reads this
  store.

## Layering (NestJS)

```
src/main.ts          -> bootstrap, listens on process.env.PORT
src/app.module.ts     -> root module
src/notifications/     -> consumer handler, template rendering, channel dispatch
src/retry/             -> retry policy + DLQ routing
```

Current scaffold has only the Nest CLI default `app.*` files and
`GET /health` — the module layout above is the target shape.

## Dependencies

Only `contracts/events/`. No import of `payments-service` code — this
service reacts purely to published saga-outcome events.

## Invariant enforced here

Idempotent consumption of `transfer.completed`/`transfer.failed`: the
same event delivered twice must never send a duplicate notification.
Retries exhausted must land in a DLQ, never silently drop the
notification.
