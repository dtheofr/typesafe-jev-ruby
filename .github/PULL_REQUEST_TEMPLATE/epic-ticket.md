<!--
  🎫 PR DE TICKET — modèle installé par /reglage (suite dev-workflow française).
  À utiliser pour : un ticket de l'épic implémenté, empilé sur la branche du ticket précédent.
  Écrit par : /au-boulot §3.5. Base = la branche gelée du ticket précédent en ordre de pile
  (`epic-⟨n⟩/⟨NN-1⟩-…`) — sauf pour la racine de pile, dont la base est la branche de l'épic.
  Contrats : la PREMIÈRE LIGNE est `Closes #⟨ticket⟩`, ne pas la déplacer — sur fusion elle ferme
  le ticket et la progression des sub-issues de l'épic se met à jour seule.
  NE PAS décrire la pile : l'UI de GitHub montre déjà les PR empilées, bases et branches portent
  l'ordre. Pas de label ajouté par l'agent — `prêt` est une porte d'entrée, pas une sortie.
  Dans l'UI web : choisir « epic-ticket » dans le sélecteur de modèles.
-->

Closes #⟨ticket⟩
Partie de l'épic #⟨epic⟩

## 🔍 Ce que fait cette PR

<!-- Le comportement livré, pas la liste des fichiers touchés. Deux à cinq lignes. -->

⟨ce qui marche après fusion, vu par quelqu'un qui n'a pas lu le diff⟩

## ✅ Critères couverts

<!-- Reprendre UN PAR UN les critères d'acceptation du ticket, avec ce qui les prouve. C'est la
     grille de lecture du relecteur humain : rien de manquant, rien hors périmètre. -->

- ⟨critère du ticket⟩ → ⟨test ou manipulation qui le prouve⟩

## 👀 Comment vérifier

<!-- Ce qu'un humain peut faire pour voir le comportement : commande, écran, requête.
     Captures bienvenues dès qu'il y a de l'UI. -->

1. `⟨commande ou manipulation⟩`
2. ⟨ce qu'on doit constater⟩

## 🧪 Vérifications

<!-- Le port de sortie du Worker, coché honnêtement. Le seam est celui acté dans la spec, pas un
     inventé ici. -->

- **Seam de test** : `⟨seam⟩` — *cf. `## Décisions de test` de la spec*
- [ ] typecheck propre
- [ ] suite complète verte
- [ ] diff contenu dans le périmètre du ticket

## ⚠️ Écarts et arbitrages

<!-- Ce que le relecteur a signalé et qui n'a pas été corrigé : les `[NIT]` accumulés, et les
     `[BLOQUANT]` restés au-delà des 2 cycles de correction — pour que l'humain tranche en
     connaissance de cause. Écrire `aucun` si rien à signaler. -->

- ⟨signalement⟩ — ⟨pourquoi pas corrigé ici, et quel ticket le porte⟩

## 📚 Références

- Ticket : #⟨ticket⟩ · Épic : #⟨epic⟩
- Spec : `docs/plans/⟨slug⟩/spec.md`
- Branche : `⟨base⟩` ← `⟨head⟩`

<!-- Rappel d'ordre de fusion : la PR docs de l'épic d'abord, puis les PR de tickets de haut en bas,
     une à une. `delete-branch-on-merge` doit être ON — GitHub retargete les enfants quand la base
     fusionnée est supprimée. -->
