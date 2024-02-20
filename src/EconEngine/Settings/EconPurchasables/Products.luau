local Template = require(script.Parent.Parent.EconDataTemplate.Template)
--[[
	* Setup your products according to the template:

	[0] = function(player, profile)
		-- do something
	end,
]]

return {
	[0] = function(player: Player, profile: typeof(Template))
		--print("got purchase")
		-- do something
	end,
}
