-- The game puts the group id of a parameter on the group block and on the divider above it as a class.
-- Class names hold only letters, digits and dashes.
local ssu = require "::/gui/main/stylesheetutil.lua"

local TITLE_GROUPS = { "hubTitle1", "hubTitle2", "hubTitle3", "hubTitle4" }
local LEVEL_GROUPS = { "hubLevel1", "hubLevel2", "hubLevel3", "hubLevel4" }
local NOTE_GROUP = "hubLock"
local DIVIDER_WIDTH = 280
local DIVIDER_THICKNESS = 4
local LIST_SPACING = 10
local SLIDER_WIDTH = 187
local SETTINGS_MAX_HEIGHT = 700
local NOTE_WIDTH = 280

local function selectors(groups, pattern)
	local result = { }
	for __, group in ipairs(groups) do
		result[#result + 1] = pattern:gsub("GROUP", group)
	end
	return table.concat(result, ",\n")
end

local function join(...)
	local result = { }
	for __, list in ipairs({ ... }) do
		for __, group in ipairs(list) do result[#result + 1] = group end
	end
	return result
end

function data()
	local result = { }
	local a = ssu.makeAdder(result)
	local colorDefault = api.gui.genericRep.get(api.gui.genericRep.find("::/gui/main/default_colors.gres")).data
	local textGroups = join(TITLE_GROUPS, { NOTE_GROUP })

	-- A divider above the title of each level and above the note of a locked level.
	-- A yellow fill under a yellow tint: the line is yellow whether the game paints the fill or only the image.
	a(selectors(textGroups, "R::ConstructionParamsContent ImageView!param-group-separator!GROUP"), {
		size = { DIVIDER_WIDTH, DIVIDER_THICKNESS },
		color = colorDefault.Warning,
		backgroundColor1 = colorDefault.Warning,
	})

	-- The controls of a level follow their title, so the block of the controls gets no divider.
	a(selectors(LEVEL_GROUPS, "R::ConstructionParamsContent ImageView!param-group-separator!GROUP"), {
		visibility = "none",
	})

	-- A title and a note are one-value buttons that look like plain text.
	local plain = { }
	for __, state in ipairs({ "checked", "unchecked", "checked:disabled", "unchecked:disabled", "checked:hover", "unchecked:hover" }) do
		plain[#plain + 1] = selectors(textGroups, "R::ConstructionParamsContent R::Component!param-group!GROUP ToggleButton!" .. state)
	end
	a(table.concat(plain, ",\n"), {
		backgroundColor1 = colorDefault.Invisible,
		borderColor = colorDefault.Invisible,
		transitionPropertyDuration = {},
	})

	a(selectors(TITLE_GROUPS, "R::ConstructionParamsContent R::Component!param-group!GROUP TextView"), {
		fontWeight = "Bold",
		color = colorDefault.NeutralLightest,
	})

	a("R::ConstructionParamsContent R::Component!param-group!" .. NOTE_GROUP .. " TextView", {
		color = colorDefault.Error,
		textAutoWrap = true,
		maxSize = { NOTE_WIDTH, -1 },
	})

	-- The list holds the group blocks and the dividers in a vertical layout. Its spacing puts room around each divider.
	a("Window!construct-settings !construction-menu-params-content > BoxLayout", {
		innerSpacing = { LIST_SPACING, LIST_SPACING },
	})

	a("Window!construct-settings!no-close-button", {
		maxSize = { 400, SETTINGS_MAX_HEIGHT },
	})

	-- A slider that cannot grow leaves no free space between itself and its value box.
	a("Window!construct-settings !construction-menu-params-content Slider!horizontal", {
		size = { SLIDER_WIDTH, -1 },
		minSize = { SLIDER_WIDTH, -1 },
		maxSize = { SLIDER_WIDTH, -1 },
		gravity = { -1, 0.5 },
	})

	log.message("[hub] parameter window style added")
	return result
end
