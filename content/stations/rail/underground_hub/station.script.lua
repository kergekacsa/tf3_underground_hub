-- Adapted from the base-game underground tram station (Urban Games).
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
	for i=1, #curve do
		local points = curve[i]
		local transfCurv = {}
		for j = 1, #points do
			transfCurv[j] = mul(mat, points[j])
		end
		ret[i] = transfCurv
	end

	return ret
end

local function makeCircleEdges(depth, radius, split_deg)
	local function arc_to_bezier(r, a0, a1, depth)
		local theta = a1 - a0
		local mid = (a0 + a1) / 2
		local cos0, sin0 = math.cos(a0), math.sin(a0)
		local cos1, sin1 = math.cos(a1), math.sin(a1)
		local cosM, sinM = math.cos(mid), math.sin(mid)

		local p0 = { r * cos0, r * sin0, depth }
		local p2 = { r * cos1, r * sin1, depth }

		local control_radius = r / math.cos(theta / 2)
		local p1 = { control_radius * math.cos(mid), control_radius * math.sin(mid), depth }

		return { p0, p1, p2 }
	end

	-- Collect all breakpoints (≤45° + custom splits)
	local breaks = {}
	for a = 0, 360, 45 do
		table.insert(breaks, a)
	end
	table.insert(breaks, split_deg % 360)
	table.insert(breaks, (split_deg + 180) % 360)

	-- Sort and deduplicate
	table.sort(breaks)
	local unique = {}
	for _, a in ipairs(breaks) do
		if #unique == 0 or math.abs(a - unique[#unique]) > 1e-6 then
			table.insert(unique, a)
		end
	end
	if unique[#unique] < 360 then
		table.insert(unique, 360)
	end

	-- Create segments
	local segments = {}
	for i = 1, #unique - 1 do
		local a0, a1 = math.rad(unique[i]), math.rad(unique[i + 1])
		table.insert(segments, arc_to_bezier(radius, a0, a1, depth))
	end

	return segments
end

local function makeEdge(origin, direction, length)
	return {{  
			{ origin[1] + direction[1] * length, origin[2] + direction[2] * length, origin[3] }, { origin[1], origin[2], origin[3] }, 
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

--Begin Generated
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
				-- top level
				{ { 3, 9, 0 }, { 3, 20, 0 }, },
				{ { 3, 20, 0 }, { 0, 20, 0 }, },

			},
			["passenger_entrance"] = {
				-- top level
				{ { -3, 9, 0 }, { -3, 20, 0 }, },
				{ { -3, 20, 0 }, { 0, 20, 0 }, },

				{ { 0, 20, 0 }, { 0, 17.51, 0.057 }, },

				-- stairs
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
				-- inside
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
					{ 20.0, -14.0, -20.5 }, { -20.0, -14.0, -20.5 }, { -20.0, 14.0, -20.5 }, { 20.0, 14.0, -20.5 }, 
				},
			},
		},
		models = {
			["models/stairs.mdl"] = {
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
					{ 9.0, -10.0, -20.5 }, { 0.0, -10.0, -20.5 }, { 0.0, 10.0, -20.5 }, { 9.0, 10.0, -20.5 }, 
				},
			},
		},
		models = {
			["models/extension.mdl"] = {
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
--End Generated

-- Place station names independently from the native 10 m repeat sections.
local nameBoard = "::/assets/stations/rail/era_c_station_name.mdl"
generatedData.rotated.models[nameBoard] = nil
generatedData.extended.models[nameBoard] = nil
local platformBench = "::/assets/buildings/res/grd_frn/bench_c_metal.mdl"
generatedData.rotated.models[platformBench] = nil
generatedData.extended.models[platformBench] = nil
local platformBin = "::/assets/buildings/com/misc/trashcan_c_01.mdl"
generatedData.rotated.models[platformBin] = nil
generatedData.extended.models[platformBin] = nil

local function widenPoint(p)
    local side = math.max(0,math.min(1,(math.abs(p[2])-3.45)/0.25))
    local low = math.max(0,math.min(1,(-12-p[3])/2.15))
    p[2] = p[2] + (p[2] < 0 and -1 or 1)*0.35*side*low
end
for _, key in ipairs({"rotated", "extended"}) do
    for curveName, curves in pairs(generatedData[key].curves) do
        if curveName ~= "collider" then
            for _, curve in ipairs(curves) do for _, p in ipairs(curve) do widenPoint(p) end end
        end
    end
    for model, placements in pairs(generatedData[key].models) do
        if model:sub(1,2) == "::" then
            for _, m in ipairs(placements) do
                local p = {m[13],m[14],m[15]}; widenPoint(p); m[14]=p[2]
            end
        end
    end
end


local japaneseModels = {
["models/stairs.mdl"] = "models/jp_stairs.mdl",
["models/extension.mdl"] = "models/jp_extension.mdl",
["models/end.mdl"] = "models/jp_end.mdl",
["models/portal_transition.mdl"] = "models/jp_portal_transition.mdl",
["models/layout_02_repeat.mdl"] = "models/jp_layout_02_repeat.mdl",
["models/layout_02_centre.mdl"] = "models/jp_layout_02_centre.mdl",
    ["models/layout_02_compact.mdl"] = "models/jp_layout_02_compact.mdl",
["models/layout_02_end.mdl"] = "models/jp_layout_02_end.mdl",
["models/layout_03_repeat.mdl"] = "models/jp_layout_03_repeat.mdl",
["models/layout_03_centre.mdl"] = "models/jp_layout_03_centre.mdl",
    ["models/layout_03_compact.mdl"] = "models/jp_layout_03_compact.mdl",
["models/layout_03_end.mdl"] = "models/jp_layout_03_end.mdl",
["models/layout_04_repeat.mdl"] = "models/jp_layout_04_repeat.mdl",
["models/layout_04_centre.mdl"] = "models/jp_layout_04_centre.mdl",
    ["models/layout_04_compact.mdl"] = "models/jp_layout_04_compact.mdl",
["models/layout_04_end.mdl"] = "models/jp_layout_04_end.mdl",
["models/layout_05_repeat.mdl"] = "models/jp_layout_05_repeat.mdl",
["models/layout_05_centre.mdl"] = "models/jp_layout_05_centre.mdl",
    ["models/layout_05_compact.mdl"] = "models/jp_layout_05_compact.mdl",
["models/layout_05_end.mdl"] = "models/jp_layout_05_end.mdl",
["models/layout_06_repeat.mdl"] = "models/jp_layout_06_repeat.mdl",
["models/layout_06_centre.mdl"] = "models/jp_layout_06_centre.mdl",
    ["models/layout_06_compact.mdl"] = "models/jp_layout_06_compact.mdl",
["models/layout_06_end.mdl"] = "models/jp_layout_06_end.mdl",
["models/layout_07_repeat.mdl"] = "models/jp_layout_07_repeat.mdl",
["models/layout_07_centre.mdl"] = "models/jp_layout_07_centre.mdl",
    ["models/layout_07_compact.mdl"] = "models/jp_layout_07_compact.mdl",
["models/layout_07_end.mdl"] = "models/jp_layout_07_end.mdl",
["::/stations/street/underground_station/models/underground_station_surface.mdl"] = "models/jp_surface.mdl",
["::/assets/stations/rail/era_c_station_name.mdl"] = "models/jp_station_name.mdl",
}
local function applyInteriorStyle(result, params)
    if params.interiorStyle == 2 then
        for _, sub in ipairs(result.subconstructions) do
            for _, model in ipairs(sub.models) do
                model.id = japaneseModels[model.id] or model.id
            end
        end
    end
    return result
end

local stationLayouts = {{
["index"] = 1,
["sequence"] = "P S C S P",
["halfWidth"] = 9,
["tracks"] = {{
["y"] = -2.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -5.15,
["direction"] = 1,
}, {
["y"] = 2.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = 5.15,
["direction"] = -1,
}},
["platforms"] = {{
["lo"] = -9,
["hi"] = -4.35,
["centre"] = -7,
["left"] = false,
["right"] = true,
["island"] = false,
}, {
["lo"] = 4.35,
["hi"] = 9,
["centre"] = 7,
["left"] = true,
["right"] = false,
["island"] = false,
}},
["columns"] = {0},
["repeatModel"] = "models/extension.mdl",
["centreModel"] = "models/stairs.mdl",
["endModel"] = "models/portal_transition.mdl",
}, {
["index"] = 2,
["sequence"] = "P S C V V C S P",
["halfWidth"] = 14,
["tracks"] = {{
["y"] = -7.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -10.15,
["direction"] = 1,
}, {
["y"] = -2.5,
["stop"] = false,
}, {
["y"] = 2.5,
["stop"] = false,
}, {
["y"] = 7.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = 10.15,
["direction"] = -1,
}},
["platforms"] = {{
["lo"] = -14,
["hi"] = -9.35,
["centre"] = -12,
["left"] = false,
["right"] = true,
["island"] = false,
}, {
["lo"] = 9.35,
["hi"] = 14,
["centre"] = 12,
["left"] = true,
["right"] = false,
["island"] = false,
}},
["columns"] = {-5, 5},
["repeatModel"] = "models/layout_02_repeat.mdl",
["centreModel"] = "models/layout_02_centre.mdl",
        ["compactModel"] = "models/layout_02_compact.mdl",
["endModel"] = "models/layout_02_end.mdl",
}, {
["index"] = 3,
["sequence"] = "S P S",
["halfWidth"] = 8,
["tracks"] = {{
["y"] = -5.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -2.85,
["direction"] = -1,
}, {
["y"] = 5.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = 2.85,
["direction"] = 1,
}},
["platforms"] = {{
["lo"] = -3.65,
["hi"] = 3.65,
["centre"] = 0,
["left"] = true,
["right"] = true,
["island"] = true,
}},
["columns"] = {},
["repeatModel"] = "models/layout_03_repeat.mdl",
["centreModel"] = "models/layout_03_centre.mdl",
        ["compactModel"] = "models/layout_03_compact.mdl",
["endModel"] = "models/layout_03_end.mdl",
}, {
["index"] = 4,
["sequence"] = "V C S P S C V",
["halfWidth"] = 13,
["tracks"] = {{
["y"] = -10.5,
["stop"] = false,
}, {
["y"] = -5.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -2.85,
["direction"] = -1,
}, {
["y"] = 5.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = 2.85,
["direction"] = 1,
}, {
["y"] = 10.5,
["stop"] = false,
}},
["platforms"] = {{
["lo"] = -3.65,
["hi"] = 3.65,
["centre"] = 0,
["left"] = true,
["right"] = true,
["island"] = true,
}},
["columns"] = {-8, 8},
["repeatModel"] = "models/layout_04_repeat.mdl",
["centreModel"] = "models/layout_04_centre.mdl",
        ["compactModel"] = "models/layout_04_compact.mdl",
["endModel"] = "models/layout_04_end.mdl",
}, {
["index"] = 5,
["sequence"] = "P S C S P S C S P",
["halfWidth"] = 17,
["tracks"] = {{
["y"] = -10.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -13.15,
["direction"] = 1,
}, {
["y"] = -5.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = -2.85,
["direction"] = -1,
}, {
["y"] = 5.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = 2.85,
["direction"] = 1,
}, {
["y"] = 10.5,
["stop"] = true,
["platform"] = 3,
["passengerY"] = 13.15,
["direction"] = -1,
}},
["platforms"] = {{
["lo"] = -17,
["hi"] = -12.35,
["centre"] = -15,
["left"] = false,
["right"] = true,
["island"] = false,
}, {
["lo"] = -3.65,
["hi"] = 3.65,
["centre"] = 0,
["left"] = true,
["right"] = true,
["island"] = true,
}, {
["lo"] = 12.35,
["hi"] = 17,
["centre"] = 15,
["left"] = true,
["right"] = false,
["island"] = false,
}},
["columns"] = {-8, 8},
["repeatModel"] = "models/layout_05_repeat.mdl",
["centreModel"] = "models/layout_05_centre.mdl",
        ["compactModel"] = "models/layout_05_compact.mdl",
["endModel"] = "models/layout_05_end.mdl",
}, {
["index"] = 6,
["sequence"] = "P S C V C S P S C V C S P",
["halfWidth"] = 22,
["tracks"] = {{
["y"] = -15.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -18.15,
["direction"] = 1,
}, {
["y"] = -10.5,
["stop"] = false,
}, {
["y"] = -5.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = -2.85,
["direction"] = -1,
}, {
["y"] = 5.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = 2.85,
["direction"] = 1,
}, {
["y"] = 10.5,
["stop"] = false,
}, {
["y"] = 15.5,
["stop"] = true,
["platform"] = 3,
["passengerY"] = 18.15,
["direction"] = -1,
}},
["platforms"] = {{
["lo"] = -22,
["hi"] = -17.35,
["centre"] = -20,
["left"] = false,
["right"] = true,
["island"] = false,
}, {
["lo"] = -3.65,
["hi"] = 3.65,
["centre"] = 0,
["left"] = true,
["right"] = true,
["island"] = true,
}, {
["lo"] = 17.35,
["hi"] = 22,
["centre"] = 20,
["left"] = true,
["right"] = false,
["island"] = false,
}},
["columns"] = {-13, -8, 8, 13},
["repeatModel"] = "models/layout_06_repeat.mdl",
["centreModel"] = "models/layout_06_centre.mdl",
        ["compactModel"] = "models/layout_06_compact.mdl",
["endModel"] = "models/layout_06_end.mdl",
}, {
["index"] = 7,
["sequence"] = "S P S C V V C S P S",
["halfWidth"] = 21,
["tracks"] = {{
["y"] = -18.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -15.85,
["direction"] = -1,
}, {
["y"] = -7.5,
["stop"] = true,
["platform"] = 1,
["passengerY"] = -10.15,
["direction"] = 1,
}, {
["y"] = -2.5,
["stop"] = false,
}, {
["y"] = 2.5,
["stop"] = false,
}, {
["y"] = 7.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = 10.15,
["direction"] = -1,
}, {
["y"] = 18.5,
["stop"] = true,
["platform"] = 2,
["passengerY"] = 15.85,
["direction"] = 1,
}},
["platforms"] = {{
["lo"] = -16.65,
["hi"] = -9.35,
["centre"] = -13,
["left"] = true,
["right"] = true,
["island"] = true,
}, {
["lo"] = 9.35,
["hi"] = 16.65,
["centre"] = 13,
["left"] = true,
["right"] = true,
["island"] = true,
}},
["columns"] = {-5, 5},
["repeatModel"] = "models/layout_07_repeat.mdl",
["centreModel"] = "models/layout_07_centre.mdl",
        ["compactModel"] = "models/layout_07_compact.mdl",
["endModel"] = "models/layout_07_end.mdl",
}}
-- Inserted by the build tool after the shared native construction helpers.
-- Only runs when a layout other than the original two side platforms is chosen.
local function updateAlternativeLayout(captureParams, params)
    local config = stationLayouts[params.layout]
    local length = captureParams.platformLengths[params.platformLength or 2]
    local half = length * 0.5
    local compact = length < 80
    local stairTop = compact and 9.5 or 20
    local stairBottom = compact and 17.5 or 30
    local stairLanding = compact and 19 or 32
    local centreHalf = compact and 20 or 40
    local angle = ((params.platformOrientation or 1) - 1) * captureParams.stepIncrement
    local rotate = transf.rotZ(math.rad(angle))
    local electric = (params.catenary or 2) == 2
    local modes = electric and {"TRAIN", "ELECTRIC_TRAIN"} or {"TRAIN"}
    local kind = ({"simple", "standard", "high_speed"})[params.trackType or 2] or "standard"
    local suffix = kind == "standard" and "" or "_" .. kind
    local ballastless = params.ballast == 2
    local insideTrack = "track" .. suffix .. (electric and "_electric" or "") .. (ballastless and "_no_ballast" or "") .. ".street_template"
    local outsideTrack = "::/infrastructure/track/" .. kind .. "/" .. kind .. (electric and "_catenary" or "") .. ".street_template"
    local outsideTunnel = (params.tunnelType or 1) == 2 and "::/infrastructure/tunnel/tunnel_a.tunnel" or "::/infrastructure/tunnel/tunnel_b.tunnel"
    local result = {edgeLists = {}, subconstructions = {}}
    local sub = {laneLists = {}, models = {}}

    local function lane(curves, rotated, width, link)
        local index = #sub.laneLists
        sub.laneLists[index+1] = laneutil.createLane(rotated and transform(curves, rotate) or curves, {"PERSON"}, width or 2, width or 2, link or false)
        return index
    end
    local function model(id, x, y, z, yaw)
        sub.models[#sub.models+1] = {id=id, transf=transf.mul(rotate, transf.rotZTransl(yaw or 0, vec3.new(x or 0,y or 0,z or 0)))}
    end
    lane(generatedData.base.curves.passenger_entrance_link, false, 2, true)
    lane(generatedData.base.curves.passenger_entrance, false)
    lane(makeCircleEdges(-12,8.5,angle-90), false)
    constructionutil.addModelsAndGroups(params, generatedData.base, sub)

    -- The concourse is above the trains. It links the native entrance ring to
    -- two staircases per platform; no pedestrian route crosses a running track.
    local spine = {-8.5, 0, 8.5}
    for _, p in ipairs(config.platforms) do spine[#spine+1] = p.centre end
    table.sort(spine)
    local ys = {}
    for _, y in ipairs(spine) do
        if #ys == 0 or math.abs(y-ys[#ys]) > 0.00001 then ys[#ys+1] = y end
    end
    local concourse = {}
    for i=1,#ys-1 do concourse[#concourse+1]={{0,ys[i],-12},{0,ys[i+1],-12}} end
    for _, p in ipairs(config.platforms) do
        for _, s in ipairs({-1,1}) do
            concourse[#concourse+1]={{0,p.centre,-12},{s*stairTop,p.centre,-12}}
            concourse[#concourse+1]={{s*stairTop,p.centre,-12},{s*stairBottom,p.centre,-17.65}}
            concourse[#concourse+1]={{s*stairBottom,p.centre,-17.65},{s*stairLanding,p.centre,-17.65}}
        end
    end
    lane(concourse,true,2)

    local terminals = {}
    for i, track in ipairs(config.tracks) do
        if ballastless then
            for x=-half,half-10,10 do model("models/concrete_track_bed.mdl",x,track.y) end
            model("models/concrete_track_bed_end.mdl",half,track.y)
            model("models/concrete_track_bed_end.mdl",-half,track.y,0,math.pi)
        end
        local direction = track.direction or (i <= #config.tracks/2 and -1 or 1)
        local xs = {-half-0.5,0,half+0.5}
        if direction < 0 then xs = {half+0.5,0,-half-0.5} end
        local curves={{{xs[1],track.y,-19.28},{xs[2],track.y,-19.28}},{{xs[2],track.y,-19.28},{xs[3],track.y,-19.28}}}
        constructionutil.addEdges(transform(curves,rotate),result,"TRACK",{type=insideTrack,edgeType="TUNNEL",edgeTypeName="station_hall.tunnel"},false,{},{})
        for _, sign in ipairs({-1,1}) do
            local near=sign*(half+0.5);local far=near+sign*10
            constructionutil.addEdges(transform({{{far,track.y,-19.28},{near,track.y,-19.28}}},rotate),result,"TRACK",{type=outsideTrack,edgeType="TUNNEL",edgeTypeName=outsideTunnel},false,{0},{0})
        end
        if track.stop then
            local p = config.platforms[track.platform]
            local platformLane = lane(makePassengerLane({0,track.passengerY,-17.65},{direction,0,0},half,stairLanding),true,1.5)
            local connections={}
            for _, s in ipairs({-1,1}) do
                connections[#connections+1]={{s*stairLanding,p.centre,-17.65},{s*stairLanding,track.passengerY,-17.65}}
            end
            lane(connections,true,1.5)
            terminals[#terminals+1]={
                personEdges={{platformLane,2},{platformLane,0},{platformLane,1}},
                personNodes={{platformLane,2},{platformLane,0},{platformLane,1}},
                vehicleNode={-1,(i-1)*8+1},transportModes=modes,
                cargoTransferSpeeds={{cargoTypeSet={cargoClassesIncluded={"PASSENGERS"}},loadSpeedModifier=1,length=length}},
                passengers=true,cargo=false,
            }
        end
    end

    model(compact and config.compactModel or config.centreModel)
    for x=-half,half-10,10 do
        if x < -centreHalf or x >= centreHalf then model(config.repeatModel,x) end
    end
    model(config.endModel,half)
    -- Keep the lateral order, with 20 cm overlap at both ends of the hall.
    model(config.endModel,-half-1.3)

    for _, p in ipairs(config.platforms) do
        local boardCount=math.max(1,math.floor(length/40))
        for j=1,boardCount do
            local x=-half+(j-.5)*length/boardCount
            -- Move the boards beside, rather than inside, a stair opening.
            if math.abs(x)>=19 and math.abs(x)<=33 then x=(x<0 and -1 or 1)*38 end
            if p.island then
                model("::/assets/stations/rail/era_c_station_name.mdl",x,p.centre,-16.15)
                model("models/name_board_support.mdl",x,p.centre)
            else
                local y=p.left and p.hi+.15 or p.lo-.15
                model("::/assets/stations/rail/era_c_station_name.mdl",x,y,-16.15)
            end
        end
        for x=-half+15,half-10,30 do
            if math.abs(x)<stairTop-2 or math.abs(x)>stairLanding+4 then
                if p.left then model("::/assets/buildings/res/grd_frn/bench_c_metal.mdl",x,p.island and p.centre-.36 or p.hi-.36,-17.65,-math.pi/2) end
                if p.right then model("::/assets/buildings/res/grd_frn/bench_c_metal.mdl",x,p.island and p.centre+.36 or p.lo+.36,-17.65,math.pi/2) end
            end
        end
    end

    local function volume(x0,x1,y0,y1,z0,z1)
        local shell={curves={collider={{{x0,y0,z0},{x1,y0,z0},{x1,y1,z0},{x0,y1,z0},{x0,y0,z1},{x1,y0,z1},{x1,y1,z1},{x0,y1,z1}}}}}
        constructionutil.addModelsAndGroups(params,shell,sub,nil,rotate)
    end
    volume(-half,half,-config.halfWidth-.2,config.halfWidth+.2,-20.5,-12.04)
    local w=math.max(config.halfWidth,10)+.2
    volume(-stairTop-.2,stairTop+.2,-w,w,-12.04,-8.3)
    for _, p in ipairs(config.platforms) do
        for _, s in ipairs({-1,1}) do volume(s<0 and -stairLanding-.2 or stairTop,s<0 and -stairTop or stairLanding+.2,p.centre-1.5,p.centre+1.5,-12.5,-8.3) end
    end
    sub.station={terminals=terminals,tag=1,pool={edges={},capacity=0},catchmentAreas={{position={0,0,0},radius=200}}}
    constructionutil.addStationCapacities(sub)
    modulesutil.addGroundFaces("::/stations/street/underground_station/underground_station.gtex",generatedData,sub)
    result.subconstructions={sub}
    result.maintenanceCost=75000+half*650*(#config.tracks/2)+#config.platforms*8000
    result.cost=result.maintenanceCost*6
    result.snapPoint={transf=transf.transl(vec3.new(0,8,0)),snapToBaseEdgeTypes={"STREET"},allowSnapToBaseEdgeEnds=true}
    return applyInteriorStyle(result, params)
end


function data()

return {
	createTemplateFn = function(captureParams, params)
		local result = {}
		return result
	end,
	updateFn = function(captureParams, params)
        if params.layout and params.layout >= 2 and params.layout <= 7 then return updateAlternativeLayout(captureParams,params) end
		local updateParams = captureParams
		local platformLenghts = updateParams.platformLengths
		local stepIncrement = updateParams.stepIncrement
		local platformAngle = ((params.platformOrientation or 1) - 1) * stepIncrement
		local platformTransform = transf.rotZ( math.rad(platformAngle))

		local electric = (params.catenary or 2) == 2
		local modes = electric and {"TRAIN", "ELECTRIC_TRAIN"} or {"TRAIN"}

		local result = {}
		result.subconstructions = {}

		local freeNodesList = { 0 }
		local snapNodes = { 0 }

		local halfLength = platformLenghts[params.platformLength or 2] * 0.5

		-- Real railway edges span the platforms. Four free outer nodes connect
        -- to ordinary rail tunnels; the station supplies its own tunnel walls.
        local trackZ = -19.28
        local trackTypes = {
            {"track_simple.street_template", "track_simple_electric.street_template",
             "::/infrastructure/track/simple/simple.street_template", "::/infrastructure/track/simple/simple_catenary.street_template"},
            {"track.street_template", "track_electric.street_template",
             "::/infrastructure/track/standard/standard.street_template", "::/infrastructure/track/standard/standard_catenary.street_template"},
            {"track_high_speed.street_template", "track_high_speed_electric.street_template",
             "::/infrastructure/track/high_speed/high_speed.street_template", "::/infrastructure/track/high_speed/high_speed_catenary.street_template"},
        }
        -- Existing stations without the new parameter keep standard track.
        local trackConfig = trackTypes[params.trackType or 2] or trackTypes[2]
        local trackType = trackConfig[electric and 2 or 1]
        if params.ballast == 2 then trackType = trackType:gsub("%.street_template$", "_no_ballast.street_template") end
        local outsideTrack = trackConfig[electric and 4 or 3]
        local outsideTunnel = (params.tunnelType or 1) == 2 and "::/infrastructure/tunnel/tunnel_a.tunnel" or "::/infrastructure/tunnel/tunnel_b.tunnel"
        local stoppingNodes = {}
        for track = 1, 2 do
            local y = track == 1 and -2.5 or 2.5
            local xs = {-halfLength-edgeBuffer, 0, halfLength+edgeBuffer}
            if track == 2 then for n = 1, #xs do xs[n] = -xs[n] end end
            local curves = {}
            for n = 1, #xs-1 do
                curves[#curves+1] = {{xs[n],y,trackZ},{xs[n+1],y,trackZ}}
            end
            constructionutil.addEdges(transform(curves, platformTransform), result, "TRACK", {
                type = trackType, edgeType = "TUNNEL", edgeTypeName = "station_hall.tunnel"
            }, false, {}, {})
            -- Zero-based node index in the flattened construction edge lists.
            stoppingNodes[track] = (track-1)*8 + 1
            for _, direction in ipairs({-1,1}) do
                local inside = direction*(halfLength+edgeBuffer)
                local outside = inside + direction*10
                constructionutil.addEdges(transform({{{outside,y,trackZ},{inside,y,trackZ}}},platformTransform),result,"TRACK",{
                    type=outsideTrack,edgeType="TUNNEL",edgeTypeName=outsideTunnel
                },false,{0},{0})
            end
        end

		local mainSubconstruction = {}

		mainSubconstruction.laneLists = {}

		local lane = laneutil.createLane(generatedData["base"].curves["passenger_entrance_link"], {"PERSON",}, 2, 2, true) -- 0
		table.insert(mainSubconstruction.laneLists, lane)

		local lane = laneutil.createLane(generatedData["base"].curves["passenger_entrance"], {"PERSON",}, 2, 2, false) -- 1
		table.insert(mainSubconstruction.laneLists, lane)

		lane = laneutil.createLane(makeCircleEdges(-12, 8.5, platformAngle - 90), {"PERSON",}, 2, 2, false) -- 2
		table.insert(mainSubconstruction.laneLists, lane)

		lane = laneutil.createLane(transform(generatedData["rotated"].curves["passenger_passageway"], platformTransform), {"PERSON",}, 2, 2, false) -- 3
		table.insert(mainSubconstruction.laneLists, lane)

		local passengerPlatform1 = makePassengerLane({ 0, -5.35, -17.65 }, { -1.0, 0.0, 0.0 }, halfLength, 14.66)
		local passengerPlatform2 = makePassengerLane({ 0, 5.35, -17.65 }, { 1.0, 0.0, 0.0 }, halfLength, 14.66)

		lane = laneutil.createLane(transform(passengerPlatform1, platformTransform), {"PERSON",}, 2, 2, false)  -- 4
		table.insert(mainSubconstruction.laneLists, lane)

		lane = laneutil.createLane(transform(passengerPlatform2, platformTransform), {"PERSON",}, 2, 2, false)  -- 5
		table.insert(mainSubconstruction.laneLists, lane)


		mainSubconstruction.models = { }

		
		constructionutil.addModelsAndGroups(params, generatedData["base"], mainSubconstruction)
		constructionutil.addModelsAndGroups(params, generatedData["rotated"], mainSubconstruction, nil, platformTransform)

		mainSubconstruction.models[#mainSubconstruction.models + 1] = {
			id = "models/end.mdl",
			transf = transf.mul(transf.rotZ(math.rad(platformAngle)), transf.transl(vec3.new(halfLength, 0, 0)))
		}
		mainSubconstruction.models[#mainSubconstruction.models + 1] = {
			id = "models/end.mdl",
			transf = transf.mul(transf.rotZ(math.rad(platformAngle + 180)), transf.transl(vec3.new(halfLength, 0, 0))) 
		}

		for i = 20, halfLength - 10, 10 do 
			constructionutil.addModelsAndGroups(params, generatedData["extended"], mainSubconstruction, nil, transf.mul(transf.rotZ(math.rad(platformAngle)), transf.transl(vec3.new(i, 0, 0))))
			constructionutil.addModelsAndGroups(params, generatedData["extended"], mainSubconstruction, nil, transf.mul(transf.rotZ(math.rad(platformAngle + 180)), transf.transl(vec3.new(i, 0, 0))))
		end

        -- One name board every 40 m on each platform, centred in each bay.
        local boardCount = math.max(1, math.floor(halfLength * 2 / 40))
        for i = 1, boardCount do
            local x = -halfLength + (i - 0.5) * halfLength * 2 / boardCount
            for _, y in ipairs({-7.5, 7.5}) do
                mainSubconstruction.models[#mainSubconstruction.models+1] = {
                    id = nameBoard,
                    transf = transf.mul(platformTransform, transf.transl(vec3.new(x, y, -16.15)))
                }
            end
        end
        for x = -halfLength + 15, halfLength - 10, 30 do
            -- Native stair exits cross each platform at x = +/-14.66 m.
            -- Keep the full bench footprint and a clear landing off this aisle.
            if math.abs(math.abs(x) - 14.66) > 4 then
                for _, y in ipairs({-6.99, 6.99}) do
                    mainSubconstruction.models[#mainSubconstruction.models+1] = {
                        id = platformBench,
                        transf = transf.mul(platformTransform, transf.rotZTransl(y < 0 and math.pi/2 or -math.pi/2, vec3.new(x,y,-17.65)))
                    }
                end
            end
        end
        -- A few bins along the walls, independent of the repeated hall pieces.
        local binCount = math.max(1, math.floor(halfLength * 2 / 60))
        for i = 1, binCount do
            local x = -halfLength + (i - .5) * halfLength * 2 / binCount
            if math.abs(math.abs(x) - 14.66) > 4 then
                for _, y in ipairs({-6.85, 6.85}) do
                    mainSubconstruction.models[#mainSubconstruction.models+1] = {
                        id = platformBin,
                        transf = transf.mul(platformTransform, transf.rotZTransl(y < 0 and -math.pi/2 or math.pi/2, vec3.new(x,y,-17.65)))
                    }
                end
            end
        end
        if params.ballast == 2 then
            for _, y in ipairs({-2.5, 2.5}) do
                for x = -halfLength, halfLength - 10, 10 do
                    mainSubconstruction.models[#mainSubconstruction.models+1] = {
                        id = "models/concrete_track_bed.mdl",
                        transf = transf.mul(platformTransform, transf.transl(vec3.new(x,y,0)))
                    }
                end
                for _, sign in ipairs({-1,1}) do
                    mainSubconstruction.models[#mainSubconstruction.models+1] = {
                        id = "models/concrete_track_bed_end.mdl",
                        transf = transf.mul(platformTransform, transf.rotZTransl(sign < 0 and math.pi or 0, vec3.new(sign*halfLength,y,0)))
                    }
                end
            end
        end
        -- Close the difference between the low tram hall and taller rail tunnel.
        for _, angle in ipairs({platformAngle, platformAngle + 180}) do
            mainSubconstruction.models[#mainSubconstruction.models+1] = {
                id = "models/portal_transition.mdl",
                transf = transf.mul(transf.rotZ(math.rad(angle)), transf.transl(vec3.new(halfLength, 0, 0)))
            }
        end

		local station = {
			terminals = {},
			tag = 1,
			pool = {
				edges = {},
				capacity = 0
			},
		}

		local terminal1 = {
			personEdges = { { 4, 2 }, { 4, 0 }, { 4, 1 }, },
			personNodes = { { 4, 2 }, { 4, 0 }, { 4, 1 }, },
			vehicleNode = { -1, stoppingNodes[1] },
			transportModes = modes,
		}

		terminal1.cargoTransferSpeeds = {{cargoTypeSet={cargoClassesIncluded={"PASSENGERS"}},loadSpeedModifier=1,length=halfLength*2}}
		terminal1.passengers = true
		terminal1.cargo = false

		local terminal2 = {
			personEdges = { { 5, 2 }, { 5, 0 }, { 5, 1 }, },
			personNodes = { { 5, 2 }, { 5, 0 }, { 5, 1 }, },
			vehicleNode = { -1, stoppingNodes[2] },
			transportModes = modes,
		}

		terminal2.cargoTransferSpeeds = {{cargoTypeSet={cargoClassesIncluded={"PASSENGERS"}},loadSpeedModifier=1,length=halfLength*2}}
		terminal2.passengers = true
		terminal2.cargo = false

		table.insert(station.terminals, terminal1)
		table.insert(station.terminals, terminal2)

		station.catchmentAreas = {}

		local catchmentArea = {
			position = { 0.0, 0.0, 0.0 },
			radius = 200
		}

		table.insert(station.catchmentAreas, catchmentArea)

		mainSubconstruction.station = station

		constructionutil.addStationCapacities(mainSubconstruction)
		
		local groundTexture = "::/stations/street/underground_station/underground_station.gtex"
		modulesutil.addGroundFaces(groundTexture, generatedData, mainSubconstruction)


		table.insert(result.subconstructions, mainSubconstruction)

		result.maintenanceCost = 75000 + halfLength * 650
		result.cost = result.maintenanceCost * 6
		
		result.snapPoint = {
			transf = transf.transl(vec3.new(0, 8.0, 0)),

			snapToBaseEdgeTypes = {"STREET"},
			
			allowSnapToBaseEdgeEnds = true,
		}

		return applyInteriorStyle(result, params)
	end
}

end
