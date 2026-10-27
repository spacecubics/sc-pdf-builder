# frozen_string_literal: true

require 'asciidoctor-diagram/d2'
require 'rexml/document'

module D2Svg
  # Prawn SVG supports clipping paths but ignores the masks D2 uses for labels.
  def self.clip_masks(svg)
    document = REXML::Document.new(svg)
    masks = {}
    REXML::XPath.each(document, '//mask') do |mask|
      rectangles = mask.elements.to_a
      unless rectangles.all? { |rect| rect.name == 'rect' } &&
          rectangles.first&.attributes&.[]('fill') == 'white' &&
          rectangles.drop(1).all? { |rect| rect.attributes['fill'] == 'black' }
        raise 'Unsupported D2 SVG mask. Use format=png for this diagram'
      end

      regions = [rectangle(rectangles.first)]
      rectangles.drop(1).each do |rectangle|
        hole = self.rectangle(rectangle)
        regions = regions.flat_map { |region| subtract(region, hole) }
      end

      clip = REXML::Element.new('clipPath')
      clip.add_attributes('id' => mask.attributes['id'], 'clipPathUnits' => 'userSpaceOnUse')
      regions.each do |x, y, width, height|
        clip.add_element('rect', 'x' => x.to_s, 'y' => y.to_s,
                         'width' => width.to_s, 'height' => height.to_s)
      end
      masks["url(##{mask.attributes['id']})"] = true
      # Prawn resolves references in document order.
      mask.parent.insert_before(mask.parent.elements[1], clip)
      mask.parent.delete_element(mask)
    end

    REXML::XPath.each(document, '//*[@mask]') do |element|
      reference = element.attributes['mask']
      next unless masks[reference]

      element.add_attribute('clip-path', reference)
      element.delete_attribute('mask')
    end
    document.to_s
  end

  def self.rectangle(element)
    %w[x y width height].map { |attribute| Float(element.attributes[attribute] || 0) }
  end

  def self.subtract(region, hole)
    x, y, width, height = region
    hx, hy, hw, hh = hole
    left, top = [x, hx].max, [y, hy].max
    right, bottom = [x + width, hx + hw].min, [y + height, hy + hh].min
    return [region] if left >= right || top >= bottom

    [[x, y, width, top - y],
     [x, bottom, width, y + height - bottom],
     [x, top, left - x, bottom - top],
     [right, top, x + width - right, bottom - top]].select { |_, _, w, h| w.positive? && h.positive? }
  end

  def convert(source, format, options)
    result = super
    format == :svg ? D2Svg.clip_masks(result) : result
  end
end

Asciidoctor::Diagram::D2Converter.prepend(D2Svg)
