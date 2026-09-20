# Spec — Retentatives automatiques dans le client HTTP

- Date : 2026-09-20 · Sujet : ajouter une fonctionnalité de retry au client HTTP du gem · Slug : `retry-client`
- Sources : `docs/plans/retry-client/affinage.md`, `LEXIQUE.md`, `docs/adr/0001-retentatives-automatiques-par-defaut.md`, `.agents/dev-workflow.md`
- Épic : #6

## Problème

Aujourd'hui, chaque échec transitoire — 429 (limite de débit), 529 (surcharge), 5xx (erreur serveur) ou simple timeout réseau — remonte immédiatement à l'appelant de `Typesafe::Client#evaluate`. Chaque utilisateur du gem doit réécrire à la main la même boucle « attendre puis rejouer », et la plupart ne le font pas : leurs intégrations sont fragiles aux salves de surcharge, faute de résilience zéro-config.

## Solution

Le client retente automatiquement les erreurs retentables (429, 529, 5xx) et les erreurs de connexion, par défaut 2 retries (3 tentatives au total). Le délai suit le `Retry-After` du serveur quand il existe, sinon un backoff exponentiel 0,5 s → 8 s avec jitter. Toute la politique se règle via un unique argument `retry_options:` (Hash) sur `Client.new` ; les appelants sensibles à la latence posent `retry_options: { max_retries: 0 }` pour retrouver le comportement actuel.

## User stories

