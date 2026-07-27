# Contributing to TransactEdge Infrastructure

Thank you for contributing to the TransactEdge infrastructure repository. This guide covers the workflow for making infrastructure changes safely.

## Prerequisites

- Access to the TransactEdge GitHub organization
- AWS credentials for the target environment (via SSO)
- Tools listed in [README.md](README.md#prerequisites)

## Workflow

### 1. Branch

Create a feature branch from `main`:

```bash
git checkout -b feat/add-msk-monitoring
```

Use conventional commit prefixes: `feat:`, `fix:`, `chore:`, `ci:`, `docs:`.

### 2. Develop

Make changes following existing conventions:

- **Terraform**: One module per AWS service under `terraform/modules/`. Environment configs wire modules in `terraform/environments/{env}/`.
- **Helm**: One chart per application service. Environment-specific config in `values-{env}.yaml`.
- **Monitoring**: Dashboards as JSON in `grafana/dashboards/`. Alert rules in `alerts/rules.yml`.

Run local validation before pushing:

```bash
make tf-fmt
make tf-validate
make helm-lint
make tf-lint
```

### 3. Pull Request

Open a PR against `main`. CI will automatically:

- Run `terraform plan` for all environments and post output as PR comments
- Run `helm lint` and `helm template` for all charts and environments

Complete the [PR checklist](.github/PULL_REQUEST_TEMPLATE.md) before requesting review.

### 4. Review

| Change Type | Required Reviewers |
|---|---|
| Terraform (general) | @transactedge/platform-team |
| IAM / Secrets | @transactedge/security + @transactedge/platform-team |
| Helm charts | Service team + @transactedge/platform-team |
| CI/CD workflows | @transactedge/platform-team |
| Alerting | @transactedge/sre + @transactedge/platform-team |

### 5. Deploy

After merge:

1. **Infrastructure**: Trigger `terraform-apply` workflow with target environment
2. **Application charts**: Application repos call the reusable deploy workflow on their next deploy

Production deployments require GitHub Environment approval.

## Code Standards

### Terraform

- Pin provider versions in `required_providers`
- Use `variables.tf`, `main.tf`, `outputs.tf` per module
- Tag all resources with `Environment`, `ManagedBy`, and `Project`
- Never hardcode secrets; use Secrets Manager or variables with sensitive marking
- Run `terraform fmt` before committing

### Helm

- Pin `appVersion` in Chart.yaml
- Non-secret config in ConfigMap; secrets via ExternalSecret only
- Include liveness and readiness probes on all Deployments
- Set resource requests and limits
- Enable HPA for production workloads

### Documentation

- Update ADRs for architectural decisions (see `docs/adr/`)
- Update `docs/architecture.md` for topology changes
- Update `docs/disaster-recovery.md` for backup/DR changes

## Prohibited Practices

- Committing secrets, credentials, or `.env` files
- Applying Terraform directly to production without PR review
- Disabling security controls (WAF, encryption, public access blocks) without Security approval
- Using `terraform apply -target` in production without documented justification
- Modifying production Helm values without staging validation

## Getting Help

- Platform Engineering: #platform-engineering on Slack
- Infrastructure changes: Use the [Infrastructure Change](.github/ISSUE_TEMPLATE/infrastructure_change.yml) issue template
- Security questions: security@transactedge.com
