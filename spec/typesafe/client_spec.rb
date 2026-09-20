# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typesafe::Client do
  # Net::HTTPClientException was named Net::HTTPServerException before Ruby 3.3.
  HTTP_CLIENT_EXCEPTION = Net.const_defined?(:HTTPClientException) ? Net::HTTPClientException : Net::HTTPServerException
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

      it "returns the parsed JSON body as a Hash" do
        expect(client.evaluate(state: state, questions: questions)).to eq(example_response)
      end
    end

    context "errors" do
      it "raises for 401 Unauthorized" do
        stub_request(:post, endpoint).to_return(status: 401, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(HTTP_CLIENT_EXCEPTION)
      end

      it "raises for 422 Unprocessable Entity" do
        stub_request(:post, endpoint).to_return(status: 422, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(HTTP_CLIENT_EXCEPTION)
      end

      it "raises for 429 Too Many Requests" do
        stub_request(:post, endpoint).to_return(status: 429, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(HTTP_CLIENT_EXCEPTION)
      end

      it "raises for 529 Overloaded" do
        stub_request(:post, endpoint).to_return(status: 529, body: "{}")

        expect { client.evaluate(state: state, questions: questions) }
          .to raise_error(Net::HTTPFatalError)
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
