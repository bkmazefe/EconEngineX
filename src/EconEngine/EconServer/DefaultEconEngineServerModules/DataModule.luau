local EconEngine = require(script.Parent.Parent.Parent)
local Template = require(script.Parent.Parent.Parent.Settings.EconDataTemplate.Template)

local DataModule = {}

export type Profile = { Data: typeof(Template) }
---------
type SetMoney = (plr: Player, amount: number) -> () & (profile: Profile, amount: number) -> ()
local SetMoney: SetMoney = function(subject, amount)
	if typeof(subject) == "Player" then
		EconEngine.Server.Data.GetProfile(subject)
	end
	if not subject or typeof(subject) ~= "table" then
		return
	end
	subject.Data.Money = amount
end
DataModule.SetMoney = SetMoney

type GetMoney = (plr: Player) -> number & (profile: Profile) -> number
local GetMoney = function(subject)
	if typeof(subject) == "Player" then
		EconEngine.Server.Data.GetProfile(subject)
	end
	if not subject or typeof(subject) ~= "table" then
		return
	end
	return subject.Data.Money
end
DataModule.GetMoney = GetMoney
---------

return DataModule
