#!/usr/bin/env bash
# test/test-extract.sh — smoke test для всіх fixtures
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXTRACT="$SKILL_DIR/bin/extract.sh"
FIXTURES="$SKILL_DIR/test/fixtures"
OUT_DIR="$SKILL_DIR/test/output"

mkdir -p "$OUT_DIR"

pass_count=0
fail_count=0
skip_count=0

pass() { echo "  ✓ $1"; pass_count=$((pass_count+1)); }
fail() { echo "  ✗ $1" >&2; fail_count=$((fail_count+1)); }
skip() { echo "  ○ SKIP $1"; skip_count=$((skip_count+1)); }

# --- Test: digital PDF ---
echo "Test: digital.pdf"
if [ ! -f "$FIXTURES/digital.pdf" ]; then
  skip "fixture missing"
else
  out="$OUT_DIR/digital.md"
  if bash "$EXTRACT" "$FIXTURES/digital.pdf" --out "$out" 2>&1 >&2; then
    grep -q "ТЕСТ-МАРКЕР-PDF-1" "$out" && pass "marker found" || fail "marker missing"
    grep -q "^method_chain:" "$out" && pass "frontmatter present" || fail "frontmatter missing"
  else
    fail "extract failed"
  fi
fi

# --- Test: empty PDF → exit 10 ---
echo "Test: empty.pdf (should fail with exit 10)"
if [ ! -f "$FIXTURES/empty.pdf" ]; then
  skip "fixture missing"
else
  out="$OUT_DIR/empty.md"
  bash "$EXTRACT" "$FIXTURES/empty.pdf" --out "$out" --no-ocr 2>/dev/null
  rc=$?
  [ "$rc" = "10" ] && pass "exit 10 returned" || fail "wrong exit: $rc"
fi

# --- Test: DOCX ---
echo "Test: sample.docx"
if [ ! -f "$FIXTURES/sample.docx" ]; then
  skip "fixture missing"
else
  out="$OUT_DIR/docx.md"
  if bash "$EXTRACT" "$FIXTURES/sample.docx" --out "$out" 2>&1 >&2; then
    grep -q "ТЕСТ-МАРКЕР-DOCX-1" "$out" && pass "marker found" || fail "marker missing"
  else
    fail "extract failed"
  fi
fi

# --- Test: DOC ---
echo "Test: sample.doc"
if [ ! -f "$FIXTURES/sample.doc" ]; then
  skip "fixture missing (libreoffice?)"
else
  out="$OUT_DIR/doc.md"
  if bash "$EXTRACT" "$FIXTURES/sample.doc" --out "$out" 2>&1 >&2; then
    grep -q "ТЕСТ-МАРКЕР-DOCX-1" "$out" && pass "marker found" || fail "marker missing"
  else
    fail "extract failed"
  fi
fi

# --- Test: XLSX ---
echo "Test: sample.xlsx"
if [ ! -f "$FIXTURES/sample.xlsx" ]; then
  skip "fixture missing"
else
  out="$OUT_DIR/xlsx.md"
  if bash "$EXTRACT" "$FIXTURES/sample.xlsx" --out "$out" 2>&1 >&2; then
    grep -q "ТЕСТ-МАРКЕР-XLSX-1" "$out" && pass "marker found" || fail "marker missing"
  else
    fail "extract failed"
  fi
fi

# --- Test: XLS ---
echo "Test: sample.xls"
if [ ! -f "$FIXTURES/sample.xls" ]; then
  skip "fixture missing"
else
  out="$OUT_DIR/xls.md"
  if bash "$EXTRACT" "$FIXTURES/sample.xls" --out "$out" 2>&1 >&2; then
    grep -q "ТЕСТ-МАРКЕР-XLSX-1" "$out" && pass "marker found" || fail "marker missing"
  else
    fail "extract failed"
  fi
fi

# --- Test: PNG image (OCR) ---
echo "Test: cyrillic.png"
if [ ! -f "$FIXTURES/cyrillic.png" ]; then
  skip "fixture missing"
else
  out="$OUT_DIR/png.md"
  if bash "$EXTRACT" "$FIXTURES/cyrillic.png" --out "$out" 2>&1 >&2; then
    grep -qi "МАРКЕР" "$out" && pass "OCR marker found" || fail "OCR marker missing"
  else
    fail "extract failed"
  fi
fi

# --- Test: nonexistent → exit 40 ---
echo "Test: nonexistent → exit 40"
bash "$EXTRACT" /tmp/nonexistent-xyzzy.pdf 2>/dev/null
rc=$?
[ "$rc" = "40" ] && pass "exit 40 returned" || fail "wrong exit: $rc"

# --- Test: unsupported format → exit 30 ---
echo "Test: unsupported .xyz → exit 30"
touch "$OUT_DIR/bogus.xyz"
bash "$EXTRACT" "$OUT_DIR/bogus.xyz" 2>/dev/null
rc=$?
[ "$rc" = "30" ] && pass "exit 30 returned" || fail "wrong exit: $rc"

echo ""
echo "Summary: $pass_count passed, $fail_count failed, $skip_count skipped"
[ "$fail_count" = "0" ] || exit 1
