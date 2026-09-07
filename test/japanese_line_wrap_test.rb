# frozen_string_literal: true

require_relative '../scripts/asciidoctor_extensions/japanese_line_wrap'

class JapaneseLineWrapTest
  POLICY = SpaceCubics::JapaneseLineWrap

  class Failure < StandardError; end

  def self.run
    tests = public_instance_methods(false).grep(/^test_/).sort
    failures = []
    tests.each do |test|
      instance = new
      instance.setup
      instance.public_send test
      $stdout.puts "PASS #{test}"
    rescue StandardError => error
      failures << [test, error]
      warn "FAIL #{test}: #{error.message}"
    end

    $stdout.puts "#{tests.length - failures.length}/#{tests.length} tests passed"
    exit 1 unless failures.empty?
  end

  def setup
    @document = Prawn::Document.new
    @document.define_singleton_method(:space_cubics_japanese_line_wrap?) { true }

    font_path = File.join(
      Gem::Specification.find_by_name('asciidoctor-pdf').full_gem_path,
      'data/fonts/mplus1p-regular-fallback.ttf'
    )
    @document.font_families.update(
      'Japanese test' => {
        normal: font_path,
        bold: font_path,
      }
    )
    @document.font 'Japanese test'
  end

  def test_finds_normal_japanese_break_opportunity
    assert POLICY.break_opportunity?('本', '語')
  end

  def test_recognizes_japanese_language_tags
    document = Struct.new(:language) do
      def attr(_name)
        language
      end
    end

    assert POLICY.japanese_document?(document.new('ja'))
    assert POLICY.japanese_document?(document.new('ja-JP'))
    refute POLICY.japanese_document?(document.new('zh'))
  end

  def test_prohibits_line_start_characters
    %w[。 、 っ ャ ー 々].each do |character|
      refute POLICY.break_opportunity?('文', character), character
    end
  end

  def test_prohibits_line_end_characters
    %w[「 （ “].each do |character|
      refute POLICY.break_opportunity?(character, '文'), character
    end
  end

  def test_keeps_dashes_and_leaders_together
    refute POLICY.break_opportunity?('—', '―')
    refute POLICY.break_opportunity?('…', '…')
    assert POLICY.break_opportunity?('…', '文')
  end

  def test_keeps_combining_mark_with_base_character
    decomposed_ga = "か\u3099"

    assert_equal([decomposed_ga, 'く'], POLICY.split_segment("#{decomposed_ga}く"))
  end

  def test_treats_period_as_break_opportunity_in_prose
    assert_equal(['.', 'vsmall-code'], POLICY.split_segment('.vsmall-code'))
  end

  def test_marks_code_fragment_as_verbatim
    fragments = Asciidoctor::PDF::FormattedText::Formatter.new.format(
      '<code>.vsmall-code</code>'
    )

    assert fragments[0][POLICY::VERBATIM]
  end

  def test_breaks_after_period_in_prose
    assert_equal(
      ['あいうえおかき.', 'vsmall-code'],
      render_lines([{ text: 'あいうえおかき.vsmall-code' }], width: 75)
    )
  end

  def test_breaks_before_inline_code_with_leading_period
    assert_equal(
      ['あいうえおかき.small-code、', '.vsmall-code'],
      render_lines(
        [
          { text: 'あいうえおかき' },
          {
            text: '.small-code',
            styles: [:bold],
            POLICY::VERBATIM => true,
          },
          { text: '、' },
          {
            text: '.vsmall-code',
            styles: [:bold],
            POLICY::VERBATIM => true,
          },
        ],
        width: 140
      )
    )
  end

  def test_keeps_closing_punctuation_off_line_start
    assert_equal(
      ['あいうえおかき', 'く。次の文'],
      render_lines([{ text: 'あいうえおかきく。次の文' }])
    )
  end

  def test_keeps_opening_punctuation_off_line_end
    assert_equal(
      ['あいうえおかき', '「引用」'],
      render_lines([{ text: 'あいうえおかき「引用」' }])
    )
  end

  def test_applies_kinsoku_across_bold_fragment
    assert_equal(
      ['あいうえおかき', '「引用」'],
      render_lines([
        { text: 'あいうえおかき「' },
        { text: '引用', styles: [:bold] },
        { text: '」' },
      ])
    )
  end

  def test_keeps_small_kana_with_text_in_previous_fragment
    assert_equal(
      ['あいうえおかき', 'くっ小書き'],
      render_lines([
        { text: 'あいうえおかきく' },
        { text: 'っ小書き', styles: [:bold] },
      ])
    )
  end

  def test_keeps_closing_punctuation_with_previous_fragment
    assert_equal(
      ['あいうえおかき', 'く。次の文'],
      render_lines([
        { text: 'あいうえおかきく' },
        { text: '。次の文', styles: [:bold] },
      ])
    )
  end

  def test_applies_kinsoku_across_link_fragment
    assert_equal(
      ['あいうえおかき', '「リンク」'],
      render_lines([
        { text: 'あいうえおかき「' },
        { text: 'リンク', link: 'https://example.com' },
        { text: '」' },
      ])
    )
  end

  private

  def assert(condition, message = 'assertion failed')
    raise Failure, message unless condition
  end

  def refute(condition, message = 'refutation failed')
    raise Failure, message if condition
  end

  def assert_equal(expected, actual)
    return if expected == actual

    raise Failure, "expected #{expected.inspect}, got #{actual.inspect}"
  end

  def render_lines(fragments, width: 80)
    rendered = []
    @document.formatted_text_box(
      fragments,
      at: [0, 700],
      width: width,
      height: 100,
      size: 10,
      draw_text_callback: lambda do |text, options|
        rendered << [options[:at][1], text]
      end
    )

    rendered.group_by(&:first).values.map do |line_fragments|
      line_fragments.map(&:last).join
    end
  end
end

JapaneseLineWrapTest.run if $PROGRAM_NAME == __FILE__
