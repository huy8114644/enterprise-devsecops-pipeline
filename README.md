# Enterprise DevSecOps Pipeline (Golden Path)

[![DevSecOps Pipeline](https://github.com/huy8114644/enterprise-devsecops-pipeline/actions/workflows/devsecops-pipeline.yml/badge.svg)](https://github.com/huy8114644/enterprise-devsecops-pipeline/actions/workflows/devsecops-pipeline.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-blue.svg)](https://slsa.dev)
[![Container: Distroless](https://img.shields.io/badge/Container-Distroless-orange.svg)](https://github.com/GoogleContainerTools/distroless)

Production-grade **Reusable DevSecOps CI/CD Golden Path Pipeline** implementing true Shift-Left security, automated supply-chain verification (SLSA Level 3), and native GitHub Security Code Scanning integration.

---

## 🏛️ Pipeline Security Architecture

```
[ Developer Commit ]
        │
        ▼
[ Stage 1: Secret Detection ] ── (Gitleaks: Block API keys & tokens)
        │
        ▼
[ Stage 2: Code Linting & Tests ] ── (Go 1.22 Race Detector + ACTIONLINT)
        │
        ▼
[ Stage 3: SAST Analysis ] ── (Semgrep OWASP Top 10 ➔ SARIF upload)
        │
        ▼
[ Stage 4: SCA Dependency Scan ] ── (Trivy FS ➔ CVE gate)
        │
        ▼
[ Stage 5: Hardened Container Build ] ── (Distroless non-root UID 65532)
        │
        ▼
[ Stage 6: Container Image Scan ] ── (Trivy Image ➔ Block HIGH/CRITICAL)
        │
        ▼
[ Stage 7: Software Bill of Materials ] ── (Syft SPDX / CycloneDX format)
        │
        ▼
[ Stage 8: Keyless Cryptographic Signing ] ── (Cosign OIDC / Sigstore)
```

---

## 🔒 Security Capabilities & Tooling

| Stage | Tool | Enforcement Policy | Output / Verification |
|---|---|---|---|
| **Secret Scanning** | Gitleaks v8 | Fail build if unencrypted credentials or private keys are committed | Block commit, Slack alert |
| **SAST** | Semgrep | Scans AST for injection flaws, insecure deserialization, SSRF | SARIF format uploaded to GitHub Code Scanning |
| **SCA** | Trivy FS | Evaluates transitive dependencies against NVD, OSV, GHSA | Automated CVE report with remediation guidance |
| **Hardened Image** | Docker + Distroless | No package managers, no shell (`/bin/sh`), runs as UID 65532 | 0 attack surface for RCE shell breakouts |
| **Image Scan** | Trivy Image | Scans OS layers and Go binary packages | Blocks deployment on unfixed CRITICAL CVEs |
| **SBOM** | Anchore Syft | Generates full inventory of packages, licenses, digests | SPDX JSON artifact attached to CI build |
| **Cosign Signing** | Sigstore Cosign | Cryptographic keyless container signing using GitHub OIDC token | In-toto attestation verifiable via Kyverno |

---

## 🚀 Microservice Architecture (`services/order-api`)

The repository includes a production-grade Go microservice configured according to **Pod Security Standards (PSS) Restricted**:
- `runAsNonRoot: true` (UID 65532).
- `readOnlyRootFilesystem: true` (prevents malicious file drops).
- `capabilities: drop: ["ALL"]` (drops all Linux privileges).
- `seccompProfile: type: RuntimeDefault`.

---

## 🛠️ Local Developer Commands

```bash
# Run unit tests with race detection
make test

# Scan local repository for leaked secrets
make scan-secrets

# Run Semgrep SAST scan locally
make scan-sast

# Scan dependencies for CVEs
make scan-vuln

# Build hardened container and generate SBOM
make build
make sbom
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

