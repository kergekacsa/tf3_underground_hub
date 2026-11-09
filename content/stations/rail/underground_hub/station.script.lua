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

local function makeCircleEdges(depth, radius, split_degs)
	local function arc_to_bezier(r, a0, a1, depth)
		local theta = a1 - a0
		local mid = (a0 + a1) / 2
		local cos0, sin0 = math.cos(a0), math.sin(a0)
		local cos1, sin1 = math.cos(a1), math.sin(a1)

		local p0 = { r * cos0, r * sin0, depth }
		local p2 = { r * cos1, r * sin1, depth }

		local control_radius = r / math.cos(theta / 2)
		local p1 = { control_radius * math.cos(mid), control_radius * math.sin(mid), depth }

		return { p0, p1, p2 }
	end

	-- Collect all breakpoints (≤45° + a split pair per level)
	local breaks = {}
	for a = 0, 360, 45 do
		table.insert(breaks, a)
	end
	for _, split_deg in ipairs(split_degs) do
		table.insert(breaks, split_deg % 360)
		table.insert(breaks, (split_deg + 180) % 360)
	end

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

local tramData = {
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

local trackZ = -19.28
local tramZ = -18.0
local ringZ = -12.0
local ringRadius = 8.5
local levelSpacing = 18.0
local maxLevels = 4
local defaultAngleIndices = { 1, 19, 10, 28 }
local defaultLengthIndex = 2
local nodesPerRailLevel = 16
local nodesPerTramLevel = 4
local tramTrackTypes = { "YES", "ELECTRIC" }
local tramModes = { "TRAM", "ELECTRIC_TRAM" }
local cargoModePassenger, cargoModeCargo = 1, 2
local vehicleTram = 2
local cargoDepotModel = "models/cargo/surface_cargo_depot.mdl"
local palletJackModel = "::/assets/stations/rail/cargo_pallet_jack.mdl"
local tunnelBCar = "::/infrastructure/tunnel/tunnel_b_car.tunnel"
local tramTemplate = "::/infrastructure/street/tram/tram_new.street_template"
local tramEndModel = "::/stations/street/underground_station/models/underground_station_end.mdl"
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
		isPassenger = mode ~= cargoModeCargo,
		isCargo = mode ~= cargoModePassenger,
	}
end

local function readLevels(captureParams, params)
	local count = math.max(1, math.min(maxLevels, tonumber(params.levelCount) or 1))
	local levels = {}
	for k = 1, count do
		levels[k] = {
			isTram = (tonumber(params["level" .. k .. "Vehicle"]) or 1) == vehicleTram,
			angle = ((tonumber(params["level" .. k .. "Angle"]) or defaultAngleIndices[k]) - 1) * captureParams.stepIncrement,
			halfLength = captureParams.platformLengths[tonumber(params["level" .. k .. "Length"]) or defaultLengthIndex] * 0.5,
			dz = -(k - 1) * levelSpacing,
		}
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

