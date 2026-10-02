# Security — fraud-service

## Threat surface

No public ingress; only input is `transfer.requested` from
`payments-service` over Kafka. Still validate the event schema and
reasonableness of fields (amount, account id) before scoring — don't
trust it blindly just because it comes from an internal topic.

## Data sensitivity

Window state in Redis is keyed by account/customer id and reflects
recent transfer activity — behavioral/financial data, not raw PII. Don't
log full event payloads routinely; log decisions (approve/block + score)
and correlation ids.

## Gaming the score

Since this service's decision gates the saga, treat the scoring logic
itself as sensitive: don't expose scoring thresholds or algorithm details
through any public-facing surface (this service has none today, but keep
it that way — no debug endpoint that reveals internal thresholds).

## Fail-safe direction

Decide explicitly (and document in code) what happens if Redis is
unreachable when a score is needed: fail closed (block/require manual
review) vs. fail open (approve) is a real product/security trade-off, not
a default to leave implicit.

## Secrets & config

Redis connection info via environment/config, not hardcoded.
