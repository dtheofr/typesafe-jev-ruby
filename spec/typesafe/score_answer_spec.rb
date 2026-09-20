# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::ScoreAnswer do
  subject(:answer) do
    described_class.new(
      score: 1.6,
      legend: { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
      probabilities: { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
      confidence: 0.7
    )
  end

  describe "#initialize" do
    it "stores the attributes" do
      expect(answer.score).to eq(1.6)
      expect(answer.legend).to eq("1" => "Calm", "2" => "Frustrated", "3" => "Very angry")
      expect(answer.probabilities).to eq("1" => 0.6, "2" => 0.35, "3" => 0.05)
      expect(answer.confidence).to eq(0.7)
    end

    it "is frozen" do
      expect(answer).to be_frozen
    end

    it "raises on a non-Numeric score" do
      expect { described_class.new(score: "high", legend: { a: "A" }, probabilities: { a: 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /score/)
    end

    it "raises on non-Hash or empty legend" do
      expect { described_class.new(score: 1.0, legend: [], probabilities: { a: 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /legend/)
      expect { described_class.new(score: 1.0, legend: {}, probabilities: { a: 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /legend/)
    end

    it "raises on non-String, non-Symbol legend keys" do
      expect { described_class.new(score: 1.0, legend: { 1 => "A" }, probabilities: { "1" => 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /legend keys/)
    end

    it "raises on blank legend descriptions" do
      expect { described_class.new(score: 1.0, legend: { "1" => "" }, probabilities: { "1" => 1.0 }, confidence: 0.5) }
        .to raise_error(ArgumentError, /legend\["1"\]/)
    end

    it "raises when probabilities keys do not match the legend keys" do
      expect do
        described_class.new(
          score: 1.0,
          legend: { "1" => "Calm", "2" => "Frustrated" },
          probabilities: { "1" => 0.5, "3" => 0.5 },
          confidence: 0.5
        )
      end.to raise_error(ArgumentError, /missing "2"; unexpected "3"/)
    end

    it "raises when probabilities do not sum to 1" do
      expect do
        described_class.new(
          score: 1.0,
          legend: { "1" => "Calm", "2" => "Frustrated" },
          probabilities: { "1" => 0.5, "2" => 0.2 },
          confidence: 0.5
        )
      end.to raise_error(ArgumentError, /must sum to 1/)
    end

    it "raises on a confidence outside 0..1" do
      expect do
        described_class.new(
          score: 1.0,
          legend: { "1" => "Calm", "2" => "Frustrated" },
          probabilities: { "1" => 0.5, "2" => 0.5 },
          confidence: -0.1
        )
      end.to raise_error(ArgumentError, /confidence/)
    end
  end

  describe "#type" do
    it 'is "score"' do
      expect(answer.type).to eq("score")
    end
  end

  describe "#to_h" do
    it "returns the API shape" do
      expect(answer.to_h).to eq(
        type: "score",
        score: 1.6,
        legend: { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
        probabilities: { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
        confidence: 0.7
      )
    end
  end

  describe "#to_json" do
    it "serializes to the API shape" do
      expect(JSON.parse(answer.to_json)).to eq(
        "type" => "score",
        "score" => 1.6,
        "legend" => { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
        "probabilities" => { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
        "confidence" => 0.7
      )
    end
  end

  describe ".from_h" do
    it "builds from the API response shape" do
      parsed = described_class.from_h(
        "type" => "score",
        "score" => 1.6,
        "legend" => { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
        "probabilities" => { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
        "confidence" => 0.7
      )
      expect(parsed).to eq(answer)
    end

    it "raises when a field is missing" do
      expect { described_class.from_h("type" => "score", "score" => 1.6, "legend" => { "1" => "Calm" }) }
        .to raise_error(ArgumentError, /probabilities/)
    end
  end

  describe "#==" do
    it "compares equal for the same shape" do
      expect(answer).to eq(described_class.new(
                             score: 1.6,
                             legend: { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
                             probabilities: { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
                             confidence: 0.7
                           ))
    end

    it "compares unequal for different scores" do
      expect(answer).not_to eq(described_class.new(
                                 score: 2.0,
                                 legend: { "1" => "Calm", "2" => "Frustrated", "3" => "Very angry" },
                                 probabilities: { "1" => 0.6, "2" => 0.35, "3" => 0.05 },
                                 confidence: 0.7
                               ))
    end
  end
end
