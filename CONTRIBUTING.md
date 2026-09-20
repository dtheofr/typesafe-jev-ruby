# Contributing

Thanks for taking the time to contribute! 🎉

## Setup

This project uses [mise](https://mise.jdx.dev) to pin Ruby (3.4 locally; the gem supports >= 3.1) and Bundler for dependencies.

```sh
bundle install
bundle exec rake spec   # run the test suite (default rake task)
```

## Conventions

- **Zero runtime dependencies**: use Ruby stdlib (`Net::HTTP`, `JSON`) only. Development gems (rspec, webmock, …) go in the gemspec's development dependencies.
- **RSpec** for tests, mirroring the `lib/` layout (`lib/typesafe/foo.rb` → `spec/typesafe/foo_spec.rb`).
- `# frozen_string_literal: true` at the top of every file.
- Value objects are **frozen and immutable**; they dup and freeze their own copies of inputs without freezing the caller's objects.
- Validation raises plain `ArgumentError`.
- Test-first: add or extend the spec alongside any change.

## Versioning

Every commit that touches the gem must:

1. bump `Typesafe::VERSION` in `lib/typesafe/version.rb` (breaking changes require a major bump now that the gem is 1.0),
2. add a `CHANGELOG.md` entry ([Keep a Changelog](https://keepachangelog.com) format),
3. include the new version in the commit message.

Releases to RubyGems are automated: a GitHub Actions workflow publishes the gem whenever CI passes on `main` with a changed version.

## Submitting changes

1. Fork / branch from `main`.
2. Make your change with tests.
3. `bundle exec rspec` green.
4. Open a pull request describing what and why.

## Reporting issues

Use the [issue templates](.github/ISSUE_TEMPLATE); bug reports should include a minimal reproduction and the gem version (`Typesafe::VERSION`).
