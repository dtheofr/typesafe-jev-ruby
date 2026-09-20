# Dev workflow — dtheofr/typesafe-jev-ruby

- Tracker: GitHub
- Repo: dtheofr/typesafe-jev-ruby
- Default branch: main
- Epic base branch: main   ← edit only if epics should branch elsewhere
- Delete-branch-on-merge: true
- Branch convention: epic-<n>-docs (docs branch + bottom-of-stack PR) · epic-<n>/<NN>-<slug> (tickets) — the docs branch is suffixed `-docs`: git cannot hold both `epic-<n>` and an `epic-<n>/…` ref prefix
- Templates — epic: .github/ISSUE_TEMPLATE/epic.md (installed) · ticket: .github/ISSUE_TEMPLATE/ticket.md (installed) · PR-docs: .github/PULL_REQUEST_TEMPLATE/epic-docs.md (installed) · PR-ticket: .github/PULL_REQUEST_TEMPLATE/epic-ticket.md (installed)
- Templates — repo's own (extra sections to merge, never drop): .github/ISSUE_TEMPLATE/bug_report.yml, .github/ISSUE_TEMPLATE/feature_request.yml
- Paseo profiles — Explorer: Explorer · Worker: Worker · Advisor: Advisor

## Conventions

Domain files are hardcoded suite conventions, created lazily by the other skills — not configuration:

- `LEXIQUE.md` — domain glossary, repo root
- `CARTE-LEXIQUES.md` — context map, repo root (multi-context repos only)
- `docs/adr/` — architecture decision records
