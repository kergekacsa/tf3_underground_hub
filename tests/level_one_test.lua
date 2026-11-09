local support = require("support")

local SCRIPT = "content/stations/rail/underground_hub/station.script.lua"
local GOLDEN = "tests/golden/level_one.txt"
local CAPTURE = { platformLengths = { 160, 240, 320, 40, 80, 120 }, stepIncrement = 5.0 }

local CASES = {
	{ name = "default", params = {} },
	{ name = "longest, rotated, simple track", params = { level1Length = 3, level1Angle = 19, trackType = 1 } },
	{ name = "shortest, no catenary, concrete bed", params = { level1Length = 4, catenary = 1, ballast = 2 } },
	{ name = "high speed, old tunnel, japanese", params = { trackType = 3, tunnelType = 2, interiorStyle = 2, level1Angle = 10 } },
}

local function render()
	local data = support.loadScript(SCRIPT)
	local out = {}
	for _, case in ipairs(CASES) do
		out[#out + 1] = "== " .. case.name .. "\n" .. support.dump(data.updateFn(CAPTURE, case.params)) .. "\n"
	end
	return table.concat(out)
end

if arg[1] == "--update" then
	support.writeFile(GOLDEN, render())
	print("golden written: " .. GOLDEN)
	os.exit(0)
end

local actual, expected = render(), support.readFile(GOLDEN)
if actual ~= expected then
	support.writeFile("tests/.build/level_one_actual.txt", actual)
	print("FAIL level one differs from golden; actual written to tests/.build/level_one_actual.txt")
	os.exit(1)
end
print("ok level one matches golden (" .. #CASES .. " cases)")
