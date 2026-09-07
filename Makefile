OUTPUT      ?= SpaceCubics_PDF_revx
ADOC_SOURCE ?= src/index.adoc
IMAGES_DIR  ?= images
BUILD_DIR   ?= build
XDG_DATA_HOME ?= $(HOME)/.local/share
FONTS_DIR   ?= $(XDG_DATA_HOME)/fonts;$(HOME)/.fonts;/usr/local/share/fonts;/usr/share/fonts/opentype/ipaexfont-gothic
THEME       ?= sc-docs

# ADOC_SOURCE may name either an entry-point .adoc file or a directory that
# contains index.adoc.
ifneq ($(filter %.adoc,$(notdir $(ADOC_SOURCE))),)
ADOC_ENTRY := $(ADOC_SOURCE)
else
ADOC_ENTRY := $(patsubst %/,%,$(ADOC_SOURCE))/index.adoc
endif
ADOC_DIR   := $(patsubst %/,%,$(dir $(ADOC_ENTRY)))
ADOC_FILES := $(shell find "$(ADOC_DIR)" -type f -name '*.adoc' -print)

STANDARD_PDF := $(BUILD_DIR)/$(OUTPUT).pdf
PRINT_PDF    := $(BUILD_DIR)/$(OUTPUT)-print.pdf

ASCIIDOCTOR_PDF := asciidoctor-pdf
RUBY            := ruby
EXTENSION       := scripts/asciidoctor_extensions/small_element.rb
THEMES_DIR      := themes

FONT_OPTION := $(if $(strip $(FONTS_DIR)),-a pdf-fontsdir="$(FONTS_DIR)")

STANDARD_COVER := images/cover-standard.svg.in
PRINT_COVER    := images/cover-print.svg.in
# The bundled themes resolve the cover relative to the builder's themes/
# directory. Keep this intermediate asset with the builder even when PDF
# outputs are written to a document repository's BUILD_DIR.
RENDERED_COVER := build/cover.svg
STANDARD_THEME := $(THEMES_DIR)/$(THEME)-theme.yml
PRINT_THEME    := $(THEMES_DIR)/$(THEME)-print-theme.yml

PDF_ASSETS := $(shell find "$(IMAGES_DIR)" -type f -print) \
	$(STANDARD_THEME) scripts/render_cover.rb $(EXTENSION)

.NOTPARALLEL:
.PHONY: all pdf standard pdf-print clean

all: standard

pdf: standard

standard: $(STANDARD_PDF)

pdf-print: $(PRINT_PDF)

$(STANDARD_PDF): $(ADOC_FILES) $(STANDARD_COVER) $(PDF_ASSETS)
	@mkdir -p "$(BUILD_DIR)"
	@mkdir -p "$(dir $(RENDERED_COVER))"
	$(RUBY) scripts/render_cover.rb \
	  "$(STANDARD_COVER)" "$(RENDERED_COVER)" --adoc "$(ADOC_ENTRY)"
	$(ASCIIDOCTOR_PDF) \
	  -r ./$(EXTENSION) \
	  -r asciidoctor-mathematical \
	  --failure-level WARN \
	  --trace \
	  -a reproducible \
	  -a imagesdir="$(abspath $(IMAGES_DIR))" \
	  -a imagesoutdir="$(abspath $(BUILD_DIR))" \
	  $(FONT_OPTION) \
	  -a pdf-theme="$(THEME)" \
	  -a pdf-themesdir="$(THEMES_DIR)" \
	  -o "$@" \
	  "$(ADOC_ENTRY)"

$(PRINT_PDF): $(ADOC_FILES) $(PRINT_COVER) $(PRINT_THEME) $(PDF_ASSETS)
	@mkdir -p "$(BUILD_DIR)"
	@mkdir -p "$(dir $(RENDERED_COVER))"
	$(RUBY) scripts/render_cover.rb \
	  "$(PRINT_COVER)" "$(RENDERED_COVER)" --adoc "$(ADOC_ENTRY)"
	$(ASCIIDOCTOR_PDF) \
	  -r ./$(EXTENSION) \
	  -r asciidoctor-mathematical \
	  --failure-level WARN \
	  --trace \
	  -a reproducible \
	  -a imagesdir="$(abspath $(IMAGES_DIR))" \
	  -a imagesoutdir="$(abspath $(BUILD_DIR))" \
	  $(FONT_OPTION) \
	  -a pdf-theme="$(THEME)-print" \
	  -a pdf-themesdir="$(THEMES_DIR)" \
	  -o "$@" \
	  "$(ADOC_ENTRY)"

clean:
	$(RM) -r "$(BUILD_DIR)"
