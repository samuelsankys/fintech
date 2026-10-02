COMPOSE_FILE := platform/docker-compose.yml
SERVICES := ledger-service accounts-service identity-service payments-service fraud-service bff-gateway statements-service notification-service

.PHONY: up down build test

up:
	docker compose -f $(COMPOSE_FILE) up -d --build

down:
	docker compose -f $(COMPOSE_FILE) down

build:
	@for svc in $(SERVICES); do \
		echo "== build $$svc =="; \
		$(MAKE) -s -f $(firstword $(MAKEFILE_LIST)) build-one SVC=$$svc || exit 1; \
	done

build-one:
	@if [ -f services/$(SVC)/mvnw ]; then \
		(cd services/$(SVC) && ./mvnw -q package -DskipTests); \
	elif [ -f services/$(SVC)/go.mod ]; then \
		(cd services/$(SVC) && go build ./...); \
	elif [ -f services/$(SVC)/package.json ]; then \
		(cd services/$(SVC) && npm install && npm run build); \
	else \
		echo "no known build tool for $(SVC)"; exit 1; \
	fi

test:
	@for svc in $(SERVICES); do \
		echo "== test $$svc =="; \
		$(MAKE) -s -f $(firstword $(MAKEFILE_LIST)) test-one SVC=$$svc || exit 1; \
	done

test-one:
	@if [ -f services/$(SVC)/mvnw ]; then \
		(cd services/$(SVC) && ./mvnw -q test); \
	elif [ -f services/$(SVC)/go.mod ]; then \
		(cd services/$(SVC) && go test ./...); \
	elif [ -f services/$(SVC)/package.json ]; then \
		(cd services/$(SVC) && npm test); \
	else \
		echo "no known test tool for $(SVC)"; exit 1; \
	fi
