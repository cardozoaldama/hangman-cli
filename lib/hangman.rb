# frozen_string_literal: true

# Root namespace and configuration paths for Hangman CLI.
module Hangman
  # Absolute path to the repository root directory.
  ROOT_DIR = File.expand_path('..', __dir__)

  # Default path to the bundled dictionary word list.
  DEFAULT_DICTIONARY_PATH = File.join(ROOT_DIR, 'words.txt')

  # Default directory used to store saved game JSON files.
  DEFAULT_SAVES_DIR = File.join(ROOT_DIR, 'saves')
end

require_relative 'hangman/version'
require_relative 'hangman/dictionary'
require_relative 'hangman/game'
