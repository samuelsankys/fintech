# Security — statements-service

## Threat surface

Public-facing indirectly via `bff-gateway`; inbound Kafka events from
`ledger-service` and `payments-service` are the other input surface —
validate event schema/shape before applying to the projection, don't
assume well-formed internal producers forever.

## Authorization

Statement search/export must be scoped to the authenticated customer's
own accounts — this service must not trust that `bff-gateway` already
filtered correctly; re-check that the requested account belongs to the
caller before returning any statement data. A statement is a complete
transaction history — one of the more sensitive reads in the system.

## Data sensitivity

Statement data includes amounts, counterparties, and timestamps —
financial history, not raw PII, but still sensitive. Avoid logging full
statement payloads; log query parameters (account id, date range) and
result counts, not line items, by default.

## Export handling

If/when export (CSV/PDF/etc.) is implemented, treat the generated file as
sensitive output: don't log its contents, ensure it's only ever returned
to the authorized requester, and avoid writing it to any shared/temp
location accessible beyond this service's process.

## Secrets & config

DB and Kafka credentials via environment/config, not committed.
