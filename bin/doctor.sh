#!/usr/bin/env bash
# doctor.sh — перевірка залежностей doc-extract за manifest.md.
# Exit codes: 0=full, 1=degraded, 2=missing coverage.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$SKILL_DIR/lib/common.sh"

MANIFEST="$SKILL_DIR/manifest.md"

if [ ! -f "$MANIFEST" ]; then
  log_err "manifest.md not found at $MANIFEST"
  exit 2
fi

# --- Determine OS → choose system-package section ---
case "$(uname -s)" in
  Darwin)  SYS_SECTION="brew-packages";   SYS_LABEL="brew-packages" ;;
  Linux)   SYS_SECTION="apt-packages";    SYS_LABEL="apt-packages" ;;
  *)       SYS_SECTION="apt-packages";    SYS_LABEL="apt-packages" ;;
esac

# --- Parse manifest.md ---
sys_packages=()
while IFS= read -r line; do
  pkg="$(echo "$line" | sed -E 's/^-[[:space:]]*([a-zA-Z0-9_.-]+).*/\1/')"
  sys_packages+=("$pkg")
done < <(awk -v sec="## $SYS_SECTION" '$0==sec{flag=1; next} /^## /{flag=0} flag' "$MANIFEST" | grep -E '^-[[:space:]]')

# На macOS додаємо cask-пакети (libreoffice)
if [ "$SYS_SECTION" = "brew-packages" ]; then
  while IFS= read -r line; do
    pkg="$(echo "$line" | sed -E 's/^-[[:space:]]*([a-zA-Z0-9_.-]+).*/\1/')"
    sys_packages+=("$pkg")
  done < <(awk '/^## brew-casks/{flag=1; next} /^## /{flag=0} flag' "$MANIFEST" | grep -E '^-[[:space:]]')
fi

pip_packages=()
while IFS= read -r line; do
  pkg="$(echo "$line" | sed -E 's/^-[[:space:]]*([a-zA-Z0-9_.-]+).*/\1/')"
  pip_packages+=("$pkg")
done < <(awk '/^## pip-packages/{flag=1; next} /^## /{flag=0} flag' "$MANIFEST" | grep -E '^-[[:space:]]')

# --- Mapping: package → command/tesseract-data to test ---
# Використовуємо case-функції замість declare -A (bash 3.2 compat, macOS).

apt_cmd_spec() {
  case "$1" in
    poppler-utils)     echo "pdftotext" ;;
    libreoffice-core)  echo "libreoffice" ;;
    tesseract-ocr)     echo "tesseract" ;;
    tesseract-ocr-ukr) echo "TESSDATA:ukr" ;;
    tesseract-ocr-rus) echo "TESSDATA:rus" ;;
    tesseract-ocr-eng) echo "TESSDATA:eng" ;;
    *) echo "$1" ;;
  esac
}

brew_cmd_spec() {
  case "$1" in
    poppler)        echo "pdftotext" ;;
    tesseract-lang) echo "TESSDATA:ukr,rus,eng" ;;
    *) echo "$1" ;;
  esac
}

get_cmd_spec() {
  if [ "$SYS_SECTION" = "brew-packages" ]; then
    brew_cmd_spec "$1"
  else
    apt_cmd_spec "$1"
  fi
}

check_sys_package() {
  local pkg="$1"
  local spec; spec="$(get_cmd_spec "$pkg")"
  if [[ "$spec" == TESSDATA:* ]]; then
    local langs="${spec#TESSDATA:}"
    has_cmd tesseract || return 1
    local installed; installed="$(tesseract --list-langs 2>&1)"
    # Пропускаємо всі мови через перевірку — всі мають бути
    local IFS=','
    for lang in $langs; do
      echo "$installed" | grep -qx "$lang" || return 1
    done
    return 0
  fi
  has_cmd "$spec"
}

