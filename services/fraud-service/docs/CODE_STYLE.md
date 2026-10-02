# Code style — fraud-service

## Language & formatting

- Go 1.22, standard library only today. Same convention as
  `payments-service`: `gofmt`/`goimports` before commit, `go vet ./...`
  must pass, prefer standard library over a framework unless scoring
  logic genuinely needs something like a Redis client library (which is
  an accepted addition — Redis isn't in the standard library).

## Naming

- Package `score` (or similar) holds the sliding-window algorithm as pure
  functions/types wherever possible — input: recent event timestamps/
  amounts, output: a score — so it's testable without Redis.
- Avoid embedding scoring thresholds as magic numbers in handler code;
  name them as constants or config values close to the scoring package.

## Error handling

- Redis unavailability is an infrastructure failure, not a business
  rejection — don't conflate "Redis is down" with "this transfer looks
  fraudulent." Surface it distinctly (e.g. a specific error type) so
  `payments-service`-facing behavior (retry vs. block) can differ.

## Commits

- Changes to the scoring algorithm or window size should note the
  expected impact on latency and false-positive/negative rate, since this
  is the one service in the system explicitly chosen to exercise
  "streaming state + latency" per root `CLAUDE.md`.
