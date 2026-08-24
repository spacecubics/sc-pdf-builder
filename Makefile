OUTPUT      := SpaceCubics_PDF_revx
ADOC_SOURCE := src/index.adoc
ADOC_DIR    := $(patsubst %/,%,$(dir $(ADOC_SOURCE)))
ADOC_FILES  := $(shell find "$(ADOC_DIR)" -type f -name '*.adoc' -print)
BUILD_DIR   := build

STANDARD_PDF := $(BUILD_DIR)/$(OUTPUT).pdf
PRINT_PDF    := $(BUILD_DIR)/$(OUTPUT)-print.pdf

ASCIIDOCTOR_PDF := asciidoctor-pdf
PYTHON          := python3
EXTENSION       := scripts/asciidoctor_extensions/small_element.rb
THEMES_DIR      := themes

STANDARD_COVER := images/cover-standard.svg.in
PRINT_COVER    := images/cover-print.svg.in
RENDERED_COVER := $(BUILD_DIR)/cover.svg
STANDARD_THEME := $(THEMES_DIR)/sc-docs-theme.yml
PRINT_THEME    := $(THEMES_DIR)/sc-docs-print-theme.yml

PDF_ASSETS := $(filter-out $(STANDARD_COVER) $(PRINT_COVER),$(wildcard images/*)) \
	$(STANDARD_THEME) scripts/render_cover.py $(EXTENSION)

.NOTPARALLEL:
.PHONY: all pdf standard print clean

all: standard print

pdf: standard

standard: $(STANDARD_PDF)

print: $(PRINT_PDF)

$(STANDARD_PDF): $(ADOC_FILES) $(STANDARD_COVER) $(PDF_ASSETS)
	@mkdir -p "$(BUILD_DIR)"
	$(PYTHON) scripts/render_cover.py \
	  "$(STANDARD_COVER)" "$(RENDERED_COVER)" --adoc "$(ADOC_SOURCE)"
	$(ASCIIDOCTOR_PDF) \
	  -r ./$(EXTENSION) \
	  -r asciidoctor-mathematical \
	  --failure-level WARN \
	  --trace \
	  -a reproducible \
	  -a imagesdir="$(abspath images)" \
	  -a pdf-theme=sc-docs \
	  -a pdf-themesdir="$(THEMES_DIR)" \
	  -D "$(BUILD_DIR)" \
	  -o "$(notdir $@)" \
	  "$(ADOC_SOURCE)"

$(PRINT_PDF): $(ADOC_FILES) $(PRINT_COVER) $(PRINT_THEME) $(PDF_ASSETS)
	@mkdir -p "$(BUILD_DIR)"
	$(PYTHON) scripts/render_cover.py \
	  "$(PRINT_COVER)" "$(RENDERED_COVER)" --adoc "$(ADOC_SOURCE)"
	$(ASCIIDOCTOR_PDF) \
	  -r ./$(EXTENSION) \
	  -r asciidoctor-mathematical \
	  --failure-level WARN \
	  --trace \
	  -a reproducible \
	  -a imagesdir="$(abspath images)" \
	  -a pdf-theme=sc-docs-print \
	  -a pdf-themesdir="$(THEMES_DIR)" \
	  -D "$(BUILD_DIR)" \
	  -o "$(notdir $@)" \
	  "$(ADOC_SOURCE)"

clean:
	$(RM) -r "$(BUILD_DIR)"