get_version() {
  local cmd="$1"
  case "$cmd" in
    pdftotext)    pdftotext -v 2>&1 | head -1 | awk '{print $NF}' ;;
    pandoc)       pandoc --version | head -1 | awk '{print $2}' ;;
    tesseract)    tesseract --version 2>&1 | head -1 | awk '{print $2}' ;;
    libreoffice)  libreoffice --version 2>/dev/null | awk '{print $2}' ;;
    antiword)     antiword 2>&1 | head -1 | awk '{print $NF}' ;;
    catdoc)       catdoc -v 2>&1 | head -1 | awk '{print $NF}' ;;
    ocrmypdf)     ocrmypdf --version 2>&1 | head -1 ;;
    *)            echo "?" ;;
  esac
}

# --- Output ---
echo "doc-extract doctor"
echo ""
echo "${SYS_LABEL}:"

degraded=0
missing=0

for pkg in "${sys_packages[@]}"; do
  if check_sys_package "$pkg"; then
    spec="$(get_cmd_spec "$pkg")"
    if [[ "$spec" == TESSDATA:* ]]; then
      printf "  ✓ %-22s %s\n" "$pkg" "(tesseract lang data)"
    else
      version="$(get_version "$spec" 2>/dev/null || echo "?")"
      printf "  ✓ %-22s %s\n" "$pkg" "$version"
    fi
  else
    printf "  ✗ %-22s %s\n" "$pkg" "НЕ встановлено"
    missing=1
  fi
done

echo ""
echo "pip-packages (python3):"

pip_module_for() {
  case "$1" in
    pdfminer.six) echo "pdfminer" ;;
    python-docx)  echo "docx" ;;
    *) echo "${1%%.*}" ;;
  esac
}

for pkg in "${pip_packages[@]}"; do
  module="$(pip_module_for "$pkg")"
  if python3 -c "import $module" 2>/dev/null; then
    version="$(python3 -c "import $module; print(getattr($module, '__version__', '?'))" 2>/dev/null)"
    printf "  ✓ %-22s %s\n" "$pkg" "$version"
  else
    printf "  ✗ %-22s %s\n" "$pkg" "НЕ встановлено"
    missing=1
  fi
done

# --- Coverage-matrix ---
echo ""
echo "Покриття форматів:"

coverage_status() {
  local primary="$1"; shift
  local -a fallbacks=("$@")
  if check_tool "$primary"; then
    for fb in "${fallbacks[@]}"; do
      check_tool "$fb" || { echo "⚠ primary OK, fallback ($fb) нема"; return 1; }
    done
    echo "✓"
    return 0
  else
    echo "✗ primary ($primary) відсутній"
    return 2
  fi
}

check_tool() {
  case "$1" in
    pdftotext|pandoc|tesseract|libreoffice|antiword|catdoc|ocrmypdf) has_cmd "$1" ;;
    pdfminer.six)    has_py_module pdfminer ;;
    python-docx)     has_py_module docx ;;
    openpyxl)        has_py_module openpyxl ;;
    xlsx2csv)        has_py_module xlsx2csv ;;
    pdfplumber)      has_py_module pdfplumber ;;
    pdftoppm+tesseract)  has_cmd pdftoppm && has_cmd tesseract ;;
    *) return 1 ;;
  esac
}

printf "  %-14s %s\n" "PDF (text)"   "$(coverage_status pdftotext pdfminer.six)"
printf "  %-14s %s\n" "PDF (scan)"   "$(coverage_status ocrmypdf 'pdftoppm+tesseract')"
printf "  %-14s %s\n" "DOCX"         "$(coverage_status pandoc python-docx)"
printf "  %-14s %s\n" "DOC"          "$(coverage_status libreoffice antiword catdoc)"
printf "  %-14s %s\n" "XLSX"         "$(coverage_status xlsx2csv openpyxl)"
printf "  %-14s %s\n" "XLS"          "$(coverage_status libreoffice)"
printf "  %-14s %s\n" "Images"       "$(coverage_status tesseract)"

echo ""
if [ "$missing" = "1" ]; then
  echo "Для повного покриття виконай install-deps:"
  echo "  bash $SKILL_DIR/bin/install-deps.sh"
  exit 2
else
  echo "Повне покриття. Все OK."
  exit 0
fi
