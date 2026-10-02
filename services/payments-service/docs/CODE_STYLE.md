# Code style — payments-service

## Language & formatting

- Go 1.22, standard library only today (`net/http`) — no framework added
  yet since there's no business logic in the scaffold. When the saga
  lands, prefer staying on the standard library (`net/http`,
  `encoding/json`) unless a concrete need (routing complexity, middleware
  chaining) justifies a dependency.
- `gofmt`/`goimports` is the formatter — non-negotiable in Go, run it
  before every commit. `go vet ./...` must pass.

## Naming

- Package names are short, lowercase, no underscores (`saga`, `store`,
  not `saga_state`).
- Exported types/functions get doc comments starting with the identifier
  name (standard Go convention) once the API surface is non-trivial.
- Saga state constants (e.g. `StatusRequested`, `StatusFraudApproved`,
  `StatusCompleted`, `StatusFailed`) should be an explicit enum-like type,
  not raw strings scattered across the codebase.

## Error handling

- Go idiom: return errors, don't panic, except for truly unrecoverable
  startup failures (e.g. can't bind the HTTP port). Wrap errors with
  context (`fmt.Errorf("posting ledger entries: %w", err)`) so saga
  failures are traceable without a debugger.
- Saga-step failures are business outcomes (-> `transfer.failed`), not Go
  errors to propagate as 500s once the saga has started — distinguish
  "infrastructure failure, retry" from "business rejection, compensate."

## Commits

- Changes to the saga state machine should reference which step/topic
  from the table in `contracts/events/` they affect, since this service
  is the integration point for the whole transfer flow.
