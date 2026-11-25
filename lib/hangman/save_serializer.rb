# frozen_string_literal: true

require 'json'
require 'yaml'

module Hangman
  # Encodes and decodes save payloads in JSON and YAML formats.
  module SaveSerializer
    # Default serialization format used when none is specified.
    DEFAULT_FORMAT = :json

    # Canonical file extensions mapped by normalized save format symbol.
    FORMAT_EXTENSIONS = { json: '.json', yaml: '.yml' }.freeze

    # Supported file extensions mapped back to normalized format symbols.
    EXTENSION_FORMATS = { '.json' => :json, '.yml' => :yaml, '.yaml' => :yaml }.freeze

    # Glob pattern matching all supported save file extensions.
    GLOB_PATTERN = '*.{json,yml,yaml}'

    module_function

    # Normalizes a format string or symbol into :json or :yaml.
    #
    # @param format [String, Symbol] requested format name
    # @return [Symbol] normalized :json or :yaml symbol
    # @raise [SaveStore::SaveError] if the format is not supported
    def normalize_format(format)
      case format.to_s.strip.downcase
      when 'json' then :json
      when 'yaml', 'yml' then :yaml
      else raise SaveStore::SaveError, "Unsupported save format '#{format}'. Use 'json' or 'yaml'."
      end
    end

    # Returns the canonical file extension for a save format.
    #
    # @param format [String, Symbol] save format name
    # @return [String] canonical extension including leading dot
    # @raise [SaveStore::SaveError] if the format is not supported
    def extension_for(format)
      FORMAT_EXTENSIONS.fetch(normalize_format(format))
    end

    # Detects the save format from a file path's extension.
    #
    # @param path [String] save file path
    # @return [Symbol] detected :json or :yaml format
    # @raise [SaveStore::SaveError] if the extension is not supported
    def format_for_path(path)
      EXTENSION_FORMATS.fetch(File.extname(path).downcase) do
        raise SaveStore::SaveError, "Unsupported save file extension for '#{path}'"
      end
    end

    # Serializes a save payload Hash into JSON or YAML text.
    #
    # @param payload [Hash] save payload to encode
    # @param format [String, Symbol] target serialization format
    # @return [String] encoded JSON or YAML text
    def dump(payload, format: DEFAULT_FORMAT)
      case normalize_format(format)
      when :json then JSON.pretty_generate(payload)
      when :yaml then YAML.dump(payload)
      end
    end

    # Parses JSON or YAML text safely into Ruby data structures.
    #
    # @param content [String] raw file content
    # @param format [String, Symbol] expected serialization format
    # @return [Object] parsed payload
    # @raise [SaveStore::SaveError] if parsing fails
    def parse(content, format:)
      case normalize_format(format)
      when :json then JSON.parse(content)
      when :yaml then YAML.safe_load(content, permitted_classes: [], aliases: false)
      end
    rescue JSON::ParserError, Psych::Exception => e
      raise SaveStore::SaveError, "Malformed #{format} save data: #{e.message}"
    end
  end
end
