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

type EconServer = {
	Events: { [string]: EconTypes.EconEvent<any> },
	Methods: { [string]: (...any) -> ...any },
}
--[[
	returns (player, profile)
]]
local e_GamepassGranted = Comet({ nil, nil, 0 })
local e_PlayerDataLoaded = Comet({ nil, nil })

local CometEvents = {
	GamepassGranted = e_GamepassGranted,
	PlayerDataLoaded = e_PlayerDataLoaded,
}

local Modules = {
	DataModule = DataModule,
	PassProductHandler = PassProductHandler,
}

local EconServer: EconServer = {
	Events = {},
	Methods = {},
}

--[[
	Initialize every EconServer module to setup their fireable and,
	connectable events
]]
for _, v in Modules do
	v._init(CometEvents)
	for i, x in v.Pub do
		EconServer.Methods[i] = x
	end
end

EconServer.Events.GamepassGranted = e_GamepassGranted :: EconTypes.EconEvent<EconTypes.GamepassGranted>
EconServer.Events.PlayerDataLoaded = e_PlayerDataLoaded :: EconTypes.EconEvent<EconTypes.PlayerDataLoaded>

Players.PlayerAdded:Connect(function(plr)
	DataModule.Secure.onPlayerAdded(plr)
	local profile = DataModule.Pub.GetProfile(plr)
	if profile then
		PassProductHandler.Secure.checkIfPlayerOwnsPasses(plr, profile)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	DataModule.Secure.onPlayerRemoving(plr)
end)

return EconServer
