# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Score do
  let(:criteria) do
    [
      "Calm, just stating facts",
      "Frustrated but civil",
      "Very angry, strong language"
    ]
  end

  describe "#initialize" do
    it "requires criteria" do
      expect { described_class.new("How frustrated is the customer?") }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on nil criteria" do
      expect { described_class.new("How frustrated?", criteria: nil) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on empty criteria" do
      expect { described_class.new("How frustrated?", criteria: []) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on non-Array criteria" do
      expect { described_class.new("How frustrated?", criteria: "calm") }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on non-String criteria elements" do
      expect { described_class.new("How frustrated?", criteria: ["calm", 2]) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on empty String criteria elements" do
      expect { described_class.new("How frustrated?", criteria: ["calm", "   "]) }
        .to raise_error(ArgumentError, /criteria/)
    end
  end

  describe "attribute readers" do
    it "exposes instructions and criteria" do
      question = described_class.new("How frustrated is the customer?", criteria: criteria)
      expect(question.instructions).to eq("How frustrated is the customer?")
      expect(question.criteria).to eq(criteria)
    end
  end

  describe "#type" do
    it "is score" do
      expect(described_class.new("How frustrated?", criteria: criteria).type).to eq("score")
    end
  end

  describe "#to_h" do
    it "returns the API shape" do
      expect(described_class.new("How frustrated?", criteria: criteria).to_h).to eq(
        type: "score",
        instructions: "How frustrated?",
        criteria: criteria
      )
    end
  end

  describe "#to_json" do
    it "serializes the API shape" do
      json = JSON.parse(described_class.new("How frustrated?", criteria: criteria).to_json)
      expect(json).to eq(
        "type" => "score",
        "instructions" => "How frustrated?",
        "criteria" => criteria
      )
    end
  end
end
