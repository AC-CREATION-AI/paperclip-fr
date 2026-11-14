# paperclip-fr

**Français** · [English](#english)

Interface de [Paperclip](https://github.com/paperclipai/paperclip) en français, sous forme de surcouche versionnée : des patches à appliquer sur le code source de Paperclip, un catalogue de traduction séparé (`catalog/fr.json`, environ 16 000 entrées) et deux scripts, `install.sh` et `uninstall.sh`, idempotents.

> Statut : paquet communautaire, non officiel. Il reprend le travail de la PR amont [paperclipai/paperclip#18468](https://github.com/paperclipai/paperclip/pull/18468). Si cette PR est fusionnée, ce dépôt devient inutile et sera archivé.

## Ce que c'est

- L'anglais reste la langue par défaut et la référence. Le français est choisi par la langue du navigateur ou par le sélecteur de langue (page de connexion et menu du compte). Le choix est mémorisé dans le navigateur.
- La traduction se fait à la compilation de l'interface : les textes sont enveloppés dans `displayText("…")` et cherchés dans le catalogue. Une entrée absente ou invalide retombe sur l'anglais.
- Ne sont jamais traduits : le code, les éditeurs, le contenu markdown, les données utilisateur et les valeurs envoyées à l'API.
- Pourquoi pas un plugin ? Le SDK de plugins ne peut pas porter la langue de l'interface (i18next est initialisé par l'hôte, pas de point d'entrée « langue »). Conclusion de l'étude : surcouche.

Captures d'écran : [À COMPLÉTER : captures avant/après de l'interface en français, à produire sur une instance de test sans donnée réelle].

## Versions de Paperclip prises en charge

| Fichier dans `patches/` | Cible |
|---|---|
| `v2026.1106.0.patch` | release amont `v2026.1106.0` |
| `master-c1451814c.patch` | `master` amont au 14 novembre 2026 (canary 2026.1114) |

`install.sh` essaie les patches du plus récent au plus ancien et applique le premier qui s'adapte. Si aucun ne convient, il ne modifie rien et le dit.

## Installation

Prérequis : `git`, `bash`, et le code source de Paperclip (un clone git de la version visée).

```bash
git clone https://github.com/AC-CREATION-AI/paperclip-fr.git
cd paperclip-fr
./install.sh --dry-run /chemin/vers/paperclip     # vérifie sans rien écrire
./install.sh /chemin/vers/paperclip               # applique
cd /chemin/vers/paperclip && pnpm --filter @paperclipai/ui build
```

L'installation sauvegarde les fichiers modifiés dans `.paperclip-fr-backup/` et écrit `.paperclip-fr.json` (patch utilisé, empreinte du catalogue). Relancer `install.sh` ne change rien (« already applied »).

## Mise à jour

1. Mettez Paperclip à jour (nouveau tag ou `master`).
2. Si le patch précédent est encore appliqué et ne convient plus : `./uninstall.sh /chemin/vers/paperclip` avant la mise à jour, ou `git checkout -- .` sur les fichiers touchés.
3. Récupérez la dernière version de ce dépôt (`git pull`) puis relancez `./install.sh`.

Chaque nuit, la CI applique le paquet sur le dernier `master` et la dernière release amont. En cas d'échec, une issue est ouverte ici et le suivi interne est alerté.

## Désinstallation

```bash
./uninstall.sh /chemin/vers/paperclip
```

Inverse le patch, supprime le catalogue, le marqueur et la sauvegarde. Relançable sans risque.

## Contribuer

- Corrections de traduction : modifiez `catalog/fr.json` (clé = texte anglais, espaces réduits ; garder les mêmes `{{vN}}`, pas de balise HTML ni d'URL ajoutée). Une PR par sujet.
- Nouveau patch pour une version amont : `scripts/refresh-patch.sh <clone-paperclip> <tag-ou-ref> <nom>`.
- Chaque PR met à jour ce README et ajoute un fragment dans `changelog.d/` (voir `changelog.d/README.md`). Détails dans [CONTRIBUTING.md](CONTRIBUTING.md).
- Tests : `bash tests/test-install.sh` et `bash scripts/check-anti-leak.sh`.

## Ajouter une langue

1. Créez `catalog/<code>.json` (ex. `de.json`) avec les mêmes clés que `fr.json`.
2. Ajoutez le code dans `DISPLAY_LOCALES` du patch (fichier `ui/src/i18n/display-text.ts` amont) et un libellé dans le sélecteur.
3. Faites installer le catalogue par `install.sh` (copie vers `ui/src/i18n/display/<code>.json`).
4. Ouvrez une PR. Les langues autres que le français sont les bienvenues mais ne sont pas encore automatisées : [À COMPLÉTER : procédure validée après la première langue ajoutée].

## Licence

MIT, comme Paperclip. Voir [LICENSE](LICENSE). Les patches sont dérivés du code de Paperclip (MIT, © Paperclip AI).

---

## English

**paperclip-fr** is a French display layer for [Paperclip](https://github.com/paperclipai/paperclip), shipped as a versioned overlay: source patches, a separate translation catalog (`catalog/fr.json`, about 16,000 entries) and idempotent `install.sh` / `uninstall.sh` scripts. Unofficial community package, based on upstream PR [#18468](https://github.com/paperclipai/paperclip/pull/18468); it becomes obsolete if that PR is merged.

**What it does.** English stays the default. French is picked from the browser language or the language picker (sign-in page, account menu). Text is wrapped in `displayText("…")` at build time and looked up in the catalog; a missing entry falls back to English. Code, editors, markdown content, user data and API values are never translated. Why not a plugin: the plugin SDK has no hook for the UI language, so an overlay is the supported option.

Screenshots: [TO COMPLETE: before/after screenshots from a test instance with no real data].

**Install** (needs `git`, `bash`, a git clone of the Paperclip source):

```bash
git clone https://github.com/AC-CREATION-AI/paperclip-fr.git && cd paperclip-fr
./install.sh --dry-run /path/to/paperclip   # check only
./install.sh /path/to/paperclip             # apply
cd /path/to/paperclip && pnpm --filter @paperclipai/ui build
```

`install.sh` picks the newest patch that fits, backs up touched files in `.paperclip-fr-backup/`, and does nothing if the tree is already patched or if no patch fits.

**Update.** Update Paperclip, remove the old patch (`./uninstall.sh`) if it no longer fits, `git pull` this repo, run `./install.sh` again. A nightly CI job applies the package on upstream `master` and the latest release and opens an issue on failure.

**Uninstall.** `./uninstall.sh /path/to/paperclip` reverses the patch and removes the catalog, marker and backup.

**Contribute.** Fix translations in `catalog/fr.json` (key = English text, keep the same `{{vN}}` placeholders, no added HTML or URLs). New upstream version: `scripts/refresh-patch.sh`. Every PR updates this README and adds a `changelog.d/` fragment. See [CONTRIBUTING.md](CONTRIBUTING.md).

**Add a language.** Add `catalog/<code>.json`, register the code in `DISPLAY_LOCALES` and the picker, let `install.sh` copy it. [TO COMPLETE: validated procedure once a second language exists].

**License.** MIT, same as Paperclip.
