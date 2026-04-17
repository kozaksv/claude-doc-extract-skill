#!/usr/bin/env bash
# lib/image.sh — OCR PNG/JPG/TIFF/WEBP через tesseract.
# extract_image <input> <output_text_file>

extract_image() {
  local input="$1" out="$2"
  local min_chars="${MIN_CHARS:-5}"  # images often sparse text
  local lang_ocr="${LANG_OCR:-ukr+rus+eng}"

  if ! has_cmd tesseract; then
    log_err "tesseract не встановлено. Запусти: bash <skill>/bin/install-deps.sh"
    echo "CHAIN=|CHARS=0|EXTRACTOR=none"
    return $EXIT_MISSING_DEPENDENCY
  fi

  log_step "OCR image (langs=$lang_ocr)..."
  if ! tesseract -l "$lang_ocr" --oem 1 --psm 3 "$input" - > "$out" 2>/dev/null; then
    # Fallback: без mode-tuning
    tesseract -l "$lang_ocr" "$input" - > "$out" 2>/dev/null || true
  fi

  local chars; chars="$(count_chars "$out" 2>/dev/null || echo 0)"
  if [ "$chars" -ge "$min_chars" ]; then
    echo "CHAIN=tesseract|CHARS=$chars|EXTRACTOR=tesseract"
    return 0
  fi
  echo "CHAIN=tesseract|CHARS=$chars|EXTRACTOR=none"
  return $EXIT_EXTRACTION_FAILED
}
