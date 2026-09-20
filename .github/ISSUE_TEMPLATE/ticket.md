---
name: "Ticket"
about: "Tranche verticale fine — complète de bout en bout, demoable seule, un contexte frais suffit"
title: "⟨NN⟩ : ⟨titre⟩"
labels: ["Ticket", "prêt"]
---

<!--
  Modèle installé par /reglage — suite dev-workflow française.
  Écrit par : /decoupage §4, un fichier par ticket, publié en ordre de pile (les bloquants d'abord).
  Contrats : la PREMIÈRE LIGNE du corps reste la première ligne — /au-boulot la lit. Ticket racine
  de la pile : la remplacer par « Partie de l'épic #⟨epic⟩. Aucun bloquant — peut démarrer. ».
  Jamais de chemins de fichiers ni de bouts de code ; seule exception, un extrait qui encode une
  décision mieux que la prose (machine à états, schéma, forme de type), inline, avec une note
  d'origine d'une ligne. Vocabulaire de LEXIQUE.md.
  À ne pas faire : cocher une case, fermer ou rouvrir un ticket — la fermeture vient des PR
  (`Closes #⟨ticket⟩`) sur fusion, et la progression de l'épic se met à jour seule.
-->

Partie de l'épic #⟨epic⟩. Bloqué par #⟨ref1⟩, #⟨ref2⟩.

| | |
|---|---|
| 🧮 Position dans la pile | `⟨NN⟩` *(paires issues d'un split : `03a` / `03b`)* |
| 🌿 Branche attendue | `epic-⟨n⟩/⟨NN⟩-⟨slug⟩` |
| 📦 Profil | `⟨tracer bullet⟩` \| `[préfacto]` \| `[refactor]` — expand / migrate / contract |

## 🎯 À construire

<!-- LE comportement de bout en bout que ce ticket fait marcher, vu par l'utilisateur. Jamais une
     liste de couches à implémenter (le schéma, puis l'API, puis l'UI) : une tranche verticale,
     demoable ou vérifiable seule, taillée pour un contexte frais. -->

⟨ce que le système sait faire à la fin de ce ticket, et comment on le voit⟩

## ✅ Critères d'acceptation

<!-- Chacun vérifiable de l'extérieur, sans lire le diff. Les cases restent décochées. -->

- [ ] ⟨critère vérifiable — chemin nominal⟩
- [ ] ⟨critère vérifiable — cas limite⟩
- [ ] ⟨critère vérifiable — chemin d'erreur⟩

## 🔗 Bloqué par

<!-- Refs explicites, dans l'ordre de la pile. Ce que chaque bloquant doit avoir livré, en quelques
     mots : c'est ce qui justifie l'arête. -->

- #⟨ref1⟩ — ⟨ce que ce bloquant doit avoir livré avant⟩
- ⟨ou `Aucun`⟩

## 🚧 Ce que ce ticket ne fait pas

<!-- Facultatif mais utile : coupe-faim pour le Worker et le relecteur — supprimer la section si
     rien à dire. Obligatoire pour un ticket [préfacto] ou une étape expand / migrate / contract
     qui ne livre pas un comportement utilisable seul : le dire explicitement. -->

- ⟨tentation voisine délibérément laissée de côté⟩ — ⟨quel ticket la porte, si connu⟩

## 📚 Références

- Épic : #⟨epic⟩
- Spec : `docs/plans/⟨slug⟩/spec.md` — `## Décisions d'implémentation`, `## Décisions de test`
- Glossaire : `LEXIQUE.md` · ADR : `docs/adr/⟨NNNN⟩-⟨slug⟩.md` *(supprimer ce qui est sans objet)*
