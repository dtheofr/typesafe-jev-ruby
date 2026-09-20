# frozen_string_literal: true

module Typesafe
  # Abstract base class for the three question types understood by the
  # TypeSafe System One API: {Noul}, {Choice}, and {Score}.
  #
  # A question is an immutable value object. The question ID used to identify
  # its answer is not part of the object: it is the Hash key under which the
  # question is sent in a request, e.g.
  #
  #   questions = { refund_requested: Typesafe::Noul.new("Does the customer request a refund?") }
  class Question
    # @return [String] the question asked about the state.
    attr_reader :instructions

    # @param instructions [String] the question asked about the state.
    # @raise [ArgumentError] if +instructions+ is not a non-empty String.
    def initialize(instructions)
      unless instructions.is_a?(String) && !instructions.strip.empty?
        raise ArgumentError, "instructions must be a non-empty String"
      end

      @instructions = instructions.dup.freeze
      validate!
      freeze
    end

    # @return [String] the API question type tag ("noul", "choice", or "score").
    # @raise [NotImplementedError] on the abstract base class.
    def type
      raise NotImplementedError, "#{self.class} must implement #type"
    end

    # @return [Hash] the question shape expected by the TypeSafe API.
    def to_h
      { type: type, instructions: instructions }
    end

    # @return [String] the question serialized as JSON for the TypeSafe API.
    def to_json(state = nil)
      JSON.generate(to_h, state)
    end

    # Questions compare equal when they are of the same class and serialize
    # to the same API shape.
    def ==(other)
      other.class == self.class && other.to_h == to_h
    end
    alias eql? ==

    def hash
      [self.class, to_h].hash
    end

    private

    # Hook for subclasses to validate their own attributes before freezing.
    def validate!; end

    # Validates that +value+ is a non-empty String and returns a frozen copy.
    def validate_string(value, name)
      unless value.is_a?(String) && !value.strip.empty?
        raise ArgumentError, "#{name} must be a non-empty String"
      end

      value.dup.freeze
    end
  end
end
