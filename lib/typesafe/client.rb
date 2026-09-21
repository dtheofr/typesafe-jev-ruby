# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"

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

    # Default retry policy for retryable failures — the 429/529/5xx status
    # errors and the +ConnectionError+ wrapping network errors: at most
    # +RETRIES+ retries (so a total of +RETRIES + 1+ attempts), with an
    # exponential backoff between attempts starting at +BASE_DELAY+ seconds,
    # doubled on each retry and capped at +MAX_DELAY+, with jitter.
    RETRIES = 2
    BASE_DELAY = 0.5
    MAX_DELAY = 8.0
    private_constant :RETRIES, :BASE_DELAY, :MAX_DELAY

    # Network-level exception families wrapped into a +ConnectionError+ before
    # any HTTP response: socket and DNS failures, connection/read/write
    # timeouts, refused or reset connections, truncated streams and TLS
    # handshake failures. Exhaustive per-version lists are an implementation
    # choice (settled in the ticket): classes that only exist on some Ruby
    # versions (Resolv::ResolvError on >= 3.3 for DNS, and the write-timeout
    # classes where they do not inherit from Timeout::Error) are added when
    # defined.
    NETWORK_ERRORS = [
      SocketError,             # generic socket failures ; DNS on Ruby <= 3.2
      Errno::ECONNREFUSED,     # connection refused
      Errno::ECONNRESET,       # connection reset
      Errno::EHOSTUNREACH,     # host unreachable
      Errno::ENETUNREACH,      # network unreachable
      Errno::EPIPE,            # write on a truncated stream
      Errno::ETIMEDOUT,        # system timeout exceeded
      EOFError,                # stream truncated while reading
      Timeout::Error,          # Net::OpenTimeout / ReadTimeout / WriteTimeout
      Net::HTTPBadResponse,    # unreadable HTTP framing
      OpenSSL::SSL::SSLError   # TLS handshake failure
    ]
    NETWORK_ERRORS << Net::WriteTimeout if defined?(Net::WriteTimeout)
    NETWORK_ERRORS << IO::TimeoutError if defined?(IO::TimeoutError)
    NETWORK_ERRORS << Resolv::ResolvError if defined?(Resolv::ResolvError)
    NETWORK_ERRORS.freeze
    private_constant :NETWORK_ERRORS

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
    # @raise [Typesafe::ConnectionError] if the request fails at the network
    #   level before any HTTP response (connection refused, DNS failure,
    #   connection/read/write timeout, reset connection or truncated stream);
    #   the original exception is available via +cause+. Retried like the
    #   retryable status errors below, and raised once the budget is
    #   exhausted.
    # @raise [Typesafe::APIError] (or a subclass) on any non-2xx HTTP response:
    #   {Typesafe::BadRequestError}, {Typesafe::AuthenticationError},
    #   {Typesafe::PermissionDeniedError}, {Typesafe::NotFoundError},
    #   {Typesafe::UnprocessableEntityError}, {Typesafe::RateLimitError},
    #   {Typesafe::OverloadedError} and {Typesafe::ServerError}.
    #
    # Retryable errors — 429, 529, 5xx and network failures — are retried
    # automatically up to +RETRIES+ times; the wait honors the server's
    # +Retry-After+ / +Retry-After-Ms+ header on a 429, otherwise an
    # exponential backoff applies. When the budget is exhausted, the last
    # retryable error is raised. Non-retryable errors (400, 401, 403, 404,
    # 422) raise immediately without any retry.
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

    # POSTs +body+ and retries retryable failures up to +RETRIES+ times.
    # The same +body+ is replayed verbatim on every attempt: an evaluation is
    # stateless, so the replay is safe. Each attempt either returns the HTTP
    # response, or an +APIError+ — the status error built from a non-2xx
    # response, or the +ConnectionError+ wrapping a network-level failure. A
    # failure that is not retryable raises immediately; once the budget is
    # exhausted, the last retryable error is raised. Network errors follow
    # exactly the same policy as the retryable statuses (429, 529, 5xx).
    def request_with_retries(body)
      retries = 0
      loop do
        outcome = attempt(body)
        return outcome if outcome.is_a?(Net::HTTPSuccess)

        raise outcome unless outcome.retryable?
        raise outcome if retries >= RETRIES

        retries += 1
        Kernel.sleep(delay_before_retry(outcome, retries))
      end
    end

    # One HTTP attempt: posts +body+ and returns the response on success, or
    # the matching +APIError+ otherwise — the status error built from the
    # non-2xx response, or the +ConnectionError+ a network-level failure
    # raised inside +post+. Never raises; the retry loop decides.
    def attempt(body)
      response = post(body)
      return response if response.is_a?(Net::HTTPSuccess)

      Errors.from_response(status: response.code.to_i, headers: response, body: response.body)
    rescue ConnectionError => error
      error
    end

    # Delay before retry +retry_number+. When the server imposes the pace on a
    # rate limit (429), its +Retry-After+ / +Retry-After-Ms+ header is honored
    # exactly; otherwise — including for +ConnectionError+, which carries no
    # HTTP headers — the delay is the exponential backoff: the base delay
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
    rescue *NETWORK_ERRORS => error
      # No HTTP response was involved: the failure is a network error, so it
      # is wrapped — instead of escaping raw — and marked retryable. Raising
      # from within this rescue keeps the original exception as +cause+.
      raise ConnectionError.new(
        message: "The TypeSafe API could not be reached: #{error.message}"
      ), cause: error
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
