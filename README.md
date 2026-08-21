# Space Cubics PDF Builder

This repository is a template for creating PDF documents from AsciiDoc
sources with Asciidoctor PDF.

The included themes and cover designs are provided as Space Cubics samples.
Use them as they are, or adapt them to the requirements of your document.
The template produces a standard PDF and a print-friendly PDF whose cover
uses less solid-color fill.

For examples of AsciiDoc syntax, build the sample document and read the
generated PDF. It covers titles, paragraphs, lists, figures, tables, code
blocks, admonitions, and links.

## Requirements

The build requires the following tools:

- GNU Make
- Python 3
- Ruby
- Asciidoctor PDF
- Rouge

On Debian or Ubuntu, install the basic tools with:

```sh
sudo apt update
sudo apt install make python3 ruby ruby-dev build-essential
```

Install the required Ruby gems with:

```sh
gem install asciidoctor-pdf rouge
```

## Tested Versions

The PDFs have been successfully built with:

- GNU Make 4.4.1
- Python 3.13.5
- Ruby 3.3.8
- Asciidoctor PDF 2.3.24
- Asciidoctor 2.0.23
- Rouge 4.7.0

## Fonts

The sample theme uses the following fonts:

- Noto Sans JP for normal text, headings, tables, and page furniture
- Sarasa Mono J for code blocks and inline code

The fonts are not included in this repository. The theme currently expects
the following files:

```text
/usr/share/fonts/truetype/Noto_Sans_JP/NotoSansJP-Regular.ttf
/usr/share/fonts/truetype/Noto_Sans_JP/NotoSansJP-Bold.ttf
/usr/share/fonts/truetype/SarasaMonoJ/SarasaMonoJ-Regular.ttf
/usr/share/fonts/truetype/SarasaMonoJ/SarasaMonoJ-Italic.ttf
/usr/share/fonts/truetype/SarasaMonoJ/SarasaMonoJ-Bold.ttf
/usr/share/fonts/truetype/SarasaMonoJ/SarasaMonoJ-BoldItalic.ttf
```

Install these fonts before building the PDF. The Noto Sans JP regular font is
also used for italic text, and its bold font is used for bold italic text.

Font installation locations differ between operating systems and Linux
distributions. A font being installed on the system is not sufficient if its
file path differs from the path in the theme. In that case, update the
`font.catalog` entries in `themes/sc-docs-theme.yml` to point to the actual
font files. Incorrect paths cause Asciidoctor PDF to report an unknown font or
fail while generating the PDF.

## Building the PDFs

The main document is `src/index.adoc`. Edit its document attributes and the
included chapter files before building.

To build a document whose entry point is in another directory, change
`ADOC_SOURCE` in the `Makefile`. All `.adoc` files in that directory and its
subdirectories are automatically added as build dependencies. For example:

```make
ADOC_SOURCE := src/my-document/index.adoc
```

Build the standard PDF with:

```sh
make pdf
```

Build the print-friendly PDF with:

```sh
make print
```

Build both versions with:

```sh
make all
```

To specify the output file name, override the `OUTPUT` variable. Specify the
base name without the `.pdf` extension:

```sh
make pdf OUTPUT=My_Document
```

This command generates `build/My_Document.pdf`. The same variable can be used
for the print-friendly PDF or both versions:

```sh
make print OUTPUT=My_Document
make all OUTPUT=My_Document
```

These commands generate `build/My_Document-print.pdf`, or both output files,
respectively.

The generated files are written to `build/`:

```text
build/SpaceCubics_PDF_revx.pdf
build/SpaceCubics_PDF_revx-print.pdf
```

Remove generated files with:

```sh
make clean
```
