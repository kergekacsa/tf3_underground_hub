-- The update script of the hub, under the path of a station that the mod Cargo Range
-- (gabri_cargo_catchment_1) supports. That mod finds a station by the path of its update script,
-- without the mod name in front. With this path it adds its range settings to the hub and scales
-- the catchment area: the passenger range for a passenger hub, the cargo range for a cargo hub,
-- and the cargo range for a mixed hub when "Include mixed stations" is on.
local hub = require "kacsa_underground_hub::/stations/rail/underground_hub/hub_script.lua"

-- Every call returns a new table: another mod may replace a function in the table it gets.
function data()
	local functions = {}
	for name, fn in pairs(hub) do functions[name] = fn end
	return functions
end
