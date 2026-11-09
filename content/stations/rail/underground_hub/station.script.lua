local vec3 = require "::/scripts/vec3.tl"
local transf = require "::/scripts/mat4.tl"
local laneutil = require "::/scripts/construction/laneutil.lua"
local modulesutil = require "::/scripts/construction/modulesutil.lua"
local constructionutil = require "::/scripts/construction/constructionutil.lua"

local function mul(mat, vec) 
	return {
		mat[1]*vec[1] + mat[5]*vec[2] + mat[ 9]*vec[3] + mat[13],
		mat[2]*vec[1] + mat[6]*vec[2] + mat[10]*vec[3] + mat[14],
		mat[3]*vec[1] + mat[7]*vec[2] + mat[11]*vec[3] + mat[15]
	}
end

local function transform(curve, mat)
	local ret = {}
	for i = 1, #curve do
		local points = curve[i]
		local transfCurv = {}
		for j = 1, #points do
			transfCurv[j] = mul(mat, points[j])
		end
		ret[i] = transfCurv
	end
	return ret
end

local function makeCircleEdges(depth, radius, split_degs)
	local function arc_to_bezier(r, a0, a1, d)
		local theta = a1 - a0
		local mid = (a0 + a1) / 2
		local cos0, sin0 = math.cos(a0), math.sin(a0)
		local cos1, sin1 = math.cos(a1), math.sin(a1)

		local p0 = { r * cos0, r * sin0, d }
		local p2 = { r * cos1, r * sin1, d }

		local control_radius = r / math.cos(theta / 2)
		local p1 = { control_radius * math.cos(mid), control_radius * math.sin(mid), d }

		return { p0, p1, p2 }
	end

	-- Breakpoints
	local breaks = {}
	for a = 0, 360, 45 do
		table.insert(breaks, a)
	end
	if type(split_degs) == "table" then
		for _, deg in ipairs(split_degs) do
			table.insert(breaks, ((deg % 360) + 360) % 360)
			table.insert(breaks, (((deg + 180) % 360) + 360) % 360)
		end
	elseif type(split_degs) == "number" then
		table.insert(breaks, ((split_degs % 360) + 360) % 360)
		table.insert(breaks, (((split_degs + 180) % 360) + 360) % 360)
	end

	table.sort(breaks)
	local unique = {}
	for _, a in ipairs(breaks) do
		if #unique == 0 then
			table.insert(unique, a)
		elseif (a - unique[#unique]) >= 1.0 then
			table.insert(unique, a)
		end
	end
	if (360 - unique[#unique]) < 1.0 then
		unique[#unique] = 360
	else
		table.insert(unique, 360)
	end

	local segments = {}
	for i = 1, #unique - 1 do
		local a0, a1 = math.rad(unique[i]), math.rad(unique[i + 1])
		table.insert(segments, arc_to_bezier(radius, a0, a1, depth))
	end

	return segments
end

local function makeEdge(origin, direction, length)
	return {{  
		{ origin[1] + direction[1] * length, origin[2] + direction[2] * length, origin[3] },
		{ origin[1], origin[2], origin[3] }, 
	}}
end

local function makePassengerLane(origin, direction, length, stairDistance)
	local dynamicLength = length - stairDistance
	local fixedLength = stairDistance * 2.0

	local start = { origin[1] + direction[1] * length, origin[2] + direction[2] * length, origin[3] }
	local stair1 = { start[1] - direction[1] * dynamicLength, start[2] - direction[2] * dynamicLength, origin[3] }
	local stair2 = { start[1] - direction[1] * (dynamicLength + fixedLength), start[2] - direction[2] * (dynamicLength + fixedLength), origin[3] }
	local farSide = { start[1] - direction[1] * length * 2.0, start[2] - direction[2] * length * 2.0, origin[3] }

	return { 
		{ start, stair1, },
		{ stair1, stair2, },
		{ stair2, farSide, },
	}
end

local function makeVehicleLane(origin, direction, length)
	return { 
		{ { origin[1] + direction[1] * length, origin[2] + direction[2] * length, origin[3] }, { origin[1], origin[2], origin[3] }, },
		{ { origin[1], origin[2], origin[3] }, { origin[1] - direction[1] * length, origin[2] - direction[2] * length, origin[3] }, },
	}
end

local edgeBuffer = 0.5

-- Base geometry definitions
local generatedData = {
	["static"] = {
		curves = {
			["ground_face"] = {
				{ { 8.0, 8.0, 0.0 }, { -8.0, 8.0, 0.0 }, { -8.0, 24.0, 0.0 }, { 8.0, 24.0, 0.0 }, },
			},
		},
	},
	["base"] = {
		curves = {
			["passenger_entrance_link"] = {
				{ { 3, 9, 0 }, { 3, 20, 0 }, },
				{ { 3, 20, 0 }, { 0, 20, 0 }, },
			},
			["passenger_entrance"] = {
				{ { -3, 9, 0 }, { -3, 20, 0 }, },
				{ { -3, 20, 0 }, { 0, 20, 0 }, },
				{ { 0, 20, 0 }, { 0, 17.51, 0.057 }, },
				{ { 0, 17.51, 0.057 }, { 0, 1.5, -9 }, },
				{ { 0, 1.5, -9 }, { 0, 0, -9 }, },
				{ { 0, 0, -9 }, { 1.5, 0, -9 }, },
				{ { 1.5, 0, -9 }, { 6.7, 0, -12 }, },
				{ { 6.7, 0, -12 }, { 8.5, 0, -12 }, },
				{ { 0, 0, -9 }, { -1.5, 0, -9 }, },
				{ { -1.5, 0, -9 }, { -6.7, 0, -12 }, },
				{ { -6.7, 0, -12 }, { -8.5, 0, -12 }, },
			},
			["collider"] = {
				{ 
					{ 8.0, 9.0, 20.0 }, { -8.0, 9.0, 20.0 }, { -8.0, 24.0, 20.0 }, { 8.0, 24.0, 20.0 }, 
					{ 8.0, 9.0, -7.4 }, { -8.0, 9.0, -7.4 }, { -8.0, 24.0, -7.4 }, { 8.0, 24.0, -7.4 }, 
				},
			},
		},
		meshes = {
			["equal"] = {
				{ 
					{ { 8.0, 9.0, 0.0 }, { -8.0, 24.0, 0.0 }, { -8.0, 9.0, 0.0 }, },
					{ { -8.0, 24.0, 0.0 }, { 8.0, 9.0, 0.0 }, { 8.0, 24.0, 0.0 }, },
				}
			},
		},
		models = {
			["::/stations/street/underground_station/models/underground_station_surface.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
			},
			["::/assets/stations/rail/era_c_street_pillar.mdl"] = {
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1.5, 8, 0, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -1.5, 8, 0, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 3.5, 8, 0, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -3.5, 8, 0, 1, },
			},
			["::/assets/buildings/com/advertisements/column_c_01.mdl"] = {
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 9.5, 0, 1, },
			},
			["::/assets/buildings/res/hedges/hdg_02_3m.mdl"] = {
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 6.5, 11, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.5, 11, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 6.5, 17, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.5, 17, 0, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, 23.5, 0, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 23.5, 0, 1, },
			},
			["::/assets/buildings/com/misc/trashcan_c_01.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 14, 0, 1, },
				{ -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, -5, 14, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 22, 0, 1, },
			},
			["::/assets/buildings/res/garden_lamp/garden_lamp_c_stand.mdl"] = {
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 5, 11, 0, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 5, 17, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -5, 11, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -5, 17, 0, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -3.5, 22, 0, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 3.5, 22, 0, 1, },
			},
			["::/assets/buildings/res/grd_frn/bench_c_metal.mdl"] = {
				{ -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 5, 15.5, 0, 1, },
				{ -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 5, 12.5, 0, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, 15.5, 0, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, 12.5, 0, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1.5, 22, 0, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -1.5, 22, 0, 1, },
			},
			["::/assets/buildings/res/hedges/hdg_02.mdl"] = {
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 6.5, 9, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.5, 9, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 6.5, 23, 0, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -6.5, 23, 0, 1, },
			},
		}
	},
	["rotated"] = {
		curves = {
			["passenger_passageway"] = {
				{ { 0, 8.5, -12 }, { 0, 11.75, -12 }, },
				{ { 0, 11.75, -12 }, { 3.33, 11.75, -12 }, },
				{ { 3.33, 11.75, -12 }, { 13.33, 11.75, -17.65 }, },
				{ { 13.33, 11.75, -17.65 }, { 14.66, 11.75, -17.65 }, },
				{ { 14.66, 11.75, -17.65 }, { 14.66, 5, -17.65 }, },

				{ { 0, 11.75, -12 }, { -3.33, 11.75, -12 }, },
				{ { -3.33, 11.75, -12 }, { -13.33, 11.75, -17.65 }, },
				{ { -13.33, 11.75, -17.65 }, { -14.66, 11.75, -17.65 }, },
				{ { -14.66, 11.75, -17.65 }, { -14.66, 5, -17.65 }, },

				{ { 0, -8.5, -12 }, { 0, -11.75, -12 }, },
				{ { 0, -11.75, -12 }, { 3.33, -11.75, -12 }, },
				{ { 3.33, -11.75, -12 }, { 13.33, -11.75, -17.65 }, },
				{ { 13.33, -11.75, -17.65 }, { 14.66, -11.75, -17.65 }, },
				{ { 14.66, -11.75, -17.65 }, { 14.66, -5, -17.65 }, },

				{ { 0, -11.75, -12 }, { -3.33, -11.75, -12 }, },
				{ { -3.33, -11.75, -12 }, { -13.33, -11.75, -17.65 }, },
				{ { -13.33, -11.75, -17.65 }, { -14.66, -11.75, -17.65 }, },
				{ { -14.66, -11.75, -17.65 }, { -14.66, -5, -17.65 }, },
			},
			["collider"] = {
				{ 
					{ 20.0, -14.0, -7.5 }, { -20.0, -14.0, -7.5 }, { -20.0, 14.0, -7.5 }, { 20.0, 14.0, -7.5 }, 
					{ 20.0, -14.0, -20.0 }, { -20.0, -14.0, -20.0 }, { -20.0, 14.0, -20.0 }, { 20.0, 14.0, -20.0 }, 
				},
			},
		},
		models = {
			["::/stations/street/underground_station/models/underground_station_stairs.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
			},
			["::/assets/stations/street/tickets_era_c_1.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 12.7, -12, 1, },
				{ -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, -12.7, -12, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 15.4, 12, -17.65, 1, },
				{ 0,-1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -15.4, 12, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 15.4, -12, -17.65, 1, },
				{ 0,-1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -15.4, -12, -17.65, 1, },
			},
			["::/assets/stations/rail/era_c_station_name.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 7.15, -16.15, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, 7.15, -16.15, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, -7.15, -16.15, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -5, -7.15, -16.15, 1, },
			},
			["::/assets/buildings/com/misc/trashcan_c_01.mdl"] = {
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 10, 6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -10, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 10, -6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, -6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -10, -6.5, -17.65, 1, },
			},
			["::/assets/buildings/res/grd_frn/bench_c_metal.mdl"] = {
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 11.5, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 8.5, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1.5, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -1.5, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -11.5, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -8.5, 6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 11.5, -6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 8.5, -6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 1.5, -6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -1.5, -6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -11.5, -6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -8.5, -6.5, -17.65, 1, },
			},
		}
	},
	["extended"] = {
		curves = {
			["collider"] = {
				{ 
					{ 9.0, -10.0, -11.5 }, { 0.0, -10.0, -11.5 }, { 0.0, 10.0, -11.5 }, { 9.0, 10.0, -11.5 }, 
					{ 9.0, -10.0, -20.0 }, { 0.0, -10.0, -20.0 }, { 0.0, 10.0, -20.0 }, { 9.0, 10.0, -20.0 }, 
				},
			},
		},
		models = {
			["::/stations/street/underground_station/models/underground_station_extension.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 },
			},
			["::/assets/stations/rail/era_c_station_name.mdl"] = {
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 7.15, -16.15, 1, },
				{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, -7.15, -16.15, 1, },
			},
			["::/assets/buildings/com/misc/trashcan_c_01.mdl"] = {
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, -6.5, -17.65, 1, },
			},
			["::/assets/buildings/res/grd_frn/bench_c_metal.mdl"] = {
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1.5, 6.5, -17.65, 1, },
				{ 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, -1.5, 6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 1.5, -6.5, -17.65, 1, },
				{ 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, -1.5, -6.5, -17.65, 1, },
			},
		}
	},
}

