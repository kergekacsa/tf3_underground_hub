-- The construction of the hub, shared by its two construction files: one for each menu.
local hub = {}

-- The choices of the vehicle selector of level 1.
hub.vehicle = { rail = 1, tram = 2 }
-- Rail on level 1, Off on the other levels.
local defaultVehicleIndex = 1

local maxLevels = 4
local defaultAngleIndices = { 1, 19, 10, 28 }

-- A level looks the same after half a turn, so its angle runs over half a circle.
local maxLevelAngle = 180.0

local function angleValues(stepIncrement)
	local values = {}
	local numSteps = (maxLevelAngle / stepIncrement);
	for i=0, numSteps do
		values[#values + 1 ] = tostring(i * stepIncrement)
	end
	return values
end

local function checkScript(name)
	return { fileName = "station.script@" .. name, params = {} }
end

local function levelEnabledScript(level)
	return checkScript("checkLevel" .. level .. "EnabledFn")
end

local function makeCargoModeParam()
	return {
		key = "cargoMode",
		name = _("HUB_CARGO_MODE"),
		values = { _("HUB_CARGO_PASSENGER"), _("HUB_CARGO_CARGO"), _("HUB_CARGO_MIXED") },
		defaultIndex = 1,
		displayMode = "Horizontal",
		group = "hubGeneral",
		postConstructionModifiable = true,
	}
end

-- The title of a level: a note with one value, shown as bold text above the controls of the level.
local function makeLevelTitleParam(level)
	return {
		key = "level" .. level .. "Title",
		name = _("HUB_LEVEL_" .. level .. "_TITLE"),
		values = { _("HUB_LEVEL_" .. level .. "_TITLE") },
		defaultIndex = 1,
		uiType = "Button",
		hideLabel = true,
		group = "hubTitle" .. level,
		postConstructionModifiable = true,
	}
end

-- Level 1 has rail and tram. Levels 2 to 4 also have off, which removes the level.
local function makeLevelVehicleParam(level, defaultIndex)
	local values = { _("HUB_VEHICLE_RAIL"), _("HUB_VEHICLE_TRAM") }
	if level >= 2 then table.insert(values, 1, _("HUB_VEHICLE_OFF")) end
	return {
		key = "level" .. level .. "Vehicle",
		name = _("HUB_LEVEL_VEHICLE"),
		values = values,
		defaultIndex = defaultIndex,
		displayMode = "Horizontal",
		hideLabel = true,
		group = "hubLevel" .. level,
		postConstructionModifiable = true,
		checkEnabledScript = level == 1 and levelEnabledScript(1) or checkScript("checkLevel" .. level .. "SwitchFn"),
	}
end

-- A note with one value that the game greys out. The stylesheet colours the group red.
local function makeLevelLockParam(level)
	return {
		key = "level" .. level .. "Lock",
		name = _("HUB_LEVEL_" .. level .. "_LOCKED"),
		values = { _("HUB_LEVEL_" .. level .. "_LOCKED") },
		defaultIndex = 1,
		uiType = "Button",
		hideLabel = true,
		group = "hubLock",
		postConstructionModifiable = true,
		checkEnabledScript = checkScript("checkLevel" .. level .. "LockFn"),
	}
end

-- Only a station that is being placed has this parameter: the game leaves out parameters that cannot
-- change after construction when it edits a built station. The script tells the two cases apart by it.
local function makePlacementMarkerParam()
	return {
		key = "hubPlacement",
		name = "hubPlacement",
		values = { "" },
		defaultIndex = 1,
		uiType = "Button",
		hideLabel = true,
		checkEnabledScript = checkScript("checkHiddenFn"),
	}
end

-- The game stores a random seed with every construction. This hidden parameter makes the panel of a
-- built station hand that seed to the check functions, so the script finds exactly the station
-- that is edited. Its first year keeps it out of the menu while a station is placed, so the menu
-- never sets a seed.
local neverInMenuYear = 9999

local function makeStationSeedParam()
	return {
		key = "seed",
		name = "seed",
		values = { "" },
		defaultIndex = 1,
		uiType = "Button",
		hideLabel = true,
		yearFrom = neverInMenuYear,
		yearTo = 0,
		postConstructionModifiable = true,
		checkEnabledScript = checkScript("checkHiddenFn"),
	}
end

local function makeLevelAngleParam(level, stepIncrement)
	return {
		key = "level" .. level .. "Angle",
		name = _("HUB_LEVEL_ANGLE"),
		displayMode = "Sparse",
		values = angleValues(stepIncrement),
		defaultIndex = defaultAngleIndices[level],
		uiType = "Slider",
		group = "hubLevel" .. level,
		postConstructionModifiable = true,
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

-- A rail level starts at 240 m and a tram level at 40 m: the saved indices 2 and 4 of the platform lengths.
local function makeLevelLengthParam(level, platformLengths, forTram)
	local defaultSavedIndex = forTram and 4 or 2
	-- Menu positions map to the saved values, so the choices are displayed in ascending order.
	local indices = {}
	for i = 1, #platformLengths do indices[i] = i end
	table.sort(indices, function(a, b) return platformLengths[a] < platformLengths[b] end)
	local sortedLengths = {}
	local defaultIndex = 1
	for position, savedIndex in ipairs(indices) do
		sortedLengths[position] = platformLengths[savedIndex]
		if savedIndex == defaultSavedIndex then defaultIndex = position end
	end
	return {
		key = "level" .. level .. (forTram and "TramLength" or "Length"),
		name = _("HUB_LEVEL_LENGTH"),
		values = makePlatformLengthsValues(sortedLengths),
		numbers = indices,
		defaultIndex = defaultIndex,
		displayMode = "Sparse",
		group = "hubLevel" .. level,
		postConstructionModifiable = true,
		checkEnabledScript = checkScript("checkLevel" .. level .. (forTram and "TramLengthFn" or "LengthFn")),
	}
end

-- The order of the lengths is fixed: it is the saved index of the length parameter.
local platformLengthValues = {160, 240, 320, 40, 80, 120}
local stepIncrement = 5.0

local function makeParams(firstLevelVehicle)
	local params = {
		makeCargoModeParam(),
		{ key = "trackType", name = _("Track Type"), defaultIndex = 2,
		  tooltips = {_("Simple"), _("Standard")},
		  values = {"::/infrastructure/track/simple/simple.tga", "::/infrastructure/track/standard/standard.tga"},
		  displayMode = "Horizontal", uiType = "IconButton", yearFrom = 1930, yearTo = 1980, group = "hubGeneral", postConstructionModifiable = true, checkEnabledScript = checkScript("checkTrackTypeLegacyFn") },
		{ key = "trackType", name = _("Track Type"), defaultIndex = 2,
		  tooltips = {_("Simple"), _("Standard"), _("High-Speed")},
		  values = {"::/infrastructure/track/simple/simple.tga", "::/infrastructure/track/standard/standard.tga", "::/infrastructure/track/high_speed/high_speed.tga"},
		  displayMode = "Horizontal", uiType = "IconButton", yearFrom = 1980, yearTo = 0, group = "hubGeneral", postConstructionModifiable = true, checkEnabledScript = checkScript("checkTrackTypeModernFn") },
		{ key = "catenary", name = _("Catenary"), values = {_("No"), _("Yes")}, defaultIndex = 2, group = "hubGeneral", postConstructionModifiable = true, checkEnabledScript = checkScript("checkCatenaryEnabledFn") },
	}
	for level = 1, maxLevels do
		params[#params + 1] = makeLevelTitleParam(level)
		params[#params + 1] = makeLevelVehicleParam(level, level == 1 and firstLevelVehicle or defaultVehicleIndex)
		params[#params + 1] = makeLevelAngleParam(level, stepIncrement)
		params[#params + 1] = makeLevelLengthParam(level, platformLengthValues, false)
		params[#params + 1] = makeLevelLengthParam(level, platformLengthValues, true)
		params[#params + 1] = makeLevelLockParam(level)
	end
	params[#params + 1] = makePlacementMarkerParam()
	params[#params + 1] = makeStationSeedParam()
	return params
end

local function makeConstructionTemplates(menuCategory)
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
				icon = "underground_hub.tga",
				previewIcon = "underground_hub_preview@2x.tga",
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
						category = menuCategory,
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


-- options.menuCategory: the menu that lists the station. options.firstLevelVehicle: the vehicle
-- that level 1 starts with, one of hub.vehicle.
function hub.construction(options)
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
	params = makeParams(options.firstLevelVehicle),
	updateScript = {
		fileName = "kacsa_underground_hub::/stations/street/underground_freight/underground_freight.script@updateFn",
		params = {
			platformLengths = platformLengthValues,
			stepIncrement = stepIncrement
		}
	},
	createTemplateScript = {
		fileName = "station.script@createTemplateFn",
		params = {}
	},
	constructionTemplates = makeConstructionTemplates(options.menuCategory),
}
end

return hub
