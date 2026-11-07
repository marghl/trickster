local T = trickster
local U = T.util
local S = T.safety
local X = T.transactions

local node_profiles = {}
local sound_profiles = {}

local function stack_table(stack)
	return ItemStack(stack):to_table()
end

local function inventory_stack_matches(inventory, listname, index, expected)
	local current = inventory:get_stack(listname, index)
	return current:to_string() == ItemStack(expected):to_string()
end

function T.register_sound_profile(id, def)
	assert(U.valid_id(id), "invalid sound profile id")
	assert(type(def) == "table" and type(def.sound) == "string" and def.sound ~= "",
		"sound profile requires sound")
	assert(not sound_profiles[id], "sound profile already exists: " .. id)
	sound_profiles[id] = {
		sound = def.sound,
		max_gain = math.max(0, math.min(tonumber(def.max_gain) or 1, 2)),
		max_distance = math.max(1, math.min(tonumber(def.max_distance) or 16, 64)),
	}
end

function T.has_sound_profile(id)
	return sound_profiles[id] ~= nil
end

function T.register_node_relocation_profile(def)
	assert(type(def) == "table", "node relocation profile required")
	assert(type(def.node) == "string" and def.node:find(":", 1, true), "exact moving node required")
	assert(not node_profiles[def.node], "node relocation profile already exists: " .. def.node)
	assert(type(def.source_replacement) == "function", "source_replacement function required")
	assert(type(def.target_allowed) == "function", "target_allowed function required")
	node_profiles[def.node] = {
		node = def.node,
		max_distance = math.max(1, math.min(tonumber(def.max_distance) or 4, 16)),
		source_replacement = def.source_replacement,
		target_allowed = def.target_allowed,
		allow_metadata = def.allow_metadata == true,
	}
end

local function metadata_empty(pos)
	local meta = minetest.get_meta(pos)
	if not meta or type(meta.to_table) ~= "function" then return true end
	local data = meta:to_table() or {}
	if next(data.fields or {}) then return false end
	for _, list in pairs(data.inventory or {}) do
		if next(list) then return false end
	end
	return true
end

local sound_effect = {}

function sound_effect.prepare(request)
	if type(request) ~= "table" then return nil, "invalid_request" end
	local player, reason = S.connected_player(request.player_name)
	if not player then return nil, reason end
	local profile = sound_profiles[request.profile]
	if not profile then return nil, "sound_not_whitelisted" end
	local pos = request.pos or player:get_pos()
	if not U.valid_pos(pos) then return nil, "invalid_position" end
	local near
	near, reason = S.near_player(player, pos, profile.max_distance)
	if not near then return nil, reason end
	return {
		player_name = request.player_name,
		profile = request.profile,
		pos = U.copy_pos(pos),
		gain = math.max(0, math.min(tonumber(request.gain) or 1, profile.max_gain)),
		pitch = math.max(0.5, math.min(tonumber(request.pitch) or 1, 2)),
	}
end

function sound_effect.apply(prepared)
	local profile = sound_profiles[prepared.profile]
	local player, reason = S.connected_player(prepared.player_name)
	if not profile then return false, "sound_not_whitelisted" end
	if not player then return false, reason end
	local near
	near, reason = S.near_player(player, prepared.pos, profile.max_distance)
	if not near then return false, reason end
	minetest.sound_play(profile.sound, {
		pos = prepared.pos,
		to_player = prepared.player_name,
		gain = prepared.gain,
		max_hear_distance = profile.max_distance,
		pitch = prepared.pitch,
	}, true)
	return true
end

function sound_effect.recover()
	return true, "ephemeral_effect_closed"
end

local node_effect = {}

function node_effect.prepare(request)
	if type(request) ~= "table" or not U.valid_pos(request.source) or not U.valid_pos(request.target) then
		return nil, "invalid_request"
	end
	local player, reason = S.connected_player(request.player_name)
	if not player then return nil, reason end
	local source = U.node_pos(request.source)
	local target = U.node_pos(request.target)
	local source_node
	source_node, reason = S.loaded_node(source)
	if not source_node then return nil, reason end
	local target_node
	target_node, reason = S.loaded_node(target)
	if not target_node then return nil, reason end
	local profile = node_profiles[source_node.name]
	if not profile then return nil, "node_not_whitelisted" end
	local dx, dy, dz = target.x - source.x, target.y - source.y, target.z - source.z
	if dx * dx + dy * dy + dz * dz > profile.max_distance * profile.max_distance then
		return nil, "target_too_far"
	end
	local allowed
	allowed, reason = S.player_may_access(source, request.player_name)
	if not allowed then return nil, reason end
	allowed, reason = S.player_may_access(target, request.player_name)
	if not allowed then return nil, reason end
	if not profile.allow_metadata and (not metadata_empty(source) or not metadata_empty(target)) then
		return nil, "metadata_not_allowed"
	end
	local ok, target_allowed = pcall(profile.target_allowed, target_node, target, source_node, source)
	if not ok or target_allowed ~= true then return nil, ok and "target_denied" or "profile_error" end
	local replacement_ok, source_replacement = pcall(profile.source_replacement,
		target_node, target, source_node, source)
	if not replacement_ok or type(source_replacement) ~= "table" or type(source_replacement.name) ~= "string" then
		return nil, "invalid_source_replacement"
	end
	if not minetest.registered_nodes[source_replacement.name] then
		return nil, "replacement_not_registered"
	end
	return {
		player_name = request.player_name,
		source = source,
		target = target,
		source_before = U.deep_copy(source_node),
		target_before = U.deep_copy(target_node),
		source_after = U.deep_copy(source_replacement),
		target_after = U.deep_copy(source_node),
	}
