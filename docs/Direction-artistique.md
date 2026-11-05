# Crack a Space Egg : direction artistique

Ce document fixe les règles que **tout** élément du jeu doit respecter : modèle, texture, effet, interface ou placement sur la carte. Chaque prompt Ropilot et chaque script y renvoie. Rien n'est « fini » tant que la vérification de la section 9 n'est pas passée.

Choix du 5 nov. 2026 :
- **Style** : cartoon stylisé.
- **Ambiance** : entre « nébuleuse colorée » et « lumineux et joyeux ». On teste deux réglages côte à côte, puis on garde le meilleur (section 5).
- **Jeux de référence** : Break and Steal an Egg, Cut a Rock, Grow a Garden, Pet Simulator 99, Steal an Egg.

---

## 1. Intention

Un **jouet cosmique de luxe**. Tout a l'air doux, rond, coloré et précieux, comme une figurine. L'espace est **magique et accueillant**, jamais sombre ni froid. Les œufs et les créatures sont les stars : tout le reste les met en valeur.

## 2. Formes

- **Rondes et généreuses** : coins arrondis, chanfreins visibles, proportions un peu exagérées (gros boutons, grosses machines, rambardes épaisses).
- **Silhouettes lisibles de loin** : on reconnaît chaque objet à sa forme, même en petit sur un téléphone.
- **Peu de détails, mais gros** : 3 détails bien faits plutôt que 30 petits (pas de « greebles » éparpillés, tuyaux minuscules ou antennes partout).
- **Modèles faits dans Blender** (maillages lissés, biseautés, texturés) pour tout ce qui compte : vaisseau, machines, astéroïdes, créatures. Les pièces simples de Roblox servent seulement aux maquettes grises.

## 3. Couleurs

| Rôle | Couleurs | Règle |
| --- | --- | --- |
| Ciel et espace | dégradés bleu nuit doux → violet → rose, touches turquoise | jamais noir pur |
| Planète | corail, orange chaud, crème | contraste chaud avec le ciel froid |
| Vaisseau | blanc crème et gris très clair, avec des accents turquoise et orange doux | propre, « jouet » |
| Bases | une couleur vive par base, en grands aplats (sol, liseré, panneau) | chacun reconnaît la sienne |
| **Sûr** (couloir, relais, bulle) | **turquoise / cyan** | toujours le même sens |
| **Danger** (Vide, monstres, alerte) | **rouge / orange vif** | toujours le même sens |
| **Argent** ($) | **or / jaune** | toujours le même sens |
| **Raretés** | les 7 couleurs de `Config.Rarities` | réservées aux œufs, créatures et annonces |

Une couleur qui porte un sens (sûr, danger, argent, rareté) **ne sert jamais à décorer**.

## 4. Matériaux et textures

- **Textures peintes maison** (`SurfaceAppearance` ou textures des maillages) : dégradés doux, bords éclaircis, ombres peintes, petites usures stylisées. On les fabrique dans Blender ou on les génère, toujours dans le style cartoon.
- **Interdits comme matériau principal** : `DiamondPlate`, `CorrodedMetal`, `Slate` brut, `Foil`, `ForceField` brut. Ils font « prototype ». `SmoothPlastic` est accepté, toujours avec une couleur choisie dans la palette.
- **Néon : 5 % de l'écran au maximum**, et seulement pour une **information de jeu** : rareté, zone sûre, objet à utiliser, danger. Jamais pour « faire joli ».
- **Bulles et dômes** : une texture dédiée (reflet doux, bord lumineux), pas le `ForceField` par défaut.

## 5. Lumière et ambiance

On règle tout cela une seule fois, dans la place, avec deux réglages à comparer en capture.

- **Réglage A, « Nébuleuse lumineuse »** : ciel nébuleuse violet-rose saturé mais clair, exposition plutôt haute, planète chaude.
- **Réglage B, « Joyeux »** : ciel plus turquoise et pastel, lumière plus blanche, contrastes plus doux.

