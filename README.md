# Crack a Space Egg

Jeu Roblox : on saute d'astéroïde en astéroïde, on les fore pour récupérer des œufs de l'espace (des œufs de roche), on les ramène à sa base et on les casse : dedans, des éclats de cristal et parfois une créature qui éclot. Sortie visée : vendredi 11 décembre 2026.

- Toutes les mécaniques décidées : [`docs/Mecaniques.md`](docs/Mecaniques.md)
- Descriptif v2 d'origine : https://claude.ai/artifact/WWrBdwE984G5YZDFRjAibu
- Tableau de production : https://claude.ai/artifact/81ksryaWTYWxuPQ6GoGvHE

## Méthode de travail (depuis le 4 nov. 2026)

**Studio est la source de vérité**, pour le code comme pour l'art, et tout se fait avec **Ropilot**.

1. Ouvrir la place dans Studio, puis cliquer sur **Connect** dans le plugin Ropilot.
2. **Ne pas connecter le plugin Rojo** : il réécrirait les scripts de Studio.
3. Les scripts s'écrivent dans `src/` puis s'envoient dans Studio avec `tools/push-to-studio.lua` (lancé par `ropilot_edit_ctx_run_command`, avec `python -m http.server 34873 --bind 127.0.0.1` dans `src/`). L'envoi `ropilot_sourcecontrol_commitscript` échoue pour l'instant (« source was not injected »).
4. En fin de session : redemander chaque script à Ropilot (`ropilot_sourcecontrol_requestscript`, après avoir supprimé sa copie locale), lancer `bash tools/export-scripts.sh`, puis `selene src`, commit et push.
5. Pour que la sauvegarde marche dans Studio : Game Settings > Security > *Enable Studio Access to API Services*.

`src/` n'est qu'une **copie** des scripts pour l'historique Git : ne pas la modifier directement.

## Organisation

Le vaisseau (`Workspace.Ship` : 7 bases, boutique, ateliers, quai) est construit dans Studio avec Ropilot (prompts dans `docs/prompts/`). Le code s'appuie sur les noms de ses pièces : `CrackPoint`, `Spawn`, `OwnerName`, `DockEnd`, `ShopPoint`, `Point`…


| Dossier | Contenu |
| --- | --- |
| `src/shared` | `Config` (toutes les valeurs d'équilibrage), `Format` (nombres affichés) |
| `src/server` | `Main` (démarrage), `WorldBuilder` (prépare `Workspace.Ship`, construit le couloir et les anneaux), `Bases` (une base par joueur), `BeltService` (tapis d'astéroïdes), `DataService` (sauvegarde), `GameService` (forage, soute, casse, améliorations) |
| `src/client` | `Belt` (mouvement fluide des astéroïdes), `Controls` (jetpack, foreuse), `Interface` (HUD, boutique, révélation) |
| `tools` | `push-to-studio.lua` (envoie src/ dans Studio par HTTP), `export-scripts.sh` (recopie Studio dans src/) |

Les RemoteEvents sont déclarés dans `default.project.json` (`ReplicatedStorage.Remotes`).

## Règles

- Le serveur décide de tout ce qui rapporte (forage, tirages, prix). Le client n'envoie que des intentions.
- Toute valeur d'équilibrage va dans `src/shared/Config.lua`, nulle part ailleurs.
- Code et commentaires en français, textes affichés en anglais.
- Vérifier avant de pousser : `bash tools/export-scripts.sh`, puis `selene src`.
