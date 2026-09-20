# typesafe-jev

[![CI](https://github.com/dtheofr/typesafe-jev-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/dtheofr/typesafe-jev-ruby/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/typesafe-jev?logo=rubygems&color=brightgreen)](https://rubygems.org/gems/typesafe-jev)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1-red?logo=ruby)](https://rubygems.org/gems/typesafe-jev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ruby client for [Jev](https://docs.typesafe.ai), TypeSafe's System One model. Ask natural-language questions about your application state and get typed, probabilistic answers you can program against.

**Zero runtime dependencies** — pure Ruby stdlib (`Net::HTTP`, `JSON`), so it works in plain Ruby and Rails alike.

## Installation

```sh
gem install typesafe-jev
```

or in your `Gemfile`:

```ruby
gem "typesafe-jev"
```

## Quickstart

```ruby
require "typesafe"

response = Typesafe::Jev.evaluate(
  state: { ticket: { text: "My payouts failed twice this week." } },
  questions: {
    refund_requested: Typesafe::Noul.new("Does the customer request a refund?"),
    category: Typesafe::Choice.new("Which category does this ticket belong to?", criteria: {
      billing:   "Payment, invoices, refunds",
      technical: "Bugs and outages",
      sales:     "Pre-sales questions"
    }),
    severity: Typesafe::Score.new("How severe is this ticket?", criteria: [
      "Low — routine request",
      "Medium — degraded experience",
      "High — blocked user",
      "Critical — money lost or security issue"
    ])
  }
)

response[:refund_requested].noul  # => 0.95 (yes/no probability, 0..1)
response[:category].choice        # => "billing"
response[:category].probabilities # => { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 }
response[:severity].score         # => "High — blocked user"
response.usage.input_tokens       # => 296
```

`Typesafe::Jev.evaluate` is the one-shot facade with the model pinned to `jev-latest`. For another model, use `Typesafe::Client` directly.

## Questions

Questions are frozen, immutable value objects. The question **id is not in the object** — it is the Hash key in the `questions:` map, and answers come back under the same key.

| Class | Answers with | Criteria |
|---|---|---|
| `Typesafe::Noul` | a yes/no probability (`noul`, 0..1) | optional `{ true: ..., false: ... }` |
| `Typesafe::Choice` | one option + full probability distribution + `confidence` | non-empty `{ key: "description" }` |
| `Typesafe::Score` | a level + `legend` + distribution + `confidence` | non-empty `["Level 1", "Level 2", ...]` |

```ruby
Typesafe::Noul.new("Does the customer request a refund?",
  criteria: { true: "The customer explicitly asks for their money back",
              false: "The customer does not mention refunds" })

Typesafe::Choice.new("Which category does this ticket belong to?",
  criteria: { billing: "Payment, invoices, refunds", technical: "Bugs and outages" })

Typesafe::Score.new("How severe is this ticket?",
  criteria: ["Low", "Medium", "High", "Critical"])
```

Invalid input raises `ArgumentError` at construction time, so bad questions fail fast — before any HTTP call.

## Responses

`Client#evaluate` returns a frozen `Typesafe::Response`:

- `response[id]` (or `response.answers`) — a typed `NoulAnswer`, `ChoiceAnswer` or `ScoreAnswer`; String and Symbol ids both work
- `response.model` — the model that performed the evaluation
- `response.usage` — `Typesafe::Usage` with `input_tokens` / `output_tokens`
- `response.to_h` / `response.to_json` — the raw API shape

Each answer type exposes its own accessors (`#noul`, `#choice`, `#probabilities`, `#confidence`, `#score`, `#legend`, …) and serializes via `#to_h`/`#to_json`.

## Errors

Any non-2xx HTTP response raises a typed error. All inherit from `Typesafe::APIError` (root: `Typesafe::Error`), which carries `#status`, `#body`, `#headers`, `#request_id` and `#retryable?`.

| Error | Status | Extras |
|---|---|---|
| `Typesafe::BadRequestError` | 400 | |
| `Typesafe::AuthenticationError` | 401 | |
| `Typesafe::PermissionDeniedError` | 403 | |
| `Typesafe::NotFoundError` | 404 | |
| `Typesafe::UnprocessableEntityError` | 422 | `#errors` (validation details) |
| `Typesafe::RateLimitError` | 429 | `#retry_after` |
| `Typesafe::OverloadedError` | 529 | |
| `Typesafe::ServerError` | 5xx | |

```ruby
begin
  Typesafe::Jev.evaluate(state: state, questions: questions)
rescue Typesafe::RateLimitError => e
  sleep(e.retry_after || 1.0)
  retry
rescue Typesafe::OverloadedError
  sleep(2**attempt)
  retry
rescue Typesafe::APIError => e
  raise "typesafe request failed (#{e.status}, request #{e.request_id}): #{e.body}"
end
```

## Configuration

The API key is read from the `TYPESAFE_API_KEY` environment variable unless passed explicitly:

```ruby
jev = Typesafe::Jev.new                      # key from ENV
jev = Typesafe::Jev.new(api_key: "sk-...")   # or explicit

client = Typesafe::Client.new(api_key: "sk-...", model: "other-model")
client.evaluate(state:, questions:, model: "one-off-model") # per-call override
```

## Documentation

TypeSafe docs live at [docs.typesafe.ai](https://docs.typesafe.ai). The full API reference for this gem is on [rubydoc.info](https://rubydoc.info/gems/typesafe-jev).

## Development

```sh
bundle install
bundle exec rake spec   # or: bundle exec rspec
```

The test suite runs against Ruby 3.1 and 3.4 in CI. See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions.

## License

[MIT](LICENSE)
