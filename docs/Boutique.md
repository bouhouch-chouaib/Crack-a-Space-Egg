# Refonte des boutiques (7 nov.)

Recherche faite avant la refonte : boutiques des jeux à succès (Pet Simulator 99, Grow a Garden,
Steal a Brainrot, Break and Steal an Egg, Bee Swarm, Dig It, Blade Ball…) et règles officielles de
Roblox (Creator Hub, DevForum). Les sources sont listées en bas.

## Ce qu'on retient

### Deux boutiques, deux monnaies, jamais mélangées
- **Robux = une fenêtre ouverte par un bouton fixe du HUD**, accessible partout (Grow a Garden,
  Steal a Brainrot, Break and Steal an Egg : bouton à gauche).
- **Monnaie du jeu ($) = un stand dans le monde** (Seed Shop de Grow a Garden, marchand de Steal a
  Brainrot, boutique de pioches de Break and Steal an Egg dans la zone sûre). Chez nous : le stand
  Shop du vaisseau devient l'**atelier des foreuses**.

### Ce qui fait une boutique « propre » (retours DevForum)
- Une seule famille de police, un seul style d'icône, de l'air autour des icônes (pas collées au bord).
- Titre en gras au-dessus, texte jamais posé sur l'image, le bouton d'achat plus visible que les stats.
- Contour (UIStroke) d'une teinte plus foncée que le fond, pas noir ; dégradé plus clair en haut ;
  coins arrondis ~12 px.
- Le premier article (vedette) en grand, les suivants plus petits. Rayons et étincelles réservés à la
  vedette : trop de mouvement brouille (Roblox, page UI/UX).
- Ouverture « pop » 0,9 → 1 en 0,2 s, survol 1,05, clic 0,95, un son discret.
- Bouton fermer : carré rouge, X blanc, en haut à droite, partout le même.
- Prix en rouge si on n'a pas assez, bouton grisé si inutilisable, cadenas pour ce qui est verrouillé.
- Mobile : tailles relatives, zones tactiles ≥ 44 px, texte ≥ 9 px, rien dans les coins bas
  (joystick et saut), marges de sécurité (ScreenInsets).

### Règles Roblox obligatoires
- **Aucun prix Robux écrit en dur** : on lit le prix de chaque passe et produit au moment de
  l'affichage (`MarketplaceService:GetProductInfoAsync`), car Roblox peut ajuster les prix (prix
  régionaux, optimisation). Pendant le chargement « … », en cas d'erreur « Unavailable ».
  Pas de « −50 % » calculé à partir d'un prix supposé.
- Une demande d'achat seulement après un clic du joueur.
- Passes : vérifier qu'on le possède avant de proposer l'achat (« OWNED »).
- Produits : tout s'accorde côté serveur dans `ProcessReceipt` (déjà le cas).
- Pas de tirage au sort payé sans afficher les chances (on n'en vend pas : nos œufs ne s'achètent pas).
- Offres limitées honnêtes : vraie fin, sauvegardée (sinon le minuteur repart à chaque serveur).

### Ce qui fait vendre (sans tromper)
- **Pack de départ** (guide officiel « Starter pack design », +2 à 10 % de revenus) : visible dès
  l'arrivée, un seul achat, fenêtre de 24 h à 3 jours sauvegardée, 2 à 5 articles dont un cosmétique
  exclusif, 99 à 299 R$.
- Gros paquet d'argent plus grand, avec « BEST VALUE » ; rubans sur 1 ou 2 cartes au plus.
- Expliquer ce que fait chaque article ; après l'achat d'un passe, proposer le complémentaire.
- Pastille rouge sur le bouton quand il y a du nouveau.

### Boutiques d'équipement et skins
- Liste des outils à gauche (4 à 6 visibles), **détail à droite** : aperçu 3D qui tourne, rayons
  derrière, stats « actuel → suivant » avec le gain en vert (+35 %).
- Un seul bouton qui change d'état : **verrouillé** (cadenas + condition), **acheter** ($ vert ou
  rouge), **équiper**, **équipé** (grisé + coche).
- **Skins dans un onglet séparé**, qui ne changent que l'apparence (Blade Ball) ; cadre à la couleur de
  la rareté ; possédés en premier ; le skin s'équipe indépendamment de la foreuse.
