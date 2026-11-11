SHELL := /bin/bash
.DEFAULT_GOAL := help
GO ?= go
CONTEXT ?=
IMAGE ?= order-api:local
.PHONY: help lint test scan scan-secrets scan-sast scan-vuln build run-local sbom plan
help:
	@echo 'lint/test: Go checks; scan: Gitleaks + Semgrep + Trivy; build/run-local: Docker'
	@echo 'plan: staging server dry-run, CONTEXT required; missing tools fail'
lint:
	cd services/order-api && $(GO) vet ./...
test:
	cd services/order-api && $(GO) test -race -cover ./...
scan: scan-secrets scan-sast scan-vuln
scan-secrets:
	gitleaks detect --config security/gitleaks.toml --source . --redact
scan-sast:
	semgrep scan --error --config security/semgrep-rules.yml --config security/semgrep-rules services/order-api
scan-vuln:
	trivy fs --scanners vuln --severity HIGH,CRITICAL --exit-code 1 services/order-api
build:
	docker build -t "$(IMAGE)" services/order-api
run-local:
	docker run --rm --read-only --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 "$(IMAGE)"
sbom:
	syft "$(IMAGE)" -o spdx-json=order-api-sbom.spdx.json
plan:
	@test -n "$(CONTEXT)" || { echo 'Set CONTEXT to the reviewed staging context'; exit 2; }
	kubectl --context "$(CONTEXT)" apply --dry-run=server -f k8s/
