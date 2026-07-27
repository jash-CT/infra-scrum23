# Secrets management approach for TransactEdge infrastructure.
#
# Primary mechanism: AWS Secrets Manager + External Secrets Operator (ESO)
#
# 1. Terraform provisions secrets in AWS Secrets Manager (see terraform/modules/secrets-manager).
# 2. RDS and ElastiCache credentials are stored automatically by their respective modules.
# 3. ESO ClusterSecretStore authenticates via IRSA (see terraform/modules/iam).
# 4. Application Helm charts declare ExternalSecret resources that sync to Kubernetes Secrets.
# 5. Pods mount secrets via envFrom secretRef — secrets never appear in ConfigMaps or Helm values.
#
# Rotation:
#   - RDS: managed rotation via AWS Secrets Manager rotation Lambda (configured post-provision).
#   - Application secrets: rotated via Security team runbook; ESO refreshInterval picks up changes.
#
# Namespaces:
#   payments  — payments-api
#   fraud     — fraud-engine
#   merchant  — merchant-portal
#   external-secrets — ESO controller
