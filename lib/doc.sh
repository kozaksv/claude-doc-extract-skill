#!/usr/bin/env bash
# lib/doc.sh — витягування тексту з legacy DOC.
# extract_doc <input> <output_text_file>

extract_doc() {
  local input="$1" out="$2"
  local min_chars="${MIN_CHARS:-50}"
  local method_chain=""
  local chars=0
  local extractor=""

  # Primary: libreoffice --convert-to txt
  if has_cmd libreoffice; then
    log_step "trying libreoffice..."
    local tmpdir; tmpdir="$(mktempdir)"
    if libreoffice --headless --convert-to txt "$input" --outdir "$tmpdir" 2>&1 >&2; then
      local base; base="$(basename "$input" .doc)"
      local produced="$tmpdir/$base.txt"
      if [ -f "$produced" ]; then
        cp "$produced" "$out"
        chars="$(count_chars "$out")"
        method_chain="libreoffice"
        rm -rf "$tmpdir"
        if [ "$chars" -ge "$min_chars" ]; then
          extractor="libreoffice"
          echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
          return 0
        fi
      fi
    fi
    rm -rf "$tmpdir"
  fi

  # Fallback: antiword
  if has_cmd antiword; then
    log_step "fallback: antiword..."
    if antiword "$input" > "$out" 2>/dev/null; then
      chars="$(count_chars "$out")"
      method_chain="${method_chain:+$method_chain, }antiword"
      if [ "$chars" -ge "$min_chars" ]; then
        extractor="antiword"
        echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
        return 0
      fi
    fi
  fi

  # Last-resort: catdoc
  if has_cmd catdoc; then
    log_step "last-resort: catdoc..."
    if catdoc "$input" > "$out" 2>/dev/null; then
      chars="$(count_chars "$out")"
      method_chain="${method_chain:+$method_chain, }catdoc"
      if [ "$chars" -ge "$min_chars" ]; then
        extractor="catdoc"
        echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=$extractor"
        return 0
      fi
    fi
  fi

  echo "CHAIN=$method_chain|CHARS=$chars|EXTRACTOR=none"
  return $EXIT_EXTRACTION_FAILED
}
