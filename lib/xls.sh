#!/usr/bin/env bash
# lib/xls.sh — XLS → конверсія в XLSX через libreoffice, потім lib/xlsx.sh

extract_xls() {
  local input="$1" out="$2"

  if ! has_cmd libreoffice; then
    log_err "XLS потребує libreoffice для конверсії в XLSX"
    echo "CHAIN=|CHARS=0|EXTRACTOR=none"
    return $EXIT_MISSING_DEPENDENCY
  fi

  log_step "converting XLS → XLSX via libreoffice..."
  local tmpdir; tmpdir="$(mktempdir)"
  if ! libreoffice --headless --convert-to xlsx "$input" --outdir "$tmpdir" 2>&1 >&2; then
    rm -rf "$tmpdir"
    echo "CHAIN=libreoffice-fail|CHARS=0|EXTRACTOR=none"
    return $EXIT_EXTRACTION_FAILED
  fi

  local base; base="$(basename "$input" .xls)"
  local converted="$tmpdir/$base.xlsx"
  if [ ! -f "$converted" ]; then
    rm -rf "$tmpdir"
    echo "CHAIN=libreoffice-no-output|CHARS=0|EXTRACTOR=none"
    return $EXIT_EXTRACTION_FAILED
  fi

  # Delegate to lib/xlsx.sh (already sourced by extract.sh)
  local chain_out
  chain_out="$(extract_xlsx "$converted" "$out")"
  local rc=$?
  rm -rf "$tmpdir"

  # Prepend libreoffice to chain
  chain_out="$(echo "$chain_out" | sed 's/CHAIN=/CHAIN=libreoffice, /')"
  echo "$chain_out"
  return $rc
}
