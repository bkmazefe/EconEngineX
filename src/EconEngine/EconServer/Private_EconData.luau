--[[
	WARNING! This module is not meant to be used directly!
	Refer to this module by requiring EconEngine itself!
]]

local Players = game:GetService("Players")
local _MarketplaceService = game:GetService("MarketplaceService")

local EconTypes = require(script.Parent.EconTypes)
local ProfileService = require(script.Parent.Parent.Parent.ProfileService)
local Template = require(script.Parent.Parent.Settings.EconDataTemplate.Template)
local EconEngineSettings = require(script.Parent.Parent.Settings.EconEngineSettings)

--[[
	List of profiles
	Profiles: { [Player]: Profile? }
]]
local Profiles: { [Player]: Profile? } = {}
--[[
	Data template
]]
local ProfileStore = ProfileService.GetProfileStore(EconEngineSettings.DataStoreName, Template)

export type Profile = {
	Data: typeof(Template),
}

type dataM = {
	Events: EconTypes.Events,
	Profiles: { [Player]: Profile? },
}

local EconData = {}
EconData.__index = EconData
------------------------------------** Local Defaults
--local max_stores = 1

------------------------------------** Private methods
local function DeepCopy(t: { any }): { any }
	local copy = {}

	for i, v in t do
		if type(v) == "table" then
			copy[i] = DeepCopy(v)
		else
			copy[i] = v
		end
	end

	return copy
end
------------------------------------** Public methods
--[[
	Get the profile of a player
	@param player: Player
	@return Profile?
]]
function EconData.GetProfile(player: Player): Profile?
	return Profiles[player]
end
--[[
	Initialize and setup an EconData object
]]
function EconData.new(events: EconTypes.Events?): EconDataInternal
	local self = setmetatable({
		Events = events,
		Profiles = {},
	}, EconData)

	return self
end

------------------------------------** Secure methods
function EconData._onPlayerAdded(self: EconDataInternal, player: Player) --Set up the profile for the player joined
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			Profiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick()
		end)

		if player:IsDescendantOf(Players) == true then
			Profiles[player] = profile
			-- A profile has been successfully loaded:
			self.Events.PlayerDataLoaded:set({ player, profile })
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		-- Roblox servers trying to load this profile at the same time:
		player:Kick()
	end
end

function EconData._onPlayerRemoving(self: EconDataInternal, player: Player)
	self.Events.PlayerLeaving:set(player)
	if self.Events.PlayerJoined:get() == player then
		self.Events.PlayerJoined:set(nil)
	end
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

export type EconDataInternal = typeof(setmetatable({} :: dataM, EconData))
return EconData
