--# EconEngine: Server Setup #--
--[[
	* Do NOT change anything unless you know what you are doing!
	
	This engine was built in a way to make sure you don't have to change anything.
	
	If you find yourself having to change something in the EconServer
	module or any of its components, I highly suggest you to read the documentary.
	
	If it is a bug that you are trying to fix within the engine, please contact @bkmazefe_ on X,
	or @bkmazefe on Discord or @bkmazefe on the DevForum.
]]
--#
local Players = game:GetService("Players")

local Comet = require(script.Comet)
local DataModule = require(script.DataModule)
local EconTypes = require(script.EconTypes)
local PassProductHandler = require(script.PassProductHandler)

--[[
	returns (player, profile)
]]
local e_GamepassGranted = Comet({ nil, nil, 0 })
local e_ProductGranted = Comet({ nil, nil, 0 })
local e_PlayerDataLoaded = Comet({ nil, nil }, true)
local e_PlayerJoined = Comet(nil)
local e_PlayerLeaving = Comet(nil)

local CometEvents = {
	GamepassGranted = e_GamepassGranted,
	ProductGranted = e_ProductGranted,
	PlayerDataLoaded = e_PlayerDataLoaded,
}

local Modules = {
	DataModule = DataModule,
	PassProductHandler = PassProductHandler,
}

export type EconServer = {
	Events: {
		GamepassGranted: EconTypes.EconEvent<EconTypes.GamepassGranted>,
		ProductGranted: EconTypes.EconEvent<EconTypes.ProductGranted>,
		PlayerDataLoaded: EconTypes.EconEvent<EconTypes.PlayerDataLoaded>,
		PlayerJoined: EconTypes.EconEvent<EconTypes.PlayerJoined>,
		PlayerLeaving: EconTypes.EconEvent<EconTypes.PlayerLeaving>,
	},
	Methods: { [string]: (...any) -> ...any },
	Data: typeof(DataModule.Pub),
	RunBeforePlayerLeaves: (Player) -> ()?,
}

local EconServer: EconServer = {
	Events = {
		GamepassGranted = e_GamepassGranted,
		ProductGranted = e_ProductGranted,
		PlayerDataLoaded = e_PlayerDataLoaded,
		PlayerJoined = e_PlayerJoined,
		PlayerLeaving = e_PlayerLeaving,
	},
	Methods = {},
	Data = DataModule.Pub,
}
for _, v in Modules do
	v._init(CometEvents)
end

--[[
	Initialize every EconServer module to setup their fireable and,
	connectable events
]]

Players.PlayerAdded:Connect(function(plr)
	DataModule.Secure.onPlayerAdded(plr)
	local profile = EconServer.Data.GetProfile(plr)
	if profile then
		PassProductHandler.Secure.checkIfPlayerOwnsPasses(plr, profile)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	if EconServer.RunBeforePlayerLeaves ~= nil then
		EconServer.RunBeforePlayerLeaves(plr)
	end
	DataModule.Secure.onPlayerRemoving(plr)
end)

return EconServer
