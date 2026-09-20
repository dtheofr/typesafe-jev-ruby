# AGENTS.md

## Project

Build a Ruby gem (`typesafe-jev`) to use **Jev**, TypeSafe's flagship System One model, from Ruby and Rails. Home: `https://docs.typesafe.ai`.

## Current state

Question classes exist ({Noul, Choice, Score} value objects under `Typesafe::`, see Structure). **No HTTP client yet**, so do not assume one exists.

## Structure

```
lib/typesafe.rb            # entry point: requires json + all question files
lib/typesafe/version.rb    # VERSION = "0.2.0"
lib/typesafe/question.rb   # abstract base: instructions, type, to_h/to_json, ==/hash, freezing
lib/typesafe/noul.rb       # Noul(instructions, criteria: nil): criteria { true:, false: }, keys normalized to symbols
lib/typesafe/choice.rb     # Choice(instructions, criteria:): non-empty Hash, String/Symbol keys => String descriptions
lib/typesafe/score.rb      # Score(instructions, criteria:): non-empty Array of Strings
spec/                      # RSpec (not minitest), mirroring lib/ layout
```

Question design decisions:

- No `Question` suffix on class names; `Typesafe::Question` is the abstract base class.
- Questions are frozen, immutable value objects; they dup inputs and freeze their own copies (caller's objects are not frozen).
- The question **id is NOT in the object**; it is the Hash key in the future request's `questions:` map (`{ refund_requested: Typesafe::Noul.new(...) }`).
- Validation raises plain `ArgumentError`.
- `#to_h` returns the API shape (`{ type:, instructions:, criteria: }`, Noul omits `criteria` when nil); `#to_json` serializes it.

## Commands

```sh
bundle install          # first setup
bundle exec rake spec   # run tests (default rake task)
bundle exec rspec       # run tests directly
```

## Key decisions

- **Zero runtime dependencies**: use Ruby stdlib (`Net::HTTP`, `JSON`) so the gem works in plain Ruby and Rails.
- **RSpec** for tests; `spec/` directory.
- Gem name: `typesafe-jev`, module namespace: `Typesafe`.
- Ruby requirement: `>= 3.1`.
- Keep the scaffold minimal until functionality is agreed; no speculative code.

## API contract (for when the client is built)

Single endpoint: `POST https://api.typesafe.ai/v1/systemone` with `Authorization: Bearer <API_KEY>`. Request: `{ state, model: "jev-latest", questions: { <id>: Question } }`. Three question types: **Noul** (yes/no probability), **Choice** (option + probability distribution + confidence), **Score** (probability-weighted level + legend + confidence). Errors: 401 (auth), 422 (validation), 429 (rate limit) and 529 (overloaded); retry 429/529 with exponential backoff. Docs index: `https://docs.typesafe.ai/llms.txt` (append `.md` to page URLs to fetch Markdown).

## Conventions

- **Always bump the version** in `lib/typesafe/version.rb` (and add a `CHANGELOG.md` entry) whenever committing changes to the gem; include the new version in the commit message.
- Ruby 3.4 locally (via mise). Freeze string literals in all files.
