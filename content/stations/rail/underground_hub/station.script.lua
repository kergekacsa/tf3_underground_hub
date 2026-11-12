-- The script of the hub for the check functions of its parameters and for its template.
local hub = require "kacsa_underground_hub::/stations/rail/underground_hub/hub_script.lua"

-- Every call returns a new table: another mod may replace a function in the table it gets.
function data()
	local functions = {}
	for name, fn in pairs(hub) do functions[name] = fn end
	return functions
end
