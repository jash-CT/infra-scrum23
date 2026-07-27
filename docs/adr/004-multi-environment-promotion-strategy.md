# ADR-004: Multi-Environment Promotion Strategy

## Status

Accepted

## Date

2025-04-01

## Context

TransactEdge operates three environments (dev, staging, production) for a PCI-regulated B2B payments platform. We need a promotion strategy that:

- Enables rapid iteration in dev
- Validates changes in staging before production exposure
- Enforces approval gates for production deployments
- Maintains immutable, auditable deployment artifacts
- Supports both infrastructure (Terraform) and application (Helm) changes

## Decision

We will implement a **forward-only, immutable artifact promotion** strategy:

1. **dev**: Automatic deployment on merge to `main`
2. **staging**: Manual promotion of the same image digest validated in dev
3. **production**: Manual promotion with GitHub Environment protection rules requiring Platform and Security approval

Infrastructure changes follow a parallel path: Terraform plan on PR, manual apply with environment-specific approval gates.

## Rationale

### Application promotion

| Environment | Trigger | Approval | Image Source |
|---|---|---|---|
| dev | Merge to main | None | `git SHA` from CI build |
| staging | Workflow dispatch | Platform team | Same `git SHA` from dev |
| production | Workflow dispatch | Platform + Security | Same `git SHA` from staging |

Images are never rebuilt during promotion. The same container digest validated in staging is deployed to production, ensuring behavioral consistency.

### Infrastructure promotion

| Environment | Trigger | Approval |
|---|---|---|
| dev | Merge to main → manual apply | Platform team |
| staging | Manual apply after dev validation | Platform team |
| production | Manual apply with confirmation input | Platform + Security (GitHub Environment) |

Terraform changes are promoted by applying the same commit sequentially across environments, not by maintaining environment-specific branches.

### Why not GitOps (ArgoCD/Flux)?

GitOps tools were evaluated but deferred to a later phase. The current team size (~25 employees, 4 platform engineers) can manage deployments via GitHub Actions reusable workflows. GitOps adoption is planned when deployment frequency exceeds 10 deploys/day across all services.

## Consequences

### Positive

- Immutable artifacts provide audit trail for PCI DSS compliance
- Production approval gate prevents accidental deployments
- Same image digest across staging and production eliminates "works in staging" discrepancies
- Clear escalation path: dev → staging → production

### Negative

- Manual promotion steps add latency (acceptable for B2B payments; not consumer-facing with sub-minute deploy requirements)
- Staging can drift from production if promotions are delayed
- No automatic rollback on metric regression (planned: Argo Rollouts or Flagger)

## Alternatives Considered

1. **GitOps with ArgoCD** — Deferred; team not at scale yet
2. **Blue/green with automatic promotion** — Deferred; requires metric-based canary analysis tooling
3. **Branch-per-environment** — Rejected; creates merge conflicts and drift
