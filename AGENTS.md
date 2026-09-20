# AGENTS.md

## Project

Build a Ruby gem (`typesafe-jev`) to use **Jev** — TypeSafe's flagship System One model — from Ruby and Rails. Home: `https://docs.typesafe.ai`.

## Current state

Minimal scaffold only. **No Jev/API code yet** — the gem contains an empty `module Typesafe` and a version constant. Do not assume a client exists.

## Structure

```
lib/typesafe.rb            # empty module (entry point)
lib/typesafe/version.rb    # VERSION = "0.1.0"
spec/                      # RSpec (not minitest)
spec/spec_helper.rb
spec/typesafe_spec.rb
```

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

Single endpoint: `POST https://api.typesafe.ai/v1/systemone` with `Authorization: Bearer <API_KEY>`. Request: `{ state, model: "jev-latest", questions: { <id>: Question } }`. Three question types — **Noul** (yes/no probability), **Choice** (option + probability distribution + confidence), **Score** (probability-weighted level + legend + confidence). Errors: 401 (auth), 422 (validation), 429 (rate limit) and 529 (overloaded) — retry 429/529 with exponential backoff. Docs index: `https://docs.typesafe.ai/llms.txt` (append `.md` to page URLs to fetch Markdown).

## Conventions

- Ruby 3.4 locally (via mise). Freeze string literals in all files.
- Git repo is initialized but has **no remote yet** — don't push, just commit.
