local support = require("support")

local SCRIPT = "content/stations/rail/underground_hub/station.script.lua"
local SCRIPT_MODULE = "content/stations/rail/underground_hub/hub_script.lua"
local RANGE_MOD_SCRIPT = "content/stations/street/underground_freight/underground_freight.script.lua"
local CON = "content/stations/rail/underground_hub/station.con.lua"
local ROAD_CON = "content/stations/rail/underground_hub/station_tram.con.lua"
local CON_MODULE = "content/stations/rail/underground_hub/hub_con.lua"
local CON_MODULE_NAME = "kacsa_underground_hub::/stations/rail/underground_hub/hub_con.lua"
local CSS = "content/stations/rail/underground_hub/hub_params.css.lua"
local STRINGS = "strings.json"
local CAPTURE = { platformLengths = { 160, 240, 320, 40, 80, 120 }, stepIncrement = 5.0 }
local EPSILON = 1e-6
-- The script names the files of this mod with the mod in front.
local OWN = "kacsa_underground_hub::/stations/rail/underground_hub/"
local DEPOT = "models/cargo/surface_cargo_depot.mdl"

local failures = 0
local function check(condition, message)
	if not condition then
		failures = failures + 1
		print("FAIL " .. message)
	end
end

local function near(a, b) return math.abs(a - b) < EPSILON end

local function build(params)
	local data = support.loadScript(SCRIPT)
	local result = data.updateFn(CAPTURE, params)
	return result, result.subconstructions[1], data
end

-- A construction file of the hub loads the shared module by its name in the game.
local function loadCon(path, env)
	env.require = function(name)
		assert(name == CON_MODULE_NAME, "a construction file loads an unknown module: " .. name)
		return assert(loadfile(CON_MODULE, "t", env))()
	end
	assert(loadfile(path, "t", env))()
	return env.data()
end

local function hasModel(sub, fragment)
	for _, model in ipairs(sub.models) do
		if model.id:find(fragment, 1, true) then return true end
	end
	return false
end

local function laneAt(sub, index) return sub.laneLists[index + 1] end

