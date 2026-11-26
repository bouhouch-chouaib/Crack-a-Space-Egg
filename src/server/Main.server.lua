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
local CarryService = require(script.Parent.CarryService)
local BoostService = require(script.Parent.BoostService)
local WindTunnelService = require(script.Parent.WindTunnelService)
local ColdService = require(script.Parent.ColdService)
local CreatureService = require(script.Parent.CreatureService)
local MonsterService = require(script.Parent.MonsterService)
local SkinService = require(script.Parent.SkinService)
local BaseSkinService = require(script.Parent.BaseSkinService)
local PenService = require(script.Parent.PenService)
local SuitService = require(script.Parent.SuitService)
local GearService = require(script.Parent.GearService)
local RelicService = require(script.Parent.RelicService)
local AnnounceService = require(script.Parent.AnnounceService)
local RewardService = require(script.Parent.RewardService)

WorldBuilder.Build()
Bases.Start()
BeltService.Start()
BoostService.Start() -- passes et potions (avant le chargement des parties)
GameService.Start() -- branche DataService.Loaded avant que les parties se chargent
HatchService.Start() -- idem : reconstruit les œufs et créatures de la base au chargement
PenService.Start() -- enclos agrandi : met la base à son niveau avant que HatchService y repose tout
DataService.Start()
LeaderboardService.Start()
MonetizationService.Start()
RewardService.Start() -- connexion quotidienne, temps de jeu, quêtes, codes, groupe, pub
MonetizationService.AdReward = RewardService.GrantAdBoost
MachineService.Start()
CarryService.Start() -- la roche dans les mains du joueur tant qu'il la rapporte à sa base
WindTunnelService.Start() -- souffleries : on y farme le niveau du jetpack
ColdService.Start() -- gel et manque d'oxygène hors du couloir
CreatureService.Start() -- sac, vente au Trading Post, fusion
MonsterService.Start() -- un monstre par anneau (3 à 14) : promenade dans le couloir, poursuite au vol d'œuf
SkinService.Start() -- skins de foreuse (atelier des foreuses)
BaseSkinService.Start() -- skins de base (anneau atteint ou passes Robux)
SuitService.Start() -- combinaisons : plus de temps hors du couloir, plus d'oxygène
GearService.Start() -- objets : batte, tapis volant, bottes, grappin, bouclier
RelicService.Start() -- reliques des explorateurs perdus
AnnounceService.Start() -- messages des trouvailles rares, sur tous les serveurs pour les plus grandes