local hallZ = -18.0
local railZ = -18.3
local silhouetteTemplate = "track_silhouette.street_template"
local rockTunnel = "::/infrastructure/tunnel/tunnel_a.tunnel"
local concreteTunnel = "::/infrastructure/tunnel/tunnel_b.tunnel"
local concreteTunnelYear = 1970
local modernTrackYear = 1980
local conFileSuffix = "underground_hub/station.con"
local lockRefreshSeconds = 1.0
local ringZ = -12.0
local ringRadius = 8.5
local platformY = 5.0
local levelSpacing = 18.0
local maxLevels = 4
local defaultAngleIndices = { 1, 19, 10, 28 }
-- Saved indices into the platform lengths: 240 m for a rail level, 40 m for a tram level.
local defaultRailLengthIndex = 2
local defaultTramLengthIndex = 4
local nodesPerRailLevel = 16
local nodesPerTramLevel = 12
local tramTrackTypes = { "YES", "ELECTRIC" }
local tramModes = { "TRAM", "ELECTRIC_TRAM" }
local cargoModePassenger, cargoModeCargo, cargoModeMixed = 1, 2, 3
local cargoDepotModel = "models/cargo/surface_cargo_depot.mdl"
local palletJackModel = "::/assets/stations/rail/cargo_pallet_jack.mdl"
local ledStripModel = "models/shared/platform_led_strip.mdl"
local hazardStripModel = "models/shared/platform_hazard_strip.mdl"
local stripStep = 1.0
local stripY = 4.5
local stripZ = -17.64
local tunnelBCar = "::/infrastructure/tunnel/tunnel_b_car.tunnel"
local tramTemplate = "::/infrastructure/street/tram/tram_new.street_template"
local hallEndModel = "::/stations/street/underground_station/models/underground_station_end.mdl"
local cargoMinX = -13.0

