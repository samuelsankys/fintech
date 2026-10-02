# Patterns — notification-service

## Idempotent consumer (reference implementation)

This service is the harness's baseline example of the idempotent-
consumer pattern: dedupe on `eventId` (e.g. a processed-events collection
in MongoDB with a unique index) before sending any notification. Every
other consumer in the system (`accounts-service`, `fraud-service`,
`statements-service`, `ledger-service`) should follow the same shape this
service establishes.

## Retry with backoff + dead-letter queue

Channel send failures are retried with backoff up to a bounded count,
then routed to a DLQ rather than dropped or retried forever. Model retry
state explicitly (attempt count, next-retry time) rather than relying on
Kafka consumer-group redelivery alone to implement backoff.

## Channel abstraction

Simulated delivery channels (email/SMS/push) sit behind a common
interface so the consumer/retry/DLQ logic is channel-agnostic — adding a
channel is an implementation of the interface, not a change to the
consumption pipeline.

## Terminal-event consumer only

This service only reacts to saga *outcomes* (`transfer.completed`,
`transfer.failed`), never intermediate saga state (`fraud.assessed`,
`ledger.entries-posted`) — keep it that way; it's meant to be the
simplest consumer in the system, not another saga participant.
