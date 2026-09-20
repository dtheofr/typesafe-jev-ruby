# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::ChoiceAnswer do
  subject(:answer) do
    described_class.new(
      choice: "billing",
      probabilities: { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
      confidence: 0.81
    )
  end

  describe "#initialize" do
    it "stores the attributes" do
      expect(answer.choice).to eq("billing")
      expect(answer.probabilities).to eq("billing" => 0.88, "technical" => 0.12, "sales" => 0.0)
      expect(answer.confidence).to eq(0.81)
    end

    it "keeps Symbol keys as given" do
      expect(described_class.new(choice: "billing", probabilities: { billing: 1.0 }, confidence: 0.5).probabilities)
        .to eq(billing: 1.0)
    end

    it "is frozen" do
      expect(answer).to be_frozen
    end

    it "raises on a blank choice" do
      expect { described_class.new(choice: "  ", probabilities: { a: 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /choice/)
    end

    it "raises on non-Hash or empty probabilities" do
      expect { described_class.new(choice: "a", probabilities: [], confidence: 0.5) }
        .to raise_error(ArgumentError, /probabilities/)
      expect { described_class.new(choice: "a", probabilities: {}, confidence: 0.5) }
        .to raise_error(ArgumentError, /probabilities/)
    end

    it "raises on non-String, non-Symbol probabilities keys" do
      expect { described_class.new(choice: "a", probabilities: { 1 => 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /probabilities keys/)
    end

    it "raises on probabilities outside 0..1" do
      expect { described_class.new(choice: "a", probabilities: { a: 1.5 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /probabilities\[:a\]/)
    end

    it "raises when probabilities do not sum to 1" do
      expect { described_class.new(choice: "a", probabilities: { a: 0.5, b: 0.2 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /must sum to 1/)
    end

    it "raises on a confidence outside 0..1" do
      expect { described_class.new(choice: "a", probabilities: { a: 1.0 }, confidence: 1.1) }
        .to raise_error(ArgumentError, /confidence/)
    end
  end

  describe "#type" do
    it 'is "choice"' do
      expect(answer.type).to eq("choice")
    end
  end

  describe "#to_h" do
    it "returns the API shape" do
      expect(answer.to_h).to eq(
        type: "choice",
        choice: "billing",
        probabilities: { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
        confidence: 0.81
      )
    end
  end

  describe "#to_json" do
    it "serializes to the API shape" do
      expect(JSON.parse(answer.to_json)).to eq(
        "type" => "choice",
        "choice" => "billing",
        "probabilities" => { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
        "confidence" => 0.81
      )
    end
  end

  describe ".from_h" do
    it "builds from the API response shape" do
      parsed = described_class.from_h(
        "type" => "choice",
        "choice" => "billing",
        "probabilities" => { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
        "confidence" => 0.81
      )
      expect(parsed).to eq(answer)
    end

    it "raises when a field is missing" do
      expect { described_class.from_h("type" => "choice", "choice" => "billing", "probabilities" => { a: 1.0 }) }
        .to raise_error(ArgumentError, /confidence/)
    end
  end

  describe "#==" do
    it "compares equal for the same shape" do
      expect(answer).to eq(described_class.new(
                             choice: "billing",
                             probabilities: { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
                             confidence: 0.81
                           ))
      expect(answer.hash).to eq(described_class.new(
                                  choice: "billing",
                                  probabilities: { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 },
                                  confidence: 0.81
                                ).hash)
    end

    it "compares unequal for different choices" do
      expect(answer).not_to eq(described_class.new(choice: "technical", probabilities: { technical: 1.0 }, confidence: 0.81))
    end
  end
end
