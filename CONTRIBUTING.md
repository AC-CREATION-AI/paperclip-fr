# Contribuer à paperclip-fr

Contributions humaines et assistées par IA bienvenues.

## Règles

1. Une PR, un sujet. Branches `feat/…`, `fix/…`, `translation/…`.
2. Tout changement de script ou de patch a un test dans `tests/` (rouge puis vert).
3. Chaque PR met à jour `README.md` si le comportement visible change, et ajoute un fragment `changelog.d/` (voir son README).
4. Commits au format Conventional Commits.
5. Aucun secret, chemin interne, adresse IP, nom de client ou donnée réelle dans le dépôt, les captures ou les journaux. `bash scripts/check-anti-leak.sh` et gitleaks tournent en CI.
6. Une revue (mainteneur) est requise avant fusion ; la CI doit être verte.

## Vérifications locales

```bash
bash tests/test-install.sh
bash scripts/check-anti-leak.sh
python3 -m json.tool catalog/fr.json > /dev/null
```

## Nouvelle version de Paperclip

```bash
git clone https://github.com/paperclipai/paperclip.git /tmp/up
bash scripts/refresh-patch.sh /tmp/up <tag-ou-ref> <nom>
```

En cas de conflit, le script s'arrête : résolvez à la main dans le clone, `git add ui doc`, puis `git diff --cached --binary > patches/<nom>.patch`. Testez avec `install.sh --dry-run` puis un cycle `install.sh` / `uninstall.sh`.

## Sécurité

Pas d'issue publique pour une vulnérabilité : utilisez les Security Advisories privés de GitHub.
