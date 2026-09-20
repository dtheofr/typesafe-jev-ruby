<!--
  🏗️ PR DOCS DE L'ÉPIC — modèle installé par /reglage (suite dev-workflow française).
  À utiliser pour : la PR qui dépose la spec et la log d'affinage. Elle est le BAS de la pile :
  toutes les PR de tickets se base dessus.
  Écrit par : /cadrage §5.5. Titre `docs(⟨slug⟩): plan de ⟨sujet⟩`, base = la branche de l'épic
  consignée dans `.agents/dev-workflow.md`, head = `epic-⟨n⟩`.
  Contrats : la PREMIÈRE LIGNE est `Closes #⟨epic⟩` — sur fusion elle ferme l'épic, donc toute la
  pile. NE PAS décrire la pile (l'UI de GitHub la montre) ; PAS de label (`Epic` est un label
  d'issue, `prêt` une porte réservée aux tickets).
  Dans l'UI web : choisir « epic-docs » dans le sélecteur de modèles.
-->

Closes #⟨epic⟩

## 🔍 Ce que dépose cette PR

<!-- Deux à cinq lignes : les artefacts de cadrage, pas leur plan. -->

⟨la spec et la session d'affinage de ⟨sujet⟩, posées sur la branche de l'épic avant tout code⟩

## 📚 Contenu

- Spec : `docs/plans/⟨slug⟩/spec.md`
- Affinage : `docs/plans/⟨slug⟩/affinage.md` *(mode `--tech` : les ADR `docs/adr/NNNN-…`)*
- Glossaire : `LEXIQUE.md` — ⟨termes ajoutés, ou `inchangé`⟩

## 🧭 Ce que la spec arrête

<!-- Trois à six puces, prises dans `## Décisions d'implémentation` : ce qu'un relecteur doit
     connaître avant de lire les tickets. Pas un résumé de la spec tout entière. -->

- ⟨décision structurante⟩
- ⟨décision structurante⟩

## 🧪 Seam de test

<!-- Validé dans /cadrage §2 ; c'est là que /au-boulot écrira les tests. -->

- **Seam retenu** : `⟨seam⟩` — ⟨pourquoi celui-ci⟩

## ⚠️ Bas de la pile

<!-- Ordre de fusion : CETTE PR d'abord — son `Closes #⟨epic⟩` ferme l'épic et toute la pile — puis
     les PR de tickets, de haut en bas, une à une. Les tickets ne sont pas encore découpés à ce
     stade : c'est /decoupage qui les publie, en sub-issues natives de l'épic. -->

- Épic : #⟨epic⟩ — ⟨N⟩ tickets à découper *(ou `à découper`)*
- Fusion : **ici d'abord**, puis les tickets de haut en bas
