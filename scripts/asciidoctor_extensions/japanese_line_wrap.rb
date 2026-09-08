# frozen_string_literal: true

require 'asciidoctor-pdf'

module SpaceCubics
  module JapaneseLineWrap
    # References:
    # https://www.w3.org/TR/jlreq/#possibilities_for_linebreaking_between_characters
    # https://www.w3.org/TR/css-text-3/#line-break-property
    SMALL_KANA = (
      'ぁぃぅぇぉゕゖ𛄲っゃゅょゎ𛅐𛅑𛅒' +
      'ァィゥェォヵヶ𛅕ㇰㇱㇲッㇳㇴㇵㇶㇷㇸㇹㇺ' +
      'ャュョㇻㇼㇽㇾㇿヮ𛅤𛅥𛅦𛅧' +
      'ｧｨｩｪｫｯｬｭｮ'
    ).freeze
    ITERATION_MARKS = 'ヽヾゝゞ々〻'.freeze
    PROLONGED_SOUND_MARKS = 'ーｰ'.freeze

    # Characters that must remain with the preceding character. This list
    # follows the common Japanese line-start restrictions described by JLREQ.
    PROHIBIT_BEFORE = (
      '!%),.:;?]}¢°’”‰′″℃' +
      '‐〜゠–' +
      '！？‼⁇⁈⁉' +
      '·・：；･' +
      '。．｡、，､' +
      ITERATION_MARKS +
      PROLONGED_SOUND_MARKS +
      SMALL_KANA
    ).freeze

    # Characters that must remain with the following character.
    PROHIBIT_AFTER = '$([{£¥‘“¿¡⸘'.freeze

    DASHES = "\u2012\u2013\u2014\u2015\u2e3a\u2e3b".freeze
    LEADERS = "\u2025\u2026\u22ef".freeze
    VERBATIM = :space_cubics_verbatim
    JAPANESE_SCRIPT = /\A(?:\p{Han}|\p{Hiragana}|\p{Katakana})\z/
    OPEN_PUNCTUATION = /\A(?:\p{Ps}|\p{Pi})\z/
    CLOSE_PUNCTUATION = /\A(?:\p{Pe}|\p{Pf})\z/

    module_function

    def japanese_document?(document)
      lang = document.attr 'lang'
      lang && /\Aja(?:-|\z)/i.match?(lang)
    end

    def enabled?(document)
      document.respond_to?(:space_cubics_japanese_line_wrap?) &&
        document.space_cubics_japanese_line_wrap?
    end

    def relevant_character?(character)
      character = base_character character
      JAPANESE_SCRIPT.match?(character) || prohibit_before?(character) ||
        prohibit_after?(character) || DASHES.include?(character) ||
        LEADERS.include?(character)
    end

    def prohibit_before?(character)
      character = base_character character
      PROHIBIT_BEFORE.include?(character) ||
        CLOSE_PUNCTUATION.match?(character)
    end

    def prohibit_after?(character)
      character = base_character character
      PROHIBIT_AFTER.include?(character) ||
        OPEN_PUNCTUATION.match?(character)
    end

    def inseparable?(left, right)
      left = base_character left
      right = base_character right
      (DASHES.include?(left) && DASHES.include?(right)) ||
        (left == right && LEADERS.include?(left))
    end

    def break_opportunity?(left, right)
      return false unless relevant_character?(left) || relevant_character?(right)

      !prohibit_after?(left) &&
        !prohibit_before?(right) &&
        !inseparable?(left, right)
    end

    def protected_boundary?(left, right)
      (relevant_character?(left) || relevant_character?(right)) &&
        !break_opportunity?(left, right)
    end

    def graphemes(text)
      text.scan(/\X/)
    end

    def base_character(grapheme)
      grapheme.each_char.first
    end

    def split_segment(segment)
      characters = graphemes segment
      return [segment] if characters.length < 2

      tokens = [characters[0].dup]
      characters.each_cons(2) do |left, right|
        if break_opportunity? left, right
          tokens << right.dup
        else
          tokens[-1] << right
        end
      end
      tokens
    end

    module Converter
      def init_pdf(document)
        super
        @space_cubics_japanese_line_wrap =
          JapaneseLineWrap.japanese_document? document
        @cjk_line_breaks = false if @space_cubics_japanese_line_wrap
      end

      def space_cubics_japanese_line_wrap?
        @space_cubics_japanese_line_wrap
      end
    end

    module Transform
      private

      def build_fragment(fragment, tag_name, attributes)
        fragment = super
        fragment[JapaneseLineWrap::VERBATIM] = true if tag_name == :code
        fragment
      end
    end

    module Arranger
      def format_array=(fragments)
        super
        return unless JapaneseLineWrap.enabled? @document

        previous_text = previous_graphemes = nil
        @unconsumed.each do |fragment|
          text = fragment[:text]
          if text == "\n"
            previous_text = previous_graphemes = nil
            next
          end
          next if text.nil? || text.empty?

          current_graphemes = nil
          if previous_text && !fragment[JapaneseLineWrap::VERBATIM]
            previous_graphemes ||=
              JapaneseLineWrap.graphemes previous_text
            current_graphemes = JapaneseLineWrap.graphemes text
            left = previous_graphemes.last
            right = current_graphemes.first
            if JapaneseLineWrap.protected_boundary?(left, right)
              fragment[:wj] = true
            end
          end
          previous_text = text
          previous_graphemes = current_graphemes
        end
      end
    end

    module LineWrap
      def tokenize(fragment)
        return super unless JapaneseLineWrap.enabled? @document

        segments = super
        return segments if @arranger.current_format_state[JapaneseLineWrap::VERBATIM]

        segments.flat_map { |segment| JapaneseLineWrap.split_segment segment }
      end

      def end_of_the_line_reached(segment)
        return super unless JapaneseLineWrap.enabled? @document

        next_text = @arranger.preview_joined_string
        protected_fragment_boundary = if next_text && !next_text.empty?
          left = JapaneseLineWrap.graphemes(segment).last
          right = JapaneseLineWrap.graphemes(next_text).first
          JapaneseLineWrap.protected_boundary? left, right
        end

        if @accumulated_width.positive? &&
            (protected_segment?(segment) || protected_fragment_boundary)
          update_line_status_based_on_last_output
          @line_full = true
        else
          super
        end
      end

      private

      def fragment_finished(fragment)
        @space_cubics_verbatim_fragment =
          @arranger.current_format_state[JapaneseLineWrap::VERBATIM]
        super
      ensure
        @space_cubics_verbatim_fragment = nil
      end

      def fragment_begins_with_breakable?(fragment)
        return true if JapaneseLineWrap.enabled?(@document) &&
          @space_cubics_verbatim_fragment

        super
      end

      def protected_segment?(segment)
        characters = JapaneseLineWrap.graphemes segment
        characters.length > 1 &&
          characters.any? { |character| JapaneseLineWrap.relevant_character? character }
      end
    end
  end
end

Asciidoctor::PDF::Converter.prepend SpaceCubics::JapaneseLineWrap::Converter
Asciidoctor::PDF::FormattedText::Transform.prepend SpaceCubics::JapaneseLineWrap::Transform
Prawn::Text::Formatted::Arranger.prepend SpaceCubics::JapaneseLineWrap::Arranger
Prawn::Text::Formatted::LineWrap.prepend SpaceCubics::JapaneseLineWrap::LineWrap