-- Real railway edges span the platforms. Four free outer nodes per level connect
-- to ordinary rail tunnels; the station supplies its own tunnel walls.
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
			curves[#curves+1] = {{xs[n],y,trackZ},{xs[n+1],y,trackZ}}
		end
		constructionutil.addEdges(transform(curves, levelTransf), result, "TRACK", {
			type = tracks.inside, edgeType = "TUNNEL", edgeTypeName = "station_hall.tunnel"
		}, false, {}, {})
		-- Zero-based node index in the flattened construction edge lists.
		stoppingNodes[track] = firstNode + (track-1)*8 + 1
		for _, direction in ipairs({-1,1}) do
			local inside = direction*(halfLength+edgeBuffer)
			local outside = inside + direction*10
			constructionutil.addEdges(transform({{{outside,y,trackZ},{inside,y,trackZ}}},levelTransf),result,"TRACK",{
				type=tracks.outside,edgeType="TUNNEL",edgeTypeName=tracks.tunnel
			},false,{0},{0})
		end
	end
	return stoppingNodes
end

-- A tram level has one street edge at each end. Its vehicle lanes lie inside the construction.
local function addTramEdges(result, level, tramTrackType)
	local levelTransf = levelTransform(level)
	local snapNodes = { 0 }
	local freeNodes = { 0 }
	for _, direction in ipairs({1, -1}) do
		local edge = makeEdge({ direction * (level.halfLength + edgeBuffer), 0.0, tramZ }, { direction, 0.0, 0.0 }, 10.0)
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

	local platformY = level.isTram and 5.0 or 5.35
	local passengerPlatform1 = makePassengerLane({ 0, -platformY, -17.65 }, { -1.0, 0.0, 0.0 }, halfLength, 14.66)
	local passengerPlatform2 = makePassengerLane({ 0, platformY, -17.65 }, { 1.0, 0.0, 0.0 }, halfLength, 14.66)

	lanes.platform[1] = #sub.laneLists
	table.insert(sub.laneLists, laneutil.createLane(transform(passengerPlatform1, levelTransf), types, 2, 2, false))
	lanes.platform[2] = #sub.laneLists
	table.insert(sub.laneLists, laneutil.createLane(transform(passengerPlatform2, levelTransf), types, 2, 2, false))

	if level.isTram then
		local vehicle1 = makeVehicleLane({ 0, -2.5, tramZ }, { -1.0, 0.0, 0.0 }, halfLength + edgeBuffer)
		local vehicle2 = makeVehicleLane({ 0, 2.5, tramZ }, { 1.0, 0.0, 0.0 }, halfLength + edgeBuffer)
		lanes.vehicle[1] = #sub.laneLists
		table.insert(sub.laneLists, laneutil.createLane(transform(vehicle1, levelTransf), tramModes, 40, 2, false))
		lanes.vehicle[2] = #sub.laneLists
		table.insert(sub.laneLists, laneutil.createLane(transform(vehicle2, levelTransf), tramModes, 40, 2, false))
	end
	return lanes
end

local function addRailLevelModels(sub, params, level, operation)
	local halfLength = level.halfLength
	local levelTransf = levelTransform(level)

	local rotated = generatedData["rotated"]
	if not operation.isPassenger then
		rotated = { curves = rotated.curves, models = filterModels(rotated.models, operation, false) }
	end
	constructionutil.addModelsAndGroups(params, rotated, sub, nil, levelTransf)

	sub.models[#sub.models + 1] = {
		id = "models/end.mdl",
		transf = transf.mul(levelTransform(level), transf.transl(vec3.new(halfLength, 0, 0)))
	}
	sub.models[#sub.models + 1] = {
		id = "models/end.mdl",
		transf = transf.mul(levelTransform(level, 180), transf.transl(vec3.new(halfLength, 0, 0)))
	}

	for i = 20, halfLength - 10, 10 do
		constructionutil.addModelsAndGroups(params, generatedData["extended"], sub, nil, transf.mul(levelTransform(level), transf.transl(vec3.new(i, 0, 0))))
		constructionutil.addModelsAndGroups(params, generatedData["extended"], sub, nil, transf.mul(levelTransform(level, 180), transf.transl(vec3.new(i, 0, 0))))
	end

	-- One name board every 40 m on each platform, centred in each bay.
	local boardCount = math.max(1, math.floor(halfLength * 2 / 40))
	for i = 1, boardCount do
		local x = -halfLength + (i - 0.5) * halfLength * 2 / boardCount
		for _, y in ipairs({-7.5, 7.5}) do
			sub.models[#sub.models+1] = {
				id = nameBoard,
				transf = transf.mul(levelTransf, transf.transl(vec3.new(x, y, -16.15)))
			}
		end
	end
	if operation.isPassenger then
		for x = -halfLength + 15, halfLength - 10, 30 do
			-- Native stair exits cross each platform at x = +/-14.66 m.
			-- Keep the full bench footprint and a clear landing off this aisle.
			if math.abs(math.abs(x) - 14.66) > 4 then
				for _, y in ipairs({-6.99, 6.99}) do
					sub.models[#sub.models+1] = {
						id = platformBench,
						transf = transf.mul(levelTransf, transf.rotZTransl(y < 0 and math.pi/2 or -math.pi/2, vec3.new(x,y,-17.65)))
					}
				end
			end
		end
	end
	-- A few bins along the walls, independent of the repeated hall pieces.
	local binCount = math.max(1, math.floor(halfLength * 2 / 60))
	for i = 1, binCount do
		local x = -halfLength + (i - .5) * halfLength * 2 / binCount
		if math.abs(math.abs(x) - 14.66) > 4 then
			for _, y in ipairs({-6.85, 6.85}) do
				sub.models[#sub.models+1] = {
					id = platformBin,
					transf = transf.mul(levelTransf, transf.rotZTransl(y < 0 and -math.pi/2 or math.pi/2, vec3.new(x,y,-17.65)))
				}
			end
		end
	end
	if params.ballast == 2 then
		for _, y in ipairs({-2.5, 2.5}) do
			for x = -halfLength, halfLength - 10, 10 do
				sub.models[#sub.models+1] = {
					id = "models/concrete_track_bed.mdl",
					transf = transf.mul(levelTransf, transf.transl(vec3.new(x,y,0)))
				}
			end
			for _, sign in ipairs({-1,1}) do
				sub.models[#sub.models+1] = {
					id = "models/concrete_track_bed_end.mdl",
					transf = transf.mul(levelTransf, transf.rotZTransl(sign < 0 and math.pi or 0, vec3.new(sign*halfLength,y,0)))
				}
			end
		end
	end
	-- Close the difference between the low tram hall and taller rail tunnel.
	for _, extraAngle in ipairs({0, 180}) do
		sub.models[#sub.models+1] = {
			id = "models/portal_transition.mdl",
			transf = transf.mul(levelTransform(level, extraAngle), transf.transl(vec3.new(halfLength, 0, 0)))
		}
	end
end

local function addTramLevelModels(sub, params, level, operation)
	local halfLength = level.halfLength
	local levelTransf = levelTransform(level)

	constructionutil.addModelsAndGroups(params, {
		curves = tramData.rotated.curves,
		models = filterModels(tramData.rotated.models, operation, false),
	}, sub, nil, levelTransf)

	sub.models[#sub.models + 1] = {
		id = tramEndModel,
		transf = transf.mul(levelTransf, transf.transl(vec3.new(halfLength, 0, 0)))
	}
	sub.models[#sub.models + 1] = {
		id = tramEndModel,
		transf = transf.mul(levelTransf, transf.mul(transf.rotZ(math.rad(180)), transf.transl(vec3.new(halfLength, 0, 0))))
	}

	local extended = { curves = tramData.extended.curves, models = filterModels(tramData.extended.models, operation, false) }
	for i = 20, halfLength - 10, 10 do
		constructionutil.addModelsAndGroups(params, extended, sub, nil, transf.mul(levelTransf, transf.transl(vec3.new(i, 0, 0))))
		constructionutil.addModelsAndGroups(params, extended, sub, nil, transf.mul(levelTransf, transf.mul(transf.rotZ(math.rad(180)), transf.transl(vec3.new(i, 0, 0)))))
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
			if arg.levelCount ~= nil then return arg end
		end
	end
	return nil
end

local function enabledIf(condition)
	return condition and "Enabled" or "Disabled"
end

local function isLevelEnabled(minLevel, arg1, arg2)
	local p = findParams(arg1, arg2)
	return enabledIf(p == nil or (tonumber(p.levelCount) or 1) >= minLevel)
end

local function anyRailLevel(arg1, arg2)
	local p = findParams(arg1, arg2)
	if not p then return "Enabled" end
	for k = 1, math.min(maxLevels, tonumber(p.levelCount) or 1) do
		if (tonumber(p["level" .. k .. "Vehicle"]) or 1) ~= vehicleTram then return "Enabled" end
	end
	return "Disabled"
end

function data()

return {
	createTemplateFn = function(captureParams, params)
		local result = {}
		return result
	end,
	checkLevel2EnabledFn = function(arg1, arg2) return isLevelEnabled(2, arg1, arg2) end,
	checkLevel3EnabledFn = function(arg1, arg2) return isLevelEnabled(3, arg1, arg2) end,
	checkLevel4EnabledFn = function(arg1, arg2) return isLevelEnabled(4, arg1, arg2) end,
	checkRailOptionsEnabledFn = function(arg1, arg2) return anyRailLevel(arg1, arg2) end,
	updateFn = function(captureParams, params)
		local electric = (params.catenary or 2) == 2
		local railModes = electric and {"TRAIN", "ELECTRIC_TRAIN"} or {"TRAIN"}
		local operation = readOperation(params)
		local levels = readLevels(captureParams, params)

		-- Existing stations without the new parameter keep standard track.
		local trackConfig = trackTypes[params.trackType or 2] or trackTypes[2]
		local insideTrack = trackConfig[electric and 2 or 1]
		if params.ballast == 2 then insideTrack = insideTrack:gsub("%.street_template$", "_no_ballast.street_template") end
		local tracks = {
			inside = insideTrack,
			outside = trackConfig[electric and 4 or 3],
			tunnel = (params.tunnelType or 1) == 2 and "::/infrastructure/tunnel/tunnel_a.tunnel" or "::/infrastructure/tunnel/tunnel_b.tunnel",
		}
		local tramTrackType = tramTrackTypes[electric and 2 or 1]

		local result = {}
		result.subconstructions = {}

		local stoppingNodes = {}
		local nodeCount = 0
		for index, level in ipairs(levels) do
			if level.isTram then
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
			if level.isTram then
				addTramLevelModels(mainSubconstruction, params, level, operation)
			else
				addRailLevelModels(mainSubconstruction, params, level, operation)
			end
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

		return applyInteriorStyle(result, params)
	end
}

end
