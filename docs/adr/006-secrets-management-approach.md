# ADR-006: Secrets Management Approach

## Status

Accepted

## Date

2025-04-12

## Context

TransactEdge handles PCI-regulated payment data and must protect credentials for RDS, ElastiCache, MSK, and application-level secrets (API keys, JWT signing keys, OAuth client secrets). Requirements:

- Secrets never stored in Git, Helm values, or ConfigMaps
- Automatic rotation for database credentials
- Least-privilege access per service (payments-api, fraud-engine, merchant-portal)
- Audit trail for secret access (SOC 2 CC6.1)
- Kubernetes-native secret injection into pods

We evaluated three approaches:

1. AWS Secrets Manager + External Secrets Operator (ESO)
2. Sealed Secrets (Bitnami)
3. HashiCorp Vault

## Decision

We will use **AWS Secrets Manager as the source of truth** with **External Secrets Operator** syncing secrets into Kubernetes.

## Rationale

| Criterion | AWS SM + ESO | Sealed Secrets | HashiCorp Vault |
|---|---|---|---|
| AWS integration | Native | None (Git-stored encrypted blobs) | Requires Vault-AWS auth config |
| Rotation | Built-in rotation Lambda | Manual | Vault rotation engines |
| Operational overhead | Low (managed service) | Low | High (self-hosted cluster) |
| Audit logging | CloudTrail integration | None | Vault audit log |
| IRSA support | Native via ESO service account | N/A | Requires Vault K8s auth |
| PCI DSS alignment | AWS SM is PCI DSS compliant | Encryption at rest only | Requires HSM for PCI |
| Cost | ~$0.40/secret/month | Free | Self-hosted compute + HA |

AWS Secrets Manager is already provisioned by Terraform modules (RDS credentials, ElastiCache auth tokens, application secrets). ESO bridges Secrets Manager to Kubernetes with a simple ClusterSecretStore + ExternalSecret CRD pattern that integrates with our Helm charts.

Sealed Secrets encrypts secrets into Git-committable blobs, but this still places encrypted secret material in version control and lacks native rotation.

HashiCorp Vault provides the richest secrets management features but requires a dedicated HA cluster, unsealing procedures, and additional operational expertise that is not justified at TransactEdge's current scale.

## Implementation

```
Terraform (secrets-manager module)
  → AWS Secrets Manager (encrypted with KMS)
    → External Secrets Operator (IRSA-authenticated)
      → Kubernetes Secret (per namespace)
        → Pod envFrom secretRef
```

### Secret naming convention

```
{environment}/{service}
  te-prod/payments-api
  te-prod/fraud-engine
  te-prod/merchant-portal
  te-prod/shared/datadog
```

### Access control

- Each service's IRSA role grants `secretsmanager:GetSecretValue` only on its own secret ARN
- External Secrets Operator role grants read access to all secrets (required for sync)
- Terraform manages secret creation; secret values are set post-provision and rotated via runbook

## Consequences

### Positive

- No secrets in Git or Helm values
- CloudTrail audit log for every secret access
- Automatic RDS credential rotation via Secrets Manager
- Helm charts declare ExternalSecret resources; secret paths are environment-specific in values files
- Consistent pattern across all three application services

### Negative

- ESO adds a cluster-level dependency (mitigated by running 2 replicas)
- Secret changes have propagation delay (ESO `refreshInterval`, default 1h)
- AWS Secrets Manager cost scales with secret count (~$2/month for 5 secrets × 3 environments)

## Alternatives Considered

1. **Sealed Secrets** — Rejected; encrypted blobs in Git, no native rotation
2. **HashiCorp Vault** — Rejected; operational overhead not justified at current scale
3. **SSM Parameter Store + ESO** — Considered; Secrets Manager preferred for rotation and audit capabilities
