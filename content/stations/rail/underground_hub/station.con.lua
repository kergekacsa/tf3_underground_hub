

local function angleValues(stepIncrement)
	local values = {}
	local numSteps = (360.0 / stepIncrement);
	for i=0, numSteps do
		values[#values + 1 ] = tostring(i * stepIncrement)
	end
	return values
end

local function makePlatformOrientationParams(stepIncrement)
	return {
			key = "platformOrientation",
			name = _("Platform Orientation"),
			displayMode = "Sparse",
			values = angleValues(stepIncrement),
			defaultIndex = 1,
			uiType = "Slider"
		}
end

local function makePlatformLengthsValues(platformConfig)
	local result = { }
	
	for i = 1, #platformConfig do
		result[#result + 1] = tostring(platformConfig[i]) .. " m"
	end
	
	return result
end

local function makePlatformLengthParams(platformLengths)
	-- Menu positions map to the original saved values, so existing stations
	-- keep their length when the choices are displayed in ascending order.
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
			key = "platformLength",
			name = _("Platform Length"),
			values = makePlatformLengthsValues(sortedLengths),
			numbers = indices,
			defaultIndex = defaultIndex,
			displayMode = "Sparse",
		}
end

-- Append choices to preserve the saved indices of existing stations.
local platformLengthValues = {160, 240, 320, 40, 80, 120}
local stepIncrement = 5.0

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
					cargo = false,
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
					cargoClassesIncluded = { "PASSENGERS", },
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
						filterCategories = { "passenger", },
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
			cargo = false,
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
			cargoClassesIncluded = { "PASSENGERS", },
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
	params = {
		{ key = "catenary", name = _("Catenary"), values = {_("No"), _("Yes")}, defaultIndex = 2 },
        { key = "layout", name = _("HUB_LAYOUT_LABEL"), values = {_("HUB_LAYOUT_1"), _("HUB_LAYOUT_2"), _("HUB_LAYOUT_3"), _("HUB_LAYOUT_4"), _("HUB_LAYOUT_5"), _("HUB_LAYOUT_6"), _("HUB_LAYOUT_7")}, defaultIndex = 1, uiType = "ComboBox" },
        { key = "tunnelType", name = _("HUB_TUNNEL_LABEL"), values = {_("HUB_TUNNEL_CONCRETE"), _("HUB_TUNNEL_OLD")}, defaultIndex = 1 },
        { key = "ballast", name = _("HUB_BALLAST_LABEL"), values = {_("HUB_BALLAST_ON"), _("HUB_BALLAST_OFF")}, defaultIndex = 1 },
        { key = "interiorStyle", name = _("HUB_STYLE_LABEL"), values = {_("HUB_STYLE_ORIGINAL"), _("HUB_STYLE_JAPANESE")}, defaultIndex = 1 },
        { key = "trackType", name = _("Track Type"), defaultIndex = 2,
          tooltips = {_("Simple"), _("Standard")},
          values = {"::/infrastructure/track/simple/simple.tga", "::/infrastructure/track/standard/standard.tga"},
          displayMode = "Horizontal", uiType = "IconButton", yearFrom = 1930, yearTo = 1980 },
        { key = "trackType", name = _("Track Type"), defaultIndex = 2,
          tooltips = {_("Simple"), _("Standard"), _("High-Speed")},
          values = {"::/infrastructure/track/simple/simple.tga", "::/infrastructure/track/standard/standard.tga", "::/infrastructure/track/high_speed/high_speed.tga"},
          displayMode = "Horizontal", uiType = "IconButton", yearFrom = 1980, yearTo = 0 },
		makePlatformOrientationParams(stepIncrement),
		makePlatformLengthParams(platformLengthValues),
	},
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
