SHELL := /bin/bash

.PHONY: test scan lint sbom build clean

test:
	@echo "==> Running Go unit tests..."
	cd services/order-api && go test -v -race ./...

scan-secrets:
	@echo "==> Running Gitleaks secret scan..."
	gitleaks detect --config security/gitleaks.toml --verbose

scan-sast:
	@echo "==> Running Semgrep SAST..."
	semgrep scan --config security/semgrep-rules.yml services/order-api

scan-vuln:
	@echo "==> Running Trivy vulnerability scan..."
	trivy fs services/order-api

build:
	@echo "==> Building hardened container image..."
	docker build -t order-api:local services/order-api

sbom: build
	@echo "==> Generating SBOM with Syft..."
	syft order-api:local -o spdx-json=order-api-sbom.spdx.json

