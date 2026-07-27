# Disaster Recovery Plan

## Objectives

| Metric | Target | Notes |
|---|---|---|
| RTO (Recovery Time Objective) | 4 hours | Time to restore critical payment processing |
| RPO (Recovery Point Objective) | 15 minutes | Maximum acceptable data loss for transactional data |

These targets align with TransactEdge's PCI DSS and SOC 2 obligations for a B2B payments platform processing live merchant transactions.

## Critical Systems

| System | Tier | RTO | RPO | Recovery Method |
|---|---|---|---|---|
| payments-api | Tier 1 | 1 hour | 5 min | EKS redeploy from ECR + Helm |
| fraud-engine | Tier 1 | 1 hour | 15 min | EKS redeploy from ECR + Helm |
| merchant-portal | Tier 2 | 2 hours | 15 min | EKS redeploy from ECR + Helm |
| RDS PostgreSQL | Tier 1 | 2 hours | 15 min | Multi-AZ failover / snapshot restore |
| Amazon MSK | Tier 1 | 2 hours | 15 min | Multi-AZ broker recovery |
| ElastiCache Redis | Tier 2 | 1 hour | N/A (cache) | Failover to replica / rebuild |
| AWS Secrets Manager | Tier 1 | 30 min | 0 | Multi-AZ, replicated secrets |

## Backup Strategy

### RDS PostgreSQL

- **Automated backups**: 35-day retention (production), 14-day (staging), 7-day (dev)
- **Backup window**: 03:00–04:00 UTC daily
- **Final snapshots**: Created on instance deletion (production)
- **Cross-region**: Manual snapshots copied to `us-west-2` weekly for production
- **Point-in-time recovery**: Enabled via automated backups (5-minute granularity)

### Amazon MSK

- **Broker storage**: EBS volumes with 7-day log retention
- **Configuration**: `min.insync.replicas=2`, `default.replication.factor=3`
- **Backup**: MSK does not support native backup; rely on multi-AZ broker redundancy and topic replication factor
- **Disaster scenario**: Restore from cross-region mirror cluster (future: MSK Replicator to us-west-2)

### ElastiCache Redis

- **Snapshots**: Daily snapshots with 7-day retention
- **Failover**: Automatic failover enabled (staging/production)
- **Data classification**: Cache-only; no transactional data stored

### S3

- **Versioning**: Enabled on all buckets
- **Lifecycle**: Transition to STANDARD_IA (90 days), GLACIER (365 days)
- **Cross-region replication**: Planned for `settlement-files` and `audit-logs` buckets

### Terraform State

- **Backend**: S3 with versioning and DynamoDB locking
- **Recovery**: Restore previous state version from S3 versioning if corruption detected

## Multi-AZ Architecture

All production-tier resources run across multiple availability zones:

- EKS node groups span 3 AZs
- RDS Multi-AZ with synchronous standby
- ElastiCache replication group with automatic failover
- MSK brokers distributed across 3 AZs
- ALB cross-zone load balancing enabled

## Multi-Region Considerations

Primary region: **us-east-1**

A warm standby in **us-west-2** is planned for Tier 1 services:

| Component | Current State | DR Target |
|---|---|---|
| EKS | us-east-1 only | us-west-2 cluster (infrastructure-as-code ready) |
| RDS | us-east-1 Multi-AZ | Cross-region read replica in us-west-2 |
| MSK | us-east-1 | MSK Replicator to us-west-2 (planned Q3) |
| Route 53 | Active | Failover routing policy configured |
| CloudFront | Global | Origin failover to us-west-2 ALB |

## Recovery Procedures

### Scenario 1: Single Pod / Deployment Failure

**Detection**: `PodCrashLooping` alert, Kubernetes events

**Response**:
1. Check pod logs: `kubectl logs -n <namespace> <pod>`
2. Verify ExternalSecret sync: `kubectl get externalsecret -n <namespace>`
3. Roll back Helm release if caused by bad deploy: `helm rollback <release> -n <namespace>`
4. Escalate to application team if code defect

**RTO**: 15 minutes

### Scenario 2: RDS Primary Failure

**Detection**: `DatabaseReplicationLag` alert, RDS console event

**Response**:
1. Verify Multi-AZ failover occurred automatically (check RDS events)
2. If failover did not occur, initiate manual failover via AWS Console
3. Update application connection strings if endpoint changed (unlikely with Multi-AZ)
4. Verify payments-api and fraud-engine database connectivity

**RTO**: 30 minutes (automatic), 1 hour (manual)

### Scenario 3: MSK Broker Failure

**Detection**: `KafkaConsumerLag` alert, MSK CloudWatch metrics

**Response**:
1. Check MSK broker health in AWS Console
2. MSK automatically replaces unhealthy brokers in Multi-AZ setup
3. Monitor consumer lag recovery
4. If topic data loss suspected, replay from payments-api outbox table

**RTO**: 1 hour

### Scenario 4: Full Region Failure (us-east-1)

**Detection**: Multiple critical alerts, AWS Health Dashboard

**Response**:
1. Declare disaster via incident command (PagerDuty + Slack #incidents)
2. Activate us-west-2 warm standby (runbook: `RUNBOOK-DR-001`)
3. Promote RDS cross-region read replica to standalone
4. Update Route 53 failover records to us-west-2 endpoints
5. Deploy application services to us-west-2 EKS via Helm
6. Validate end-to-end payment flow with synthetic transactions
7. Communicate status to merchants via status page

**RTO**: 4 hours

## Runbook References

| Runbook ID | Title | Location |
|---|---|---|
| RUNBOOK-DR-001 | Full region failover to us-west-2 | wiki.transactedge.com/runbooks/dr-001 |
| RUNBOOK-DR-002 | RDS point-in-time recovery | wiki.transactedge.com/runbooks/dr-002 |
| RUNBOOK-DR-003 | MSK broker recovery | wiki.transactedge.com/runbooks/dr-003 |
| RUNBOOK-DR-004 | Helm release rollback | wiki.transactedge.com/runbooks/dr-004 |

## DR Validation Schedule

| Activity | Frequency | Owner |
|---|---|---|
| RDS restore validation (to isolated instance) | Quarterly | Platform Engineering |
| Helm rollback drill | Monthly | Platform Engineering |
| Tabletop exercise (region failure) | Semi-annual | Platform + Security + Leadership |
| Full failover drill (us-west-2) | Annual | Platform Engineering |

## Contact

- **Platform on-call**: PagerDuty — TransactEdge Platform
- **Security incidents**: security@transactedge.com
- **Executive escalation**: CTO via PagerDuty escalation policy
