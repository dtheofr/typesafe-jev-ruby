# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-20

### Added

- **Automatic retries** on retryable errors (429, 529 and 5xx): by default
  `Typesafe::Client#evaluate` (and `Typesafe::Jev.evaluate`) now retries up to
  2 times (3 attempts in total) with an exponential backoff — 0.5 s base,
  doubled on each retry, capped at 8 s, with jitter — before raising the last
  retryable error. The POST is replayed verbatim; non-retryable errors
  (400, 401, 403, 404, 422) still raise immediately without any replay. The
  retries are silent: no log output, no configuration needed.

- **`Retry-After` honored** on rate limits: when a 429 carries a `Retry-After`
  (seconds) or `Retry-After-Ms` (milliseconds) header, `Typesafe::Client#evaluate`
  (and `Typesafe::Jev.evaluate`) now waits exactly the delay the server imposes
  before retrying, instead of the default exponential backoff. A 429 without
  either header — or with a non-numeric `Retry-After` — keeps the default
  exponential backoff.

- **Network errors become retryable and wrapped**: a failure at the network
  level — connection refused, DNS failure, connection/read/write timeout,
  reset connection, truncated stream or TLS handshake failure — no longer
  escapes `Typesafe::Client#evaluate` (or `Typesafe::Jev.evaluate`) raw. It is
  wrapped in a new retryable `Typesafe::ConnectionError < APIError` with the
  original exception preserved as `#cause`, and follows the exact same retry
  policy as the 429/529/5xx errors: replayed with the default
  exponential backoff, then raised once the budget is exhausted. A brief
  outage is therefore absorbed by the automatic retries.

- **Configurable retry policy via `retry_options:`**: `Typesafe::Client.new`
  (and `Typesafe::Jev.new`) now accept a single `retry_options:` Hash that
  tunes the retry loop — `max_retries` (2 by default), `base_delay` (0.5 s)
  and `max_delay` (8.0 s). Absent keys, `nil` values and `retry_options: nil`
  keep the defaults, and `max_retries: 0` restores the
  single-attempt behavior. Unknown keys and invalid values (negative or
  non-numeric delays, non-Integer `max_retries`) raise an `ArgumentError`
  naming the key at construction time. The normalized options are dupped and
  frozen on the client (mutating the Hash passed at initialization has no
  effect); `evaluate` keeps its signature.

### Documentation

- **The README documents the automatic retries end to end**: retryable errors
  (429, 529 and 5xx) and network failures wrapped in a retryable
  `Typesafe::ConnectionError` are retried automatically, 2 retries by
  default (3 attempts in total). The wait honors the server's `Retry-After`
  / `Retry-After-Ms` header on a 429; otherwise it follows an exponential
  backoff, 0.5 s base, doubled on each retry, capped at 8.0 s, with jitter.
  The policy is tuned or disabled per client via `retry_options:` on
  `Typesafe::Client.new` (inherited by `Typesafe::Jev.new`): `max_retries` /
  `base_delay` / `max_delay`, with `max_retries: 0` restoring a single
  attempt. Unknown keys and invalid values raise an `ArgumentError` naming
  the key at construction time, and the normalized options are frozen on the
  client. Retries are silent (no log, no callback) and replay the POST
  verbatim; non-retryable errors (400, 401, 403, 404, 422) raise immediately
  without any replay. See the README section "Retries".

## [1.0.0] - 2026-09-20

### Added

- Full MIT `LICENSE` text, a complete README (quickstart, question/answer/error guide), a `CONTRIBUTING.md` guide and GitHub issue templates.
- Gemspec metadata: `documentation_uri` (rubydoc.info) and `rubygems_mfa_required`; homepage now points at the GitHub repository.

### Changed

- **Stability**: the public API shipped in 0.7.0 is now declared stable and covered by Semantic Versioning; breaking changes will require a major version bump from here on.

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
