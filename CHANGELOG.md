# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-20

### Added

- Full MIT `LICENSE` text, a complete README (quickstart, question/answer/error guide), a `CONTRIBUTING.md` guide and GitHub issue templates.
- Gemspec metadata: `documentation_uri` (rubydoc.info) and `rubygems_mfa_required`; homepage now points at the GitHub repository.

### Changed

- **Stability**: the public API shipped in 0.7.0 is now declared stable and covered by Semantic Versioning — breaking changes will require a major version bump from here on.

## [0.7.0] - 2026-09-20

### Changed

- **Breaking**: `Typesafe::Client#evaluate` (and `Typesafe::Jev.evaluate`) now raises typed `Typesafe::Error` subclasses on any non-2xx response instead of raw `Net::HTTPClientException`/`Net::HTTPFatalError`: `BadRequestError` (400), `AuthenticationError` (401), `PermissionDeniedError` (403), `NotFoundError` (404), `UnprocessableEntityError` (422, with `#errors`), `RateLimitError` (429, with `#retry_after`), `OverloadedError` (529) and `ServerError` (5xx), all under the `Typesafe::APIError` base with `status`, `body`, `headers`, `request_id` and `#retryable?`. `Typesafe::Error` is the root rescuable class.

## [0.6.0] - 2026-09-20

### Changed

- **Breaking**: `Typesafe::Client#evaluate` (and `Typesafe::Jev.evaluate`) now returns a typed `Typesafe::Response` instead of the raw parsed Hash; answers come back as `NoulAnswer`/`ChoiceAnswer`/`ScoreAnswer` objects accessible via `response[question_id]` (String or Symbol). Use `response.to_h` for the previous raw-Hash behavior.

## [0.5.0] - 2026-09-20

### Added

- Response classes mirroring the question classes: abstract `Typesafe::Answer` base with `Answer.from_h` dispatching on the `type` tag, plus `Typesafe::NoulAnswer` (`noul`), `Typesafe::ChoiceAnswer` (`choice`, `probabilities`, `confidence`) and `Typesafe::ScoreAnswer` (`score`, `legend`, `probabilities`, `confidence`). Frozen, immutable value objects that validate their inputs and serialize via `#to_h`/`#to_json`.
- `Typesafe::Usage` (token counts) and `Typesafe::Response` (`model`, `answers`, `usage`), with `Response.from_json`/`from_h` to parse an API response body into typed Answer objects; `Response#[]` accepts String or Symbol question ids.

## [0.4.1] - 2026-09-20

### Fixed

- Gemspec metadata: point `source_code_uri`/`changelog_uri` and author/email at the `dtheofr` GitHub account.

## [0.4.0] - 2026-09-20

### Added

- `Typesafe::Jev`, a `Typesafe::Client` subclass with the model pinned to `jev-latest`: `Jev.new(api_key: nil).evaluate(...)` plus a one-shot `Typesafe::Jev.evaluate(state:, questions:, api_key: nil)`.

## [0.3.0] - 2026-09-20

### Added

- `Typesafe::Client`: `initialize(api_key:, model:)` (key from argument or `TYPESAFE_API_KEY`, model defaults to `jev-latest`) and `evaluate(state:, questions:, model: nil)` posting to the System One endpoint. Returns the parsed JSON response; non-2xx responses raise the stdlib `Net::HTTP` error as-is.

## [0.2.0] - 2026-09-20

### Added

- Question classes: `Typesafe::Noul`, `Typesafe::Choice`, `Typesafe::Score` with the abstract `Typesafe::Question` base. Frozen, immutable value objects that validate their inputs and serialize to the TypeSafe API shape via `#to_h`/`#to_json`.

## [0.1.0] - 2026-09-20

### Added

- Initial gem scaffold.

[unreleased]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.7.0...v1.0.0
[0.7.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/dtheofr/typesafe-jev-ruby/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/dtheofr/typesafe-jev-ruby/releases/tag/v0.1.0
