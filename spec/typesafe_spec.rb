# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe do
  it "has a version" do
    expect(Typesafe::VERSION).to eq("1.0.0")
  end

  it "exposes the question types" do
    expect(Typesafe::Question).to be_a(Class)
    expect(Typesafe::Noul).to be < Typesafe::Question
    expect(Typesafe::Choice).to be < Typesafe::Question
    expect(Typesafe::Score).to be < Typesafe::Question
  end

  it "exposes the answer types" do
    expect(Typesafe::Answer).to be_a(Class)
    expect(Typesafe::NoulAnswer).to be < Typesafe::Answer
    expect(Typesafe::ChoiceAnswer).to be < Typesafe::Answer
    expect(Typesafe::ScoreAnswer).to be < Typesafe::Answer
    expect(Typesafe::Response).to be_a(Class)
    expect(Typesafe::Usage).to be_a(Class)
  end
end
