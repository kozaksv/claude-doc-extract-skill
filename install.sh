#!/usr/bin/env bash
# install.sh — installer для doc-extract skill у ~/.claude/skills/doc-extract.
set -euo pipefail

TARGET="$HOME/.claude/skills/doc-extract"
REPO="https://github.com/kozaksv/claude-doc-extract-skill.git"

if [ -d "$TARGET/.git" ]; then
  echo "Updating existing doc-extract skill in $TARGET..."
  git -C "$TARGET" pull --ff-only
else
  echo "Installing doc-extract to $TARGET..."
  mkdir -p "$(dirname "$TARGET")"
  git clone "$REPO" "$TARGET"
fi

echo ""
echo "Done. Next steps:"
echo "  1. Діагностика:        bash $TARGET/bin/doctor.sh"
echo "  2. Install залежності: bash $TARGET/bin/install-deps.sh"
