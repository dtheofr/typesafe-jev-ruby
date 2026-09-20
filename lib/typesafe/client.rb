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

    # Default retry policy for retryable errors (429, 529, 5xx): at most
    # +RETRIES+ retries (so a total of +RETRIES + 1+ attempts), with an
    # exponential backoff between attempts starting at +BASE_DELAY+ seconds,
    # doubled on each retry and capped at +MAX_DELAY+, with jitter.
    RETRIES = 2
    BASE_DELAY = 0.5
    MAX_DELAY = 8.0
    private_constant :RETRIES, :BASE_DELAY, :MAX_DELAY

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

    # Evaluates a state against a map of questions and returns a {Response}
    # with one typed {Answer} per question, e.g. `response[:refund_requested]`.
    # `response.to_h` gives the raw parsed body as a Hash.
    #
    # @param state [String, Object, Array] the content to evaluate; passed
    #   through as-is.
    # @param questions [Hash{String, Symbol => Question}] question ids mapped
    #   to Question objects; answers come back under the same keys.
    # @param model [String, nil] model for this call; falls back to the model
    #   given at initialization.
    # @return [Response] the parsed response.
    # @raise [ArgumentError] if +questions+ is not a non-empty Hash of
    #   String/Symbol keys to Question values, +model+ is invalid, or the
    #   response body is not a valid response shape.
    # @raise [JSON::ParserError] if the response body is not valid JSON.
    # @raise [Typesafe::APIError] (or a subclass) on any non-2xx HTTP response:
    #   {Typesafe::BadRequestError}, {Typesafe::AuthenticationError},
    #   {Typesafe::PermissionDeniedError}, {Typesafe::NotFoundError},
    #   {Typesafe::UnprocessableEntityError}, {Typesafe::RateLimitError},
    #   {Typesafe::OverloadedError} and {Typesafe::ServerError}.
    #
    # Retryable errors (429, 529 and 5xx) are retried automatically up to
    # +RETRIES+ times; the wait honors the server's +Retry-After+ /
    # +Retry-After-Ms+ header on a 429, otherwise an exponential backoff
    # applies. When the budget is exhausted, the last retryable error is
    # raised. Non-retryable errors (400, 401, 403, 404, 422) raise
    # immediately without any retry.
    def evaluate(state:, questions:, model: nil)
      model = model.nil? ? self.model : freeze_string(model, "model must be a non-empty String")
      questions = validate_questions!(questions)

      body = JSON.generate(
        state: state,
        model: model,
        questions: questions.transform_values(&:to_h)
      )

      response = request_with_retries(body)
      Response.from_json(response.body)
    end

    private

    # POSTs +body+ and retries retryable error responses up to +RETRIES+
    # times. The same +body+ is replayed verbatim on every attempt: an
    # evaluation is stateless, so the replay is safe. Raises the error as
    # soon as it is not retryable, or once the retry budget is exhausted.
    def request_with_retries(body)
      retries = 0
      loop do
        response = post(body)
        return response if response.is_a?(Net::HTTPSuccess)

        error = Errors.from_response(status: response.code.to_i, headers: response, body: response.body)
        raise error unless error.retryable?
        raise error if retries >= RETRIES

        retries += 1
        Kernel.sleep(delay_before_retry(error, retries))
      end
    end

    # Delay before retry +retry_number+. When the server imposes the pace on a
    # rate limit (429), its +Retry-After+ / +Retry-After-Ms+ header is honored
    # exactly; otherwise the delay is the exponential backoff: the base delay
    # doubled on each retry, capped at +MAX_DELAY+ seconds, with equal jitter
    # so parallel clients do not align (uniform between half the nominal delay
    # and the nominal delay). A non-numeric or non-positive +Retry-After+ is
    # ignored and falls back on the default backoff.
    def delay_before_retry(error, retry_number)
      server_delay = error.is_a?(RateLimitError) ? error.retry_after : nil
      return server_delay if server_delay && server_delay > 0

      nominal = [BASE_DELAY * (2**(retry_number - 1)), MAX_DELAY].min
      nominal * (0.5 + Kernel.rand * 0.5)
    end

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
