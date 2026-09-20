# typesafe-jev

[![CI](https://github.com/dtheofr/typesafe-jev-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/dtheofr/typesafe-jev-ruby/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/typesafe-jev?logo=rubygems&color=brightgreen)](https://rubygems.org/gems/typesafe-jev)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1-red?logo=ruby)](https://rubygems.org/gems/typesafe-jev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Ruby client for [Jev](https://docs.typesafe.ai), TypeSafe's System One model. Ask natural-language questions about your application state and get typed, probabilistic answers you can program against.

**Zero runtime dependencies**: pure Ruby stdlib (`Net::HTTP`, `JSON`), so it works in plain Ruby and Rails alike.

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
      "Low: routine request",
      "Medium: degraded experience",
      "High: blocked user",
      "Critical: money lost or security issue"
    ])
  }
)

response[:refund_requested].noul  # => 0.95 (yes/no probability, 0..1)
response[:category].choice        # => "billing"
response[:category].probabilities # => { "billing" => 0.88, "technical" => 0.12, "sales" => 0.0 }
response[:severity].score         # => "High: blocked user"
response.usage.input_tokens       # => 296
```

`Typesafe::Jev.evaluate` is the one-shot facade with the model pinned to `jev-latest`. For another model, use `Typesafe::Client` directly.

## Questions

Questions are frozen, immutable value objects. The question **id is not in the object**; it is the Hash key in the `questions:` map, and answers come back under the same key.

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

Invalid input raises `ArgumentError` at construction time, so bad questions fail fast, before any HTTP call.

## Responses

`Client#evaluate` returns a frozen `Typesafe::Response`:

- `response[id]` (or `response.answers`): a typed `NoulAnswer`, `ChoiceAnswer` or `ScoreAnswer`; String and Symbol ids both work
- `response.model`: the model that performed the evaluation
- `response.usage`: `Typesafe::Usage` with `input_tokens` / `output_tokens`
- `response.to_h` / `response.to_json`: the raw API shape

Each answer type exposes its own accessors (`#noul`, `#choice`, `#probabilities`, `#confidence`, `#score`, `#legend`, …) and serializes via `#to_h`/`#to_json`.

## Errors

Any non-2xx HTTP response raises a typed error. All inherit from `Typesafe::APIError` (root: `Typesafe::Error`), which carries `#status`, `#body`, `#headers`, `#request_id` and `#retryable?`. A network failure that occurs before any HTTP response raises a retryable `Typesafe::ConnectionError` instead (see [Retries](#retries)).

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
| `Typesafe::ConnectionError` | n/a (network, no HTTP response) | `#cause` (wrapped exception) |

Retryable errors (429, 529, 5xx) and `ConnectionError` are retried automatically, then raised once the retry budget is exhausted; non-retryable errors (400, 401, 403, 404, 422) raise immediately. See [Retries](#retries) for the full policy.

```ruby
begin
  Typesafe::Jev.evaluate(state: state, questions: questions)
rescue Typesafe::ConnectionError => e
  warn "TypeSafe unreachable: #{e.cause}"
rescue Typesafe::APIError => e
  raise "typesafe request failed (status #{e.status}, request #{e.request_id}): #{e.body}"
end
```

## Retries

Retryable failures are retried automatically: rate limits (429), overload (529), server errors (5xx), everything `APIError#retryable?` covers, and network failures that occur before any HTTP response (refused connection, DNS failure, read/write timeout, reset connection), which are wrapped in a retryable `Typesafe::ConnectionError`. By default the client makes **2 retries** (3 attempts in total). The wait honors the server's `Retry-After` / `Retry-After-Ms` header when a 429 carries one; otherwise it is an exponential backoff starting at **0.5 s**, doubled on each retry, capped at **8.0 s**, with jitter so parallel clients do not align. Non-retryable errors (400, 401, 403, 404, 422) raise immediately, without any replay. The POST is replayed verbatim on each attempt (an evaluation is stateless), and retries are silent: no log output, no callback.

The whole policy is configured once per client with a single `retry_options:` Hash:

```ruby
# defaults: { max_retries: 2, base_delay: 0.5, max_delay: 8.0 }
client = Typesafe::Client.new(api_key: "sk-...", retry_options: { max_retries: 3 })

# latency-sensitive path: back to a single attempt
strict = Typesafe::Client.new(api_key: "sk-...", retry_options: { max_retries: 0 })

# Typesafe::Jev inherits the option from Typesafe::Client
jev = Typesafe::Jev.new(api_key: "sk-...", retry_options: { max_retries: 0 })
```

Accepted keys: `max_retries` (non-negative Integer), `base_delay` and `max_delay` (non-negative numbers). An absent key, a `nil` value, or `retry_options: nil` keeps the defaults; `max_retries: 0` restores a single attempt. Options are validated strictly at construction time (an unknown key, a typo for instance, or an invalid value raises an `ArgumentError` naming the key), and the normalized Hash is frozen on the client: mutating the Hash you passed later has no effect. The policy is fixed at initialization, so `evaluate`'s signature does not change and there is no per-call override.

## Configuration

The API key is read from the `TYPESAFE_API_KEY` environment variable unless passed explicitly:

```ruby
jev = Typesafe::Jev.new                      # key from ENV
jev = Typesafe::Jev.new(api_key: "sk-...")   # or explicit

client = Typesafe::Client.new(api_key: "sk-...", model: "other-model")
client.evaluate(state:, questions:, model: "one-off-model") # per-call override
```

Both `Typesafe::Client.new` and `Typesafe::Jev.new` also take the retry policy as a `retry_options:` Hash at initialization; see [Retries](#retries).

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
