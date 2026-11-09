local maxLevels = 4
local defaultAngleIndices = { 1, 19, 10, 28 }

local function angleValues(stepIncrement)
	local values = {}
	local numSteps = (360.0 / stepIncrement);
	for i=0, numSteps do
		values[#values + 1 ] = tostring(i * stepIncrement)
	end
	return values
end

local function levelEnabledScript(level)
	if level == 1 then return nil end
	return { fileName = "station.script@checkLevel" .. level .. "EnabledFn", params = {} }
end

local function railEnabledScript()
	return { fileName = "station.script@checkRailOptionsEnabledFn", params = {} }
end

local function makeLevelCountParam()
	local values, numbers = {}, {}
	for level = 1, maxLevels do
		values[level] = tostring(level)
		numbers[level] = level
	end
	return {
		key = "levelCount",
		name = _("HUB_LEVEL_COUNT"),
		values = values,
		numbers = numbers,
		defaultIndex = 1,
		displayMode = "Horizontal",
		group = "hubGeneral",
	}
end

local function makeCargoModeParam()
	return {
		key = "cargoMode",
		name = _("HUB_CARGO_MODE"),
		values = { _("HUB_CARGO_PASSENGER"), _("HUB_CARGO_CARGO"), _("HUB_CARGO_MIXED") },
		defaultIndex = 1,
		displayMode = "Horizontal",
		group = "hubGeneral",
	}
end

local function makeLevelVehicleParam(level)
	return {
		key = "level" .. level .. "Vehicle",
		name = _("HUB_LEVEL_" .. level .. "_VEHICLE"),
		values = { _("HUB_VEHICLE_RAIL"), _("HUB_VEHICLE_TRAM") },
		defaultIndex = 1,
		displayMode = "Horizontal",
		group = "hubLevel" .. level,
		checkEnabledScript = levelEnabledScript(level),
	}
end

local function makeLevelAngleParam(level, stepIncrement)
	return {
		key = "level" .. level .. "Angle",
		name = _("HUB_LEVEL_" .. level .. "_ANGLE"),
		displayMode = "Sparse",
		values = angleValues(stepIncrement),
		defaultIndex = defaultAngleIndices[level],
		uiType = "Slider",
		group = "hubLevel" .. level,
		checkEnabledScript = levelEnabledScript(level),
	}
end

local function makePlatformLengthsValues(platformConfig)
	local result = { }

	for i = 1, #platformConfig do
		result[#result + 1] = tostring(platformConfig[i]) .. " m"
	end

	return result
end

local function makeLevelLengthParam(level, platformLengths)
	-- Menu positions map to the saved values, so the choices are displayed in ascending order.
	local indices = {}
	for i = 1, #platformLengths do indices[i] = i end
	table.sort(indices, function(a, b) return platformLengths[a] < platformLengths[b] end)
	local sortedLengths = {}
	local defaultIndex = 1
	for position, savedIndex in ipairs(indices) do
		sortedLengths[position] = platformLengths[savedIndex]
		if savedIndex == 2 then defaultIndex = position end
	end
	return {
		key = "level" .. level .. "Length",
		name = _("HUB_LEVEL_" .. level .. "_LENGTH"),
		values = makePlatformLengthsValues(sortedLengths),
		numbers = indices,
		defaultIndex = defaultIndex,
		displayMode = "Sparse",
		group = "hubLevel" .. level,
		checkEnabledScript = levelEnabledScript(level),
	}
end

-- The order of the lengths is fixed: it is the saved index of the length parameter.
local platformLengthValues = {160, 240, 320, 40, 80, 120}
local stepIncrement = 5.0

local function makeParams()
	local params = {
		makeLevelCountParam(),
		makeCargoModeParam(),
		{ key = "ballast", name = _("HUB_BALLAST_LABEL"), values = {_("HUB_BALLAST_ON"), _("HUB_BALLAST_OFF")}, defaultIndex = 1, group = "hubGeneral", checkEnabledScript = railEnabledScript() },
		{ key = "trackType", name = _("Track Type"), defaultIndex = 2,
		  tooltips = {_("Simple"), _("Standard")},
		  values = {"::/infrastructure/track/simple/simple.tga", "::/infrastructure/track/standard/standard.tga"},
		  displayMode = "Horizontal", uiType = "IconButton", yearFrom = 1930, yearTo = 1980, group = "hubGeneral", checkEnabledScript = railEnabledScript() },
		{ key = "trackType", name = _("Track Type"), defaultIndex = 2,
		  tooltips = {_("Simple"), _("Standard"), _("High-Speed")},
		  values = {"::/infrastructure/track/simple/simple.tga", "::/infrastructure/track/standard/standard.tga", "::/infrastructure/track/high_speed/high_speed.tga"},
		  displayMode = "Horizontal", uiType = "IconButton", yearFrom = 1980, yearTo = 0, group = "hubGeneral", checkEnabledScript = railEnabledScript() },
		{ key = "catenary", name = _("Catenary"), values = {_("No"), _("Yes")}, defaultIndex = 2, group = "hubGeneral" },
		{ key = "interiorStyle", name = _("HUB_STYLE_LABEL"), values = {_("HUB_STYLE_ORIGINAL"), _("HUB_STYLE_JAPANESE")}, defaultIndex = 1, group = "hubStyle" },
		{ key = "tunnelType", name = _("HUB_TUNNEL_LABEL"), values = {_("HUB_TUNNEL_CONCRETE"), _("HUB_TUNNEL_OLD")}, defaultIndex = 1, group = "hubStyle", checkEnabledScript = railEnabledScript() },
	}
	for level = 1, maxLevels do
		params[#params + 1] = makeLevelVehicleParam(level)
		params[#params + 1] = makeLevelAngleParam(level, stepIncrement)
		params[#params + 1] = makeLevelLengthParam(level, platformLengthValues)
	end
	return params
end

local function makeConstructionTemplates()
	local templates = {}

	local function addTemplate(from, to)
		local yearCoefficient = 10
		table.insert(templates, {
			type = "DYNAMIC",
			configureLayerScript = {
				fileName = "::/gui/construction/construction_desc_layers.script@configureDefaultLayerFn",
				params = {
					heightmapContours = true,
				}
			},
			configureHudIconsScript = {
				fileName = "::/gui/construction/construction_desc_hud_icons.script@configureStationHudIconsFn",
				params = {
					cargo = true,
				}
			},
			availability = {
				yearFrom = from,
				yearTo = to
			},
			description = {
				name = _("HUB_UNDERGROUND_RAIL_NAME"),
				description = _("HUB_UNDERGROUND_RAIL_DESC"),
				icon = "::/stations/street/underground_station/underground_station.tga",
				previewIcon = "::/stations/street/underground_station/underground_station_preview.tga",
				attributes = {
					noise =  { 40, -1 },
					pollution = { 80, -1 },
					maintenanceCost = { 20000 * yearCoefficient, -1 },
					cost = { 120000 * yearCoefficient, -1 },
				},
				cargoTypeSet = {
					cargoClassesExcluded = {},
					cargoClassesIncluded = { "PASSENGERS", "UNIVERSAL", },
					cargoTypesExcluded = {},
					cargoTypesIncluded = {},
				},
			},
			data = {
				params = {}
			},
			menuCategory = {
				categories = {
					{
						category = "rail_buildings",
						filterCategories = { "passenger", "cargo", },
						order = 5000,
					},
				},
			},
		})
	end

	addTemplate(1970, 0)

	return templates
end


function data()
return {
	configureLayerScript = {
		fileName = "::/gui/construction/construction_desc_layers.script@configureDefaultLayerFn",
		params = {
			heightmapContours = true,
		}
	},
	configureHudIconsScript = {
		fileName = "::/gui/construction/construction_desc_hud_icons.script@configureStationHudIconsFn",
		params = {
			cargo = true,
		}
	},
	namePrefix = _("{townName} Underground Station"),
	subConstructionNamePrefix = "{constructionName}",
	description = {
		name = _("HUB_UNDERGROUND_RAIL_NAME"),
		description = _("HUB_UNDERGROUND_RAIL_DESC"),
		icon = "",
		previewIcon = "",
		attributes = {
			noise =  { 40, -1 },
			pollution = { 80, -1 },
			maintenanceCost = { 20000, -1 },
			cost = { 120000, -1 },
		},
		cargoTypeSet = {
			cargoClassesExcluded = {},
			cargoClassesIncluded = { "PASSENGERS", "UNIVERSAL", },
			cargoTypesExcluded = {},
			cargoTypesIncluded = {},
		},
	},
	availability = {
	},
	soundConfig = {
		builderAudioRes = "::/gui/construction/sound/buildoze_construction_large.builder_audio",
	},
	undergroundView = true,
	order = 9000,
	params = makeParams(),
	updateScript = {
		fileName = "station.script@updateFn",
		params = {
			platformLengths = platformLengthValues,
			stepIncrement = stepIncrement
		}
	},
	createTemplateScript = {
		fileName = "station.script@createTemplateFn",
		params = {}
	},
	constructionTemplates = makeConstructionTemplates(),
}

end
