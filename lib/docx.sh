#!/usr/bin/env bash
# lib/docx.sh — витягування тексту з DOCX.
# extract_docx <input> <output_text_file>

extract_docx() {
  local input="$1" out="$2"
  local min_chars="${MIN_CHARS:-20}"
  local method_chain=""
  local chars=0
  local extractor=""

  # Primary: pandoc
  if has_cmd pandoc; then
    log_step "trying pandoc..."
    if pandoc -f docx -t plain "$input" -o "$out" 2>/dev/null; then
      chars="$(count_chars "$out")"
      method_chain="pandoc"
      if [ "$chars" -ge "$min_chars" ]; then
        extractor="pandoc $(pandoc --version | head -1 | awk '{print $2}')"
        echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
        return 0
      fi
    fi
  fi

  # Fallback: python-docx
  if has_py_module docx; then
    log_step "fallback: python-docx..."
    python3 -c "
from docx import Document
import sys
doc = Document(sys.argv[1])
with open(sys.argv[2], 'w') as f:
    for p in doc.paragraphs:
        f.write(p.text + '\n')
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                f.write(cell.text + '\t')
            f.write('\n')
" "$input" "$out" 2>&1 >&2 || true
    chars="$(count_chars "$out" 2>/dev/null || echo 0)"
    method_chain="${method_chain:+$method_chain, }python-docx"
    if [ "$chars" -ge "$min_chars" ]; then
      extractor="python-docx"
      echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
      return 0
    fi
  fi

  echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=none"
  return $EXIT_EXTRACTION_FAILED
}
