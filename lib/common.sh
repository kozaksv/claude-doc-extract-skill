#!/usr/bin/env bash
# Common helpers: exit codes, logging, frontmatter generation.
# Source this from bin/extract.sh і lib/<format>.sh.

# --- Exit codes ---
readonly EXIT_SUCCESS=0
readonly EXIT_EXTRACTION_FAILED=10
readonly EXIT_MISSING_DEPENDENCY=20
readonly EXIT_UNSUPPORTED_FORMAT=30
readonly EXIT_INPUT_NOT_FOUND=40
readonly EXIT_INVALID_OPTIONS=50

# --- Logging (stderr, не stdout) ---
log_step() { printf '→ %s\n' "$*" >&2; }
log_info() { printf '  %s\n' "$*" >&2; }
log_warn() { printf '⚠ %s\n' "$*" >&2; }
log_err()  { printf '✗ %s\n' "$*" >&2; }
log_ok()   { printf '✓ %s\n' "$*" >&2; }

# --- Verbose mode ---
VERBOSE="${VERBOSE:-0}"
log_verbose() { [ "$VERBOSE" = "1" ] && printf '    %s\n' "$*" >&2 || true; }

# --- Dependency check ---
# has_cmd <cmd> — 0 if available, 1 if not
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# has_py_module <module> — 0 if importable, 1 if not
has_py_module() {
  python3 -c "import $1" 2>/dev/null
}

# require_cmd <cmd> <package-name>
# Exits with EXIT_MISSING_DEPENDENCY if not available.
# Package name is passed generically; run install-deps.sh for OS-specific command.
require_cmd() {
  if ! has_cmd "$1"; then
    log_err "Missing command: $1 (package: $2). Run: bash <skill>/bin/install-deps.sh"
    return 1
  fi
  return 0
}

# --- Character counting ---
# count_chars <file> — prints number of non-whitespace characters
count_chars() {
  # Use awk для stability across locales
  awk 'BEGIN{n=0} {gsub(/[[:space:]]/,""); n+=length($0)} END{print n}' "$1"
}

# --- Frontmatter generation ---
# write_frontmatter <out_file> <source> <extractor> <pages> <chars> <method_chain>
# Writes YAML frontmatter до out_file (overwrite).
write_frontmatter() {
  local out="$1" source="$2" extractor="$3" pages="$4" chars="$5" method_chain="$6"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  {
    echo "---"
    echo "source: $source"
    echo "extracted_at: $ts"
    echo "extractor: $extractor"
    echo "pages: $pages"
    echo "chars: $chars"
    echo "method_chain: [$method_chain]"
    echo "---"
    echo ""
  } > "$out"
}

# --- Temp directory ---
# mktempdir — creates a temp dir, echoes path. Caller must clean up.
mktempdir() {
  mktemp -d -t doc-extract.XXXXXX
}
