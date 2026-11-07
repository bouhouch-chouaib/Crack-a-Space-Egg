-- Point d'entrée du serveur : construit la carte puis démarre les services dans l'ordre.

local WorldBuilder = require(script.Parent.WorldBuilder)
local Bases = require(script.Parent.Bases)
local EventService = require(script.Parent.EventService)
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

WorldBuilder.Build()
Bases.Start()
EventService.Start()
BeltService.Start()
BoostService.Start() -- passes et potions (avant le chargement des parties)
GameService.Start() -- branche DataService.Loaded avant que les parties se chargent
HatchService.Start() -- idem : reconstruit les œufs et créatures de la base au chargement
DataService.Start()
LeaderboardService.Start()
MonetizationService.Start()
MachineService.Start()
WindTunnelService.Start() -- souffleries : on y farme le niveau du jetpack
ColdService.Start() -- gel et manque d'oxygène hors du couloir
CreatureService.Start() -- sac, vente au Trading Post, fusion
MonsterService.Start() -- monstres des anneaux 5 à 7 (bruit, gardiens, poursuites)
