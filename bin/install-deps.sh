#!/usr/bin/env bash
# install-deps.sh — друкує install-команду з manifest.md.
# Не інсталює сам — користувач копіює й виконує.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$SKILL_DIR/manifest.md"

# Extract install-command block
awk '/^## install-command/{flag=1; next} /^## /{flag=0} flag' "$MANIFEST" \
  | awk '/^```bash$/{f=1; next} /^```$/{f=0} f'

echo ""
echo "# Після встановлення:"
echo "bash $SKILL_DIR/bin/doctor.sh"
