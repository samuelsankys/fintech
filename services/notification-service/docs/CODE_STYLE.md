# Code style — notification-service

## Language & formatting

- Node.js 22 LTS, NestJS 10.x, npm. Same conventions as the other Node
  services: ESLint via `npm run lint`, strict TypeScript, DTOs over
  `any`.

## Naming & structure

- Template rendering, channel dispatch (simulated email/SMS/push), and
  retry/DLQ policy are separate, independently testable units — don't
  collapse "render + send + retry" into one method.
- Channels implement a common interface (e.g. `NotificationChannel.send
  (payload): Promise<DeliveryResult>`) so adding a new simulated channel
  doesn't require touching consumer/retry logic.

## NestJS conventions

- Kafka consumer handler lives in its own provider, injected with the
  template service, channel dispatcher, and retry policy — keep it thin,
  delegate to those collaborators.
- Mongoose/Mongo client setup in its own module, not inlined into the
  notification handler.

## Commits

- A change to retry/backoff policy or DLQ routing should state the new
  retry count/backoff shape explicitly, since it directly affects
  delivery guarantees this service is responsible for.
