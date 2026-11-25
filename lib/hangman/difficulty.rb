# frozen_string_literal: true

require 'yaml'

module Hangman
  # Loads and validates difficulty tier presets from a YAML configuration file.
  class Difficulty
    # Raised when the difficulty configuration file is missing or malformed.
    class ConfigError < StandardError; end

    # Immutable definition of a single difficulty tier.
    Level = Data.define(:key, :label, :min_length, :max_length, :max_attempts, :max_hints)

    # Default difficulty key used when no tier is explicitly chosen.
    DEFAULT_KEY = 'normal'

    # Initializes a difficulty loader for the given YAML file path.
    #
    # @param path [String] path to the YAML difficulties configuration file
    def initialize(path: DEFAULT_DIFFICULTIES_PATH)
      @path = path
    end

    # Returns all validated difficulty levels defined in the YAML file.
    #
    # @return [Array<Level>] frozen list of configured difficulty levels
    # @raise [ConfigError] if the file cannot be read or contains invalid data
    def all
      @all ||= load_levels
    end

    # Finds a difficulty level by its normalized string or symbol key.
    #
    # @param key [String, Symbol] difficulty key such as 'easy', 'normal', or 'hard'
    # @return [Level] matching difficulty level
    # @raise [ConfigError] if the requested difficulty key does not exist
    def fetch(key)
      normalized = key.to_s.strip.downcase
      level = all.find { it.key == normalized }
      raise ConfigError, "Unknown difficulty '#{key}'" unless level

      level
    end

    # Returns the default difficulty level ('normal' if present, otherwise the first tier).
    #
    # @return [Level] default difficulty level
    # @raise [ConfigError] if the configuration cannot be loaded
    def default
      all.find { it.key == DEFAULT_KEY } || all.first
    end

    private

    def load_levels
      raw = YAML.safe_load_file(@path, permitted_classes: [], aliases: false)
      unless raw.is_a?(Hash) && !raw.empty?
        raise ConfigError, "Difficulty config at #{@path} must be a non-empty mapping"
      end

      raw.map { |key, attrs| build_level(key, attrs) }.freeze
    rescue Errno::ENOENT, Psych::Exception => e
      raise ConfigError, "Could not load difficulties from #{@path}: #{e.message}"
    end

    def build_level(key, attrs)
      raise ConfigError, "Difficulty '#{key}' must be a mapping" unless attrs.is_a?(Hash)

      fields = validated_fields(key, attrs)
      Level.new(key: key.to_s.strip.downcase, **fields)
    end

    def validated_fields(key, attrs)
      min_len, max_len = validate_bounds(key, attrs)
      {
        label: validate_label(key, attrs['label']),
        min_length: min_len,
        max_length: max_len,
        max_attempts: validate_positive_int(key, attrs['max_attempts'], 'max_attempts'),
        max_hints: validate_non_negative_int(key, attrs['max_hints'], 'max_hints')
      }
    end

    def validate_bounds(key, attrs)
      min_len = validate_positive_int(key, attrs['min_length'], 'min_length')
      max_len = validate_positive_int(key, attrs['max_length'], 'max_length')
      raise ConfigError, "Difficulty '#{key}' has min_length > max_length" if min_len > max_len

      [min_len, max_len]
    end

    def validate_label(key, label)
      text = label.to_s.strip
      raise ConfigError, "Difficulty '#{key}' must define a label" unless label.is_a?(String) && !text.empty?

      text
    end

    def validate_positive_int(key, value, field)
      return value if value.is_a?(Integer) && value.positive?

      raise ConfigError, "Difficulty '#{key}' #{field} must be a positive Integer"
    end

    def validate_non_negative_int(key, value, field)
      return value if value.is_a?(Integer) && value >= 0

      raise ConfigError, "Difficulty '#{key}' #{field} must be a non-negative Integer"
    end
  end
end
