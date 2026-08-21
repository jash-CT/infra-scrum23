# SCRUM-23: Remote State Staging Verification

## Purpose

Verify that Terraform remote state uses the shared S3 backend with DynamoDB
locking, and that versioning supports rollback. This checklist produces SOC 2
evidence for control continuity (plan review + state integrity).

## Prerequisites

1. Bootstrap applied once in the AWS account (`make bootstrap-state` or
   `terraform apply` under `terraform/bootstrap`).
2. Operator has permission to assume `te-github-actions-terraform` (or an
   equivalent platform role) via SSO/OIDC — **no long-lived access keys**.
3. Staging environment directory: `terraform/environments/staging`.
4. **State precondition:** before bootstrap apply or force-unlock, run
   `make tf-lock-preflight` (or `python scripts/check_terraform_locks.py`).
   Apply is blocked while any DynamoDB `LockID` items remain.

## Verification Steps

### 1. Backend init against remote state

```bash
cd terraform/environments/staging
terraform init -input=false
```

Expect: successful init against `transactedge-terraform-state` with key
`environments/staging/terraform.tfstate` and DynamoDB table
`transactedge-terraform-locks`.

### 2. Confirm locking prevents concurrent modification

In terminal A:

```bash
terraform plan -var-file=terraform.tfvars -lock-timeout=0s
# While plan/apply holds the lock, leave a long-running apply if needed:
# terraform apply -var-file=terraform.tfvars
```

In terminal B (while A holds the lock):

```bash
terraform plan -var-file=terraform.tfvars -lock-timeout=0s
```

Expect: terminal B fails with a state lock error referencing the DynamoDB
`LockID` for the staging state key.

### 3. Confirm state versioning (rollback capability)

```bash
aws s3api get-bucket-versioning --bucket transactedge-terraform-state
aws s3api list-object-versions \
  --bucket transactedge-terraform-state \
  --prefix environments/staging/terraform.tfstate
```

Expect: `Status=Enabled`, and after at least one successful apply, one or more
versions of the staging state object exist.

### 4. Confirm encryption

```bash
aws s3api get-bucket-encryption --bucket transactedge-terraform-state
```

Expect: SSE-KMS with the bootstrap CMK (alias matching
`transactedge-terraform-state`).

## Automated coverage

Run without AWS credentials:

```bash
make tf-remote-state-test
```

CI (`terraform-plan.yml`) validates bootstrap HCL and posts environment
`terraform plan` output as a PR comment. No `terraform apply` runs from pull
requests.

## Evidence to attach

- CI run URL for bootstrap validate + staging plan comment
- Screenshot or CLI output of lock contention from step 2
- `get-bucket-versioning` / `list-object-versions` output from step 3

## Makefile shortcuts
- `make tf-remote-state-test` — contract tests (no AWS)
- `make tf-bootstrap-validate` — validate bootstrap HCL locally
- `make tf-lock-preflight` — check DynamoDB locks before apply
