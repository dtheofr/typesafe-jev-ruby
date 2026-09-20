# frozen_string_literal: true

module Typesafe
  # The answer to a {Noul} question: the yes/no probability on a scale from
  # 0 (no) to 1 (yes).
  #
  #   Typesafe::NoulAnswer.new(noul: 0.95)
  class NoulAnswer < Answer
    # @return [Numeric] the yes/no answer, between 0 (no) and 1 (yes).
    attr_reader :noul

    # @param noul [Numeric] the yes/no probability, between 0 and 1.
    # @raise [ArgumentError] if +noul+ is not a Numeric between 0 and 1.
    def initialize(noul:)
      @noul = validate_probability(noul, "noul")
      freeze
    end

    # @param hash [Hash] a +noul+ answer entry from the API response, with
    #   String or Symbol keys.
    # @return [NoulAnswer]
    def self.from_h(hash)
      new(noul: hash["noul"] || hash[:noul])
    end

    def type
      "noul"
    end

    def to_h
      { type: type, noul: noul }
    end
  end
end
