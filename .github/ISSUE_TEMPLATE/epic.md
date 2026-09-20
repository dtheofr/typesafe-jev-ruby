---
name: "Épic"
about: "Un ensemble de travail cadré — problème, solution, décisions arrêtées"
title: "⟨slug⟩: ⟨résumé en quelques mots⟩"
labels: ["Epic"]
---

<!--
  Modèle installé par /reglage — suite dev-workflow française.
  Écrit par : /cadrage §4, depuis docs/plans/⟨slug⟩/spec.md, elle-même issue de /affinage.
  Règles de remplissage : ne jamais supprimer un titre de section, garder l'ordre, remplacer
  chaque placeholder ⟨…⟩ — crochets compris. Ne rien inventer : ce que la session d'affinage n'a
  pas décidé ne va pas dans le corps (ou alors c'est un point de « Hors périmètre »).
  À ne pas faire : un bloc « Sous-tickets » — l'UI native des sub-issues de GitHub l'affiche déjà,
  il divergerait ; le label `prêt` — porte réservée aux tickets, honorée par /au-boulot.
-->

## 🎯 Problème

<!-- Le problème vécu, du point de vue de l'utilisateur — condensé de `## Problème` de la spec. -->

⟨une à trois phrases : ce qui coince aujourd'hui, pour qui, avec quelle conséquence⟩

## 💡 Solution

<!-- Condensé de `## Solution` : ce que l'utilisateur obtient, pas comment on le construit. -->

⟨une à trois phrases : ce qui change une fois l'épic livré⟩

## 🧭 Décisions arrêtées

<!-- Une ligne par décision sortie de la session d'affinage, dédoublonnée. Une recommandation que
     l'utilisateur n'a jamais acceptée n'est pas une décision. Vocabulaire de LEXIQUE.md, jamais en
     contradiction avec un ADR acté. -->

1. ⟨décision⟩
2. ⟨décision⟩
3. ⟨décision⟩

## 🧪 Seam de test

<!-- Le(s) point(s) d'accroche des tests, validés dans /cadrage §2 : le seam le plus haut possible,
     le moins nombreux possible — la cible est un seul seam. -->

- **Seam retenu** : ⟨seam⟩ — ⟨pourquoi celui-ci plutôt qu'un plus bas dans la pile⟩

## 🚫 Hors périmètre

<!-- Ce qui a été explicitement écarté ; la raison quand elle évite une re-discussion plus tard. -->

- ⟨point écarté⟩ — ⟨raison⟩

## 📚 Références

<!-- Liens relatifs depuis la racine du dépôt. -->

- Spec : `docs/plans/⟨slug⟩/spec.md`
- Affinage : `docs/plans/⟨slug⟩/affinage.md` *(mode `--tech` : lister les ADR `docs/adr/NNNN-…`)*
- Glossaire : `LEXIQUE.md` *(supprimer la ligne si absent)*

<details>
<summary>📎 Affinage — session complète</summary>

<!-- La session d'affinage collée verbatim : documentée, sans alourdir la lecture.
     Mode `--tech` avec une simple log d'index : supprimer ce bloc et lier les ADR plus haut. -->

⟨contenu intégral de docs/plans/⟨slug⟩/affinage.md⟩

</details>
