# frozen_string_literal: true

module Hangman
  # Runs the interactive terminal loop for starting, playing, saving, and loading games.
  class CLI
    # Initializes a CLI controller with injectable I/O streams and collaborators.
    #
    # @param input [IO, StringIO] input stream to read user commands from
    # @param output [IO, StringIO] output stream to print prompts and boards to
    # @param dictionary [Dictionary] word source for new games
    # @param save_store [SaveStore] persistence backend for saved games
    # @param renderer [Renderer] formatter for menus, boards, and messages
    def initialize(
      input: $stdin,
      output: $stdout,
      dictionary: Dictionary.new,
      save_store: SaveStore.new,
      renderer: Renderer.new
    )
      @input = input
      @output = output
      @dictionary = dictionary
      @save_store = save_store
      @renderer = renderer
    end

    # Starts the interactive main menu loop until the user quits or reaches EOF.
    #
    # @return [void]
    def run
      @output.puts(@renderer.banner)
      loop do
        @output.puts(@renderer.main_menu(@save_store.list.length))
        break if handle_menu_choice(prompt('Choose an option: ')) == :quit
      end
      @output.puts('Goodbye!')
    end

    private

    def handle_menu_choice(choice)
      case choice&.downcase
      when '1', 'new' then start_new_game
      when '2', 'load' then load_saved_game
      when '3', 'quit', 'exit', nil then return :quit
      else @output.puts('Invalid choice. Please enter 1, 2, or 3.')
      end
      :continue
    end

    def start_new_game
      play_session(Game.new(secret_word: @dictionary.sample))
    rescue Dictionary::EmptyDictionaryError => e
      @output.puts("Error: #{e.message}")
    end

    def load_saved_game
      entries = @save_store.list
      return @output.puts('No saved games found.') if entries.empty?

      @output.puts(@renderer.save_list(entries))
      slot = select_slot_name(entries)
      play_session(@save_store.load(slot)) if slot
    rescue SaveStore::SaveError => e
      @output.puts("Error: #{e.message}")
    end

    def select_slot_name(entries)
      choice = prompt("Enter save number or name (or 'back'): ")
      return nil if choice.nil? || choice.casecmp?('back')
      return choice unless choice.match?(/\A\d+\z/)

      index = choice.to_i - 1
      index.between?(0, entries.length - 1) ? entries[index].name : choice
    end

    def play_session(game)
      until game.over?
        @output.puts(@renderer.board(game))
        break if process_turn(game, prompt('Your guess or command: ')) == :quit
      end
      @output.puts(@renderer.game_over(game)) if game.over?
    end

    def process_turn(game, action)
      return :quit if exit_command?(action)

      if action.casecmp?('save')
        handle_save(game)
      else
        @output.puts(@renderer.guess_feedback(game.guess(action)))
      end
      :continue
    end

    def exit_command?(action)
      action.nil? || %w[quit exit].include?(action.downcase)
    end

    def handle_save(game)
      slot_name = prompt('Enter a save slot name: ')
      return if slot_name.nil? || slot_name.empty?

      saved_slot = @save_store.save(slot_name, game)
      @output.puts("Game saved as '#{saved_slot}'.")
    rescue SaveStore::SaveError => e
      @output.puts("Save failed: #{e.message}")
    end

    def prompt(message)
      @output.print(message)
      @output.flush
      @input.gets&.strip
    end
  end
end
