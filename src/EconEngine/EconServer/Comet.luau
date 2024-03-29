--[[
	State management module written by yours truly @bkmazefe. Inspired from Elttob's States in Fusion Library.
]]
local Promise = require(script.Parent.Parent.Parent.Promise)

local Comet = {}
Comet.__index = Comet

export type Comet<T> = {
	new: (T) -> Comet<T>,
	set: (self: Comet<T>, new_value: T, force_update: boolean?) -> (),
	get: (self: Comet<T>) -> T,
	tie: (self: Comet<T>, callback: (value: T) -> any, on_disconnect: (() -> ())?) -> () -> (),
	_updateAll: (self: Comet<T>) -> (),
	toString: (self: Comet<T>) -> (),
	_doesUnpack: boolean,

	stored_value: T,
	_connections: { [(value: T) -> any]: (value: T) -> any },
}

local WEAK_KEYS_METATABLE = { __mode = "k" }

function Comet.new<T>(value: T, doesUnpack: boolean?): Comet<T>
	local self = setmetatable({
		stored_value = value,
		_connections = setmetatable({}, WEAK_KEYS_METATABLE),
		_doesUnpack = doesUnpack and true or false,
	}, Comet)

	return self
end

function Comet.set<T>(self: Comet<T>, new_value: T, force_update: boolean?)
	if self.stored_value ~= new_value or force_update then
		self.stored_value = new_value
		self:_updateAll()
	end
end

function Comet.get<T>(self: Comet<T>): T
	return self.stored_value
end

function Comet._updateAll<T>(self: Comet<T>)
	for _, callback in self._connections do
		Promise.new(function(resolve, reject)
			local val = self:get()
			if self._doesUnpack == true and val and next(val) then
				resolve(callback(table.unpack(val)))
			elseif val then
				resolve(callback(val))
			else
				reject(val)
			end
		end):catch(warn)
	end
end

function Comet.Connect<T>(self: Comet<T>, callback: (value: T, ...any) -> any, on_disconnect: (() -> ())?): () -> ()
	self._connections[callback] = callback

	return function()
		self._connections[callback] = nil
		if on_disconnect ~= nil then
			on_disconnect()
		end
	end
end

function Comet.toString<T>(self: Comet<T>)
	return tostring(self:get())
end

return Comet.new
