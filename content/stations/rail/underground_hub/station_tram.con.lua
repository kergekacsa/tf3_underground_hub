-- The hub in the menu Road, Buildings. Level 1 starts as a tram level.
local hub = require "kacsa_underground_hub::/stations/rail/underground_hub/hub_con.lua"

function data()
return hub.construction {
	menuCategory = "road_buildings",
	firstLevelVehicle = hub.vehicle.tram,
}
end
