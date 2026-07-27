# ADR-001: EKS vs ECS for Container Orchestration

## Status

Accepted

## Date

2025-03-15

## Context

TransactEdge requires a container orchestration platform to run payments-api (Go), fraud-engine (Python), and merchant-portal (Next.js) across dev, staging, and production environments. The platform must support:

- Horizontal pod autoscaling based on CPU, memory, and custom metrics
- Service mesh readiness for future mTLS between services
- GitOps-compatible deployment workflows (Helm)
- IRSA for least-privilege AWS access from pods
- PCI DSS compliance for payment processing workloads

Two AWS-native options were evaluated: Amazon EKS (managed Kubernetes) and Amazon ECS (with Fargate).

## Decision

We will use **Amazon EKS** with managed node groups for all application workloads.

## Rationale

| Criterion | EKS | ECS |
|---|---|---|
| Ecosystem (Helm, Prometheus Operator, External Secrets) | Native Kubernetes ecosystem | Limited; requires custom tooling |
| Autoscaling | HPA + Cluster Autoscaler + Karpenter option | Service Auto Scaling (CPU/memory only) |
| Observability | ServiceMonitor CRDs, kube-state-metrics | CloudWatch Container Insights |
| Multi-cloud portability | Kubernetes API is portable | AWS-specific |
| Team expertise | Platform team has Kubernetes experience | Would require new skill investment |
| IRSA | First-class support | Task role per task definition |
| Cost | Control plane: $0.10/hr per cluster | No control plane fee (Fargate per-task pricing) |

EKS provides the richest ecosystem for observability (Prometheus/Grafana via kube-prometheus-stack), secrets management (External Secrets Operator), and ingress (AWS Load Balancer Controller). The Kubernetes API is an industry standard that simplifies hiring and onboarding.

ECS Fargate eliminates node management but lacks the CRD-based tooling ecosystem that TransactEdge's observability and secrets strategy depends on.

## Consequences

### Positive

- Full Helm chart support for application deployments
- Native integration with Prometheus Operator, External Secrets Operator, and AWS Load Balancer Controller
- Horizontal Pod Autoscaler with custom metrics (payment throughput, Kafka lag)
- Portable skill set across cloud providers if needed

### Negative

- EKS control plane cost ($0.10/hr × 3 environments = ~$220/month)
- Node management overhead (mitigated by managed node groups and future Karpenter adoption)
- Kubernetes complexity requires dedicated platform engineering investment

### Neutral

- AWS Load Balancer Controller required for Ingress (same as ECS with ALB)
- Cluster upgrades must be planned and tested per environment

## Alternatives Considered

1. **ECS with Fargate** — Rejected due to limited observability and secrets ecosystem
2. **Self-managed Kubernetes on EC2** — Rejected; EKS control plane management is worth the cost
3. **EKS with Fargate profiles** — Considered for future stateless workloads; managed node groups chosen for initial deployment due to DaemonSet requirements (node-exporter, fluent-bit)