local trackTypes = {
	{"track_simple.street_template", "track_simple_electric.street_template",
	 "::/infrastructure/track/simple/simple.street_template", "::/infrastructure/track/simple/simple_catenary.street_template"},
	{"track.street_template", "track_electric.street_template",
	 "::/infrastructure/track/standard/standard.street_template", "::/infrastructure/track/standard/standard_catenary.street_template"},
	{"track_high_speed.street_template", "track_high_speed_electric.street_template",
	 "::/infrastructure/track/high_speed/high_speed.street_template", "::/infrastructure/track/high_speed/high_speed_catenary.street_template"},
}

local function readOperation(params)
	local mode = tonumber(params.cargoMode) or cargoModePassenger
	return {
		mode = mode,
		isPassenger = mode ~= cargoModeCargo,
		isCargo = mode ~= cargoModePassenger,
	}
end

-- Level 1 has the choices rail and tram. Levels 2 to 4 have off, rail and tram, so that the one
-- selector of a level also switches the level. A level keeps its depth by its number, so level 3 can
-- exist without level 2.
local function vehicleOf(values, level)
	local index = tonumber(values["level" .. level .. "Vehicle"]) or 1
	if level == 1 then return index == 2 and "tram" or "rail" end
	if index == 3 then return "tram" end
	return index == 2 and "rail" or "off"
end

local function isActive(values, level)
	return vehicleOf(values, level) ~= "off"
end

local function readLevels(captureParams, params)
	local levels = {}
	for k = 1, maxLevels do
		if isActive(params, k) then
			local isTram = vehicleOf(params, k) == "tram"
			local lengthKey = "level" .. k .. (isTram and "TramLength" or "Length")
			levels[#levels + 1] = {
				number = k,
				isTram = isTram,
				angle = ((tonumber(params["level" .. k .. "Angle"]) or defaultAngleIndices[k]) - 1) * captureParams.stepIncrement,
				halfLength = captureParams.platformLengths[tonumber(params[lengthKey]) or (isTram and defaultTramLengthIndex or defaultRailLengthIndex)] * 0.5,
				dz = -(k - 1) * levelSpacing,
			}
		end
	end
	return levels
end

local function levelTransform(level, extraAngle)
	return transf.mul(transf.transl(vec3.new(0, 0, level.dz)), transf.rotZ(math.rad(level.angle + (extraAngle or 0))))
end

local function personLaneTypes(operation)
	return operation.isCargo and {"PERSON", "CARGO"} or {"PERSON"}
end

