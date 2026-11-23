# frozen_string_literal: true

module Hangman
  # Represents the state and rules of a single Hangman game session.
  class Game
    # Immutable outcome returned for each player guess attempt.
    GuessResult = Data.define(:outcome, :letter)

    # Default number of incorrect guesses permitted before losing.
    DEFAULT_MAX_ATTEMPTS = 6

    # Pattern matching a single lowercase ASCII alphabetic letter.
    LETTER_PATTERN = /\A[a-z]\z/

    # Target word the player is attempting to uncover.
    # @return [String]
    attr_reader :secret_word

    # Maximum number of wrong guesses allowed in this session.
    # @return [Integer]
    attr_reader :max_attempts

    # Ordered list of unique letters guessed so far.
    # @return [Array<String>]
    attr_reader :guessed_letters

    # Reconstructs a Game instance from a serialized Hash payload.
    #
    # @param data [Hash] serialized game attributes
    # @return [Game] restored game instance
    # @raise [ArgumentError] if required keys are missing or have invalid types
    def self.from_h(data)
      validate_serialized_hash!(data)
      new(
        secret_word: data.fetch('secret_word'),
        max_attempts: data.fetch('max_attempts'),
        guessed_letters: data.fetch('guessed_letters')
      )
    end

    # Validates serialized game data before instantiating a Game.
    #
    # @param data [Object] parsed payload expected to be a Hash
    # @return [void]
    # @raise [ArgumentError] if the structure or field types are invalid
    def self.validate_serialized_hash!(data)
      raise ArgumentError, 'Saved game data must be a Hash' unless data.is_a?(Hash)
      raise ArgumentError, 'Invalid secret_word in saved data' unless data['secret_word'].is_a?(String)
      raise ArgumentError, 'Invalid max_attempts in saved data' unless data['max_attempts'].is_a?(Integer)
      raise ArgumentError, 'Invalid guessed_letters in saved data' unless data['guessed_letters'].is_a?(Array)
    end
    private_class_method :validate_serialized_hash!

    # Creates a new Hangman game session.
    #
    # @param secret_word [String] alphabetic secret word to guess
    # @param max_attempts [Integer] positive number of allowed wrong guesses
    # @param guessed_letters [Array<String>] pre-existing guessed letters
    # @raise [ArgumentError] if the secret word or attempt limit is invalid
    def initialize(secret_word:, max_attempts: DEFAULT_MAX_ATTEMPTS, guessed_letters: [])
      @secret_word = normalize_secret_word(secret_word)
      @max_attempts = validate_max_attempts(max_attempts)
      @guessed_letters = normalize_guesses(guessed_letters)
    end

    # Processes one player guess and returns an immutable outcome value.
    #
    # @param input [String, #to_s] raw letter entered by the player
    # @return [GuessResult] result describing :correct, :incorrect, :duplicate, :invalid, or :finished
    def guess(input)
      return GuessResult.new(outcome: :finished, letter: nil) if over?

      letter = input.to_s.strip.downcase
      return GuessResult.new(outcome: :invalid, letter:) unless letter.match?(LETTER_PATTERN)
      return GuessResult.new(outcome: :duplicate, letter:) if @guessed_letters.include?(letter)

      @guessed_letters << letter
      outcome = @secret_word.include?(letter) ? :correct : :incorrect
      GuessResult.new(outcome:, letter:)
    end

    # Returns all guessed letters that do not appear in the secret word.
    #
    # @return [Array<String>] incorrect letters in guess order
    def wrong_guesses
      @guessed_letters.reject { @secret_word.include?(it) }
    end

    # Returns all guessed letters that appear in the secret word.
    #
    # @return [Array<String>] correct letters in guess order
    def correct_guesses
      @guessed_letters.select { @secret_word.include?(it) }
    end

    # Returns how many incorrect guesses remain before the game is lost.
    #
    # @return [Integer] remaining wrong guesses (minimum zero)
    def remaining_attempts
      [@max_attempts - wrong_guesses.length, 0].max
    end

    # Renders the secret word with unguessed letters replaced by underscores.
    #
    # @return [String] space-separated masked word display
    def masked_word
      @secret_word.chars.map { @guessed_letters.include?(it) ? it : '_' }.join(' ')
    end

    # Checks whether every letter of the secret word has been guessed.
    #
    # @return [Boolean] true if the player has won
    def won?
      @secret_word.chars.all? { @guessed_letters.include?(it) }
    end

    # Checks whether the player has exhausted all attempts without winning.
    #
    # @return [Boolean] true if the player has lost
    def lost?
      !won? && remaining_attempts.zero?
    end

    # Checks whether the game has reached a win or loss state.
    #
    # @return [Boolean] true if the session has ended
    def over?
      won? || lost?
    end

    # Serializes the current game state into a JSON-compatible Hash.
    #
    # @return [Hash{String => Object}] plain Hash representation of the game
    def to_h
      {
        'secret_word' => @secret_word,
        'max_attempts' => @max_attempts,
        'guessed_letters' => @guessed_letters.dup
      }
    end

    private

    def normalize_secret_word(word)
      normalized = word.to_s.strip.downcase
      unless normalized.match?(Dictionary::WORD_PATTERN)
        raise ArgumentError, 'Secret word must contain only ASCII letters'
      end

      normalized
    end

    def validate_max_attempts(attempts)
      unless attempts.is_a?(Integer) && attempts.positive?
        raise ArgumentError, 'max_attempts must be a positive Integer'
      end

      attempts
    end

    def normalize_guesses(guesses)
      raise ArgumentError, 'guessed_letters must be an Array' unless guesses.is_a?(Array)

      guesses.map { it.to_s.strip.downcase }.grep(LETTER_PATTERN).uniq
    end
  end
end
