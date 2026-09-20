# frozen_string_literal: true

module Typesafe
  # A yes/no question. The answer is the probability that the answer is yes.
  #
  #   Typesafe::Noul.new("Does the customer request a refund?")
  #
  # +criteria+ optionally clarifies what yes and no mean:
  #
  #   Typesafe::Noul.new("Is the message urgent?",
  #                      criteria: { true: "Conveys urgency", false: "No time pressure" })
  class Noul < Question
    # @return [Hash, nil] the optional +{ true:, false: }+ descriptions.
    attr_reader :criteria

    # @param instructions [String] the yes/no question asked about the state.
    # @param criteria [Hash, nil] optional +{ true:, false: }+ descriptions of
    #   what yes and no mean. Keys may be Strings or Symbols and are
    #   normalized to Symbols.
    def initialize(instructions, criteria: nil)
      @criteria = criteria.nil? ? nil : normalize_criteria(criteria)
      super(instructions)
    end

    def type
      "noul"
    end

    # @return [Hash] the API shape; +criteria+ is omitted when not given.
    def to_h
      @criteria ? super.merge(criteria: @criteria) : super
    end

    private

    def normalize_criteria(criteria)
      unless criteria.is_a?(Hash)
        raise ArgumentError, "criteria must be a Hash with :true and :false keys"
      end

      normalized = {}
      criteria.each do |key, value|
        unless key.is_a?(String) || key.is_a?(Symbol)
          raise ArgumentError, "criteria keys must be Strings or Symbols"
        end

        sym = key.to_sym
        raise ArgumentError, "criteria has duplicate key #{sym.inspect}" if normalized.key?(sym)

        normalized[sym] = validate_string(value, "criteria[#{key.inspect}]")
      end

      unless normalized.keys.sort == %i[false true]
        raise ArgumentError, "criteria must have exactly :true and :false keys"
      end

      normalized.freeze
    end
  end
end
