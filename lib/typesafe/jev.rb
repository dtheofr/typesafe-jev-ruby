# frozen_string_literal: true

require_relative "client"

module Typesafe
  # Convenience facade over {Client} for TypeSafe's flagship model, Jev.
  #
  # The model is pinned to "jev-latest"; for any other model, use
  # {Typesafe::Client} directly.
  #
  #   Typesafe::Jev.evaluate(state: "My payouts failed", questions: { urgent: Typesafe::Noul.new("Is this urgent?") })
  #
  # or, reusing one client:
  #
  #   jev = Typesafe::Jev.new
  #   jev.evaluate(state: state, questions: questions)
  class Jev < Client
    PINNED_MODEL = "jev-latest"

    # @param api_key [String, nil] the TypeSafe API key; falls back to the
    #   +TYPESAFE_API_KEY+ environment variable.
    # @raise [ArgumentError] if no usable API key is found.
    def initialize(api_key: nil)
      super(api_key: api_key, model: PINNED_MODEL)
    end

    # Evaluates a state against a map of questions with the pinned model.
    #
    # @param state [String, Object, Array] the content to evaluate; passed
    #   through as-is.
    # @param questions [Hash{String, Symbol => Question}] question ids mapped
    #   to Question objects; answers come back under the same keys.
    # @param model [String, nil] must be nil or "jev-latest".
    # @return [Response] the parsed response.
    # @raise [ArgumentError] if +questions+ is invalid, +model+ is not the
    #   pinned one, or the response body is not a valid response shape.
    # @raise [JSON::ParserError] if the response body is not valid JSON.
    # @raise [Typesafe::APIError] (or a subclass) on any non-2xx HTTP response;
    #   see {Typesafe::Client#evaluate}.
    def evaluate(state:, questions:, model: nil)
      if model && model != PINNED_MODEL
        raise ArgumentError,
              "Typesafe::Jev pins the model to \"jev-latest\"; use Typesafe::Client for other models"
      end

      super(state: state, questions: questions, model: model)
    end

    # One-shot evaluation using a client built from the environment (or the
    # given API key). Equivalent to <tt>Jev.new(api_key:).evaluate(...)</tt>.
    #
    # @param state [String, Object, Array] the content to evaluate.
    # @param questions [Hash{String, Symbol => Question}] question ids mapped
    #   to Question objects.
    # @param api_key [String, nil] the TypeSafe API key; falls back to the
    #   +TYPESAFE_API_KEY+ environment variable.
    # @return [Response] the parsed response.
    def self.evaluate(state:, questions:, api_key: nil)
      new(api_key: api_key).evaluate(state: state, questions: questions)
    end
  end
end
