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
