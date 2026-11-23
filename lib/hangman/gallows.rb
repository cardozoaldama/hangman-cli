# frozen_string_literal: true

module Hangman
  # Provides progressive ASCII gallows artwork indexed by wrong guess count.
  module Gallows
    # Seven ASCII gallows stages corresponding to zero through six wrong guesses.
    STAGES = [
      <<~ART,
          +---+
          |   |
              |
              |
              |
              |
        =========
      ART
      <<~ART,
          +---+
          |   |
          O   |
              |
              |
              |
        =========
      ART
      <<~ART,
          +---+
          |   |
          O   |
          |   |
              |
              |
        =========
      ART
      <<~ART,
          +---+
          |   |
          O   |
         /|   |
              |
              |
        =========
      ART
      <<~'ART',
          +---+
          |   |
          O   |
         /|\  |
              |
              |
        =========
      ART
      <<~'ART',
          +---+
          |   |
          O   |
         /|\  |
         /    |
              |
        =========
      ART
      <<~'ART'
          +---+
          |   |
          O   |
         /|\  |
         / \  |
              |
        =========
      ART
    ].freeze

    # Returns the ASCII gallows drawing for the given number of wrong guesses.
    #
    # @param wrong_count [Integer] number of incorrect guesses made so far
    # @return [String] multiline ASCII gallows artwork
    def self.stage(wrong_count)
      STAGES[wrong_count.clamp(0, STAGES.length - 1)]
    end
  end
end
