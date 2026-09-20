# frozen_string_literal: true

module Typesafe
  # Token usage for one evaluation request.
  #
  #   Typesafe::Usage.new(input_tokens: 296, output_tokens: 20)
  class Usage
    # @return [Integer] the number of input tokens.
    attr_reader :input_tokens

    # @return [Integer] the number of output tokens.
    attr_reader :output_tokens

    # @param input_tokens [Integer] the number of input tokens.
    # @param output_tokens [Integer] the number of output tokens.
    # @raise [ArgumentError] if a token count is not a non-negative Integer.
    def initialize(input_tokens:, output_tokens:)
      @input_tokens = validate_token_count(input_tokens, "input_tokens")
      @output_tokens = validate_token_count(output_tokens, "output_tokens")
      freeze
    end

    # @param hash [Hash] a +usage+ entry from the API response, with String
    #   or Symbol keys.
    # @return [Usage]
    # @raise [ArgumentError] if +hash+ is not a Hash or a token count is
    #   missing or invalid.
    def self.from_h(hash)
      unless hash.is_a?(Hash)
        raise ArgumentError, "usage must be a Hash, got #{hash.inspect}"
      end

      new(
        input_tokens: hash["input_tokens"] || hash[:input_tokens],
        output_tokens: hash["output_tokens"] || hash[:output_tokens]
      )
    end

    # @return [Hash] the +usage+ shape returned by the TypeSafe API.
    def to_h
      { input_tokens: input_tokens, output_tokens: output_tokens }
    end

    # Usages compare equal when their token counts match.
    def ==(other)
      other.class == self.class && other.to_h == to_h
    end
    alias eql? ==

    def hash
      [self.class, to_h].hash
    end

    private

    def validate_token_count(value, name)
      unless value.is_a?(Integer) && value >= 0
        raise ArgumentError, "#{name} must be a non-negative Integer, got #{value.inspect}"
      end

      value
    end
  end
end