Commun aux deux :
- `Lighting.Technology = Future`, ombres douces.
- Ciel personnalisé (`Sky`), jamais celui de base.
- `Atmosphere` légère et colorée, pour donner de la profondeur aux anneaux lointains.
- `Bloom` discret : seuls le néon et les effets brillent.
- `ColorCorrection` : un peu plus de saturation, une teinte légèrement chaude.
- `SunRays` subtils.

## 6. Effets visuels (VFX)

- **Jamais une image fixe qu'on déplace, jamais un modèle 3D dur qui tourne seul.** Un effet se construit en **couches**, au moins 3 :
  - un **cœur** (le flash) ;
  - une **lueur** (halo doux) ;
  - des **éclats** (étincelles, éclats de roche, paillettes) ;
  - une **traîne ou une fumée** (retombée).
- **Textures animées** (planches de sprites jouées en flipbook) faites pour chaque effet, au lieu de textures uniques statiques.
- **Courbes** de taille, de transparence et de couleur sur toute la vie de chaque particule. Varier la vitesse, la rotation et la durée. Utiliser `LightEmission` pour ce qui brille.
- **Rythme** : anticipation (petit gonflement) → impact (flash, secousse de caméra légère) → retombée (éclats qui ralentissent, fumée qui se dissipe).
- **Mouvements en douceur** : apparitions avec un petit rebond, rien de linéaire ni de saccadé.
- **Intensité selon la rareté** : un œuf Commun fait un petit « pop », un Cosmique arrête le temps.
- **Moments clés** qui ont tous effet + son + retour à l'écran : coup de foreuse, œuf qui sort, astéroïde qui se brise, casse de l'œuf, éclosion, achat, amélioration, entrée et sortie de zone sûre.
- Chaque effet est vérifié **image par image** (capture d'effet Ropilot) avant d'être validé.

## 7. Carte et ergonomie (le joueur ne sait peut-être pas lire)

- **Tout se comprend sans texte** : icône + couleur + flèche + forme. Les mots ne font que compléter.
- **Une seule fonction par endroit**, et elle se reconnaît de loin : la boutique ressemble à une boutique, la vente à un comptoir de vente, la fusion à une machine.
- **Rien d'inutile** : chaque objet sur la carte sert au jeu ou guide le regard. On enlève le décor qui encombre ou cache.
- **Distances courtes** : de sa base à la boutique, à la vente, à la fusion ou au départ du couloir, **5 secondes de marche au maximum**.
- **Les astéroïdes forment des chemins jouables**, pas un semis au hasard : des groupes et des lignes où chaque saut est faisable avec le jetpack de départ. Le premier astéroïde est à portée de saut du bout du quai, et les plus rares sont un peu plus loin, mais toujours atteignables.
- **Guidage permanent** : une flèche ou une ligne lumineuse vers l'objectif du moment (sortir, forer, rentrer, casser).
- **Zones de clic larges** : boutons d'au moins 44 px, invites assez grandes et assez proches pour les doigts.
- **On vérifie toujours à hauteur de joueur**, en vue PC et en format téléphone, jamais seulement en vue du dessus.

## 8. Budgets (téléphone)

- Vaisseau : 2 000 pièces au maximum, 30 lumières.
- Modèle répété (astéroïde, bouée…) : moins de 6 pièces, sans lumière.
- Effets : 3 à 5 émetteurs par effet, durée courte, pas d'émetteur actif en permanence hors de l'écran.

## 9. Vérification avant de dire « fini »

1. Capture **en jeu**, à hauteur de joueur, en PC et en format téléphone.
2. Liste :
   - [ ] Le style est cartoon, rond et coloré, et suit la palette (section 3).
   - [ ] Aucun matériau interdit, néon à moins de 5 % et seulement pour une information.
   - [ ] On comprend à quoi sert l'objet sans lire.
   - [ ] Rien d'inutile, rien qui cache une chose importante.
   - [ ] Les effets sont en couches, animés, avec un rythme, et adaptés à la rareté.
   - [ ] Les budgets sont respectés.
3. Si un point échoue, on corrige avant de passer à la suite.
4. **Chouaib valide** sur la capture.
