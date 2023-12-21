local Comet = require(script.Parent.Comet)

--[[
	Undefined profile table type for type referencing
]]
export type abstractProfile = { Data: { [string]: any } }
export type GamepassGranted = { Player? | abstractProfile? | number? }
export type PlayerDataLoaded = { Player? | abstractProfile? }
export type Events = {
	GamepassGranted: Comet.Comet<GamepassGranted>,
	PlayerDataLoaded: Comet.Comet<PlayerDataLoaded>,
}

export type EconEvent<T> = {
	Connect: (self: Comet.Comet<T>, callback: (value: T, ...any) -> any, on_disconnect: (() -> ())?) -> () -> (),
	get: (self: Comet.Comet<T>) -> T,
}

return nil
