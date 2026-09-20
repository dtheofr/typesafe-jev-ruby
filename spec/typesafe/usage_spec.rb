# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Usage do
  subject(:usage) { described_class.new(input_tokens: 296, output_tokens: 20) }

  describe "#initialize" do
    it "stores the token counts" do
      expect(usage.input_tokens).to eq(296)
      expect(usage.output_tokens).to eq(20)
    end

    it "is frozen" do
      expect(usage).to be_frozen
    end

    it "raises on non-Integer token counts" do
      expect { described_class.new(input_tokens: "296", output_tokens: 20) }
        .to raise_error(ArgumentError, /input_tokens/)
      expect { described_class.new(input_tokens: 296, output_tokens: 20.5) }
        .to raise_error(ArgumentError, /output_tokens/)
    end

    it "raises on negative token counts" do
      expect { described_class.new(input_tokens: -1, output_tokens: 20) }
        .to raise_error(ArgumentError, /input_tokens/)
    end
  end

  describe "#to_h" do
    it "returns the API shape" do
      expect(usage.to_h).to eq(input_tokens: 296, output_tokens: 20)
    end
  end

  describe ".from_h" do
    it "builds from String keys" do
      expect(described_class.from_h("input_tokens" => 296, "output_tokens" => 20)).to eq(usage)
    end

    it "raises when a field is missing" do
      expect { described_class.from_h("input_tokens" => 296) }.to raise_error(ArgumentError, /output_tokens/)
    end
  end

  describe "#==" do
    it "compares equal for the same counts" do
      expect(usage).to eq(described_class.new(input_tokens: 296, output_tokens: 20))
      expect(usage.hash).to eq(described_class.new(input_tokens: 296, output_tokens: 20).hash)
    end

    it "compares unequal for different counts" do
      expect(usage).not_to eq(described_class.new(input_tokens: 296, output_tokens: 21))
    end
  end
end
