local T = trickster
local U = {}
T.util = U

function U.clamp(value, low, high)
	return math.max(low, math.min(high, value))
end

function U.copy_pos(pos)
	return {x = pos.x, y = pos.y, z = pos.z}
end

function U.valid_pos(pos)
	return type(pos) == "table"
		and type(pos.x) == "number"
		and type(pos.y) == "number"
		and type(pos.z) == "number"
		and pos.x == pos.x and pos.y == pos.y and pos.z == pos.z
end

function U.node_pos(pos)
	return {
		x = math.floor(pos.x + 0.5),
		y = math.floor(pos.y + 0.5),
		z = math.floor(pos.z + 0.5),
	}
end

function U.valid_id(value)
	return type(value) == "string" and value:match("^[a-z][a-z0-9_]*$") ~= nil
end

function U.shallow_copy(source)
	local copy = {}
	for key, value in pairs(source or {}) do copy[key] = value end
	return copy
end

function U.deep_copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	if seen[value] then error("cyclic table cannot be copied", 2) end
	seen[value] = true
	local copy = {}
	for key, item in pairs(value) do
		copy[U.deep_copy(key, seen)] = U.deep_copy(item, seen)
	end
	seen[value] = nil
	return copy
end

function U.table_size(value)
	local count = 0
	for _ in pairs(value or {}) do count = count + 1 end
	return count
end

function U.now()
	return os.time()
end

function U.random_id(prefix)
	return string.format("%s_%d_%06d", prefix, U.now(), math.random(0, 999999))
end

function U.call(callback, ...)
	if type(callback) ~= "function" then return true end
	local ok, result = pcall(callback, ...)
	if not ok then return false, "callback_error", result end
	return true, result
end

function U.same_node(a, b)
	return a and b and a.name == b.name
		and (a.param1 or 0) == (b.param1 or 0)
		and (a.param2 or 0) == (b.param2 or 0)
end

