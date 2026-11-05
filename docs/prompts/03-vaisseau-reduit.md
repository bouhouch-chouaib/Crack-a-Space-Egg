# Prompts Ropilot : vaisseau réduit (5 bases)

Retour de Chouaib (5 nov.) : moins de bases, un vaisseau plus petit et plus serré, seulement trois points de service (boutique, magasin de vente, machine à fusion), et un quai plus long qui avance dans le couloir.

Coller **un par un** dans Ropilot, dans l'ordre.

**Nouveau plan** (vue du dessus, toujours un D, l'avant vers +Z) :
- Pont en demi-disque de **rayon 104** centré sur (0, 0, 0), complété à l'avant par un rectangle qui va jusqu'à **z = +24**.
- **5 bases de 32 × 32**, sur un arc de rayon 80, à 8 studs l'une de l'autre côté place.
- **Boutique** à l'avant gauche, **magasin de vente** à l'avant droite, **machine à fusion** au centre de la place.
- **Quai** de 30 de large, qui part du pont et avance jusqu'à **z = +64**.

---

## Prompt 1 : réduire le vaisseau à 5 bases

```
Refais Workspace.Ship en plus petit et plus serré, en gardant exactement le même style (Star Wars, coque grise en plaques, néons bleus, réacteurs, tour de commandement). Ne touche à aucun script, ni à Workspace.World, ni à ReplicatedStorage.Assets, ni à ReplicatedStorage.RopilotSandbox.

1. Supprime Workspace.Ship.Workshops (les 5 ateliers) entièrement.
2. Nouveau pont, vue du dessus en "D" :
   - demi-disque de rayon 104 centré sur (0, 0, 0), partie courbe vers -Z ;
   - plus un rectangle de x = -104 à +104 et de z = 0 à z = +24, qui ferme le D par un bord droit à z = +24 ;
   - dessus du pont exactement à y = 0, plat et praticable partout, rebord de 2 studs tout autour sauf au quai.
   Réduis la coque, les réacteurs, la tour et la bulle (dôme de rayon 125) en proportion. La tour reste derrière la base du milieu, sans cacher la vue entre les bases.
3. Garde 5 bases seulement : Base1 à Base5 (supprime Base6 et Base7). Chaque base devient un carré de 32 x 32 avec le même contenu, réduit et resserré : Floor (PrimaryPart), murets bas sans mur ni toit à l'avant, panneau arrière avec le TextLabel "OwnerName", machine à casser + "CrackPoint", caisson de pression + "ChamberPoint", vitrine 4 socles + "RelicSlot1" à "RelicSlot4", enclos des créatures + "CreatureArea", SpawnLocation "Spawn", "GuardianPoint".
   Place les bases (centre au sol, côté ouvert tourné vers le centre (0, 0, 0)) :
   Base1 : (-75, 0, -27)
   Base2 : (-46, 0, -66)
   Base3 : (0, 0, -80)
   Base4 : (46, 0, -66)
   Base5 : (75, 0, -27)
   Couleurs du liseré : bleu, vert, orange, violet, rouge.
4. Le quai (Workspace.Ship.Deck.Dock) : une passerelle de 30 studs de large, centrée sur x = 0, qui part du bord avant du pont (z = +24) et avance jusqu'à z = +64, avec des rambardes lumineuses et le portique "LAUNCH" au bout. Déplace la Part invisible "DockEnd" exactement en (0, 0, 64).
5. Laisse vides pour le prompt suivant : l'avant gauche du pont (de x = -100 à -40, z = 0 à +22), l'avant droite (de x = +40 à +100, z = 0 à +22) et le centre de la place autour de (0, 0, -20).

Budget : 2 000 pièces maximum pour tout le vaisseau, 30 lumières maximum. Tout Anchored, petits détails en CanCollide false.
À la fin : vérifie que les 5 bases ne se chevauchent pas, que le sol est continu de chaque base jusqu'au bout du quai, et les noms ci-dessus. Donne le nombre de pièces. Capture vue du dessus.
```

---

## Prompt 2 : boutique, magasin de vente, machine à fusion

```
Dans Workspace.Ship, construis les trois seuls points de service du vaisseau, dans le même style (Star Wars, métal, néons). Ne touche pas aux bases, à la coque ni au quai, et à aucun script.

1. Dossier existant Workspace.Ship.Shop : la boutique, à l'avant gauche (de x = -100 à -40, z = +2 à +22), ouverte vers les bases (vers -Z). Comptoir, étagères avec équipements (foreuses, jetpacks, combinaisons) et potions lumineuses, grand panneau néon "SHOP". Une Part invisible "ShopPoint" devant le comptoir (Transparency 1, CanCollide false, CanQuery false).

2. Nouveau Model Workspace.Ship.Sell : le magasin de vente, à l'avant droite (de x = +40 à +100, z = +2 à +22), ouvert vers les bases. Comptoir de rachat avec balance holographique, caisses de cristaux, grand panneau néon "SELL" (vert / doré). Une Part invisible "SellPoint" devant le comptoir.

3. Nouveau Model Workspace.Ship.Fusion : la machine à fusion, au centre de la place, autour de (0, 0, -20). Une machine sci-fi circulaire d'environ 12 studs de large et 12 de haut maximum : 3 réceptacles vitrés autour d'un noyau d'énergie violet et cyan (Neon), anneaux lumineux, câbles. Elle doit être belle de tous les côtés (on la voit depuis les 5 bases) et ne pas cacher les bases. Une Part invisible "FusionPoint" devant la machine, côté avant (+Z).

Rien d'autre sur le pont. Budget : 350 pièces maximum pour les trois, 5 lumières maximum. Tout Anchored, détails en CanCollide false.
À la fin : vérifie les noms (Ship.Shop.ShopPoint, Ship.Sell.SellPoint, Ship.Fusion.FusionPoint), donne le total de pièces du vaisseau, capture depuis une base vers l'avant.
```
