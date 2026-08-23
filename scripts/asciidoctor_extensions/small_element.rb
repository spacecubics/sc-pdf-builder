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
    font_size_delta =
      FONT_SIZE_DELTAS.find { |role, _| node.role? role }&.last

    return super unless font_size_delta

    original_font_size = @theme.code_font_size
    @theme.code_font_size = [
      original_font_size.to_f - font_size_delta,
      1,
    ].max

    super
  ensure
    @theme.code_font_size = original_font_size if original_font_size
  end
end

Asciidoctor::PDF::Converter.prepend SmallCode
