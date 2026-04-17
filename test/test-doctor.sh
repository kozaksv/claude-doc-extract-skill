#!/usr/bin/env bash
# Smoke-test for doctor.sh: runs it, checks that output has expected sections.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$("$SKILL_DIR/bin/doctor.sh" 2>&1 || true)"

pass() { echo "✓ $1"; }
fail() { echo "✗ $1" >&2; exit 1; }

echo "$OUTPUT" | grep -q "apt-packages:" || fail "missing apt-packages section"
pass "apt-packages section present"

echo "$OUTPUT" | grep -q "pip-packages" || fail "missing pip-packages section"
pass "pip-packages section present"

echo "$OUTPUT" | grep -q "Покриття форматів:" || fail "missing coverage section"
pass "coverage section present"

echo "$OUTPUT" | grep -qE "poppler-utils" || fail "missing poppler-utils in output"
pass "poppler-utils listed"

echo "$OUTPUT" | grep -qE "tesseract-ocr-ukr" || fail "missing tesseract-ocr-ukr"
pass "tesseract-ocr-ukr listed"

echo "All doctor tests passed."
