# Lexique

## Erreurs

**Erreur retentable**:
Erreur HTTP que le client peut rejouer telle quelle avec une chance de succès : 429 (limite de débit), 529 (surcharge) et 5xx (erreur serveur). Définie par `Typesafe::APIError#retryable?`.
_Exemple_ : un 529 pendant une salve d'appels est retentable ; un 401 ne l'est jamais.
_Éviter_ : erreur transitoire, erreur temporaire
_Liens_ : Erreur de connexion, lib/typesafe/errors.rb

**Erreur de connexion**:
Échec au niveau réseau (connexion refusée, DNS, timeout de lecture/écriture, connexion réinitialisée) survenu avant toute réponse HTTP. Renvoyée aux utilisateurs sous forme de `Typesafe::ConnectionError < APIError`, marquée retentable.
_Exemple_ : un timeout de lecture de 30 s lève une ConnectionError, pas une `Net::ReadTimeout`.
_Éviter_ : erreur réseau brute, NetworkError
_Liens_ : Erreur retentable, lib/typesafe/errors.rb
