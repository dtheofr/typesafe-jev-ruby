# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Choice do
  let(:criteria) do
    {
      billing: "Payment or subscription issues",
      technical: "Bugs or integration problems",
      sales: "Pricing or account questions"
    }
  end

  describe "#initialize" do
    it "requires criteria" do
      expect { described_class.new("Which team should handle this?") }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on nil criteria" do
      expect { described_class.new("Which team?", criteria: nil) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on empty criteria" do
      expect { described_class.new("Which team?", criteria: {}) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on non-Hash criteria" do
      expect { described_class.new("Which team?", criteria: ["billing", "technical"]) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on non-String, non-Symbol criteria keys" do
      expect { described_class.new("Which team?", criteria: { 1 => "billing" }) }
        .to raise_error(ArgumentError, /criteria keys/)
    end

    it "raises on non-String criteria values" do
      expect { described_class.new("Which team?", criteria: { billing: 42 }) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on empty String criteria values" do
      expect { described_class.new("Which team?", criteria: { billing: "" }) }
        .to raise_error(ArgumentError, /criteria/)
    end
  end

  describe "attribute readers" do
    it "exposes instructions and criteria" do
      question = described_class.new("Which team should handle this?", criteria: criteria)
      expect(question.instructions).to eq("Which team should handle this?")
      expect(question.criteria).to eq(criteria)
    end

    it "keeps String criteria keys as given" do
      question = described_class.new("Which team?", criteria: { "billing" => "Payments" })
      expect(question.criteria).to eq("billing" => "Payments")
    end
  end

  describe "#type" do
    it "is choice" do
      expect(described_class.new("Which team?", criteria: criteria).type).to eq("choice")
    end
  end

  describe "#to_h" do
    it "returns the API shape" do
      expect(described_class.new("Which team?", criteria: criteria).to_h).to eq(
        type: "choice",
        instructions: "Which team?",
        criteria: criteria
      )
    end
  end

  describe "#to_json" do
    it "serializes the API shape" do
      json = JSON.parse(described_class.new("Which team?", criteria: criteria).to_json)
      expect(json).to eq(
        "type" => "choice",
        "instructions" => "Which team?",
        "criteria" => { "billing" => "Payment or subscription issues",
                        "technical" => "Bugs or integration problems",
                        "sales" => "Pricing or account questions" }
      )
    end
  end
end
