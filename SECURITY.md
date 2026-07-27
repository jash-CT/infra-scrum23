# Security Policy

## Reporting a Vulnerability

TransactEdge takes the security of its payment processing infrastructure seriously. If you discover a security vulnerability, please report it responsibly.

**Do not** open a public GitHub issue for security vulnerabilities.

### Contact

- Email: security@transactedge.com
- PGP Key: Available at https://transactedge.com/.well-known/pgp-key.txt

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Affected environment (dev, staging, production)
- Affected service (payments-api, fraud-engine, merchant-portal, infrastructure)
- Potential impact assessment

### Response Timeline

| Stage | Timeline |
|---|---|
| Acknowledgment | Within 24 hours |
| Initial assessment | Within 72 hours |
| Remediation plan | Within 5 business days |
| Fix deployment | Based on severity (critical: 24h, high: 7d, medium: 30d) |

## Infrastructure Security Controls

This repository implements the following security controls:

### Access Control

- IAM roles follow least-privilege principle (IRSA per service)
- Production Terraform applies require Platform + Security approval
- CODEOWNERS enforces review requirements for sensitive paths
- EKS API endpoint is private in staging and production

### Encryption

- All data at rest encrypted with AWS KMS (RDS, ElastiCache, MSK, S3, Secrets Manager, EKS secrets)
- All data in transit encrypted with TLS (ALB, MSK, RDS, Redis)
- Terraform state encrypted in S3 with DynamoDB locking

### Secrets Management

- AWS Secrets Manager is the sole source of truth for credentials
- Secrets are never committed to version control
- External Secrets Operator syncs secrets to Kubernetes with IRSA authentication
- See [ADR-006](docs/adr/006-secrets-management-approach.md)

### Network Security

- VPC with public, private, and database subnet tiers
- Security groups restrict ingress to required ports and source security groups
- AWS WAF on ALB and CloudFront (staging/production)
- fraud-engine is internal-only (no public internet exposure)

### Compliance

- PCI DSS: Cardholder data environment isolated in production VPC
- SOC 2: Audit logging via CloudTrail, CloudWatch, and Prometheus
- All infrastructure changes tracked in Git with PR review requirements

## Supported Versions

| Component | Supported Version |
|---|---|
| Terraform | >= 1.6.0 |
| Kubernetes (EKS) | 1.29 |
| Helm | >= 3.14 |
| PostgreSQL | 15.x |
| Redis | 7.x |
| Kafka (MSK) | 3.5.x |

## Security-Related Files

Changes to the following paths require Security team review (enforced via CODEOWNERS):

- `terraform/modules/iam/`
- `terraform/modules/secrets-manager/`
- `k8s/secrets/`
- `.github/workflows/`
