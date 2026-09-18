# Include this file after defining the document's build settings.
_SC_PDF_DEFAULT_GOAL := $(.DEFAULT_GOAL)
_SC_PDF_DIRECTORY := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PDF_BUILDER ?= $(_SC_PDF_DIRECTORY)
ADOC_SOURCE ?= src/index.adoc
ADOC_RECURSIVE ?= 0
IMAGES_DIR ?= images
BUILD_DIR ?= build
OUTPUT ?= $(patsubst %.adoc,%,$(notdir $(patsubst %/,%,$(ADOC_SOURCE))))
THEME ?= sc-docs
PDF_GEMS ?= $(CURDIR)/.bundle/pdf-gems

_SC_PDF_ENV = BUNDLE_GEMFILE="$(abspath $(PDF_BUILDER))/Gemfile" \
	BUNDLE_PATH="$(abspath $(PDF_GEMS))"
_SC_PDF_FONT_OPTION = $(if $(filter undefined,$(origin FONTS_DIR)),,FONTS_DIR="$(FONTS_DIR)")

.PHONY: pdf pdf-print pdf-setup pdf-clean
.NOTPARALLEL:

pdf-setup:
	$(_SC_PDF_ENV) CMAKE_POLICY_VERSION_MINIMUM=3.5 \
	  CMAKE_GENERATOR="Unix Makefiles" bundle install

pdf pdf-print:
	+$(_SC_PDF_ENV) bundle exec $(MAKE) --no-print-directory -C "$(PDF_BUILDER)" -f pdf.mk $@ \
	  ADOC_SOURCE="$(abspath $(ADOC_SOURCE))" \
	  ADOC_DEPS="$(abspath $(ADOC_DEPS))" \
	  ADOC_RECURSIVE="$(ADOC_RECURSIVE)" \
	  IMAGES_DIR="$(abspath $(IMAGES_DIR))" \
	  BUILD_DIR="$(abspath $(BUILD_DIR))" \
	  OUTPUT="$(OUTPUT)" THEME="$(THEME)" DRAFT="$(DRAFT)" $(_SC_PDF_FONT_OPTION)

pdf-clean:
	$(RM) -r "$(BUILD_DIR)"

.DEFAULT_GOAL := $(_SC_PDF_DEFAULT_GOAL)
