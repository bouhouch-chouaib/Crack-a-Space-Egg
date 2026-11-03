# Crack a Space Egg

Jeu Roblox : on saute d'astéroïde en astéroïde, on les fore pour récupérer des œufs de l'espace (des œufs de roche), on les ramène à sa base et on les casse : dedans, des éclats de cristal et parfois une créature qui éclot. Sortie visée : vendredi 11 décembre 2026.

- Fiche de game design (onglet « Descriptif complet (v2) ») : https://claude.ai/artifact/WWrBdwE984G5YZDFRjAibu
- Tableau de production : https://claude.ai/artifact/81ksryaWTYWxuPQ6GoGvHE

## Lancer le projet

1. Outils (une fois) : `aftman install` (Rojo 7.7.0, Selene, StyLua).
2. `rojo serve` dans ce dossier.
3. Dans Roblox Studio : plugin Rojo, **Connect** (localhost:34872), puis **Play**.
4. Pour que la sauvegarde marche dans Studio : Game Settings > Security > *Enable Studio Access to API Services*.

## Organisation

| Dossier | Contenu |
| --- | --- |
| `src/shared` | `Config` (toutes les valeurs d'équilibrage), `Format` (nombres affichés) |
| `src/server` | `Main` (démarrage), `WorldBuilder` (carte greybox générée par code), `DataService` (sauvegarde), `GameService` (forage, soute, casse, améliorations, anneaux) |
| `src/client` | `Controls` (jetpack, foreuse), `Interface` (HUD, boutique, révélation des géodes) |

Les RemoteEvents sont déclarés dans `default.project.json` (`ReplicatedStorage.Remotes`).

## Règles

- Le serveur décide de tout ce qui rapporte (forage, tirages, prix). Le client n'envoie que des intentions.
- Toute valeur d'équilibrage va dans `src/shared/Config.lua`, nulle part ailleurs.
- Code et commentaires en français, textes affichés en anglais.
- Vérifier avant de pousser : `rojo build -o test.rbxlx` puis `selene src`.
