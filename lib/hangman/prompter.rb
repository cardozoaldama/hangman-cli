# frozen_string_literal: true

module Hangman
  # Shared terminal prompt and selection parsing helpers.
  #
  # @api private
  module Prompter
    # Displays a prompt and reads one stripped line from the input stream.
    #
    # @param message [String] prompt text shown to the user
    # @return [String, nil] stripped line, or nil on EOF
    def prompt(message)
      @output.print(message)
      @output.flush
      @input.gets&.strip
    end

    # Prompts the user for a yes/no confirmation.
    #
    # @param message [String] confirmation question
    # @return [Boolean] true if answered with y or yes
    def confirm?(message)
      answer = prompt(message)
      %w[y yes].include?(answer&.downcase)
    end

    # Checks whether an input represents an empty or 'back' navigation choice.
    #
    # @param choice [String, nil] raw user choice
    # @return [Boolean] true if empty, nil, or 'back'
    def back_choice?(choice)
      choice.nil? || choice.empty? || choice.casecmp?('back')
    end

    # Checks whether an input is a valid 1-based menu index up to limit.
    #
    # @param choice [String] raw user choice
    # @param limit [Integer] maximum valid 1-based index
    # @return [Boolean] true if within 1..limit
    def numbered_choice?(choice, limit)
      choice.match?(/\A\d+\z/) && choice.to_i.between?(1, limit)
    end
  end
end
