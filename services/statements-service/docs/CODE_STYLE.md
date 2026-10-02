# Code style — statements-service

## Language & formatting

- Node.js 22 LTS, NestJS 10.x, npm. Same conventions as `bff-gateway`:
  ESLint via `npm run lint`, strict TypeScript, DTOs over `any`.

## Naming & structure

- Separate the **ingestion side** (`src/events/`, one handler per
  consumed topic, each idempotent and side-effect-scoped to updating the
  projection) from the **query side** (`src/statements/`, read-only
  endpoints for `bff-gateway`) — don't let query logic reach into event
  handlers or vice versa.
- Projection update functions should be structured as
  `(currentState, event) -> newState` where practical, mirroring the
  event-sourcing read-model pattern, so replay and incremental
  consumption share the same logic path.

## NestJS conventions

- Kafka consumer setup lives in its own module (`EventsModule` or
  similar), injected with the projection repository — don't scatter
  Kafka client wiring across feature modules.
- Query endpoints use validation pipes on inputs (date ranges, pagination,
  export format) same as any other service's public-facing contract.

## Commits

- A change to the projection schema (new field derived from an event)
  should note whether a full replay is required to backfill it.
