# frozen_string_literal: true

module Typesafe
  # Abstract base class for the three answer types returned by the TypeSafe
  # System One API: {NoulAnswer}, {ChoiceAnswer}, and {ScoreAnswer}.
  #
  # An answer is an immutable value object mirroring its question: it carries
  # what the model returned for one question, but not the question id — that
  # is the Hash key under which the answer appears in a {Response}.
  #
  # Use {Answer.from_h} (or {Response.from_json}) to build typed answers from
  # a parsed response body:
  #
  #   Typesafe::Answer.from_h({ "type" => "noul", "noul" => 0.95 })
  #   # => #<Typesafe::NoulAnswer @noul=0.95>
  class Answer
    # Builds the typed answer matching +hash+'s +type+ tag.
    #
    # @param hash [Hash] one entry of the API response's +answers+ map, with
    #   String or Symbol keys.
    # @return [NoulAnswer, ChoiceAnswer, ScoreAnswer]
    # @raise [ArgumentError] if +hash+ is not a Hash or its +type+ is missing
    #   or unknown.
    def self.from_h(hash)
      unless hash.is_a?(Hash)
        raise ArgumentError, "answer must be a Hash, got #{hash.inspect}"
      end

      type = hash["type"] || hash[:type]
      case type
      when "noul" then NoulAnswer.from_h(hash)
      when "choice" then ChoiceAnswer.from_h(hash)
      when "score" then ScoreAnswer.from_h(hash)
      else
        raise ArgumentError,
              "unknown answer type #{type.inspect} (expected \"noul\", \"choice\", or \"score\")"
      end
    end

    # @return [String] the API answer type tag ("noul", "choice", or "score").
    # @raise [NotImplementedError] on the abstract base class.
    def type
      raise NotImplementedError, "#{self.class} must implement #type"
    end

    # @return [Hash] the answer shape returned by the TypeSafe API.
    def to_h
      { type: type }
    end

    # @return [String] the answer serialized as JSON.
    def to_json(state = nil)
      JSON.generate(to_h, state)
    end

    # Answers compare equal when they are of the same class and serialize
    # to the same API shape.
    def ==(other)
      other.class == self.class && other.to_h == to_h
    end
    alias eql? ==

    def hash
      [self.class, to_h].hash
    end

    private

    # Validates that +value+ is a non-empty String and returns a frozen copy.
    def validate_string(value, name)
      unless value.is_a?(String) && !value.strip.empty?
        raise ArgumentError, "#{name} must be a non-empty String"
      end

      value.dup.freeze
    end

    # Validates that +value+ is a finite Numeric, optionally within +range+.
    def validate_number(value, name, range: nil)
      unless value.is_a?(Numeric) && value.finite?
        raise ArgumentError, "#{name} must be a finite Numeric, got #{value.inspect}"
      end

      if range && !range.cover?(value)
        raise ArgumentError, "#{name} must be between #{range.min} and #{range.max}, got #{value.inspect}"
      end

      value
    end

    # Validates that +value+ is a probability between 0 and 1.
    def validate_probability(value, name)
      validate_number(value, name, range: 0.0..1.0)
    end

    # Validates a probability distribution: a non-empty Hash with String or
    # Symbol keys mapping to probabilities in 0..1 that sum to 1. When
    # +allowed_keys+ is given, the keys must match it exactly.
    def normalize_probabilities(probabilities, allowed_keys: nil)
      unless probabilities.is_a?(Hash) && !probabilities.empty?
        raise ArgumentError, "probabilities must be a non-empty Hash of option or level keys to probabilities"
      end

      normalized = probabilities.each_with_object({}) do |(key, probability), result|
        unless key.is_a?(String) || key.is_a?(Symbol)
          raise ArgumentError, "probabilities keys must be Strings or Symbols, got #{key.inspect}"
        end

        result[key.is_a?(String) ? key.dup.freeze : key] =
          validate_probability(probability, "probabilities[#{key.inspect}]")
      end

      sum = normalized.values.sum
      unless (sum - 1.0).abs <= 1e-6
        raise ArgumentError, "probabilities must sum to 1, got #{sum}"
      end

      if allowed_keys
        expected = allowed_keys.map(&:to_s)
        actual = normalized.keys.map(&:to_s)
        missing = expected - actual
        unexpected = actual - expected
        unless missing.empty? && unexpected.empty?
          problems = []
          problems << "missing #{missing.map(&:inspect).join(", ")}" unless missing.empty?
          problems << "unexpected #{unexpected.map(&:inspect).join(", ")}" unless unexpected.empty?
          raise ArgumentError, "probabilities keys must match the legend keys (#{problems.join("; ")})"
        end
      end

      normalized.freeze
    end
  end
end
