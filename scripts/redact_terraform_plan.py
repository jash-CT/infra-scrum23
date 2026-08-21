#!/usr/bin/env python3
"""Redact sensitive identifiers from Terraform plan text before logging/PR comments."""

from __future__ import annotations

import re
import sys

PATTERNS: list[tuple[str, str]] = [
    (r"arn:aws:kms:[^\s\"'\\]+", "arn:aws:kms:[REDACTED]"),
    (r"arn:aws:secretsmanager:[^\s\"'\\]+", "arn:aws:secretsmanager:[REDACTED]"),
    (r"arn:aws:iam::[0-9]+:(role|user|policy)/[^\s\"'\\]+", r"arn:aws:iam::[REDACTED]:\1/[REDACTED]"),
    (r"arn:aws:sts::[0-9]+:[^\s\"'\\]+", "arn:aws:sts::[REDACTED]"),
    (r"AKIA[0-9A-Z]{16}", "AKIA[REDACTED]"),
    (
        r"(?<=[\"'])[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(?=[\"'])",
        "[REDACTED-UUID]",
    ),
]


def redact(text: str) -> str:
    for pat, repl in PATTERNS:
        text = re.sub(pat, repl, text, flags=re.IGNORECASE)
    return text


def main() -> int:
    sys.stdout.write(redact(sys.stdin.read()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
