# Changelog

## 0.3.0

- Add `Typesafe::Client`: `initialize(api_key:, model:)` (key from argument or `TYPESAFE_API_KEY`, model defaults to `jev-latest`) and `evaluate(state:, questions:, model: nil)` posting to the System One endpoint. Returns the parsed JSON response; non-2xx responses raise the stdlib `Net::HTTP` error as-is.

## 0.2.0

- Add question classes: `Typesafe::Noul`, `Typesafe::Choice`, `Typesafe::Score` with the abstract `Typesafe::Question` base. Frozen, immutable value objects that validate their inputs and serialize to the TypeSafe API shape via `#to_h`/`#to_json`.

## 0.1.0

- Initial gem scaffold.
