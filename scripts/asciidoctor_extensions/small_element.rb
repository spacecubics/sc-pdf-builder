# frozen_string_literal: true

require 'asciidoctor-pdf'

module SmallTable
  FONT_SIZE_DELTAS = {
    'small-table' => 1,
    'vsmall-table' => 2,
  }.freeze

  def convert_table(node)
    font_size_delta = FONT_SIZE_DELTAS.find { |role, _| node.role? role }&.last
    return super unless font_size_delta

    original_font_size = @theme.table_font_size
    @theme.table_font_size = [original_font_size.to_f - font_size_delta, 1].max
    super
  ensure
    @theme.table_font_size = original_font_size if original_font_size
  end
end

Asciidoctor::PDF::Converter.prepend SmallTable

module SmallCode
  FONT_SIZE_DELTAS = {
    'small-code' => 1,
    'vsmall-code' => 2,
  }.freeze

  def convert_listing_or_literal(node)
    font_size_delta = FONT_SIZE_DELTAS.find { |role, _| node.role? role }&.last
    return super unless font_size_delta

    had_autofit_option = node.option? 'autofit'
    node.set_option 'autofit'
    @small_code_font_size = [@theme.code_font_size.to_f - font_size_delta, 1].max
    super
  ensure
    if font_size_delta
      @small_code_font_size = nil
      node.remove_attr 'autofit-option' unless had_autofit_option
    end
  end

  def compute_autofit_font_size(fragments, category)
    return @small_code_font_size if category == :code && @small_code_font_size

    super
  end
end

Asciidoctor::PDF::Converter.prepend SmallCode
