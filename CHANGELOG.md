# Changelog

Format : une ligne par changement visible. Les changements en cours vivent dans `changelog.d/` (un fragment par PR, voir `changelog.d/README.md`) et sont regroupés ici à la release.

## [Non publié]

(voir `changelog.d/`)

## [0.1.0] - 2026-11-14

### Ajouté
- Surcouche de traduction française de l'interface (catalogue `catalog/fr.json`, 15 979 entrées), issue de la PR amont paperclipai/paperclip#18468.
- Patches pour la release amont `v2026.1106.0` et pour `master` (c1451814c).
- `install.sh` (idempotent, `--dry-run`, sauvegarde) et `uninstall.sh`.
- CI : tests des scripts, contrôle anti-fuite, gitleaks ; CI nocturne sur le dernier `master` et la dernière release amont.
