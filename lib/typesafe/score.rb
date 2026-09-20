# frozen_string_literal: true

module Typesafe
  # A question that positions the state along an ordered spectrum of levels.
  # The answer includes the score, the legend (levels by number), the
  # probability distribution across levels, and a confidence.
  #
  #   Typesafe::Score.new("How frustrated is the customer?",
  #                       criteria: [
  #                         "Calm, just stating facts",
  #                         "Frustrated but civil",
  #                         "Very angry, strong language"
  #                       ])
  class Score < Question
    # @return [Array<String>] the ordered levels of the spectrum.
    attr_reader :criteria

    # @param instructions [String] the question asked about the state.
    # @param criteria [Array<String>] the ordered levels; a non-empty array
    #   of non-empty Strings, ordered from lowest to highest.
    def initialize(instructions, criteria:)
      @criteria = normalize_criteria(criteria)
      super(instructions)
    end

    def type
      "score"
    end

    def to_h
      super.merge(criteria: @criteria)
    end

    private

    def normalize_criteria(criteria)
      unless criteria.is_a?(Array) && !criteria.empty?
        raise ArgumentError, "criteria must be a non-empty Array of Strings"
      end

      criteria.each_with_index.map do |level, index|
        validate_string(level, "criteria[#{index}]")
      end.freeze
    end
  end
end
