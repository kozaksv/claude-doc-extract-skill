#!/usr/bin/env bash
# lib/pdf.sh — витягування тексту з PDF каскадом.
# Usage: extract_pdf <input> <output_text_file>
# Returns 0 on success (output has text), 10 if cascade exhausted.
# Env: MIN_CHARS (default 50), NO_OCR (0/1), LANG_OCR (default ukr+rus+eng)

# Sourced from extract.sh; common.sh already loaded.

extract_pdf() {
  local input="$1" out="$2"
  local min_chars="${MIN_CHARS:-50}"
  local no_ocr="${NO_OCR:-0}"
  local lang_ocr="${LANG_OCR:-ukr+rus+eng}"
  local method_chain=""
  local chars=0
  local extractor=""

  # --- Step 1: pdftotext ---
  if has_cmd pdftotext; then
    log_step "trying pdftotext..."
    if pdftotext -layout "$input" "$out" 2>/dev/null; then
      chars="$(count_chars "$out")"
      log_info "pdftotext: $chars chars"
      method_chain="pdftotext"
      if [ "$chars" -ge "$min_chars" ]; then
        extractor="pdftotext $(pdftotext -v 2>&1 | head -1 | awk '{print $NF}')"
        echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
        return 0
      fi
    fi
  else
    log_warn "pdftotext not installed"
  fi

  # --- Step 2: pdfminer.six ---
  if has_py_module pdfminer; then
    log_step "fallback: pdfminer.six..."
    python3 -c "
from pdfminer.high_level import extract_text
import sys
try:
    text = extract_text(sys.argv[1])
    with open(sys.argv[2], 'w') as f:
        f.write(text)
except Exception as e:
    sys.stderr.write(f'pdfminer error: {e}\n')
    sys.exit(1)
" "$input" "$out" 2>&1 >&2 || true
    chars="$(count_chars "$out" 2>/dev/null || echo 0)"
    log_info "pdfminer: $chars chars"
    method_chain="${method_chain:+$method_chain, }pdfminer"
    if [ "$chars" -ge "$min_chars" ]; then
      extractor="pdfminer.six"
      echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
      return 0
    fi
  fi

  # --- Step 3: OCR (if enabled) ---
  if [ "$no_ocr" = "1" ]; then
    log_warn "OCR disabled (--no-ocr); stopping"
    echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=none"
    return $EXIT_EXTRACTION_FAILED
  fi

  # Try ocrmypdf first (cleaner)
  if has_cmd ocrmypdf; then
    log_step "OCR with ocrmypdf (langs=$lang_ocr)..."
    local tmpdir; tmpdir="$(mktempdir)"
    local sidecar="$tmpdir/sidecar.txt"
    local ocrpdf="$tmpdir/ocr.pdf"
    # ocrmypdf prints progress to stderr — passthrough
    if ocrmypdf --sidecar "$sidecar" --language "$lang_ocr" \
         --force-ocr --skip-text 2>&1 \
         "$input" "$ocrpdf" >&2; then
      cp "$sidecar" "$out"
      chars="$(count_chars "$out")"
      log_info "ocrmypdf: $chars chars"
      method_chain="${method_chain:+$method_chain, }ocr"
      rm -rf "$tmpdir"
      if [ "$chars" -ge "$min_chars" ]; then
        extractor="ocrmypdf"
        echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
        return 0
      fi
    else
      log_warn "ocrmypdf failed, trying pdftoppm+tesseract fallback..."
      rm -rf "$tmpdir"
    fi
  fi

  # Fallback: pdftoppm + tesseract per page
  if has_cmd pdftoppm && has_cmd tesseract; then
    log_step "OCR fallback: pdftoppm+tesseract..."
    local tmpdir; tmpdir="$(mktempdir)"
    pdftoppm -r 300 "$input" "$tmpdir/page" -png 2>/dev/null
    : > "$out"
    local page_count; page_count="$(ls "$tmpdir"/page-*.png 2>/dev/null | wc -l)"
    local i=0
    for p in "$tmpdir"/page-*.png; do
      i=$((i+1))
      log_step "OCR page $i/$page_count..."
      tesseract -l "$lang_ocr" "$p" - 2>/dev/null >> "$out"
      echo "" >> "$out"
    done
    chars="$(count_chars "$out")"
    log_info "pdftoppm+tesseract: $chars chars over $page_count pages"
    method_chain="${method_chain:+$method_chain, }ocr-manual"
    rm -rf "$tmpdir"
    if [ "$chars" -ge "$min_chars" ]; then
      extractor="pdftoppm+tesseract"
      echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor|PAGES=$page_count"
      return 0
    fi
  fi

  # Exhausted
  echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=none"
  return $EXIT_EXTRACTION_FAILED
}
