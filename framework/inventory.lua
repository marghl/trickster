local T = trickster
local U = T.util
local S = T.safety
local I = {}
T.inventory = I

local profiles = {}
local blocked_nodes = {}
local blocked_groups = {}
local neighbors = {
	{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0},
	{x = 0, y = 1, z = 0}, {x = 0, y = -1, z = 0},
	{x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1},
}

local function valid_rules(lists)
	assert(type(lists) == "table", "inventory profile requires lists")
	local result = {}
	for listname, operations in pairs(lists) do
		assert(type(listname) == "string" and listname ~= "", "invalid inventory list")
		assert(type(operations) == "table", "inventory list operations required")
		result[listname] = {
			put = operations.put == true,
			take = operations.take == true,
			move = operations.move == true,
		}
	end
	return result
end

-- Integration-owned hook. A persona cannot make an unknown inventory safe by
-- naming it in a plan; the profile must exist before that plan is prepared.
function T.register_inventory_profile(def)
	assert(type(def) == "table", "inventory profile required")
	assert(type(def.node) == "string" and def.node:find(":", 1, true), "exact node name required")
	assert(not profiles[def.node], "inventory profile already exists: " .. def.node)
	profiles[def.node] = {
		node = def.node,
		lists = valid_rules(def.lists),
		max_stacks = math.min(T.config.max_inventory_stacks,
			math.max(1, math.floor(tonumber(def.max_stacks) or 1))),
		max_distance = math.max(1, tonumber(def.max_distance) or 8),
		reject_automation = def.reject_automation ~= false,
		validate = def.validate,
	}
end

function T.block_inventory_neighbor(name)
	assert(type(name) == "string" and name:find(":", 1, true), "exact node name required")
	blocked_nodes[name] = true
end

function T.block_inventory_neighbor_group(group)
	assert(U.valid_id(group), "invalid group name")
	blocked_groups[group] = true
end

local function is_blocked_neighbor(node_name)
	if blocked_nodes[node_name] then return true end
	for group in pairs(blocked_groups) do
		if minetest.get_item_group(node_name, group) > 0 then return true end
	end
	return false
end

function I.has_blocked_neighbor(pos)
	for _, offset in ipairs(neighbors) do
		local neighbor = vector.add(pos, offset)
		local node, reason = S.loaded_node(neighbor)
		if not node then return true, reason end
		if is_blocked_neighbor(node.name) then return true, "blocked_neighbor" end
	end
	return false
end

function I.prepare_node_access(request, operation)
	if type(request) ~= "table" or not U.valid_pos(request.pos) then
		return nil, "invalid_inventory_request"
	end
	local player, reason = S.connected_player(request.player_name)
	if not player then return nil, reason end
	local pos = U.node_pos(request.pos)
	local node
	node, reason = S.loaded_node(pos)
	if not node then return nil, reason end
	local profile = profiles[node.name]
	if not profile then return nil, "inventory_not_whitelisted" end
	local rules = profile.lists[request.list]
	if not rules or not rules[operation] then return nil, "inventory_operation_not_allowed" end
	local allowed
	allowed, reason = S.player_may_access(pos, request.player_name)
	if not allowed then return nil, reason end
	allowed, reason = S.near_player(player, pos, profile.max_distance)
	if not allowed then return nil, reason end
	if profile.reject_automation then
		local blocked
		blocked, reason = I.has_blocked_neighbor(pos)
		if blocked then return nil, reason end
	end
	local meta = minetest.get_meta(pos)
	local inventory = meta and meta:get_inventory()
	if not inventory or inventory:get_size(request.list) <= 0 then
		return nil, "inventory_list_missing"
	end
	local actor
	actor, reason = S.make_actor(player)
	if not actor then return nil, reason end
	if type(profile.validate) == "function" then
		local ok, accepted = pcall(profile.validate, {
			pos = U.copy_pos(pos), node = node, player = player, actor = actor,
			inventory = inventory, operation = operation, request = U.deep_copy(request),
		})
		if not ok then return nil, "profile_error" end
		if accepted ~= true then return nil, "profile_denied" end
	end
	return {
		pos = pos,
		node = U.deep_copy(node),
		profile = profile,
		inventory = inventory,
		actor = actor,
		player = player,
		list = request.list,
	}
end

function I.callback_limit(access, operation, index, stack, destination)
	local def = minetest.registered_nodes[access.node.name] or {}
	local callback
	local ok, result
	if operation == "put" then
		callback = def.allow_metadata_inventory_put
		if not callback then return stack:get_count() end
		ok, result = pcall(callback, access.pos, access.list, index, ItemStack(stack), access.actor)
	elseif operation == "take" then
		callback = def.allow_metadata_inventory_take
		if not callback then return stack:get_count() end
		ok, result = pcall(callback, access.pos, access.list, index, ItemStack(stack), access.actor)
	else
		callback = def.allow_metadata_inventory_move
		if not callback then return stack:get_count() end
		ok, result = pcall(callback, access.pos, access.list, index,
			destination.list, destination.index, stack:get_count(), access.actor)
	end
	if not ok then return 0, "callback_error" end
	return math.max(0, math.floor(tonumber(result) or 0))
end

function I.notify(access, operation, index, stack, destination)
	local def = minetest.registered_nodes[access.node.name] or {}
	local callback
	local ok, err
	if operation == "put" then
		callback = def.on_metadata_inventory_put
		if callback then ok, err = pcall(callback, access.pos, access.list, index, ItemStack(stack), access.actor) end
	elseif operation == "take" then
		callback = def.on_metadata_inventory_take
		if callback then ok, err = pcall(callback, access.pos, access.list, index, ItemStack(stack), access.actor) end
	else
		callback = def.on_metadata_inventory_move
		if callback then ok, err = pcall(callback, access.pos, access.list, index,
			destination.list, destination.index, stack:get_count(), access.actor) end
	end
	if callback and not ok then
		T.log("error", "inventory notification failed: " .. tostring(err))
		return false, "notification_error"
	end
	return true
end

function I.profile(node_name)
	return profiles[node_name]
end

