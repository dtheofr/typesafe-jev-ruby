# frozen_string_literal: true

require_relative "lib/typesafe/version"

Gem::Specification.new do |spec|
  spec.name = "typesafe-jev"
  spec.version = Typesafe::VERSION
  spec.authors = ["dtheo"]
  spec.email = ["dtheo@users.noreply.github.com"]

  spec.summary = "Ruby client for Jev, TypeSafe's System One model."
  spec.description = "Use Jev, TypeSafe's System One model, from Ruby or Rails."
  spec.homepage = "https://docs.typesafe.ai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dtheo/typesafe-jev-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/dtheo/typesafe-jev-ruby/blob/main/CHANGELOG.md"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.0"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
