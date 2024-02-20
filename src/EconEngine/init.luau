--# EconEngine #--

local RunService = game:GetService("RunService")
local isServer = RunService:IsServer()

local EconEngine = {}

if isServer == true then
	local EconServer = require(script.EconServer)
	EconEngine.Server = EconServer
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
