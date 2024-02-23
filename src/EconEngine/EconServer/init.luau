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
local EconTypes = require(script.EconTypes)
local Private_EconData = require(script.Private_EconData)

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
	PlayerJoined = e_PlayerJoined,
	PlayerLeaving = e_PlayerLeaving,
}

export type EconData = {
	GetProfile: (Player) -> Private_EconData.Profile?,
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
	Data: Private_EconData.EconDataInternal,
	RunBeforePlayerLeaves: (Player) -> ()?,
}

local EconServer: EconServer = {
	Events = CometEvents,
	Methods = {},
	Data = Private_EconData.new(CometEvents),
}

local PassProductHandler = require(script.Private_PassProductHandler).new(EconServer.Data, CometEvents)

function setup()
	Players.PlayerAdded:Connect(function(plr)
		EconServer.Data:_onPlayerAdded(plr)
		local profile = EconServer.Data.GetProfile(plr)
		if profile then
			PassProductHandler.CheckIfPlayerOwnsPasses(plr, profile)
		end
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if EconServer.RunBeforePlayerLeaves ~= nil and typeof(EconServer.RunBeforePlayerLeaves) == "function" then
			EconServer.RunBeforePlayerLeaves(plr)
		end
		EconServer.Data:_onPlayerRemoving(plr)
	end)
	return EconServer
end

return setup
