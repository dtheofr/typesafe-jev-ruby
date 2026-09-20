# frozen_string_literal: true

require "spec_helper"

RSpec.describe Typesafe::Jev do
  let(:api_key) { "sk-test-123" }

  let(:endpoint) { "https://api.typesafe.ai/v1/systemone" }

  let(:example_response) do
    {
      "model" => "jev-latest",
      "answers" => {
        "is_urgent" => { "type" => "noul", "noul" => 0.95 }
      },
      "usage" => { "input_tokens" => 296, "output_tokens" => 20 }
    }
  end

  let(:state) { "Help! My payouts have been failing for 3 days." }
  let(:questions) { { is_urgent: Typesafe::Noul.new("Does this convey urgency?") } }

  it "is a Typesafe::Client" do
    expect(described_class).to be < Typesafe::Client
  end

  describe "initialization" do
    it "accepts an explicit api key" do
      expect(described_class.new(api_key: api_key).api_key).to eq(api_key)
    end

    it "falls back to ENV[\"TYPESAFE_API_KEY\"] when no key is passed" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TYPESAFE_API_KEY").and_return("sk-from-env")
      expect(described_class.new.api_key).to eq("sk-from-env")
    end

    it "raises when no usable key is found" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TYPESAFE_API_KEY").and_return(nil)
      expect { described_class.new }.to raise_error(ArgumentError, /api_key/)
    end

    it "pins the model to \"jev-latest\"" do
      expect(described_class.new(api_key: api_key).model).to eq("jev-latest")
    end
  end

  describe "#evaluate" do
    before do
      stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer #{api_key}" },
          body: { "state" => state, "model" => "jev-latest", "questions" => { "is_urgent" => { "type" => "noul", "instructions" => "Does this convey urgency?" } } }
        ).to_return(status: 200, body: JSON.generate(example_response))
    end

    it "evaluates with the pinned model" do
      expect(described_class.new(api_key: api_key).evaluate(state: state, questions: questions))
        .to eq(Typesafe::Response.from_h(example_response))
    end

    it "accepts the pinned model explicitly at call time" do
      expect(described_class.new(api_key: api_key).evaluate(state: state, questions: questions, model: "jev-latest"))
        .to eq(Typesafe::Response.from_h(example_response))
    end

    it "raises when a different model is requested" do
      client = described_class.new(api_key: api_key)
      expect { client.evaluate(state: state, questions: questions, model: "jev-1.13.0") }
        .to raise_error(ArgumentError, /pins the model/)
    end

    it "inherits the default retries on retryable errors" do
      client = described_class.new(api_key: api_key)
      allow(Kernel).to receive(:sleep)

      stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer #{api_key}" },
          body: { "state" => state, "model" => "jev-latest", "questions" => { "is_urgent" => { "type" => "noul", "instructions" => "Does this convey urgency?" } } }
        ).to_return(
          { status: 529, body: "{}" },
          { status: 200, body: JSON.generate(example_response) }
        )

      expect(client.evaluate(state: state, questions: questions))
        .to eq(Typesafe::Response.from_h(example_response))
    end

    it "inherits the network error wrapping: a refused connection raises Typesafe::ConnectionError" do
      client = described_class.new(api_key: api_key)
      allow(Kernel).to receive(:sleep)

      stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer #{api_key}" },
          body: { "state" => state, "model" => "jev-latest", "questions" => { "is_urgent" => { "type" => "noul", "instructions" => "Does this convey urgency?" } } }
        ).to_raise(Errno::ECONNREFUSED)

      expect { client.evaluate(state: state, questions: questions) }
        .to raise_error(Typesafe::ConnectionError)
    end
  end

  describe ".evaluate one-shot" do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TYPESAFE_API_KEY").and_return(api_key)
    end

    it "evaluates using a client built from the environment" do
      stub_request(:post, endpoint)
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
        .to_return(status: 200, body: JSON.generate(example_response))

      expect(described_class.evaluate(state: state, questions: questions)).to eq(Typesafe::Response.from_h(example_response))
    end

    it "accepts an explicit api key" do
      stub_request(:post, endpoint)
        .with(headers: { "Authorization" => "Bearer #{api_key}" })
        .to_return(status: 200, body: JSON.generate(example_response))

      expect(described_class.evaluate(state: state, questions: questions, api_key: api_key))
        .to eq(Typesafe::Response.from_h(example_response))
    end
  end
end
