# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'

module Hangman
  # Persists and restores Hangman game sessions as JSON files.
  class SaveStore
    # Raised when saving, listing, or loading a game slot fails.
    class SaveError < StandardError; end

    # Lightweight metadata summary of a saved game slot.
    SaveEntry = Data.define(:name, :saved_at, :masked_word, :remaining_attempts)

    # Pattern restricting save slot names to safe filename characters.
    VALID_NAME_PATTERN = /\A[a-z0-9_-]+\z/

    # Initializes a save store rooted at the given directory.
    #
    # @param directory [String] directory path where JSON save files live
    def initialize(directory: DEFAULT_SAVES_DIR)
      @directory = directory
    end

    # Saves a game session to a sanitized JSON slot file.
    #
    # @param name [String] desired save slot name
    # @param game [Game] game session to serialize
    # @return [String] sanitized slot name written to disk
    # @raise [SaveError] if the slot name is invalid or writing fails
    def save(name, game)
      slot = sanitize_name(name)
      FileUtils.mkdir_p(@directory)
      File.write(slot_path(slot), JSON.pretty_generate(build_payload(game)))
      slot
    rescue SystemCallError => e
      raise SaveError, "Could not write save '#{slot}': #{e.message}"
    end

    # Loads and reconstructs a saved Game from a slot name.
    #
    # @param name [String] save slot name to load
    # @return [Game] restored game session
    # @raise [SaveError] if the slot does not exist or contains invalid data
    def load(name)
      payload = parse_payload(resolve_existing_path(name))
      Game.from_h(payload.fetch('game'))
    rescue JSON::ParserError, ArgumentError, TypeError, SystemCallError => e
      raise SaveError, "Could not load save '#{name}': #{e.message}"
    end

    # Lists all valid saved game entries sorted newest first.
    #
    # @return [Array<SaveEntry>] metadata entries for available saves
    def list
      return [] unless Dir.exist?(@directory)

      Dir.glob(File.join(@directory, '*.json'))
         .filter_map { build_entry(it) }
         .sort { |a, b| [b.saved_at, a.name] <=> [a.saved_at, b.name] }
    end

    # Checks whether a valid saved slot exists on disk.
    #
    # @param name [String] candidate slot name
    # @return [Boolean] true if the slot file exists
    def exists?(name)
      slot = normalize_name(name)
      return false unless slot.match?(VALID_NAME_PATTERN)

      File.file?(slot_path(slot))
    end

    # Deletes a saved game slot if it exists.
    #
    # @param name [String] save slot name to remove
    # @return [String, nil] deleted slot name, or nil if not present
    # @raise [SaveError] if the slot name is invalid
    def delete(name)
      slot = sanitize_name(name)
      path = slot_path(slot)
      return nil unless File.file?(path)

      File.delete(path)
      slot
    end

    private

    def normalize_name(name)
      name.to_s.strip.downcase.tr(' ', '_')
    end

    def sanitize_name(name)
      slot = normalize_name(name)
      unless slot.match?(VALID_NAME_PATTERN)
        raise SaveError, 'Save name must use only letters, digits, hyphens, or underscores'
      end

      slot
    end

    def slot_path(slot)
      File.join(@directory, "#{slot}.json")
    end

    def resolve_existing_path(name)
      path = slot_path(sanitize_name(name))
      raise SaveError, "Save slot '#{name}' not found" unless File.file?(path)

      path
    end

    def build_payload(game)
      {
        'version' => Hangman::VERSION,
        'saved_at' => Time.now.utc.iso8601,
        'game' => game.to_h
      }
    end

    def parse_payload(path)
      data = JSON.parse(File.read(path))
      raise SaveError, 'Malformed save file structure' unless data.is_a?(Hash) && data['game'].is_a?(Hash)

      data
    end

    def build_entry(path)
      payload = parse_payload(path)
      game = Game.from_h(payload['game'])
      SaveEntry.new(
        name: File.basename(path, '.json'),
        saved_at: payload['saved_at'].to_s,
        masked_word: game.masked_word,
        remaining_attempts: game.remaining_attempts
      )
    rescue SaveError, JSON::ParserError, ArgumentError, TypeError, SystemCallError
      nil
    end
  end
end
