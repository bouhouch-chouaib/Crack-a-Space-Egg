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
| Vaisseau-base | ✅ 240 × 140, fixe au-dessus du bord de la planète, protégé par une bulle de pression. On y apparaît, et on y trouve la boutique et le classement |
| 8 bases joueurs | ✅ 36 × 28 chacune, sur le pourtour du vaisseau. **Une base est toujours sûre** : sa bulle repousse les monstres |
| Quai de départ | ✅ La sortie de chaque base vers le couloir |
| Couloir de sécurité | ✅ 90 de large, balisé de bouées lumineuses ; la combinaison y est protégée. Environ **2 500 studs** de long pour 7 anneaux |
| Relais de pression | ✅ Bulles de 30 studs dans le couloir, entre deux anneaux, pour recharger la combinaison. 💡 Ils ne protègent pas des monstres : seule la base protège |
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
- 💡 Sur mobile, des boutons Jetpack et Forer s'ajoutent à l'écran.

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
- ✅ Créatures en 3D, style briques + picots comme les œufs (tools/blender/creatures.py). Dans la base, chacune se promène autour de son socle lumineux (même trajet chez tous les joueurs), sautille, balance la queue, bat des ailes ; nom et $/s au-dessus de la tête. Anneau 1 fait (6/42) ; en attendant les autres, une carte (image, nom, $/s) les remplace.
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
- 💡 L'inventaire contient 100 créatures au maximum, et un verrou protège les favorites.

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
| Combinaison | Chaque palier donne la résistance à la pression qui ouvre l'anneau suivant. Sans le bon palier, la pression y est mortelle |

### Niveau du jetpack et souffleries (remplace l'oxygène, 7 nov.)

- ✅ L'oxygène est retiré, et la vitesse ne s'achète plus. Elle vient du **niveau du jetpack** (HUD : « Jetpack Lv N » + barre d'XP). Chaque niveau donne +3 % de vitesse au sol et en vol et +0,05 s de carburant (`Config.Movement`, `Config.Jetpack`). Au niveau 1, le réservoir ne contient que 2 s de poussée (de quoi rejoindre l'anneau 1).
- ✅ **Soufflerie personnelle** (l'équivalent des tapis de course) : chaque base a son emplacement devant l'entrée. Le joueur l'achète (Breeze Tunnel, 1 K$), puis l'améliore palier par palier avec l'invite du socle : Gale 30 K$, Storm 1,5 M$, Cyclone 80 M$, Hurricane 4 Md$, Tempest 220 Md$, Supernova Vortex 11 T$. Dans le courant d'air de SA soufflerie, il flotte sur place (Saut tenu = monter plus haut) et gagne de l'XP chaque seconde, même AFK : 2, 8, 30, 150, 800, 5 000, 30 000 XP/s. Les autres joueurs ne peuvent pas s'en servir et ne voient pas l'invite.
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

### (Ancien) Oxygène et caissons de pression

C'est l'équivalent des tapis de course des simulateurs : l'oxygène se farme, il ne s'achète pas.

- ✅ L'**oxygène max** est le temps qu'on tient hors du couloir. La Combinaison ouvre les anneaux, l'oxygène permet d'y rester : il faut les deux pour avancer.
- ✅ On l'entraîne dans un **caisson de pression**. L'oxygène max monte tant qu'on reste dedans, même en AFK.
  - **Caisson de base** dans chaque base : sans risque, +1 s toutes les 3 minutes.
  - **Caissons des relais de pression**, un par relais : ×2, ×3, ×5, ×8, ×12, ×20 selon l'anneau.
- ✅ Dans les anneaux 5 à 7, les relais ne protègent pas des monstres : farmer loin rapporte beaucoup, mais c'est risqué.
- ✅ **Rendements décroissants** : la vitesse est divisée par (1 + oxygène / 60), pour que la statistique ne s'envole pas.
- ✅ **Courbe visée** : on part avec 15 s et il faut environ 180 s pour le Nid. Ça donne environ 15 min de caisson pour l'anneau 2, environ 1 h 30 au total pour l'anneau 4, et **environ 10 h au total pour l'anneau 7**.
- ✅ La Supernova remet l'oxygène max à zéro.
- 💡 Tous les chiffres vont dans `Config.lua` et se règlent en jeu.

## 13. Dangers

- ✅ **Le Vide** vide la jauge d'oxygène, plus vite dans les anneaux lointains. Il n'y a **qu'une seule jauge**, et sa taille dépend de l'entraînement en caisson. À zéro, le joueur perd des PV, puis revient au vaisseau avec une soute vide.
- ✅ **Les monstres** vivent dans les anneaux 5, 6 et 7, sur les astéroïdes et dans le couloir, jamais dans le Vide. Leur façon de repérer le joueur dépend de l'anneau :
  - anneau 5 : **le bruit** (forer, courir, utiliser le jetpack remplit une jauge de bruit) ;
  - anneau 6 : **le vol de ses œufs** (forer l'astéroïde qu'il garde le réveille) ;
  - anneau 7 : 💡 les deux.
- ✅ Un monstre réveillé **poursuit le joueur jusqu'à sa base**. S'il l'attrape, le joueur perd la moitié de sa soute et revient au vaisseau. Atteindre sa base le sauve.
- ✅ Mourir, ou tomber dans le Vide, ramène au vaisseau avec une soute vide.

## 14. Événements

| Événement | Fréquence | Effet |
| --- | --- | --- |
| Astéroïde spécial (doré, cristallin, colossal) | Plusieurs fois par heure | Annoncé à tout le serveur |
| Épave d'ancien foreur | Rare | Contient une relique |
| Pluie de météores | Toutes les 20 min, pendant 3 min | Défilement plus rapide, +50 % d'œufs |
| Comète de Noël | Toutes les 60 min | Tout le serveur la fore ensemble |
| Réveil des monstres | Rare | 2 min de chaos dans les anneaux 5 à 7, butin doublé |

## 15. Progression à long terme

- ✅ **Index** des créatures : compléter un anneau donne un bonus de chance permanent.
- ✅ **Supernova** (rebirth), **dès la sortie** : tout repart à zéro sauf l'index, les créatures et les reliques, avec +50 % de $ pour toujours.

## 16. Fidélisation (tout est prévu dès la sortie)

- ✅ **La première minute** est la priorité : le joueur ne doit ni s'ennuyer ni se demander quoi faire. Il n'y a **pas de cinématique**, on joue tout de suite. Une flèche au sol et des bulles de texte très courtes guident les premières actions : sortir, forer, rentrer, casser. 💡 Un astéroïde facile arrive pile au bon moment, et le premier œuf donne à coup sûr une créature.
- ✅ Une récompense de connexion quotidienne, sur 7 jours qui reprennent au début.
- ✅ 3 quêtes du jour.
- ✅ Des cadeaux à 5, 15, 30 et 60 minutes de jeu.
- ✅ Des codes promo, et +10 % de chance pour les membres du groupe Roblox.

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
| Pluie de météores pour tout le serveur | ✅ Produit |

## 19. Interface

- ✅ Le MVP a déjà le HUD ($, soute, carburant), la boutique et l'écran de révélation.
- 💡 À ajouter : jauge de combinaison, jauge de bruit, inventaire et fusion des créatures, index, quêtes, récompenses, boutique Robux, réglages (son, qualité).

## 20. Son et ambiance

- 💡 Une musique par lieu (vaisseau, couloir, Vide, monstres) et un bruitage par rareté à la casse.
- 💡 Bruitages de la foreuse et du jetpack, et une alarme quand la combinaison faiblit.

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
