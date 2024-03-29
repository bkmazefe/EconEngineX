local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Passes = require(script.Parent.Parent.Settings.EconPurchasables.Passes)
local Products = require(script.Parent.Parent.Settings.EconPurchasables.Products)
local Promise = require(script.Parent.Parent.Parent.Promise)
local EconTypes = require(script.Parent.EconTypes)
local Private_EconData = require(script.Parent.Private_EconData)

local PassProductHandler = {}
PassProductHandler.__index = PassProductHandler
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

function PassProductHandler.new(
	EconData: Private_EconData.EconDataInternal?,
	Events: EconTypes.Events?
): PassProductHandler
	local self = setmetatable({}, PassProductHandler)
	self.Data = EconData
	self.Events = Events
	return self
end

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

function PassProductHandler.GetPlayerProfileAsync(self: PassProductHandler, player: Player) --> [Profile] / nil
	-- Yields until a Profile linked to a player is loaded or the player leaves
	local profile = self.Data.GetProfile(player)
	while profile == nil and player:IsDescendantOf(Players) == true do
		task.wait()
		profile = self.Data.GetProfile(player)
	end
	return profile
end

function PassProductHandler.GrantProduct(self: PassProductHandler, player: Player, product_id: number)
	-- We shouldn't yield during the product granting process!
	local profile = self.Data.GetProfile(player)
	local product_function = SETTINGS.Products[product_id]
	if product_function ~= nil then
		product_function(player, profile)
	else
		warn("ProductId " .. tostring(product_id) .. " has not been defined in Products table")
	end
end

function PassProductHandler.ProcessReceipt(self: PassProductHandler, receipt_info)
	local player = Players:GetPlayerByUserId(receipt_info.PlayerId)

	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = self:GetPlayerProfileAsync(player)

	if profile ~= nil then
		return PurchaseIdCheckAsync(profile, receipt_info.PurchaseId, function()
			self:GrantProduct(player, receipt_info.ProductId)
			self.Events.ProductGranted:set({ player, profile, receipt_info.ProductId })
		end)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function PassProductHandler.CheckIfPlayerOwnsPasses(plr: Player, profile: Private_EconData.Profile)
	for id, f in SETTINGS.GamePasses do
		Promise.new(function(resolve)
			resolve(MarketplaceService:UserOwnsGamePassAsync(plr.UserId, id))
		end)
			:catch(function(msg)
				warn(msg)
			end)
			:andThen(function(body)
				if body == true then
					f(plr, profile)
				end
			end)
	end
end

function PassProductHandler.GamePassPurchaseFinished(
	self: PassProductHandler,
	player: Player,
	gamepassId: number,
	wasPurchased: boolean
)
	if not wasPurchased then
		return
	end

	local profile = self.Data.GetProfile(player)
	if not profile then
		return
	end

	local gamepass_function: (Player, Private_EconData.Profile) -> () = SETTINGS.GamePasses[gamepassId]
	if gamepass_function ~= nil then
		gamepass_function(player, profile)
		self.Events.GamepassGranted:set({ player, profile, gamepassId })
	end
	return
end

export type PassProductHandler = typeof(PassProductHandler.new())
return PassProductHandler
