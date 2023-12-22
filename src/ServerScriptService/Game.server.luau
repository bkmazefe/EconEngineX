local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconEngine = require(ReplicatedStorage.EconEngine)

EconEngine.Server.Events.PlayerDataLoaded:Connect(function(player, profile)
	print(player)
	print(profile)
end)
