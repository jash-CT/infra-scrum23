# ADR-003: Helm vs Kustomize for Kubernetes Packaging

## Status

Accepted

## Date

2025-03-22

## Context

TransactEdge deploys three application services (payments-api, fraud-engine, merchant-portal) to EKS across three environments. Each service requires Deployment, Service, HPA, ServiceMonitor, Ingress, ConfigMap, and ExternalSecret resources with environment-specific configuration differences.

We evaluated Helm and Kustomize as Kubernetes packaging tools.

## Decision

We will use **Helm** as the primary Kubernetes packaging tool, with one chart per application service.

## Rationale

| Criterion | Helm | Kustomize |
|---|---|---|
| Templating | Go templates with values files | Strategic merge patches and overlays |
| Environment config | `values-{env}.yaml` per chart | `overlays/{env}/` per app |
| Versioning | Chart version + app version in Chart.yaml | No built-in versioning |
| CI integration | `helm lint`, `helm template`, `helm upgrade` | `kustomize build`, `kubectl apply -k` |
| Reusable deploy workflow | `--set image.tag` at deploy time | Requires kustomize edit or sed |
| Ecosystem | De facto standard for app packaging | Better for cluster-level config (base + overlays) |
| Learning curve | Moderate (Go templates) | Lower (plain YAML patches) |

Helm's values file pattern maps directly to our three-environment model. The reusable GitHub Actions deploy workflow passes `image.tag` via `--set`, enabling application repos to deploy without modifying chart source. Chart versioning provides an audit trail of Kubernetes manifest changes.

Kustomize excels at cluster-level configuration (namespaces, RBAC, CRDs) but lacks built-in release management and rollback capabilities that Helm provides via `helm history` and `helm rollback`.

## Consequences

### Positive

- One chart per service with clear ownership (CODEOWNERS)
- Environment-specific values files (`values-dev.yaml`, `values-staging.yaml`, `values-production.yaml`)
- `helm upgrade --install` with `--wait` provides deployment verification
- `helm rollback` enables rapid recovery (see disaster-recovery.md)
- Application repos call reusable deploy workflow without chart modifications

### Negative

- Go template syntax can be error-prone (mitigated by `helm lint` in CI)
- Chart dependencies (e.g., kube-prometheus-stack) add version management overhead
- Helm release state stored in cluster (mitigated by GitOps principles — chart source is truth)

### Neutral

- Kustomize may still be used for cluster-level resources (External Secrets Operator install, monitoring stack) where Helm chart dependencies are overkill

## Alternatives Considered

1. **Kustomize overlays** — Rejected for application services; better suited for cluster config
2. **Raw YAML manifests** — Rejected; no templating, no release management
3. **Helm + Kustomize hybrid** — Adopted partially; Helm for apps, Kustomize reserved for cluster-level config if needed
