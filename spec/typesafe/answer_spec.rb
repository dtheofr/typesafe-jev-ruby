# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Answer do
  describe "#type" do
    it "is not implemented on the base class" do
      expect { described_class.new.type }.to raise_error(NotImplementedError, /must implement #type/)
    end
  end

  describe ".from_h" do
    it "builds a NoulAnswer for type noul" do
      expect(described_class.from_h("type" => "noul", "noul" => 0.95))
        .to eq(Typesafe::NoulAnswer.new(noul: 0.95))
    end

    it "builds a ChoiceAnswer for type choice" do
      answer = described_class.from_h(
        "type" => "choice",
        "choice" => "billing",
        "probabilities" => { "billing" => 1.0 },
        "confidence" => 0.8
      )
      expect(answer).to be_a(Typesafe::ChoiceAnswer)
    end

    it "builds a ScoreAnswer for type score" do
      answer = described_class.from_h(
        "type" => "score",
        "score" => 1.6,
        "legend" => { "1" => "Calm", "2" => "Frustrated" },
        "probabilities" => { "1" => 0.6, "2" => 0.4 },
        "confidence" => 0.7
      )
      expect(answer).to be_a(Typesafe::ScoreAnswer)
    end

    it "accepts Symbol keys" do
      expect(described_class.from_h(type: "noul", noul: 0.95))
        .to eq(Typesafe::NoulAnswer.new(noul: 0.95))
    end

    it "raises on a non-Hash" do
      expect { described_class.from_h("noul") }.to raise_error(ArgumentError, /must be a Hash/)
    end

    it "raises on a missing type" do
      expect { described_class.from_h("noul" => 0.95) }
        .to raise_error(ArgumentError, /unknown answer type/)
    end

    it "raises on an unknown type" do
      expect { described_class.from_h("type" => "essay") }
        .to raise_error(ArgumentError, /unknown answer type "essay"/)
    end
  end
end
