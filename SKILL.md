---
name: doc-extract
description: Use this skill to extract text from PDF, DOCX, DOC, XLSX, XLS, or image (PNG/JPG/TIFF/WEBP) files via offline tool cascade. NO LLM fallback — caller decides if LLM is needed for failed extractions.
---

# doc-extract

Витягування тексту з документів через offline tools. Дефолтний вибір замість Read tool (LLM) для всіх PDF/DOCX/XLS/images, бо дешевше й відтворюваніше.

## Quick usage

```bash
bash ~/.claude/skills/doc-extract/bin/extract.sh <input> \
  --out <output.md> \
  --format md
```

## Handle exit codes

| Exit | Action |
|---|---|
| 0  | Success — output file valid, proceed |
| 10 | extraction_failed — каскад вичерпано. STOP and ask user: (1) скіпнути (2) записати summary вручну (3) використати Read tool (LLM vision, дорого) |
| 20 | missing_dependency — run `bash ~/.claude/skills/doc-extract/bin/doctor.sh`, show output, ask user to install, STOP |
| 30 | unsupported_format — ask user to convert or skip |
| 40 | input_not_found — check path |
| 50 | invalid_options — bug in caller |

## Діагностика

Перед першим використанням:
```bash
bash ~/.claude/skills/doc-extract/bin/doctor.sh
```

Якщо показує missing deps:
```bash
bash ~/.claude/skills/doc-extract/bin/install-deps.sh  # видрукує команду
```

## Full docs

`README.md`, `manifest.md` у цьому репо.
