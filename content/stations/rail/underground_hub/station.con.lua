-- The hub in the menu Rail, Buildings. Level 1 starts as a rail level.
local hub = require "kacsa_underground_hub::/stations/rail/underground_hub/hub_con.lua"

function data()
return hub.construction {
	menuCategory = "rail_buildings",
	firstLevelVehicle = hub.vehicle.rail,
}
end
