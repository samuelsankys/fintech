# Patterns — identity-service

## PII boundary / data minimization

This service is the single source of truth for PII and the only place
allowed to hold it. Every outbound payload (event or API response) is a
deliberately minimized view, not a serialization of the internal domain
model. Apply an explicit mapping layer (view/DTO) between domain entities
and anything that leaves the service — never rely on "the field just
isn't used downstream" as protection.

## Token issuance as its own concern

Auth/token logic is a distinct use case from customer/KYC management,
even though it lives in the same service — keep it in its own
application-layer package so it can be reasoned about (and eventually
extracted) independently.

## Event producer, not consumer, in the core saga

`identity-service` only produces `customer.registered` in the current
design; it doesn't consume saga events. Keep it that way unless a real
requirement needs identity to react to transfer/ledger state — adding
unnecessary inbound coupling here increases the PII service's blast
radius for no reason.

## Outbox pattern

Like the other Java services, `customer.registered` must be published via
the outbox pattern (DB write + outbox row in one transaction), not a
direct dual-write to Kafka.
