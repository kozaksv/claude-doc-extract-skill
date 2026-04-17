# doc-extract — системні залежності

Machine-readable manifest. Parser у `bin/doctor.sh` читає секції
`## apt-packages` і `## pip-packages` як списки `- name` з коментарями.

## apt-packages

- poppler-utils       # pdftotext, pdfinfo, pdftoppm, pdfimages — PDF tools
- libreoffice-core    # DOC/XLS → txt/xlsx конверсія (headless)
- tesseract-ocr       # OCR engine
- tesseract-ocr-ukr   # українська мова для OCR
- tesseract-ocr-rus   # російська мова для OCR
- tesseract-ocr-eng   # англійська мова для OCR
- pandoc              # DOCX → plain text
- antiword            # DOC lightweight fallback
- catdoc              # DOC last-resort
- ocrmypdf            # готовий OCR pipeline для PDF

## pip-packages

- pdfminer.six
- python-docx
- openpyxl
- xlsx2csv
- pdfplumber
- chardet

## coverage-matrix

| format | primary | fallback | last-resort |
|---|---|---|---|
| PDF (text)    | pdftotext         | pdfminer.six  | — |
| PDF (scanned) | ocrmypdf          | pdftoppm+tesseract | — |
| DOCX          | pandoc            | python-docx   | — |
| DOC           | libreoffice       | antiword      | catdoc |
| XLSX          | xlsx2csv          | openpyxl      | — |
| XLS           | libreoffice       | —             | — |
| Image         | tesseract         | —             | — |
| PDF tables    | pdfplumber (opt)  | —             | — |

## install-command

Повна разова інсталяція (для Debian/Ubuntu):

```bash
sudo apt-get install -y poppler-utils libreoffice-core \
  tesseract-ocr tesseract-ocr-ukr tesseract-ocr-rus tesseract-ocr-eng \
  pandoc antiword catdoc ocrmypdf
pip3 install --user pdfminer.six python-docx openpyxl xlsx2csv pdfplumber chardet
```