- Performance : un seul aperçu 3D (l'article sélectionné), des images figées dans la liste.

## Plan de la refonte

### 1. STORE (Robux) — bouton du HUD, à gauche, avec l'icône Robux
Fenêtre large, menu de catégories à gauche qui fait défiler jusqu'à la section :
1. **Vedette** pleine largeur : Starter Pack avec son contenu en icônes et son vrai compte à rebours.
2. **Passes** (permanents) : cartes avec icône, nom, effet en une ligne, bouton prix vert ou « OWNED ».
3. **Cash** : 5 paquets, le plus gros plus grand avec « BEST VALUE ».
4. **Boosts** : potions de 15 min, avec le temps restant si elles sont actives.
Les sections « Coming soon » disparaissent. Tous les prix sont lus sur Roblox.

### 2. Atelier des foreuses ($) — le stand Shop du vaisseau
Trois onglets :
- **DRILLS** : les 11 foreuses en liste, détail à droite (aperçu 3D, puissance actuelle → suivante,
  prix en $, achat aussi possible en Robux avec le petit bouton existant).
- **SKINS** : apparences de foreuse (couleurs et matières), qui se gardent quand on change de foreuse.
- **UPGRADES** : le scanner (chance).

### 3. Style commun (UIKit)
Une police de titres (Fredoka One) et une pour les petits textes (Builder Sans), cartes et boutons
refaits selon les règles ci-dessus, fenêtres plus aérées.

## Fait (7 nov.)
- ✅ STORE et atelier des foreuses séparés, comme prévu ci-dessus ; ancien `Shop.client.lua` supprimé.
- ✅ Prix Robux lus sur Roblox, « OWNED », Starter Pack honnête (3 jours, un seul achat), rubans retirés sauf « BEST VALUE! ».
- ✅ Skins : 9 en $ et 3 en passes Robux (Galaxy, Rainbow, Supernova), créés sur Roblox avec leur icône.
- ✅ Skins de base : 3 passes Robux (Galaxy 199, Gold 299, Rainbow 399), créés sur Roblox avec leur icône (`tools/store-icons/baseskin_*.png`).

## Sources
- Monetization foundations : https://create.roblox.com/docs/production/game-design/monetization-foundations
- Starter pack design : https://create.roblox.com/docs/production/game-design/starter-pack-design
- UI and UX design : https://create.roblox.com/docs/production/game-design/ui-ux-design
- Contextual purchases : https://create.roblox.com/docs/production/game-design/contextual-purchases
- Managed pricing : https://create.roblox.com/docs/production/monetization/managed-pricing
- Game passes : https://create.roblox.com/docs/production/monetization/game-passes
- Developer products : https://create.roblox.com/docs/production/monetization/developer-products
- Paid random items : https://create.roblox.com/docs/production/monetization/paid-random-items
- Polices (Builder Sans, fin de Gotham) : https://devforum.roblox.com/t/introducing-builder-font-deprecating-gotham-and-arial/2868222
- Retours DevForum sur les boutiques : https://devforum.roblox.com/t/cant-get-my-shop-ui-to-look-good/3810143 ,
  https://devforum.roblox.com/t/how-can-i-make-my-shop-ui-better/3293954 ,
  https://devforum.roblox.com/t/feedback-on-shop-ui/1885845 , https://devforum.roblox.com/t/ui-design-guide/2975811
- Aperçus 3D et performance : https://devforum.roblox.com/t/viewportframe-performance-issues-for-displaying-items/1798310
- Pet Simulator 99 (sections de la boutique) : https://www.u7buy.com/blog/pet-simulator-99-exclusive-shop-guide/
- Grow a Garden (bouton Shop, offres limitées) : https://www.pcgamer.com/games/survival-crafting/grow-a-garden-better-seeds ,
  https://rblxguide.com/games/grow-a-garden/updates/grow-a-garden-limited-time-shop-guide
- Steal a Brainrot (marchand) : https://techwiser.com/steal-a-brainrot-dealer-how-use-guide/
- Break and Steal an Egg (Shop à gauche) : https://progameguides.com/roblox/how-to-claim-the-sabertooth-egg-in-break-and-steal-an-egg/
- Dig It (stats des pelles) : https://beebom.com/dig-shovel-stats-explained
- Blade Ball (skins) : https://www.gfinityesports.com/article/blade-ball-rainbow-explosion
