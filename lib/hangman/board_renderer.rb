# frozen_string_literal: true

module Hangman
  # Renders active game boards, A-Z letter banks, and end-of-game summaries.
  #
  # @api private
  class BoardRenderer
    # Two-row layout of lowercase ASCII letters for the visual letter tracker.
    ALPHABET_ROWS = [('a'..'m').to_a.freeze, ('n'..'z').to_a.freeze].freeze

    # Initializes a board renderer.
    #
    # @param color [Boolean] whether to emit ANSI color escape codes
    def initialize(color: false)
      @color = color
    end

    # Formats the active game board with scaled gallows, masked word, and A-Z letter bank.
    #
    # @param game [Game] current game session
    # @return [String] rendered board output
    def board(game)
      sections = [
        '',
        board_header(game),
        Gallows.stage(game.wrong_count, max_attempts: game.max_attempts).chomp,
        board_status(game),
        '',
        "Guess a letter or full word, or enter 'hint', 'save', 'help', 'quit'."
      ]
      "#{sections.join("\n")}\n"
    end

    # Formats the end-of-game summary revealing the secret word and session stats.
    #
    # @param game [Game] completed game session
    # @param stats [SessionStats, nil] optional session scoreboard
    # @return [String] final board and win or loss announcement
    def game_over(game, stats: nil)
      lines = [
        '',
        Gallows.stage(game.wrong_count, max_attempts: game.max_attempts).chomp,
        "Word: #{game.masked_word}",
        outcome_message(game)
      ]
      lines << stats_line(stats) if stats&.any?
      "#{lines.join("\n")}\n"
    end

    # Formats a one-line summary of the session win/loss scoreboard.
    #
    # @param stats [SessionStats] session statistics tracker
    # @return [String] formatted scoreboard line
    def stats_line(stats)
      style("Session: #{stats.wins}W-#{stats.losses}L | Streak: #{stats.streak} (Best: #{stats.best_streak})", :cyan)
    end

    private

    def style(text, *codes) = Ansi.style(text, *codes, enabled: @color)

    def board_header(game)
      style("Difficulty: #{game.difficulty.capitalize} | Hints left: #{game.remaining_hints}/#{game.max_hints}", :cyan)
    end

    def board_status(game)
      lines = [
        "Word:               #{style(game.masked_word, :bold)}",
        "Letters:            #{letter_bank(game)}",
        "Remaining attempts: #{game.remaining_attempts}/#{game.max_attempts}"
      ]
      lines.insert(2, "Wrong words:        #{game.wrong_words.join(', ')}") unless game.wrong_words.empty?
      lines.join("\n")
    end

    def letter_bank(game)
      ALPHABET_ROWS
        .map { |row| row.map { format_letter(it, game) }.join(' ') }
        .join("\n                    ")
    end

    def format_letter(letter, game)
      return style_letter(letter, :green, "[#{letter}]") if game.correct_guesses.include?(letter)
      return style_letter(letter, :red, '·') if game.wrong_guesses.include?(letter)

      letter
    end

    def style_letter(letter, color, plain) = @color ? style(letter, color) : plain

    def outcome_message(game)
      if game.won?
        style("You won! The word was '#{game.secret_word}'.", :green, :bold)
      else
        style("Game over! The word was '#{game.secret_word}'.", :red, :bold)
      end
    end
  end
end
