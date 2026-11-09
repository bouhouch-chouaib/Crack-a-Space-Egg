-- Point d'entrée du serveur : construit la carte puis démarre les services dans l'ordre.

local WorldBuilder = require(script.Parent.WorldBuilder)
local Bases = require(script.Parent.Bases)
local BeltService = require(script.Parent.BeltService)
local GameService = require(script.Parent.GameService)
local DataService = require(script.Parent.DataService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local MonetizationService = require(script.Parent.MonetizationService)
local MachineService = require(script.Parent.MachineService)
local HatchService = require(script.Parent.HatchService)
local BoostService = require(script.Parent.BoostService)
local WindTunnelService = require(script.Parent.WindTunnelService)
local ColdService = require(script.Parent.ColdService)
local CreatureService = require(script.Parent.CreatureService)
local MonsterService = require(script.Parent.MonsterService)
local SkinService = require(script.Parent.SkinService)
local BaseSkinService = require(script.Parent.BaseSkinService)
local SuitService = require(script.Parent.SuitService)
local GearService = require(script.Parent.GearService)
local RelicService = require(script.Parent.RelicService)
local RewardService = require(script.Parent.RewardService)
local GemService = require(script.Parent.GemService)
local SupernovaService = require(script.Parent.SupernovaService)
local FeedbackService = require(script.Parent.FeedbackService)

WorldBuilder.Build()
Bases.Start()
BeltService.Start()
BoostService.Start() -- passes et potions (avant le chargement des parties)
GameService.Start() -- branche DataService.Loaded avant que les parties se chargent
HatchService.Start() -- idem : reconstruit les œufs et créatures de la base au chargement
DataService.Start()
LeaderboardService.Start()
MonetizationService.Start()
RewardService.Start() -- connexion quotidienne, temps de jeu, quêtes, codes, groupe, pub
MonetizationService.AdReward = RewardService.GrantAdBoost
GemService.Start() -- sac de minerais et vente au stand SELL
SupernovaService.Start() -- renaissance : tout recommence, +50 % de revenus pour toujours
FeedbackService.Start() -- boîte à retours des joueurs
MachineService.Start()
WindTunnelService.Start() -- souffleries : on y farme le niveau du jetpack
ColdService.Start() -- gel et manque d'oxygène hors du couloir
CreatureService.Start() -- sac, vente au Trading Post, fusion
MonsterService.Start() -- monstres des anneaux 5 à 7 (bruit, gardiens, poursuites)
SkinService.Start() -- skins de foreuse (atelier des foreuses)
BaseSkinService.Start() -- skins de base (Supernovas ou passes Robux)
SuitService.Start() -- combinaisons : plus de temps hors du couloir, plus d'oxygène
GearService.Start() -- objets : batte, tapis volant, bottes, grappin, bouclier
RelicService.Start() -- reliques des explorateurs perdus
