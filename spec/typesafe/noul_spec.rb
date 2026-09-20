# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Noul do
  describe "#initialize" do
    it "accepts instructions only" do
      question = described_class.new("Does the customer request a refund?")
      expect(question.instructions).to eq("Does the customer request a refund?")
    end

    it "accepts true/false criteria" do
      question = described_class.new(
        "Is the message urgent?",
        criteria: { true: "Conveys urgency", false: "No time pressure" }
      )
      expect(question.criteria).to eq(true: "Conveys urgency", false: "No time pressure")
    end

    it "normalizes string criteria keys to symbols" do
      question = described_class.new(
        "Is the message urgent?",
        criteria: { "true" => "Conveys urgency", "false" => "No time pressure" }
      )
      expect(question.criteria).to eq(true: "Conveys urgency", false: "No time pressure")
    end

    it "accepts criteria: nil" do
      expect(described_class.new("Yes?", criteria: nil).criteria).to be_nil
    end

    it "raises on non-Hash criteria" do
      expect { described_class.new("Yes?", criteria: ["yes", "no"]) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on criteria missing the :true key" do
      expect { described_class.new("Yes?", criteria: { false: "no" }) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on criteria missing the :false key" do
      expect { described_class.new("Yes?", criteria: { true: "yes" }) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on criteria with extra keys" do
      expect { described_class.new("Yes?", criteria: { true: "y", false: "n", maybe: "m" }) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on criteria with empty values" do
      expect { described_class.new("Yes?", criteria: { true: "y", false: "" }) }
        .to raise_error(ArgumentError, /criteria/)
    end

    it "raises on duplicate string and symbol keys" do
      expect { described_class.new("Yes?", criteria: { "true" => "y", true: "also y", false: "n" }) }
        .to raise_error(ArgumentError, /duplicate/)
    end

    it "raises on non-String, non-Symbol criteria keys" do
      expect { described_class.new("Yes?", criteria: { 1 => "y", false: "n" }) }
        .to raise_error(ArgumentError, /criteria keys/)
    end
  end

  describe "#type" do
    it "is noul" do
      expect(described_class.new("Yes?").type).to eq("noul")
    end
  end

  describe "#to_h" do
    it "omits criteria when not given" do
      expect(described_class.new("Does the customer request a refund?").to_h).to eq(
        type: "noul",
        instructions: "Does the customer request a refund?"
      )
    end

    it "includes criteria when given" do
      expect(described_class.new(
        "Is the message urgent?",
        criteria: { true: "Conveys urgency", false: "No time pressure" }
      ).to_h).to eq(
        type: "noul",
        instructions: "Is the message urgent?",
        criteria: { true: "Conveys urgency", false: "No time pressure" }
      )
    end
  end

  describe "#to_json" do
    it "serializes the API shape" do
      json = JSON.parse(described_class.new("Yes?").to_json)
      expect(json).to eq("type" => "noul", "instructions" => "Yes?")
    end
  end
end
