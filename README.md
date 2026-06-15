Not_Lowest
Weather System


Note: This requires a UI reconstruction
I added the UI helpers itself but it requires my core module. So I added fallbacks in (most?) places in the form of ResolveHelper so it can require the elements and you can just put them in there without any fancy preloading.

So you could do something like this, since this is a one off and the actual source is in a private repo I relooked over everything that I could find.
You'll likely have to replace the sounds.

I found the sounds on https://www.epidemicsound.com

--// This is excerpt from my core loader (https://github.com/gmoddev/CoreExample)
```
local function LoadServices(): Services
	local Cache = {}

	return setmetatable({
		Promise = Promise	
	}, {
		__index = function(_, key)
			if Cache[key] then
				return Cache[key]
			end

			local Success, Service = pcall(game.GetService, game, key)
			if Success and Service then
				Cache[key] = Service
				return Service
			end

			warn(("Invalid service requested: %s"):format(tostring(key)))
			return nil
		end;
		__newindex = function()
			return warn("Services table is read only")
		end,
	})
end

local Services = LoadServices()
local Helpers = ReplicatedStorage.Helpers

local Client = pcall(require,script.WeatherClient)
local Success,Err = pcall(function()
    return Client(Helpers,Services)
end)
```
