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

    it "accepts retry_options and exposes the normalized, frozen policy" do
      client = described_class.new(api_key: api_key, retry_options: { max_retries: 0 })

      expect(client.retry_options).to eq(max_retries: 0, base_delay: 0.5, max_delay: 8.0)
      expect(client.retry_options).to be_frozen
    end

    it "validates retry_options strictly, raising an ArgumentError at construction" do
      expect { described_class.new(api_key: api_key, retry_options: { max_retrie: 3 }) }
        .to raise_error(ArgumentError, /max_retrie/)
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

    it "reflects retry_options: { max_retries: 0 } with a single attempt" do
      client = described_class.new(api_key: api_key, retry_options: { max_retries: 0 })
      allow(Kernel).to receive(:sleep)

      stub = stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer #{api_key}" },
          body: { "state" => state, "model" => "jev-latest", "questions" => { "is_urgent" => { "type" => "noul", "instructions" => "Does this convey urgency?" } } }
        ).to_return(status: 529, body: "{}")

      expect { client.evaluate(state: state, questions: questions) }
        .to raise_error(Typesafe::OverloadedError)

      expect(stub).to have_been_requested.once
    end

    it "reflects a configured base_delay in the requested sleeps" do
      sleeps = []
      client = described_class.new(api_key: api_key, retry_options: { max_retries: 1, base_delay: 1.0 })
      allow(Kernel).to receive(:sleep) { |delay| sleeps << delay }

      stub_request(:post, endpoint)
        .with(
          headers: { "Authorization" => "Bearer #{api_key}" },
          body: { "state" => state, "model" => "jev-latest", "questions" => { "is_urgent" => { "type" => "noul", "instructions" => "Does this convey urgency?" } } }
        ).to_return(
          { status: 529, body: "{}" },
          { status: 200, body: JSON.generate(example_response) }
        )

      client.evaluate(state: state, questions: questions)

      expect(sleeps.length).to eq(1)
      expect(sleeps[0]).to be_between(0.5, 1.0)
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
