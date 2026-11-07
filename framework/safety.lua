local T = trickster
local U = T.util
local S = {}
T.safety = S

function S.connected_player(name)
	if type(name) ~= "string" or name == "" then return nil, "invalid_player" end
	local player = minetest.get_player_by_name(name)
	if not player or not player:is_player() then return nil, "player_offline" end
	return player
end

function S.loaded_node(pos)
	if not U.valid_pos(pos) then return nil, "invalid_position" end
	local node = minetest.get_node_or_nil(pos)
	if not node or node.name == "ignore" then return nil, "node_unloaded" end
	return node
end

function S.player_may_access(pos, player_name)
	local _, reason = S.loaded_node(pos)
	if reason then return false, reason end
	if minetest.is_protected(pos, player_name) then
		return false, "protected"
	end
	return true
end

function S.near_player(player, pos, maximum)
	local current = player:get_pos()
	if not current then return false, "missing_player_position" end
	local dx, dy, dz = current.x - pos.x, current.y - pos.y, current.z - pos.z
	if dx * dx + dy * dy + dz * dz > maximum * maximum then
		return false, "too_far"
	end
	return true
end

function S.make_actor(player, inventory)
	if not rawget(_G, "fakelib") or type(fakelib.create_player) ~= "function" then
		return nil, "fakelib_unavailable"
	end
	local options = {
		name = player:get_player_name(),
		position = player:get_pos(),
		direction = player:get_look_dir(),
	}
	if inventory then options.inventory = inventory end
	local ok, actor = pcall(fakelib.create_player, options)
	if not ok or not actor then return nil, "fake_player_failed" end
	return actor
end

function S.check_callback(callback, ...)
	if type(callback) ~= "function" then return true end
	local ok, result = pcall(callback, ...)
	if not ok then
		T.log("error", "safety callback failed: " .. tostring(result))
		return false, "callback_error"
	end
	return result ~= false and result ~= 0, result == 0 and "callback_denied" or nil, result
end

