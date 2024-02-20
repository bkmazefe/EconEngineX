local Comet = require(script.Parent.Comet)

--[[
	Undefined profile table type for type referencing
]]
export type abstractProfile = { Data: { [string]: any } }
export type GamepassGranted = { Player? | abstractProfile? | number? }
export type ProductGranted = { Player? | abstractProfile? | number? }
export type PlayerDataLoaded = { Player? | abstractProfile? }
export type PlayerJoined = Player?
export type PlayerLeaving = Player?
export type Events = {
	GamepassGranted: Comet.Comet<GamepassGranted>,
	ProductGranted: Comet.Comet<ProductGranted>,
	PlayerDataLoaded: Comet.Comet<PlayerDataLoaded>,
	PlayerJoined: Comet.Comet<PlayerJoined>,
	PlayerLeaving: Comet.Comet<PlayerLeaving>,
}

export type EconEvent<T> = {
	Connect: (self: Comet.Comet<T>, callback: (value: T, ...any) -> any, on_disconnect: (() -> ())?) -> () -> (),
	get: (self: Comet.Comet<T>) -> T,
}

return nil
