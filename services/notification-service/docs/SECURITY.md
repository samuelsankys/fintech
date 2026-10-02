# Security — notification-service

## Threat surface

No public ingress; input is `transfer.completed`/`transfer.failed` from
`payments-service` over Kafka. Validate event schema before rendering a
notification from it — a malformed or unexpected payload shouldn't crash
the consumer or produce a malformed message to a real/simulated channel.

## Data sensitivity

Notification payloads may include customer-facing details derived from
the transfer (amount, counterparty reference). Avoid logging full
rendered notification content at `INFO` — log event id, channel,
delivery outcome, and retry count, not the message body, by default.

## Template injection

If templates support variable interpolation, treat transfer-derived
fields as untrusted input into the template — sanitize/escape so a
crafted account alias or reference string can't break out of the
template format (e.g. HTML injection if a channel renders HTML).

## Retry/DLQ handling

DLQ entries may accumulate sensitive payloads over time — apply the same
logging/retention discipline to DLQ storage as to live data, don't treat
it as a lower-sensitivity bucket by default.

## Secrets & config

MongoDB connection info and any simulated-channel credentials via
environment/config, not committed.
