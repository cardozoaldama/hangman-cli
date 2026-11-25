# frozen_string_literal: true

module Hangman
  # Represents the state and rules of a single Hangman game session.
  class Game
    # Immutable outcome returned for each player guess or hint action.
    GuessResult = Data.define(:outcome, :value)

    # Immutable difficulty rules governing attempts and hints for a session.
    Rules = Data.define(:difficulty, :max_attempts, :max_hints)

    # Default number of incorrect guesses permitted before losing.
    DEFAULT_MAX_ATTEMPTS = 6

    # Default difficulty key for standalone or legacy games.
    DEFAULT_DIFFICULTY = 'normal'

    # Default number of hints permitted when no difficulty preset is supplied.
    DEFAULT_MAX_HINTS = 1

    # Default ruleset matching classic Normal Hangman gameplay.
    DEFAULT_RULES = Rules.new(
      difficulty: DEFAULT_DIFFICULTY,
      max_attempts: DEFAULT_MAX_ATTEMPTS,
      max_hints: DEFAULT_MAX_HINTS
    )

    # Pattern matching a single lowercase ASCII alphabetic letter.
    LETTER_PATTERN = /\A[a-z]\z/

    # Pattern matching a multi-letter lowercase ASCII word guess.
    WORD_GUESS_PATTERN = /\A[a-z]{2,}\z/

    # Target word the player is attempting to uncover.
    # @return [String]
    attr_reader :secret_word

    # Difficulty rules active for this game session.
    # @return [Rules]
    attr_reader :rules

    # Ordered list of unique letters guessed or revealed so far.
    # @return [Array<String>]
    attr_reader :guessed_letters

    # Ordered list of unique incorrect full-word guesses made so far.
    # @return [Array<String>]
    attr_reader :wrong_words

    # Number of hints already consumed in this session.
    # @return [Integer]
    attr_reader :hints_used

    # Creates a new Game configured from a {Difficulty::Level}.
    #
    # @param secret_word [String] alphabetic secret word to guess
    # @param level [Difficulty::Level] difficulty preset defining attempts and hints
    # @return [Game] configured game session
    def self.from_difficulty(secret_word:, level:)
      rules = Rules.new(difficulty: level.key, max_attempts: level.max_attempts, max_hints: level.max_hints)
      new(secret_word:, rules:)
    end

    # Reconstructs a Game instance from a serialized Hash payload.
    #
    # @param data [Hash] serialized game attributes
    # @return [Game] restored game instance
    # @raise [ArgumentError] if required keys are missing or have invalid types
    def self.from_h(data)
      GameCodec.load(data)
    end

    # Creates a new Hangman game session.
    #
    # @param secret_word [String] alphabetic secret word to guess
    # @param rules [Rules] difficulty rules for attempt and hint limits
    # @param guessed_letters [Array<String>] pre-existing guessed letters
    # @param wrong_words [Array<String>] pre-existing incorrect word guesses
    # @param hints_used [Integer] number of hints already consumed
    # @raise [ArgumentError] if any game parameter is invalid
    def initialize(secret_word:, rules: DEFAULT_RULES, guessed_letters: [], wrong_words: [], hints_used: 0)
      @secret_word = normalize_secret_word(secret_word)
      @rules = validate_rules(rules)
      @guessed_letters = GameCodec.normalize_guesses(guessed_letters)
      @wrong_words = GameCodec.normalize_wrong_words(wrong_words)
      @hints_used = GameCodec.validate_non_negative_int(hints_used, 'hints_used')
    end

    # Returns the difficulty key for this session.
    #
    # @return [String] difficulty identifier
    def difficulty = @rules.difficulty

    # Returns the maximum incorrect guesses allowed in this session.
    #
    # @return [Integer] attempt limit
    def max_attempts = @rules.max_attempts

    # Returns the maximum hints allowed in this session.
    #
    # @return [Integer] hint limit
    def max_hints = @rules.max_hints

    # Returns how many hints remain available in this session.
    #
    # @return [Integer] remaining hints (minimum zero)
    def remaining_hints = [max_hints - @hints_used, 0].max

    # Processes one letter or full-word guess and returns an immutable outcome value.
    #
    # @param input [String, #to_s] raw letter or word entered by the player
    # @return [GuessResult] result describing the guess outcome and normalized value
    def guess(input)
      return GuessResult.new(outcome: :finished, value: nil) if over?

      normalized = input.to_s.strip.downcase
      return guess_letter(normalized) if normalized.match?(LETTER_PATTERN)
      return guess_word(normalized) if normalized.match?(WORD_GUESS_PATTERN)

      GuessResult.new(outcome: :invalid, value: normalized)
    end

    # Reveals one unguessed letter from the secret word if hints remain.
    #
    # @return [GuessResult] result with :hint and revealed letter, :no_hints, or :finished
    def use_hint
      return GuessResult.new(outcome: :finished, value: nil) if over?
      return GuessResult.new(outcome: :no_hints, value: nil) if remaining_hints.zero?

      letter = (@secret_word.chars.uniq - @guessed_letters).sample
      @guessed_letters << letter if letter
      @hints_used += 1
      GuessResult.new(outcome: :hint, value: letter)
    end

    # Returns all guessed letters that do not appear in the secret word.
    #
    # @return [Array<String>] incorrect letters in guess order
    def wrong_guesses = @guessed_letters.reject { @secret_word.include?(it) }

    # Returns all guessed letters that appear in the secret word.
    #
    # @return [Array<String>] correct letters in guess order
    def correct_guesses = @guessed_letters.select { @secret_word.include?(it) }

    # Returns total incorrect guesses across letters and full-word guesses.
    #
    # @return [Integer] total penalty count
    def wrong_count = wrong_guesses.length + @wrong_words.length

    # Returns how many incorrect guesses remain before the game is lost.
    #
    # @return [Integer] remaining wrong guesses (minimum zero)
    def remaining_attempts = [max_attempts - wrong_count, 0].max

    # Renders the secret word with unguessed letters replaced by underscores.
    #
    # @return [String] space-separated masked word display
    def masked_word = @secret_word.chars.map { @guessed_letters.include?(it) ? it : '_' }.join(' ')

    # Checks whether every letter of the secret word has been guessed.
    #
    # @return [Boolean] true if the player has won
    def won? = @secret_word.chars.all? { @guessed_letters.include?(it) }

    # Checks whether the player has exhausted all attempts without winning.
    #
    # @return [Boolean] true if the player has lost
    def lost? = !won? && remaining_attempts.zero?

    # Checks whether the game has reached a win or loss state.
    #
    # @return [Boolean] true if the session has ended
    def over? = won? || lost?

    # Serializes the current game state into a JSON/YAML-compatible Hash.
    #
    # @return [Hash{String => Object}] plain Hash representation of the game
    def to_h = GameCodec.dump(self)

    private

    def guess_letter(letter)
      return GuessResult.new(outcome: :duplicate, value: letter) if @guessed_letters.include?(letter)

      @guessed_letters << letter
      outcome = @secret_word.include?(letter) ? :correct : :incorrect
      GuessResult.new(outcome:, value: letter)
    end

    def guess_word(word)
      return reveal_secret_word(word) if word == @secret_word
      return GuessResult.new(outcome: :duplicate_word, value: word) if @wrong_words.include?(word)

      @wrong_words << word
      GuessResult.new(outcome: :word_incorrect, value: word)
    end

    def reveal_secret_word(word)
      (@secret_word.chars.uniq - @guessed_letters).each { @guessed_letters << it }
      GuessResult.new(outcome: :word_correct, value: word)
    end

    def normalize_secret_word(word)
      normalized = word.to_s.strip.downcase
      unless normalized.match?(Dictionary::WORD_PATTERN)
        raise ArgumentError, 'Secret word must contain only ASCII letters'
      end

      normalized
    end

    def validate_rules(rules)
      raise ArgumentError, 'rules must be a Hangman::Game::Rules' unless rules.is_a?(Rules)
      raise ArgumentError, 'max_attempts must be a positive Integer' unless positive_int?(rules.max_attempts)
      raise ArgumentError, 'max_hints must be a non-negative Integer' unless non_negative_int?(rules.max_hints)

      rules
    end

    def positive_int?(value) = value.is_a?(Integer) && value.positive?

    def non_negative_int?(value) = value.is_a?(Integer) && value >= 0
  end
end
