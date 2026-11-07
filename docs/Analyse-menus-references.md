# Analyse des menus de Break and Steal an Egg (7 nov.)

Sources : l'enregistrement d'écran de Chouaib (35 s, 1918×1078, 30 images/s, version française du jeu),
découpé image par image, plus une vidéo YouTube récente (« Starting OVER as NOOB… », mise à jour Crystal Egg)
et les 5 captures de `references/*.webp`. Les images utiles sont dans `references/bse-video/`
(écrans en pleine résolution, et planches `anim_*.jpg` où chaque case vaut 1/15 s).

## 1. Le HUD

| Élément | Ce qu'on voit | Image |
| --- | --- | --- |
| Boutons de menu (gauche) | **Petits** rectangles plats (≈ 200×55 px à 1080p), dégradé vif + picots, icône blanche à gauche, texte blanc à contour noir. Boutique vert, Index cyan. Pastille rouge ronde à contour blanc avec un **chiffre** (« 7 ») au lieu d'un « ! ». Dessous, un interrupteur « Mode lent » | `hud_left.jpg` |
| Monnaies (bas gauche) | Deux lignes de gros chiffres en **italique**, contour sombre : vitesse en bleu (icône chaussure + petit « + » jaune pour en acheter), argent en vert (icône billets). Pas de cadre derrière | `hud_money.jpg` |
| Boosts actifs (bas droite) | Rangée d'icônes **sans cadre** : l'image, « x2 » / « x4 » vert en exposant, le temps restant dessous (« 2m 33s ») | `equipped.jpg` |
| Boutons ronds (droite) | Carrés arrondis rouge (œuf) et orange (patte), avec deux petits compteurs ronds (rouge « 1 », vert « 1 ») accrochés au bord | `index.jpg` |
| Bandeau du haut | Phrase d'info centrée, sans fond : « Vous gagnez $72M/jour hors ligne ! » + emoji | — |
| Panneau latéral | Les créatures équipées (« 5/9 Actifs », bouton vert « +1 Équipement [$75M] ») et les œufs en croissance (« Ouvrir ») **glissent depuis le bord droit** en 0,1 s ; petit bouton rouge « > » pour les replier ; « Équiper le mieux » vert dessous | `equipped.jpg`, `anim_pets_open.jpg` |
| Minuteur | Bas droite, icône + « dans 31 s » | — |

## 2. Les fenêtres (règles communes)

- **Bandeau de titre** uni et vif (vert boutique, cyan index, orange atelier, magenta index de la v. précédente), titre blanc à gros contour **à gauche**, trois bandes de reflet en diagonale, motif de picots. Croix : carré rouge foncé, X blanc, dans le bandeau à droite.
- **Corps** gris anthracite à picots, contour noir épais, coins peu arrondis.
- **Navigation par catégories à l'extérieur de la fenêtre**, collée à droite : grandes icônes **sans bouton derrière** (étiquette de prix « % », étoile, chaussure, billets) avec leur nom dessous. La catégorie affichée a son nom en couleur. Clic = la liste défile jusqu'à la section. Les onglets de l'Index (« Monde », « Limité ») sont aussi dehors, à droite.
- **Titres de section** centrés « -- PASSES -- », chacun de la couleur de sa section (jaune, magenta, cyan, vert).
- Tout le reste du jeu est **flouté** quand une fenêtre est ouverte, sans assombrir.

