# frozen_string_literal: true

module Typesafe
  # The answer to a {Choice} question: the selected option, the probability
  # distribution across every option, and a confidence between 0 and 1.
  #
  #   Typesafe::ChoiceAnswer.new(
  #     choice: "billing",
  #     probabilities: { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
  #     confidence: 0.81
  #   )
  class ChoiceAnswer < Answer
    # @return [String] the highest-probability option.
    attr_reader :choice

    # @return [Hash] every option mapped to its probability.
    attr_reader :probabilities

    # @return [Numeric] how certain the model is, between 0 and 1.
    attr_reader :confidence

    # @param choice [String] the selected option.
    # @param probabilities [Hash] option keys (String or Symbol) mapped to
    #   probabilities in 0..1; the values must sum to 1.
    # @param confidence [Numeric] the model's confidence, between 0 and 1.
    # @raise [ArgumentError] if any attribute is invalid.
    def initialize(choice:, probabilities:, confidence:)
      @choice = validate_string(choice, "choice")
      @probabilities = normalize_probabilities(probabilities)
      @confidence = validate_probability(confidence, "confidence")
      freeze
    end

    # @param hash [Hash] a +choice+ answer entry from the API response, with
    #   String or Symbol keys.
    # @return [ChoiceAnswer]
    def self.from_h(hash)
      new(
        choice: hash["choice"] || hash[:choice],
        probabilities: hash["probabilities"] || hash[:probabilities],
        confidence: hash["confidence"] || hash[:confidence]
      )
    end

    def type
      "choice"
    end

    def to_h
      { type: type, choice: choice, probabilities: probabilities, confidence: confidence }
    end
  end
end
