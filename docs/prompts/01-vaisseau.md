# Prompts Ropilot : le vaisseau-base

À coller **un par un** dans Ropilot, dans l'ordre. Vérifier le résultat (capture) avant de passer au suivant.

**Plan retenu** (vue du dessus) : un pont en forme de **D**.
- La partie **courbe** est vers l'arrière, côté planète. Les **7 bases** carrées sont alignées le long de cette courbe.
- La partie **droite** est vers l'avant, côté anneaux. On y trouve **la boutique** à gauche, **les ateliers** à droite et **le quai** au milieu, d'où part le couloir.
- Entre les deux, une **place centrale** dégagée : depuis sa base, chaque joueur voit les autres bases et ce qu'elles contiennent, comme dans les jeux du type Steal an Egg.

Repère : l'origine (0, 0, 0) est le centre du D. Le dessus du pont est à **y = 0**. L'avant est vers **+Z**.

---

## Prompt 1 : la coque et le pont

```
Construis dans Workspace un Model nommé "Ship" : le vaisseau-base d'un jeu spatial, style Star Wars (vaisseau impérial / rebelle : coque grise en plaques, lignes de panneaux, détails mécaniques). Ne touche à aucun script, ni à Workspace.World, ni à ReplicatedStorage.RopilotSandbox, ni à Workspace.RopilotTestArea.

Forme vue du dessus : un "D".
- Demi-disque de rayon 160 studs centré sur (0, 0, 0), la partie courbe vers -Z.
- Plus un rectangle de x = -160 à +160 et de z = 0 à z = +40, qui ferme le D par un bord droit à z = +40.
- Le dessus du pont (sol où marchent les joueurs) est exactement à y = 0, plat et praticable partout.

Le pont :
- Sol en plaques de métal (Metal / DiamondPlate), gris clair et gris moyen, avec des lignes de panneaux et quelques bandes lumineuses bleues (Neon) qui guident vers le quai à l'avant.
- Un rebord tout autour (hauteur 2 studs) pour ne pas tomber, sauf au quai.
- Au centre (0, 0, -40) une place dégagée : un grand emblème au sol (cercle lumineux avec des anneaux autour d'une planète), sans obstacle haut.

La coque sous le pont :
- Épaisseur visible d'au moins 25 studs sous le pont, avec des étages en gradins, des plaques, des tuyaux, des antennes, des hublots éclairés.
- À l'arrière (côté courbe, vers -Z) : 3 gros réacteurs avec une lueur bleue (Neon + PointLight).
- Derrière la base centrale, à l'arrière : une tour de commandement façon Star Destroyer (pont de commandement en hauteur avec vitres éclairées), sans gêner la vue entre les bases.

Bulle de pression : une demi-sphère (dôme) qui couvre tout le pont, rayon 190, matériau ForceField, couleur bleu clair, Transparency 0.7, CanCollide false, CanQuery false, CanTouch false. Nomme-la "Bubble".

Règles techniques :
- Tout Anchored. Les petits détails : CanCollide false, CanQuery false.
- Pas plus de 2 500 pièces pour tout le vaisseau (il doit tourner sur téléphone).
- Organise en sous-dossiers ou sous-modèles : "Hull", "Deck", "Engines", "Tower", "Bubble". Laisse vides pour l'instant les emplacements des bases, de la boutique et des ateliers (prompts suivants).
- Fais une capture vue du dessus et une vue de 3/4 arrière à la fin.
```

---

## Prompt 2 : une base de joueur (modèle de référence)

```
Dans Workspace.Ship, crée un dossier "Bases" et construis dedans un Model "Base4" : une base de joueur carrée de 40 x 40 studs, centrée sur (0, 0, -130), orientée pour que son côté ouvert regarde le centre (0, 0, 0) (son avant pointe vers +Z).

La base doit être ouverte et lisible depuis la place centrale, comme les bases des jeux type Steal an Egg : on voit tout ce qu'il y a dedans depuis les autres bases.
- Sol légèrement surélevé (0,5 stud) avec un liseré lumineux de couleur (Neon), qui changera par joueur.
- Murets bas (hauteur 3 studs, verre + cadre métal) sur les côtés et à l'arrière. AUCUN mur ni toit à l'avant : l'avant est entièrement ouvert vers la place.
- À l'arrière, un grand panneau d'affichage face à la place (pour le nom du joueur), avec une SurfaceGui et un TextLabel nommé "OwnerName" (texte "FREE BASE", gros, lisible de loin).

Équipements (style sci-fi, propres, lumineux) :
- Arrière gauche : la machine à casser les œufs (presse hydraulique sci-fi, environ 8 x 9 x 8). Mets dedans une Part invisible "CrackPoint" (1x1x1, Transparency 1, CanCollide false) à hauteur de taille, devant la machine.
- Arrière droite : le caisson de pression (cylindre vitré de 7 de diamètre et 10 de haut, avec une porte vers l'avant et une lumière bleue intérieure). Part invisible "ChamberPoint" au centre du caisson, au niveau du sol.
- Côté gauche : la vitrine à reliques, 4 socles avec cloche de verre, alignés le long du muret. Dans chaque socle une Part invisible "RelicSlot1" à "RelicSlot4" posée sur le socle.
- Le centre de la base reste libre : c'est l'enclos où les créatures se promènent. Mets-y quelques petits rochers et cristaux décoratifs sur les bords, et une Part invisible "CreatureArea" (environ 24 x 1 x 18, Transparency 1, CanCollide false, CanQuery false) qui couvre cette zone au sol.
- Devant, au centre : un SpawnLocation nommé "Spawn" (6 x 0,4 x 6, Neutral true, Duration 0), dans le style du sol.
- Une Part invisible "GuardianPoint" près de la machine à casser (place du gardien).
- Pose le PrimaryPart du Model sur le sol de la base, nommé "Floor".

Règles : tout Anchored, pas de script, moins de 250 pièces pour la base. Capture de face et de 3/4 à la fin.
```