-- A shaft is a lane of one straight vertical piece.
local function shaftsOf(sub)
	local shafts = {}
	for _, lane in ipairs(sub.laneLists) do
		local curve = lane.curves[1]
		if #lane.curves == 1 and #curve == 2 and near(curve[1][1], curve[2][1]) and near(curve[1][2], curve[2][2]) and not near(curve[1][3], curve[2][3]) then
			shafts[#shafts + 1] = lane
		end
	end
	return shafts
end

-- A stairs walkway is the only lane that spans the 12.35 m from a platform to the ring below.
local STAIR_DROP = 12.35

local function stairWalkwaysOf(sub)
	local walkways = {}
	for _, lane in ipairs(sub.laneLists) do
		local low, high = math.huge, -math.huge
		for _, curve in ipairs(lane.curves) do
			for _, point in ipairs(curve) do
				low, high = math.min(low, point[3]), math.max(high, point[3])
			end
		end
		if near(high - low, STAIR_DROP) then walkways[#walkways + 1] = lane end
	end
	return walkways
end

local function hasNodeAt(sub, point)
	local count = 0
	for _, lane in ipairs(sub.laneLists) do
		for _, curve in ipairs(lane.curves) do
			for _, node in ipairs({ curve[1], curve[#curve] }) do
				if math.abs(node[1] - point[1]) < 1e-6 and math.abs(node[2] - point[2]) < 1e-6 and math.abs(node[3] - point[3]) < 1e-6 then count = count + 1 end
			end
		end
	end
	return count
end

local function countModels(sub, fragment)
	local count = 0
	for _, model in ipairs(sub.models) do
		if model.id:find(fragment, 1, true) then count = count + 1 end
	end
	return count
end

-- Four rail levels: depth, terminals, node indices and stairs.
do
	local result, sub = build({ level2Vehicle = 2, level3Vehicle = 2, level4Vehicle = 2 })
	check(#sub.station.terminals == 8, "four levels give eight terminals")
	check(#result.edgeLists == 24, "four rail levels add 24 edge calls, got " .. #result.edgeLists)
	check(#sub.laneLists == 21, "four rail levels give 21 lanes, got " .. #sub.laneLists)
	for level = 1, 4 do
		local firstEdge = result.edgeLists[(level - 1) * 6 + 1]
		check(near(firstEdge.curves[1][1][3], -18.3 - 18 * (level - 1)), "level " .. level .. " rail track depth, between the floor and the platform")
		for track = 1, 2 do
			local terminal = sub.station.terminals[(level - 1) * 2 + track]
			check(terminal.vehicleNode[1] == -1 and terminal.vehicleNode[2] == ((level - 1) * 2 + track - 1) * 8 + 1,
				"rail terminal node index of level " .. level .. " track " .. track)
			local platformLane = laneAt(sub, terminal.personEdges[1][1])
			check(near(platformLane.curves[1][1][3], -17.65 - 18 * (level - 1)), "level " .. level .. " platform lane depth")
		end
	end
	check(#shaftsOf(sub) == 0, "neighbouring levels have no shaft")
	check(#stairWalkwaysOf(sub) == 3, "four levels have three stairs walkways, found " .. #stairWalkwaysOf(sub))
end

-- The stairs between neighbouring levels. One platform side has nine walkway pieces: three from
-- each of its two corridors to the landing, and three from the landing to the middle of the shared
-- platform. Then each of the two exit stairs has three pieces, from the middle to the ring.
do
	local PIECES_PER_SIDE, EXIT_PIECES = 9, 3
	local SHARED_Z = -27.5986
	local function turned(x, y, degrees)
		local c, s = math.cos(math.rad(degrees)), math.sin(math.rad(degrees))
		return x * c - y * s, x * s + y * c
	end
	local function samePoint(a, b) return near(a[1], b[1]) and near(a[2], b[2]) and near(a[3], b[3]) end
	-- Upper level angle index, lower level angle index, expected exit direction in the frame of the upper level.
	-- The default angles 0 and 90 degrees put the exits on the axis along the upper hall.
	for _, case in ipairs({ { 1, 19, 0 }, { 8, 37, 0 }, { 1, 1, 0 }, { 30, 2, 0 }, { 1, 16, 165 }, { 1, 22, 15 }, { 10, 24, 160 } }) do
		local upperAngle, lowerAngle, exitDirection = (case[1] - 1) * 5, (case[2] - 1) * 5, case[3]
		local label = "angles " .. upperAngle .. " and " .. lowerAngle
		local _, sub = build({ level1Angle = case[1], level2Vehicle = 2, level2Angle = case[2] })
		local walkway = stairWalkwaysOf(sub)[1]
		check(#walkway.curves == 2 * PIECES_PER_SIDE + 2 * EXIT_PIECES, "the stairs walkway has 24 pieces, found " .. #walkway.curves)
		for side = 0, 1 do
			local sign = side == 0 and 1 or -1
			local function piece(index) return walkway.curves[side * PIECES_PER_SIDE + index] end
			local landing = piece(7)[1]
			for corridor = 0, 1 do
				local corridorSign = corridor == 0 and 1 or -1
				local first, flight, last = piece(corridor * 3 + 1), piece(corridor * 3 + 2), piece(corridor * 3 + 3)
				local startX, startY = turned(sign * corridorSign * 14.66, sign * 11.75, upperAngle)
				check(near(first[1][1], startX) and near(first[1][2], startY) and near(first[1][3], -17.65), "the stairs start at the foot of the stairs from the ring, " .. label)
				check(hasNodeAt(sub, first[1]) >= 2, "the start of the stairs is a node of the passageway of the upper level")
				check(samePoint(first[2], flight[1]) and samePoint(flight[2], last[1]) and samePoint(last[2], landing), "the walkway from a corridor to the landing has no gap")
				local inwardX, inwardY = turned(-sign * corridorSign, 0, upperAngle)
				check((flight[2][1] - flight[1][1]) * inwardX + (flight[2][2] - flight[1][2]) * inwardY > 9 and flight[2][3] < flight[1][3] - 5, "the first flight leads towards the centre and down")
			end
			check(samePoint(piece(7)[2], piece(8)[1]) and samePoint(piece(8)[2], piece(9)[1]), "the walkway from the landing to the shared platform has no gap")
			check(piece(8)[2][3] < piece(8)[1][3] - 3, "the second flight leads down")
			check(samePoint(piece(9)[2], { 0, 0, SHARED_Z }), "both second flights end in the middle of the shared platform")

			local function exitPiece(index) return walkway.curves[2 * PIECES_PER_SIDE + side * EXIT_PIECES + index] end
			check(samePoint(exitPiece(1)[1], { 0, 0, SHARED_Z }) and samePoint(exitPiece(1)[2], exitPiece(2)[1]) and samePoint(exitPiece(2)[2], exitPiece(3)[1]), "an exit stairs leads from the middle of the shared platform without a gap")
			local last = exitPiece(3)[2]
			local expectedX, expectedY = turned(sign * 8.5, 0, upperAngle + exitDirection)
			check(near(last[1], expectedX) and near(last[2], expectedY) and near(last[3], -30), "the exit stairs meet the ring of the lower level in direction " .. exitDirection .. ", " .. label)
			check(hasNodeAt(sub, last) >= 3, "the end of the exit stairs is a node of the ring of the lower level, " .. label)
		end
		local passageX, passageY = turned(0, 8.5, lowerAngle)
		check(hasNodeAt(sub, { passageX, passageY, -30 }) >= 3, "the ring of the lower level meets its own passageway")
		local toExit = (lowerAngle - upperAngle + 90) % 180
		local pointsToExit = hasNodeAt(sub, { passageX, passageY, -30 }) >= 4
		check(pointsToExit == (toExit <= 30 or toExit >= 150), "the exit stairs point to the exits of the lower ring exactly when the exits lie beside the second flights, " .. label)

		-- The railing of the shared platform leaves the four stairs open.
		local rails, exitStairs = 0, 0
		for _, model in ipairs(sub.models) do
			if model.id == OWN .. "models/platform_rail.mdl" then
				rails = rails + 1
				local middle = (math.deg(math.atan(model.transf[2], model.transf[1])) - upperAngle + 2.5) % 180
				check(middle < 64 or middle > 116, "no railing piece stands where a second flight arrives, found one at " .. middle)
				check(math.abs((middle - exitDirection + 90) % 180 - 90) > 26, "no railing piece stands in front of an exit stairs, found one at " .. middle)
			elseif model.id == OWN .. "models/exit_stairs.mdl" then
				exitStairs = exitStairs + 1
				local direction = (math.deg(math.atan(model.transf[2], model.transf[1])) + 90 - upperAngle) % 180
				check(near(direction % 180, exitDirection % 180) or near(direction, 180), "the exit stairs model points in direction " .. exitDirection .. ", found " .. direction)
			end
		end
		check(rails >= 16 and exitStairs == 1, "the shared platform has a railing and one exit stairs model, found " .. rails .. " and " .. exitStairs)
	end

	local _, sub = build({ level2Vehicle = 2 })
	check(countModels(sub, "models/hall_doors.mdl") == 2 and countModels(sub, "underground_station_stairs.mdl") == 0, "every level uses the hall with open corridor walls")
	check(countModels(sub, "models/level_stairs.mdl") == 1 and countModels(sub, "models/hall_door_plugs.mdl") == 1, "the upper level has the stairs, and the lowest level has its corridor walls back")
	check(countModels(sub, "tickets_era_c") == 2 * (6 + 4), "every ticket machine of the hall stays, and each ring has four more, found " .. countModels(sub, "tickets_era_c"))

	-- Bins and ticket machines along the outer wall of each ring gallery, which is too narrow for
	-- benches, and four benches at the foot of the shared platform, looking away from it.
	local function furnitureAt(models, radius, z)
		local found = {}
		for _, model in ipairs(models) do
			local m = model.transf
			if near(math.sqrt(m[13] ^ 2 + m[14] ^ 2), radius) and near(m[15], z) then found[#found + 1] = model end
		end
		return found
	end
	-- Level 1 lies at 0 degrees and level 2 at 90 degrees.
	for _, ring in ipairs({ { -12, 0 }, { -30, 90 } }) do
		local ringZ, levelAngle = ring[1], ring[2]
		local onRing = furnitureAt(sub.models, 9.75, ringZ)
		check(#onRing == 4 + 4, "a ring gallery has four bins and four ticket machines, found " .. #onRing .. " at " .. ringZ)
		for _, model in ipairs(onRing) do
			local m = model.transf
			local direction = (math.deg(math.atan(m[14], m[13])) - levelAngle) % 180
			check(math.abs(direction - 90) > 30, "no furniture stands in an exit of the ring, found " .. model.id .. " at " .. direction)
			check(not model.id:find("bench", 1, true), "no bench stands on the narrow ring gallery")
			if model.id:find("tickets", 1, true) then
				check(m[5] * m[13] + m[6] * m[14] > 9, "a ticket machine on the ring looks to the middle")
			end
		end
	end
	local atPlatform = furnitureAt(sub.models, 3.45, -30)
	check(#atPlatform == 4, "four benches stand at the foot of the shared platform, found " .. #atPlatform)
	for _, model in ipairs(atPlatform) do
		local m = model.transf
		check(m[1] * m[13] + m[2] * m[14] > 3 and math.abs(m[13]) < 1.3, "a bench at the shared platform stands below a second flight and looks away from the platform")
	end
	local _, freight = build({ cargoMode = 2, level2Vehicle = 2 })
	check(#furnitureAt(freight.models, 9.75, -12) == 4 and #furnitureAt(freight.models, 3.45, -30) == 0, "a cargo hub keeps only the bins")
	local BENCH_LENGTH = 2.0
	local first, second = atPlatform[1].transf, atPlatform[2].transf
	check(math.sqrt((first[13] - second[13]) ^ 2 + (first[14] - second[14]) ^ 2) > BENCH_LENGTH, "two benches at the shared platform stand apart")
	local _, single = build({})
	check(countModels(single, "models/hall_door_plugs.mdl") == 1 and countModels(single, "models/level_stairs.mdl") == 0 and #stairWalkwaysOf(single) == 0, "one level has no stairs")

	-- Every point of the walkway below the corridor lies inside the stairs model.
	local model = support.readFile("content/stations/rail/underground_hub/models/level_stairs.mdl")
	local function triple(key)
		local x, y, z = model:match(key .. " = { ([%-%d%.]+), ([%-%d%.]+), ([%-%d%.]+) }")
		return { tonumber(x), tonumber(y), tonumber(z) }
	end
	local bbMin, bbMax = triple("bbMin"), triple("bbMax")
	local walkway = stairWalkwaysOf(sub)[1]
	for index, curve in ipairs(walkway.curves) do
		local point = curve[2]
		local inside = true
		for c = 1, 3 do
			if point[c] < bbMin[c] - 0.01 or point[c] > bbMax[c] + 0.01 then inside = false end
		end
		check(inside, "walkway piece " .. index .. " ends inside the stairs model")
	end

	-- The game stops with a fatal error on a mesh part without faces, so every part of a generated
	-- mesh has faces and its own material.
	for _, name in ipairs({ "level_stairs", "exit_stairs", "platform_rail", "hall_door_plugs" }) do
		local mesh = support.readFile("content/stations/rail/underground_hub/models/msh/" .. name .. ".msh")
		local description = support.readFile("content/stations/rail/underground_hub/models/" .. name .. ".mdl")
		local parts = select(2, mesh:gsub("indices = {", ""))
		local materials = select(2, description:match("materials = {([^}]*)}"):gsub("%.mtl", ""))
		check(parts > 0 and parts == materials, "model " .. name .. " has one material for each mesh part, found " .. parts .. " parts and " .. materials .. " materials")
		check(not mesh:find("count = 0[ ,}]"), "model " .. name .. " has no empty mesh part")
	end

	-- The light panels of the hall and of the stairs use the light material of this mod, which is always on.
	local hall = support.readFile("content/stations/rail/underground_hub/models/hall_doors.mdl")
	local light = support.readFile("content/stations/rail/underground_hub/models/mat/hub_light.mtl")
	check(hall:find('"mat/hub_light.mtl"', 1, true) and not hall:find("underground_station_light.mtl", 1, true) and model:find('"mat/hub_light.mtl"', 1, true), "the hall and the stairs use the light material of this mod")
	check(light:find("fromTime = 0, toTime = 24", 1, true), "the light material is on all day")
	local surface = support.readFile("content/stations/rail/underground_hub/models/surface.mdl")
	check(surface:find('"mat/hub_light.mtl"', 1, true) and not surface:find("underground_station_light.mtl", 1, true), "the entrance building uses the light material of this mod")
	for _, mode in ipairs({ 1, 2, 3 }) do
		local _, entrance = build({ cargoMode = mode })
		check(countModels(entrance, "models/surface.mdl") == 1 and countModels(entrance, "underground_station_surface.mdl") == 0, "the entrance building is the copy with lights, in operation " .. mode)
	end

	-- The catenary of a rail level stays below the ceiling of the hall, which is 5.8 m above the track.
	local HALL_CEILING_ABOVE_TRACK = -12.5 - (-18.3)
	for _, style in ipairs({ "station_track", "station_track_simple", "station_track_high_speed" }) do
		local text = support.readFile("content/stations/rail/underground_hub/" .. style .. ".street.lua")
		local base, height = tonumber(text:match('%["catenaryBase"%] = ([%d%.]+)')), tonumber(text:match('%["catenaryHeight"%] = ([%d%.]+)'))
		check(base + height < HALL_CEILING_ABOVE_TRACK, "the catenary of " .. style .. " stays below the ceiling of the hall")
	end
end

-- A level keeps its depth by its number, so level 3 can exist without level 2.
do
	local result, sub = build({ level3Vehicle = 2 })
	check(#sub.station.terminals == 4, "levels 1 and 3 give four terminals")
	local lane = laneAt(sub, sub.station.terminals[3].personEdges[1][1])
	check(near(lane.curves[1][1][3], -17.65 - 36), "level 3 lies two levels below level 1 even without level 2")
	check(near(result.edgeLists[7].curves[1][1][3], -18.3 - 36), "the rail track of level 3 lies at its own depth")
	local shafts = shaftsOf(sub)
	check(#shafts == 2 and #stairWalkwaysOf(sub) == 0, "a level below a gap keeps its two shafts and has no stairs")
	local top, bottom = shafts[1].curves[1][1], shafts[1].curves[1][2]
	check(near(top[3], -12) and near(bottom[3], -48), "the shaft runs from the entrance ring down to the ring of level 3")
	check(near(math.sqrt(top[1] ^ 2 + top[2] ^ 2), 8.5), "the shaft stands on the ring of radius 8.5")
	check(hasNodeAt(sub, bottom) >= 3, "the shaft ends on a node of the ring and the passageway of level 3")
	check(countModels(sub, "models/level_stairs.mdl") == 0 and countModels(sub, "models/hall_door_plugs.mdl") == 2, "no stairs model across a gap")
end

-- The price is the price of the source mod: 150000 maintenance per level, 6 times that to build, 1.25 times for cargo.
do
	local one = build({})
	local three = build({ level2Vehicle = 2, level3Vehicle = 3 })
	local cargo = build({ cargoMode = 2 })
	local mixed = build({ cargoMode = 3, level2Vehicle = 2 })
	check(one.maintenanceCost == 150000 and one.cost == 900000, "one level costs 900000 to build with 150000 maintenance")
	check(three.maintenanceCost == 450000 and three.cost == 2700000, "three levels cost three times as much")
	check(cargo.maintenanceCost == 187500 and cargo.cost == 1125000, "a cargo hub costs 1.25 times as much")
	check(mixed.maintenanceCost == 375000, "a mixed hub with two levels costs 2 x 1.25 x 150000")
	check(build({ level1Length = 4 }).cost == one.cost, "the length of a level does not change the price")
end

-- Only the street side of the plot links to the pavement: the one linkable lane holds three short
-- pieces at the front, one for each connection to the pavement.
do
	local _, sub = build({ level2Vehicle = 2 })
	local streetSideY, linkable = 21.5, 0
	for index, lane in ipairs(sub.laneLists) do
		if lane.link then
			linkable = linkable + 1
			for _, curve in ipairs(lane.curves) do
				for _, point in ipairs(curve) do
					check(point[2] >= streetSideY and point[3] == 0, "a linkable lane node lies at the street side of the plot, found y " .. point[2])
				end
			end
		end
	end
	check(linkable == 1, "one lane links the station to the pavement, found " .. linkable)
	local link, entrance = sub.laneLists[1].curves, sub.laneLists[2].curves
	check(#link == 3 and link[1][1][1] < -4 and link[2][1][1] == 0 and link[3][1][1] > 4, "three pieces link the plot to the pavement: left, middle and right")
	for _, piece in ipairs(link) do
		local last = piece[2]
		local joined = false
		for _, curve in ipairs(entrance) do
			if curve[1][1] == last[1] and curve[1][2] == last[2] and curve[2][1] == 0 and curve[2][2] == 20 then joined = true end
		end
		check(joined, "the walkway from a front piece to the stairs is part of the lane that does not link, piece at x " .. last[1])
	end
end

-- Every platform is reachable on foot from each of the three connections to the pavement. The game
-- joins lane pieces that end at the same point.
do
	local function key(point)
		local CENTIMETRES = 100
		local function rounded(value) return math.floor(value * CENTIMETRES + 0.5) end
		return rounded(point[1]) .. " " .. rounded(point[2]) .. " " .. rounded(point[3])
	end
	local function reachableFrom(sub, start)
		local neighbours = {}
		for _, lane in ipairs(sub.laneLists) do
			for _, curve in ipairs(lane.curves) do
				local a, b = key(curve[1]), key(curve[#curve])
				neighbours[a] = neighbours[a] or {}
				neighbours[b] = neighbours[b] or {}
				table.insert(neighbours[a], b)
				table.insert(neighbours[b], a)
			end
		end
		local seen, queue = { [key(start)] = true }, { key(start) }
		while #queue > 0 do
			local node = table.remove(queue)
			for _, other in ipairs(neighbours[node] or {}) do
				if not seen[other] then
					seen[other] = true
					queue[#queue + 1] = other
				end
			end
		end
		return seen
	end
	local cases = {
		{ level2Vehicle = 2, level3Vehicle = 2, level4Vehicle = 2 },
		{ level1Vehicle = 3, level2Vehicle = 2, level3Vehicle = 3, level4Vehicle = 2, level2Angle = 8, level3Angle = 30 },
		{ level3Vehicle = 2 },
		{ cargoMode = 2, level2Vehicle = 2, level4Vehicle = 3 },
	}
	for number, params in ipairs(cases) do
		local _, sub = build(params)
		for _, piece in ipairs(sub.laneLists[1].curves) do
			local seen = reachableFrom(sub, piece[1])
			for index, terminal in ipairs(sub.station.terminals) do
				local platform = laneAt(sub, terminal.personEdges[1][1]).curves[1][1]
				check(seen[key(platform)], "people reach terminal " .. index .. " from the pavement connection at x " .. piece[1][1] .. ", case " .. number)
			end
		end
	end
end

-- Level angle and length reach the geometry.
do
	local _, sub = build({ level2Vehicle = 2, level1Length = 4, level2Length = 3, level2Angle = 37 })
	local t1, t2 = sub.station.terminals[1], sub.station.terminals[3]
	check(near(t1.cargoTransferSpeeds[1].length, 40), "level 1 length 40 m")
	check(near(t2.cargoTransferSpeeds[1].length, 320), "level 2 length 320 m")
	local lane = laneAt(sub, t2.personEdges[1][1])
	local first, last = lane.curves[1][1], lane.curves[#lane.curves][2]
	local angle = math.deg(math.atan(first[2] - last[2], first[1] - last[1]))
	check(near((angle + 360) % 360, (36 * 5) % 360) or near((angle + 360) % 360, (36 * 5 + 180) % 360), "level 2 platform lane follows the level angle")
end

-- Rail and tram levels in one hub.
do
	local result, sub = build({ level2Vehicle = 3, level3Vehicle = 3, level4Vehicle = 2 })
	local terminals = sub.station.terminals
	check(#terminals == 8, "mixed hub has eight terminals")
	check(#result.edgeLists == 24, "mixed hub adds 24 edge calls, got " .. #result.edgeLists)
	check(result.edgeLists[7].kind == "TRACK" and result.edgeLists[7].spec.edgeTypeName == OWN .. "station_hall.tunnel" and result.edgeLists[7].spec.type == OWN .. "track_silhouette.street_template", "a tram level starts with inert silhouette edges across its hall")
	local first, second = result.edgeLists[7].curves[1][1], result.edgeLists[8].curves[1][1]
	check(result.edgeLists[8].spec.type == OWN .. "track_silhouette.street_template" and near(math.sqrt((first[1] - second[1]) ^ 2 + (first[2] - second[2]) ^ 2), 5), "the silhouette is two parallel tracks 5 m apart")
	check(result.edgeLists[9].kind == "STREET" and result.edgeLists[9].spec.tramTrackType == "ELECTRIC", "tram level uses an electric street edge by default")

	-- The tunnel of a tram level beyond its hall, at each end: an outer piece that closes a dead
	-- end, with the free node at its outer end, then a piece of the game tunnel up to the hall.
	local HALL_END, JOINT, OUTER_END = 20.5, 25.5, 30.5
	local function alongLevel(point) return math.sqrt(point[1] ^ 2 + point[2] ^ 2) end
	for stub = 0, 1 do
		local outer, inner = result.edgeLists[9 + stub * 2], result.edgeLists[10 + stub * 2]
		check(outer.kind == "STREET" and outer.spec.edgeTypeName == OWN .. "tram_end.tunnel", "the outer tunnel piece of a tram level closes a dead end")
		check(inner.kind == "STREET" and inner.spec.edgeTypeName == "::/infrastructure/tunnel/tunnel_b_car.tunnel", "the inner tunnel piece of a tram level is the tunnel of the game")
		check(near(alongLevel(outer.curves[1][1]), OUTER_END) and near(alongLevel(outer.curves[1][2]), JOINT), "the outer piece runs from the free end to the joint")
		check(near(alongLevel(inner.curves[1][1]), JOINT) and near(alongLevel(inner.curves[1][2]), HALL_END), "the inner piece runs from the joint to the hall")
		check(#outer.a == 1 and outer.a[1] == 0 and #outer.b == 1 and outer.b[1] == 0, "only the outer end of the outer piece is free")
		check(#inner.a == 0 and #inner.b == 0, "the inner piece has no free node")
	end
	for _, index in ipairs({ 3, 4, 5, 6 }) do
		local terminal = terminals[index]
		check(terminal.transportModes[1] == "TRAM", "terminal " .. index .. " serves trams")
		check(terminal.vehicleNode[2] == 1 and laneAt(sub, terminal.vehicleNode[1]).types[1] == "TRAM", "terminal " .. index .. " points at a tram lane")
	end
	check(terminals[7].transportModes[1] == "TRAIN" and terminals[7].vehicleNode[2] == 49, "rail level after two tram levels starts at node 49")
	check(terminals[8].vehicleNode[2] == 57, "second track of that level is node 57")
	local _, _, data = build({})
	local plain = data.updateFn(CAPTURE, { level2Vehicle = 3, catenary = 1 })
	check(plain.edgeLists[9].spec.tramTrackType == "YES", "catenary off gives plain tram track")
end

-- The rail tunnel that joins a level is the newest one of the year.
do
	local function tunnelOf(year)
		local result = support.loadScript(SCRIPT).updateFn(CAPTURE, { year = year })
		return result.edgeLists[2].spec.edgeTypeName
	end
	check(tunnelOf(1950):find("tunnel_a", 1, true), "before 1970 the rock tunnel joins a rail level")
	check(tunnelOf(1970):find("tunnel_b", 1, true) and tunnelOf(2020):find("tunnel_b", 1, true), "from 1970 the concrete tunnel joins a rail level")
	check(tunnelOf(nil):find("tunnel_b", 1, true), "without a year the concrete tunnel joins a rail level")
end

-- Cargo mode.
do
	local _, passenger = build({ cargoMode = 1 })
	local _, cargo = build({ cargoMode = 2 })
	local _, mixed = build({ cargoMode = 3, level2Vehicle = 3 })
	check(passenger.station.terminals[1].passengers and not passenger.station.terminals[1].cargo, "passenger mode carries passengers only")
	check(not hasModel(passenger, DEPOT), "passenger mode builds no cargo depot")
	check(cargo.station.terminals[1].cargo and not cargo.station.terminals[1].passengers, "cargo mode carries cargo only")
	check(cargo.station.terminals[1].cargoTransferSpeeds[1].cargoTypeSet.cargoClassesIncluded[1] == "UNIVERSAL", "cargo mode loads all cargo")
	check(hasModel(cargo, DEPOT), "cargo mode builds the depot")
	check(not hasModel(cargo, "bench_c_metal"), "cargo mode places no benches")
	check(hasModel(passenger, "bench_c_metal"), "passenger mode places benches")
	for _, terminal in ipairs(mixed.station.terminals) do
		check(terminal.cargo and terminal.passengers, "mixed mode carries both on every level")
	end
	check(#mixed.station.terminals[1].cargoTransferSpeeds[1].cargoTypeSet.cargoClassesIncluded == 2, "mixed mode loads passengers and cargo")
	local hasCargoLane = false
	for _, lane in ipairs(cargo.laneLists) do
		for _, laneType in ipairs(lane.types) do if laneType == "CARGO" then hasCargoLane = true end end
	end
	check(hasCargoLane, "cargo mode opens the lanes to cargo")
	check(cargo.groundFaces ~= nil and cargo.terrainAlignmentLists ~= nil, "cargo mode paves and levels the depot apron")
end

-- One design for every level: the hall models of the game station, the strips of the platforms,
-- and no model of the original rail station.
do
	local result, sub = build({ level2Vehicle = 3, level2TramLength = 2 })
	local own = 0
	for _, model in ipairs(sub.models) do
		local id = model.id
		local name = id:sub(1, #OWN) == OWN and id:sub(#OWN + 1) or nil
		local known = name and (name:find("^models/cargo/") or name:find("^models/shared/") or name:find("^models/[%w_]+%.mdl$"))
		if id:sub(1, 2) ~= "::" and not known then own = own + 1 end
	end
	check(own == 0, "every model is a game model, a cargo model, a strip or a stairs model, found " .. own .. " others")
	-- A name without a mod or "::/" in front is looked up relative to a file. The update function
	-- is handed out by a script file in another folder, so no such name may reach the game.
	for _, edges in ipairs(result.edgeLists) do
		check(edges.spec.type:find("::/", 1, true) ~= nil and edges.spec.edgeTypeName:find("::/", 1, true) ~= nil, "an edge names its track or street and its tunnel with the mod or the game in front, found " .. edges.spec.type .. " and " .. edges.spec.edgeTypeName)
	end
	for _, model in ipairs(sub.models) do
		check(model.id:find("::/", 1, true) ~= nil, "a model is named with the mod or the game in front, found " .. model.id)
	end
	check(hasModel(sub, "underground_station_end.mdl") and hasModel(sub, "underground_station_extension.mdl") and hasModel(sub, "models/hall_doors.mdl"), "the hall of the game station is used, as the copy with open corridor walls")
	local rail, tram = 0, 0
	for _, model in ipairs(sub.models) do
		if model.id == OWN .. "models/shared/platform_led_strip.mdl" then rail = rail + 1 end
	end
	check(rail == 2 * 2 * 240, "passenger mode lays 240 strips per platform side of two 240 m levels, found " .. rail)
	local _, hazard = build({ cargoMode = 2 })
	local _, mixed = build({ cargoMode = 3 })
	check(hasModel(hazard, "platform_hazard_strip.mdl") and not hasModel(hazard, "platform_led_strip.mdl"), "cargo mode lays hazard strips only")
	check(hasModel(mixed, "platform_hazard_strip.mdl") and hasModel(mixed, "platform_led_strip.mdl"), "mixed mode lays one strip of each kind")
	check(result.slots and result.slots[1].type == "underground_dummy" and result.slotConfig.underground_dummy.maxModules == 0, "the dummy slot shows the configuration wrench")
end

-- A fake world: stations with nodes at their level depths, own edges, and tracks or streets
-- that other players built on a free node.
local function fakeApi(stations)
	local nodes, trackEdges, streetEdges = {}, {}, {}
	local function component(entity)
		return stations[entity]
	end
	local built = { CONSTRUCTION = "construction", BASE_NODE = "node", BASE_EDGE = "edge" }
	local ids = {}
	local edges = {}
	for id, station in ipairs(stations) do
		ids[#ids + 1] = id
		station.frozenNodes, station.frozenEdges = {}, {}
		for index, node in ipairs(station.nodes) do
			local nodeId = id * 100 + index
			local ownEdge = 5000 + nodeId
			station.frozenEdges[index] = ownEdge
			edges[ownEdge] = { node0 = nodeId, node1 = nodeId }
			nodes[nodeId] = { position = { x = 0, y = 0, z = node.z } }
			trackEdges[nodeId], streetEdges[nodeId] = {}, {}
			if node.own then table.insert(trackEdges[nodeId], ownEdge) end
			if node.track then table.insert(trackEdges[nodeId], 7000 + nodeId) end
			if node.street then table.insert(streetEdges[nodeId], 8000 + nodeId) end
		end
	end
	return {
		type = { ComponentType = built },
		engine = {
			getEntitiesWithComponent = function() return ids end,
			getComponent = function(entity, kind)
				if kind == built.CONSTRUCTION then return component(entity) end
				if kind == built.BASE_EDGE then return edges[entity] end
				return nodes[entity]
			end,
			system = { streetSystem = {
				getNodeTrackSegments = function(node) return trackEdges[node] or {} end,
				getNodeStreetSegments = function(node) return streetEdges[node] or {} end,
			} },
		},
	}
end

local STATION_FILE = "kacsa_underground_hub::/stations/rail/underground_hub/station.con"
local ROAD_STATION_FILE = "kacsa_underground_hub::/stations/rail/underground_hub/station_tram.con"
local STORED = { level2Vehicle = 3, level3Vehicle = 2, cargoMode = 1, catenary = 2, trackType = 2 }

-- The station has a rail level, a tram level and a rail level, at their depths.
local function fakeStation(connected, params)
	local station = { fileName = STATION_FILE, params = params or STORED, nodes = {
		{ z = -18.54, own = true, track = connected[1] },
		{ z = -36.0, own = true, street = connected[2] },
		{ z = -54.54, own = true, track = connected[3] },
	} }
	return station
end

local function lockCheck(stations, values)
	local data = support.loadScript(SCRIPT, { api = fakeApi(stations), print = function() end })
	return function(name, ...) return data[name]({}, values) end
end

-- Greying out of the controls and the lock of connected levels. The game calls a check function with
-- the captured parameters of the script reference and the flat table of the current values.
do
	local data = support.loadScript(SCRIPT, { api = fakeApi({}), print = function() end })
	local function check2(fn, values) return data[fn]({}, values) end
	check(check2("checkLevel2EnabledFn", { level1Vehicle = 1 }) == "Hidden", "level 2 controls disabled for one level")
	check(check2("checkLevel2EnabledFn", { level2Vehicle = 2 }) == "Enabled", "level 2 controls enabled for two levels")
	check(check2("checkLevel4EnabledFn", { level2Vehicle = 2, level3Vehicle = 2 }) == "Hidden", "level 4 controls disabled for three levels")
	check(check2("checkLevel1EnabledFn", { level1Vehicle = 1 }) == "Enabled", "level 1 controls enabled")
	check(check2("checkTrackTypeEnabledFn", { level1Vehicle = 2, level2Vehicle = 3 }) == "Hidden", "track type disabled when all levels are tram")
	check(check2("checkTrackTypeEnabledFn", { level1Vehicle = 1 }) == "Enabled", "track type enabled for a rail level")
	check(check2("checkTrackTypeEnabledFn", { level1Vehicle = 2, level2Vehicle = 3, level3Vehicle = 1 }) == "Hidden", "a level that is off does not count as a rail level")
	check(data.checkTrackTypeEnabledFn() == "Enabled" and data.checkCatenaryEnabledFn() == "Enabled", "controls stay enabled when the arguments are unknown")
	check(check2("checkLevel1LockFn", { level1Vehicle = 1 }) == "Hidden", "no lock note without connections")

	-- The two track type selectors: the one for the current year shows.
	local function withYear(year)
		return support.loadScript(SCRIPT, { api = { engine = { util = { getYear = function() return year end } }, type = {}, }, print = function() end })
	end
	for year, expected in pairs({ [1950] = { legacy = "Enabled", modern = "Hidden" }, [1979] = { legacy = "Enabled", modern = "Hidden" }, [1980] = { legacy = "Hidden", modern = "Enabled" }, [2020] = { legacy = "Hidden", modern = "Enabled" } }) do
		local dated = withYear(year)
		check(dated.checkTrackTypeLegacyFn({}, { level1Vehicle = 1 }) == expected.legacy, "the track selector up to 1980 in " .. year .. " is " .. expected.legacy)
		check(dated.checkTrackTypeModernFn({}, { level1Vehicle = 1 }) == expected.modern, "the track selector from 1980 in " .. year .. " is " .. expected.modern)
	end
	check(support.loadScript(SCRIPT, { api = {}, print = function() end }).checkTrackTypeModernFn({}, { level1Vehicle = 1 }) == "Enabled", "without a year the modern selector shows")

	-- Each level has a length selector for rail and one for tram, with their own defaults.
	do
		local function lengthOf(sub, level) return sub.station.terminals[level * 2 - 1].cargoTransferSpeeds[1].length end
		check(check2("checkLevel1LengthFn", { level1Vehicle = 1 }) == "Enabled" and check2("checkLevel1TramLengthFn", { level1Vehicle = 1 }) == "Hidden", "a rail level shows only the rail length")
		check(check2("checkLevel1LengthFn", { level1Vehicle = 2 }) == "Hidden" and check2("checkLevel1TramLengthFn", { level1Vehicle = 2 }) == "Enabled", "a tram level shows only the tram length")
		check(check2("checkLevel2TramLengthFn", { level2Vehicle = 1 }) == "Hidden" and check2("checkLevel2LengthFn", { level2Vehicle = 1 }) == "Hidden", "a level that is off shows no length in a built station")
		local _, railDefault = build({ level2Vehicle = 2 })
		local _, tramDefault = build({ level2Vehicle = 3 })
		check(lengthOf(railDefault, 1) == 240 and lengthOf(railDefault, 2) == 240 and lengthOf(tramDefault, 2) == 40, "a new rail level is 240 m long and a new tram level 40 m")
		local _, chosen = build({ level2Vehicle = 3, level2TramLength = 6, level2Length = 3 })
		check(lengthOf(chosen, 2) == 120, "a tram level uses its own length selector, not the rail one")
	end

	-- The switch of a level and the controls of a level that is off.
	check(check2("checkLevel2SwitchFn", { level1Vehicle = 1 }) == "Enabled", "the switch of level 2 shows for a station without connections")
	check(check2("checkLevel3EnabledFn", { level2Vehicle = 2 }) == "Hidden", "the controls of a level that is off are hidden")
	check(check2("checkLevel3EnabledFn", { level3Vehicle = 2 }) == "Enabled", "the controls of level 3 show when its vehicle is not off, without level 2")

	-- Tracks on the tram level: that level is locked, and so are the controls that would change its edges.
	local ask = lockCheck({ fakeStation({ false, true, false }) }, STORED)
	check(ask("checkLevel2EnabledFn") == "Hidden" and ask("checkLevel1EnabledFn") == "Enabled" and ask("checkLevel3EnabledFn") == "Enabled", "only the connected level is locked")
	check(ask("checkLevel2LockFn") == "Disabled" and ask("checkLevel1LockFn") == "Hidden" and ask("checkLevel3LockFn") == "Hidden", "only the connected level shows the note")
	check(ask("checkLevel2SwitchFn") == "Hidden" and ask("checkLevel3SwitchFn") == "Enabled" and ask("checkLevel4SwitchFn") == "Enabled", "a connected level loses its switch, so it cannot be removed")
	check(ask("checkCatenaryEnabledFn") == "Hidden", "the catenary is locked while a level is connected")
	check(ask("checkTrackTypeEnabledFn") == "Enabled", "the track type stays free while no rail level is connected")

	-- Tracks on the first rail level only.
	ask = lockCheck({ fakeStation({ true, false, false }) }, STORED)
	check(ask("checkTrackTypeEnabledFn") == "Hidden", "the track type is locked while a rail level is connected")
	check(ask("checkLevel1LockFn") == "Disabled", "level 1 shows the note")

	-- Nothing connected: nothing locked.
	ask = lockCheck({ fakeStation({ false, false, false }) }, STORED)
	check(ask("checkLevel2EnabledFn") == "Enabled" and ask("checkCatenaryEnabledFn") == "Enabled", "a station without connections is free")

	-- The panel of a placed station greys controls out, the panel of a built station hides them.
	local placed = support.loadScript(SCRIPT, { api = fakeApi({}), print = function() end })
	check(placed.checkLevel3EnabledFn({}, { level2Vehicle = 2, hubPlacement = 1 }) == "Disabled", "a placed station greys out the controls of a level that is off")
	check(placed.checkLevel3EnabledFn({}, { level2Vehicle = 2 }) == "Hidden", "a built station hides the controls of a level that is off")
	check(placed.checkTrackTypeEnabledFn({}, { level1Vehicle = 2, hubPlacement = 1 }) == "Disabled", "a placed station greys out the track type without a rail level")

	-- After a change in the panel the values match no station, and the lock stays.
	local graced = support.loadScript(SCRIPT, { api = fakeApi({ fakeStation({ false, true, false }) }), print = function() end })
	check(graced.checkLevel2EnabledFn({}, STORED) == "Hidden", "level 2 is locked")
	local changed = {}
	for key, value in pairs(STORED) do changed[key] = value end
	changed.cargoMode = 3
	check(graced.checkLevel2EnabledFn({}, changed) == "Hidden", "the lock stays while the values match no station")
	changed.level1Vehicle = 2
	check(graced.checkLevel2EnabledFn({}, changed) == "Hidden" and graced.checkLevel2LockFn({}, changed) == "Disabled", "the lock stays for every later change")
	check(graced.checkLevel2EnabledFn({}, { cargoMode = 2, level2Vehicle = 1 }) == "Hidden", "the lock stays even when the changed values turn the level off")

	-- Placing a station: the marker parameter is present, so nothing is locked, even for the same values.
	local placing = {}
	for key, value in pairs(STORED) do placing[key] = value end
	placing.hubPlacement = 1
	ask = lockCheck({ fakeStation({ true, true, true }) }, placing)
	check(ask("checkLevel2EnabledFn") == "Enabled" and ask("checkCatenaryEnabledFn") == "Enabled", "a station that is being placed is never locked")

	-- Another station with other values is not the station being edited.
	local other = {}
	for key, value in pairs(STORED) do other[key] = value end
	other.level3Vehicle = 1
	ask = lockCheck({ fakeStation({ true, true, true }, other) }, STORED)
	check(ask("checkLevel2EnabledFn") == "Enabled", "a station with other values is not matched")

	-- Two stations with the same values count together.
	ask = lockCheck({ fakeStation({ false, false, false }), fakeStation({ false, true, false }) }, STORED)
	check(ask("checkLevel2EnabledFn") == "Hidden", "stations that cannot be told apart lock together")

	-- A station that was placed from the road menu has the other construction file.
	local fromRoadMenu = fakeStation({ false, true, false })
	fromRoadMenu.fileName = ROAD_STATION_FILE
	ask = lockCheck({ fromRoadMenu }, STORED)
	check(ask("checkLevel2EnabledFn") == "Hidden", "a station from the road menu is found and locked too")

	-- The game stores a seed with every station, and the panel hands it to the check functions. Two
	-- stations with the same values are told apart by it.
	local function withSeed(seed)
		local params = {}
		for key, value in pairs(STORED) do params[key] = value end
		params.seed = seed
		return params
	end
	local FREE_SEED, CONNECTED_SEED = 1111, 2222
	local twins = { fakeStation({ false, false, false }, withSeed(FREE_SEED)), fakeStation({ true, true, false }, withSeed(CONNECTED_SEED)) }
	ask = lockCheck(twins, withSeed(FREE_SEED))
	check(ask("checkLevel1EnabledFn") == "Enabled" and ask("checkLevel2EnabledFn") == "Enabled", "a station without tracks is free, also when its twin with the same values has tracks")
	ask = lockCheck(twins, withSeed(CONNECTED_SEED))
	check(ask("checkLevel1EnabledFn") == "Hidden" and ask("checkLevel2EnabledFn") == "Hidden", "the twin with tracks is locked")
	-- A station that the game stored no seed for is found by its values, as before.
	ask = lockCheck({ fakeStation({ false, true, false }) }, withSeed(FREE_SEED))
	check(ask("checkLevel2EnabledFn") == "Hidden", "a station without a stored seed is found by its values")

	-- A failing lookup leaves the controls free.
	local broken = support.loadScript(SCRIPT, { api = { type = {}, engine = {} }, print = function() end })
	check(broken.checkLevel1EnabledFn({}, STORED) == "Enabled", "a failing lookup does not lock")
end

-- The parameter list of the construction file.
do
	local keys = {}
	local env = setmetatable({
		_ = function(key) keys[#keys + 1] = key; return key end,
	}, { __index = _G })
	local con = loadCon(CON, env)
	local script = support.loadScript(SCRIPT)

	-- The two menu entries differ only in their menu and in the vehicle that level 1 starts with.
	local RAIL, TRAM = 1, 2
	local road = loadCon(ROAD_CON, setmetatable({ _ = function(key) return key end }, { __index = _G }))
	local function firstLevelDefault(construction)
		for _, param in ipairs(construction.params) do
			if param.key == "level1Vehicle" then return param.defaultIndex end
		end
	end
	local function menuOf(construction)
		local categories = construction.constructionTemplates[1].menuCategory.categories
		return #construction.constructionTemplates == 1 and #categories == 1 and categories[1].category
	end
	check(menuOf(con) == "rail_buildings" and firstLevelDefault(con) == RAIL, "the entry of the rail menu starts with a rail level")
	check(menuOf(road) == "road_buildings" and firstLevelDefault(road) == TRAM, "the entry of the road menu starts with a tram level")
	check(#road.params == #con.params, "both entries have the same parameters")
	for index, param in ipairs(con.params) do
		local other = road.params[index]
		check(other.key == param.key and (param.key == "level1Vehicle" or other.defaultIndex == param.defaultIndex), "parameter " .. param.key .. " is the same in both entries")
	end

	-- The toolbar shows the passenger capacity that the game counts on the platforms of the default
	-- station: cells of 1.2 m along and across the walkway of each terminal.
	local CELL, WALKWAY_WIDTH = 1.2, 2
	local function round(value) return math.floor(value + 0.5) end
	local function toolbarCapacity(params)
		local _, sub = build(params)
		local capacity = 0
		for _, terminal in ipairs(sub.station.terminals) do
			for _, edge in ipairs(terminal.personEdges) do
				local curve = laneAt(sub, edge[1]).curves[edge[2] + 1]
				local from, to = curve[1], curve[#curve]
				local length = math.sqrt((from[1] - to[1]) ^ 2 + (from[2] - to[2]) ^ 2 + (from[3] - to[3]) ^ 2)
				capacity = capacity + math.max(round(length / CELL), 1) * math.max(round(WALKWAY_WIDTH / CELL), 1)
			end
		end
		return capacity
	end
	check(toolbarCapacity({ level1Vehicle = firstLevelDefault(road) }) == 128, "the entry of the road menu shows a passenger capacity of 128, found " .. toolbarCapacity({ level1Vehicle = firstLevelDefault(road) }))
	check(toolbarCapacity({ level1Vehicle = firstLevelDefault(con) }) == 800, "the entry of the rail menu shows a passenger capacity of 800, found " .. toolbarCapacity({ level1Vehicle = firstLevelDefault(con) }))
	local seen, groupOf = {}, {}
	for _, param in ipairs(con.params) do
		seen[param.key] = (seen[param.key] or 0) + 1
		groupOf[param.key] = param.group
		if param.checkEnabledScript then
			local name = param.checkEnabledScript.fileName:match("@(.+)$")
			check(type(script[name]) == "function", "param " .. param.key .. " names a check function that exists: " .. name)
		end
	end
	for _, key in ipairs({ "cargoMode", "catenary", "trackType", "level1Title", "level1Vehicle", "level2Title", "level4Title", "level2Angle", "level3Length", "level3TramLength", "level4Vehicle", "level1Lock", "level4Lock", "hubPlacement", "seed" }) do
		check(seen[key], "parameter " .. key .. " exists")
	end
	check(not seen.layout and not seen.platformOrientation and not seen.ballast and not seen.interiorStyle and not seen.tramCatenary and not seen.tunnelType, "removed parameters stay removed")
	check(seen.trackType == 2, "two year-gated track type selectors")
	local NEVER_IN_MENU = 9999
	for _, param in ipairs(con.params) do
		if param.key == "seed" then
			check(param.yearFrom == NEVER_IN_MENU and param.postConstructionModifiable == true, "the seed parameter is in the panel of a built station and never in the menu of a placed one")
			check(param.checkEnabledScript.fileName:match("@(.+)$") == "checkHiddenFn", "the seed parameter is hidden")
		end
	end
	check(seen.levelCount == nil and seen.level2Active == nil, "there is neither a level count nor a separate level switch")
	for _, param in ipairs(con.params) do
		if param.key:match("^level%dAngle$") then
			check(#param.values == 37 and tonumber(param.values[1]) == 0 and tonumber(param.values[#param.values]) == 180, "the angle of a level runs from 0 to 180 degrees in steps of 5, found " .. #param.values .. " values up to " .. tostring(param.values[#param.values]))
			check(param.defaultIndex <= #param.values, "the default angle of " .. param.key .. " lies inside the range")
		end
	end
	for _, param in ipairs(con.params) do
		local level = param.key:match("^level(%d)Vehicle$")
		if level then
			check(#param.values == (tonumber(level) == 1 and 2 or 3), "the vehicle selector of level " .. level .. " has " .. (tonumber(level) == 1 and "rail and tram" or "off, rail and tram"))
		end
	end
	for _, param in ipairs(con.params) do
		check((param.postConstructionModifiable == true) == (param.key ~= "hubPlacement"), "parameter " .. param.key .. " can change after construction, except the placement marker")
	end

	-- A group shows as one block with a divider, so its parameters MUST be next to each other.
	local closed, previous = {}, nil
	for _, param in ipairs(con.params) do
		if param.group ~= previous then
			check(param.group == nil or param.group == "hubLock" or not closed[param.group], "group " .. tostring(param.group) .. " is not split")
			if previous then closed[previous] = true end
			previous = param.group
		end
	end
	-- The stylesheet: every divider is a thin yellow line, the list has room around its dividers, the
	-- sliders leave a free strip on the right of the settings window with their value next to them,
	-- and the window is taller.
	local rules = {}
	local cssEnv = setmetatable({
		require = function() return { makeAdder = function(list) return function(selector, style) list[#list + 1] = { selector = selector, style = style } end end } end,
		log = { message = function() end },
		api = { gui = { genericRep = { find = function() return 1 end, get = function() return { data = { Warning = "yellow", Error = "red", Invisible = "invisible", NeutralLightest = "white" } } end } } },
	}, { __index = _G })
	assert(loadfile(CSS, "t", cssEnv))()
	for _, rule in ipairs(cssEnv.data()) do rules[#rules + 1] = rule end
	local function ruleFor(fragment)
		for _, rule in ipairs(rules) do
			if rule.selector:find(fragment, 1, true) then return rule end
		end
		return { selector = "", style = {} }
	end
	local divider = ruleFor("ImageView!param-group-separator")
	for level = 1, 4 do
		check(divider.selector:find("!hubTitle" .. level, 1, true), "a divider above the title of level " .. level)
		check(not divider.selector:find("!hubLevel" .. level, 1, true), "no divider above the controls of level " .. level)
	end
	check(divider.selector:find("!hubLock", 1, true), "a divider above the note of a locked level")
	local hidden = ruleFor("separator!hubLevel1")
	check(hidden.style.visibility == "none" and hidden.selector:find("hubLevel4", 1, true), "the dividers above the controls of a level are hidden")
	local plain = ruleFor("hubLock ToggleButton!checked")
	check(plain.style.backgroundColor1 == "invisible" and plain.style.borderColor == "invisible" and plain.selector:find("hubTitle2 ToggleButton!unchecked", 1, true), "a title and a note have no button background")
	check(ruleFor("param-group!hubTitle1 TextView").style.fontWeight == "Bold", "the title of a level is bold")
	check(ruleFor("param-group!hubLock TextView").style.color == "red", "the lock note is red")
	check((divider.style.size or { 0, 0 })[2] == 4, "the divider is 4 px thick")
	check(divider.style.color == "yellow" and divider.style.backgroundColor1 == "yellow", "the divider is yellow")
	check((ruleFor("> BoxLayout").style.innerSpacing or { 0, 0 })[2] > 0, "the list has room between its blocks and dividers")
	check((ruleFor("Slider!horizontal").style.size or { 999 })[1] < 280, "the sliders are narrower than the original 280")
	local slider = ruleFor("Slider!horizontal").style
	check((slider.minSize or { 0 })[1] == (slider.maxSize or { 1 })[1], "the slider cannot grow, so its value box stays next to it")
	check((ruleFor("Window!construct-settings!no-close-button").style.maxSize or { 0, 0 })[2] > 460, "the settings window is taller than the original 460")
	for level = 1, 4 do
		for _, suffix in ipairs({ "Vehicle", "Angle", "Length", "TramLength" }) do
			for _, param in ipairs(con.params) do
				if param.key == "level" .. level .. suffix then check(param.group == "hubLevel" .. level, param.key .. " is in its level group") end
			end
		end
	end

	local text = support.readFile(STRINGS)
	local languages = select(2, text:gsub('\n  "[%a_]+": {', ""))
	local GAME_LANGUAGES = 13
	check(languages == GAME_LANGUAGES, "the strings cover the " .. GAME_LANGUAGES .. " languages of the game, found " .. languages)
	local _, stationNames = text:gsub('"{townName} Underground Station":', "")
	check(stationNames == GAME_LANGUAGES - 1, "the name of a new station is translated in every language but English, found " .. stationNames)
	local vanilla = { Catenary = true, No = true, Yes = true, ["Track Type"] = true, Simple = true, Standard = true, ["High-Speed"] = true }
	for _, key in ipairs(keys) do
		if not vanilla[key] and key:sub(1, 4) == "HUB_" then
			local _, count = text:gsub('"' .. key .. '":', "")
			check(count == languages, "string " .. key .. " exists in all " .. languages .. " languages, found " .. count)
		end
	end
end

-- The plot is turned: the street and the open side lie where the stairs of the entrance building
-- start, and the advertising column stands at the back in place of a row of benches.
do
	local STREET_Y, BACK_Y = 22.5, 6.5
	local BUILDING_BACK_Y, COLUMN_RADIUS = 10.76, 0.61
	-- The stairs of the entrance building run below the plot here, less deep than a hedge of the game
	-- reaches. Their ceiling is highest at the end towards the building.
	local STAIRS = { halfWidth = 1.7, fromY = 5.3, toY = 11.9 }
	local function stairsCeilingAt(y) return 0.30 - 0.571 * (11.82 - y) end
	local HEDGE_EXTENT = { ["hdg_02.mdl"] = { -1.52, 1.49 }, ["hdg_02_3m.mdl"] = { -1.46, 5.64 }, ["back_hedge.mdl"] = { -1.46, 5.64 } }
	local HEDGE_HALF_DEPTH = 1.34
	local BACK_HEDGE = OWN .. "models/back_hedge.mdl"
	local function footprint(model)
		local extent = HEDGE_EXTENT[model.id:match("([^/]+)$")]
		check(extent ~= nil, "the test knows the size of the hedge model " .. model.id)
		local m = model.transf
		local lowX, highX, lowY, highY = math.huge, -math.huge, math.huge, -math.huge
		for _, along in ipairs(extent or {}) do
			for _, across in ipairs({ -HEDGE_HALF_DEPTH, HEDGE_HALF_DEPTH }) do
				local x, y = m[1] * along + m[5] * across + m[13], m[2] * along + m[6] * across + m[14]
				lowX, highX, lowY, highY = math.min(lowX, x), math.max(highX, x), math.min(lowY, y), math.max(highY, y)
			end
		end
		return lowX, highX, lowY, highY
	end
	-- The deepest point of the back hedge model, read from its mesh.
	local function backHedgeDepth()
		local FLOAT_BYTES, COMPONENTS = 4, 3
		local folder = "content/stations/rail/underground_hub/models/msh/"
		local deepest = math.huge
		for lod = 0, 2 do
			local text = support.readFile(folder .. "back_hedge_lod" .. lod .. ".msh")
			local block = text:match("vertexAttr.-position = {([^}]*)}")
			local offset, count = block:match("offset = (%d+)"), block:match("count = (%d+)")
			local file = assert(io.open(folder .. "back_hedge_lod" .. lod .. ".msh.blob", "rb"))
			local blob = file:read("a")
			file:close()
			for at = tonumber(offset) + 1, tonumber(offset) + tonumber(count), COMPONENTS * FLOAT_BYTES do
				deepest = math.min(deepest, (string.unpack("<f", blob, at + 2 * FLOAT_BYTES)))
			end
		end
		return deepest
	end
	local function modelsOf(sub, fragment)
		local found = {}
		for _, model in ipairs(sub.models) do
			if model.id:find(fragment, 1, true) and near(model.transf[15], 0) then found[#found + 1] = model.transf end
		end
		return found
	end
	for _, mode in ipairs({ 1, 3 }) do
		local result, sub = build({ cargoMode = mode })
		local snap = result.snapPoint.transf
		check(near(snap[13], 0) and near(snap[14], STREET_Y) and near(snap[1], -1), "the station snaps to a street at the side where the stairs start, operation " .. mode)
		local pillars = modelsOf(sub, "era_c_street_pillar")
		check(#pillars > 0, "the street side has its light pillars")
		for _, m in ipairs(pillars) do check(near(m[14], STREET_Y), "a light pillar stands at the street side") end
		local column = modelsOf(sub, "advertisements/column")
		check(#column == 1 and near(column[1][13], 0) and column[1][14] + COLUMN_RADIUS < BUILDING_BACK_Y - 1 and column[1][14] > BACK_Y, "the advertising column stands at the back of the plot, clear of the entrance building")
		for _, m in ipairs(modelsOf(sub, "bench_c_metal")) do
			check(math.abs(m[13]) > 4, "no bench stands at the back or in front of the stairs, found one at x " .. m[13] .. " y " .. m[14])
		end
		for _, m in ipairs(modelsOf(sub, "hedges/")) do
			check(m[14] < STREET_Y - 0.4 or math.abs(m[13]) > 6, "no hedge closes the street side, found one at x " .. m[13])
		end
		-- The back hedge runs from one side hedge to the other without a gap, also above the stairs.
		-- It is the shallow model, and it stays above the ceiling of the stairs.
		local SIDE_HEDGE_INNER_X = 5.2
		local spans = {}
		for _, model in ipairs(sub.models) do
			if model.id == BACK_HEDGE then
				local lowX, highX, lowY, highY = footprint(model)
				check(near(model.transf[14], BACK_Y + 0.5), "a piece of the back hedge stands at the back of the plot, found y " .. model.transf[14])
				check(backHedgeDepth() > stairsCeilingAt(highY) + 0.5, "the back hedge stays 0.5 m above the ceiling of the entrance stairs")
				spans[#spans + 1] = { lowX, highX }
			elseif model.id:find("hedges/", 1, true) then
				local lowX, highX, lowY, highY = footprint(model)
				local aboveStairs = lowX < STAIRS.halfWidth and highX > -STAIRS.halfWidth and lowY < STAIRS.toY and highY > STAIRS.fromY
				check(not aboveStairs, "no deep hedge of the game stands above the stairs of the entrance building, found one at x " .. model.transf[13] .. " y " .. model.transf[14])
			end
		end
		table.sort(spans, function(a, b) return a[1] < b[1] end)
		check(#spans > 0 and spans[1][1] <= -SIDE_HEDGE_INNER_X, "the back hedge starts inside the side hedge")
		local covered = spans[1] and spans[1][2] or -math.huge
		for index = 2, #spans do
			check(spans[index][1] <= covered, "the back hedge has no gap, found one at x " .. covered)
			covered = math.max(covered, spans[index][2])
		end
		check(covered >= SIDE_HEDGE_INNER_X, "the back hedge ends inside the other side hedge, found " .. covered)

		-- The ground texture turns with the plot: its asphalt row lies at the street side. The part
		-- between the hedges is paved up to the street.
		local textured, paved = nil, nil
		for _, ground in ipairs(sub.groundFaces) do
			local mode = ground.modes[1]
			if mode.key:find("underground_station.gtex", 1, true) then textured = ground end
			if mode.key:find("asphalt_01.gtex", 1, true) and not paved then
				for _, point in ipairs(ground.face) do
					if near(point[2], STREET_Y) and math.abs(point[1]) < 6 then paved = ground end
				end
			end
		end
		check(textured ~= nil and paved ~= nil, "the plot has its ground texture and a paved part at the street, operation " .. mode)
		for _, ground in ipairs(sub.groundFaces) do
			check(ground.modes[1].key:match("%.gtex$") ~= nil, "a ground face names a ground texture, found " .. ground.modes[1].key)
		end
		if textured then
			for index, point in ipairs(textured.face) do
				local atStreet = near(point[2], STREET_Y)
				check(atStreet or near(point[2], BACK_Y), "the ground texture covers the plot from the back to the street")
				check(near(textured.modes[1].texCoords[index][2], atStreet and 0 or 1), "the asphalt row of the ground texture lies at the street side")
			end
		end
	end
	local _, cargo = build({ cargoMode = 2 })
	local depot = modelsOf(cargo, "surface_cargo_depot")
	check(#depot == 1 and depot[1][13] > 6, "the cargo depot stands on the other side after the turn")
	check(#modelsOf(cargo, "advertisements/column") == 0, "a cargo hub has no advertising column")
end

-- The files of the mod page and the pictures of the menu.
do
	local NAME_LIMIT, SUMMARY_LIMIT = 32, 100
	local page = support.readFile("_metadata/modinfo.json")
	local name, summary = page:match('"name": "([^"]+)",\n    "summary"'), page:match('"summary": "([^"]+)"')
	check(name ~= nil and #name <= NAME_LIMIT, "the name of the mod page has at most " .. NAME_LIMIT .. " characters")
	check(summary ~= nil and #summary <= SUMMARY_LIMIT and not summary:find("\n", 1, true), "the summary of the mod page has at most " .. SUMMARY_LIMIT .. " characters")
	check(name ~= nil and support.readFile(STRINGS):find('"HUB_UNDERGROUND_RAIL_NAME": "' .. name .. '"', 1, true) ~= nil, "the construction menu and the mod page use the same English name")

	local function bytes(path, count)
		local file = io.open(path, "rb")
		check(file ~= nil, "picture exists: " .. path)
		if not file then return nil end
		local head = file:read(count)
		file:close()
		return head
	end
	-- A PNG holds its width and height as big-endian numbers at bytes 17 and 21.
	local PAGE_WIDTH, PAGE_HEIGHT, GALLERY = 1920, 1080, 4
	for index = 0, GALLERY do
		local head = bytes("_metadata/" .. index .. ".png", 24)
		if head then
			local width, height = string.unpack(">I4I4", head, 17)
			check(width == PAGE_WIDTH and height == PAGE_HEIGHT, "picture " .. index .. " of the mod page is " .. PAGE_WIDTH .. " x " .. PAGE_HEIGHT)
		end
	end
	-- A TGA holds its width and height as little-endian numbers at bytes 13 and 15.
	local sizes = { ["underground_hub.tga"] = { 120, 75 }, ["underground_hub@2x.tga"] = { 240, 150 }, ["underground_hub_preview@2x.tga"] = { 1600, 900 } }
	for file, size in pairs(sizes) do
		local head = bytes("content/stations/rail/underground_hub/" .. file, 18)
		if head then
			local width, height = string.unpack("<I2I2", head, 13)
			check(width == size[1] and height == size[2], file .. " is " .. size[1] .. " x " .. size[2] .. ", found " .. width .. " x " .. height)
		end
	end
	check(bytes("image_00.jpg", 2) ~= nil, "the picture of the mod list exists")
end

-- The tunnel type of the outer tram tunnel piece: the car tunnel of the game with the dead-end wall
-- switched on, in no menu, with every file named as a file of the game.
do
	local tunnel = support.readFile("content/stations/rail/underground_hub/tram_end.tunnel.lua")
	local dead = tunnel:match("deadConfig = {([^}]*)}")
	local DEAD_MODELS_FOR_A_WALL = 5
	check(dead ~= nil and select(2, dead:gsub("tunnel_b_car_dead_", "")) == DEAD_MODELS_FOR_A_WALL, "the tram tunnel names five dead-end models, so the game closes its dead end")
	check(tunnel:find('local newdir = "::/infrastructure/tunnel/b_car/"', 1, true) ~= nil and tunnel:find('fileName = "::/infrastructure/tunnel/tunnel.script@tunnel.updateFn"', 1, true) ~= nil, "the tram tunnel names the models and the script of the game")
	check(tunnel:find("categories = {},", 1, true) ~= nil and tunnel:find("yearFrom = -1,", 1, true) ~= nil, "the tram tunnel is in no menu")
	check(not tunnel:find('"/infrastructure', 1, true), "the tram tunnel names no file without the prefix of the game")
end

-- The mod Cargo Range (gabri_cargo_catchment_1) finds a station by the path of its update script.
-- The hub hands its update function to the game under a path that the mod supports.
do
	-- How that mod reads a script name: without the mod name, the function name and ".lua".
	local function asRangeModReads(name)
		return (name:gsub("^.-::", ""):gsub("@.*$", ""):gsub("%.lua$", ""))
	end
	local SUPPORTED = "/stations/street/underground_freight/underground_freight.script"
	local con = loadCon(CON, setmetatable({ _ = function(key) return key end }, { __index = _G }))
	check(asRangeModReads(con.updateScript.fileName) == SUPPORTED, "the update script of the hub has a path that the range mod supports, found " .. con.updateScript.fileName)
	check(con.updateScript.fileName:match("^kacsa_underground_hub::/") ~= nil and con.updateScript.fileName:match("@updateFn$") ~= nil, "the update script is named with the mod name and the function")
	local alias, own = support.loadScript(RANGE_MOD_SCRIPT), support.loadScript(SCRIPT)
	check(type(alias.updateFn) == "function" and type(own.updateFn) == "function" and type(own.checkHiddenFn) == "function", "both script files hand out the functions of the hub")
	local module = support.readFile(RANGE_MOD_SCRIPT)
	check(module:find("functions[name] = fn", 1, true) ~= nil, "a script file returns a new table on every call, so a replaced function is not replaced twice")
	local result = alias.updateFn(CAPTURE, { level2Vehicle = 2 })
	check(#result.subconstructions[1].station.terminals == 4, "the update function under the supported path builds the hub")

	-- What that mod reads in the result: the terminals tell passengers from cargo, a cargo type set
	-- holds only classes, and the station has one catchment area with a radius.
	local OPERATIONS = { { mode = 1, passengers = true, cargo = false }, { mode = 2, passengers = false, cargo = true }, { mode = 3, passengers = true, cargo = true } }
	for _, operation in ipairs(OPERATIONS) do
		local _, sub = build({ cargoMode = operation.mode })
		for _, terminal in ipairs(sub.station.terminals) do
			check(terminal.passengers == operation.passengers and terminal.cargo == operation.cargo, "a terminal tells whether it serves passengers and cargo, operation " .. operation.mode)
			for _, speed in ipairs(terminal.cargoTransferSpeeds) do
				local set = speed.cargoTypeSet
				check(set.cargoTypesIncluded == nil and set.cargoTypesExcluded == nil and set.cargoClassesExcluded == nil, "a cargo type set names only included classes")
				for _, class in ipairs(set.cargoClassesIncluded) do
					check(class == "PASSENGERS" or (operation.cargo and class == "UNIVERSAL"), "a passenger hub names only the class PASSENGERS, found " .. class)
				end
			end
		end
		check(#sub.station.catchmentAreas == 1 and type(sub.station.catchmentAreas[1].radius) == "number", "the station has one catchment area with a radius")
	end
end

-- Every model the script names exists in the mod.
do
	local text = support.readFile(SCRIPT_MODULE)
	for path in text:gmatch('"(models/[%w_/]+%.mdl)"') do
		local file = io.open("content/stations/rail/underground_hub/" .. path, "rb")
		check(file ~= nil, "model file exists: " .. path)
		if file then file:close() end
	end
end

-- The icon and the preview image are files of this mod, named relative to the construction file.
-- A path that starts with "::/" names a file of the game, not of this mod.
do
	local text = support.readFile(CON_MODULE)
	local icon = text:match('%s+icon = "([^"]+)"')
	local preview = text:match('%s+previewIcon = "([^"]+)"')
	check(icon == "underground_hub.tga" and preview == "underground_hub_preview@2x.tga", "the menu entry names the icon and the preview image of this mod, found " .. tostring(icon) .. " and " .. tostring(preview))
	check(not text:find('"::/stations/rail/underground_hub/', 1, true), "no file of this mod is named with the prefix of the game")
	for _, name in ipairs({ "underground_hub.tga", "underground_hub@2x.tga", "underground_hub_preview@2x.tga" }) do
		local file = io.open("content/stations/rail/underground_hub/" .. name, "rb")
		check(file ~= nil, "image file exists: " .. name)
		if file then file:close() end
	end
	check(support.readFile(ROAD_CON):find('menuCategory = "road_buildings"', 1, true) and support.readFile(CON):find('menuCategory = "rail_buildings"', 1, true), "the station is listed under road buildings and rail buildings")
end

if failures > 0 then
	print(failures .. " checks failed")
	os.exit(1)
end
print("ok hub levels, tram, cargo and parameters")
