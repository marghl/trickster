local script = debug.getinfo(1, "S").source:sub(2)
local root = script:match("^(.*)/tests/[^/]+$") or "."

math.randomseed(12345)

local storage_fields = {}
local world = {}
local metas = {}
local players = {}
local logs = {}
local sounds_played = 0
local function pos_key(pos) return pos.x .. ":" .. pos.y .. ":" .. pos.z end

local function serialize(value)
	local kind = type(value)
	if kind == "nil" then return "nil" end
	if kind == "number" or kind == "boolean" then return tostring(value) end
	if kind == "string" then return string.format("%q", value) end
	assert(kind == "table", "cannot serialize " .. kind)
	local parts = {"{"}
	for key, item in pairs(value) do
		parts[#parts + 1] = "[" .. serialize(key) .. "]=" .. serialize(item) .. ","
	end
	parts[#parts + 1] = "}"
	return table.concat(parts)
end

local function deserialize(text)
	if text == "" or text == nil then return nil end
	local loader = loadstring or load
	local chunk = assert(loader("return " .. text))
	return chunk()
end

local Stack = {}
Stack.__index = Stack
local function make_stack(value)
	local data
	if getmetatable(value) == Stack then
		data = {name = value.name, count = value.count, wear = value.wear, metadata = value.metadata}
	elseif type(value) == "table" then
		data = {
			name = value.name or "",
			count = tonumber(value.count) or ((value.name and value.name ~= "") and 1 or 0),
			wear = tonumber(value.wear) or 0,
			metadata = value.metadata or "",
		}
	elseif type(value) == "string" then
		local name, count = value:match("^(%S+)%s*(%d*)$")
		data = {name = name or "", count = tonumber(count) or ((name and name ~= "") and 1 or 0), wear = 0, metadata = ""}
	else
		data = {name = "", count = 0, wear = 0, metadata = ""}
	end
	return setmetatable(data, Stack)
end
function Stack:is_empty() return self.name == "" or self.count <= 0 end
function Stack:get_count() return self.count end
function Stack:to_table()
	if self:is_empty() then return nil end
	return {name = self.name, count = self.count, wear = self.wear, metadata = self.metadata}
end
function Stack:to_string()
	if self:is_empty() then return "" end
	return table.concat({self.name, self.count, self.wear, self.metadata}, "|")
end
ItemStack = make_stack

local function new_inventory(size)
	local lists = {main = {}}
	for index = 1, size or 8 do lists.main[index] = make_stack() end
	local inventory = {}
	function inventory:get_size(list) return lists[list] and #lists[list] or 0 end
	function inventory:get_stack(list, index) return make_stack(lists[list][index]) end
	function inventory:set_stack(list, index, stack) lists[list][index] = make_stack(stack) end
	function inventory:_list(list) return lists[list] end
	return inventory
end

vector = {
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
}

local storage = {
	get_string = function(_, key) return storage_fields[key] or "" end,
	set_string = function(_, key, value) storage_fields[key] = value end,
}

minetest = {
	settings = {
		get = function() return nil end,
		get_bool = function(_, _, fallback) return fallback end,
	},
	registered_nodes = {
		["air"] = {},
		["default:stone"] = {},
		["default:ore"] = {},
		["default:chest"] = {},
		["pipeworks:tube"] = {groups = {tube = 1}},
	},
	get_mod_storage = function() return storage end,
	serialize = serialize,
	deserialize = deserialize,
	log = function(level, message) logs[#logs + 1] = level .. ":" .. message end,
	get_player_by_name = function(name) return players[name] end,
	get_node_or_nil = function(pos) return world[pos_key(pos)] end,
	swap_node = function(pos, node)
		world[pos_key(pos)] = {name = node.name, param1 = node.param1 or 0, param2 = node.param2 or 0}
	end,
	is_protected = function(pos) return pos.x == 99 end,
	get_meta = function(pos)
		local key = pos_key(pos)
		if not metas[key] then
			local inventory = new_inventory(8)
			metas[key] = {
				get_inventory = function() return inventory end,
				to_table = function() return {fields = {}, inventory = {}} end,
			}
		end
		return metas[key]
	end,
	get_item_group = function(name, group)
		local def = minetest.registered_nodes[name]
		return def and def.groups and def.groups[group] or 0
	end,
	sound_play = function() sounds_played = sounds_played + 1 return 1 end,
}

fakelib = {
	create_player = function(options)
		return {
			is_fake_player = true,
			is_player = function() return true end,
			get_player_name = function() return options.name end,
			get_pos = function() return options.position end,
		}
	end,
}

local function new_player(name, pos)
	local inventory = new_inventory(8)
	local player = {
		is_player = function() return true end,
		get_player_name = function() return name end,
		get_pos = function() return {x = pos.x, y = pos.y, z = pos.z} end,
		get_look_dir = function() return {x = 0, y = 0, z = 1} end,
		get_inventory = function() return inventory end,
		get_wield_list = function() return "main" end,
		get_wield_index = function() return 1 end,
	}
	players[name] = player
	return player, inventory
end

trickster = {modname = "trickster", modpath = root}
local modules = {
	"config", "util", "log", "registry", "state", "safety", "transactions",
	"vault", "inventory", "effects", "plans", "director",
}
for _, module in ipairs(modules) do
	dofile(root .. "/framework/" .. module .. ".lua")
end
trickster.transactions.recover_all()

local player, player_inventory = new_player("tester", {x = 0, y = -1000, z = 0})
player_inventory:set_stack("main", 2, {name = "default:pick", count = 1})

trickster.register_sound_profile("hard_footstep", {
	sound = "default_hard_footstep", max_gain = 0.35, max_distance = 12,
})
dofile(root .. "/personas/underground_01/persona.lua")
dofile(root .. "/personas/underground_01/interactions.lua")
assert(trickster.get_persona("underground_01").traits.curiosity == 0.75)
assert(trickster.director.depth_factor(-500, -500, -2500) == 0)
assert(trickster.director.depth_factor(-1500, -500, -2500) == 0.5)
assert(trickster.director.depth_factor(-2500, -500, -2500) == 1)
assert(trickster.director.stay_factor(120, 120, 720) == 0)
assert(trickster.director.stay_factor(420, 120, 720) == 0.5)
local sound_plan = trickster.get_interaction("underground_01:stray_sound").build_plan({
	player_name = "tester",
	position = {x = 0, y = -1000, z = 0},
	look_direction = {x = 0, y = 0, z = 1},
})
assert(sound_plan.effects[1].type == "sound")
assert(sound_plan.effects[1].request.pos.z < 0, "sound must be behind the player")
sound_plan.persona_id = "underground_01"
assert(trickster.plans.submit(sound_plan))
assert(trickster.plans.execute(assert(trickster.plans.pop())))
assert(sounds_played == 1, "acoustic interaction must use the sound effect")
trickster.state._reset_for_tests()

assert(trickster.state.relationship("tester", "underground_01") == 0)
assert(trickster.state.change_relationship("tester", "underground_01", -140) == -100)
assert(trickster.state.change_relationship("tester", "underground_01", 250) == 100)

local source = {x = 2, y = -1000, z = 0}
local target = {x = 3, y = -1000, z = 0}
world[pos_key(source)] = {name = "default:ore", param1 = 0, param2 = 0}
world[pos_key(target)] = {name = "default:stone", param1 = 0, param2 = 0}
for _, offset in ipairs({
	{x=1,y=0,z=0},{x=-1,y=0,z=0},{x=0,y=1,z=0},
	{x=0,y=-1,z=0},{x=0,y=0,z=1},{x=0,y=0,z=-1},
}) do
	local p = vector.add({x = 6, y = -1000, z = 0}, offset)
	world[pos_key(p)] = {name = "air", param1 = 0, param2 = 0}
end

trickster.register_node_relocation_profile({
	node = "default:ore",
	max_distance = 2,
	target_allowed = function(node) return node.name == "default:stone" end,
	source_replacement = function(target_node) return target_node end,
})

trickster.register_interaction({
	id = "move_ore",
	persona_id = "underground_01",
	build_plan = function(context)
		return {
			player_name = context.player_name,
			intent = "confuse",
			tier = 0,
			cooldowns = {player = 60, persona = 120},
			effects = {{
				type = "node_relocate",
				request = {source = source, target = target},
			}},
		}
	end,
})

local plan_id = assert(trickster.request_interaction("underground_01:move_ore", {player_name = "tester"}))
assert(type(plan_id) == "string")
local plan = assert(trickster.plans.pop())
assert(trickster.plans.execute(plan))
assert(world[pos_key(source)].name == "default:stone")
assert(world[pos_key(target)].name == "default:ore")
assert(next(trickster.transactions._pending()) == nil)
assert(trickster.state.cooldown_reason("tester", "underground_01") == "player_cooldown")

trickster.state._reset_for_tests()
local swap_plan = {
	persona_id = "underground_01",
	player_name = "tester",
	effects = {{type = "player_inventory_swap", request = {source_index = 2, target_index = 5}}},
}
assert(trickster.plans.submit(swap_plan))
assert(trickster.plans.execute(assert(trickster.plans.pop())))
assert(player_inventory:get_stack("main", 2):is_empty())
assert(player_inventory:get_stack("main", 5):to_table().name == "default:pick")

trickster.register_inventory_profile({
	node = "default:chest",
	lists = {main = {put = true, take = true, move = true}},
	reject_automation = true,
})
trickster.block_inventory_neighbor_group("tube")
local chest = {x = 6, y = -1000, z = 0}
world[pos_key(chest)] = {name = "default:chest", param1 = 0, param2 = 0}
local access = assert(trickster.inventory.prepare_node_access({
	player_name = "tester", pos = chest, list = "main",
}, "put"))
assert(access.actor.is_fake_player)
world[pos_key({x = 7, y = -1000, z = 0})] = {name = "pipeworks:tube", param1 = 0, param2 = 0}
local denied, reason = trickster.inventory.prepare_node_access({
	player_name = "tester", pos = chest, list = "main",
}, "take")
assert(denied == nil and reason == "blocked_neighbor")

local contract = trickster.vault.create({
	player_name = "tester",
	persona_id = "underground_01",
	stack = {name = "default:tree", count = 4},
	return_kind = "transformed",
	purpose = "construct_tree",
	recipe = {result = "tree_01"},
	fallback = {kind = "return_to_source"},
})
assert(trickster.vault.mark_secured(contract))
assert(trickster.vault.fulfill(contract, {structure = "tree_01"}))
assert(trickster.vault.get(contract).state == "fulfilled")

print("trickster framework tests passed")
