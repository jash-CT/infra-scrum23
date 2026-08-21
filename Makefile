.PHONY: help tf-fmt tf-validate tf-plan tf-apply tf-lint tf-bootstrap-validate tf-remote-state-test tf-lock-preflight helm-lint helm-template k8s-validate obs-up obs-down

ENV ?= dev
CHART ?= payments-api
AWS_REGION ?= us-east-1

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

tf-fmt: ## Format all Terraform files
	terraform fmt -recursive terraform/

tf-bootstrap-validate: ## Validate remote state bootstrap (no AWS backend)
	cd terraform/bootstrap && terraform init -backend=false -input=false && terraform validate

tf-remote-state-test: ## Run SCRUM-23 remote state contract tests
	python -m unittest discover -s tests/terraform -p 'test_*.py' -v

tf-validate: ## Validate Terraform for bootstrap and all environments
	@$(MAKE) tf-bootstrap-validate
	@for env in dev staging production; do \
		echo "==> Validating $$env"; \
		cd terraform/environments/$$env && terraform init -backend=false -input=false && terraform validate && cd -; \
	done

tf-plan: ## Run Terraform plan for ENV (default: dev)
	cd terraform/environments/$(ENV) && terraform init -input=false && terraform plan -var-file=terraform.tfvars

tf-apply: ## Run Terraform apply for ENV (default: dev)
	cd terraform/environments/$(ENV) && terraform init -input=false && terraform apply -var-file=terraform.tfvars

tf-lint: ## Run tflint on Terraform modules
	tflint --init
	tflint --recursive terraform/

helm-lint: ## Lint all Helm charts for all environments
	@for chart in payments-api fraud-engine merchant-portal; do \
		for env in dev staging production; do \
			echo "==> Linting $$chart ($$env)"; \
			helm lint helm/charts/$$chart -f helm/charts/$$chart/values-$$env.yaml; \
		done; \
	done

helm-template: ## Render Helm template for CHART and ENV
	helm template $(CHART) helm/charts/$(CHART) \
		-f helm/charts/$(CHART)/values-$(ENV).yaml \
		--namespace $(shell case $(CHART) in payments-api) echo payments;; fraud-engine) echo fraud;; merchant-portal) echo merchant;; esac)

k8s-validate: helm-template ## Validate rendered Kubernetes manifests
	helm template $(CHART) helm/charts/$(CHART) \
		-f helm/charts/$(CHART)/values-$(ENV).yaml | kubectl apply --dry-run=client -f -

obs-up: ## Start local Prometheus, Grafana, and Alertmanager stack
	docker compose up -d

obs-down: ## Stop local observability stack
	docker compose down

obs-logs: ## Tail observability stack logs
	docker compose logs -f

bootstrap-state-plan: ## Plan bootstrap remote state backend (review before apply)
	cd terraform/bootstrap && terraform init && terraform plan

tf-lock-preflight: ## Fail if DynamoDB still holds Terraform locks (state precondition)
	python scripts/check_terraform_locks.py

bootstrap-state: ## Bootstrap Terraform remote state backend (run once per account)
	@$(MAKE) tf-lock-preflight
	cd terraform/bootstrap && terraform init && terraform apply
