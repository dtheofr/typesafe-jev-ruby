# frozen_string_literal: true

module Typesafe
  # Root of all errors raised by the gem, so users can `rescue Typesafe::Error`.
  class Error < StandardError; end

  # A non-2xx HTTP response from the TypeSafe API.
  #
  #   begin
  #     client.evaluate(state:, questions:)
  #   rescue Typesafe::RateLimitError => e
  #     sleep(e.retry_after || 1.0)
  #     retry
  #   end
  #
  # The `detail` field of an error body comes in three shapes, all of which
  # are rendered into the exception message:
  #
  # * a plain String: `{"detail": "Unknown model: jev-99"}`
  # * a Hash with error_type/message:
  #   `{"detail": {"error_type": "authentication_error", "message": "..."}}`
  # * an Array of validation entries (FastAPI/pydantic style):
  #   `{"detail": [{"type": "missing", "loc": ["body", "questions"], "msg": "Field required"}]}`
  class APIError < Error
    # @return [Integer] the HTTP status code.
    attr_reader :status
    # @return [Hash, Array, String, nil] the parsed JSON body (Hash or Array),
    #   the raw body String when it is not valid JSON, or nil for an empty body.
    attr_reader :body
    # @return [Hash{String => String}] the response headers, as received.
    attr_reader :headers
    # @return [String, nil] the +x-typesafe-request-id+ response header, when present.
    attr_reader :request_id

    # @param status [Integer] the HTTP status code.
    # @param body [Hash, Array, String, nil] the parsed or raw response body.
    # @param headers [Hash{String => String}] the response headers.
    # @param message [String, nil] overrides the rendered +detail+-based message.
    def initialize(status:, body: nil, headers: {}, message: nil)
      @status = status
      @body = body
      @headers = headers
      @request_id = header("x-typesafe-request-id")
      super(message || "The TypeSafe API returned status #{status}.")
    end

    # True when the request may succeed if retried after a delay: rate limits
    # (429), overload (529) and server errors (5xx).
    # @return [Boolean]
    def retryable?
      status == 429 || status == 529 || (500..599).cover?(status)
    end

    private

    # Case-insensitive header lookup, since header casing depends on the server.
    def header(name)
      headers.each { |key, value| return value if key.to_s.downcase == name }
      nil
    end
  end

  # The request was invalid (400).
  class BadRequestError < APIError; end

  # Missing or invalid API key (401).
  class AuthenticationError < APIError; end

  # Access denied (403). The API also returns this for a missing API key.
  class PermissionDeniedError < APIError; end

  # The endpoint or resource was not found (404).
  class NotFoundError < APIError; end

  # The request body failed server-side validation (422).
  class UnprocessableEntityError < APIError
    # The parsed validation entries, e.g.
    # `{"type" => "missing", "loc" => ["body", "questions"], "msg" => "Field required"}`;
    # empty when the body carries none.
    # @return [Array<Hash>]
    def errors
      detail = body.is_a?(Hash) ? body["detail"] : nil
      detail.is_a?(Array) ? detail : []
    end
  end

  # The rate limit was exceeded (429).
  class RateLimitError < APIError
    # The server's requested wait before retrying, parsed from the
    # +Retry-After+ (seconds) or +Retry-After-Ms+ (milliseconds) header.
    # @return [Float, Integer, nil]
    def retry_after
      if (ms = header("retry-after-ms"))
        Float(ms) / 1000
      elsif (seconds = header("retry-after"))
        Float(seconds)
      end
    rescue ArgumentError, TypeError
      nil
    end
  end

  # TypeSafe is temporarily overloaded (529).
  class OverloadedError < APIError; end

  # The server failed to process the request (5xx, excluding 529).
  class ServerError < APIError; end

  # Builds error instances from raw HTTP responses.
  module Errors
    module_function

    # Maps a non-2xx response to the matching error class.
    #
    # @param status [Integer] the HTTP status code.
    # @param headers [Hash, #each_header] the response headers.
    # @param body [String, Hash, Array, nil] the raw or parsed response body.
    # @return [APIError] an instance of the class matching +status+.
    def from_response(status:, headers: {}, body: nil)
      parsed_body = parse_body(body)
      klass = STATUS_CLASSES.fetch(status) do
        (500..599).cover?(status) ? ServerError : APIError
      end

      klass.new(
        status: status,
        body: parsed_body.is_a?(String) ? parsed_body.dup.freeze : parsed_body.freeze,
        headers: normalize_headers(headers).freeze,
        message: message_from_body(parsed_body, status)
      )
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError, TypeError
      body
    end

    def message_from_body(parsed_body, status)
      detail = parsed_body.is_a?(Hash) ? parsed_body["detail"] : nil
      case detail
      when String then detail
      when Hash then detail["message"] || detail[:message] || "Invalid request."
      when Array then detail.map { |entry| validation_message(entry) }.join("; ")
      else "The TypeSafe API returned status #{status}."
      end
    end

    def validation_message(entry)
      return entry.to_s unless entry.is_a?(Hash)

      loc = Array(entry["loc"]).join(".")
      msg = entry["msg"] || entry[:msg]
      loc.empty? ? msg.to_s : "#{loc}: #{msg}"
    end

    def normalize_headers(headers)
      return headers.each_header.to_h if headers.respond_to?(:each_header)

      headers.dup
    rescue TypeError
      {}
    end

    STATUS_CLASSES = {
      400 => BadRequestError,
      401 => AuthenticationError,
      403 => PermissionDeniedError,
      404 => NotFoundError,
      422 => UnprocessableEntityError,
      429 => RateLimitError,
      529 => OverloadedError
    }.freeze
    private_constant :STATUS_CLASSES
  end
end
