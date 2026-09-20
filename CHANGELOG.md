# Changelog

## 0.2.0

- Add question classes: `Typesafe::Noul`, `Typesafe::Choice`, `Typesafe::Score` with the abstract `Typesafe::Question` base. Frozen, immutable value objects that validate their inputs and serialize to the TypeSafe API shape via `#to_h`/`#to_json`.

## 0.1.0

- Initial gem scaffold.
