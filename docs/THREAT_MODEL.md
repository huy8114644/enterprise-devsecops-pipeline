# STRIDE Threat Model: Order API Service

| Threat Category | Potential Attack Vector | Applied DevSecOps Countermeasure | Verification Gate |
|---|---|---|---|
| **Spoofing** | Forged container provenance or unauthorized API client | Cosign Keyless Image Attestation + mTLS | Sigstore OIDC Verify |
| **Tampering** | In-container binary patching or arbitrary write to rootfs | Read-only root filesystem + Distroless base | PSS Restricted Policy |
| **Repudiation** | Denying malicious API actions | Structured audit logging with correlation IDs | CloudWatch Audit Trail |
| **Information Disclosure** | Secret leaks via env vars or error traces | HashiCorp Vault ephemeral injection + Gitleaks | Pre-commit & CI Gitleaks |
| **Denial of Service** | Volumetric HTTP flood or resource exhaustion | In-memory token bucket rate limiter + K8s resource limits | Kyverno limits enforcement |
| **Elevation of Privilege** | Container breakout to host node | Non-root UID (65532) + Drop ALL Linux capabilities | Kyverno Disallow Privileged |
