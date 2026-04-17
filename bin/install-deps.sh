#!/usr/bin/env bash
# install-deps.sh — друкує install-команду з manifest.md.
# Не інсталює сам — користувач копіює й виконує.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$SKILL_DIR/manifest.md"

# Extract install-command block
awk '/^## install-command/,/^## /' "$MANIFEST" \
  | awk '/^```bash$/,/^```$/' \
  | sed '1d;$d'

echo ""
echo "# Після встановлення:"
echo "bash $SKILL_DIR/bin/doctor.sh"
