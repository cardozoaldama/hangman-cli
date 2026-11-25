# frozen_string_literal: true

module Hangman
  # Provides progressive ASCII gallows artwork scaled to the session attempt limit.
  module Gallows
    # Seven ASCII gallows stages from empty gallows to complete figure.
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

    # Returns the ASCII gallows drawing scaled to the game's attempt limit.
    #
    # @param wrong_count [Integer] number of incorrect guesses made so far
    # @param max_attempts [Integer] total incorrect guesses allowed in the session
    # @return [String] multiline ASCII gallows artwork
    def self.stage(wrong_count, max_attempts: Game::DEFAULT_MAX_ATTEMPTS)
      return STAGES.first if wrong_count <= 0
      return STAGES.last if max_attempts <= 0 || wrong_count >= max_attempts

      scaled = ((wrong_count.to_f / max_attempts) * (STAGES.length - 1)).round
      STAGES[scaled.clamp(1, STAGES.length - 2)]
    end
  end
end
