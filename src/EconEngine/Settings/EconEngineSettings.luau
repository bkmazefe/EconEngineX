--[[
	Refer to the document for more info on the settings and
	what they are for.
]]

local SETTINGS = {
	--[[
		Changing this will make the EconEngine start saving/loading data from a different DataStore.
		Meaning your players will have a fresh start.
	]]
	DataStoreName = "PlayerData",
	Serialize_Data_Values = false,
}

return SETTINGS :: typeof(SETTINGS)
