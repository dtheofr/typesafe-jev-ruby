# frozen_string_literal: true

module Typesafe
  # A question that selects one option from a defined, unordered set.
  # The answer includes the selected option, the probability distribution
  # across all options, and a confidence.
  #
  #   Typesafe::Choice.new("Which team should handle this?",
  #                        criteria: {
  #                          billing: "Payment or subscription issues",
  #                          technical: "Bugs or integration problems"
  #                        })
  class Choice < Question
    # @return [Hash] the option keys mapped to their descriptions.
    attr_reader :criteria

    # @param instructions [String] the question asked about the state.
    # @param criteria [Hash] the options: keys (String or Symbol) mapped to
    #   non-empty String descriptions.
    def initialize(instructions, criteria:)
      @criteria = normalize_criteria(criteria)
      super(instructions)
    end

    def type
      "choice"
    end

    def to_h
      super.merge(criteria: @criteria)
    end

    private

    def normalize_criteria(criteria)
      unless criteria.is_a?(Hash) && !criteria.empty?
        raise ArgumentError, "criteria must be a non-empty Hash of option keys to descriptions"
      end

      criteria.each_with_object({}) do |(key, value), normalized|
        unless key.is_a?(String) || key.is_a?(Symbol)
          raise ArgumentError, "criteria keys must be Strings or Symbols"
        end

        normalized[key] = validate_string(value, "criteria[#{key.inspect}]")
      end.freeze
    end
  end
end
