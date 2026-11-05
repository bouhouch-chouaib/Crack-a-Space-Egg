# Prompts Ropilot : le couloir et les astéroïdes

À coller **un par un** dans Ropilot, dans l'ordre.

**Principe** : le couloir fait environ 2 500 studs. Ses dimensions changent avec l'équilibrage (`Config.lua`). Ropilot ne construit donc **pas** le couloir lui-même : il fabrique des **modèles** rangés dans `ReplicatedStorage.Assets`, et le code les copie aux bons endroits au lancement. Si un modèle manque, le code garde sa forme grise.

Le couloir contient :
- environ **31 plateformes** flottantes entre les anneaux ;
- **86 bouées** sur les bords ;
- **6 relais** de pression ;
- les **astéroïdes** des 7 anneaux, qui défilent (environ 60 à la fois) et servent aussi de décor tout autour des anneaux (210).

Ces modèles sont répétés des dizaines de fois : le nombre de pièces par modèle compte beaucoup pour le téléphone.

---

## Prompt 1 : plateforme et bouée

```
Crée dans ReplicatedStorage un dossier "Assets" (s'il n'existe pas), et dedans un dossier "Corridor". Ces modèles seront copiés par le code des dizaines de fois : ne les place pas dans Workspace (sauf pour tes captures, que tu supprimes ensuite). Ne touche à aucun script, ni à Workspace.Ship, ni à Workspace.World.
Style : le même que le vaisseau Workspace.Ship (Star Wars, métal gris, néons bleus).

1. Model "Pad" : une petite plateforme flottante de l'espace, sur laquelle les joueurs sautent pour avancer dans le couloir.
   - Surface de marche plate de 12 x 12 studs : c'est une Part nommée "Top", PrimaryPart du Model, Size (12, 1, 12). Le dessus de "Top" est la surface où l'on marche.
   - Dessous : un petit moteur antigravité avec une lueur bleue (Neon), des plaques et un liseré lumineux sur le bord du dessus, pour bien voir la plateforme de loin.
   - 12 pièces maximum. Tout Anchored. Seul "Top" a CanCollide true ; les détails : CanCollide false, CanQuery false.

2. Model "Buoy" : une bouée lumineuse qui balise les bords du couloir (la zone sûre).
   - Environ 3 studs de haut : un petit corps métallique et un cœur Neon bleu clair nommé "Core" (PrimaryPart).
   - 4 pièces maximum, aucune lumière (il y en a 86). Tout Anchored, CanCollide false, CanQuery false, CanTouch false.

Fais une capture de chacun posé dans le vide (fond spatial), puis supprime les copies de capture.
```

---

## Prompt 2 : le relais de pression

```
Dans ReplicatedStorage.Assets.Corridor, crée un Model "Relay" : un relais de pression, une petite station sûre posée dans le couloir entre deux anneaux. Les joueurs y rechargent leur oxygène et, plus tard, s'y entraînent dans un caisson.
Style : le même que le vaisseau Workspace.Ship (Star Wars, métal, néons bleus). Ne touche à aucun script ni à Workspace.

- Plateforme ronde de 24 studs de diamètre. Sa surface de marche est une Part nommée "Floor" (PrimaryPart). Le dessus de "Floor" est à la hauteur du pivot du Model.
- Un dôme de protection de 30 studs de diamètre, ForceField, bleu clair, Transparency 0.6, nommé "Bubble" : CanCollide false, CanQuery false, CanTouch false.
- Au centre : une borne de recharge d'oxygène (colonne avec des réservoirs lumineux). Mets devant elle une Part invisible "RefillPoint" (1x1x1, Transparency 1, CanCollide false, CanQuery false).
- Sur un côté : l'emplacement libre du futur caisson de pression, marqué au sol, avec une Part invisible "ChamberPoint" au niveau du sol.
- Deux petites rampes d'accès face à face, dans l'axe avant-arrière (axe Z du Model), pour entrer et sortir du côté du couloir.
- En dessous : un petit moteur antigravité avec une lueur bleue.
- 90 pièces maximum, 1 PointLight maximum. Tout Anchored ; les petits détails en CanCollide false.

Fais une capture de 3/4 et de dessus d'une copie posée dans le vide, puis supprime la copie.
```

---

## Prompt 3 : les astéroïdes des 7 anneaux

```
Dans ReplicatedStorage.Assets, crée un dossier "Asteroids" avec 7 Models, un par anneau : "Ring1" à "Ring7". Ce sont les astéroïdes que les joueurs forent, et sur lesquels ils se tiennent debout pendant qu'ils défilent. Ils servent aussi de décor autour des anneaux. Ne touche à aucun script ni à Workspace.

Règles pour chaque Model :
- Diamètre total d'environ 16 studs (le code le redimensionnera entre 10 et 28 avec Model:ScaleTo).
- La roche principale est UNE pièce (MeshPart de préférence, sinon Part) nommée exactement "Asteroid" : c'est la PrimaryPart, CanCollide true, CanQuery true. Forme de rocher irrégulier mais assez ronde, avec un dessus assez plat pour qu'on puisse s'y tenir debout.
- Les autres pièces sont des détails (cristaux, glace, lueurs) : CanCollide false, CanQuery false, CanTouch false.
- 6 pièces maximum par Model. Pas de lumière (il y en a des dizaines à l'écran).
- Tout Anchored.

Thème de chaque anneau :
1. "Ring1", Dust Belt : roche brun-gris poussiéreuse, quelques petits cristaux ternes.
2. "Ring2", Ice Ring : roche couverte de glace bleu pâle, pointes de givre, un peu brillante.
3. "Ring3", Magma Field : roche noire volcanique avec des fissures orange lumineuses (Neon).
4. "Ring4", Nebula : roche violette sombre, cristaux roses et violets qui brillent légèrement.
5. "Ring5", Devourer Belt : roche sombre et rouge, comme mâchée, avec des os ou des crocs de pierre.
6. "Ring6", The Rift : roche fracturée bleu-noir, éclats lumineux cyan dans les failles.
7. "Ring7", The Nest : roche ambrée en forme de nid, avec des coquilles d'œufs géants pétrifiés à la surface.

Fais une capture des 7 alignés côte à côte (copies dans Workspace), puis supprime les copies.
```
