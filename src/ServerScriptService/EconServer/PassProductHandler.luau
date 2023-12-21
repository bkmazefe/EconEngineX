local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataModule = require(script.Parent.DataModule)
local Passes = require(ServerScriptService.EconPurchasables.Passes)
local Products = require(ServerScriptService.EconPurchasables.Products)
local Promise = require(ReplicatedStorage.Packages.Promise)
local EconTypes = require(script.Parent.EconTypes)

local Events: EconTypes.Events

local PassProductHandler = {
	Secure = {},
	Pub = {},
}
------------------------------------** Purchase handling
-- Data store for tracking purchases that were successfully processed
local SETTINGS = {
	Products = Products,
	GamePasses = Passes,

	PurchaseIdLog = 50, -- Store this amount of purchase id's in MetaTags;
	-- This value must be reasonably big enough so the player would not be able
	-- to purchase products faster than individual purchases can be confirmed.
	-- Anything beyond 30 should be good enough.
}

local function PurchaseIdCheckAsync(profile, purchase_id, grant_product_callback) --> Enum.ProductPurchaseDecision
	-- Yields until the purchase_id is confirmed to be saved to the profile or the profile is released

	if profile:IsActive() ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	else
		local meta_data = profile.MetaData

		local local_purchase_ids = meta_data.MetaTags.ProfilePurchaseIds
		if local_purchase_ids == nil then
			local_purchase_ids = {}
			meta_data.MetaTags.ProfilePurchaseIds = local_purchase_ids
		end

		-- Granting product if not received:

		if table.find(local_purchase_ids, purchase_id) == nil then
			while #local_purchase_ids >= SETTINGS.PurchaseIdLog do
				table.remove(local_purchase_ids, 1)
			end
			table.insert(local_purchase_ids, purchase_id)
			task.spawn(grant_product_callback)
		end

		-- Waiting until the purchase is confirmed to be saved:

		local result = nil

		local function check_latest_meta_tags()
			local saved_purchase_ids = meta_data.MetaTagsLatest.ProfilePurchaseIds
			if saved_purchase_ids ~= nil and table.find(saved_purchase_ids, purchase_id) ~= nil then
				result = Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end

		check_latest_meta_tags()

		local meta_tags_connection = profile.MetaTagsUpdated:Connect(function()
			check_latest_meta_tags()
			-- When MetaTagsUpdated fires after profile release:
			if profile:IsActive() == false and result == nil then
				result = Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end)

		while result == nil do
			task.wait()
		end

		meta_tags_connection:Disconnect()

		return result
	end
end

local function GetPlayerProfileAsync(player: Player) --> [Profile] / nil
	-- Yields until a Profile linked to a player is loaded or the player leaves
	local profile = DataModule.Pub.GetProfile(player)
	while profile == nil and player:IsDescendantOf(Players) == true do
		task.wait()
		profile = DataModule.Pub.GetProfile(player)
	end
	return profile
end

local function GrantProduct(player: Player, product_id: number)
	-- We shouldn't yield during the product granting process!
	local profile = DataModule.Pub.GetProfile(player)
	local product_function = SETTINGS.Products[product_id]
	if product_function ~= nil then
		product_function(player, profile)
	else
		warn("ProductId " .. tostring(product_id) .. " has not been defined in Products table")
	end
end

function PassProductHandler.Secure.ProcessReceipt(receipt_info)
	local player = Players:GetPlayerByUserId(receipt_info.PlayerId)

	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = GetPlayerProfileAsync(player)

	if profile ~= nil then
		return PurchaseIdCheckAsync(profile, receipt_info.PurchaseId, function()
			GrantProduct(player, receipt_info.ProductId)
		end)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function PassProductHandler.Secure.checkIfPlayerOwnsPasses(plr: Player, profile: DataModule.profile)
	for id, f in SETTINGS.GamePasses do
		Promise.new(function(resolve)
			resolve(MarketplaceService:UserOwnsGamePassAsync(plr.UserId, id))
		end):andThen(function(body)
			if body == true then
				f(plr, profile)
			end
		end)
	end
end

function PassProductHandler.Secure.GamePassPurchaseFinished(player: Player, gamepassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end

	local profile = DataModule.Pub.GetProfile(player)
	if not profile then
		return
	end

	local gamepass_function: (Player, DataModule.profile) -> () = SETTINGS.GamePasses[gamepassId]
	if gamepass_function ~= nil then
		gamepass_function(player, profile)
		Events.GamepassGranted:set({ player, profile, gamepassId })
	end
	return
end

PassProductHandler._init = function(t)
	Events = t
end
return PassProductHandler
