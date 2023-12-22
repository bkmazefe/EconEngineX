--# EconEngine #--

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local isServer = RunService:IsServer()

local EconEngine = {}

if isServer == true then
	local EconServer = require(ServerScriptService.EconServer)
	EconEngine.Server = EconServer
end

--[[
	--TODO:
	Add the RemoteEvent Handler (Probe) and any other function that may needed
	to be called from the client.
]]

return EconEngine :: typeof(EconEngine)
