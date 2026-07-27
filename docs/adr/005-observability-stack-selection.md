# ADR-005: Observability Stack Selection

## Status

Accepted

## Date

2025-04-08

## Context

TransactEdge requires comprehensive observability for a PCI-regulated payments platform running payments-api, fraud-engine, and merchant-portal on EKS. Requirements include:

- Application metrics (latency, error rates, throughput)
- Infrastructure metrics (CPU, memory, pod restarts)
- Kafka consumer lag monitoring
- Database connection and replication lag monitoring
- Alerting with severity-based routing to Slack and PagerDuty
- Dashboards for on-call engineers and service owners

We evaluated self-hosted Prometheus/Grafana against AWS-managed alternatives.

## Decision

We will deploy a **self-hosted Prometheus + Grafana + Alertmanager** stack on EKS, managed via kube-prometheus-stack Helm chart, supplemented by AWS CloudWatch for infrastructure-level metrics.

## Rationale

| Criterion | Prometheus/Grafana (self-hosted) | Amazon Managed Grafana + AMP |
|---|---|---|
| Cost (3 environments) | ~$200/month (compute for Prometheus) | ~$500+/month (AMP + AMG licensing) |
| PromQL compatibility | Native | AMP supports PromQL |
| Custom metrics | Full control over scrape configs and recording rules | Limited customization |
| Alertmanager integration | Native | Requires SNS/Lambda bridge |
| Dashboard portability | Grafana JSON dashboards in Git | AMG dashboards (less portable) |
| Vendor lock-in | Low (Prometheus is CNCF standard) | High (AWS-specific) |
| ServiceMonitor CRDs | Native Kubernetes integration | Not applicable |

Self-hosted Prometheus on EKS provides full control over scrape configurations, recording rules, and alert definitions. Grafana dashboards are version-controlled in this repository (`grafana/dashboards/`). Alertmanager routing rules map directly to TransactEdge's on-call structure (payments, risk, platform teams).

AWS Managed Prometheus and Grafana were evaluated but rejected due to higher cost, reduced customization, and the team's existing Prometheus expertise.

CloudWatch remains in use for AWS service metrics (RDS, MSK, ALB) and as a secondary alerting path via CloudWatch Alarms for infrastructure-level events.

## Consequences

### Positive

- Dashboards and alert rules version-controlled in Git
- PromQL is portable across environments and future multi-region setup
- ServiceMonitor CRDs provide declarative scrape configuration per Helm chart
- Local development via docker-compose enables dashboard validation before deploy

### Negative

- Prometheus storage management (retention, compaction) is our responsibility
- High-availability Prometheus requires Thanos or Cortex (planned for production scale)
- Self-hosted Grafana requires backup of dashboard state (mitigated by Git-based provisioning)

## Alternatives Considered

1. **Amazon Managed Prometheus + Amazon Managed Grafana** — Rejected due to cost and customization limits
2. **Datadog** — Evaluated; rejected due to cost at scale (~$15/host/month × 20+ hosts × 3 environments)
3. **Grafana Cloud** — Considered as future option if self-hosted operational burden grows
