--# EconEngine #--

local RunService = game:GetService("RunService")
local isServer = RunService:IsServer()

local EconTypes = require(script.EconServer.EconTypes)
local EconEngine = {}

if isServer == true then
	local EconServer = require(script.EconServer)
	EconEngine.Server = EconServer :: Server

	export type Data = EconServer.EconData
	export type Server = {
		Events: {
			GamepassGranted: EconTypes.EconEvent<EconTypes.GamepassGranted>,
			ProductGranted: EconTypes.EconEvent<EconTypes.ProductGranted>,
			PlayerDataLoaded: EconTypes.EconEvent<EconTypes.PlayerDataLoaded>,
			PlayerJoined: EconTypes.EconEvent<EconTypes.PlayerJoined>,
			PlayerLeaving: EconTypes.EconEvent<EconTypes.PlayerLeaving>,
		},
		Methods: { [string]: (...any) -> ...any },
		Data: Data,
	}
else
	script.EconServer:Destroy()
end

--[[
	--TODO:
	Add the RemoteEvent Handler (Probe) and any other function that may needed
	to be called from the client.
	Add Probe
]]
export type EconEngine = typeof(EconEngine)

return EconEngine :: EconEngine
