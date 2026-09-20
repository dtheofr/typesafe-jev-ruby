# frozen_string_literal: true

require "typesafe"

RSpec.describe Typesafe do
  it "has a version" do
    expect(Typesafe::VERSION).to eq("0.4.1")
  end

  it "exposes the question types" do
    expect(Typesafe::Question).to be_a(Class)
    expect(Typesafe::Noul).to be < Typesafe::Question
    expect(Typesafe::Choice).to be < Typesafe::Question
    expect(Typesafe::Score).to be < Typesafe::Question
  end
end
