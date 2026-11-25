# frozen_string_literal: true

module Hangman
  # Serializes and validates Game state hashes for backward-compatible save files.
  #
  # @api private
  module GameCodec
    module_function

    # Converts a Game instance into a plain Hash suitable for JSON or YAML.
    #
    # @param game [Game] game session to serialize
    # @return [Hash{String => Object}] plain Hash representation
    def dump(game)
      {
        'secret_word' => game.secret_word,
        'difficulty' => game.difficulty,
        'max_attempts' => game.max_attempts,
        'max_hints' => game.max_hints,
        'hints_used' => game.hints_used,
        'guessed_letters' => game.guessed_letters.dup,
        'wrong_words' => game.wrong_words.dup
      }
    end

    # Validates a Hash payload and reconstructs a Game instance.
    #
    # @param data [Object] parsed save payload expected to be a Hash
    # @return [Game] restored game session
    # @raise [ArgumentError] if required fields are missing or have invalid types
    def load(data)
      validate_payload!(data)
      Game.new(
        secret_word: data.fetch('secret_word'),
        rules: build_rules(data),
        guessed_letters: data.fetch('guessed_letters'),
        wrong_words: optional_array(data, 'wrong_words'),
        hints_used: optional_non_negative_int(data, 'hints_used', 0)
      )
    end

    # Normalizes a list of guessed single letters.
    #
    # @param guesses [Object] candidate array of guessed letters
    # @return [Array<String>] deduplicated lowercase single letters
    # @raise [ArgumentError] if guesses is not an Array
    def normalize_guesses(guesses)
      raise ArgumentError, 'guessed_letters must be an Array' unless guesses.is_a?(Array)

      guesses.map { it.to_s.strip.downcase }.grep(Game::LETTER_PATTERN).uniq
    end

    # Normalizes a list of incorrect full-word guesses.
    #
    # @param words [Object] candidate array of wrong word guesses
    # @return [Array<String>] deduplicated lowercase multi-letter words
    # @raise [ArgumentError] if words is not an Array
    def normalize_wrong_words(words)
      raise ArgumentError, 'wrong_words must be an Array' unless words.is_a?(Array)

      words.map { it.to_s.strip.downcase }.grep(Game::WORD_GUESS_PATTERN).uniq
    end

    # Validates a non-negative integer field.
    #
    # @param count [Object] candidate integer value
    # @param name [String] field name for error reporting
    # @return [Integer] validated integer
    # @raise [ArgumentError] if count is not a non-negative Integer
    def validate_non_negative_int(count, name)
      return count if count.is_a?(Integer) && count >= 0

      raise ArgumentError, "#{name} must be a non-negative Integer"
    end

    def validate_payload!(data)
      raise ArgumentError, 'Saved game data must be a Hash' unless data.is_a?(Hash)
      raise ArgumentError, 'Invalid secret_word in saved data' unless data['secret_word'].is_a?(String)
      raise ArgumentError, 'Invalid max_attempts in saved data' unless data['max_attempts'].is_a?(Integer)
      raise ArgumentError, 'Invalid guessed_letters in saved data' unless data['guessed_letters'].is_a?(Array)
    end
    private_class_method :validate_payload!

    def build_rules(data)
      Game::Rules.new(
        difficulty: optional_string(data, 'difficulty', Game::DEFAULT_DIFFICULTY),
        max_attempts: data.fetch('max_attempts'),
        max_hints: optional_non_negative_int(data, 'max_hints', Game::DEFAULT_MAX_HINTS)
      )
    end
    private_class_method :build_rules

    def optional_array(data, key)
      value = data.fetch(key, [])
      raise ArgumentError, "Invalid #{key} in saved data" unless value.is_a?(Array)

      value
    end
    private_class_method :optional_array

    def optional_string(data, key, fallback)
      value = data.fetch(key, fallback)
      raise ArgumentError, "Invalid #{key} in saved data" unless value.is_a?(String)

      value
    end
    private_class_method :optional_string

    def optional_non_negative_int(data, key, fallback)
      value = data.fetch(key, fallback)
      validate_non_negative_int(value, key)
    end
    private_class_method :optional_non_negative_int
  end
end
