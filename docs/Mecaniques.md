# Crack a Space Egg : inventaire complet des mécaniques

Document de référence pour développer le jeu complet. Il reprend le descriptif v2 et les réponses de Chouaib et Alex du 4 novembre 2026. Quand il contredit le descriptif v2, c'est ce document qui compte.

Légende : ✅ décidé · 💡 détail proposé, à ajuster en jeu · ❓ reste à trancher (voir la fin).

---

## 1. Univers et ton

- ✅ Le vaisseau des joueurs flotte au-dessus d'une planète géante, avec **7 anneaux** d'astéroïdes autour. Des créatures cosmiques y ont pondu des œufs, aujourd'hui pétrifiés.
- ✅ Un œuf de l'espace est une coque de pierre craquelée, dont les veines lumineuses ont la couleur de sa rareté.
- ✅ Le style est beau et cinématique, bien au-dessus de Steal an Egg.
- ✅ Sortie le 11 décembre, avec un habillage de Noël (comète de Noël, neige sur le vaisseau).

## 2. Carte et lieux

| Lieu | Détail |
| --- | --- |
| Planète | ✅ Décor géant de 1 200 studs de rayon, centre de rotation des anneaux |
| Vaisseau-base | ✅ 240 × 140, fixe au-dessus du bord de la planète, protégé par une bulle de pression. On y apparaît, et on y trouve les boutiques et le classement. Le 8 nov., les deux coins à côté du quai sont comblés par un quart de disque à rambarde arrondie (`tools/build-shops.lua`) : à gauche, trois stands en arc tournés vers le coin, **STORE** (Robux, vert), **ITEMS** (foreuses, skins, scanner, bleu) et **SELL** (vente, doré), chacun avec comptoir, auvent rayé, enseigne, icône holographique et un vendeur astronaute (personnage Roblox de base à tête jaune, combinaison blanche aux couleurs du stand, qui respire et fait coucou : `ShipShops.client`) ; à droite, les trois tableaux de classement en arc. Le passage central vers le quai est dégagé. La vente (créatures, et plus tard géodes à pierres précieuses) reste à faire |
| 8 bases joueurs | ✅ 36 × 28 chacune, sur le pourtour du vaisseau. **Une base est toujours sûre** : sa bulle repousse les monstres |
| Quai de départ | ✅ La sortie de chaque base vers le couloir |
| Couloir de sécurité | ✅ 90 de large, balisé de bouées lumineuses ; la combinaison y est protégée. Environ **2 500 studs** de long pour 7 anneaux |
| Relais de pression | ❌ Retirés le 7 nov. : c'est le carburant du jetpack qui décide quels vides on traverse |
| Le Vide | ✅ Tout ce qui est hors du couloir. Aucun monstre n'y vit, mais il use très vite la combinaison |

**Taille des anneaux** ✅ : l'écart entre deux anneaux et leur épaisseur augmentent de **+35 % par anneau**. Le trajet de l'anneau 1 au 2 est court ; celui du 6 au 7 est très long. La difficulté monte aussi à chaque anneau : PV, usure de la combinaison, vitesse de défilement. Le joueur ne peut pas sauter un anneau, il doit s'améliorer.

💡 Formule de départ : écart entre deux anneaux = 150 × 1,35^(n−1), soit 150, 203, 273, 369, 498 puis 673 studs ; épaisseur = 60 × 1,35^(n−1).

| N° | Anneau | Particularité | Monstres |
| --- | --- | --- | --- |
| 1 | Poussière | Tutoriel, astéroïdes faciles et rapides | Non |
| 2 | Glace | Astéroïdes glissants | Non |
| 3 | Magma | Jets de lave qui projettent | Non |
| 4 | Nébuleuse | Brouillard ; le scanner repère les œufs | Non |
| 5 | Dévoreurs | Gros astéroïdes, monstres qui **entendent** le bruit | Oui |
| 6 | Faille | Lent et lointain ; monstres qui gardent leurs œufs | Oui |
| 7 | **Le Nid** | Là où les créatures ont pondu : œufs géants, gardés par une créature-mère | Oui |

💡 Multiplicateur de valeur par anneau : ×1, ×4, ×16, ×64, ×256, ×1 024, ×4 096.

## 3. Déplacement

