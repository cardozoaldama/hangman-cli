# frozen_string_literal: true

module Hangman
  # Runs the interactive terminal loop for starting, playing, saving, loading, and deleting games.
  class CLI
    include Prompter

    # Initializes a CLI controller with injectable I/O streams and collaborators.
    #
    # @param input [IO, StringIO] input stream to read user commands from
    # @param output [IO, StringIO] output stream to print prompts and boards to
    # @param dictionary [Dictionary] word source for new games
    # @param save_store [SaveStore] persistence backend for saved games
    # @param difficulties [Difficulty] difficulty preset loader
    def initialize(
      input: $stdin,
      output: $stdout,
      dictionary: Dictionary.new,
      save_store: SaveStore.new,
      difficulties: Difficulty.new
    )
      @input = input
      @output = output
      @dictionary = dictionary
      @save_store = save_store
      @difficulties = difficulties
      @renderer = Renderer.new(color: color_enabled?(output))
      @stats = SessionStats.new
      @runner = SessionRunner.new(input:, output:, save_store:, renderer: @renderer)
    end

    # Starts the interactive main menu loop until the user quits or reaches EOF.
    #
    # @return [void]
    def run
      @output.puts(@renderer.banner)
      loop do
        @output.puts(@renderer.main_menu(@save_store.list.length, stats: @stats))
        break if handle_menu_choice(prompt('Choose an option: ')) == :quit
      end
      @output.puts('Goodbye!')
    end

    private

    def color_enabled?(output) = output.respond_to?(:tty?) && output.tty? && ENV['NO_COLOR'].to_s.empty?

    def handle_menu_choice(choice)
      case choice&.downcase
      when '1', 'new' then start_new_game
      when '2', 'load' then load_saved_game
      when '3', 'delete' then delete_saved_game
      when '4', 'quit', 'exit', nil then return :quit
      else @output.puts('Invalid choice. Please enter 1, 2, 3, or 4.')
      end
      :continue
    end

    def start_new_game
      level = select_difficulty
      return unless level

      loop do
        break unless play_round(level) == :completed
        break unless confirm?("Play again on #{level.label}? (y/n): ")
      end
    rescue Difficulty::ConfigError, Dictionary::EmptyDictionaryError => e
      @output.puts("Error: #{e.message}")
    end

    def select_difficulty
      levels = @difficulties.all
      @output.puts(@renderer.difficulty_menu(levels))
      choice = prompt("Choose difficulty (1-#{levels.length}, name, or 'back'): ")
      return nil if back_choice?(choice)
      return levels[choice.to_i - 1] if numbered_choice?(choice, levels.length)

      @difficulties.fetch(choice)
    end

    def play_round(level)
      word = @dictionary.sample(min_length: level.min_length, max_length: level.max_length)
      finish_session(Game.from_difficulty(secret_word: word, level:))
    end

    def load_saved_game
      target = pick_save_target
      return unless target

      finish_session(@save_store.load(target[0], format: target[1]))
    rescue SaveStore::SaveError => e
      @output.puts("Error: #{e.message}")
    end

    def delete_saved_game
      target = pick_save_target
      return unless target

      label = target[1] ? "'#{target[0]}' (#{target[1]})" : "'#{target[0]}'"
      return unless confirm?("Delete #{label}? (y/n): ")

      deleted = @save_store.delete(target[0], format: target[1])
      @output.puts(deleted ? "Deleted save '#{deleted}'." : "Save slot '#{target[0]}' not found.")
    rescue SaveStore::SaveError => e
      @output.puts("Error: #{e.message}")
    end

    def finish_session(game)
      outcome = @runner.play(game)
      if game.over?
        @stats.record(won: game.won?)
        @output.puts(@renderer.game_over(game, stats: @stats))
      end
      outcome
    end

    def pick_save_target
      entries = @save_store.list
      return @output.puts('No saved games found.') && nil if entries.empty?

      @output.puts(@renderer.save_list(entries))
      resolve_save_choice(entries)
    end

    def resolve_save_choice(entries)
      choice = prompt("Enter save number or name (or 'back'): ")
      return nil if back_choice?(choice)
      return entry_target(entries[choice.to_i - 1]) if numbered_choice?(choice, entries.length)

      [choice, nil]
    end

    def entry_target(entry) = [entry.name, entry.format]
  end
end
