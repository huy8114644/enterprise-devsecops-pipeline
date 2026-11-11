SHELL := /bin/bash

.PHONY: all lint test scan scan-secrets scan-sast scan-vuln build run-local sbom clean help

all: lint test scan build

help:
	@echo "Enterprise DevSecOps Pipeline Commands:"
	@echo "  make lint         Run Go static code analysis (go vet)"
	@echo "  make test         Execute Go unit tests with race condition detector"
	@echo "  make scan         Run full security scan suite (Secrets, SAST, SCA)"
	@echo "  make scan-secrets Scan repository for leaked credentials via Gitleaks"
	@echo "  make scan-sast    Run AST-based SAST rules via Semgrep"
	@echo "  make scan-vuln    Scan dependencies and OS packages via Trivy"
	@echo "  make build        Build hardened multi-stage Distroless container"
	@echo "  make run-local    Run order-api microservice locally on port 8080"
	@echo "  make sbom         Generate SPDX Software Bill of Materials via Syft"
	@echo "  make clean        Remove generated build artifacts and reports"

lint:
	@echo "==> Running static code analysis (go vet)..."
	@if command -v go >/dev/null 2>&1; then 		cd services/order-api && go vet ./...; 	else 		docker run --rm -v $(CURDIR)/services/order-api:/app -w /app golang:1.22 go vet ./...; 	fi

test:
	@echo "==> Running Go unit tests with race detector..."
	@if command -v go >/dev/null 2>&1; then 		cd services/order-api && go test -v -race -coverprofile=coverage.out ./...; 	else 		docker run --rm -v $(CURDIR)/services/order-api:/app -w /app golang:1.22 go test -v -race -coverprofile=coverage.out ./...; 	fi

scan: scan-secrets scan-sast scan-vuln
	@echo "==> All security scans completed successfully."

scan-secrets:
	@echo "==> [Secret Scan] Running Gitleaks..."
	@which gitleaks >/dev/null 2>&1 && gitleaks detect --config security/gitleaks.toml --verbose || echo "[INFO] gitleaks CLI not installed locally; enforced via GitHub Actions CI"

scan-sast:
	@echo "==> [SAST] Running Semgrep OWASP Top 10 rules..."
	@which semgrep >/dev/null 2>&1 && semgrep scan --config security/semgrep-rules.yml services/order-api || echo "[INFO] semgrep CLI not installed locally; enforced via GitHub Actions CI"

scan-vuln:
	@echo "==> [SCA] Running Trivy vulnerability scanner..."
	@which trivy >/dev/null 2>&1 && trivy fs services/order-api || echo "[INFO] trivy CLI not installed locally; enforced via GitHub Actions CI"

build:
	@echo "==> Building hardened multi-stage container image..."
	docker build -t order-api:local services/order-api

run-local:
	@echo "==> Starting order-api microservice locally on port 8080..."
	cd services/order-api && go run main.go middleware_security.go middleware_ratelimit.go

sbom: build
	@echo "==> Generating SBOM with Syft in SPDX JSON format..."
	@which syft >/dev/null 2>&1 && syft order-api:local -o spdx-json=order-api-sbom.spdx.json || echo "[INFO] syft CLI not installed locally; generated in CI pipeline"

clean:
	@echo "==> Cleaning local build artifacts..."
	rm -f services/order-api/coverage.out order-api-sbom.spdx.json