- ✅ Le joueur marche, saute et utilise le jetpack (maintenir Saut en l'air ; le carburant se recharge au sol).
- ✅ On saute d'astéroïde en astéroïde. Tomber dans le Vide ramène au vaisseau avec une soute vide.
- 💡 Un joueur debout sur un astéroïde est entraîné avec lui.
- ✅ **Téléphones, tablettes, manettes et consoles** (7 nov.). `Device.lua` suit l'appareil utilisé en direct (clavier et souris, tactile ou manette ; une console démarre en manette) : aides, guide, boutons et textes changent dès qu'on change d'appareil.
  - **Téléphone** (`Mobile.client`) : gros bouton **DRILL** juste à gauche du bouton de saut de Roblox (qui sert aussi à voler), à sa taille, recalé quand l'écran tourne ; le maintenir fore la roche la plus proche à portée, il devient vert quand une roche est à portée. L'argent, le jetpack, STORE et INDEX montent en haut à gauche pour laisser la place au joystick. Mode allégé : moitié moins de particules (`Config.Mobile`). Poser l'œuf : toucher le sol de sa base.
  - **Manette** : maintenir **RT** (ou RB) fore la roche la plus proche ; A = sauter / voler ; **croix gauche = STORE, croix droite = INDEX** (petite flèche sur les boutons) ; dans une fenêtre, le premier bouton est sélectionné, la croix et le stick se déplacent dedans, A valide, **B ferme**. Poser l'œuf : il va juste devant le joueur, RT pour le poser. Invites : X (machine, stand, soufflerie), Y (faire éclore).
  - Touches de la manette réunies dans `Device.Pad`.

## 4. Tapis d'astéroïdes

- ✅ Les astéroïdes apparaissent juste avant le couloir, avancent le long de leur anneau et disparaissent après lui. Il y en a environ 60 actifs au maximum.
- ✅ Les anneaux intérieurs tournent plus vite. Un astéroïde reste 20 à 40 secondes dans le couloir.
- ✅ Le serveur gère les PV, les stocks et les gains ; le client rend le mouvement fluide.
- ✅ **Chaque astéroïde contient un stock d'œufs** (3 à 8 selon sa taille). Les œufs sortent un par un pendant le forage, pour le joueur qui fore. L'astéroïde se brise quand son stock est vide.
- ✅ Des **épaves d'anciens foreurs** passent parfois dans le couloir ; en les fouillant, on trouve une relique (section 10).

## 5. Forage

- ✅ On maintient le clic ou le doigt sur l'astéroïde : un faisceau part, et le serveur vérifie la portée et la cadence.
- ✅ À plusieurs, chacun récolte ses propres œufs pendant qu'il fore, jusqu'à ce que le stock soit vide.
- 💡 Un œuf sort toutes les X unités de dégâts, avec X qui dépend de l'anneau.

## 6. Œufs et soute

- ✅ **La rareté est tirée au forage** : les veines de l'œuf brillent de sa couleur dès qu'il sort, donc le retour devient tendu. Le contenu reste une surprise jusqu'à l'éclosion.
- ✅ (7 nov.) **L'œuf sort encore pris dans la roche** : on le ramène tel quel à la base, où une machine retire la roche (section 7).
- ✅ Les 7 raretés : Commun 58 %, Peu commun 27 %, Rare 11 %, Épique 3,75 %, Légendaire 1/400, Mythique 1/4 000, Cosmique 1/100 000. Elles sont modifiées par l'anneau, le scanner et les potions, et un compteur de veine garantit un Légendaire.
- ✅ La soute a une place limitée, qu'on agrandit avec l'amélioration. Un œuf colossal se porte à deux.
- 💡 L'œuf le plus rare de la soute se voit sur le dos du joueur.

## 6 bis. Géodes et minerais (8 nov.)

- ✅ Quand on fore, **une fois sur 3** c'est une **géode** au lieu d'un œuf (même rareté tirée, même chance du scanner). Elle jaillit de la roche comme un œuf (boule de roche de la couleur de l'anneau, pointes de cristal de la couleur de la rareté) ; l'emplacement en haut à droite affiche « RARE GEODE! ». On la ramène au vaisseau comme un œuf (oxygène compris).
- ✅ La **machine de la base** la fend (« CRACKING GEODE... » puis « GEM FOUND! ») et révèle un **minerai** de l'anneau (`Config.Rings[anneau].Crystals[rareté]` : Grey Quartz, Calcite, Amethyst... jusqu'à Cosmic Yolk), d'une taille tirée au hasard (Small, normal, Large) et parfois **brillant** (×3). Il va dans le **sac de minerais** (200 au plus).
- ✅ **Modèles des minerais (8 nov.)** : 25 types de pierres taillées ou brutes faites dans Blender (`tools/blender/gems.py` : pointe de quartz, grappe, rhomboèdre, cubes, octaèdre, brillant rond, princesse, émeraude, ovale, poire, marquise, cœur, coussin, trillion, baguette, cabochon, perle, cabochon goutte, pépite, biterminé, géode ouverte, étoile, colonne, orbe facetté, joyau serti d'or). Les 45 minerais `Assets.Gems.R<anneau>_T<rareté>` en sont des déclinaisons (couleur, verre ou opaque, cœur Neon à partir d'Epic, roche couleur de l'anneau), posées par `tools/gems-install.lua` (`ServerStorage.GemsInstall`) ; les 25 types sont gardés dans `ServerStorage.GemTypes`.
- ✅ On le vend au stand **SELL** : fenêtre **TRADING POST** (`SellUI.client`, serveur `GemService`) avec le sac (aperçu 3D qui tourne, nom, rareté, taille, valeur, SELL), **SELL ALL** et **SELL PETS** (vente des créatures).
- ✅ Prix = revenu d'une créature de même anneau et même rareté × 60 s × taille × brillant (`Config.Geodes`, `Config.GemValue`).
- 💡 Modèles : en attendant ceux faits avec Ropilot, géodes et minerais sont faits de pièces (`GemModel.lua`). Les modèles rangés dans `ReplicatedStorage.Assets.Gems.R<anneau>_T<rareté>` et `Assets.Geodes.R<anneau>_T<rareté>` (ou `Geodes.R<anneau>`, ou `Geodes.Geode`) sont pris automatiquement.

## 7. De la roche à l'éclosion (décision du 7 nov.)

La casse instantanée à la machine est remplacée par un parcours en deux temps :

1. ✅ **La machine à dérocher** : à sa base, le joueur passe ses œufs dans une machine **ultra détaillée et spectaculaire** qui retire la roche autour de l'œuf. On voit la roche se fissurer, éclater et l'œuf apparaître, avec une intensité qui dépend de la rareté. Le modèle est fait sur mesure (aucun modèle du Creator Store n'était au niveau) d'après une image de référence de Chouaib.
2. ✅ **Couver dans la base** : le joueur pose l'œuf dégagé dans sa base, et il **éclot au bout d'un certain temps**.

- ✅ La créature obtenue a la rareté de l'œuf et vient de l'anneau d'où il sort.
- ✅ Pose : l'œuf qui sort de la machine atterrit dans les mains du joueur. Un fantôme de l'œuf suit la souris sur le sol de sa base (cercle vert = libre, rouge = mur, machine, point d'apparition ou autre œuf trop près), clic pour poser. S'il en a plusieurs, le suivant arrive dans ses mains dès que le premier est posé ; base pleine = les œufs attendent.
- ✅ « Hatch now ⚡ » (touche R) : faire éclore tout de suite contre des Robux, prix selon la rareté (`Config.Hatch.Skip`, 9 à 199 R$). On paie du temps, jamais un œuf ni une créature. Produits à créer sur Roblox (ProductId = 0 → « Coming soon! »).
- ✅ Temps d'éclosion selon la rareté (`Config.Hatch.Time`) : 20 s (Common) → 30 min (Cosmic). Le temps passe aussi hors ligne. Compte à rebours au-dessus de l'œuf, puis « READY! Press F ».
- ✅ Éclosion (touche F, E étant pris par la machine) : l'œuf tremble et blanchit, éclate en coquilles et en lumière ; bannière « YOU HATCHED » avec la créature, sa rareté et ses $/s ; annonce au serveur à partir de Mythic.
- ✅ La créature reste dans la base et rapporte des $ chaque seconde : valeur de la rareté × multiplicateur de l'anneau × 0,5 × taille (`Config.CreatureIncome`). 10 places par base (œufs + créatures).
- ✅ Créatures en 3D, style briques + picots comme les œufs (tools/blender/creatures.py). Dans la base, chacune se promène autour de sa place (même trajet chez tous les joueurs ; le disque de lumière de sa rareté s'éteint en fondu juste après l'éclosion, plus de flaque au sol depuis le 7 nov.), sautille, balance la queue, bat des ailes ; nom et $/s au-dessus de la tête. Anneau 1 fait (6/42) ; en attendant les autres, une carte (image, nom, $/s) les remplace.
- ❓ Encore à trancher : vendre ou ranger une créature pour libérer une place, agrandir la base, accélérer aussi l'éclosion avec des $.

## 8. Monnaie : les dollars ($)

- ✅ **La monnaie s'affiche en dollars ($)**. Casser un œuf donne directement des $ : il n'y a pas de cristaux à vendre.
- ✅ Les $ servent aux améliorations, au gardien, à la Supernova et aux skins.
- ✅ Les créatures posées dans la base rapportent des $ en continu.

## 9. Créatures

- ✅ **6 créatures par anneau**, toutes différentes, chacune avec sa rareté. Avec 7 anneaux, cela fait **42 espèces**, réunies dans un index du type Steal an Egg.
- ✅ Répartition des raretés par fenêtre glissante. 💡 Anneaux 1 à 4 : de Commun à Mythique. Anneaux 5 à 7 : de Peu commun à Cosmique. Les chances penchent vers le rare à chaque anneau.
- ✅ **Le poids et la taille sont aléatoires**, entre un minimum et un maximum propres à chaque espèce. 💡 Une créature plus grosse rapporte plus en base et vaut plus dans l'index.
- ✅ Une créature a **un rôle à la fois** :
  - **3 créatures équipées** suivent le joueur et donnent leur pouvoir (4 avec le passe) ;
  - les autres vivent dans la base, **s'y promènent librement** et rapportent des $.
- ✅ **Pouvoirs** : des bonus passifs (forage, chance, soute, combinaison) et des pouvoirs actifs avec temps de recharge (bouclier, silence, aimant à œufs…). 💡 Les communes à épiques n'ont qu'un passif ; les légendaires et au-dessus ont aussi un pouvoir actif.
- ✅ **Évolution par fusion** : 3 créatures identiques donnent le stade suivant. 💡 Il y a 3 stades (bébé, adulte, ancien), et la taille du résultat est la moyenne des trois.
- ✅ Volume d'art : Alex part de squelettes communs (quadrupède, volant, serpent…), génère les modèles avec l'IA puis les retouche. **Les 42 doivent être prêts pour la sortie.**
- ✅ **Sac** (7 nov.) : 100 places. On range une créature de la base dans le sac, ou on la renvoie dans la base, où elle se pose seule à la première place libre. Un cadenas protège les favorites : on ne peut ni les vendre ni les fusionner. Bouton **PETS** du menu (`CreatureService`, `CreaturesUI.client`, règles dans `Config.PetRules`).
- ✅ **Trading Post** (stand SELL) : on vend la sélection, ou « Sell duplicates », qui garde le meilleur exemplaire de chaque espèce et stade. Le prix vaut 5 min du revenu de la créature. Une confirmation est demandée pour les Épiques et au-delà, et pour les stades évolués. Il faut être près du stand.
- ✅ **Fusion** (machine à fusion) : 3 créatures identiques (même espèce, même stade) donnent le stade suivant : bébé → **Adult** (revenu ×3,5, taille ×1,25) → **Elder** (×12, ×1,5). Leur taille est la moyenne des trois. « Auto-fill » choisit le groupe le plus précieux, en sacrifiant les moins rentables. Le résultat retourne dans la base si l'une des trois y était.
- ✅ **Index** (bouton INDEX, dans l'esprit des jeux d'œufs) : un onglet par anneau, avec ses 6 créatures. Celles qu'on n'a **jamais eues dans sa base** sont des silhouettes noires « ??? ». À droite, la créature choisie : nom, rareté, chance de l'obtenir et revenu. On voit la progression x/6 et la collection x/42. Un anneau complet se réclame (Claim!) : +10 % de chance pour toujours et 2 500 × le revenu de base de l'anneau en $ (`d.seen`, `d.indexClaimed`).
- Il n'y a pas de bouton PETS : le sac s'ouvre aux stands (Trading Post, Fusion Machine).
- Pas encore fait : équiper 3 créatures qui suivent le joueur, et leurs pouvoirs.

## 10. Objets spéciaux et reliques

- ✅ Les œufs donnent parfois un **objet spécial** (5 %) :
  - des **potions et outils** à usage unique (potion de chance de 10 min, recharge de combinaison, bombe de forage, aimant à œufs) ;
  - des **skins et décos** (couleurs de combinaison, traînées de jetpack, skins de base).
- ✅ Les **reliques d'exploration** sont ultra rares et viennent des épaves d'anciens foreurs qui passent dans le couloir. On les expose dans la base, en **vitrine**, visible par tout le serveur. 💡 Chaque relique donne un petit bonus permanent.

## 11. Base du joueur

- ✅ (7 nov.) **Au départ, les 5 bases sont vides** : seulement la clôture et le sol, avec la même apparence pour toutes. L'ancien contenu (panneaux « FREE BASE », machine à casser, caisson, vitrine, zone des créatures) est rangé dans `ServerStorage.RemovedFromBases`.
- ✅ La base accueillera la machine à dérocher, les emplacements où couvent les œufs, puis la vitrine à reliques, le terminal d'équipement et l'espace où se promènent les créatures.
- ✅ **Skins de base** : des thèmes complets (sol, murs, lumière), trouvés dans les œufs ou achetés.
- ✅ **Gardien de base** : un PNJ par base, acheté en $. 💡 Il casse les œufs et range les créatures pendant que le joueur est dehors.
- ✅ Les mineurs et scientifiques du descriptif v2 sont remplacés par le gardien.
- 💡 Le nom du joueur flotte au-dessus de sa base.

## 12. Améliorations (payées en $)

| Amélioration | Effet |
| --- | --- |
| Foreuse | Fore plus vite |
| Soute | Plus d'œufs par voyage |
| Scanner | Plus de chance ; repère les astéroïdes rares et les épaves |
| Combinaison | ❌ Retirée le 7 nov. : **tous les anneaux sont ouverts**, on peut y aller et y forer à ses risques et périls. C'est la portée du jetpack (paliers) qui décide si on y arrive sans tomber dans le Vide |

### Niveau du jetpack et souffleries (remplace l'oxygène, 7 nov.)

- ✅ L'oxygène est retiré, et la vitesse ne s'achète plus. Elle vient du **niveau du jetpack** (HUD : « Jetpack Lv N » + barre d'XP).
- ✅ (7 nov.) **Portée du jetpack** : le carburant de chaque niveau est calculé pour une portée de vol (`Config.Jetpack.Tiers`, `Config.JetpackFuel`). Au niveau 1, un vol porte à 44 studs : on va sur l'anneau 1, mais le vide jusqu'à l'anneau 2 (55 studs) est trop large. **Tomber dans le Vide = mourir** (écran « LOST IN THE VOID », réapparition à la base, œuf perdu). Les relais entre les anneaux sont retirés : seul le niveau du jetpack décide jusqu'où on va.
- ✅ **8 paliers de jetpack**, chacun avec son modèle 3D (généré par l'IA de Studio, `ReplicatedStorage.Assets.Jetpacks.Jet1..Jet8`) et sa jauge : Rusty Starter (niv. 1, anneau 1), Scout Booster (10, anneau 2), Comet Pack (25, anneau 3), Blaze Thruster (45, anneau 4), Nebula Wings (65, anneau 5), Rift Striker (90, anneau 6), Nova Titan (115, anneau 7), Supernova X (140). Entre deux paliers, portée, carburant et vitesse montent petit à petit : vitesse en vol 20 → 42 studs/s, carburant 0,8 → 2,9 s, vitesse au sol +0,5 % par niveau. Message « New jetpack: … You can now fly to the … » à chaque palier.
- ✅ **Jauge de carburant** (bord droit) : elle grandit et change de couleur avec le palier, chiffre romain au-dessus ; halo qui pulse (III), reflet (IV), étincelles et icône qui flotte (V), rayons (VI), contour doré (VII), contour arc-en-ciel (VIII). Elle clignote en rouge sous 25 %.
- ✅ Le vol plané (se laisser tomber) ne consomme pas de carburant depuis le 7 nov. ; il faut juste qu'il en reste, sinon on tombe sans frein.
- ✅ **Soufflerie personnelle** (l'équivalent des tapis de course) : chaque base a son emplacement devant l'entrée. Le joueur l'achète (Breeze Tunnel, 1 K$), puis l'améliore palier par palier avec l'invite du socle : Gale 30 K$, Storm 1,5 M$, Cyclone 80 M$, Hurricane 4 Md$, Tempest 220 Md$, Supernova Vortex 11 T$. Dans le courant d'air de SA soufflerie, il flotte sur place (Saut tenu = monter plus haut) et gagne de l'XP chaque seconde, même AFK : 2, 8, 30, 150, 800, 5 000, 30 000 XP/s. Les autres joueurs ne peuvent pas s'en servir et ne voient pas l'invite.
- ✅ (7 nov.) Pendant l'entraînement, des « +XP » jaillissent du joueur chaque seconde (XP réellement gagnée, boosts compris) : 2 bulles par seconde avec la Breeze Tunnel, jusqu'à 8 avec la Supernova Vortex, de plus en plus grosses et colorées, avec un petit « pop ».
- ✅ Voler en mission (poussée ou plané, hors soufflerie) rapporte 1 XP/s.
- ✅ XP pour passer au niveau suivant : 20 × 1,12^(niveau − 1), niveau max 150. Le serveur compte l'XP (`WindTunnelService`) et la sauvegarde (`jetXP`).
- ✅ Jetpack : Saut maintenu = poussée vers le haut (carburant, rechargé au sol) ; relâché = vol plané (chute freinée) ; on pilote la direction avec de l'inertie. Modèle 3D porté au dos, flammes, fumée, étincelles, traînée, lumière, poussière au décollage et à l'atterrissage ; le joueur se penche dans le sens du vol. Les autres joueurs voient les flammes (état relayé par le serveur).
- La foreuse est maintenant accrochée sur le côté (le jetpack occupe le dos).

### Gel hors du couloir (7 nov.)

- ✅ On respire dans le couloir (entre les bouées, au-delà du quai) et sur le vaisseau (`SafeZone`). Ailleurs, il n'y a plus d'oxygène et le froid gagne (`ColdService`, réglages `Config.Cold`).
- ✅ En sortant, on a 3 s de répit : bandeau « Leaving the corridor », compte à rebours et flèche verte vers la zone sûre. Ensuite, le gel monte en 7 s. Si on est à plus de 40 studs, il n'y a pas de répit et le gel va 2× plus vite. De retour dans la zone, on dégèle en moins de 2 s.
- ✅ Effet plein écran : le givre envahit l'écran depuis les coins (deux couches), la vignette bleue bat comme un cœur, des flocons tombent, l'image devient bleue puis floue, la jauge d'O₂ se vide et la caméra frissonne. Le joueur ralentit jusqu'à −45 %. Les autres joueurs le voient se couvrir de givre.
- ✅ À 100 %, le joueur est pris dans un bloc de glace hérissé de cristaux. Il voit un flash, de la glace fissurée sur tout l'écran et « FROZEN! ». 2,2 s plus tard, la glace éclate et il revient à sa base en perdant les œufs de sa soute, comme une chute dans le Vide.
- Textures : `tools/fx/cold_textures.py` (givre léger et épais, fissures, vignette, flèche).

### Oxygène de l'œuf (7 nov.)

- ✅ Dès qu'on sort un œuf de la roche, un compte à rebours d'air démarre. Sa durée dépend de l'anneau où l'œuf a été foré : 45 s (anneau 1), puis +5 s par anneau jusqu'à 75 s (anneau 7). Un peu plus de temps au loin, mais bien moins que la distance en plus : plus on va loin, plus il faut un bon jetpack pour revenir à temps (`Config.Oxygen`).
- ✅ Le temps s'arrête et se recharge dès qu'on est de retour sur le vaisseau.
- ✅ À zéro : plus d'air, le joueur meurt, perd l'œuf et réapparaît à sa base.
- ✅ Affichage (`OxygenFx.client`) : jauge « AIR 0:42 » sous l'emplacement de l'œuf ; sous 30 % elle passe au rouge et tremble, l'écran bat en rouge, un bip chaque seconde et « HURRY HOME! » au centre ; à zéro, flash rouge et « OUT OF AIR! ». Le guide dit « Fast! 42 s of air left ».

### (Ancien) Oxygène et caissons de pression

C'est l'équivalent des tapis de course des simulateurs : l'oxygène se farme, il ne s'achète pas.

- ✅ L'**oxygène max** est le temps qu'on tient hors du couloir. La Combinaison ouvre les anneaux, l'oxygène permet d'y rester : il faut les deux pour avancer.
- ✅ On l'entraîne dans un **caisson de pression**. L'oxygène max monte tant qu'on reste dedans, même en AFK.
  - **Caisson de base** dans chaque base : sans risque, +1 s toutes les 3 minutes.
  - **Caissons des relais de pression**, un par relais : ×2, ×3, ×5, ×8, ×12, ×20 selon l'anneau.
- ✅ Dans les anneaux 5 à 7, les relais ne protègent pas des monstres : farmer loin rapporte beaucoup, mais c'est risqué.
- ✅ **Rendements décroissants** : la vitesse est divisée par (1 + oxygène / 60), pour que la statistique ne s'envole pas.
- ✅ **Courbe visée** : on part avec 15 s et il faut environ 180 s pour le Nid. Ça donne environ 15 min de caisson pour l'anneau 2, environ 1 h 30 au total pour l'anneau 4, et **environ 10 h au total pour l'anneau 7**.
- ✅ La Supernova remet le niveau du jetpack et la soufflerie à zéro.
- 💡 Tous les chiffres vont dans `Config.lua` et se règlent en jeu.

## 13. Dangers

- ✅ **Le Vide** vide la jauge d'oxygène, plus vite dans les anneaux lointains. Il n'y a **qu'une seule jauge**, et sa taille dépend de l'entraînement en caisson. À zéro, le joueur perd des PV, puis revient au vaisseau avec une soute vide.
- ✅ **Les monstres** vivent dans les anneaux 5, 6 et 7, sur les astéroïdes et dans le couloir, jamais dans le Vide. Leur façon de repérer le joueur dépend de l'anneau :
  - anneau 5 : **le bruit** (forer, courir, utiliser le jetpack remplit une jauge de bruit) ;
  - anneau 6 : **le vol de ses œufs** (forer l'astéroïde qu'il garde le réveille) ;
  - anneau 7 : 💡 les deux.
- ✅ (7 nov.) **Fait** (`MonsterService`, `MonsterFx.client`, réglages dans `Config.Monsters`) :
  - anneau 5 : **le Dévoreur**, ver de roche aux fissures vertes. La jauge de bruit (à droite) se remplit quand on fore ou qu'on pousse au jetpack, redescend quand on plane ou qu'on reste discret ; alerte à 70 % (grondement, secousse), réveil à 100 % ;
  - anneau 6 : **le Gardien de la Faille**, un œil cosmique. Environ 1 astéroïde sur 5 est gardé : un petit œil flotte au-dessus, avec une lueur. Il contient 50 % d'œufs en plus, à la rareté tirée deux fois (la meilleure). Le forer réveille le gardien ;
  - anneau 7 : **la Reine du Nid**, insecte aux ailes de cristal : bruit et astéroïdes gardés ;
  - modèles générés par l'IA 3D de Studio (`ReplicatedStorage.Assets.Monsters` : Devourer, Watcher, Queen).
- ✅ **Poursuite** : le monstre sort en grandissant (1,4 s pour fuir), puis vole vers le joueur à 85 / 90 / 95 % de sa vitesse en vol (au moins 28 studs/s). **Il abandonne au bout d'un temps qui dépend de la rareté de l'œuf porté** : 8 s (Commun), 10, 13, 16, 20, 25, 30 s (Cosmique), 5 s sans œuf. Le vaisseau le fait fuir aussitôt. 12 s de répit ensuite.
- ✅ **S'il attrape le joueur** : l'œuf porté est perdu et le joueur revient à sa base.
- ✅ **À l'écran** pour le joueur poursuivi : bandeau « NOM! ESCAPE 12s » avec une barre (en bas), bord rouge qui bat plus fort quand il approche, icône de danger au bord de l'écran de son côté, contour du monstre visible à travers les roches, musique de poursuite, rugissement, grondement près de lui, secousses. Les autres joueurs voient et entendent aussi le monstre.
- ✅ Tomber dans le Vide tue le joueur : il réapparaît à sa base et perd l'œuf porté.

## 14. Événements

| Événement | Fréquence | Effet |
| --- | --- | --- |
| Astéroïde spécial (doré, cristallin, colossal) | Plusieurs fois par heure | Annoncé à tout le serveur |
| Épave d'ancien foreur | Rare | Contient une relique |
| ~~Pluie de météores~~ | ❌ Retirée le 7 nov. | — |
| Comète de Noël | Toutes les 60 min | Tout le serveur la fore ensemble |
| Réveil des monstres | Rare | 2 min de chaos dans les anneaux 5 à 7, butin doublé |

## 15. Progression à long terme

- ✅ **Index** des créatures : compléter un anneau donne un bonus de chance permanent.
- ✅ (7 nov.) Chaque nouvelle créature découverte rapporte une petite récompense : l'équivalent d'1 min de ses revenus, au moins 250 $ (`Config.IndexReward.NewSeconds`), avec le message « New in your Index: … +$… » juste après sa sortie de l'œuf.
- ✅ **Supernova** (rebirth), **dès la sortie** (8 nov., `SupernovaService`, `SupernovaUI.client`, `Config.Supernova`) :
  - Le bouton SUPERNOVA (colonne de gauche, croix bas à la manette) n'apparaît qu'à partir du **niveau 25 du jetpack** (Comet Pack, anneau 3) ; pastille « ! » quand on peut payer.
  - Prix : 5 M$, puis ×8 à chaque fois (40 M$, 320 M$…).
  - On perd : $, foreuse (sauf celle payée en Robux), scanner, niveau du jetpack, soufflerie, œuf porté.
  - On garde : créatures (base et sac), œufs, Index, minerais, skins, passes et potions.
  - On gagne : +50 % de revenus des créatures pour toujours, cumulable (x1,5, x2, x2,5…).
  - Fenêtre YOU LOSE / YOU KEEP / YOU GET, double appui pour confirmer (« SURE? TAP AGAIN! »), explosion d'étoile en plein écran, retour à la base pendant le flash blanc ; les autres joueurs reçoivent « X went SUPERNOVA! ».

## 16. Fidélisation (tout est prévu dès la sortie)

- ✅ **La première minute** est la priorité : le joueur ne doit ni s'ennuyer ni se demander quoi faire. Il n'y a **pas de cinématique**, on joue tout de suite. 💡 Un astéroïde facile arrive pile au bon moment, et le premier œuf donne à coup sûr une créature.
- ✅ **Guide** (7 nov., `Guide.client`, `Config.Guide`) : **un enfant doit pouvoir le suivre sans difficulté**, et il tient le joueur plusieurs minutes, jusqu'à ce qu'il ait intégré la boucle et ses détours.
  - Bulle en bas de l'écran : 3 à 5 mots, grosse icône, une petite ligne d'aide ; 10 étoiles de progression ; petite croix pour passer (deux touches).
  - Chaîne de grosses flèches vertes posées au sol tous les 5 studs, du joueur jusqu'au but, avec une vague de lumière qui file vers le but ; flèche au sol (chevrons qui filent vers le but), flèche qui rebondit au-dessus du but, contour vert qui le fait briller même derrière un mur, grosse flèche au bord de l'écran quand le but est hors champ.
  - Main qui montre le geste : clic maintenu sur la roche (ordinateur), appui sur le bouton DRILL (téléphone).
  - Fête à chaque étape (« Great! », étincelles, son), « You did it! » à la fin.
  - Étapes enregistrées (`d.guide`) : forer un œuf → le rapporter à la machine → poser l'œuf → pendant qu'il couve, aller chercher le suivant → faire éclore → « ta créature rapporte des $ » → 3 créatures → acheter sa soufflerie (1K) → jetpack niveau 3 → acheter la Rusty Drill (2K) → acheter un niveau de Scanner (la chance). Pas d'étape « va à l'anneau 2 » : le joueur y va de lui-même (ordre et niveaux revus après un test du 7 nov.).
  - Il suit l'état réel : s'il tombe, perd son œuf, porte un œuf ou en a un prêt, la bulle le ramène à ce qu'il faut faire (« Bring it home! », « Press F to hatch! »...), même pendant les objectifs suivants. Pas assez d'argent : « Save $2K for a new drill » avec la somme actuelle, et la flèche vers les roches.
  - Les anciens joueurs qui ont déjà des créatures ne le voient pas.
- ✅ **Fait le 7 nov.** (`RewardService`, fenêtre REWARDS `RewardsUI.client`, réglages `Config.Rewards` et `Config.Codes`). Jamais d'œufs ni de créatures ; les sommes en $ suivent l'anneau le plus lointain atteint, pour rester intéressantes à toutes les étapes. Les journées changent à minuit UTC.
  - Connexion quotidienne sur 7 jours qui reprennent au début ; un jour manqué = retour au jour 1. Jour 1 : 1K $, puis potions et $, jour 7 : gros cadeau (10K $ + x2 Luck et x2 Money 15 min dans l'anneau 1).
  - Cadeaux à 5, 15, 30 et 60 minutes de jeu dans la journée (cumulé, AFK compris).
  - 3 quêtes du jour tirées parmi 6 (forer des œufs, faire éclore, casser des astéroïdes, poser des œufs, s'entraîner en soufflerie, gagner des $ avec ses créatures), 1K $ chacune (anneau 1), et x2 Luck 15 min quand les 3 sont réclamées.
  - Codes promo (une fois par joueur) : WELCOME, SPACEEGG, DRILLTIME.
  - Groupe Roblox : +10 % de chance tant qu'on est membre, et un cadeau au premier « Claim ». **Le jeu appartient à un compte, pas à un groupe : mettre l'identifiant du groupe dans `Config.Rewards.GroupId`** (le bouton affiche « GROUP SOON » d'ici là).
  - Boost gratuit contre une pub récompensée (AdService, toutes les 10 min) : x2 Luck et x2 Money 5 min. La pub passe par le produit de la potion x2 Luck (canal AdReward). Roblox ne montre ces pubs qu'aux joueurs et pays éligibles.
  - Bouton REWARDS dans le HUD avec pastille quand quelque chose est à réclamer ; la fenêtre s'ouvre sur l'onglet utile. Manette : croix haut.

## 17. Social

- ✅ Les vitrines et les créatures se voient dans toutes les bases. Une annonce part au serveur à partir de Mythique.
- ✅ Pas de vol entre joueurs à la sortie.
- ✅ Échanges de créatures : mise à jour de janvier.
- ✅ Factions : plus tard.
- 💡 Classements : sur le serveur ($) et global (œufs cassés, meilleure rareté).

## 18. Monétisation (jamais d'œufs vendus contre des Robux)

| Article | Type |
| --- | --- |
| Soute XL | ✅ Passe |
| Jetpack turbo | ✅ Passe |
| Casse auto | ✅ Passe |
| **×2 argent** | ✅ Passe |
| **×2 entraînement** (l'oxygène monte deux fois plus vite dans les caissons) | ✅ Passe : un raccourci de temps, pas un avantage hors de portée des autres |
| **+1 créature équipée** | ✅ Passe |
| **VIP** (nom doré, +10 % de $, traînée exclusive) | ✅ Passe |
| Skins de base et de combinaison | ✅ Produits |
| Potion de chance, recharge de combinaison | ✅ Produits |
| ~~Pluie de météores pour tout le serveur~~ | ❌ Retirée le 7 nov. (produit retiré de la vente sur Roblox) |

### Boutique Robux (7 nov.)

- ✅ **Passes** (définitifs) : x2 Jetpack XP (149 R$), Turbo Jetpack (+25 % de carburant, 99 R$ ; pas plus, pour ne pas sauter un palier), Fast Hatch (éclosion ×2 plus rapide, 199 R$), x2 Money (revenus des créatures ×2, 299 R$), +5 Base Slots (249 R$), VIP (+10 % d'argent et tag [VIP] doré dans le chat, 399 R$).
- ✅ **Potions** de 15 min, cumulables dans le temps et sauvegardées : x2 Luck (39 R$), x2 Money (39 R$), x2 Jetpack XP (25 R$). (Meteor Shower retirée le 7 nov.)
- ✅ **Starter Pack** (99 R$) : gros paquet d'argent + x2 Luck + x2 Money. **Paquets d'argent** : le montant dépend de l'anneau le plus lointain où l'on a déjà sorti un œuf.
- ✅ Les effets sont calculés par le serveur (`BoostService`). Les identifiants Roblox vont dans `Config.Shop`, `Config.Drills` et `Config.Hatch.Skip`. Tant qu'un identifiant vaut 0, le bouton affiche « Coming soon! ».
- ✅ Les 33 articles sont créés sur Roblox depuis l'Assistant de Studio (API Open Cloud) : 6 passes et 27 produits (10 foreuses, 7 « Hatch now », 4 potions, 5 paquets d'argent, le Starter Pack). Chacun a une icône faite par `tools/store_icons.py` (images dans `tools/store-icons`). Leurs identifiants sont dans `Config`.
- ✅ **Skins de foreuse** (7 nov.) : 12 apparences dans `Config.DrillSkins`, gardées quand on change de foreuse (`DrillSkin.lua` recolore Body, Trim, Dark, Bit, Glow ; serveur : `SkinService`). Classic gratuit, 8 en $ (25K à 50B, de Rare à Mythic, étincelles à partir de Frost), 3 premium en passes Robux : Galaxy (149 R$, étincelles), Rainbow (199 R$, couleurs qui défilent), Supernova (249 R$, flammes). Icônes des passes : captures de la foreuse dans Studio sur fond vert, composées comme les autres (`tools/store-icons/skin_*.png`). Le créateur du jeu possède ses propres passes : dans Studio, les skins premium affichent donc EQUIP.
- Dans Studio, les points d'accès de test `ServerStorage.ReceiptDebug` et `BoostDebug` font passer un achat fictif par le vrai traitement. Ils n'existent pas dans le jeu publié.

## 19. Interface

- ✅ Le MVP a déjà le HUD ($, soute, carburant), la boutique et l'écran de révélation.
- 💡 À ajouter : jauge de combinaison, jauge de bruit, inventaire et fusion des créatures, index, quêtes, récompenses, boutique Robux, réglages (son, qualité).

## 20. Son et ambiance

- ✅ (7 nov.) Sons gratuits du Creator Store (APM Music, Pro Sound Effects, Daily Sounds), tous dans `Config.Sounds` : pour en changer un, on remplace son Id. Module `Sfx` (sons à l'écran ou placés dans le monde, boucles avec fondu) et script `Audio.client` qui les déclenche.
- ✅ **Musique par lieu** : « Explore » dans le vaisseau, « Futureworld » dans les anneaux, « Dangerous Pursuit » pendant une poursuite de monstre (fondu de 1,6 s). Hors du couloir, elle baisse sous un vent glacé.
- ✅ **Volumes mesurés** (7 nov.) : chaque son a été mesuré dans Studio (AudioAnalyzer : niveau et timbre) puis réglé sur un niveau commun ; les enregistrements pro très faibles ont un volume au-dessus de 1. Pour les boucles tirées d'un long enregistrement, seule sa partie régulière tourne (`Region`).
- ✅ **Jetpack** : allumage à la poussée, souffle grave du réacteur + flamme qui montent dans les aigus avec la vitesse de montée, souffle léger en vol plané, extinction quand il reste coupé. Les jetpacks des autres joueurs s'entendent de près.
- ✅ **Foreuse** : moteur dès qu'elle tourne, grosse foreuse dans la pierre quand les coups portent ; les deux montent dans les aigus à mesure que l'œuf se dégage. « Pop » + tintement quand l'œuf sort, gros impact croquant + éboulis quand l'astéroïde se brise.
- ✅ **Autres boucles** : soufflerie, vent du Vide, battements de cœur quand le gel dépasse la moitié.
- ✅ **Moments clés** : coups de foreuse et roche qui éclate (placés au point d'impact), œuf ramassé, œuf révélé, éclosion (fanfare à partir d'Épique, entendue aussi par les voisins), achat en $, gros gain, niveau de jetpack, alarme à la sortie du couloir, prise dans la glace et dégel, achat Robux, clic sur les boutons, ouverture des fenêtres, message d'erreur.
- ✅ **Machine à dérocher** (Derock.client, entendue et vue par tous) : « clac » des pinces ; forage qui monte dans les aigus ; la roche se fend de plus en plus vite (craquement, éclats, petit sursaut) et chaque craquement ouvre une **fissure lumineuse** à la couleur de la rareté (bord sombre, cœur clair, halo, rayon de lumière qui sort) ; la dernière seconde, la roche tremble fort, s'illumine de l'intérieur et les rayons s'allongent sur une montée sonore ; puis explosion (plus de morceaux et d'étincelles selon la rareté, éclair de couleur, secousse de caméra pour le joueur tout près), tintement et fanfare à partir d'Épique ; l'œuf s'envole avec un souffle et arrive avec un « pop ».
- ❌ Réglages musique / sons retirés le 7 nov.
- 💡 Musique propre aux monstres des anneaux 5 à 7, quand ils existeront.

## 21. Technique

- ✅ Le serveur est autoritaire. La sauvegarde est versionnée, avec migration et sans jamais écraser une partie.
- ✅ Rojo et `src/` sont la source de vérité. 8 joueurs par serveur.
- 💡 Un mode téléphone allégé (moins de particules).

## 22. Lancement

- 💡 Miniatures, icône, description et badges (premier Épique, premier Mythique, Supernova…), faits avec Alex.

---

## Ce qui reste à trancher

1. **Gardien ou passe Casse auto** : ils se recoupent. 💡 Le gardien casse lentement pendant l'absence du joueur ; le passe casse tout instantanément à l'arrivée.
2. **Ampleur** : 7 anneaux, 42 créatures, 3 types de monstres, fusion, gardien, Supernova et toute la fidélisation en 5 semaines (gel des fonctionnalités le 5 décembre). Il faut un ordre de production strict et un plan B si on prend du retard : sortir avec les anneaux 6 et 7 « bientôt ».
