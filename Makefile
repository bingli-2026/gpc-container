.DEFAULT_GOAL := verify

.PHONY: format-check lint test-unit test-integration test-contract test-e2e architecture-check verify

# These targets deliberately discover their inputs at runtime.  The repository is
# bootstrapped in phases, so a target skips only when its source tree, test suite,
# or required executable has not been provisioned yet.  Once present, failures are
# propagated to make.
format-check:
	@set -eu; \
	if [ -f go.mod ]; then \
		if ! command -v go >/dev/null 2>&1; then echo "SKIP format-check (Go): go is not installed"; \
		elif unformatted="$$(gofmt -l $$(find . -type f -name '*.go' -not -path './vendor/*'))" && [ -n "$$unformatted" ]; then \
			echo "FAIL format-check (Go): run gofmt on:"; echo "$$unformatted"; exit 1; \
		fi; \
	else echo "SKIP format-check (Go): go.mod is not present"; fi; \
	if [ -f frontend/package.json ]; then \
		if command -v pnpm >/dev/null 2>&1; then pnpm --dir frontend run format:check; \
		else echo "SKIP format-check (frontend): pnpm is not installed"; fi; \
	else echo "SKIP format-check (frontend): frontend/package.json is not present"; fi

lint:
	@set -eu; \
	if [ -f go.mod ]; then \
		if command -v go >/dev/null 2>&1; then go vet ./...; \
		else echo "SKIP lint (Go): go is not installed"; fi; \
	else echo "SKIP lint (Go): go.mod is not present"; fi; \
	if [ -f frontend/package.json ]; then \
		if command -v pnpm >/dev/null 2>&1; then pnpm --dir frontend run lint; \
		else echo "SKIP lint (frontend): pnpm is not installed"; fi; \
	else echo "SKIP lint (frontend): frontend/package.json is not present"; fi

test-unit:
	@set -eu; \
	if [ -d internal ] && find internal -type f -name '*_test.go' -print -quit | grep -q .; then \
		if command -v go >/dev/null 2>&1; then go test ./internal/...; \
		else echo "SKIP test-unit: go is not installed"; fi; \
	else echo "SKIP test-unit: no internal Go test files are present"; fi

test-integration:
	@set -eu; \
	if [ -f deploy/test/compose.yaml ]; then \
		if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then docker compose -f deploy/test/compose.yaml config >/dev/null; \
		else echo "SKIP test-integration (fixtures): docker compose is not installed"; fi; \
	else echo "SKIP test-integration (fixtures): deploy/test/compose.yaml is not present"; fi; \
	if [ -d tests/integration ] && find tests/integration -type f -name '*_test.go' -print -quit | grep -q .; then \
		if command -v go >/dev/null 2>&1; then go test ./tests/integration/...; \
		else echo "SKIP test-integration (Go): go is not installed"; fi; \
	else echo "SKIP test-integration (Go): no integration test files are present"; fi

test-contract:
	@set -eu; \
	if [ -d tests/contract ] && find tests/contract -type f -name '*_test.go' -print -quit | grep -q .; then \
		if command -v go >/dev/null 2>&1; then go test ./tests/contract/...; \
		else echo "SKIP test-contract: go is not installed"; fi; \
	else echo "SKIP test-contract: no contract test files are present"; fi

test-e2e:
	@set -eu; \
	if [ -d tests/e2e ] && find tests/e2e -type f -name '*_test.go' -print -quit | grep -q .; then \
		if command -v go >/dev/null 2>&1; then go test ./tests/e2e/...; \
		else echo "SKIP test-e2e (Go): go is not installed"; fi; \
	else echo "SKIP test-e2e (Go): no Go end-to-end test files are present"; fi; \
	if [ -f frontend/package.json ]; then \
		if command -v pnpm >/dev/null 2>&1; then pnpm --dir frontend run test:e2e; \
		else echo "SKIP test-e2e (frontend): pnpm is not installed"; fi; \
	else echo "SKIP test-e2e (frontend): frontend/package.json is not present"; fi

architecture-check:
	@set -eu; \
	if [ -d tests/architecture ] && find tests/architecture -type f -name '*_test.go' -print -quit | grep -q .; then \
		if command -v go >/dev/null 2>&1; then go test ./tests/architecture/...; \
		else echo "SKIP architecture-check: go is not installed"; fi; \
	else echo "SKIP architecture-check: no architecture test files are present"; fi

verify: format-check lint test-unit test-integration test-contract test-e2e architecture-check
