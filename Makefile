OUTPUT      ?= SpaceCubics_PDF_revx
ADOC_SOURCE ?= src/index.adoc
IMAGES_DIR  ?= images
BUILD_DIR   ?= build
XDG_DATA_HOME ?= $(HOME)/.local/share
FONTS_DIR   ?= $(XDG_DATA_HOME)/fonts;$(HOME)/.fonts;/usr/local/share/fonts;/usr/share/fonts/opentype/ipaexfont-gothic
THEME       ?= sc-docs
ifeq ($(V),1)
Q           =
QUIET_GEN   =
QUIET_CLEAN =
else
Q           = @
QUIET_GEN   = @echo '   ' GEN $@;
QUIET_CLEAN = @echo '   ' CLEAN $(BUILD_DIR);
endif

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
BUILD_CONFIG := $(BUILD_DIR)/.sc-pdf-builder-config

ASCIIDOCTOR_PDF := asciidoctor-pdf
RUBY            := ruby
EXTENSION       := scripts/asciidoctor_extensions/small_element.rb
KINSOKU_EXT     := scripts/asciidoctor_extensions/japanese_line_wrap.rb
DRAFT_EXTENSION := scripts/asciidoctor_extensions/draft_watermark.rb
THEMES_DIR      := themes

FONT_OPTION := $(if $(strip $(FONTS_DIR)),-a pdf-fontsdir="$(FONTS_DIR)")
ifdef DRAFT
DRAFT_OPTION := -r ./$(DRAFT_EXTENSION)
endif

STANDARD_COVER := images/cover-standard.svg.in
PRINT_COVER    := images/cover-print.svg.in
# The generated covers are intermediate inputs to Asciidoctor PDF.
STANDARD_RENDERED_COVER := $(BUILD_DIR)/cover-standard.svg
PRINT_RENDERED_COVER    := $(BUILD_DIR)/cover-print.svg
STANDARD_THEME := $(THEMES_DIR)/$(THEME)-theme.yml
PRINT_THEME    := $(THEMES_DIR)/$(THEME)-print-theme.yml

PDF_ASSETS := $(shell find "$(IMAGES_DIR)" -type f -print) \
	scripts/render_cover.rb $(EXTENSION) $(KINSOKU_EXT) $(DRAFT_EXTENSION)

.NOTPARALLEL:
.PHONY: all pdf standard pdf-print clean FORCE

all: standard

pdf: standard

standard: $(STANDARD_PDF)

pdf-print: $(PRINT_PDF)

$(BUILD_DIR):
	$(Q)mkdir -p "$@"

FORCE:

$(BUILD_CONFIG): FORCE | $(BUILD_DIR)
	$(Q)printf '%s\n' \
	  'ADOC_ENTRY=$(abspath $(ADOC_ENTRY))' \
	  'IMAGES_DIR=$(abspath $(IMAGES_DIR))' \
	  'FONTS_DIR=$(FONTS_DIR)' \
	  'THEME=$(THEME)' \
	  'DRAFT=$(DRAFT)' \
	  'ASCIIDOCTOR_PDF=$(ASCIIDOCTOR_PDF)' > "$@.tmp"
	$(Q)if ! cmp -s "$@.tmp" "$@"; then \
	  mv "$@.tmp" "$@"; \
	else \
	  rm "$@.tmp"; \
	fi

$(STANDARD_RENDERED_COVER): $(STANDARD_COVER) $(ADOC_ENTRY) \
	scripts/render_cover.rb $(BUILD_CONFIG) | $(BUILD_DIR)
	$(QUIET_GEN) $(RUBY) scripts/render_cover.rb \
	  "$(STANDARD_COVER)" "$@" --adoc "$(ADOC_ENTRY)"

$(PRINT_RENDERED_COVER): $(PRINT_COVER) $(ADOC_ENTRY) \
	scripts/render_cover.rb $(BUILD_CONFIG) | $(BUILD_DIR)
	$(QUIET_GEN) $(RUBY) scripts/render_cover.rb \
	  "$(PRINT_COVER)" "$@" --adoc "$(ADOC_ENTRY)"

$(STANDARD_PDF): $(ADOC_FILES) $(STANDARD_RENDERED_COVER) $(STANDARD_THEME) \
	$(PDF_ASSETS) $(BUILD_CONFIG) | $(BUILD_DIR)
	$(QUIET_GEN) $(ASCIIDOCTOR_PDF) \
	  -r ./$(EXTENSION) \
	  -r ./$(KINSOKU_EXT) \
	  $(DRAFT_OPTION) \
	  -r asciidoctor-mathematical \
	  --failure-level WARN \
	  --trace \
	  -a reproducible \
	  -a imagesdir="$(abspath $(IMAGES_DIR))" \
	  -a imagesoutdir="$(abspath $(BUILD_DIR))" \
	  -a pdf-cover-image="$(abspath $(STANDARD_RENDERED_COVER))" \
	  $(FONT_OPTION) \
	  -a pdf-theme="$(THEME)" \
	  -a pdf-themesdir="$(THEMES_DIR)" \
	  -o "$@" \
	  "$(ADOC_ENTRY)"

$(PRINT_PDF): $(ADOC_FILES) $(PRINT_RENDERED_COVER) $(STANDARD_THEME) \
	$(PRINT_THEME) $(PDF_ASSETS) $(BUILD_CONFIG) | $(BUILD_DIR)
	$(QUIET_GEN) $(ASCIIDOCTOR_PDF) \
	  -r ./$(EXTENSION) \
	  -r ./$(KINSOKU_EXT) \
	  $(DRAFT_OPTION) \
	  -r asciidoctor-mathematical \
	  --failure-level WARN \
	  --trace \
	  -a reproducible \
	  -a imagesdir="$(abspath $(IMAGES_DIR))" \
	  -a imagesoutdir="$(abspath $(BUILD_DIR))" \
	  -a pdf-cover-image="$(abspath $(PRINT_RENDERED_COVER))" \
	  $(FONT_OPTION) \
	  -a pdf-theme="$(THEME)-print" \
	  -a pdf-themesdir="$(THEMES_DIR)" \
	  -o "$@" \
	  "$(ADOC_ENTRY)"

clean:
	$(QUIET_CLEAN)$(RM) -r "$(BUILD_DIR)"
