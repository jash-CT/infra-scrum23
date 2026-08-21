"""Contract tests for SCRUM-23 Terraform remote state (S3 + DynamoDB locking).

These tests do not require live AWS credentials. They assert the bootstrap and
environment HCL encode the mandatory remote-state controls.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
BOOTSTRAP_DIR = REPO_ROOT / "terraform" / "bootstrap"
ENVIRONMENTS = ("dev", "staging", "production")
WORKFLOWS_DIR = REPO_ROOT / ".github" / "workflows"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _backend_block(env_main: str) -> str:
    match = re.search(r'backend\s+"s3"\s*\{(.*?)\n\s*\}', env_main, re.DOTALL)
    if not match:
        raise AssertionError("S3 backend block not found")
    return match.group(1)


class RemoteStateBackendContractTests(unittest.TestCase):
    def test_bootstrap_enables_versioning(self) -> None:
        main = _read(BOOTSTRAP_DIR / "main.tf")
        self.assertIn('resource "aws_s3_bucket_versioning" "terraform_state"', main)
        self.assertRegex(main, r'status\s*=\s*"Enabled"')

    def test_bootstrap_uses_explicit_kms_cmk(self) -> None:
        main = _read(BOOTSTRAP_DIR / "main.tf")
        self.assertIn('resource "aws_kms_key" "terraform_state"', main)
        self.assertIn("enable_key_rotation", main)
        self.assertIn("kms_master_key_id", main)
        self.assertIn('sse_algorithm     = "aws:kms"', main)

    def test_bootstrap_dynamodb_lock_table(self) -> None:
        main = _read(BOOTSTRAP_DIR / "main.tf")
        self.assertIn('resource "aws_dynamodb_table" "terraform_locks"', main)
        self.assertIn('hash_key                    = "LockID"', main)
        self.assertIn("deletion_protection_enabled = true", main)
        self.assertIn("point_in_time_recovery", main)
        self.assertIn("server_side_encryption", main)

    def test_bootstrap_denies_insecure_transport(self) -> None:
        main = _read(BOOTSTRAP_DIR / "main.tf")
        self.assertIn("DenyInsecureTransport", main)
        self.assertIn('"aws:SecureTransport" = "false"', main)

    def test_bootstrap_ownership_and_public_access_block(self) -> None:
        main = _read(BOOTSTRAP_DIR / "main.tf")
        self.assertIn('object_ownership = "BucketOwnerEnforced"', main)
        self.assertIn("block_public_acls       = true", main)
        self.assertIn("restrict_public_buckets = true", main)

    def test_bootstrap_retains_noncurrent_versions(self) -> None:
        main = _read(BOOTSTRAP_DIR / "main.tf")
        self.assertIn("noncurrent_version_expiration", main)
        variables = _read(BOOTSTRAP_DIR / "variables.tf")
        self.assertIn("noncurrent_version_expiration_days", variables)

    def test_bootstrap_provider_constraint(self) -> None:
        versions = _read(BOOTSTRAP_DIR / "versions.tf")
        self.assertIn('version = "~> 6.57"', versions)

    def test_environment_backends_use_shared_bucket_and_locks(self) -> None:
        for env in ENVIRONMENTS:
            with self.subTest(env=env):
                main = _read(
                    REPO_ROOT / "terraform" / "environments" / env / "main.tf"
                )
                block = _backend_block(main)
                self.assertIn('bucket         = "transactedge-terraform-state"', block)
                self.assertIn(
                    f'key            = "environments/{env}/terraform.tfstate"',
                    block,
                )
                self.assertIn(
                    'dynamodb_table = "transactedge-terraform-locks"', block
                )
                self.assertIn("encrypt        = true", block)
                self.assertIn('region         = "us-east-1"', block)

    def test_environment_state_keys_are_isolated(self) -> None:
        keys = set()
        for env in ENVIRONMENTS:
            main = _read(REPO_ROOT / "terraform" / "environments" / env / "main.tf")
            block = _backend_block(main)
            match = re.search(r'key\s*=\s*"([^"]+)"', block)
            self.assertIsNotNone(match)
            keys.add(match.group(1))
        self.assertEqual(len(keys), len(ENVIRONMENTS))

    def test_ci_uses_oidc_not_static_aws_keys(self) -> None:
        for workflow_name in ("terraform-plan.yml", "terraform-apply.yml"):
            with self.subTest(workflow=workflow_name):
                content = _read(WORKFLOWS_DIR / workflow_name)
                self.assertIn("id-token: write", content)
                self.assertIn("role-to-assume:", content)
                self.assertNotIn("AWS_ACCESS_KEY_ID", content)
                self.assertNotIn("aws_secret_access_key", content.lower())

    def test_ci_posts_plan_comment_and_validates_bootstrap(self) -> None:
        plan = _read(WORKFLOWS_DIR / "terraform-plan.yml")
        self.assertIn("Comment PR with plan", plan)
        self.assertIn("bootstrap", plan.lower())
        self.assertIn("hashicorp/setup-terraform@v4", plan)
        self.assertIn("redact_terraform_plan.py", plan)

    def test_environment_providers_not_upgraded_by_bootstrap(self) -> None:
        """Provider ~> 6.57 is bootstrap-scoped; env stacks stay on ~> 5.40."""
        for env in ENVIRONMENTS:
            with self.subTest(env=env):
                main = _read(
                    REPO_ROOT / "terraform" / "environments" / env / "main.tf"
                )
                self.assertIn('version = "~> 5.40"', main)
                self.assertNotIn('version = "~> 6.57"', main)

    def test_lock_preflight_script_exists(self) -> None:
        script = REPO_ROOT / "scripts" / "check_terraform_locks.py"
        self.assertTrue(script.is_file())
        body = _read(script)
        self.assertIn("dynamodb", body)
        self.assertIn("LockID", body)

    def test_plan_redaction_script_exists(self) -> None:
        script = REPO_ROOT / "scripts" / "redact_terraform_plan.py"
        self.assertTrue(script.is_file())
        body = _read(script)
        self.assertIn("arn:aws:kms:[REDACTED]", body)
        self.assertIn("arn:aws:secretsmanager:[REDACTED]", body)


if __name__ == "__main__":
    unittest.main()
