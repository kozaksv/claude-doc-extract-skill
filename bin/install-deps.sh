#!/usr/bin/env bash
# install-deps.sh — друкує install-команду з manifest.md, з урахуванням ОС.
# Не інсталює сам — користувач копіює й виконує.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$SKILL_DIR/manifest.md"

# Визначаємо OS
case "$(uname -s)" in
  Darwin)  SECTION="install-command-brew" ;;
  Linux)   SECTION="install-command-apt" ;;
  *)       SECTION="install-command-apt" ;;  # fallback
esac

# Витягуємо bash-блок з відповідної секції
awk -v sec="## $SECTION" '
  $0 == sec { flag=1; next }
  /^## / { flag=0 }
  flag
' "$MANIFEST" | awk '/^```bash$/{f=1; next} /^```$/{f=0} f'

echo ""
echo "# Після встановлення:"
echo "bash $SKILL_DIR/bin/doctor.sh"
