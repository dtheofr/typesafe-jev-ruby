# frozen_string_literal: true

module Typesafe
  # The answer to a {Score} question: the probability-weighted value across
  # the levels (which can land between two levels), the legend mapping each
  # level back to its description, the probability distribution across
  # levels, and a confidence between 0 and 1.
  #
  #   Typesafe::ScoreAnswer.new(
  #     score: 1.6,
  #     legend: { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
  #     probabilities: { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
  #     confidence: 0.7
  #   )
  class ScoreAnswer < Answer
    # @return [Numeric] the probability-weighted answer across the levels;
    #   can land between levels.
    attr_reader :score

    # @return [Hash] each level number mapped back to its description.
    attr_reader :legend

    # @return [Hash] each level mapped to its probability; keys match the
    #   legend.
    attr_reader :probabilities

    # @return [Numeric] how certain the model is, between 0 and 1.
    attr_reader :confidence

    # @param score [Numeric] the probability-weighted answer across levels.
    # @param legend [Hash] level keys (String or Symbol) mapped to non-empty
    #   String descriptions.
    # @param probabilities [Hash] the same level keys mapped to probabilities
    #   in 0..1; the values must sum to 1 and the keys must match +legend+.
    # @param confidence [Numeric] the model's confidence, between 0 and 1.
    # @raise [ArgumentError] if any attribute is invalid.
    def initialize(score:, legend:, probabilities:, confidence:)
      @score = validate_number(score, "score")
      @legend = normalize_legend(legend)
      @probabilities = normalize_probabilities(probabilities, allowed_keys: @legend.keys)
      @confidence = validate_probability(confidence, "confidence")
      freeze
    end

    # @param hash [Hash] a +score+ answer entry from the API response, with
    #   String or Symbol keys.
    # @return [ScoreAnswer]
    def self.from_h(hash)
      new(
        score: hash["score"] || hash[:score],
        legend: hash["legend"] || hash[:legend],
        probabilities: hash["probabilities"] || hash[:probabilities],
        confidence: hash["confidence"] || hash[:confidence]
      )
    end

    def type
      "score"
    end

    def to_h
      { type: type, score: score, legend: legend, probabilities: probabilities, confidence: confidence }
    end

    private

    # Validates that +legend+ is a non-empty Hash of level keys to
    # non-empty String descriptions, with frozen copies of the descriptions.
    def normalize_legend(legend)
      unless legend.is_a?(Hash) && !legend.empty?
        raise ArgumentError, "legend must be a non-empty Hash of level keys to descriptions"
      end

      legend.each_with_object({}) do |(key, description), normalized|
        unless key.is_a?(String) || key.is_a?(Symbol)
          raise ArgumentError, "legend keys must be Strings or Symbols, got #{key.inspect}"
        end

        normalized[key.is_a?(String) ? key.dup.freeze : key] =
          validate_string(description, "legend[#{key.inspect}]")
      end.freeze
    end
  end
end
