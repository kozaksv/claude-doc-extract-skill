#!/usr/bin/env bash
# extract.sh — dispatcher for doc-extract.
# See --help або README.md for usage.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SKILL_DIR/lib/common.sh"

source "$SKILL_DIR/lib/pdf.sh"
source "$SKILL_DIR/lib/docx.sh"
source "$SKILL_DIR/lib/doc.sh"
source "$SKILL_DIR/lib/xlsx.sh"
source "$SKILL_DIR/lib/xls.sh"
source "$SKILL_DIR/lib/image.sh"

# --- Args ---
INPUT=""
OUT=""
FORMAT="md"
LANG_OCR="ukr+rus+eng"
MIN_CHARS="50"
NO_OCR="0"
TABLES="0"
VERBOSE="0"
DRY_RUN="0"

show_help() {
  cat <<EOF
extract.sh INPUT [options]

Options:
  --out FILE          записати в файл (інакше stdout)
  --format md|txt|json (default: md)
  --lang CODES        OCR languages (default: ukr+rus+eng)
  --min-chars N       поріг success (default: 50)
  --no-ocr            заборонити OCR-гілку
  --tables            pdfplumber для таблиць (not implemented in v1)
  --verbose
  --dry-run
  -h, --help

Exit codes:
  0   success
  10  extraction_failed
  20  missing_dependency
  30  unsupported_format
  40  input_not_found
  50  invalid_options
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --out)       OUT="$2"; shift 2 ;;
    --format)    FORMAT="$2"; shift 2 ;;
    --lang)      LANG_OCR="$2"; shift 2 ;;
    --min-chars) MIN_CHARS="$2"; shift 2 ;;
    --no-ocr)    NO_OCR="1"; shift ;;
    --tables)    TABLES="1"; shift ;;
    --verbose)   VERBOSE="1"; shift ;;
    --dry-run)   DRY_RUN="1"; shift ;;
    -h|--help)   show_help; exit 0 ;;
    -*)          log_err "Unknown option: $1"; show_help; exit $EXIT_INVALID_OPTIONS ;;
    *)           [ -z "$INPUT" ] && INPUT="$1" || { log_err "Extra arg: $1"; exit $EXIT_INVALID_OPTIONS; }
                 shift ;;
  esac
done

export VERBOSE MIN_CHARS NO_OCR LANG_OCR

# --- Validation ---
if [ -z "$INPUT" ]; then
  log_err "INPUT not specified"
  show_help
  exit $EXIT_INVALID_OPTIONS
fi

if [ ! -f "$INPUT" ]; then
  log_err "Input not found: $INPUT"
  exit $EXIT_INPUT_NOT_FOUND
fi

case "$FORMAT" in
  md|txt|json) ;;
  *) log_err "Invalid --format: $FORMAT (use md|txt|json)"; exit $EXIT_INVALID_OPTIONS ;;
esac

# --- Dispatch по extension ---
ext="$(echo "${INPUT##*.}" | tr '[:upper:]' '[:lower:]')"

if [ "$DRY_RUN" = "1" ]; then
  log_info "dry-run: ext=$ext, input=$INPUT, out=${OUT:-stdout}, format=$FORMAT"
  exit 0
fi

# Temp output for raw text
TMPTXT="$(mktemp -t doc-extract.XXXXXX.txt)"
trap "rm -f $TMPTXT" EXIT

case "$ext" in
  pdf)         chain_info="$(extract_pdf "$INPUT" "$TMPTXT")"; rc=$? ;;
  docx)        chain_info="$(extract_docx "$INPUT" "$TMPTXT")"; rc=$? ;;
  doc)         chain_info="$(extract_doc "$INPUT" "$TMPTXT")"; rc=$? ;;
  xlsx)        chain_info="$(extract_xlsx "$INPUT" "$TMPTXT")"; rc=$? ;;
  xls)         chain_info="$(extract_xls "$INPUT" "$TMPTXT")"; rc=$? ;;
  png|jpg|jpeg|tiff|webp)
               chain_info="$(extract_image "$INPUT" "$TMPTXT")"; rc=$? ;;
  *)
    log_err "Unsupported format: .$ext"
    exit $EXIT_UNSUPPORTED_FORMAT
    ;;
esac

# Parse chain_info: CHAIN=...|CHARS=N|EXTRACTOR=name[|PAGES=N]
chain="$(echo "$chain_info" | sed -E 's/.*CHAIN=([^|]*).*/\1/')"
chars="$(echo "$chain_info" | sed -E 's/.*CHARS=([^|]*).*/\1/')"
extractor="$(echo "$chain_info" | sed -E 's/.*EXTRACTOR=([^|]*).*/\1/')"
pages="$(echo "$chain_info" | grep -oE 'PAGES=[0-9]+' | cut -d= -f2 || echo "?")"
[ -z "$pages" ] && pages="?"

if [ "$rc" != "0" ]; then
  log_err "extraction_failed: chain=[$chain] chars=$chars"
  exit "$rc"
fi

# --- Emit output ---
emit() {
  if [ -z "$OUT" ]; then
    cat "$TMPTXT"
  else
    if [ "$FORMAT" = "md" ]; then
      write_frontmatter "$OUT" "$INPUT" "$extractor" "$pages" "$chars" "$chain"
      cat "$TMPTXT" >> "$OUT"
    elif [ "$FORMAT" = "txt" ]; then
      cp "$TMPTXT" "$OUT"
    elif [ "$FORMAT" = "json" ]; then
      python3 -c "
import json, sys
with open('$TMPTXT') as f:
    text = f.read()
data = {
  'source': '$INPUT',
  'extractor': '$extractor',
  'pages': '$pages',
  'chars': $chars,
  'method_chain': '$chain'.split(', '),
  'text': text,
}
with open('$OUT', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
"
    fi
  fi
}

emit
log_ok "success: chain=[$chain] chars=$chars"
exit 0
