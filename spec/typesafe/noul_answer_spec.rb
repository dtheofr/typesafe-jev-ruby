# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::NoulAnswer do
  subject(:answer) { described_class.new(noul: 0.95) }

  describe "#initialize" do
    it "stores the noul value" do
      expect(answer.noul).to eq(0.95)
    end

    it "accepts the bounds 0 and 1" do
      expect(described_class.new(noul: 0).noul).to eq(0)
      expect(described_class.new(noul: 1).noul).to eq(1)
    end

    it "is frozen" do
      expect(answer).to be_frozen
    end

    it "raises on non-Numeric values" do
      expect { described_class.new(noul: "0.5") }.to raise_error(ArgumentError, /noul/)
      expect { described_class.new(noul: nil) }.to raise_error(ArgumentError, /noul/)
    end

    it "raises on non-finite values" do
      expect { described_class.new(noul: Float::NAN) }.to raise_error(ArgumentError, /noul/)
      expect { described_class.new(noul: Float::INFINITY) }.to raise_error(ArgumentError, /noul/)
    end

    it "raises on values outside 0..1" do
      expect { described_class.new(noul: -0.1) }.to raise_error(ArgumentError, /noul/)
      expect { described_class.new(noul: 1.1) }.to raise_error(ArgumentError, /noul/)
    end
  end

  describe "#type" do
    it 'is "noul"' do
      expect(answer.type).to eq("noul")
    end
  end

  describe "#to_h" do
    it "returns the API shape" do
      expect(answer.to_h).to eq(type: "noul", noul: 0.95)
    end
  end

  describe "#to_json" do
    it "serializes to the API shape" do
      expect(JSON.parse(answer.to_json)).to eq("type" => "noul", "noul" => 0.95)
    end
  end

  describe ".from_h" do
    it "builds from String keys" do
      expect(described_class.from_h("type" => "noul", "noul" => 0.95)).to eq(answer)
    end

    it "builds from Symbol keys" do
      expect(described_class.from_h(type: "noul", noul: 0.95)).to eq(answer)
    end

    it "raises when noul is missing" do
      expect { described_class.from_h("type" => "noul") }.to raise_error(ArgumentError, /noul/)
    end
  end

  describe "#==" do
    it "compares equal for the same value" do
      expect(answer).to eq(described_class.new(noul: 0.95))
      expect(answer.eql?(described_class.new(noul: 0.95))).to be(true)
      expect(answer.hash).to eq(described_class.new(noul: 0.95).hash)
    end

    it "compares unequal for different values" do
      expect(answer).not_to eq(described_class.new(noul: 0.9))
    end

    it "compares unequal across answer types" do
      other = Typesafe::ChoiceAnswer.new(choice: "billing", probabilities: { billing: 1.0 }, confidence: 0.5)
      expect(answer).not_to eq(other)
    end
  end
end
