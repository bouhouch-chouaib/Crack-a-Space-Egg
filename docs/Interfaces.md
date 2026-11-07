# Crack a Space Egg : les interfaces prévues

Contenu de chaque écran, avant de passer à la création. Analyse détaillée des menus de Break and Steal an Egg (HUD, fenêtres, animations mesurées image par image, boutique, Index) : `docs/Analyse-menus-references.md`.

Le style suit le kit tiré des jeux d'œufs (captures du 6 nov.) :
- fenêtres à épais contour noir, bandeau de titre en dégradé avec reflets, fond sombre à picots ;
- grosse croix rouge, boutons de prix verts avec l'icône Robux, bouton cadeau violet ;
- cartes en dégradés vifs avec une illustration peinte, pastilles penchées.

Les textes affichés sont **en anglais**, et la traduction automatique de Roblox les met dans la langue du joueur.

Légende : ✅ décidé dans `docs/Mecaniques.md` · ❓ à trancher (voir la fin).

---

## 1. HUD (toujours à l'écran)

| Zone | Contenu |
| --- | --- |
| **En bas à gauche** | **Argent** en énorme ($, vert-or), avec le revenu par seconde des créatures de la base (« +$120/s ») et les gains qui s'envolent en « +$12.5K » |
| **À gauche, deux gros boutons seulement** | 🛒 **STORE** (Robux) et 📖 **INDEX** (décision du 6 nov., STORE depuis le 7 nov.). Pastille rouge « ! » quand il y a quelque chose à acheter ou à réclamer |
| **En haut à droite** | **Œuf porté** ✅ (7 nov.) : on n'en porte qu'un, donc pas de compteur. Emplacement discret « NO EGG – Drill an asteroid » ; quand on ramasse un œuf, il s'allume à la couleur de la rareté (« EPIC EGG! – Bring it home! »), avec rayons, halo et un éclat au ramassage. Les potions actives sont juste en dessous |
| **À droite, ronds** | Raccourcis : ⭐ Supernova (quand elle est disponible), 🛡️ boost actif (potion, avec son minuteur) |
| **Jauges (bord gauche)** | **Jetpack** (carburant, existe déjà), **Oxygène** : elle n'apparaît que hors du couloir et devient rouge et clignote en dessous de 25 % ✅. **Bruit** : seulement dans les anneaux 5 à 7, comme un œil qui s'ouvre ✅ |
| **En bas au centre** | **Pouvoir actif** de la créature équipée (Légendaire et plus), avec son temps de recharge en cercle ✅ |
| **Dans le monde** | Barre de PV et « 🥚 x5 » au-dessus de l'astéroïde visé, la maison « YOUR BASE », la bannière d'événement |
| **Téléphone** | Gros boutons ronds Jetpack et Forer en bas à droite |

Animations : l'argent défile quand il monte, les boutons se soulèvent au survol et s'écrasent quand on appuie, les pastilles « ! » pulsent, la soute pleine tremble.

## 2. Révélation de la casse (plein écran)