end

local function node_recheck(prepared)
	local source, reason = S.loaded_node(prepared.source)
	if not source then return false, reason end
	local target
	target, reason = S.loaded_node(prepared.target)
	if not target then return false, reason end
	if not U.same_node(source, prepared.source_before) or not U.same_node(target, prepared.target_before) then
		return false, "world_changed"
	end
	local allowed
	allowed, reason = S.player_may_access(prepared.source, prepared.player_name)
	if not allowed then return false, reason end
	allowed, reason = S.player_may_access(prepared.target, prepared.player_name)
	if not allowed then return false, reason end
	return true
end

function node_effect.apply(prepared, transaction_id)
	local ok, reason = node_recheck(prepared)
	if not ok then return false, reason end
	minetest.swap_node(prepared.target, prepared.target_after)
	X.set_stage(transaction_id, "target_written")
	local current = minetest.get_node_or_nil(prepared.source)
	if not U.same_node(current, prepared.source_before) then
		minetest.swap_node(prepared.target, prepared.target_before)
		X.set_stage(transaction_id, "rolled_back")
		return false, "source_changed"
	end
	minetest.swap_node(prepared.source, prepared.source_after)
	X.set_stage(transaction_id, "applied")
	return true
end

function node_effect.recover(prepared)
	local source = minetest.get_node_or_nil(prepared.source)
	local target = minetest.get_node_or_nil(prepared.target)
	if not source or not target then return false, "nodes_unloaded" end
	if U.same_node(source, prepared.source_before) and U.same_node(target, prepared.target_before) then
		return true, "rolled_back"
	end
	if U.same_node(source, prepared.source_before) and U.same_node(target, prepared.target_after) then
		minetest.swap_node(prepared.source, prepared.source_after)
		return true, "recovered_commit"
	end
	if U.same_node(source, prepared.source_after) and U.same_node(target, prepared.target_after) then
		return true, "recovered_complete"
	end
	return false, "world_conflict"
end

local player_inventory_effect = {}

function player_inventory_effect.prepare(request)
	if type(request) ~= "table" then return nil, "invalid_request" end
	local player, reason = S.connected_player(request.player_name)
	if not player then return nil, reason end
	local inventory = player:get_inventory()
	local list = request.list or "main"
	if list ~= "main" then return nil, "player_list_not_allowed" end
	local size = inventory:get_size(list)
	local source = math.floor(tonumber(request.source_index) or 0)
	local target = math.floor(tonumber(request.target_index) or 0)
	if source < 1 or target < 1 or source > size or target > size or source == target then
		return nil, "invalid_slot"
	end
	if player:get_wield_list() == list
		and (player:get_wield_index() == source or player:get_wield_index() == target) then
		return nil, "wielded_slot"
	end
	local source_stack = inventory:get_stack(list, source)
	local target_stack = inventory:get_stack(list, target)
	if source_stack:is_empty() then return nil, "empty_source" end
	return {
		player_name = request.player_name,
		list = list,
		source_index = source,
		target_index = target,
		source_before = stack_table(source_stack),
		target_before = stack_table(target_stack),
		source_after = stack_table(target_stack),
		target_after = stack_table(source_stack),
	}
end

function player_inventory_effect.apply(prepared, transaction_id)
	local player, reason = S.connected_player(prepared.player_name)
	if not player then return false, reason end
	local inventory = player:get_inventory()
	if not inventory_stack_matches(inventory, prepared.list, prepared.source_index, prepared.source_before)
		or not inventory_stack_matches(inventory, prepared.list, prepared.target_index, prepared.target_before) then
		return false, "inventory_changed"
	end
	inventory:set_stack(prepared.list, prepared.target_index, ItemStack(prepared.target_after))
	X.set_stage(transaction_id, "target_written")
	if not inventory_stack_matches(inventory, prepared.list, prepared.source_index, prepared.source_before) then
		inventory:set_stack(prepared.list, prepared.target_index, ItemStack(prepared.target_before))
		X.set_stage(transaction_id, "rolled_back")
		return false, "source_changed"
	end
	inventory:set_stack(prepared.list, prepared.source_index, ItemStack(prepared.source_after))
	X.set_stage(transaction_id, "applied")
	return true
end

function player_inventory_effect.recover(prepared)
	local player = minetest.get_player_by_name(prepared.player_name)
	if not player then return false, "player_offline" end
	local inventory = player:get_inventory()
	local source_before = inventory_stack_matches(inventory, prepared.list,
		prepared.source_index, prepared.source_before)
	local target_before = inventory_stack_matches(inventory, prepared.list,
		prepared.target_index, prepared.target_before)
	local source_after = inventory_stack_matches(inventory, prepared.list,
		prepared.source_index, prepared.source_after)
	local target_after = inventory_stack_matches(inventory, prepared.list,
		prepared.target_index, prepared.target_after)
	if source_before and target_before then return true, "rolled_back" end
	if source_before and target_after then
		inventory:set_stack(prepared.list, prepared.source_index, ItemStack(prepared.source_after))
		return true, "recovered_commit"
	end
	if source_after and target_after then return true, "recovered_complete" end
	return false, "inventory_conflict"
end

T._register_core_effect("sound", sound_effect)
T._register_core_effect("node_relocate", node_effect)
T._register_core_effect("player_inventory_swap", player_inventory_effect)

X.register_kind("effect", {
	recover = function(tx)
		local prepared = tx.payload and tx.payload.prepared
		local effect_name = tx.payload and tx.payload.effect
		local handler = T._get_core_effect(effect_name)
		if not handler or not prepared then return false, "invalid_effect_transaction" end
		return handler.recover(prepared, tx.stage)
	end,
})
