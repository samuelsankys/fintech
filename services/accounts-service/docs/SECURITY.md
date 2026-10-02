# Security — accounts-service

## Threat surface

Public-facing indirectly: `bff-gateway` forwards authenticated requests
here, but this service should not trust that auth was already done
somewhere upstream without verification — if it ever gets a service-to-
service auth mechanism (mTLS, internal JWT), validate it here too, don't
rely solely on network topology.

## Data sensitivity

Account/limit data is financial but not raw PII (that's
`identity-service`'s domain). Still avoid logging full balance/limit
payloads at `INFO`; log account ids and operation outcomes, not amounts,
by default.

## Authorization

Balance/limit reads must be scoped to the authenticated customer —
`accounts-service` must enforce that a request for account X's balance is
only served to a caller authorized for account X, even though
`bff-gateway` is the JWT-validation edge. Don't assume the gateway already
filtered this; defense in depth for a core financial read.

## Projection integrity

Since the balance projection is rebuilt from `ledger.entries-posted`, a
forged or replayed event from an untrusted source could corrupt it.
Validate event origin/schema (via the Kafka topic ACLs and the event
schema in `contracts/events/`), don't accept arbitrary unvalidated
payloads into the projection update path.

## Secrets & config

DB and Kafka credentials via environment/config, not committed into
`application.properties`.
