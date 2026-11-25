# frozen_string_literal: true

# Root namespace and configuration paths for Hangman CLI.
module Hangman
  # Absolute path to the repository root directory.
  ROOT_DIR = File.expand_path('..', __dir__)

  # Default path to the bundled dictionary word list.
  DEFAULT_DICTIONARY_PATH = File.join(ROOT_DIR, 'words.txt')

  # Default path to the YAML difficulty configuration file.
  DEFAULT_DIFFICULTIES_PATH = File.join(ROOT_DIR, 'config', 'difficulties.yml')

  # Default directory used to store saved game JSON and YAML files.
  DEFAULT_SAVES_DIR = File.join(ROOT_DIR, 'saves')
end

require_relative 'hangman/version'
require_relative 'hangman/difficulty'
require_relative 'hangman/dictionary'
require_relative 'hangman/game_codec'
require_relative 'hangman/game'
require_relative 'hangman/session_stats'
require_relative 'hangman/save_serializer'
require_relative 'hangman/save_store'
require_relative 'hangman/gallows'
require_relative 'hangman/ansi'
require_relative 'hangman/board_renderer'
require_relative 'hangman/renderer'
require_relative 'hangman/prompter'
require_relative 'hangman/session_runner'
require_relative 'hangman/cli'
