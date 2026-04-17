#!/usr/bin/env bash
# Генерує тестові фікстури з простих джерел. Запускається раз при розробці.
set -euo pipefail
cd "$(dirname "$0")"

MARKER_PDF="ТЕСТ-МАРКЕР-PDF-1"
MARKER_DOCX="ТЕСТ-МАРКЕР-DOCX-1"
MARKER_DOC="ТЕСТ-МАРКЕР-DOC-1"
MARKER_XLSX="ТЕСТ-МАРКЕР-XLSX-1"
MARKER_XLS="ТЕСТ-МАРКЕР-XLS-1"
MARKER_IMG="ТЕСТ-МАРКЕР-PNG-1"

# 1. digital.pdf — через pandoc з markdown
echo "# Digital PDF" > /tmp/src.md
echo "$MARKER_PDF" >> /tmp/src.md
echo "Тестова сторінка з українським текстом." >> /tmp/src.md
pandoc /tmp/src.md -o digital.pdf --pdf-engine=xelatex 2>/dev/null \
  || pandoc /tmp/src.md -o digital.pdf

# 2. sample.docx
echo "# DOCX" > /tmp/src.md
echo "$MARKER_DOCX" >> /tmp/src.md
pandoc /tmp/src.md -o sample.docx

# 3. sample.doc (через libreoffice із docx)
libreoffice --headless --convert-to doc sample.docx --outdir . 2>/dev/null || \
  echo "WARN: libreoffice unavailable — skipping sample.doc" >&2

# 4. sample.xlsx — через python
python3 - <<PY
from openpyxl import Workbook
wb = Workbook()
ws = wb.active
ws['A1'] = '$MARKER_XLSX'
ws['A2'] = 'Значення'
ws['B2'] = 42
wb.save('sample.xlsx')
PY

# 5. sample.xls (legacy) — через libreoffice
libreoffice --headless --convert-to xls sample.xlsx --outdir . 2>/dev/null || \
  echo "WARN: libreoffice unavailable — skipping sample.xls" >&2

# 6. cyrillic.png — ImageMagick з текстом
convert -size 600x200 xc:white -font DejaVu-Sans -pointsize 36 \
  -fill black -gravity center -draw "text 0,0 '$MARKER_IMG'" cyrillic.png 2>/dev/null || \
  python3 - <<PY
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (600, 200), 'white')
d = ImageDraw.Draw(img)
try:
    f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 36)
except:
    f = ImageFont.load_default()
d.text((20, 70), '$MARKER_IMG', font=f, fill='black')
img.save('cyrillic.png')
PY

# 7. empty.pdf — PDF без text-layer
convert xc:white -page A4 empty.pdf 2>/dev/null || \
  python3 - <<PY
from PIL import Image
img = Image.new('RGB', (800, 1000), 'white')
img.save('empty.pdf')
PY

# 8. scanned.pdf — зображення з текстом, вкладене в PDF без text-layer
convert cyrillic.png -page A4 scanned.pdf 2>/dev/null

echo "Fixtures built in $(pwd)"
ls -la
