-- Point d'entrée du serveur : construit la carte puis démarre les services dans l'ordre.

local WorldBuilder = require(script.Parent.WorldBuilder)
local GameService = require(script.Parent.GameService)
local DataService = require(script.Parent.DataService)

WorldBuilder.Build()
GameService.Start() -- branche DataService.Loaded avant que les parties se chargent
DataService.Start()
