# claude-doc-extract-skill

Скіл для Claude Code (і Bash-CLI) — вилучення тексту з документів через каскад offline-tools. Без LLM fallback.

## Що робить

Підтримує формати:
- **PDF** — pdftotext → pdfminer.six → ocrmypdf → pdftoppm+tesseract
- **DOCX** — pandoc → python-docx
- **DOC** — libreoffice → antiword → catdoc
- **XLSX** — xlsx2csv → openpyxl
- **XLS** — libreoffice → xlsx → xlsx-каскад
- **Images** (PNG/JPG/TIFF/WEBP) — tesseract (ukr+rus+eng)

Ніколи не звертається до Claude multimodal / LLM — це окрема свідома дія юзера.

## Встановлення

```bash
curl -fsSL https://raw.githubusercontent.com/kozaksv/claude-doc-extract-skill/main/install.sh | bash
```

Після встановлення:

```bash
bash ~/.claude/skills/doc-extract/bin/doctor.sh
```

Якщо чогось нема — doctor друкує install-команди. Виконай, повтори doctor.

## Використання (CLI)

```bash
# stdout
bash ~/.claude/skills/doc-extract/bin/extract.sh file.pdf

# в файл з frontmatter
bash ~/.claude/skills/doc-extract/bin/extract.sh file.pdf --out transcript.md

# пропустити OCR (швидше, якщо digital)
bash ~/.claude/skills/doc-extract/bin/extract.sh file.pdf --no-ocr

# інша мова OCR
bash ~/.claude/skills/doc-extract/bin/extract.sh img.png --lang eng

# JSON output
bash ~/.claude/skills/doc-extract/bin/extract.sh file.docx --out out.json --format json
```

## Exit codes

| Code | Значення |
|---|---|
| 0 | success |
| 10 | extraction_failed (каскад вичерпано, тексту мало) |
| 20 | missing_dependency |
| 30 | unsupported_format |
| 40 | input_not_found |
| 50 | invalid_options |

## Інтеграція з Wiki-скілом

Wiki skill ([kozaksv/claude-wiki-skill](https://github.com/kozaksv/claude-wiki-skill)) на кроці `ingest-binary` викликає doc-extract замість власного extraction. Вся логіка transcripts робиться тут.

## Формат `md`-output

```markdown
---
source: path/to/file.pdf
extracted_at: 2026-04-17T12:34:56Z
extractor: pdftotext 22.02.0
pages: 14
chars: 31847
method_chain: [pdftotext]
---

<text>
```

## Залежності

**apt:** `poppler-utils libreoffice-core libreoffice-writer libreoffice-calc tesseract-ocr tesseract-ocr-{ukr,rus,eng} pandoc antiword catdoc ocrmypdf`

**pip:** `pdfminer.six python-docx openpyxl xlsx2csv pdfplumber chardet`

Повний манфіест у [`manifest.md`](manifest.md).

**Примітка:** для DOC/XLS потрібні `libreoffice-writer` і `libreoffice-calc` (не просто `libreoffice-core`).

## Видалення

```bash
rm -rf ~/.claude/skills/doc-extract
```

## Ліцензія

MIT
