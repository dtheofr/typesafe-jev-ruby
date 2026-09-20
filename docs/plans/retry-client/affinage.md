# Affinage — Retry des requêtes HTTP dans le client

- Date : 2026-09-20 · Sujet : ajouter une fonctionnalité de retry au client HTTP du gem · Mode : produit
- Sources : .agents/dev-workflow.md, AGENTS.md (contrat API), lib/typesafe/client.rb, lib/typesafe/errors.rb, lib/typesafe/jev.rb

## Round 1
Posé : Q1 — Périmètre des erreurs retentées · Q2 — Erreurs réseau · Q3 — Surface de configuration · Q4 — Stratégie de backoff · Q5 — Nombre de retries par défaut
- **Décision (user)** Q1 : 429 + 529 + 5xx (tout ce que `retryable?` considère) — AGENTS.md sera mis à jour en conséquence (le contrat « 429/529 seulement » est supplanté).
- **Décision (user)** Q2 : oui — encapsuler dans une `Typesafe::ConnectionError < APIError` retentable.
- **Décision (user)** Q3 : options sur `Client.new` uniquement (héritées par `Jev`), pas d'override par appel.
- **Décision (user)** Q4 : honorer `Retry-After` si présent, sinon backoff exponentiel 0,5 s → 8 s (doublement, plafond) + jitter.
- **Décision (user)** Q5 : 2 retries par défaut (3 tentatives au total), opt-out via configuration.

### Réglé jusqu'ici
| Q | Décision |
|---|---|
| Q1 | 429 + 529 + 5xx |
| Q2 | ConnectionError, retentable |
| Q3 | Options sur `Client.new` uniquement |
| Q4 | Retry-After sinon expo 0,5 s→8 s + jitter |
| Q5 | 2 retries par défaut |

## Round 2
Posé : Q6 — Réglage des délais · Q7 — Observabilité · Q8 — Budget temps global · Q9 — ADR
- **Décision (user)** Q6 : supplantée par l'amendement du user (voir ci-dessous) — les options de délai vivent dans `retry_options:`.
- **Décision (user)** Q7 : totalement silencieux en v1 — pas de callback ni de log.
- **Décision (user)** Q8 : pas de budget temps global — `max_retries` + plafond de délai bornent déjà le pire cas.
- **Décision (user)** Q9 : ADR-0001 écrite (`docs/adr/0001-retentatives-automatiques-par-defaut.md`, accepté) + AGENTS.md mis à jour.

### Amendement (user) — surface de configuration
- **Décision (user)** : remplacer les kwargs plats (`max_retries:`, …) par un **unique argument `retry_options:`** (Hash) regroupant toutes les options de retry, sur `Client.new`, hérité par `Jev`. Q3 est amendée en conséquence ; les détails (clés exactes, validation des clés inconnues) sont reposés en Round 3.

### Réglé jusqu'ici
| Q | Décision |
|---|---|
| Q1 | 429 + 529 + 5xx |
| Q2 | ConnectionError, retentable |
| Q3 | ~~kwargs plats~~ → `retry_options:` (Hash unique) sur `Client.new` (amendé) |
| Q4 | Retry-After sinon expo 0,5 s→8 s + jitter |
| Q5 | 2 retries par défaut |
| Q7 | Silencieux, pas de hook v1 |
| Q8 | Pas de budget global |
| Q9 | ADR-0001 + AGENTS.md mis à jour |

## Round 3
Posé : Q10 — Clés de `retry_options:` · Q11 — Clés inconnues
- **Décision (user)** Q10 : `{ max_retries:, base_delay:, max_delay: }` — clés absentes/nil → valeurs par défaut (2 / 0,5 / 8,0) ; `retry_options: nil` = tous les défauts ; valeurs validées (numériques positifs, Integer pour max_retries) et hash normalisé figé sur le client.
- **Décision (user)** Q11 : `ArgumentError` sur toute clé inconnue (typo = échec bruyant à la construction du client).

### Réglé jusqu'ici
| Q | Décision |
|---|---|
| Q10 | max_retries / base_delay / max_delay, défauts 2 / 0,5 / 8,0 |
| Q11 | ArgumentError sur clé inconnue |

- Session confirmée le 2026-09-20
- Passage advisor proposé (sujets : retry actif par défaut, silence des retries en v1) — refusé par le user, les décisions tiennent telles quelles.

### Délibérément non posé
- Formule de jitter exacte (full vs equal jitter, amplitude) — détail d'implémentation, politique figée en v1.
- Liste précise des exceptions réseau enveloppées par ConnectionError — détail d'implémentation pour /cadrage.
