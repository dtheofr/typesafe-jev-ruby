# 0001 — Retentatives automatiques activées par défaut dans le client

**Statut :** accepté
**Contexte :** l'API TypeSafe renvoie des erreurs transitoires — 429 (limite de débit), 529 (surcharge), 5xx (erreur serveur) — et subit des échecs réseau (timeout, connexion refusée). Le contrat API initial (AGENTS.md) prévoyait un retry manuel limité à 429/529, à la charge de l'appelant. Un client Ruby qui rejoue chaque échec transitoire à la main répète le même code chez chaque utilisateur, et les surcharges 529 sont assez fréquentes pour que la résilience zéro-config soit la valeur principale du gem.

**Décision :** le client retente automatiquement, par défaut, toute erreur retentable (`APIError#retryable?` : 429, 529, 5xx) ainsi que les erreurs de connexion (`ConnectionError`, nouveau wrapper des exceptions réseau). Par défaut : 2 retries (3 tentatives au total). Délai : `Retry-After`/`Retry-After-Ms` honoré quand présent (429), sinon backoff exponentiel 0,5 s → 8 s (doublement, plafond, jitter). Configuration via un unique argument `retry_options:` (Hash) sur `Client.new`, hérité par `Jev` — pas d'override par appel. Aucune sortie de log ni callback : les retries sont silencieux en v1. Cette décision écarte délibérément le contrat « retry 429/529 seulement » d'AGENTS.md, qui est mis à jour en conséquence.

**Conséquences :**
- Un appel `evaluate` peut durer jusqu'à ~3× les timeouts HTTP plus ~1,5 s de délais de retry au pire cas ; les appelants sensibles à la latence posent `retry_options: { max_retries: 0 }`.
- Un POST est rejoué à l'identique : acceptable car l'évaluation est sans état (aucune écriture côté serveur), mais chaque retry consomme potentiellement du quota.
- Les retries sont invisibles sans instrumentation côté appelant ; le coût de l'absence d'observabilité est assumé en v1.
- Le comportement par défaut d'un gem « bibliothèque » devient actif (retry) plutôt que passif : toute future API du client devra préserver cette sémantique ou casser la compatibilité.
