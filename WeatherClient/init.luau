--[[
Not_Lowest
Delinquent Studios
]]

return function(helpers,services)
	local oldwarn = warn 
	local warn = function(...)
		oldwarn("[Weather] ", ...)
	end
	
	local WeatherLoaderScript = script.Loader
	if not WeatherLoaderScript then
		warn("WeatherLoader not found")
		return
	end

	warn("WeatherLoader Loading")

	helpers.warn = warn --// TODO: Clone table so we dont pollute global helpers

	local Loaded, Loader = pcall(function()
		return require(WeatherLoaderScript)(helpers, services)
	end)

	if not Loaded then
		warn("Failed to load WeatherLoader: " .. tostring(Loader))
		return
	end

	local Success,LoaderError = pcall(function()
		return Loader:Start()
	end)
	if Success then
		warn("WeatherLoader Loaded")
	else
		warn("Failed to start WeatherLoader: " .. tostring(LoaderError))
	end

end