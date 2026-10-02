# Code style — bff-gateway

## Language & formatting

- Node.js 22 LTS, NestJS 10.x, npm. ESLint via `npm run lint` — use it,
  don't hand-wave formatting; fix lint errors rather than disabling
  rules inline unless there's a documented reason.
- TypeScript strict mode conventions: avoid `any`; model request/response
  shapes as explicit DTOs/interfaces, ideally generated or kept in sync
  with `contracts/openapi/` rather than hand-duplicated and left to
  drift.

## Naming & structure

- One Nest module per composed capability (`auth`, `transfers`,
  `accounts`, `statements`), each owning its controller, service, and
  DTOs — don't let `app.controller.ts` grow into a dumping ground for
  every route as real endpoints land.
- Downstream HTTP clients (to `identity-service`, `accounts-service`,
  etc.) live in their own injectable service per target service
  (`IdentityClient`, `AccountsClient`, ...), not inlined into feature
  services — keeps composition logic separate from HTTP plumbing.

## NestJS conventions

- Use Nest's built-in validation pipes (`class-validator` /
  `class-transformer`) on every inbound DTO — this is the system's public
  edge, input validation belongs here first.
- Guards for JWT auth and rate limiting are global or per-module, not
  copy-pasted per controller method.

## Commits

- A change to a composed endpoint's shape must update
  `contracts/openapi/` in the same change, not after.
