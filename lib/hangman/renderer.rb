# frozen_string_literal: true

module Hangman
  # Formats menus, game boards, letter banks, feedback messages, and save lists for terminal display.
  class Renderer
    # Templates mapped by {Game::GuessResult#outcome} symbols.
    FEEDBACK_MESSAGES = {
      correct: "Good guess! '%<value>s' is in the word.",
      incorrect: "Sorry, '%<value>s' is not in the word.",
      duplicate: "You already guessed '%<value>s'. Try another letter.",
      word_correct: "Bullseye! '%<value>s' is the secret word!",
      word_incorrect: "Sorry, '%<value>s' is not the secret word.",
      duplicate_word: "You already tried '%<value>s'. Try another guess.",
      hint: "Hint: the letter '%<value>s' is in the word.",
      no_hints: 'No hints remaining for this game.',
      invalid: "Enter a letter (a-z), a word guess, or 'hint', 'save', 'help', 'quit'.",
      finished: 'This game is already over.'
    }.freeze

    # Accent colors mapped by {Game::GuessResult#outcome} symbols.
    FEEDBACK_COLORS = {
      correct: :green,
      word_correct: :green,
      hint: :cyan,
      incorrect: :red,
      word_incorrect: :red,
      duplicate: :yellow,
      duplicate_word: :yellow,
      no_hints: :yellow,
      invalid: :yellow
    }.freeze

    # Initializes a terminal renderer.
    #
    # @param color [Boolean] whether to emit ANSI color escape codes
    def initialize(color: false)
      @color = color
      @board_renderer = BoardRenderer.new(color:)
    end

    # Formats the startup title banner.
    #
    # @return [String] decorated title banner with current version
    def banner
      text = <<~BANNER
        ================================
              Hangman CLI v#{Hangman::VERSION}
        ================================
      BANNER
      style(text, :cyan, :bold)
    end

    # Formats the main menu showing saved game count and optional session scoreboard.
    #
    # @param save_count [Integer] number of saved game slots available
    # @param stats [SessionStats, nil] optional session scoreboard
    # @return [String] formatted main menu text
    def main_menu(save_count, stats: nil)
      lines = [
        '', 'Main Menu:', '  1) New game',
        "  2) Load saved game (#{save_count} available)",
        '  3) Delete saved game', '  4) Quit'
      ]
      lines.insert(1, @board_renderer.stats_line(stats)) if stats&.any?
      "#{lines.join("\n")}\n"
    end

    # Formats the difficulty selection menu.
    #
    # @param levels [Array<Difficulty::Level>] configured difficulty tiers
    # @return [String] formatted difficulty selection text
    def difficulty_menu(levels)
      lines = levels.each_with_index.map do |level, index|
        "  #{index + 1}) #{level.label.ljust(7)} | #{level.min_length}-#{level.max_length} letters | " \
          "#{level.max_attempts} attempts | #{level.max_hints} hints"
      end
      "\nChoose Difficulty:\n#{lines.join("\n")}\n"
    end

    # Formats the active game board with scaled gallows, masked word, and A-Z letter bank.
    #
    # @param game [Game] current game session
    # @return [String] rendered board output
    def board(game) = @board_renderer.board(game)

    # Formats the in-game command reference.
    #
    # @return [String] help text listing available commands
    def help
      <<~HELP

        Commands:
          a-z        Guess a single letter
          word       Guess the full secret word (costs 1 attempt if wrong)
          hint       Reveal one unguessed letter (if hints remain)
          save       Save current progress as JSON or YAML
          help       Show this command list
          quit/exit  Return to the main menu
      HELP
    end

    # Formats feedback for a single guess or hint action.
    #
    # @param result [Game::GuessResult] outcome returned by {Game#guess} or {Game#use_hint}
    # @return [String] human-readable feedback line
    def guess_feedback(result)
      message = format(FEEDBACK_MESSAGES.fetch(result.outcome), value: result.value)
      color = FEEDBACK_COLORS[result.outcome]
      color ? style(message, color) : message
    end

    # Formats the end-of-game summary revealing the secret word and session stats.
    #
    # @param game [Game] completed game session
    # @param stats [SessionStats, nil] optional session scoreboard
    # @return [String] final board and win or loss announcement
    def game_over(game, stats: nil) = @board_renderer.game_over(game, stats:)

    # Formats a numbered list of saved game slots across JSON and YAML formats.
    #
    # @param entries [Array<SaveStore::SaveEntry>] saved game metadata entries
    # @return [String] formatted save slot listing
    def save_list(entries)
      lines = entries.each_with_index.map do |entry, index|
        tag = entry.format.to_s.upcase
        "  #{index + 1}) #{entry.name} [#{tag}] (#{entry.difficulty}) | #{entry.masked_word} | " \
          "#{entry.remaining_attempts} left | #{entry.saved_at}"
      end
      "\nSaved Games:\n#{lines.join("\n")}\n"
    end

    private

    def style(text, *codes) = Ansi.style(text, *codes, enabled: @color)
  end
end
