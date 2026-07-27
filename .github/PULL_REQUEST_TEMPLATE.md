## Summary

<!-- Describe the infrastructure change and its motivation. Link related issues. -->

## Change type

- [ ] Terraform (AWS resources)
- [ ] Helm charts (Kubernetes workloads)
- [ ] CI/CD workflows
- [ ] Monitoring / alerting
- [ ] Documentation
- [ ] Secrets management

## Environments affected

- [ ] dev
- [ ] staging
- [ ] production

## Application services affected

- [ ] payments-api
- [ ] fraud-engine
- [ ] merchant-portal
- [ ] None (platform-only change)

## Terraform plan review checklist

- [ ] `terraform fmt` passes locally
- [ ] `terraform validate` passes for all affected environments
- [ ] Terraform plan output attached (or linked from CI comment)
- [ ] No unintended resource destruction (`terraform plan` reviewed for `-/+` and destroy actions)
- [ ] IAM changes reviewed for least-privilege compliance
- [ ] Security group changes reviewed for ingress/egress rules
- [ ] State backend and locking unaffected
- [ ] Secrets are not committed to version control

## Helm review checklist

- [ ] `helm lint` passes for all affected charts and environments
- [ ] `helm template` output reviewed for correctness
- [ ] Resource requests/limits appropriate for target environment
- [ ] HPA thresholds validated
- [ ] ExternalSecret references point to correct AWS Secrets Manager paths
- [ ] Ingress hostnames and TLS configuration verified

## Risk assessment

| Risk | Mitigation |
|------|-----------|
| <!-- e.g., RDS downtime during parameter group change --> | <!-- e.g., apply during maintenance window --> |

## Rollback plan

<!-- How to revert this change if it fails in production. -->

## Post-deploy validation

<!-- Health checks, metrics, and smoke tests to run after apply. -->

## Compliance

- [ ] PCI DSS impact assessed (if applicable)
- [ ] SOC 2 control mapping updated (if applicable)
- [ ] Security team review requested (if IAM/secrets/networking changed)