---

## Prompt 3 : les 7 bases

```
Duplique Workspace.Ship.Bases.Base4 pour avoir 7 bases au total, nommées Base1 à Base7, posées le long de la courbe du vaisseau. Chaque base garde exactement le même contenu et les mêmes noms de pièces. Place chaque centre de base au sol (y = 0) et oriente-la pour que son côté ouvert regarde le centre (0, 0, 0) (CFrame.lookAt(centre, Vector3.new(0, 0, 0)) appliqué au Floor) :

Base1 : (-122, 0, -44)
Base2 : (-95, 0, -89)
Base3 : (-51, 0, -119)
Base4 : (0, 0, -130)
Base5 : (51, 0, -119)
Base6 : (95, 0, -89)
Base7 : (122, 0, -44)

Ajoute sur chaque base, sur le liseré lumineux, une couleur différente : bleu, vert, orange, violet, rouge, jaune, cyan (Base1 à Base7).
Vérifie que les bases ne se chevauchent pas (environ 5 studs entre deux coins voisins) et que le pont est bien sous chacune. Capture vue du dessus à la fin.
```

---

## Prompt 4 : la boutique, les ateliers et le quai

```
Le vaisseau est fini sauf l'avant. Sur le bord droit avant de Workspace.Ship (entre z = +5 et z = +38), en face des bases, complète ce qui manque. Ne touche pas aux bases ni à la coque.

1. Le quai existe déjà (Workspace.Ship.Deck.Dock, avec son portique). Garde-le tel quel et ajoute seulement dedans une Part invisible "DockEnd" (1x1x1, Transparency 1, CanCollide false, CanQuery false, Anchored) exactement à (0, 0, 40) : c'est là que le couloir commence.

2. Dans le dossier existant Workspace.Ship.Shop, construis la boutique, à gauche, de x = -150 à x = -60 : une échoppe sci-fi ouverte vers les bases (vers -Z), comptoir, étagères avec des potions lumineuses et des caisses, grand panneau "SHOP" en néon, lumière chaude. Ajoute dans Shop une Part invisible "ShopPoint" devant le comptoir.

3. Dans le dossier existant Workspace.Ship.Workshops, à droite, de x = +60 à x = +150 : une rangée de 5 ateliers spatiaux côte à côte, ouverts vers les bases, chacun un Model avec un comptoir, une machine différente et un panneau néon :
   - "DrillWorkshop" (panneau "DRILL", foreuses et mèches)
   - "CargoWorkshop" (panneau "CARGO", caisses et soutes)
   - "SuitWorkshop" (panneau "SUIT", combinaison spatiale sur un mannequin)
   - "JetpackWorkshop" (panneau "JETPACK", jetpack et flamme bleue)
   - "ScannerWorkshop" (panneau "SCANNER", écran radar holographique)
   Dans chaque atelier, une Part invisible "Point" devant le comptoir.

Style cohérent avec le reste du vaisseau (Star Wars, métal, néons). Rien de haut (moins de 14 studs) qui cache la vue entre les bases et l'avant. Le passage vers le quai reste libre.
Budget : 450 pièces maximum pour cette étape (le vaisseau en a déjà 2 490), et 6 lumières maximum (Shop + ateliers). Les petits détails en CanCollide false. Tout Anchored, pas de script.
À la fin : vérifie les noms (Ship.Deck.Dock.DockEnd, Ship.Shop.ShopPoint, Ship.Workshops.<Nom>Workshop.Point), donne le total de pièces du vaisseau, et fais une capture depuis la place centrale vers l'avant.
```

---

## Prompt 5 : finition et contrôle

```
Passe de finition sur Workspace.Ship :
- Ajoute des lumières (PointLight / SpotLight) douces sur la place centrale, les bases et la boutique, sans en mettre plus de 40 au total.
- Ajoute des petits détails Star Wars sur la coque visible depuis le pont (antennes, conduits, feux clignotants rouges sur les bords), en CanCollide false.
- Vérifie : tout est Anchored, aucune pièce ne flotte, le sol du pont est continu et praticable de chaque base jusqu'au quai, aucune pièce invisible ne bloque le passage.
- Vérifie les noms : Ship.Bases.Base1 à Base7 contiennent chacune Floor, Spawn, CrackPoint, ChamberPoint, RelicSlot1 à RelicSlot4, CreatureArea, GuardianPoint et un TextLabel "OwnerName". Ship.Dock.DockEnd, Ship.Shop.ShopPoint, et Ship.Workshops.<Nom>Workshop.Point existent.
- Donne-moi le nombre total de pièces du vaisseau.
Captures : vue du dessus, vue depuis une base vers la place, vue de 3/4 arrière.
```
