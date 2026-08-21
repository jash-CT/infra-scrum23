#!/usr/bin/env python3
"""Preflight: refuse bootstrap/env apply when DynamoDB still holds Terraform locks.

SCRUM-23 state_precondition — orphaned locks after aborted applies or provider
migrations must be cleared deliberately (force-unlock) before mutating state
backend resources.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys


DEFAULT_TABLE = "transactedge-terraform-locks"
DEFAULT_REGION = "us-east-1"


def _scan_locks(table: str, region: str) -> list[dict]:
    """Return DynamoDB items that look like active Terraform locks."""
    cmd = [
        "aws",
        "dynamodb",
        "scan",
        "--table-name",
        table,
        "--region",
        region,
        "--output",
        "json",
    ]
    try:
        raw = subprocess.check_output(cmd, stderr=subprocess.PIPE, text=True)
    except FileNotFoundError:
        print("ERROR: aws CLI not found; cannot verify lock preconditions.", file=sys.stderr)
        sys.exit(2)
    except subprocess.CalledProcessError as exc:
        # Table may not exist yet on first bootstrap — that is an allowed starting state.
        err = (exc.stderr or "").lower()
        if "resourcenotfoundexception" in err or "requested resource not found" in err:
            print(f"OK: lock table {table!r} does not exist yet (first bootstrap).")
            return []
        print(f"ERROR: dynamodb scan failed:\n{exc.stderr}", file=sys.stderr)
        sys.exit(2)

    payload = json.loads(raw or "{}")
    items = payload.get("Items") or []
    locks = []
    for item in items:
        lock_id = (item.get("LockID") or {}).get("S")
        if not lock_id:
            continue
        # Terraform stores lock metadata under Info; presence of LockID is enough.
        locks.append({"LockID": lock_id, "Info": (item.get("Info") or {}).get("S", "")})
    return locks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--table",
        default=os.environ.get("TF_LOCK_TABLE", DEFAULT_TABLE),
        help="DynamoDB lock table name",
    )
    parser.add_argument(
        "--region",
        default=os.environ.get("AWS_REGION", DEFAULT_REGION),
        help="AWS region",
    )
    parser.add_argument(
        "--allow-empty-only",
        action="store_true",
        default=True,
        help="Exit non-zero if any lock items are present (default).",
    )
    args = parser.parse_args()

    locks = _scan_locks(args.table, args.region)
    if not locks:
        print(f"OK: no active Terraform locks in {args.table!r}.")
        return 0

    print("BLOCKED: active Terraform lock(s) present — clear before mutating state backend:", file=sys.stderr)
    for lock in locks:
        print(f"  - LockID={lock['LockID']}", file=sys.stderr)
        if lock["Info"]:
            print(f"    Info={lock['Info'][:200]}", file=sys.stderr)
    print(
        "Confirm no apply is in progress, then: terraform force-unlock <lock-id>",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
