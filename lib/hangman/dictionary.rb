# frozen_string_literal: true

module Hangman
  # Loads and samples eligible secret words from a newline-delimited word list.
  class Dictionary
    # Raised when the word list file is missing or contains no eligible words.
    class EmptyDictionaryError < StandardError; end

    # Default minimum character length for secret words.
    MIN_LENGTH = 5

    # Default maximum character length for secret words.
    MAX_LENGTH = 12

    # Pattern matching lowercase ASCII alphabetic words.
    WORD_PATTERN = /\A[a-z]+\z/

    # Initializes a dictionary reader for the given word file and default length bounds.
    #
    # @param path [String] path to the newline-delimited word list file
    # @param min_length [Integer] default minimum word length to include
    # @param max_length [Integer] default maximum word length to include
    def initialize(path: DEFAULT_DICTIONARY_PATH, min_length: MIN_LENGTH, max_length: MAX_LENGTH)
      @path = path
      @min_length = min_length
      @max_length = max_length
    end

    # Returns all eligible, deduplicated lowercase words within the given length bounds.
    #
    # @param min_length [Integer] minimum word length to include
    # @param max_length [Integer] maximum word length to include
    # @return [Array<String>] frozen list of valid secret words
    # @raise [EmptyDictionaryError] if the dictionary file cannot be read
    def words(min_length: @min_length, max_length: @max_length)
      all_words.select { it.length.between?(min_length, max_length) }.freeze
    end

    # Returns one randomly selected eligible word within the given length bounds.
    #
    # @param min_length [Integer] minimum word length to include
    # @param max_length [Integer] maximum word length to include
    # @return [String] a randomly chosen secret word
    # @raise [EmptyDictionaryError] if no eligible words are available
    def sample(min_length: @min_length, max_length: @max_length)
      word = words(min_length:, max_length:).sample
      raise EmptyDictionaryError, "No eligible words found in #{@path}" unless word

      word
    end

    private

    def all_words
      @all_words ||= load_all_words
    end

    def load_all_words
      File.readlines(@path, chomp: true)
          .map { it.strip.downcase }
          .grep(WORD_PATTERN)
          .uniq
          .freeze
    rescue Errno::ENOENT => e
      raise EmptyDictionaryError, "Word list not found at #{@path}: #{e.message}"
    end
  end
end