### Animations mesurées (30 images/s)
| Moment | Ce qui se passe | Durée |
| --- | --- | --- |
| Ouverture | La fenêtre apparaît **presque d'un coup** à ~95 % puis se pose à 100 % (léger rebond) ; le flou monte en même temps | 2 à 4 images (≈ 0,1 s) |
| Icônes de navigation | Elles **apparaissent l'une après l'autre** (≈ 0,1 s d'écart) après la fenêtre | ≈ 0,4 s en tout |
| Contenu | Les illustrations arrivent juste après le cadre (les prix et images se chargent) | ≈ 0,3 s |
| Fermeture | Le X s'enfonce, puis la fenêtre **rétrécit** (100 → 75 %) en glissant un peu vers le bas, puis disparaît ; le flou retombe | ≈ 0,2 s |
| Survol d'une carte | La carte **s'éclaircit** (voile blanc) | instantané |
| Clic sur une catégorie | Défilement doux jusqu'à la section | ≈ 0,3 s |
| « Réclamer tout » | La barre bleue se vide, devient « Débloqué : 7/112 », la pastille du bouton Index disparaît, les récompenses **sautent sous la fenêtre** en petites tuiles, l'argent défile vers sa nouvelle valeur | ≈ 1 s |

## 3. La boutique (Robux)

Ordre : **En vedette → Passes → Étoiles de monture → Vitesse → Argent**.

| Section | Détails |
| --- | --- |
| En vedette | Grande carte avec une **illustration de fond peinte** (cristaux violets), « Nouveau ! » dans un cadre arc-en-ciel, titre doré « CRYSTAL EGG », « Temps limité ! », compte à rebours en haut à droite (« 13d 23h 45m 58s »). Les créatures possibles avec leur **pourcentage** ; la plus rare dans un cadre arc-en-ciel avec « DIVINE! ». 4 prix (50, 10, 3, 1 œuf) : le plus gros est un bouton **arc-en-ciel** avec l'ancien prix barré en rouge, les autres verts ; chacun a son bouton cadeau violet. Survol d'une créature = info-bulle noire (nom + rareté) |
| Passes | 2 par ligne, **cartes larges** : fond en dégradé à la couleur du passe (arc-en-ciel, or), grosse icône ronde à gauche, nom en haut, phrase au centre, cadeau violet + prix vert en bas |
| Étoiles de monture | 3 cartes violettes avec un **soleil de rayons** derrière l'objet, nom en majuscules sous l'objet, prix vert. Ruban jaune penché « Meilleure valeur ! » qui dépasse en haut à droite. « Stock hebdomadaire : 5/5 » et « Réapprovisionnement dans 6 jours 23 heures » en rouge |
| Vitesse | Bandeau large « DOUBLE votre VITESSE » avec **« x1 ▶ x2 »** en énormes chiffres (x2 doré), puis 3 cartes (+50M, +500M, +1B de vitesse) et un encart blanc « AMÉLIORER Tapis roulant ! » (mot en arc-en-ciel) |
| Argent | Cartes vertes avec **soleil de rayons**, billets → liasses → sac → coffre-fort. **3 petites cartes puis 2 grandes** sur la seconde ligne |

## 4. L'Index

Bandeau cyan « Index des animaux de compagnie ». Pour chaque zone : image du biome en colonne à gauche avec son nom, grille 4×2 de tuiles **sur fond de la couleur de la rareté** (gris, rose, vert, bleu, violet, jaune) avec le nom en haut, silhouettes noires « ??? » pour les inconnues, contour blanc sur la tuile choisie ; barre de progression verte « 2/8 » avec l'objet récompense posé au bout. À droite : la fiche (silhouette, nom, rareté, « ??? » vert) et l'encadré vert sombre « Récompenses : » (tuiles $100, +420) avec un bouton « RÉCLAMER ! » gris tant que rien n'est prêt. En bas : barre bleue « RÉCLAMER TOUT (7) ! » avec une icône de livre qui déborde, qui devient « Débloqué : 7/112 ».

## 5. Ce qu'on a déjà, et ce qu'on prend

Déjà fait chez nous : bandeau en dégradé à reflets et picots, croix rouge, flou, cartes en dégradé, rayons et halos, ruban « BEST VALUE! », prix lus sur Roblox, Starter Pack, menu de catégories avec défilement, Index par anneau avec silhouettes et récompense.

À reprendre (fait le 7 nov., voir le commit) :
1. **Navigation à l'extérieur** de la fenêtre, à droite : icônes flottantes + nom, nom coloré pour la section affichée, arrivée en cascade. La liste prend toute la largeur.
2. **Ouverture éclair** (≈ 0,12 s avec rebond) et **fermeture en rétrécissant** (≈ 0,18 s).
3. **Soleil de rayons** derrière l'illustration de chaque carte (lent, pas seulement la vedette).
4. **Survol = la carte s'éclaircit** (en plus du léger grossissement).
5. **Passes en cartes larges**, 2 par ligne, icône à gauche.
6. **Cash en 3 + 2**, les deux plus gros paquets plus grands ; le meilleur avec un **prix arc-en-ciel**.
7. Titres de section « -- X -- ».

Pas repris, volontairement :
- **Œufs vendus contre des Robux** (et leurs pourcentages) : interdit chez nous (`docs/Interfaces.md`, décisions du 6 nov.).
- **Ancien prix barré** : Roblox demande de ne pas calculer de réduction à partir d'un prix supposé (`docs/Boutique.md`).
- **Bouton cadeau** : il faut d'abord un vrai système d'achat pour un ami (choix du joueur, produit cadeau côté serveur). À faire plus tard.
- Stock hebdomadaire, Vitesse, tapis roulant : mécaniques propres à leur jeu.

Idées pour la suite : bandeau « x1 ▶ x2 » pour les passes multiplicateurs, « Réclamer tout » dans l'Index,
boosts actifs sans cadre en bas à droite, panneau des créatures équipées qui glisse depuis la droite,
message « Vous gagnez … hors ligne » si on ajoute des gains hors ligne.
