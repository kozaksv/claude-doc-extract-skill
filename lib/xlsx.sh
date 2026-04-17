#!/usr/bin/env bash
# lib/xlsx.sh — витягування тексту з XLSX як TSV.
# extract_xlsx <input> <output_text_file>

extract_xlsx() {
  local input="$1" out="$2"
  local min_chars="${MIN_CHARS:-10}"  # XLSX can be sparse, lower threshold
  local method_chain=""
  local chars=0
  local extractor=""

  # Primary: xlsx2csv
  if has_py_module xlsx2csv; then
    log_step "trying xlsx2csv..."
    python3 -m xlsx2csv --all "$input" > "$out" 2>/dev/null || true
    chars="$(count_chars "$out" 2>/dev/null || echo 0)"
    method_chain="xlsx2csv"
    if [ "$chars" -ge "$min_chars" ]; then
      extractor="xlsx2csv"
      echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
      return 0
    fi
  fi

  # Fallback: openpyxl
  if has_py_module openpyxl; then
    log_step "fallback: openpyxl..."
    python3 -c "
from openpyxl import load_workbook
import sys
wb = load_workbook(sys.argv[1], data_only=True, read_only=True)
with open(sys.argv[2], 'w') as f:
    for name in wb.sheetnames:
        ws = wb[name]
        f.write(f'=== Sheet: {name} ===\n')
        for row in ws.iter_rows(values_only=True):
            f.write('\t'.join('' if v is None else str(v) for v in row) + '\n')
        f.write('\n')
" "$input" "$out" 2>&1 >&2 || true
    chars="$(count_chars "$out" 2>/dev/null || echo 0)"
    method_chain="${method_chain:+$method_chain, }openpyxl"
    if [ "$chars" -ge "$min_chars" ]; then
      extractor="openpyxl"
      echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
      return 0
    fi
  fi

  echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=none"
  return $EXIT_EXTRACTION_FAILED
}
