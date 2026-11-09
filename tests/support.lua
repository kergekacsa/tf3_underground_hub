local M = {}

local function mulMat(a, b)
	local r = {}
	for col = 0, 3 do
		for row = 1, 4 do
			local s = 0
			for k = 0, 3 do s = s + a[k * 4 + row] * b[col * 4 + k + 1] end
			r[col * 4 + row] = s
		end
	end
	return r
end

local function transl(v) return { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, v[1], v[2], v[3], 1 } end
local function rotZ(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 }
end

local stubs = {
	["::/scripts/vec3.tl"] = { new = function(x, y, z) return { x, y, z } end },
	["::/scripts/mat4.tl"] = {
		transl = transl,
		rotZ = rotZ,
		mul = mulMat,
		rotZTransl = function(a, v) return mulMat(transl(v), rotZ(a)) end,
	},
	["::/scripts/construction/laneutil.lua"] = {
		createLane = function(curves, types, w1, w2, link)
			return { kind = "lane", curves = curves, types = types, w1 = w1, w2 = w2, link = link }
		end,
	},
	["::/scripts/construction/modulesutil.lua"] = {
		addGroundFaces = function(texture, generated, sub) sub.groundTexture = texture end,
	},
	["::/scripts/construction/constructionutil.lua"] = {
		addEdges = function(curves, result, kind, spec, flag, a, b)
			result.edgeLists = result.edgeLists or {}
			result.edgeLists[#result.edgeLists + 1] = { kind = kind, spec = spec, curves = curves, flag = flag, a = a, b = b }
		end,
		addModelsAndGroups = function(params, generated, sub, _, mat)
			sub.models = sub.models or {}
			sub.colliders = sub.colliders or {}
			local ids = {}
			for id in pairs(generated.models or {}) do ids[#ids + 1] = id end
			table.sort(ids)
			for _, id in ipairs(ids) do
				for _, placement in ipairs(generated.models[id]) do
					sub.models[#sub.models + 1] = { id = id, transf = mat and mulMat(mat, placement) or placement }
				end
			end
			local collider = generated.curves and generated.curves.collider
			if collider then sub.colliders[#sub.colliders + 1] = { mat = mat, curves = collider } end
		end,
		addStationCapacities = function(sub) sub.capacities = true end,
	},
}

function M.loadScript(path, extraEnv)
	local env = setmetatable({
		require = function(name) return assert(stubs[name], "no stub for " .. name) end,
	}, { __index = _G })
	for key, value in pairs(extraEnv or {}) do env[key] = value end
	local chunk = assert(loadfile(path, "t", env))
	chunk()
	return env.data()
end

local function dump(value, indent, out)
	local t = type(value)
	if t == "number" then
		out[#out + 1] = string.format("%.4f", value + 0.0)
	elseif t == "table" then
		local keys = {}
		for k in pairs(value) do keys[#keys + 1] = k end
		table.sort(keys, function(x, y)
			if type(x) == type(y) then return x < y end
			return type(x) == "number"
		end)
		out[#out + 1] = "{\n"
		for _, k in ipairs(keys) do
			out[#out + 1] = indent .. "  " .. tostring(k) .. " = "
			dump(value[k], indent .. "  ", out)
			out[#out + 1] = "\n"
		end
		out[#out + 1] = indent .. "}"
	else
		out[#out + 1] = tostring(value)
	end
end

function M.dump(value)
	local out = {}
	dump(value, "", out)
	return table.concat(out)
end

function M.readFile(path)
	local f = assert(io.open(path, "rb"))
	local s = f:read("a")
	f:close()
	return s
end

function M.writeFile(path, text)
	local f = assert(io.open(path, "wb"))
	f:write(text)
	f:close()
end

return M
