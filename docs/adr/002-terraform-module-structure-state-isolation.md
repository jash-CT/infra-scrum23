# ADR-002: Terraform Module Structure and State Isolation Strategy

## Status

Accepted

## Date

2025-03-18

## Context

TransactEdge infrastructure spans multiple AWS services (VPC, EKS, RDS, ElastiCache, MSK, S3, IAM, ALB, CloudFront, Secrets Manager) across three environments. We need a Terraform organization strategy that provides:

- Reusable, composable modules
- Isolated state per environment to limit blast radius
- Encrypted remote state with locking
- Clear ownership boundaries for platform engineering

## Decision

We will use a **modular Terraform structure** with **per-environment state isolation**:

```
terraform/
  bootstrap/          # One-time state backend provisioning
  modules/            # Reusable modules (vpc, eks, rds, ...)
  environments/
    dev/              # State key: environments/dev/terraform.tfstate
    staging/          # State key: environments/staging/terraform.tfstate
    production/       # State key: environments/production/terraform.tfstate
```

Remote state backend: S3 bucket (`transactedge-terraform-state`) with DynamoDB locking (`transactedge-terraform-locks`).

## Rationale

### Module structure

Each AWS service is encapsulated in its own module under `terraform/modules/`. Environment root configs in `terraform/environments/{env}/` wire modules together with environment-specific `terraform.tfvars`. This provides:

- **Reusability**: The `vpc` module is identical across environments; only inputs differ
- **Testability**: Modules can be validated independently with `terraform validate`
- **Ownership**: CODEOWNERS maps modules to responsible teams

### State isolation

Separate state files per environment ensure:

- A `terraform apply` in dev cannot affect production resources
- State locking prevents concurrent modifications within an environment
- Blast radius of state corruption is limited to one environment
- Different approval workflows per environment (production requires manual gate)

We rejected a monorepo single-state approach because a single state file for all environments creates unacceptable risk for a PCI-regulated payments platform.

### Remote backend

S3 with versioning provides state history for recovery. DynamoDB locking prevents concurrent applies. Encryption at rest is mandatory for SOC 2 compliance.

## Consequences

### Positive

- Clear separation of concerns between modules and environments
- Production changes require explicit environment selection in CI
- State recovery via S3 versioning
- Modules are portable to additional regions (us-west-2 DR)

### Negative

- Cross-environment resource references require data sources or remote state outputs (not direct resource references)
- Three state files to manage and monitor
- Bootstrap must be applied before any environment

## Alternatives Considered

1. **Terragrunt with DRY configs** — Deferred; adds complexity before team is at scale
2. **Single state with workspaces** — Rejected; workspaces share a single state file, increasing blast radius
3. **CDK for Terraform (cdktf)** — Rejected; team expertise is in HCL, not TypeScript/Python for IaC
