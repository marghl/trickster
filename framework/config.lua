local T = trickster
local prefix = T.modname .. "."

local function number(name, fallback, minimum, maximum)
	local value = tonumber(minetest.settings:get(prefix .. name)) or fallback
	if minimum then value = math.max(minimum, value) end
	if maximum then value = math.min(maximum, value) end
	return value
end

T.config = {
	enabled = minetest.settings:get_bool(prefix .. "enabled", true),
	diagnostic_log = minetest.settings:get_bool(prefix .. "diagnostic_log", true),
	dry_run = minetest.settings:get_bool(prefix .. "dry_run", false),
	runtime_interval = number("runtime_interval", 1, 0.2, 60),
	director_interval = number("director_interval", 1, 0.5, 10),
	max_queue = math.floor(number("max_queue", 64, 1, 1000)),
	max_effects_per_plan = math.floor(number("max_effects_per_plan", 8, 1, 32)),
	max_node_scan = math.floor(number("max_node_scan", 128, 1, 4096)),
	max_inventory_stacks = math.floor(number("max_inventory_stacks", 4, 1, 99)),
	state_flush_interval = number("state_flush_interval", 60, 10, 3600),
	transaction_limit = math.floor(number("transaction_limit", 128, 1, 1000)),
}
