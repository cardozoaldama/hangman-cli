# frozen_string_literal: true

module Hangman
  # Applies optional ANSI terminal styling sequences to output strings.
  #
  # @api private
  module Ansi
    # ANSI SGR color and style codes mapped by symbolic name.
    CODES = { bold: 1, dim: 2, red: 31, green: 32, yellow: 33, cyan: 36 }.freeze

    module_function

    # Wraps text in ANSI escape codes when color output is enabled.
    #
    # @param text [String] plain text to format
    # @param names [Array<Symbol>] style keys defined in {CODES}
    # @param enabled [Boolean] whether ANSI escape codes should be emitted
    # @return [String] styled text or original plain text
    def style(text, *names, enabled: true)
      return text unless enabled && !names.empty?

      codes = names.filter_map { CODES[it] }.join(';')
      codes.empty? ? text : "\e[#{codes}m#{text}\e[0m"
    end
  end
end
