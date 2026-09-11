# frozen_string_literal: true

require 'asciidoctor-pdf'

module DraftWatermark
  def convert_document(doc)
    result = super

    # Overlay completed pages so cover artwork and shaded blocks cannot hide
    # the watermark. Use the full page bounds, independent of theme margins.
    (1..page_count).each do |number|
      go_to_page number
      canvas do
        save_graphics_state do
          font 'Helvetica', style: :bold, size: [bounds.width, bounds.height].min * 0.18 do
            fill_color '808080'
            transparent 0.25 do
              center = [bounds.width / 2, bounds.height / 2]
              rotate 45, origin: center do
                draw_text 'DRAFT', at: [center[0] - width_of('DRAFT') / 2,
                  center[1] - (font.ascender + font.descender) / 2]
              end
            end
          end
        end
      end
    end

    result
  end
end

Asciidoctor::PDF::Converter.prepend DraftWatermark
