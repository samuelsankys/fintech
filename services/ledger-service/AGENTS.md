# AGENTS.md — ledger-service

## Responsibility

Double-entry ledger, append-only, source of truth for account balance.

## Stack & version

- Java 17, Spring Boot 4.1.1 (Web + Actuator starters)
- Build tool: Maven, via the checked-in wrapper (`./mvnw`) — no system
  Maven install required, only a JDK 17+ on PATH.

## Build / test / lint

```bash
./mvnw test              # run tests
./mvnw package            # build the jar (target/*.jar)
./mvnw spring-boot:run     # run locally on port 8081
```

No linter configured yet.

## Package layout

```
src/main/java/com/fintech/ledgerservice/
  LedgerServiceApplication.java   # Spring Boot entry point
  HealthController.java           # GET /health
src/main/resources/application.properties
src/test/java/com/fintech/ledgerservice/LedgerServiceApplicationTests.java
```

## Events produced / consumed

(none yet — placeholder, no business logic implemented)

## What not to touch

(none yet — placeholder)
