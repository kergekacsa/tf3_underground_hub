-- The game puts the group id of a parameter on the divider above its group as a class.
-- Class names hold only letters, digits and dashes.
local ssu = require "::/gui/main/stylesheetutil.lua"

local DIVIDER_GROUPS = { "hubStyle", "hubLevel1", "hubLevel2", "hubLevel3", "hubLevel4" }
local DIVIDER_WIDTH = 280
local DIVIDER_THICKNESS = 4
local LIST_SPACING = 10
local SLIDER_WIDTH = 187
local SETTINGS_MAX_HEIGHT = 700

function data()
	local result = { }
	local a = ssu.makeAdder(result)
	local colorDefault = api.gui.genericRep.get(api.gui.genericRep.find("::/gui/main/default_colors.gres")).data

	local dividers = { }
	for __, group in ipairs(DIVIDER_GROUPS) do
		dividers[#dividers + 1] = "R::ConstructionParamsContent ImageView!param-group-separator!" .. group
	end

	-- A yellow fill under a yellow tint: the line is yellow whether the game paints the fill or only the image.
	a(table.concat(dividers, ",\n"), {
		size = { DIVIDER_WIDTH, DIVIDER_THICKNESS },
		color = colorDefault.Warning,
		backgroundColor1 = colorDefault.Warning,
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
