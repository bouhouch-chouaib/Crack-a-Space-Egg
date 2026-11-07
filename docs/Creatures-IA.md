# Créatures « blocky » animées (7 nov., soir) — méthode actuelle

Les 42 créatures ont été refaites dans un seul style, celui des jeux d'œufs de référence : low-poly « blocky »
(blocs chanfreinés, prismes, cristaux, couleurs franches, texture pixel), faites dans Blender avec le kit
`ropilot.model` (px = 8, sans picots). Plus la rareté monte, plus elles sont grandes et impressionnantes :
Common/Uncommon chibi et mignonnes, Rare avec quelques cristaux lumineux, Epic armure et yeux lumineux,
Legendary majestueuses, Mythic menaçantes (crocs, ailes, flammes), Cosmic en boss ultime.
Les anciennes versions sont dans `ServerStorage.OldCreatures` (et les restes trouvés dans le Workspace dans
`OldCreatures.WorkspaceLeftovers`).

Chaîne pour une créature (clé `R<anneau>_T<rareté>`) :
1. Blender : modèle fait avec le kit, une pièce par partie (tête, pattes, ailes...). Fichiers dans le dossier
   Blender de Ropilot : `<clé>.blend` (spécification du kit) et `<clé>_rig.blend` (découpé).
2. `tools/blender/rigjoin.py` : `rig_join(clé, {rôle: [pièces]})` fusionne les pièces par membre animé
   (Head, Jaw, LegFL/FR/BL/BR, LegL/R, ArmL/R, WingL/R, FinL/R, EarL/R, Tail, Tentacles ; le reste = Body).
   Chaque matériau lumineux donne un objet « <rôle>__Glow » (Neon dans Studio) qui suit son membre.
3. Import dans Studio, puis `require(ServerStorage.CreatureRig).Install(workspace.Work_<clé>, clé, nil, true)`
   (`tools/creature-rig.lua`) : retire les soudures, recalcule gauche/droite d'après la position, pose un
   Joint par membre, attribut Follow sur les pièces lumineuses, Height = hauteur (ou 0,55 × longueur pour
   une créature plate ou allongée, sinon la raie et les serpents deviennent immenses).
4. `Creatures.client` anime les membres selon `Config.CreatureMotion` : pattes en trot diagonal, ailes qui
   battent, queue qui remue, tête qui regarde autour, mâchoire qui s'ouvre pour rugir ; oreilles,
   mâchoire et pièces « Follow » suivent la tête ou leur membre.
5. Portraits (`Art` de `Config.Creatures`) : rendus Blender des modèles installés, style standard Ropilot
   (dossier Renders/Creatures, ids dans renders.json).

---

# Créatures 3D générées par IA (7 nov.)

Les 42 créatures (`ReplicatedStorage.Assets.Creatures.R<anneau>_T<rareté>`) sont générées par l'IA 3D de
Roblox Studio (Cube, gratuite), dans le style des familiers des jeux d'œufs : low-poly facetté, texturé.
La modélisation par code (tools/blender/polykit.py, creatures_poly*.py) reste comme solution de secours.

Règles des descriptions (prompts) :
- Common / Uncommon : « cute blocky … pet, cube head, big square eyes, happy ».
- Plus la rareté monte : « majestic / powerful / epic … », yeux lumineux, armure, ailes, flammes.
- Jamais de regard triste. La modération de Roblox refuse parfois « warrior », « war paint »,
  « angry … frowning brows », « fangs/snarling » : préférer « intense glowing eyes », « bold », « confident ».
- Terminer par : « stylized low-poly Roblox pet, faceted shapes, vivid solid colors, full body, facing forward ».
- Pas plus de ~3 générations en même temps (sinon « Rate limit exceeded »).

Installation : chaque modèle reçoit un `Core` invisible aux pieds (regard vers -Z), les attributs
Ring, Rarity, Height ; la taille en jeu vient de `Config.Hatch.PetHeight`. Pas de picots (le modèle est texturé).

## Astéroïdes générés par IA (7 nov.)

Les astéroïdes du tapis et du décor (`ReplicatedStorage.Assets.Asteroids.Ring<N>.V1..V3`) sont aussi
générés par l'IA 3D de Roblox : 3 formes par anneau, une seule pièce (`segmentation = none`, 4 000 triangles).
Chaque variante est un modèle avec une MeshPart texturée `Asteroid` (PrimaryPart, collision Hull, on marche dessus).
Les anciens modèles low-poly sont sauvegardés dans `ServerStorage.OldAsteroids`.

Description : « Floating <biome> space asteroid rock, <forme>, rough stone surface with sharp broken edges
and dark cracks, <matière>, rocky on all sides, stylized semi-realistic game asset ».
- Formes : V1 « irregular lumpy potato shape », V2 « broad low flattened chunk wider than tall »,
  V3 « chunky cluster of fused boulders ». Éviter « shard » (donne un pic vertical) et « round craters »
  (donne une boule trouée).
- Matières : 1 grès beige et brun avec topazes, 2 roche bleu-gris givrée avec blocs de glace,
  3 basalte noir veiné de lave orange, 4 pierre violette avec cristaux roses, 5 roche anthracite moussue
  aux veines vertes, 6 ardoise bleu nuit fendue de cyan, 7 grès doré avec grappes d'ambre.
