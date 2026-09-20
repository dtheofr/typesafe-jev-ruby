# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Response do
  subject(:response) do
    described_class.from_json(<<~JSON)
      {
        "model": "jev-1.13.0",
        "answers": {
          "is_urgent": {
            "type": "noul",
            "noul": 0.95
          },
          "department": {
            "type": "choice",
            "choice": "billing",
            "probabilities": { "billing": 0.88, "technical": 0.12, "sales": 0.0 },
            "confidence": 0.81
          },
          "frustration": {
            "type": "score",
            "score": 1.6,
            "legend": { "1": "Calm", "2": "Frustrated", "3": "Very angry" },
            "probabilities": { "1": 0.6, "2": 0.35, "3": 0.05 },
            "confidence": 0.7
          }
        },
        "usage": { "input_tokens": 296, "output_tokens": 20 }
      }
    JSON
  end

  describe ".from_json" do
    it "parses the model" do
      expect(response.model).to eq("jev-1.13.0")
    end

    it "parses typed answers" do
      expect(response[:is_urgent]).to be_a(Typesafe::NoulAnswer).and have_attributes(noul: 0.95)
      expect(response[:department]).to be_a(Typesafe::ChoiceAnswer).and have_attributes(choice: "billing")
      expect(response[:frustration]).to be_a(Typesafe::ScoreAnswer).and have_attributes(score: 1.6)
    end

    it "parses the usage" do
      expect(response.usage).to eq(Typesafe::Usage.new(input_tokens: 296, output_tokens: 20))
    end

    it "raises on invalid JSON" do
      expect { described_class.from_json("{ not json") }.to raise_error(JSON::ParserError)
    end
  end

  describe ".from_h" do
    it "builds from Symbol keys" do
      parsed = described_class.from_h(model: "jev-1.13.0", answers: { urgent: { type: "noul", noul: 1.0 } },
                                      usage: { input_tokens: 1, output_tokens: 1 })
      expect(parsed[:urgent]).to eq(Typesafe::NoulAnswer.new(noul: 1.0))
    end

    it "accepts Answer objects in the answers map" do
      answer = Typesafe::NoulAnswer.new(noul: 1.0)
      parsed = described_class.from_h(model: "jev", answers: { urgent: answer },
                                      usage: { input_tokens: 1, output_tokens: 1 })
      expect(parsed[:urgent]).to equal(answer)
    end

    it "raises on a non-Hash" do
      expect { described_class.from_h("response") }.to raise_error(ArgumentError, /must be a Hash/)
    end

    it "raises when a top-level field is missing" do
      expect { described_class.from_h("model" => "jev", "usage" => { "input_tokens" => 1, "output_tokens" => 1 }) }
        .to raise_error(ArgumentError, /answers/)
    end

    it "raises on an empty answers map" do
      expect do
        described_class.from_h("model" => "jev", "answers" => {}, "usage" => { "input_tokens" => 1, "output_tokens" => 1 })
      end.to raise_error(ArgumentError, /answers/)
    end

    it "raises on an invalid answer type" do
      expect do
        described_class.from_h("model" => "jev", "answers" => { "x" => { "type" => "essay" } },
                               "usage" => { "input_tokens" => 1, "output_tokens" => 1 })
      end.to raise_error(ArgumentError, /unknown answer type "essay"/)
    end
  end

  describe "#initialize" do
    it "is frozen" do
      expect(response).to be_frozen
    end

    it "raises on a blank model" do
      expect do
        described_class.new(model: "", answers: { a: { type: "noul", noul: 1.0 } },
                            usage: Typesafe::Usage.new(input_tokens: 1, output_tokens: 1))
      end.to raise_error(ArgumentError, /model/)
    end
  end

  describe "#[]" do
    it "looks up answers by Symbol id" do
      expect(response[:is_urgent]).to eq(Typesafe::NoulAnswer.new(noul: 0.95))
    end

    it "looks up answers by String id" do
      expect(response["is_urgent"]).to eq(Typesafe::NoulAnswer.new(noul: 0.95))
    end

    it "returns nil for unknown ids" do
      expect(response[:nope]).to be_nil
      expect(response["nope"]).to be_nil
    end
  end

  describe "#answers" do
    it "keys answers by the question ids" do
      expect(response.answers.keys).to contain_exactly("is_urgent", "department", "frustration")
    end
  end

  describe "#to_h" do
    it "round-trips back to the API shape" do
      hash = JSON.parse(response.to_json)
      expect(described_class.from_json(response.to_json)).to eq(response)
      expect(hash).to eq(JSON.parse(<<~JSON))
        {
          "model": "jev-1.13.0",
          "answers": {
            "is_urgent": { "type": "noul", "noul": 0.95 },
            "department": { "type": "choice", "choice": "billing",
                            "probabilities": { "billing": 0.88, "technical": 0.12, "sales": 0.0 },
                            "confidence": 0.81 },
            "frustration": { "type": "score", "score": 1.6,
                             "legend": { "1": "Calm", "2": "Frustrated", "3": "Very angry" },
                             "probabilities": { "1": 0.6, "2": 0.35, "3": 0.05 },
                             "confidence": 0.7 }
          },
          "usage": { "input_tokens": 296, "output_tokens": 20 }
        }
      JSON
    end
  end

  describe "#==" do
    it "compares equal for the same shape" do
      expect(response).to eq(described_class.from_json(response.to_json))
      expect(response.hash).to eq(described_class.from_json(response.to_json).hash)
    end

    it "compares unequal for different models" do
      other_hash = JSON.parse(response.to_json)
      other_hash["model"] = "jev-1.12.0"
      expect(response).not_to eq(described_class.from_h(other_hash))
    end
  end
end
