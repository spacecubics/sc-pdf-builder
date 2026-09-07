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
- Ruby
- Asciidoctor PDF
- Rouge

On Debian or Ubuntu, install the basic tools with:

```sh
sudo apt update
sudo apt install make ruby ruby-dev build-essential
```

Install the required Ruby gems with:

```sh
gem install asciidoctor-pdf rouge
```

## Tested Versions

The PDFs have been successfully built with:

- GNU Make 4.4.1
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

## Building PDFs

Create a `Makefile` in the root of a document repository, then use it to build
the PDFs. Start by cloning the PDF builder and copying its sample Makefile:

```sh
git clone {sc-pdf-builder URL}
cp sc-pdf-builder/Makefile_sample Makefile
make ADOC_SOURCE=path/to/document.adoc \
  IMAGES_DIR=path/to/images
```

The command builds both PDF variants in the document repository's `build/`
directory. Build only the standard PDF with:

```sh
make pdf
```

To build the sample document included with the PDF builder, use its source and
image directories:

```sh
make ADOC_SOURCE=sc-pdf-builder/src/index.adoc \
  IMAGES_DIR=sc-pdf-builder/images
```

Build the print-friendly PDF with:

```sh
make print
```

Remove generated files with:

```sh
make clean
```

### Configure the build

`Makefile_sample` supplies the following variables. Override a variable on the
command line for a single build, or set its value in the document repository's
`Makefile` to make the setting permanent.

- `PDF_BUILDER` is the path to the cloned builder. Its default is
  `sc-pdf-builder`.
- `ADOC_SOURCE` is the entry-point `.adoc` file. Its default is
  `src/index.adoc`. All `.adoc` files in its directory and subdirectories are
  build dependencies.
- `IMAGES_DIR` is the directory used for `image::` references. Its default is
  `images`.
- `OUTPUT` is the base name of the generated PDFs, without the `.pdf`
  extension. Its default is `document`.
- `BUILD_DIR` is the output directory. Its default is `build`.

For example, build a document whose source and images are in custom locations:

```sh
make pdf ADOC_SOURCE=docs/manual/manual.adoc \
  IMAGES_DIR=docs/assets OUTPUT=My_Document
```

This command generates `build/My_Document.pdf`. The same settings apply to
the print-friendly PDF and both PDF variants:

```sh
make print OUTPUT=My_Document
make all OUTPUT=My_Document
```

To store generated files in another directory, override `BUILD_DIR`:

```sh
make all BUILD_DIR=output
```

The previous commands generate the following files when `OUTPUT` is
`My_Document`:

```text
build/My_Document.pdf
build/My_Document-print.pdf
```
