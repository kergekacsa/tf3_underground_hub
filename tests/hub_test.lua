local support = require("support")

local SCRIPT = "content/stations/rail/underground_hub/station.script.lua"
local CON = "content/stations/rail/underground_hub/station.con.lua"
local CSS = "content/stations/rail/underground_hub/hub_params.css.lua"
local STRINGS = "strings.json"
local CAPTURE = { platformLengths = { 160, 240, 320, 40, 80, 120 }, stepIncrement = 5.0 }
local EPSILON = 1e-6
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

local function hasModel(sub, fragment)
	for _, model in ipairs(sub.models) do
		if model.id:find(fragment, 1, true) then return true end
	end
	return false
end

local function laneAt(sub, index) return sub.laneLists[index + 1] end

-- Four rail levels: depth, terminals, node indices and shafts.
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
	local shaft = laneAt(sub, 6)
	check(#shaft.curves == 1 and #shaft.curves[1] == 2, "level 2 shaft is one straight lane")
	check(near(shaft.curves[1][1][3], -12) and near(shaft.curves[1][2][3], -30), "level 2 shaft runs from the ring down 18 m")
	local top, bottom = shaft.curves[1][1], shaft.curves[1][2]
	check(near(math.sqrt(top[1] ^ 2 + top[2] ^ 2), 8.5) and near(top[1], bottom[1]) and near(top[2], bottom[2]), "level 2 shaft stands upright on the ring of radius 8.5")
end

-- A level keeps its depth by its number, so level 3 can exist without level 2.
do
	local result, sub = build({ level3Vehicle = 2 })
	check(#sub.station.terminals == 4, "levels 1 and 3 give four terminals")
	local lane = laneAt(sub, sub.station.terminals[3].personEdges[1][1])
	check(near(lane.curves[1][1][3], -17.65 - 36), "level 3 lies two levels below level 1 even without level 2")
	check(near(result.edgeLists[7].curves[1][1][3], -18.3 - 36), "the rail track of level 3 lies at its own depth")
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
	check(#result.edgeLists == 20, "mixed hub adds 20 edge calls, got " .. #result.edgeLists)
	check(result.edgeLists[7].kind == "TRACK" and result.edgeLists[7].spec.edgeTypeName == "station_hall.tunnel" and result.edgeLists[7].spec.type == "track_silhouette.street_template", "a tram level starts with inert silhouette edges across its hall")
	local first, second = result.edgeLists[7].curves[1][1], result.edgeLists[8].curves[1][1]
	check(result.edgeLists[8].spec.type == "track_silhouette.street_template" and near(math.sqrt((first[1] - second[1]) ^ 2 + (first[2] - second[2]) ^ 2), 5), "the silhouette is two parallel tracks 5 m apart")
	check(result.edgeLists[9].kind == "STREET" and result.edgeLists[9].spec.tramTrackType == "ELECTRIC", "tram level uses an electric street edge by default")
	for _, index in ipairs({ 3, 4, 5, 6 }) do
		local terminal = terminals[index]
		check(terminal.transportModes[1] == "TRAM", "terminal " .. index .. " serves trams")
		check(terminal.vehicleNode[2] == 1 and laneAt(sub, terminal.vehicleNode[1]).types[1] == "TRAM", "terminal " .. index .. " points at a tram lane")
	end
	check(terminals[7].transportModes[1] == "TRAIN" and terminals[7].vehicleNode[2] == 41, "rail level after two tram levels starts at node 41")
	check(terminals[8].vehicleNode[2] == 49, "second track of that level is node 49")
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
		if id:sub(1, 2) ~= "::" and not id:find("^models/cargo/") and not id:find("^models/shared/") then own = own + 1 end
	end
	check(own == 0, "every model is a game model, a cargo model or a strip, found " .. own .. " others")
	check(hasModel(sub, "underground_station_end.mdl") and hasModel(sub, "underground_station_extension.mdl") and hasModel(sub, "underground_station_stairs.mdl"), "the hall of the game station is used")
	local rail, tram = 0, 0
	for _, model in ipairs(sub.models) do
		if model.id == "models/shared/platform_led_strip.mdl" then rail = rail + 1 end
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
	assert(loadfile(CON, "t", env))()
	local con = env.data()
	local script = support.loadScript(SCRIPT)
	local seen, groupOf = {}, {}
	for _, param in ipairs(con.params) do
		seen[param.key] = (seen[param.key] or 0) + 1
		groupOf[param.key] = param.group
		if param.checkEnabledScript then
			local name = param.checkEnabledScript.fileName:match("@(.+)$")
			check(type(script[name]) == "function", "param " .. param.key .. " names a check function that exists: " .. name)
		end
	end
	for _, key in ipairs({ "cargoMode", "catenary", "trackType", "level1Title", "level1Vehicle", "level2Title", "level4Title", "level2Angle", "level3Length", "level3TramLength", "level4Vehicle", "level1Lock", "level4Lock", "hubPlacement" }) do
		check(seen[key], "parameter " .. key .. " exists")
	end
	check(not seen.layout and not seen.platformOrientation and not seen.ballast and not seen.interiorStyle and not seen.tramCatenary and not seen.tunnelType, "removed parameters stay removed")
	check(seen.trackType == 2, "two year-gated track type selectors")
	check(seen.levelCount == nil and seen.level2Active == nil, "there is neither a level count nor a separate level switch")
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
	local vanilla = { Catenary = true, No = true, Yes = true, ["Track Type"] = true, Simple = true, Standard = true, ["High-Speed"] = true }
	for _, key in ipairs(keys) do
		if not vanilla[key] and key:sub(1, 4) == "HUB_" then
			local _, count = text:gsub('"' .. key .. '":', "")
			check(count == languages, "string " .. key .. " exists in all " .. languages .. " languages, found " .. count)
		end
	end
end

-- Every model the script names exists in the mod.
do
	local text = support.readFile(SCRIPT)
	for path in text:gmatch('"(models/[%w_/]+%.mdl)"') do
		local file = io.open("content/stations/rail/underground_hub/" .. path, "rb")
		check(file ~= nil, "model file exists: " .. path)
		if file then file:close() end
	end
end

if failures > 0 then
	print(failures .. " checks failed")
	os.exit(1)
end
print("ok hub levels, tram, cargo and parameters")
