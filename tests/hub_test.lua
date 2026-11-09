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
	local result, sub = build({ levelCount = 4 })
	check(#sub.station.terminals == 8, "four levels give eight terminals")
	check(#result.edgeLists == 24, "four rail levels add 24 edge calls, got " .. #result.edgeLists)
	check(#sub.laneLists == 21, "four rail levels give 21 lanes, got " .. #sub.laneLists)
	for level = 1, 4 do
		local firstEdge = result.edgeLists[(level - 1) * 6 + 1]
		check(near(firstEdge.curves[1][1][3], -19.28 - 18 * (level - 1)), "level " .. level .. " tunnel track depth")
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

-- Level angle and length reach the geometry.
do
	local _, sub = build({ levelCount = 2, level1Length = 4, level2Length = 3, level2Angle = 37 })
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
	local result, sub = build({ levelCount = 4, level2Vehicle = 2, level3Vehicle = 2 })
	local terminals = sub.station.terminals
	check(#terminals == 8, "mixed hub has eight terminals")
	check(#result.edgeLists == 16, "mixed hub adds 16 edge calls, got " .. #result.edgeLists)
	check(result.edgeLists[7].kind == "STREET" and result.edgeLists[7].spec.tramTrackType == "ELECTRIC", "tram level uses an electric street edge by default")
	for _, index in ipairs({ 3, 4, 5, 6 }) do
		local terminal = terminals[index]
		check(terminal.transportModes[1] == "TRAM", "terminal " .. index .. " serves trams")
		check(terminal.vehicleNode[2] == 1 and laneAt(sub, terminal.vehicleNode[1]).types[1] == "TRAM", "terminal " .. index .. " points at a tram lane")
	end
	check(terminals[7].transportModes[1] == "TRAIN" and terminals[7].vehicleNode[2] == 25, "rail level after two tram levels starts at node 25")
	check(terminals[8].vehicleNode[2] == 33, "second track of that level is node 33")
	local _, _, data = build({})
	local plain = data.updateFn(CAPTURE, { levelCount = 2, level2Vehicle = 2, catenary = 1 })
	check(plain.edgeLists[7].spec.tramTrackType == "YES", "catenary off gives plain tram track")
end

-- Cargo mode.
do
	local _, passenger = build({ cargoMode = 1 })
	local _, cargo = build({ cargoMode = 2 })
	local _, mixed = build({ cargoMode = 3, levelCount = 2, level2Vehicle = 2 })
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

-- Greying out of the controls. The game calls a check function with the captured parameters of
-- the script reference and the flat table of the current values, and expects a text.
do
	local data = support.loadScript(SCRIPT)
	local function check2(fn, values) return data[fn]({}, values) end
	check(check2("checkLevel2EnabledFn", { levelCount = 1 }) == "Disabled", "level 2 controls disabled for one level")
	check(check2("checkLevel2EnabledFn", { levelCount = 2 }) == "Enabled", "level 2 controls enabled for two levels")
	check(check2("checkLevel4EnabledFn", { levelCount = 3 }) == "Disabled", "level 4 controls disabled for three levels")
	check(check2("checkLevel3EnabledFn", { levelCount = 3 }) == "Enabled", "level 3 controls enabled for three levels")
	check(check2("checkRailOptionsEnabledFn", { levelCount = 2, level1Vehicle = 2, level2Vehicle = 2 }) == "Disabled", "rail options disabled when all levels are tram")
	check(check2("checkRailOptionsEnabledFn", { levelCount = 1 }) == "Enabled", "rail options enabled for a rail level")
	check(check2("checkRailOptionsEnabledFn", { levelCount = 2, level1Vehicle = 2, level2Vehicle = 2, level3Vehicle = 1 }) == "Disabled", "a rail level above the level count does not count")
	check(data.checkRailOptionsEnabledFn() == "Enabled", "rail options stay enabled when the arguments are unknown")
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
	for _, key in ipairs({ "levelCount", "cargoMode", "catenary", "ballast", "trackType", "interiorStyle", "tunnelType", "level1Vehicle", "level2Angle", "level3Length", "level4Vehicle" }) do
		check(seen[key], "parameter " .. key .. " exists")
	end
	check(not seen.layout and not seen.platformOrientation, "removed parameters stay removed")

	-- A group shows as one block with a divider, so its parameters MUST be next to each other.
	local closed, previous = {}, nil
	for _, param in ipairs(con.params) do
		if param.group ~= previous then
			check(param.group == nil or not closed[param.group], "group " .. tostring(param.group) .. " is not split")
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
		api = { gui = { genericRep = { find = function() return 1 end, get = function() return { data = { Warning = "yellow" } } end } } },
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
	local firstGroup = con.params[1].group
	local groupsWithDivider = {}
	for _, param in ipairs(con.params) do
		if param.group and param.group ~= firstGroup and not groupsWithDivider[param.group] then
			groupsWithDivider[param.group] = true
			check(divider.selector:find("!" .. param.group, 1, true), "the divider style covers group " .. param.group)
		end
	end
	for group in divider.selector:gmatch("separator!(%w+)") do
		check(groupsWithDivider[group], "the divider style names only existing groups: " .. group)
	end
	check(seen.tramCatenary == nil and seen.catenary == 1, "one catenary switch serves rail and tram levels")
	local order = {}
	for _, param in ipairs(con.params) do
		if #order == 0 or order[#order] ~= param.key then order[#order + 1] = param.key end
	end
	for position, key in ipairs({ "levelCount", "cargoMode", "ballast", "trackType", "catenary", "interiorStyle", "tunnelType", "level1Vehicle" }) do
		check(order[position] == key, "parameter " .. position .. " is " .. key .. ", found " .. tostring(order[position]))
	end
	for _, key in ipairs({ "levelCount", "cargoMode", "ballast", "trackType", "catenary" }) do
		check(groupOf[key] == "hubGeneral", key .. " is in the first block")
	end
	for _, key in ipairs({ "interiorStyle", "tunnelType" }) do
		check(groupOf[key] == "hubStyle", key .. " is in the second block")
	end
	check((divider.style.size or { 0, 0 })[2] == 4, "the divider is 4 px thick")
	check(divider.style.color == "yellow" and divider.style.backgroundColor1 == "yellow", "the divider is yellow")
	check((ruleFor("> BoxLayout").style.innerSpacing or { 0, 0 })[2] > 0, "the list has room between its blocks and dividers")
	check((ruleFor("Slider!horizontal").style.size or { 999 })[1] < 280, "the sliders are narrower than the original 280")
	local slider = ruleFor("Slider!horizontal").style
	check((slider.minSize or { 0 })[1] == (slider.maxSize or { 1 })[1], "the slider cannot grow, so its value box stays next to it")
	check((ruleFor("Window!construct-settings!no-close-button").style.maxSize or { 0, 0 })[2] > 460, "the settings window is taller than the original 460")
	for level = 1, 4 do
		for _, suffix in ipairs({ "Vehicle", "Angle", "Length" }) do
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

if failures > 0 then
	print(failures .. " checks failed")
	os.exit(1)
end
print("ok hub levels, tram, cargo and parameters")
