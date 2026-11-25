# frozen_string_literal: true

module Hangman
  # Runs the interactive turn loop for a single active Hangman game session.
  class SessionRunner
    include Prompter

    # Commands that terminate the active session and return to the main menu.
    EXIT_COMMANDS = %w[quit exit].freeze

    # Initializes a session runner with I/O streams and persistence/display collaborators.
    #
    # @param input [IO, StringIO] input stream to read player actions from
    # @param output [IO, StringIO] output stream to print boards and feedback to
    # @param save_store [SaveStore] persistence backend for saving games
    # @param renderer [Renderer] formatter for game boards and feedback
    def initialize(input:, output:, save_store:, renderer:)
      @input = input
      @output = output
      @save_store = save_store
      @renderer = renderer
    end

    # Plays turns until the game finishes or the player quits to the menu.
    #
    # @param game [Game] active game session
    # @return [Symbol] :completed if the game ended, or :quit if exited early
    def play(game)
      until game.over?
        @output.puts(@renderer.board(game))
        return :quit if process_turn(game, prompt('Your guess or command: ')) == :quit
      end
      :completed
    end

    private

    def process_turn(game, action)
      return :quit if exit_command?(action)

      dispatch_command(game, action)
      :continue
    end

    def dispatch_command(game, action)
      case action.downcase
      when 'help' then @output.puts(@renderer.help)
      when 'hint' then @output.puts(@renderer.guess_feedback(game.use_hint))
      when 'save' then handle_save(game)
      else @output.puts(@renderer.guess_feedback(game.guess(action)))
      end
    end

    def exit_command?(action) = action.nil? || EXIT_COMMANDS.include?(action.downcase)

    def handle_save(game)
      slot_name = prompt('Enter a save slot name: ')
      return if slot_name.nil? || slot_name.empty?

      format = prompt_save_format
      return unless confirm_overwrite?(slot_name, format)

      saved_slot = @save_store.save(slot_name, game, format:)
      @output.puts("Game saved as '#{saved_slot}' (#{format}).")
    rescue SaveStore::SaveError => e
      @output.puts("Save failed: #{e.message}")
    end

    def prompt_save_format
      choice = prompt('Save format (json/yaml) [json]: ')
      raw = choice.nil? || choice.empty? ? 'json' : choice
      SaveSerializer.normalize_format(raw)
    end

    def confirm_overwrite?(slot_name, format)
      return true unless @save_store.exists?(slot_name, format:)

      confirm?("Overwrite existing save '#{slot_name}' (#{format})? (y/n): ")
    end
  end
end
