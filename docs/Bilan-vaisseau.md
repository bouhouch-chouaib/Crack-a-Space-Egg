# Bilan du vaisseau au regard de la direction artistique (6 nov. 2026)

Chaque élément déjà construit a été passé en revue : comptage des pièces, des matériaux, de la part de néon et des couleurs, puis captures dans Studio. On le juge contre `docs/Direction-artistique.md`.

Verdicts : ✅ garder · 🔧 retoucher · 🔁 refaire.

## Vue d'ensemble

Le vaisseau a la bonne **organisation** (5 bases en arc, place libre, services sur la ligne avant, quai). Mais le **rendu** est encore celui d'un prototype :
- des cases pastel au hasard, avec des picots partout ;
- du néon de toutes les couleurs ;
- des machines faites de blocs simples ;
- une silhouette de vaisseau plate.

Il manque aussi une palette commune : chaque morceau a ses couleurs (rouge, marine, beige, or, pastels).

## Élément par élément

| Élément | Constat | Verdict | À faire |
| --- | --- | --- | --- |
| **Sol du pont** (110 plaques) | Damier pastel au hasard (bleu, crème, jaune, menthe, lavande), plastique à picots, lignes bleues partout. C'est le plus gros défaut visible | 🔁 | Un sol propre : crème lisse, avec de grands chemins turquoise qui mènent des bases à la ligne avant, et une couleur par base sous chaque base |
| **Rebord** (96 pièces) | Néon arc-en-ciel (vert, jaune, rouge, bleu) sur 14 % de sa surface | 🔁 | Rambarde arrondie crème avec un seul liseré turquoise (couleur « sûr ») |
| **Coque, halo, quille** | Silhouette d'assiette plate. Rouge, marine et beige hors palette. Néon à 28-46 % | 🔁 | Nouvelle coque modélisée dans Blender : ronde, généreuse, crème et turquoise, lueurs douces seulement aux réacteurs |
| **Réacteurs** | Formes simples, 33 % de néon | 🔁 | À refaire avec la coque : gros réacteurs arrondis avec une lueur en couches (un effet, pas du néon plein) |
| **Tour de commandement** | Empilement de blocs (beige, marine, rouge) et 2 boules roses. Lisible, mais très « jouet en blocs » | 🔁 | Tour arrondie avec un dôme vitré, dans la palette, modélisée dans Blender |
| **Quai et portique LAUNCH** | Bonne place et bonne taille. Couleurs marine et rouge, bords « danger » rayés | 🔧 | Repeindre dans la palette, portique plus rond et plus cartoon, garder le panneau LAUNCH lisible |
| **Bases : sol** | Plastique à picots pastel | 🔁 | Sol lisse dans la couleur de la base, bord arrondi |
| **Bases : murets et vitres** | Corrects, ouverts vers la place | 🔧 | Arrondir et passer à la palette de la base |
| **Bases : panneau « FREE BASE »** | Panneau géant, texte minuscule, illisible de loin | 🔁 | Panneau plus petit, avec le nom du joueur en très gros (et plus tard son avatar), dans la couleur de la base |
| **Bases : machine à casser** | Cadre de blocs avec un toit jaune, ne ressemble à rien | 🔁 | Vraie machine cartoon (presse à œufs avec une cloche vitrée), modélisée dans Blender. C'est l'objet n° 1 du jeu |
| **Bases : caisson de pression** | Cylindre simple, 32 % de néon | 🔁 | Caisson arrondi, vitré, avec un hublot et une jauge, modélisé dans Blender |
| **Bases : vitrine à reliques** | Socles vitrés corrects, 14 % de néon | 🔧 | Moins de néon, socles plus ronds |
| **Bases : enclos des créatures** | 23 % de néon pastel, petits cubes éparpillés qui font « débris » | 🔧 | Retirer les cubes, bordure douce sans néon, quelques rochers et cristaux faits dans Blender |
| **Stands SHOP et SELL** | Faits sur mesure, dans le thème et la palette | ✅ | — |
| **Machine à fusion** | Faite sur mesure, cartoon. Noyau trop brillant (16 % de néon) | 🔧 | Baisser la lueur du noyau, ajouter un effet en couches plutôt que du néon plein |
| **Lumière** | Neutre, correcte. Le ciel choisi est sombre | 🔧 | Plus de lumière ambiante pour que le pont paraisse clair et joyeux |

## Ordre proposé

1. **Sol, rebord et palette commune** (dans Studio, rapide, gros effet).
2. **Le kit de base** (machine à casser, caisson, panneau, enclos) : modélisé une fois, copié dans les 5 bases avec leur couleur.
3. **La coque, les réacteurs et la tour** (Blender), pour une vraie silhouette de vaisseau cartoon.
4. **Le quai et le portique LAUNCH**.
5. **La lumière finale**, puis une capture à hauteur de joueur pour validation.

Chaque étape se termine par une capture à hauteur de joueur et ta validation.

## Reprise faite (6 nov. 2026)

| Étape | Fait |
| --- | --- |
| 1. Sol, rebord, palette | Damier pastel retiré ; sol crème uni, chemins turquoise de guidage (bases → place → quai, ligne avant) ; rebord crème à un seul liseré turquoise ; palette commune dans la direction artistique |
| Picots | Picots carrés Roblox sur toutes les pièces (`tools/apply-studs.lua`), sauf verre, néon et formes rondes |
| 2. Kit de base | Machine à casser (presse à œufs), caisson de pression (capsule à hublot), panneau du propriétaire réduit, modélisés dans Blender et posés dans les 5 bases à leur couleur ; enclos néon et cubes retirés |
| 3. Coque | Coque ronde avec hublots et bande turquoise, 2 réacteurs, tour à dôme vitré (Blender) ; lueurs des réacteurs et de lévitation en couches de particules |
| 4. Quai | Quai à la largeur du couloir (90 studs), rambardes, flèches au sol, portique LAUNCH ; rebord ouvert sur 90 studs |
| 5. Lumière | Lumière claire et saturée, bloom réservé au néon ; noyau de la fusion moins brûlé, avec un halo en couches |

Le vaisseau est passé de 1 983 à environ 650 pièces. Tout ce qui a été retiré est rangé dans `ServerStorage.RemovedFromShip`.
