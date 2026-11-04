-- Point d'entrée du serveur : construit la carte puis démarre les services dans l'ordre.

local WorldBuilder = require(script.Parent.WorldBuilder)
local Bases = require(script.Parent.Bases)
local BeltService = require(script.Parent.BeltService)
local GameService = require(script.Parent.GameService)
local DataService = require(script.Parent.DataService)

WorldBuilder.Build()
Bases.Start()
BeltService.Start()
GameService.Start() -- branche DataService.Loaded avant que les parties se chargent
DataService.Start()
