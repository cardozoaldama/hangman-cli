# frozen_string_literal: true

module Hangman
  # Formats menus, game boards, feedback messages, and save lists for terminal display.
  class Renderer
    # Templates mapped by GuessResult#outcome symbols.
    FEEDBACK_MESSAGES = {
      correct: "Good guess! '%<letter>s' is in the word.",
      incorrect: "Sorry, '%<letter>s' is not in the word.",
      duplicate: "You already guessed '%<letter>s'. Try another letter.",
      invalid: 'Please enter a single letter (a-z), "save", or "quit".',
      finished: 'This game is already over.'
    }.freeze

    # Formats the startup title banner.
    #
    # @return [String] decorated title banner with current version
    def banner
      <<~BANNER
        ================================
              Hangman CLI v#{Hangman::VERSION}
        ================================
      BANNER
    end

    # Formats the main menu showing available saved game count.
    #
    # @param save_count [Integer] number of saved game slots available
    # @return [String] formatted main menu text
    def main_menu(save_count)
      <<~MENU

        Main Menu:
          1) New game
          2) Load saved game (#{save_count} available)
          3) Quit
      MENU
    end

    # Formats the active game board with gallows, masked word, and prompt hint.
    #
    # @param game [Game] current game session
    # @return [String] rendered board output
    def board(game)
      wrong = game.wrong_guesses.empty? ? 'none' : game.wrong_guesses.join(', ')
      <<~BOARD

        #{Gallows.stage(game.wrong_guesses.length)}
        Word:               #{game.masked_word}
        Wrong guesses:      #{wrong}
        Remaining attempts: #{game.remaining_attempts}

        Enter a letter (a-z), 'save' to save, or 'quit' to return to menu.
      BOARD
    end

    # Formats feedback for a single guess attempt.
    #
    # @param result [Game::GuessResult] outcome returned by {Game#guess}
    # @return [String] human-readable feedback line
    def guess_feedback(result)
      format(FEEDBACK_MESSAGES.fetch(result.outcome), letter: result.letter)
    end

    # Formats the end-of-game summary revealing the secret word.
    #
    # @param game [Game] completed game session
    # @return [String] final board and win or loss announcement
    def game_over(game)
      <<~SUMMARY

        #{Gallows.stage(game.wrong_guesses.length)}
        Word: #{game.masked_word}
        #{outcome_message(game)}
      SUMMARY
    end

    # Formats a numbered list of saved game slots.
    #
    # @param entries [Array<SaveStore::SaveEntry>] saved game metadata entries
    # @return [String] formatted save slot listing
    def save_list(entries)
      lines = entries.each_with_index.map do |entry, index|
        "  #{index + 1}) #{entry.name} | #{entry.masked_word} | " \
          "#{entry.remaining_attempts} attempts left | #{entry.saved_at}"
      end
      "\nSaved Games:\n#{lines.join("\n")}\n"
    end

    private

    def outcome_message(game)
      if game.won?
        "You won! The word was '#{game.secret_word}'."
      else
        "Game over! The word was '#{game.secret_word}'."
      end
    end
  end
end
