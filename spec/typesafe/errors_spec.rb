# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typesafe::Errors do
  # Real response bodies captured from the live API.
  let(:bodies) do
    {
      bad_key: {
        "detail" => {
          "error_type" => "authentication_error",
          "message" => "Cannot authenticate with the server. Please check your API key and try again."
        }
      },
      missing_key: {
        "detail" => {
          "error_type" => "authentication_error",
          "message" => "Must supply an API key! Check your request and try again."
        }
      },
      noul_missing_fields: { "detail" => "Noul question must have criteria or instructions: q" },
      unknown_model: {
        "detail" => { "error_type" => "api_usage_error", "message" => "Unknown model: jev-99" }
      },
      too_many_score_levels: { "detail" => "Too many score levels. Must have at most 10 levels." },
      too_many_choices: { "detail" => "Too many choices. Must have at most 255 choices." },
      missing_questions: {
        "detail" => [
          { "type" => "missing", "loc" => ["body", "questions"], "msg" => "Field required",
            "input" => { "state" => "hello", "model" => "jev-latest" } }
        ]
      },
      not_found: { "detail" => "Not Found" }
    }
  end

  describe ".from_response" do
    it "raises AuthenticationError for 401 with the API message" do
      error = Typesafe::Errors.from_response(status: 401, body: bodies[:bad_key])

      expect(error).to be_a(Typesafe::AuthenticationError)
      expect(error.message).to eq("Cannot authenticate with the server. Please check your API key and try again.")
    end

    it "raises PermissionDeniedError for 403" do
      error = Typesafe::Errors.from_response(status: 403, body: bodies[:missing_key])

      expect(error).to be_a(Typesafe::PermissionDeniedError)
      expect(error.message).to eq("Must supply an API key! Check your request and try again.")
    end

    it "raises BadRequestError for 400 with a plain String detail" do
      error = Typesafe::Errors.from_response(status: 400, body: bodies[:noul_missing_fields])

      expect(error).to be_a(Typesafe::BadRequestError)
      expect(error.message).to eq("Noul question must have criteria or instructions: q")
    end

    it "raises BadRequestError for 400 with an error_type/message Hash detail" do
      error = Typesafe::Errors.from_response(status: 400, body: bodies[:unknown_model])

      expect(error).to be_a(Typesafe::BadRequestError)
      expect(error.message).to eq("Unknown model: jev-99")
    end

    it "raises UnprocessableEntityError for 422 and exposes the validation entries" do
      error = Typesafe::Errors.from_response(status: 422, body: bodies[:missing_questions])

      expect(error).to be_a(Typesafe::UnprocessableEntityError)
      expect(error.message).to eq("body.questions: Field required")
      expect(error.errors).to eq(
        [{ "type" => "missing", "loc" => ["body", "questions"], "msg" => "Field required",
           "input" => { "state" => "hello", "model" => "jev-latest" } }]
      )
    end

    it "raises RateLimitError for 429" do
      error = Typesafe::Errors.from_response(status: 429, body: "{}")

      expect(error).to be_a(Typesafe::RateLimitError)
    end

    it "raises OverloadedError for 529" do
      error = Typesafe::Errors.from_response(status: 529, body: "{}")

      expect(error).to be_a(Typesafe::OverloadedError)
    end

    it "raises ServerError for other 5xx statuses" do
      [500, 502, 503].each do |status|
        error = Typesafe::Errors.from_response(status: status, body: nil)

        expect(error).to be_a(Typesafe::ServerError)
        expect(error.status).to eq(status)
      end
    end

    it "raises NotFoundError for 404" do
      error = Typesafe::Errors.from_response(status: 404, body: bodies[:not_found])

      expect(error).to be_a(Typesafe::NotFoundError)
      expect(error.message).to eq("Not Found")
    end

    it "falls back to the generic APIError for an unmapped 4xx status" do
      error = Typesafe::Errors.from_response(status: 409, body: "{}")

      expect(error).to be_a(Typesafe::APIError)
      expect(error).not_to be_a(Typesafe::BadRequestError)
      expect(error.message).to eq("The TypeSafe API returned status 409.")
    end

    it "exposes the status, parsed body and headers" do
      headers = { "Content-Type" => "application/json", "X-Typesafe-Request-Id" => "req_123" }
      error = Typesafe::Errors.from_response(status: 401, headers: headers, body: bodies[:bad_key])

      expect(error.status).to eq(401)
      expect(error.body).to eq(bodies[:bad_key])
      expect(error.headers).to eq(headers)
    end

    it "reads the request id case-insensitively" do
      error = Typesafe::Errors.from_response(
        status: 401, headers: { "x-typesafe-request-id" => "req_abc" }, body: "{}"
      )

      expect(error.request_id).to eq("req_abc")
    end

    it "leaves request_id nil when the header is absent" do
      error = Typesafe::Errors.from_response(status: 401, body: "{}")

      expect(error.request_id).to be_nil
    end

    it "parses a raw JSON String body and keeps a non-JSON body as a String" do
      parsed = Typesafe::Errors.from_response(status: 401, body: JSON.generate(bodies[:bad_key]))
      raw = Typesafe::Errors.from_response(status: 502, body: "<html>Bad Gateway</html>")

      expect(parsed.body).to eq(bodies[:bad_key])
      expect(raw.body).to eq("<html>Bad Gateway</html>")
    end

    it "keeps a nil body for an empty response" do
      error = Typesafe::Errors.from_response(status: 500, body: nil)

      expect(error.body).to be_nil
      expect(error.message).to eq("The TypeSafe API returned status 500.")
    end

    it "freezes the parsed body and headers without freezing caller inputs" do
      raw_body = JSON.generate(bodies[:bad_key])
      headers = { "Content-Type" => "application/json" }
      error = Typesafe::Errors.from_response(status: 401, headers: headers, body: raw_body)

      expect(error.body).to be_frozen
      expect(error.headers).to be_frozen
      expect(raw_body).not_to be_frozen
      expect(headers).not_to be_frozen
    end

    it "accepts a Net::HTTPResponse for headers" do
      response = Net::HTTPResponse.new("1.1", 401, "Unauthorized")
      response["x-typesafe-request-id"] = "req_net"

      error = Typesafe::Errors.from_response(status: 401, headers: response, body: "{}")

      expect(error.request_id).to eq("req_net")
      expect(error.headers).to eq({ "x-typesafe-request-id" => "req_net" })
    end
  end

  describe Typesafe::APIError do
    describe "#retryable?" do
      it "is true for 429, 529 and 5xx" do
        [429, 529, 500, 503, 599].each do |status|
          expect(Typesafe::APIError.new(status: status)).to be_retryable
        end
      end

      it "is false for 4xx and 2xx-adjacent statuses" do
        [400, 401, 403, 404, 422].each do |status|
          expect(Typesafe::APIError.new(status: status)).not_to be_retryable
        end
      end
    end
  end

  describe Typesafe::RateLimitError do
    it "parses Retry-After in seconds" do
      error = Typesafe::Errors.from_response(status: 429, headers: { "Retry-After" => "3" }, body: "{}")

      expect(error.retry_after).to eq(3.0)
    end

    it "parses Retry-After-Ms in milliseconds" do
      error = Typesafe::Errors.from_response(status: 429, headers: { "Retry-After-Ms" => "750" }, body: "{}")

      expect(error.retry_after).to eq(0.75)
    end

    it "prefers Retry-After-Ms when both headers are present" do
      error = Typesafe::Errors.from_response(
        status: 429, headers: { "Retry-After" => "3", "Retry-After-Ms" => "750" }, body: "{}"
      )

      expect(error.retry_after).to eq(0.75)
    end

    it "returns nil when the header is absent or unparseable" do
      absent = Typesafe::Errors.from_response(status: 429, headers: {}, body: "{}")
      unparseable = Typesafe::Errors.from_response(status: 429, headers: { "Retry-After" => "soon" }, body: "{}")

      expect(absent.retry_after).to be_nil
      expect(unparseable.retry_after).to be_nil
    end
  end

  describe Typesafe::UnprocessableEntityError do
    it "returns an empty errors list when the body has no validation entries" do
      error = Typesafe::Errors.from_response(status: 422, body: "{}")

      expect(error.errors).to eq([])
    end
  end

  describe Typesafe::Error do
    it "is the root of all gem errors" do
      [Typesafe::APIError, Typesafe::BadRequestError, Typesafe::AuthenticationError,
       Typesafe::PermissionDeniedError, Typesafe::NotFoundError,
       Typesafe::UnprocessableEntityError, Typesafe::RateLimitError,
       Typesafe::OverloadedError, Typesafe::ServerError].each do |klass|
        expect(klass).to be < Typesafe::Error
      end
    end
  end
end
