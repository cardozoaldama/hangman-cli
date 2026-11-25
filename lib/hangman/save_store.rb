# frozen_string_literal: true

require 'fileutils'
require 'time'

module Hangman
  # Persists and restores Hangman game sessions as JSON or YAML files.
  class SaveStore
    # Raised when saving, listing, loading, or deleting a game slot fails.
    class SaveError < StandardError; end

    # Lightweight metadata summary of a saved game slot.
    SaveEntry = Data.define(:name, :format, :difficulty, :saved_at, :masked_word, :remaining_attempts)

    # Pattern restricting save slot names to safe filename characters.
    VALID_NAME_PATTERN = /\A[a-z0-9_-]+\z/

    # Initializes a save store rooted at the given directory.
    #
    # @param directory [String] directory path where JSON and YAML save files live
    def initialize(directory: DEFAULT_SAVES_DIR)
      @directory = directory
    end

    # Saves a game session to a sanitized JSON or YAML slot file.
    #
    # @param name [String] desired save slot name
    # @param game [Game] game session to serialize
    # @param format [String, Symbol] target save format (:json or :yaml)
    # @return [String] sanitized slot name written to disk
    # @raise [SaveError] if the slot name, format, or file write fails
    def save(name, game, format: SaveSerializer::DEFAULT_FORMAT)
      slot = sanitize_name(name)
      fmt = SaveSerializer.normalize_format(format)
      FileUtils.mkdir_p(@directory)
      File.write(slot_path(slot, fmt), SaveSerializer.dump(build_payload(game), format: fmt))
      slot
    rescue SystemCallError => e
      raise SaveError, "Could not write save '#{slot}': #{e.message}"
    end

    # Loads and reconstructs a saved Game from a slot name and optional format.
    #
    # @param name [String] save slot name to load
    # @param format [String, Symbol, nil] optional format to disambiguate matching slots
    # @return [Game] restored game session
    # @raise [SaveError] if the slot is missing, ambiguous, or contains invalid data
    def load(name, format: nil)
      payload = parse_payload(resolve_existing_path(name, format:))
      Game.from_h(payload.fetch('game'))
    rescue ArgumentError, TypeError, SystemCallError => e
      raise SaveError, "Could not load save '#{name}': #{e.message}"
    end

    # Lists all valid saved game entries across JSON and YAML files, sorted newest first.
    #
    # @return [Array<SaveEntry>] metadata entries for available saves
    def list
      return [] unless Dir.exist?(@directory)

      Dir.glob(File.join(@directory, SaveSerializer::GLOB_PATTERN))
         .filter_map { build_entry(it) }
         .sort { |a, b| [b.saved_at, a.name, a.format.to_s] <=> [a.saved_at, b.name, b.format.to_s] }
    end

    # Checks whether a valid saved slot exists on disk.
    #
    # @param name [String] candidate slot name
    # @param format [String, Symbol, nil] optional format filter
    # @return [Boolean] true if a matching slot file exists
    def exists?(name, format: nil)
      slot = normalize_name(name)
      return false unless slot.match?(VALID_NAME_PATTERN)

      !matching_paths(slot, format:).empty?
    end

    # Deletes a saved game slot if it exists.
    #
    # @param name [String] save slot name to remove
    # @param format [String, Symbol, nil] optional format to disambiguate matching slots
    # @return [String, nil] deleted slot name, or nil if not present
    # @raise [SaveError] if the slot name is invalid or multiple formats match
    def delete(name, format: nil)
      slot = sanitize_name(name)
      paths = matching_paths(slot, format:)
      return nil if paths.empty?
      raise SaveError, ambiguous_message(name) if paths.length > 1

      File.delete(paths.first)
      slot
    end

    private

    def normalize_name(name) = name.to_s.strip.downcase.tr(' ', '_')

    def sanitize_name(name)
      slot = normalize_name(name)
      return slot if slot.match?(VALID_NAME_PATTERN)

      raise SaveError, 'Save name must use only letters, digits, hyphens, or underscores'
    end

    def slot_path(slot, format) = File.join(@directory, "#{slot}#{SaveSerializer.extension_for(format)}")

    def matching_paths(slot, format: nil)
      if format
        path = slot_path(slot, format)
        return File.file?(path) ? [path] : []
      end

      SaveSerializer::EXTENSION_FORMATS.keys
                                       .map { File.join(@directory, "#{slot}#{it}") }
                                       .select { File.file?(it) }
    end

    def resolve_existing_path(name, format: nil)
      paths = matching_paths(sanitize_name(name), format:)
      raise SaveError, "Save slot '#{name}' not found" if paths.empty?
      raise SaveError, ambiguous_message(name) if paths.length > 1

      paths.first
    end

    def ambiguous_message(name) = "Multiple save formats exist for '#{name}'. Select by number or format."

    def build_payload(game)
      {
        'version' => Hangman::VERSION,
        'saved_at' => Time.now.utc.iso8601,
        'game' => game.to_h
      }
    end

    def parse_payload(path)
      data = SaveSerializer.parse(File.read(path), format: SaveSerializer.format_for_path(path))
      raise SaveError, 'Malformed save file structure' unless data.is_a?(Hash) && data['game'].is_a?(Hash)

      data
    end

    def build_entry(path)
      payload = parse_payload(path)
      game = Game.from_h(payload['game'])
      create_entry(path, payload, game)
    rescue SaveError, ArgumentError, TypeError, SystemCallError
      nil
    end

    def create_entry(path, payload, game)
      SaveEntry.new(
        name: File.basename(path, File.extname(path)),
        format: SaveSerializer.format_for_path(path),
        difficulty: game.difficulty,
        saved_at: payload['saved_at'].to_s,
        masked_word: game.masked_word,
        remaining_attempts: game.remaining_attempts
      )
    end
  end
end