On la voit à la machine à casser de sa base.
1. L'œuf apparaît au centre et tremble de plus en plus. Ses veines brillent de la couleur de sa rareté.
2. La coque se fend, puis un éclair de lumière de la couleur de la rareté.
3. Le résultat apparaît :
   - **💰 de l'argent** (montant en grand) ;
   - **🐾 une créature** (carte avec nom, rareté, taille, poids, Shiny, pastille « NEW! » si c'est la première fois, et son pouvoir) ;
   - **🎁 un objet spécial** (potion, outil, skin).
4. Avec plusieurs œufs, les Communs passent vite, les rares prennent leur temps. Un **récapitulatif** en fin de casse montre tout ce qui est sorti et le total.

L'intensité dépend de la rareté ✅ : un Commun fait un petit « pop », un Cosmique assombrit l'écran, fait tourner des rayons et arrête le temps. Un bouton **Skip** permet de passer.

## 3. Upgrades : améliorations (section de la boutique, et stand SHOP du vaisseau)

Cinq cartes, une par amélioration ✅ :

| Carte | Montre |
| --- | --- |
| ⛏️ **Drill** | Niveau, puissance actuelle → suivante |
| 📦 **Cargo** | Places dans la soute |
| 🚀 **Jetpack** | Poussée, carburant, vitesse |
| 📡 **Scanner** | Chance, repère des astéroïdes rares |
| 🧑‍🚀 **Suit** | ❌ Retiré le 7 nov. : tous les anneaux sont ouverts (le jetpack décide jusqu'où on va) |

Chaque carte a une illustration, son niveau, « actuel → suivant », et un bouton **$ prix** : vert si on peut payer, gris sinon. Au niveau maximum, une pastille **MAX**.

## 4. Trading Post : vente (stand SELL)

- Une grille de **ses créatures** qui ne sont ni équipées ni verrouillées, chacune avec son prix en $ (selon la rareté, la taille et le stade).
- Des filtres par rareté, un bouton **Sell all duplicates** (garde le meilleur exemplaire de chaque espèce), et le total en grand.
- Une confirmation obligatoire à partir d'Épique (« Are you sure? »).

## 5. Fusion Machine (machine à fusion)

- **Trois emplacements** à remplir avec 3 créatures identiques, de la même espèce et du même stade ✅. Un bouton **Auto-fill** les remplit.
- L'**aperçu du résultat** : le stade suivant (bébé → adulte → ancien) ✅, avec un pouvoir doublé et une taille égale à la moyenne des trois.
- Un bouton **FUSE** lance l'animation : les 3 créatures tournent et se fondent dans le noyau, éclair, puis la nouvelle créature apparaît.

## 6. Creatures (inventaire)

- Une **grille de cartes** : portrait, cadre de la couleur de la rareté, étoiles du stade, taille, poids, Shiny, cadenas pour les favorites ✅. 100 places au maximum ✅.
- En haut, les **emplacements équipés** (3, ou 4 avec le passe ✅), avec un bouton **Equip best**.
- Panneau de détail : nom, rareté, **pouvoir passif** et **pouvoir actif** ✅, **revenu en base** ($/s), et les boutons **Equip** / **Send to base** / **Lock**.
- Tri par rareté, revenu ou nouveauté, et recherche.

## 7. Index (collection, comme dans Steal an Egg)

- À gauche, **un onglet par anneau** (7) ✅, avec l'image de l'anneau.
- Au centre, les **6 créatures de l'anneau**. Celles qu'on n'a pas encore trouvées sont des **silhouettes « ??? »** avec le fond de leur rareté.
- Une **barre de progression** de l'anneau (x/6) et le **total** (x/42).
- À droite, la créature sélectionnée (nom, rareté, chance de l'obtenir) et les **récompenses de l'anneau** : bonus de chance permanent et $ ✅, avec un bouton **Claim!**.
- Un onglet **Relics** : les reliques trouvées dans les épaves et leur petit bonus ✅.

## 8. Rewards (cadeaux et quêtes)

Trois onglets ✅ :
- **Daily** : un calendrier de 7 jours, le jour actuel en avant, **Claim**, puis un compte à rebours jusqu'au suivant.
- **Playtime** : 4 cadeaux (5, 15, 30 et 60 min) avec leur minuteur, prêts à réclamer quand ils brillent.
- **Quests** : 3 quêtes du jour avec une barre de progression et une récompense, et le temps avant la remise à zéro.

En bas : le champ **Codes**, et la récompense **Join the group** (+10 % de chance) ✅.

## 9. Boutiques : STORE (Robux) et atelier des foreuses ($)

✅ Refonte du 7 nov. (recherche dans `docs/Boutique.md`) : **deux fenêtres, deux monnaies, jamais mélangées**.

- **STORE** (bouton du HUD, Robux) : menu à gauche (STARTER, PASSES, CASH, BOOSTS) qui fait défiler jusqu'à la section. Starter Pack en vedette (rayons, « ONE TIME! », contenu en icônes, vrai compte à rebours de 3 jours depuis la première partie, un seul achat), passes avec « OWNED », 5 paquets d'argent (le dernier en or « BEST VALUE! »), potions avec leur temps restant. Tous les prix sont lus sur Roblox (`Prices.lua`), « … » pendant le chargement.
- **DRILL WORKSHOP** (stand Shop du vaisseau, $) : onglets **DRILLS** (liste, aperçu 3D qui tourne, puissance actuelle → suivante, achat en $ ou petit bouton Robux), **SKINS** (12 apparences de foreuse, voir Mecaniques.md) et **UPGRADES** (scanner).

Ancienne version (6 nov., remplacée) : une seule fenêtre qui défile.

1. **Featured** : l'offre du moment, avec un compte à rebours. **Jamais d'œufs contre des Robux** ✅.
2. **Upgrades** ($) : les 5 cartes Drill, Cargo, Jetpack, Scanner, Suit (contenu en §3). Le stand SHOP du vaisseau ouvre la boutique directement à cette section.
3. **Pets** : ses créatures, les emplacements équipés et le bouton Equip best (contenu en §6). La vente (§4) et la fusion (§5) restent aux machines du vaisseau.
4. **Rewards** : connexion quotidienne, cadeaux de temps de jeu, 3 quêtes du jour, codes, bonus du groupe (contenu en §8).
5. **Game Passes** ✅ : Cargo XL, Turbo Jetpack, Auto Crack, x2 Money, x2 Training, +1 Equipped Creature, VIP.
6. **Potions** ✅ (15 min) : x2 Luck, x2 Money, x2 Jetpack XP. (Meteor Shower retirée le 7 nov.)
7. **Money packs** ✅ : 5 paliers, du paquet de billets au coffre, jusqu'à de gros montants.
8. **Skins** ✅ : thèmes de base, couleurs de combinaison, traînées de jetpack.
9. **Free boost** ✅ : une potion x2 de 5 min contre une pub récompensée.

Les cartes ont une illustration sur un fond en dégradé, un bouton vert (Robux ou $) et un bouton cadeau violet pour les achats Robux, avec parfois une pastille « BEST SELLER! » ou « BEST VALUE! ».

## 10. Écrans de la base

| Écran | Contenu |
| --- | --- |
| **Pressure Chamber** (caisson) | Oxygène max actuel, vitesse d'entraînement, multiplicateur du caisson (×1 dans la base, jusqu'à ×20 dans les relais) ✅, bouton **Enter** / **Leave**, et le passe x2 Training à côté |
| **Guardian** (gardien) | Achat en $, puis son état : œufs en attente, œufs cassés pendant ton absence ✅ |
| **Relic Display** (vitrine) | Les 4 socles et les reliques qu'on y pose ✅ |

## 11. Supernova (renaissance)

- **Ce qu'on perd** : $, améliorations, oxygène.
- **Ce qu'on garde** : créatures, index, reliques.
- **Ce qu'on gagne** : +50 % de $ pour toujours, cumulable ✅.
- Le coût ou la condition, puis un gros bouton **SUPERNOVA** avec confirmation et une animation d'explosion d'étoile.

## 12. Messages et petits écrans

| Écran | Contenu |
| --- | --- |
| **Toasts** | « +3 eggs · best: Rare », « Cargo full! », « Not enough $ » (petites bulles qui glissent) |
| **Annonce serveur** | Bandeau en haut quand quelqu'un trouve un Mythique ou mieux ✅ |
| **Nouvel anneau** | Grand titre à l'entrée de l'anneau (« RING n », sans avertissement) ✅ ; « First egg from the … » au premier œuf ✅ |
| **Perte** | Flash rouge « You lost 5 eggs » (Vide, monstre) ✅ |
| **Première minute** | ✅ (7 nov.) Guide pour enfants : bulle de 3 à 5 mots en bas, flèche au sol, flèche qui rebondit, contour vert, flèche au bord de l'écran, main qui montre le geste, fête à chaque étape (voir Mecaniques.md §16). L'aide du bas se cache pendant le guide |
| **Réglages** | ❌ Retirés le 7 nov. (fenêtre musique / sons et roue dentée) |

---

## Décisions du 6 nov. 2026

1. **Money packs** : oui, comme sur la capture de Break and Steal an Egg (gros montants possibles). Jamais d'œufs ni de créatures contre des Robux.
2. **Free boost contre une pub récompensée** : oui.
3. **Gemmes** : non, une seule monnaie ($).
4. **Améliorations** : au stand SHOP du vaisseau **et** dans la boutique (section Upgrades).
5. **HUD** : seulement deux boutons, SHOP et INDEX. Upgrades, Pets et Rewards sont des sections de la boutique.

> Note technique (7 nov.) : les BillboardGui en `AlwaysOnTop = true` ne s'affichent pas dans ce jeu (barre de vie des roches, nombres de dégâts et maison « YOUR BASE » étaient invisibles). Tout est en `AlwaysOnTop = false`, placé assez haut pour ne pas être caché.