-- Keeps the models of a source table, minus the passenger props when the hub carries no
-- passengers and minus everything left of x = -2 when the surface holds the cargo depot.
local function filterModels(sourceModels, operation, dropLeftZone)
	local result = {}
	for id, transforms in pairs(sourceModels) do
		local isPassengerProp = id:find("bench_c_metal", 1, true) or id:find("tickets_era_c", 1, true) or id:find("advertisements/", 1, true)
		local keep = {}
		for _, placement in ipairs(transforms) do
			local drop = (dropLeftZone and operation.isCargo and placement[13] < -2.0)
				or (not operation.isPassenger and isPassengerProp)
			if not drop then keep[#keep + 1] = placement end
		end
		if #keep > 0 then result[id] = keep end
	end
	return result
end

-- A rail level has real railway edges across the hall. Four free outer nodes per level connect
-- to ordinary rail tunnels; the hall of the construction supplies the tunnel walls.
-- Returns the zero-based node index of the stopping edge of each track.
local function addRailEdges(result, level, tracks, firstNode)
	local halfLength = level.halfLength
	local levelTransf = levelTransform(level)
	local stoppingNodes = {}
	for track = 1, 2 do
		local y = track == 1 and -2.5 or 2.5
		local xs = {-halfLength-edgeBuffer, 0, halfLength+edgeBuffer}
		if track == 2 then for n = 1, #xs do xs[n] = -xs[n] end end
		local curves = {}
		for n = 1, #xs-1 do
			curves[#curves+1] = {{xs[n],y,railZ},{xs[n+1],y,railZ}}
		end
		constructionutil.addEdges(transform(curves, levelTransf), result, "TRACK", {
			type = tracks.inside, edgeType = "TUNNEL", edgeTypeName = "station_hall.tunnel"
		}, false, {}, {})
		-- Zero-based node index in the flattened construction edge lists.
		stoppingNodes[track] = firstNode + (track-1)*8 + 1
		for _, direction in ipairs({-1,1}) do
			local inside = direction*(halfLength+edgeBuffer)
			local outside = inside + direction*10
			constructionutil.addEdges(transform({{{outside,y,railZ},{inside,y,railZ}}},levelTransf),result,"TRACK",{
				type=tracks.outside,edgeType="TUNNEL",edgeTypeName=tracks.tunnel
			},false,{0},{0})
		end
	end
	return stoppingNodes
end

-- A tram level has no edges across its hall, so the placement preview would show only its two ends.
-- These two parallel railway edges are inert: their nodes are not free, and their track style has no visible model.
local function addTramSilhouette(result, level)
	local halfLength = level.halfLength
	local levelTransf = levelTransform(level)
	for _, y in ipairs({-2.5, 2.5}) do
		local xs = {-halfLength-edgeBuffer, 0, halfLength+edgeBuffer}
		local curves = {}
		for n = 1, #xs-1 do
			curves[#curves+1] = {{xs[n],y,hallZ},{xs[n+1],y,hallZ}}
		end
		constructionutil.addEdges(transform(curves, levelTransf), result, "TRACK", {
			type = silhouetteTemplate, edgeType = "TUNNEL", edgeTypeName = "station_hall.tunnel"
		}, false, {}, {})
	end
end

-- A tram level has one street edge at each end. Its vehicle lanes lie inside the construction.
local function addTramEdges(result, level, tramTrackType)
	local levelTransf = levelTransform(level)
	local snapNodes = { 0 }
	local freeNodes = { 0 }
	for _, direction in ipairs({1, -1}) do
		local edge = makeEdge({ direction * (level.halfLength + edgeBuffer), 0.0, hallZ }, { direction, 0.0, 0.0 }, 10.0)
		constructionutil.addEdges(transform(edge, levelTransf), result, "STREET", {
			type = tramTemplate,
			tramTrackType = tramTrackType,
			edgeType = "TUNNEL",
			edgeTypeName = tunnelBCar,
		}, false, snapNodes, freeNodes)
	end
end

-- Adds the lanes of one level and returns the zero-based lane indices of its two platform
-- lanes and, for a tram level, of its two vehicle lanes.
local function addLevelLanes(sub, level, operation)
	local levelTransf = levelTransform(level)
	local halfLength = level.halfLength
	local types = personLaneTypes(operation)
	local lanes = { platform = {}, vehicle = {} }

	-- Vertical shaft from the entrance ring down to the passageway of a deeper level.
	if level.dz < -0.01 then
		local ringRotation = transf.rotZ(math.rad(level.angle))
		for _, y in ipairs({ringRadius, -ringRadius}) do
			local ringNode = mul(ringRotation, { 0, y, ringZ })
			local passageNode = mul(levelTransf, { 0, y, ringZ })
			table.insert(sub.laneLists, laneutil.createLane({ { ringNode, passageNode } }, types, 2, 2, false))
		end
	end

	table.insert(sub.laneLists, laneutil.createLane(transform(generatedData["rotated"].curves["passenger_passageway"], levelTransf), types, 2, 2, false))

	local passengerPlatform1 = makePassengerLane({ 0, -platformY, -17.65 }, { -1.0, 0.0, 0.0 }, halfLength, 14.66)
	local passengerPlatform2 = makePassengerLane({ 0, platformY, -17.65 }, { 1.0, 0.0, 0.0 }, halfLength, 14.66)

	lanes.platform[1] = #sub.laneLists
	table.insert(sub.laneLists, laneutil.createLane(transform(passengerPlatform1, levelTransf), types, 2, 2, false))
	lanes.platform[2] = #sub.laneLists
	table.insert(sub.laneLists, laneutil.createLane(transform(passengerPlatform2, levelTransf), types, 2, 2, false))

	if level.isTram then
		local vehicle1 = makeVehicleLane({ 0, -2.5, hallZ }, { -1.0, 0.0, 0.0 }, halfLength + edgeBuffer)
		local vehicle2 = makeVehicleLane({ 0, 2.5, hallZ }, { 1.0, 0.0, 0.0 }, halfLength + edgeBuffer)
		lanes.vehicle[1] = #sub.laneLists
		table.insert(sub.laneLists, laneutil.createLane(transform(vehicle1, levelTransf), tramModes, 40, 2, false))
		lanes.vehicle[2] = #sub.laneLists
		table.insert(sub.laneLists, laneutil.createLane(transform(vehicle2, levelTransf), tramModes, 40, 2, false))
	end
	return lanes
end

-- The hall of a level: the same design for rail and tram levels.
local function addLevelModels(sub, params, level, operation)
	local halfLength = level.halfLength
	local levelTransf = levelTransform(level)
	local turned = transf.mul(levelTransf, transf.rotZ(math.rad(180)))

	constructionutil.addModelsAndGroups(params, {
		curves = generatedData["rotated"].curves,
		models = filterModels(generatedData["rotated"].models, operation, false),
	}, sub, nil, levelTransf)

	sub.models[#sub.models + 1] = {
		id = hallEndModel,
		transf = transf.mul(levelTransf, transf.transl(vec3.new(halfLength, 0, 0)))
	}
	sub.models[#sub.models + 1] = {
		id = hallEndModel,
		transf = transf.mul(turned, transf.transl(vec3.new(halfLength, 0, 0)))
	}

	local extended = { curves = generatedData["extended"].curves, models = filterModels(generatedData["extended"].models, operation, false) }
	for i = 20, halfLength - 10, 10 do
		constructionutil.addModelsAndGroups(params, extended, sub, nil, transf.mul(levelTransf, transf.transl(vec3.new(i, 0, 0))))
		constructionutil.addModelsAndGroups(params, extended, sub, nil, transf.mul(turned, transf.transl(vec3.new(i, 0, 0))))
	end

	-- Safety and guide strips along both platform edges: guide light for passengers, hazard stripes for cargo.
	local sideStrips = {
		[cargoModePassenger] = { ledStripModel, ledStripModel },
		[cargoModeCargo] = { hazardStripModel, hazardStripModel },
		[cargoModeMixed] = { ledStripModel, hazardStripModel },
	}
	local strips = sideStrips[operation.mode] or sideStrips[cargoModePassenger]
	for x = -halfLength + stripStep / 2, halfLength - stripStep / 2, stripStep do
		for side, sign in ipairs({-1, 1}) do
			sub.models[#sub.models + 1] = {
				id = strips[side],
				transf = transf.mul(levelTransf, transf.transl(vec3.new(x, sign * stripY, stripZ)))
			}
		end
	end

	if operation.isCargo then
		sub.models[#sub.models + 1] = {
			id = palletJackModel,
			transf = transf.mul(levelTransf, transf.transl(vec3.new(halfLength - 3.0, 6.2, -17.65)))
		}
	end
end

-- The surface building: the entrance of the original, widened to the left for the cargo depot.
local function addSurface(sub, params, operation)
	if not operation.isCargo then
		constructionutil.addModelsAndGroups(params, generatedData["base"], sub)
		return
	end

	local minX = cargoMinX
	local base = generatedData["base"]
	constructionutil.addModelsAndGroups(params, {
		curves = {
			passenger_entrance_link = base.curves["passenger_entrance_link"],
			passenger_entrance = base.curves["passenger_entrance"],
			collider = {{
				{ 8.0, 9.0, 20.0 }, { minX, 9.0, 20.0 }, { minX, 24.0, 20.0 }, { 8.0, 24.0, 20.0 },
				{ 8.0, 9.0, -7.4 }, { minX, 9.0, -7.4 }, { minX, 24.0, -7.4 }, { 8.0, 24.0, -7.4 },
			}},
		},
		meshes = {
			["equal"] = {{
				{ { 8.0, 9.0, 0.0 }, { minX, 24.0, 0.0 }, { minX, 9.0, 0.0 }, },
				{ { minX, 24.0, 0.0 }, { 8.0, 9.0, 0.0 }, { 8.0, 24.0, 0.0 }, },
			}},
		},
		models = filterModels(base.models, operation, true),
	}, sub)

	sub.models[#sub.models + 1] = {
		id = cargoDepotModel,
		transf = transf.mul(transf.transl(vec3.new(-7.2, 16.5, 0.0)), transf.rotZ(math.pi))
	}
	sub.models[#sub.models + 1] = {
		id = palletJackModel,
		transf = transf.mul(transf.transl(vec3.new(-5.0, 11.5, 0.0)), transf.rotZ(math.rad(30)))
	}
	local hedges = {
		{ "hdg_02", -12.5, 9 }, { "hdg_02_3m", -12.5, 11 }, { "hdg_02_3m", -12.5, 14 }, { "hdg_02_3m", -12.5, 17 },
		{ "hdg_02_3m", -12.5, 20 }, { "hdg_02", -12.5, 23 },
	}
	for _, hedge in ipairs(hedges) do
		sub.models[#sub.models + 1] = {
			id = "::/assets/buildings/res/hedges/" .. hedge[1] .. ".mdl",
			transf = { 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, hedge[2], hedge[3], 0, 1 }
		}
	end
	for _, x in ipairs({-10.5, -7.5, -4.5, -2.0}) do
		sub.models[#sub.models + 1] = {
			id = "::/assets/buildings/res/hedges/hdg_02_3m.mdl",
			transf = { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, 23.5, 0, 1 }
		}
	end
end

local function addGround(sub, operation)
	local groundTexture = "::/stations/street/underground_station/underground_station.gtex"
	if not operation.isCargo then
		modulesutil.addGroundFaces(groundTexture, generatedData, sub)
		return
	end

	local minX = cargoMinX
	local apronFace = { { 8.0, 8.0, 0.0 }, { minX, 8.0, 0.0 }, { minX, 24.0, 0.0 }, { 8.0, 24.0, 0.0 } }
	modulesutil.addGroundFaces(groundTexture, { static = { curves = { ground_face = { apronFace } } } }, sub)
	sub.terrainAlignmentLists = sub.terrainAlignmentLists or {}
	table.insert(sub.terrainAlignmentLists, {
		type = "EQUAL",
		faces = { apronFace },
		slopeLow = 0.275,
		slopeHigh = 0.6,
	})
	sub.groundFaces = sub.groundFaces or {}
	table.insert(sub.groundFaces, {
		face = { { -3.5, 8.0, 0.0 }, { minX + 0.5, 8.0, 0.0 }, { minX + 0.5, 23.5, 0.0 }, { -3.5, 23.5, 0.0 } },
		modes = {{ type = "FILL", key = "::/terrain/materials/asphalt_01/asphalt_01.tmat" }},
	})
end

local function makeTerminal(laneIndex, vehicleNode, modes, length, operation)
	local classes = {}
	if operation.isPassenger then classes[#classes + 1] = "PASSENGERS" end
	if operation.isCargo then classes[#classes + 1] = "UNIVERSAL" end
	return {
		personEdges = { { laneIndex, 2 }, { laneIndex, 0 }, { laneIndex, 1 }, },
		personNodes = { { laneIndex, 2 }, { laneIndex, 0 }, { laneIndex, 1 }, },
		vehicleNode = vehicleNode,
		transportModes = modes,
		cargoTransferSpeeds = {{cargoTypeSet={cargoClassesIncluded=classes},loadSpeedModifier=1,length=length}},
		passengers = operation.isPassenger,
		cargo = operation.isCargo,
	}
end

-- The game calls a check function with the captured parameters of the script reference and the
-- current values of all construction parameters, and expects "Enabled", "Disabled" or "Hidden".
local function findParams(arg1, arg2)
	for _, arg in ipairs({arg1, arg2}) do
		if type(arg) == "table" then
			if type(arg.params) == "table" then return arg.params end
			if next(arg) ~= nil then return arg end
		end
	end
	return nil
end

-- The panel of a placed station greys out a control. The panel of a built station honours only "Hidden",
-- so there a control that is off disappears. The parameter hubPlacement exists only in the first panel.
local function enabledIf(condition, values)
	if condition then return "Enabled" end
	return values.hubPlacement ~= nil and "Disabled" or "Hidden"
end

local function clock()
	local ok, seconds = pcall(function() return os.clock() end)
	return ok and seconds or nil
end

-- All nodes of a station: the free nodes at the ends of its tunnels belong to its edges, not to its frozen nodes.
local function nodesOf(construction)
	local componentType = api.type.ComponentType
	local nodes, seen = {}, {}
	local function add(node)
		if node ~= nil and not seen[node] then
			seen[node] = true
			nodes[#nodes + 1] = node
		end
	end
	for _, node in ipairs(construction.frozenNodes) do add(node) end
	for _, edge in ipairs(construction.frozenEdges) do
		local base = api.engine.getComponent(edge, componentType.BASE_EDGE)
		if base then
			add(base.node0)
			add(base.node1)
		end
	end
	return nodes
end

-- The levels of a built station that have tracks or streets on their nodes. A level is found by
-- the depth of its nodes below the highest node of the station.
local function connectedLevelsOf(entity)
	local componentType = api.type.ComponentType
	local construction = api.engine.getComponent(entity, componentType.CONSTRUCTION)
	local own = {}
	for _, edge in ipairs(construction.frozenEdges) do own[edge] = true end
	local nodes, top = {}, nil
	for _, node in ipairs(nodesOf(construction)) do
		local base = api.engine.getComponent(node, componentType.BASE_NODE)
		if base then
			nodes[#nodes + 1] = { node = node, z = base.position.z }
			if top == nil or base.position.z > top then top = base.position.z end
		end
	end
	local streetSystem = api.engine.system.streetSystem
	local connected, depths = {}, {}
	for _, entry in ipairs(nodes) do
		for _, edges in ipairs({ streetSystem.getNodeTrackSegments(entry.node), streetSystem.getNodeStreetSegments(entry.node) }) do
			for _, edge in ipairs(edges) do
				if not own[edge] then
					local level = math.floor((top - entry.z) / levelSpacing + 0.5) + 1
					connected[level] = true
					depths[#depths + 1] = string.format("L%d at %.1f m", level, top - entry.z)
				end
			end
		end
	end
	return connected, #nodes, depths
end

-- A parameter the construction has no stored value for matches: the game then uses the default.
local function storedParamsMatch(stored, values)
	for key, value in pairs(values) do
		if stored[key] ~= nil and stored[key] ~= value then return false end
	end
	return true
end

-- The game passes no entity to a check function. The station being edited is the one whose stored
-- parameters equal the values of the panel. Stations that cannot be told apart count together.
local function matchingStations(values)
	local componentType = api.type.ComponentType
	local entities = {}
	for _, entity in ipairs(api.engine.getEntitiesWithComponent(componentType.CONSTRUCTION)) do
		local construction = api.engine.getComponent(entity, componentType.CONSTRUCTION)
		if construction and construction.fileName:find(conFileSuffix, 1, true) and storedParamsMatch(construction.params, values) then
			entities[#entities + 1] = entity
		end
	end
	return entities
end

-- After a change in the panel the values match no station any more. The stations of the last match stay in use.
local function stillBuilt(entities)
	local componentType = api.type.ComponentType
	local kept = {}
	for _, entity in ipairs(entities) do
		if api.engine.getComponent(entity, componentType.CONSTRUCTION) then kept[#kept + 1] = entity end
	end
	return kept
end

local function findConnectedLevels(values, remembered)
	local entities = matchingStations(values)
	local matched = #entities > 0
	if not matched then entities = stillBuilt(remembered) end
	local connected, nodes, details = {}, 0, {}
	for _, entity in ipairs(entities) do
		local levels, count, depths = connectedLevelsOf(entity)
		nodes = nodes + count
		for _, depth in ipairs(depths) do details[#details + 1] = depth end
		for level in pairs(levels) do connected[level] = true end
	end
	return connected, entities, matched, nodes, details
end

local function signatureOf(values)
	local keys = {}
	for key in pairs(values) do keys[#keys + 1] = key end
	table.sort(keys)
	local parts = {}
	for _, key in ipairs(keys) do parts[#parts + 1] = key .. "=" .. tostring(values[key]) end
	return table.concat(parts, ";")
end

local lockCache = { at = nil, signature = nil, levels = {}, logged = "", entities = {} }

-- Every parameter of the panel asks for the locks, so the answer is kept for a moment.
-- The parameter hubPlacement exists only while a station is placed, not while a built station is edited.
local function connectedLevels(values)
	if values == nil or values.hubPlacement ~= nil then return {} end
	local now, signature = clock(), signatureOf(values)
	if lockCache.signature == signature and now ~= nil and lockCache.at ~= nil and now - lockCache.at < lockRefreshSeconds then
		return lockCache.levels
	end
	local ok, levels, entities, matched, nodes, details = pcall(findConnectedLevels, values, lockCache.entities)
	if not ok then
		print("[hub] connection lookup failed: " .. tostring(levels))
		levels, entities, matched = {}, lockCache.entities, false
	end
	if matched then lockCache.entities = entities end
	lockCache.at, lockCache.signature, lockCache.levels = now, signature, levels
	local list = {}
	for level in pairs(levels) do list[#list + 1] = level end
	table.sort(list)
	local text = "stations " .. tostring(#entities) .. (matched and "" or " (remembered)") .. ", nodes " .. tostring(nodes) .. ", connected levels " .. (#list == 0 and "none" or table.concat(list, ",") .. " (" .. table.concat(details or {}, "; ") .. ")")
	if text ~= lockCache.logged then
		lockCache.logged = text
		print("[hub] lock lookup: " .. text)
	end
	return levels
end

local function isRailLevel(values, level)
	return vehicleOf(values, level) == "rail"
end

local function levelControl(level, arg1, arg2)
	local p = findParams(arg1, arg2)
	if p == nil then return "Enabled" end
	if not isActive(p, level) then return enabledIf(false, p) end
	return enabledIf(not connectedLevels(p)[level], p)
end

-- A level has one length selector for rail and one for tram, each with its own default. Only the one for the vehicle shows.
local function lengthControl(level, forTram, arg1, arg2)
	local p = findParams(arg1, arg2)
	if p == nil then return "Enabled" end
	if (vehicleOf(p, level) == "tram") ~= forTram then return "Hidden" end
	return levelControl(level, arg1, arg2)
end

-- The vehicle selector of a level also switches it off. It stays until tracks are connected to the level.
local function switchControl(level, arg1, arg2)
	local p = findParams(arg1, arg2)
	if p == nil then return "Enabled" end
	return enabledIf(not connectedLevels(p)[level], p)
end

local function lockMessage(level, arg1, arg2)
	local p = findParams(arg1, arg2)
	if p == nil or not isActive(p, level) or not connectedLevels(p)[level] then return "Hidden" end
	return "Disabled"
end

-- The catenary changes the edges of every level.
local function catenaryControl(arg1, arg2)
	local p = findParams(arg1, arg2)
	if p == nil then return "Enabled" end
	return enabledIf(next(connectedLevels(p)) == nil, p)
end

local function currentYear()
	local ok, year = pcall(function() return api.engine.util.getYear() end)
	return ok and year or nil
end

-- The track type changes the edges of the rail levels.
local function trackTypeControl(arg1, arg2)
	local p = findParams(arg1, arg2)
	if p == nil then return "Enabled" end
	local connected = connectedLevels(p)
	local hasRail = false
	for level = 1, maxLevels do
		if isRailLevel(p, level) then
			hasRail = true
			if connected[level] then return enabledIf(false, p) end
		end
	end
	return enabledIf(hasRail, p)
end

-- The two selectors share a key and cover different years, as in the placement panel. A built station
-- is edited without the year filter of the game, so the check hides the one that is not available now.
local function trackTypeForYears(modern, arg1, arg2)
	local year = currentYear()
	local isModernYear = year == nil or year >= modernTrackYear
	if isModernYear ~= modern then return "Hidden" end
	return trackTypeControl(arg1, arg2)
end

function data()

return {
	createTemplateFn = function(captureParams, params)
		return {}
	end,
	checkLevel1EnabledFn = function(arg1, arg2) return levelControl(1, arg1, arg2) end,
	checkLevel2EnabledFn = function(arg1, arg2) return levelControl(2, arg1, arg2) end,
	checkLevel3EnabledFn = function(arg1, arg2) return levelControl(3, arg1, arg2) end,
	checkLevel4EnabledFn = function(arg1, arg2) return levelControl(4, arg1, arg2) end,
	checkLevel1LengthFn = function(arg1, arg2) return lengthControl(1, false, arg1, arg2) end,
	checkLevel1TramLengthFn = function(arg1, arg2) return lengthControl(1, true, arg1, arg2) end,
	checkLevel2LengthFn = function(arg1, arg2) return lengthControl(2, false, arg1, arg2) end,
	checkLevel2TramLengthFn = function(arg1, arg2) return lengthControl(2, true, arg1, arg2) end,
	checkLevel3LengthFn = function(arg1, arg2) return lengthControl(3, false, arg1, arg2) end,
	checkLevel3TramLengthFn = function(arg1, arg2) return lengthControl(3, true, arg1, arg2) end,
	checkLevel4LengthFn = function(arg1, arg2) return lengthControl(4, false, arg1, arg2) end,
	checkLevel4TramLengthFn = function(arg1, arg2) return lengthControl(4, true, arg1, arg2) end,
	checkLevel2SwitchFn = function(arg1, arg2) return switchControl(2, arg1, arg2) end,
	checkLevel3SwitchFn = function(arg1, arg2) return switchControl(3, arg1, arg2) end,
	checkLevel4SwitchFn = function(arg1, arg2) return switchControl(4, arg1, arg2) end,
	checkLevel1LockFn = function(arg1, arg2) return lockMessage(1, arg1, arg2) end,
	checkLevel2LockFn = function(arg1, arg2) return lockMessage(2, arg1, arg2) end,
	checkLevel3LockFn = function(arg1, arg2) return lockMessage(3, arg1, arg2) end,
	checkLevel4LockFn = function(arg1, arg2) return lockMessage(4, arg1, arg2) end,
	checkCatenaryEnabledFn = catenaryControl,
	checkTrackTypeEnabledFn = trackTypeControl,
	checkTrackTypeLegacyFn = function(arg1, arg2) return trackTypeForYears(false, arg1, arg2) end,
	checkTrackTypeModernFn = function(arg1, arg2) return trackTypeForYears(true, arg1, arg2) end,
	checkHiddenFn = function() return "Hidden" end,
	updateFn = function(captureParams, params)
		local electric = (params.catenary or 2) == 2
		local railModes = electric and {"TRAIN", "ELECTRIC_TRAIN"} or {"TRAIN"}
		local operation = readOperation(params)
		local levels = readLevels(captureParams, params)

		local trackConfig = trackTypes[params.trackType or 2] or trackTypes[2]
		local tracks = {
			inside = trackConfig[electric and 2 or 1],
			outside = trackConfig[electric and 4 or 3],
			tunnel = (tonumber(params.year) or concreteTunnelYear) >= concreteTunnelYear and concreteTunnel or rockTunnel,
		}
		local tramTrackType = tramTrackTypes[electric and 2 or 1]

		local result = {}
		result.subconstructions = {}

		-- A dummy module slot makes the game show the configuration wrench of a built station.
		result.slots = {{
			id = 1,
			transf = transf.transl(vec3.new(0, 0, -500.0)),
			type = "underground_dummy",
			spacing = { 0, 0, 0, 0 },
		}}
		result.slotConfig = {
			underground_dummy = {
				maxModules = 0,
				message = "",
				skipCollisionCheck = true,
			},
		}

		local stoppingNodes = {}
		local nodeCount = 0
		for index, level in ipairs(levels) do
			if level.isTram then
				addTramSilhouette(result, level)
				addTramEdges(result, level, tramTrackType)
				nodeCount = nodeCount + nodesPerTramLevel
			else
				stoppingNodes[index] = addRailEdges(result, level, tracks, nodeCount)
				nodeCount = nodeCount + nodesPerRailLevel
			end
		end

		local mainSubconstruction = {}

		mainSubconstruction.laneLists = {}
		local types = personLaneTypes(operation)

		local lane = laneutil.createLane(generatedData["base"].curves["passenger_entrance_link"], types, 2, 2, true) -- 0
		table.insert(mainSubconstruction.laneLists, lane)

		lane = laneutil.createLane(generatedData["base"].curves["passenger_entrance"], types, 2, 2, false) -- 1
		table.insert(mainSubconstruction.laneLists, lane)

		local splits = {}
		for index, level in ipairs(levels) do splits[index] = level.angle - 90 end
		lane = laneutil.createLane(makeCircleEdges(ringZ, ringRadius, splits), types, 2, 2, false) -- 2
		table.insert(mainSubconstruction.laneLists, lane)

		local lanes = {}
		for index, level in ipairs(levels) do
			lanes[index] = addLevelLanes(mainSubconstruction, level, operation)
		end

		mainSubconstruction.models = { }
		addSurface(mainSubconstruction, params, operation)
		for _, level in ipairs(levels) do
			addLevelModels(mainSubconstruction, params, level, operation)
		end

		local station = {
			terminals = {},
			tag = 1,
			pool = {
				edges = {},
				capacity = 0
			},
		}
		for index, level in ipairs(levels) do
			for track = 1, 2 do
				local terminal
				if level.isTram then
					terminal = makeTerminal(lanes[index].platform[track], { lanes[index].vehicle[track], 1 }, tramModes, level.halfLength*2, operation)
				else
					terminal = makeTerminal(lanes[index].platform[track], { -1, stoppingNodes[index][track] }, railModes, level.halfLength*2, operation)
				end
				table.insert(station.terminals, terminal)
			end
		end

		station.catchmentAreas = {}

		local catchmentArea = {
			position = { 0.0, 0.0, 0.0 },
			radius = 200
		}

		table.insert(station.catchmentAreas, catchmentArea)

		mainSubconstruction.station = station

		constructionutil.addStationCapacities(mainSubconstruction)

		addGround(mainSubconstruction, operation)

		table.insert(result.subconstructions, mainSubconstruction)

		result.maintenanceCost = 75000
		for _, level in ipairs(levels) do
			result.maintenanceCost = result.maintenanceCost + level.halfLength * 650
		end
		result.cost = result.maintenanceCost * 6

		result.snapPoint = {
			transf = transf.transl(vec3.new(0, 8.0, 0)),

			snapToBaseEdgeTypes = {"STREET"},

			allowSnapToBaseEdgeEnds = true,
		}

		return result
	end
}

end
