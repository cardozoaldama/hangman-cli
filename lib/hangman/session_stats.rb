# frozen_string_literal: true

module Hangman
  # Tracks win/loss counts and streaks across an interactive CLI session.
  class SessionStats
    # Number of games won in the current session.
    # @return [Integer]
    attr_reader :wins

    # Number of games lost in the current session.
    # @return [Integer]
    attr_reader :losses

    # Current consecutive wins.
    # @return [Integer]
    attr_reader :streak

    # Longest consecutive win streak achieved in the current session.
    # @return [Integer]
    attr_reader :best_streak

    # Initializes all session statistics counters to zero.
    def initialize
      @wins = 0
      @losses = 0
      @streak = 0
      @best_streak = 0
    end

    # Records the outcome of a finished game round.
    #
    # @param won [Boolean] whether the player won the round
    # @return [void]
    def record(won:)
      if won
        @wins += 1
        @streak += 1
        @best_streak = [@best_streak, @streak].max
      else
        @losses += 1
        @streak = 0
      end
    end

    # Returns total completed games in the current session.
    #
    # @return [Integer] total wins plus losses
    def played
      @wins + @losses
    end

    # Checks whether at least one game has been completed in this session.
    #
    # @return [Boolean] true if one or more rounds finished
    def any?
      played.positive?
    end
  end
end
