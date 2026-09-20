# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe::Question do
  # A minimal concrete subclass, since the base class is abstract.
  let(:klass) do
    Class.new(described_class) do
      def type
        "test"
      end
    end
  end

  describe "#type" do
    it "raises NotImplementedError on the abstract base class" do
      question = described_class.allocate
      expect { question.type }.to raise_error(NotImplementedError)
    end
  end

  describe "#initialize" do
    it "raises on nil instructions" do
      expect { klass.new(nil) }.to raise_error(ArgumentError, /instructions/)
    end

    it "raises on non-String instructions" do
      expect { klass.new(42) }.to raise_error(ArgumentError, /instructions/)
    end

    it "raises on empty instructions" do
      expect { klass.new("") }.to raise_error(ArgumentError, /instructions/)
    end

    it "raises on whitespace-only instructions" do
      expect { klass.new("   ") }.to raise_error(ArgumentError, /instructions/)
    end
  end

  describe "#instructions" do
    it "returns the instructions" do
      expect(klass.new("Is the sky blue?").instructions).to eq("Is the sky blue?")
    end
  end

  describe "#to_h" do
    it "returns the type and instructions" do
      expect(klass.new("Is the sky blue?").to_h).to eq(
        type: "test",
        instructions: "Is the sky blue?"
      )
    end

    it "returns a fresh hash each time" do
      question = klass.new("Is the sky blue?")
      question.to_h[:injected] = true
      expect(question.to_h).not_to have_key(:injected)
    end
  end

  describe "#to_json" do
    it "serializes the API shape" do
      json = JSON.parse(klass.new("Is the sky blue?").to_json)
      expect(json).to eq("type" => "test", "instructions" => "Is the sky blue?")
    end
  end

  describe "equality" do
    it "is equal when type and instructions match" do
      expect(klass.new("a")).to eq(klass.new("a"))
      expect(klass.new("a").eql?(klass.new("a"))).to be(true)
      expect(klass.new("a").hash).to eq(klass.new("a").hash)
    end

    it "is not equal when instructions differ" do
      expect(klass.new("a")).not_to eq(klass.new("b"))
    end

    it "is not equal across question classes" do
      expect(klass.new("a")).not_to eq(Typesafe::Noul.new("a"))
    end

    it "can be used as a Hash key" do
      hash = { klass.new("a") => :answer }
      expect(hash[klass.new("a")]).to eq(:answer)
    end
  end

  describe "immutability" do
    it "is frozen" do
      expect(klass.new("a")).to be_frozen
    end

    it "freezes the instructions" do
      expect(klass.new("a").instructions).to be_frozen
    end

    it "freezes its own copy of the criteria" do
      criteria = ["Calm", "Furious"]
      question = Typesafe::Score.new("How frustrated?", criteria: criteria)
      expect(question.criteria).to be_frozen
    end

    it "does not let the caller's criteria be mutated through the question" do
      criteria = ["Calm", "Furious"]
      question = Typesafe::Score.new("How frustrated?", criteria: criteria)
      expect { question.criteria[0] = "mutated" }.to raise_error(FrozenError)
    end

    it "does not freeze the caller's criteria" do
      criteria = ["Calm", "Furious"]
      Typesafe::Score.new("How frustrated?", criteria: criteria)
      expect(criteria).not_to be_frozen
    end
  end
end
