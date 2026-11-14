# Fragments de changelog

Chaque PR ajoute un fichier `changelog.d/<identifiant>.<catégorie>.md` contenant une ligne.

Catégories : `added`, `changed`, `fixed`, `removed`, `translation`.

Exemple : `changelog.d/pr-12.translation.md` → `Corrige la traduction de « Blocked » dans la liste des tâches.`

À la release, les fragments sont regroupés dans `CHANGELOG.md` puis supprimés.
