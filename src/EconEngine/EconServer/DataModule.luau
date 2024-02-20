--local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local _MarketplaceService = game:GetService("MarketplaceService")

local EconTypes = require(script.Parent.EconTypes)
local ProfileService = require(script.Parent.Parent.Parent.ProfileService)
local Template = require(script.Parent.Parent.Settings.EconDataTemplate.Template)

-- Data structures and server profile maintaining
local Profiles: { [Player]: profile? } = {}
local data = Template
local ProfileStore = ProfileService.GetProfileStore("PlayerData", data)

local DataModule = {
	Secure = {},
	Pub = {},
}

local Events: EconTypes.Events

DataModule.Pub.GetProfile = function(player: Player): profile?
	return Profiles[player]
end

export type profile = {
	Data: typeof(data),
}

------------------------------------** Local Defaults
--local max_stores = 1

------------------------------------** Private methods
--* Set up the leaderboard entry
local function replicateLoadedDataToServer(player: Player, profile: profile) --Replicate values to client and show server
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
end

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

------------------------------------** Global methods
function DataModule.Secure.onPlayerAdded(player: Player) --Set up the profile for the player joined
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
			replicateLoadedDataToServer(player, profile)
			print("update ready")
			Events.PlayerDataLoaded:set({ player, profile })
		else
			-- Player left before the profile loaded:
			profile:Release()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick()
	end
end

function DataModule.Secure.onPlayerRemoving(player)
	Events.PlayerLeaving:set(player)
	if Events.PlayerJoined:get() == player then
		Events.PlayerJoined:set(nil)
	end
	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
	end
end

DataModule._init = function(t)
	Events = t
end

return DataModule
