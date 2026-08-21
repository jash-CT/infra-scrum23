# Platform Operations Runbook

This runbook covers on-call procedures for the infrastructure that hosts
`payments-api`, `fraud-engine`, and `merchant-portal`. It is the entry point
for Platform Engineering on-call and is cross-referenced from each
application repository's own runbook for issues that trace back to shared
infrastructure. See [disaster-recovery.md](disaster-recovery.md) for
region/data-store-level recovery and [deployment-pipeline.md](deployment-pipeline.md)
for the deploy flow.

## Scope

This runbook covers issues in:

- Amazon EKS (cluster, node groups, add-ons)
- RDS PostgreSQL, ElastiCache Redis, Amazon MSK
- ALB / CloudFront / WAF edge layer
- External Secrets Operator / AWS Secrets Manager sync
- Prometheus / Grafana / Alertmanager

Application-level logic issues belong in the owning repository's runbook:
[payments-api](https://github.com/transactedge/payments-api/blob/main/docs/runbook.md),
[fraud-engine](https://github.com/transactedge/fraud-engine/blob/main/docs/runbook.md),
[merchant-portal](https://github.com/transactedge/merchant-portal/blob/main/docs/runbook.md).

## First Response Checklist

1. Check the **cluster health** overview: node readiness, control plane status
   (`kubectl get nodes`, `kubectl get componentstatuses` where available on EKS).
2. Check Alertmanager for the full set of currently firing alerts — a single
   root cause (e.g. an AZ-level network event) often triggers multiple
   `PodCrashLooping` and latency alerts simultaneously across namespaces.
3. Check AWS Health Dashboard for an active event in `us-east-1`.
4. Check `kubectl get externalsecret -A` for sync failures — a stale or failed
   secret sync is a frequent, easily missed root cause of app-level
   authentication or connectivity failures that look like application bugs.
5. Check whether the incident correlates with a recent Terraform apply or Helm
   deploy (`helm history <release> -n <namespace>`).

## Key Dashboards and Alerts

| Alert | Threshold | Scope |
|---|---|---|
| `HighErrorRate` | 5xx > 5% over 5m | payments-api (labeled `team: payments`) |
| `ElevatedPaymentFailureRate` | failure rate > 2% over 10m | payments-api |
| `ElevatedFraudEngineLatency` | P99 > 500ms over 5m | fraud-engine |
| `KafkaConsumerLag` | lag > 10,000 over 10m | MSK / `payments-api`, `fraud-engine` consumer groups |
| `DatabaseReplicationLag` | lag > 30s over 5m | RDS |
| `PodCrashLooping` | > 3 restarts / 15m | any namespace in `payments\|fraud\|merchant` |
| `MerchantPortalHighLatency` | P95 > 2s over 5m | merchant-portal |

Dashboards (provisioned via `grafana/provisioning/`, sourced from
`grafana/dashboards/`):

- `payments-api-latency-errors.json`
- `fraud-engine-latency.json`
- `kafka-consumer-lag.json`
- `database-connections.json`

## Common Failure Modes

### 1. EKS node group not scaling / pods stuck `Pending`

**Response:**
1. Check node group capacity and Cluster Autoscaler/Karpenter logs.
2. Check for a resource request/limit misconfiguration in a recently changed
   Helm values file (`values-<env>.yaml`) causing bin-packing failures.
3. Check AWS service quotas (EC2 instance limits) if scale-out is failing
   entirely rather than being slow.

### 2. External Secrets Operator sync failures

**Response:**
1. `kubectl describe externalsecret <name> -n <namespace>` — check the
   `SecretSyncedError` condition and message.
2. Confirm the IRSA role attached to the ESO service account still has
   `secretsmanager:GetSecretValue` on the target secret ARN — a Terraform
   change to `terraform/modules/iam/` is a common cause.
3. Confirm the secret still exists in AWS Secrets Manager under the expected
   path/name — a manual console deletion or a Terraform destroy/recreate with
   a changed name will break sync silently until the refresh interval elapses.

### 3. RDS PostgreSQL performance degradation

**Response:**
1. Check CPU, IOPS, and connection count on the Database Connections
   dashboard.
2. Check `pg_stat_activity` for long-running or blocking queries; correlate
   with recent application deploys.
3. If replication lag is climbing (`DatabaseReplicationLag`), check for a
   large batch operation (e.g. a settlement batch completion job) rather than
   assuming instance failure.
4. Escalate to a Multi-AZ failover decision only after confirming the primary
   itself, not just a specific query pattern, is the bottleneck.

### 4. Amazon MSK broker or partition issues

**Response:**
1. Check MSK CloudWatch metrics for under-replicated partitions and broker
   CPU/disk.
2. Confirm `min.insync.replicas=2` / `default.replication.factor=3` settings
   are intact (see [disaster-recovery.md](disaster-recovery.md)).
3. If a single broker is unhealthy, MSK's Multi-AZ design should self-heal by
   replacing it — verify this is progressing rather than intervening manually.

### 5. Helm deploy failure / stuck rollout

**Response:**
1. `kubectl rollout status deployment/<name> -n <namespace>` to confirm the
   rollout is genuinely stuck vs. slow.
2. Check `ImagePullBackOff` (ECR auth/IRSA issue) vs. readiness probe failures
   (application-level issue — hand off to the owning team's runbook).
3. Roll back: `helm rollback <release> <revision> -n <namespace>`.
4. If the rollout is stuck due to a `terraform-apply` in progress that changed
   IAM/networking concurrently with a deploy, pause the Helm deploy until the
   Terraform apply completes.

### 6. Terraform state lock contention or drift

**Response:**
1. A stuck DynamoDB lock (from an aborted `terraform apply`) blocks all
   subsequent plans/applies for that environment's state key.
2. Confirm no other apply is genuinely in progress before force-unlocking:
   `terraform force-unlock <lock-id>`.
3. Run `terraform plan` after any manual AWS console change to detect and
   reconcile drift before the next scheduled apply.
4. If state corruption is suspected, restore a prior object version from the
   versioned `transactedge-terraform-state` bucket (see
   [SCRUM-23 verification](scrum-23-remote-state-verification.md)).

### 7. WAF/ALB blocking legitimate merchant traffic

**Response:**
1. Check AWS WAF sampled requests for the blocking rule (rate-based rule vs.
   managed rule group).
2. If a specific merchant integration is triggering a rate-based rule due to
   legitimate high-volume API usage, coordinate with payments-team on a scoped
   allowlist rather than disabling the rule broadly.

## Escalation

| Condition | Escalate to |
|---|---|
| Suspected security incident (WAF bypass, IAM privilege issue, secret exposure) | `security@transactedge.com` |
| Multi-service outage / suspected region event | Declare incident via PagerDuty + Slack `#incidents`; engage Leadership per [incident-management](https://github.com/transactedge/transactedge-docs) |
| Application-level defect once infra is confirmed healthy | Hand off to owning team's runbook |
| Production Terraform apply required outside change window | Platform lead + Security approval |

## Related Documentation

- [Architecture](architecture.md)
- [Deployment Pipeline](deployment-pipeline.md)
- [Disaster Recovery](disaster-recovery.md)
- [ADR Index](adr/)
- [payments-api runbook](https://github.com/transactedge/payments-api/blob/main/docs/runbook.md)
- [fraud-engine runbook](https://github.com/transactedge/fraud-engine/blob/main/docs/runbook.md)
- [merchant-portal runbook](https://github.com/transactedge/merchant-portal/blob/main/docs/runbook.md)