1. En tant que développeur Ruby/Rais intégrant le gem, je veux que les erreurs retentables (429, 529, 5xx) soient rejouées automatiquement, afin que mes évaluations survivent aux incidents passagers sans code de ma part.
2. En tant que développeur intégrant le gem, je veux qu'une erreur réseau (connexion refusée, DNS, timeout de lecture/écriture, connexion réinitialisée) soit encapsulée dans une `Typesafe::ConnectionError` (sous-classe de `APIError`), afin de traiter tous les échecs via un unique `rescue Typesafe::Error`.
3. En tant que développeur intégrant le gem, je veux que la `ConnectionError` soit considérée comme une erreur retentable, afin que les coupures réseau brèves soient absorbées sans intervention.
4. En tant que développeur, je veux 2 retries par défaut (3 tentatives au total), afin d'obtenir une résilience utile sans rien configurer.
5. En tant que développeur sensible à la latence, je veux poser `retry_options: { max_retries: 0 }`, afin de retrouver le comportement actuel (une seule tentative) pour mes chemins critiques.
6. En tant que développeur, je veux configurer toute la politique via un unique Hash `retry_options:` passé à `Client.new` (hérité par `Typesafe::Jev`), afin de ne pas dupliquer la configuration à chaque appel.
7. En tant que développeur, je veux régler `max_retries`, `base_delay` et `max_delay` dans ce Hash, afin d'adapter le rythme des retentatives à mon contexte sans plombier les internes du gem.
8. En tant que serveur de l'API TypeSafe, je veux que le client honore mon en-tête `Retry-After` / `Retry-After-Ms` quand il accompagne un 429, afin que la reprise respecte le rythme que j'impose.
9. En tant que développeur, je veux un backoff exponentiel (base 0,5 s, doublement, plafond 8 s, avec jitter) quand le serveur n'impose pas de délai, afin de ne pas marteler l'API pendant une surcharge et d'éviter les effects d'alignement entre clients parallèles.
10. En tant que développeur qui fait une typo dans `retry_options` (clé inconnue), je veux une `ArgumentError` dès la construction du client, afin de découvrir l'erreur immédiatement et non de subir silencieusement les valeurs par défaut.
11. En tant que développeur, je veux que les valeurs de `retry_options` soient validées (numériques non négatifs, `max_retries` entier) et que le Hash normalisé soit figé sur le client, afin d'obtenir un objet immuable et des messages d'erreur clairs en cas de valeur absurde.
12. En tant qu'appelant sous forte charge, je veux que la requête POST soit rejouée à l'identique sans effet de bord, afin que le retry soit sûr (l'évaluation est sans état).
13. En tant que développeur, je veux que les retentatives soient totalement silencieuses (pas de log, pas de callback), afin que le gem n'écrive jamais dans ma sortie standard ni n'impose d'API d'observation.
14. En tant que développeur, je veux qu'aucun budget temps global ne s'ajoute à la politique, afin que le pire cas reste borné par `max_retries` et le plafond de délai (~1,5 s de sommeil au-delà des timeouts HTTP avec les défauts).
15. En tant que développeur, je veux que les erreurs non retentables (400, 401, 403, 404, 422) ne soient jamais rejouées, afin qu'un problème définitif échoue vite et clairement.
16. En tant que mainteneur du gem, je veux que le contrat API d'AGENTS.md reflète la nouvelle sémantique de retry, afin que la documentation interne ne contredise pas le code.

## Décisions d'implémentation

- **Retentatives actives par défaut** : 2 retries (3 tentatives au total). Décision actée dans ADR-0001, qui écarte délibérément l'ancien contrat « retry 429/529 seulement, à la charge de l'appelant ».
- **Périmètre des erreurs retentées** : toute erreur retentable au sens de `APIError#retryable?` — 429, 529 et 5xx — plus les erreurs de connexion. Le vocabulaire suit `LEXIQUE.md` (erreur retentable, erreur de connexion).
- **`ConnectionError`** : nouvelle sous-classe de `APIError` encapsulant les échecs au niveau réseau survenus avant toute réponse HTTP (connexion refusée, DNS, timeout, connexion réinitialisée), marquée retentable. Les exceptions réseau cessent d'être levées brutes.
- **Surface de configuration** : un unique argument `retry_options:` (Hash) sur `Client.new`, hérité automatiquement par `Typesafe::Jev`. Pas d'override par appel : la signature de `evaluate` ne change pas.
- **Clés acceptées** : `max_retries`, `base_delay`, `max_delay`. Défauts : 2 / 0,5 / 8,0. Clé absente ou valeur `nil` → défaut. `retry_options: nil` → tous les défauts.
- **Validation stricte** : `ArgumentError` sur toute clé inconnue (la typo échoue bruyamment à la construction) et sur toute valeur invalide (numériques non négatifs ; `max_retries` entier). Le Hash normalisé est dupliqué et figé sur le client, dans le style immuable du gem.
- **Politique de délai** : `Retry-After` (secondes) ou `Retry-After-Ms` (millisecondes) honoré quand présent sur un 429 — le parsing existe déjà sur `RateLimitError#retry_after` ; sinon backoff exponentiel partant de `base_delay`, doublement à chaque tentative, plafonné à `max_delay`, avec jitter. La formule de jitter exacte est un détail d'implémentation (politique figée en v1, non réglable).
- **Pas de budget temps global** : `max_retries` et le plafond de délai bornent le pire cas.
- **Rejeu** : le POST est rejoué à l'identique (évaluation sans état, aucune écriture côté serveur) ; chaque retry peut consommer du quota — coût assumé.
- **Silence** : aucune sortie de log, aucun callback en v1.
- **Contrat** : la ligne « retry » d'AGENTS.md est mise à jour pour pointer vers ADR-0001 (déjà faite dans la session) ; le CHANGELOG enregistrera la nouvelle version au moment du code.

## Décisions de test

- **Seam retenu** : l'API publique `Typesafe::Client#evaluate` / `Typesafe::Jev#evaluate`, déjà le seam de `spec/typesafe/client_spec.rb` — l'endpoint HTTP est stubbé avec **WebMock** (`stub_request`), et `sleep` est stubbé pour contrôler les délais sans ralentir la suite. Le retry y est observable de l'extérieur : séquences de requêtes stubbées (échec puis succès), erreurs finalement levées, délais demandés, et jamais au niveau des internes.
- **Comportement testé** (l'externe, pas l'implémentation) : une séquence 529→529→200 réussit avec 2 sleeps ; une erreur au-delà de `max_retries` lève l'erreur d'origine ; un 422/401 n'est jamais rejoué ; `Retry-After` est demandé comme délai ; un échec réseau devient une `ConnectionError` retentée puis, à épuisement, levée ; la validation de `retry_options` (clé inconnue, valeur invalide) lève `ArgumentError` à la construction ; `Jev` hérite du comportement ; `max_retries: 0` retombe sur une tentative unique.
- **Prior art** : `spec/typesafe/client_spec.rb` (WebMock, erreurs), `spec/typesafe/errors_spec.rb`, `spec/typesafe/jev_spec.rb`.

## Hors périmètre

- **Observabilité** (callback `on_retry`, logger, métriques) — rejeté pour v1 (décision Q7) ; réintroduisable plus tard sans casser `retry_options`.
- **Override de la politique par appel** dans `evaluate` — rejeté (décision Q3, amendée en `retry_options:` unique).
- **Budget temps global** (`retry_total_budget:`) — rejeté (décision Q8), `max_retries` + plafond bornent déjà le pire cas.
- **Stratégie de retry pluggable** (objet de stratégie personnalisé) — supplantée par le Hash `retry_options:` à clés fixes.
- **Retentative des erreurs non retentables** (400/401/403/404/422) — jamais, par construction.
- **Formule de jitter exacte et liste précise des exceptions réseau enveloppées** — délibérément non posées (détails d'implémentation, voir Notes).

## Notes

- Deux points délibérément non tranchés en affinage, à régler à l'implémentation : la formule de jitter exacte (full vs equal jitter, amplitude) et la liste exhaustive des exceptions `Net::HTTP`/`Socket`/`OpenSSL` enveloppées par `ConnectionError`. Leur place naturelle est le découpage des tickets.
- Point ouvert pour l'implémentation : la `ConnectionError` devrait conserver l'exception d'origine en `cause`, cohérent avec l'encapsulation décidée (Q2) — non discuté explicitement en session.
- Les modifications de domaine issues de l'affinage sont déjà en place : `LEXIQUE.md` créé (erreur retentable, erreur de connexion), `docs/adr/0001-retentatives-automatiques-par-defaut.md` accepté, contrat AGENTS.md mis à jour.
