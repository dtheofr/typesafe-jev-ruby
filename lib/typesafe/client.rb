# frozen_string_literal: true

require "json"
require "net/http"

require_relative "question"

module Typesafe
  # HTTP client for the TypeSafe System One evaluation endpoint.
  #
  #   client = Typesafe::Client.new(api_key: "sk-...", model: "jev-latest")
  #   client.evaluate(
  #     state: { ticket: { text: "My payouts failed" } },
  #     questions: { refund_requested: Typesafe::Noul.new("Does the customer request a refund?") }
  #   )
  #
  # The API key comes from the +TYPESAFE_API_KEY+ environment variable unless
  # passed at initialization. The model defaults to +"jev-latest"+ and may be
  # overridden per call.
  class Client
    DEFAULT_MODEL = "jev-latest"
    API_ENDPOINT = "https://api.typesafe.ai/v1/systemone"

    # @return [String] the API key sent as +Authorization: Bearer <key>+.
    attr_reader :api_key

    # @return [String] the default model used when +evaluate+ gets none.
    attr_reader :model

    # @param api_key [String, nil] the TypeSafe API key; falls back to the
    #   +TYPESAFE_API_KEY+ environment variable.
    # @param model [String, nil] the default model; defaults to "jev-latest".
    # @raise [ArgumentError] if no usable API key is found or +model+ is
    #   present but not a non-empty String.
    def initialize(api_key: nil, model: nil)
      @api_key = freeze_string(api_key || ENV.fetch("TYPESAFE_API_KEY") { nil },
                               "api_key must be a non-empty String " \
                               "(passed at initialization or set in the TYPESAFE_API_KEY environment variable)")
      @model = freeze_string(model || DEFAULT_MODEL, "model must be a non-empty String")
      freeze
    end

    # Evaluates a state against a map of questions and returns the raw JSON
    # response as a Hash, e.g. +{"model"=>..., "answers"=>{...}, "usage"=>...}+.
    #
    # @param state [String, Object, Array] the content to evaluate; passed
    #   through as-is.
    # @param questions [Hash{String, Symbol => Question}] question ids mapped
    #   to Question objects; answers come back under the same keys.
    # @param model [String, nil] model for this call; falls back to the model
    #   given at initialization.
    # @return [Hash] the parsed response body.
    # @raise [ArgumentError] if +questions+ is not a non-empty Hash of
    #   String/Symbol keys to Question values, or +model+ is invalid.
    # @raise [Net::HTTPClientException, Net::HTTPFatalError] on any non-2xx
    #   HTTP response.
    def evaluate(state:, questions:, model: nil)
      model = model.nil? ? self.model : freeze_string(model, "model must be a non-empty String")
      questions = validate_questions!(questions)

      body = JSON.generate(
        state: state,
        model: model,
        questions: questions.transform_values(&:to_h)
      )

      response = post(body)
      response.value
      JSON.parse(response.body)
    end

    private

    def post(body)
      uri = URI(API_ENDPOINT)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = body

      Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: true,
        open_timeout: 5, write_timeout: 10, read_timeout: 30
      ) { |http| http.request(request) }
    end

    def validate_questions!(questions)
      unless questions.is_a?(Hash) && !questions.empty?
        raise ArgumentError, "questions must be a non-empty Hash mapping question ids to Question objects"
      end

      questions.each do |id, question|
        unless (id.is_a?(String) && !id.strip.empty?) || (id.is_a?(Symbol) && !id.to_s.strip.empty?)
          raise ArgumentError, "questions keys must be non-empty String or Symbol question ids, got #{id.inspect}"
        end

        unless question.is_a?(Question)
          raise ArgumentError, "questions values must be Typesafe::Question objects, got #{question.inspect}"
        end
      end

      questions
    end

    def freeze_string(value, error_message)
      unless value.is_a?(String) && !value.strip.empty?
        raise ArgumentError, error_message
      end

      value.dup.freeze
    end
  end
end
