# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typesafe::Client do
  let(:api_key) { "sk-test-123" }
  let(:client) { described_class.new(api_key: api_key) }

  let(:endpoint) { "https://api.typesafe.ai/v1/systemone" }

  let(:example_response) do
    {
      "model" => "jev-1.13.0",
      "answers" => {
        "is_urgent" => { "type" => "noul", "noul" => 0.95 }
      },
      "usage" => { "input_tokens" => 296, "output_tokens" => 20 }
    }
  end

  describe "initialization" do
    it "accepts an explicit api key" do
      expect(described_class.new(api_key: "sk-explicit").api_key).to eq("sk-explicit")
    end

    it "falls back to ENV[\"TYPESAFE_API_KEY\"] when no key is passed" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TYPESAFE_API_KEY").and_return("sk-from-env")
      expect(described_class.new.api_key).to eq("sk-from-env")
    end

    it "raises when no key is passed and the environment variable is unset" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TYPESAFE_API_KEY").and_return(nil)
      expect { described_class.new }
        .to raise_error(ArgumentError, /api_key/)
    end

    it "raises when the key is blank" do
      expect { described_class.new(api_key: "   ") }
        .to raise_error(ArgumentError, /api_key/)
    end

    it "raises when the key is not a String" do
      expect { described_class.new(api_key: 42) }
        .to raise_error(ArgumentError, /api_key/)
    end

    it "defaults the model to \"jev-latest\"" do
      expect(described_class.new(api_key: api_key).model).to eq("jev-latest")
    end

    it "accepts a model at initialization" do
      expect(described_class.new(api_key: api_key, model: "jev-1.13.0").model)
        .to eq("jev-1.13.0")
    end

    it "raises when the model is blank" do
      expect { described_class.new(api_key: api_key, model: "") }
        .to raise_error(ArgumentError, /model/)
    end

    it "raises when the model is not a String" do
      expect { described_class.new(api_key: api_key, model: :jev) }
        .to raise_error(ArgumentError, /model/)
    end

    it "freezes its own copies without freezing the caller's inputs" do
      key = +"sk-test-123"
      model = +"jev-latest"
      client = described_class.new(api_key: key, model: model)

      expect(client.api_key).to be_frozen
      expect(client.model).to be_frozen
      expect(key).not_to be_frozen
      expect(model).not_to be_frozen
      expect(client).to be_frozen
    end
  end

  describe "#evaluate" do
    let(:state) { "Help! My payouts have been failing for 3 days." }
    let(:questions) do
      { is_urgent: Typesafe::Noul.new("Does this convey urgency?") }
    end

    context "validation of questions" do
      it "raises when questions is not a Hash" do
        expect { client.evaluate(state: state, questions: []) }
          .to raise_error(ArgumentError, /questions/)
      end

      it "raises when questions is empty" do
        expect { client.evaluate(state: state, questions: {}) }
          .to raise_error(ArgumentError, /questions/)
      end

      it "raises when a key is not a String or Symbol" do
        expect { client.evaluate(state: state, questions: { 42 => Typesafe::Noul.new("Is it?") }) }
          .to raise_error(ArgumentError, /questions/)
      end

      it "raises when a String key is blank" do
        expect { client.evaluate(state: state, questions: { "   " => Typesafe::Noul.new("Is it?") }) }
          .to raise_error(ArgumentError, /questions/)
      end

      it "raises when a value is not a Typesafe::Question" do
        expect { client.evaluate(state: state, questions: { is_urgent: "yes?" }) }
          .to raise_error(ArgumentError, /questions/)
      end
    end

    context "model resolution" do
      it "falls back to the model given at initialization when model is omitted" do
        client = described_class.new(api_key: api_key, model: "jev-1.13.0")
        stub_post(questions: questions, model: "jev-1.13.0")

        client.evaluate(state: state, questions: questions)
      end

      it "uses the call-level model when given" do
        client = described_class.new(api_key: api_key, model: "jev-1.13.0")
        stub_post(questions: questions, model: "jev-2.0.0")

        client.evaluate(state: state, questions: questions, model: "jev-2.0.0")
      end

      it "raises when a call-level model is blank" do
        expect { client.evaluate(state: state, questions: questions, model: "") }
          .to raise_error(ArgumentError, /model/)
      end

      it "raises when a call-level model is not a String" do
        expect { client.evaluate(state: state, questions: questions, model: 42) }
          .to raise_error(ArgumentError, /model/)
      end
    end

    context "request" do
      it "sends the exact API shape: endpoint, headers and body" do
        questions = {
          is_urgent: Typesafe::Noul.new(
            "Does this convey urgency?",
            criteria: { true: "Explicitly time-sensitive", false: "No urgency expressed" }
          ),
          "department" => Typesafe::Choice.new(
            "Which team should handle this?",
            criteria: { billing: "Payments, invoicing, refunds", technical: "Bugs, outages" }
          ),
          frustration: Typesafe::Score.new(
            "How frustrated is the customer?",
            criteria: ["Calm", "Frustrated", "Very angry"]
          )
        }

        stub = stub_request(:post, endpoint)
          .with(
            headers: {
              "Authorization" => "Bearer #{api_key}",
              "Content-Type" => "application/json"
            },
            body: {
              "state" => "Help! My payouts have been failing for 3 days.",
              "model" => "jev-latest",
              "questions" => {
                "is_urgent" => {
                  "type" => "noul",
                  "instructions" => "Does this convey urgency?",
                  "criteria" => { "true" => "Explicitly time-sensitive", "false" => "No urgency expressed" }
                },
                "department" => {
                  "type" => "choice",
                  "instructions" => "Which team should handle this?",
                  "criteria" => { "billing" => "Payments, invoicing, refunds", "technical" => "Bugs, outages" }
                },
                "frustration" => {
                  "type" => "score",
                  "instructions" => "How frustrated is the customer?",
                  "criteria" => ["Calm", "Frustrated", "Very angry"]
                }
              }
            }
          ).to_return(status: 200, body: JSON.generate(example_response))

        client.evaluate(state: state, questions: questions)

        expect(stub).to have_been_requested
      end

      it "serializes state verbatim, including Hash and Array forms" do
        state = { ticket: { messages: [{ author: "customer", text: "Broken!" }] }, urgent: true }
        stub = stub_request(:post, endpoint)
          .with(body: hash_including("state" => { "ticket" => { "messages" => [{ "author" => "customer", "text" => "Broken!" }] }, "urgent" => true }))
          .to_return(status: 200, body: JSON.generate(example_response))

        client.evaluate(state: state, questions: questions)

        expect(stub).to have_been_requested
      end
    end

    context "response" do
      before do
        stub_request(:post, endpoint).to_return(status: 200, body: JSON.generate(example_response))
      end

      it "returns a Typesafe::Response with typed answers" do
        response = client.evaluate(state: state, questions: questions)
        expect(response).to eq(Typesafe::Response.from_h(example_response))
        expect(response.model).to eq("jev-1.13.0")
        expect(response[:is_urgent]).to eq(Typesafe::NoulAnswer.new(noul: 0.95))
        expect(response.usage).to eq(Typesafe::Usage.new(input_tokens: 296, output_tokens: 20))
      end

      it "round-trips to the wire shape via #to_json" do
        body = JSON.parse(client.evaluate(state: state, questions: questions).to_json)
        expect(body).to eq(example_response)
      end

      it "raises on a malformed response body" do
        stub_request(:post, endpoint).to_return(status: 200, body: JSON.generate({ "model" => "jev" }))

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(ArgumentError, /answers/)
      end
    end

    context "errors" do
      # The default retry policy sleeps between retries; stub the Kernel sleep
      # so these retryable-error scenarios stay fast and deterministic.
      before do
        allow(Kernel).to receive(:sleep)
      end

      it "raises AuthenticationError on 401 with the API message" do
        stub_request(:post, endpoint).to_return(
          status: 401,
          body: JSON.generate(
            "detail" => {
              "error_type" => "authentication_error",
              "message" => "Cannot authenticate with the server. Please check your API key and try again."
            }
          )
        )

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Typesafe::AuthenticationError, /Cannot authenticate with the server/)
      end

      it "raises UnprocessableEntityError on 422" do
        stub_request(:post, endpoint).to_return(status: 422, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Typesafe::UnprocessableEntityError)
      end

      it "raises RateLimitError on 429" do
        stub_request(:post, endpoint).to_return(status: 429, body: "{}", headers: { "Retry-After" => "2" })

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Typesafe::RateLimitError) { |error| expect(error.retry_after).to eq(2.0) }
      end

      it "raises OverloadedError on 529" do
        stub_request(:post, endpoint).to_return(status: 529, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Typesafe::OverloadedError)
      end

      it "raises ServerError on 5xx" do
        stub_request(:post, endpoint).to_return(status: 500, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Typesafe::ServerError)
      end

      it "raises errors rescuable as Typesafe::Error" do
        stub_request(:post, endpoint).to_return(status: 403, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Typesafe::PermissionDeniedError)
      end
    end

    context "retries" do
      # The policy waits before each retry via Kernel.sleep; record requested
      # delays so the backoff is verifiable without slowing the suite down.
      let(:sleeps) { [] }

      before do
        allow(Kernel).to receive(:sleep) { |delay| sleeps << delay }
      end

      it "succeeds after a 429, replaying the identical request" do
        stub = stub_request(:post, endpoint)
          .with(
            headers: {
              "Authorization" => "Bearer #{api_key}",
              "Content-Type" => "application/json"
            },
            body: hash_including("state" => state, "model" => "jev-latest")
          ).to_return(
            { status: 429, body: "{}" },
            { status: 200, body: JSON.generate(example_response) }
          )

        response = client.evaluate(state: state, questions: questions)

        expect(response).to eq(Typesafe::Response.from_h(example_response))
        expect(stub).to have_been_requested.times(2)
      end

      [529, 500].each do |status|
        it "succeeds after a #{status} with exactly two requests" do
          stub = stub_request(:post, endpoint)
            .with(body: hash_including("state" => state, "model" => "jev-latest"))
            .to_return(
              { status: status, body: "{}" },
              { status: 200, body: JSON.generate(example_response) }
            )

          response = client.evaluate(state: state, questions: questions)

          expect(response).to eq(Typesafe::Response.from_h(example_response))
          expect(stub).to have_been_requested.times(2)
        end
      end

      {
        429 => Typesafe::RateLimitError,
        529 => Typesafe::OverloadedError,
        500 => Typesafe::ServerError
      }.each do |status, error_class|
        it "raises the original #{error_class} once retryable failures exceed the budget" do
          stub = stub_request(:post, endpoint).to_return(status: status, body: "{}")

          expect { client.evaluate(state: state, questions: questions) }
            .to raise_error(error_class)

          expect(stub).to have_been_requested.times(3)
        end
      end

      {
        401 => Typesafe::AuthenticationError,
        403 => Typesafe::PermissionDeniedError,
        404 => Typesafe::NotFoundError,
        422 => Typesafe::UnprocessableEntityError
      }.each do |status, error_class|
        it "never retries a #{status}" do
          stub = stub_request(:post, endpoint).to_return(status: status, body: "{}")

          expect { client.evaluate(state: state, questions: questions) }
            .to raise_error(error_class)

          expect(stub).to have_been_requested.once
        end
      end

      it "sleeps 0.5s then 1s between attempts (exponential backoff with jitter)" do
        stub_request(:post, endpoint).to_return(
          { status: 529, body: "{}" },
          { status: 529, body: "{}" },
          { status: 200, body: JSON.generate(example_response) }
        )

        client.evaluate(state: state, questions: questions)

        expect(sleeps.length).to eq(2)
        expect(sleeps[0]).to be_between(0.25, 0.5)
        expect(sleeps[1]).to be_between(0.5, 1.0)
      end

      it "does not sleep when the first attempt succeeds" do
        stub_request(:post, endpoint).to_return(status: 200, body: JSON.generate(example_response))

        client.evaluate(state: state, questions: questions)

        expect(sleeps).to be_empty
      end

      it "honors Retry-After on a 429, waiting exactly the server's delay in seconds" do
        stub_request(:post, endpoint).to_return(
          { status: 429, body: "{}", headers: { "Retry-After" => "2" } },
          { status: 200, body: JSON.generate(example_response) }
        )

        client.evaluate(state: state, questions: questions)

        expect(sleeps).to eq([2.0])
      end

      it "honors Retry-After-Ms on a 429, waiting exactly the server's delay in seconds" do
        stub_request(:post, endpoint).to_return(
          { status: 429, body: "{}", headers: { "Retry-After-Ms" => "250" } },
          { status: 200, body: JSON.generate(example_response) }
        )

        client.evaluate(state: state, questions: questions)

        expect(sleeps).to eq([0.25])
      end

      it "ignores a non-numeric Retry-After and falls back to the default backoff" do
        stub_request(:post, endpoint).to_return(
          { status: 429, body: "{}", headers: { "Retry-After" => "soon" } },
          { status: 200, body: JSON.generate(example_response) }
        )

        client.evaluate(state: state, questions: questions)

        expect(sleeps.length).to eq(1)
        expect(sleeps[0]).to be_between(0.25, 0.5)
      end

      [-1, 0].each do |value|
        it "ignores a non-positive numeric Retry-After (#{value}) and falls back to the default backoff" do
          stub_request(:post, endpoint).to_return(
            { status: 429, body: "{}", headers: { "Retry-After" => value.to_s } },
            { status: 200, body: JSON.generate(example_response) }
          )

          client.evaluate(state: state, questions: questions)

          expect(sleeps.length).to eq(1)
          expect(sleeps[0]).to be_between(0.25, 0.5)
        end
      end

      it "keeps the exponential backoff on a 429 without a Retry-After header" do
        stub_request(:post, endpoint).to_return(
          { status: 429, body: "{}" },
          { status: 200, body: JSON.generate(example_response) }
        )

        client.evaluate(state: state, questions: questions)

        expect(sleeps.length).to eq(1)
        expect(sleeps[0]).to be_between(0.25, 0.5)
      end
    end
  end

  private

  def stub_post(questions:, model:)
    stub_request(:post, endpoint)
      .with(body: hash_including("model" => model))
      .to_return(status: 200, body: JSON.generate(example_response))
  end
end
