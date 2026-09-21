# frozen_string_literal: true

# Bundler and RubyGems require gems by their gem name, so
# `gem "typesafe-jev"` in a Gemfile runs `require "typesafe-jev"`.
# Without this file, Bundler's fallback would translate the dash to a
# slash and load `typesafe/jev` (the Jev facade alone) instead of the
# full entry point, leaving most of the gem unloaded.
require_relative "typesafe"
