# AGENTS.md — accounts-service

## Responsibility

Accounts, limits, and balance as a read projection (CQRS).

## Stack & version

- Java 17, Spring Boot 4.1.1 (Web + Actuator starters)
- Build tool: Maven, via the checked-in wrapper (`./mvnw`) — no system
  Maven install required, only a JDK 17+ on PATH.

## Build / test / lint

```bash
./mvnw test              # run tests
./mvnw package            # build the jar (target/*.jar)
./mvnw spring-boot:run     # run locally on port 8082
```

No linter configured yet.

## Package layout

```
src/main/java/com/fintech/accountsservice/
  AccountsServiceApplication.java   # Spring Boot entry point
  HealthController.java             # GET /health
src/main/resources/application.properties
src/test/java/com/fintech/accountsservice/AccountsServiceApplicationTests.java
```

## Events produced / consumed

(none yet — placeholder, no business logic implemented)

## What not to touch

(none yet — placeholder)
