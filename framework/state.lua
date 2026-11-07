local T = trickster
local U = T.util
local storage = minetest.get_mod_storage()
local key = "framework_state_v1"
local decoded = minetest.deserialize(storage:get_string(key))

local data = type(decoded) == "table" and decoded or {
	players = {},
	server = {mode = "active"},
}
data.players = type(data.players) == "table" and data.players or {}
data.server = type(data.server) == "table" and data.server or {mode = "active"}

local dirty = false
local S = {}
T.state = S

local function player_state(name)
	assert(type(name) == "string" and name ~= "", "player name required")
	local state = data.players[name]
	if not state then
		state = {
			cooldown_until = 0,
			personas = {},
		}
		data.players[name] = state
		dirty = true
	end
	state.personas = state.personas or {}
	return state
end

local function persona_state(name, persona_id)
	local player = player_state(name)
	local state = player.personas[persona_id]
	if not state then
		state = {
			relationship = 0,
			cooldown_until = 0,
			danger_cooldown_until = 0,
			memory = {},
		}
		player.personas[persona_id] = state
		dirty = true
	end
	state.memory = state.memory or {}
	return state
end

function S.get_player(name)
	return U.deep_copy(player_state(name))
end

function S.get_persona(name, persona_id)
	return U.deep_copy(persona_state(name, persona_id))
end

function S.relationship(name, persona_id)
	return persona_state(name, persona_id).relationship or 0
end

function S.change_relationship(name, persona_id, delta)
	assert(type(delta) == "number", "relationship delta must be numeric")
	local state = persona_state(name, persona_id)
	state.relationship = U.clamp((state.relationship or 0) + delta, -100, 100)
	dirty = true
	return state.relationship
end

function S.set_cooldowns(name, persona_id, values)
	local player = player_state(name)
	local persona = persona_state(name, persona_id)
	values = values or {}
	player.cooldown_until = math.max(player.cooldown_until or 0, tonumber(values.player) or 0)
	persona.cooldown_until = math.max(persona.cooldown_until or 0, tonumber(values.persona) or 0)
	persona.danger_cooldown_until = math.max(persona.danger_cooldown_until or 0,
		tonumber(values.danger) or 0)
	dirty = true
end

function S.cooldown_reason(name, persona_id, now)
	now = now or U.now()
	local player = player_state(name)
	local persona = persona_state(name, persona_id)
	if (player.cooldown_until or 0) > now then return "player_cooldown" end
	if (persona.cooldown_until or 0) > now then return "persona_cooldown" end
	if (persona.danger_cooldown_until or 0) > now then return "danger_cooldown" end
	return nil
end

function S.set_memory(name, persona_id, memory_key, value)
	assert(U.valid_id(memory_key), "invalid memory key")
	local memory = persona_state(name, persona_id).memory
	if value == nil then
		memory[memory_key] = nil
	else
		if memory[memory_key] == nil and U.table_size(memory) >= 32 then
			return false, "memory_limit"
		end
		local encoded = minetest.serialize(value)
		if type(encoded) ~= "string" or #encoded > 4096 then return false, "memory_value_too_large" end
		memory[memory_key] = U.deep_copy(value)
	end
	dirty = true
	return true
end

function S.get_memory(name, persona_id, memory_key)
	return U.deep_copy(persona_state(name, persona_id).memory[memory_key])
end

function S.get_mode()
	return data.server.mode or "active"
end

function S.set_mode(mode)
	assert(mode == "active" or mode == "directing" or mode == "paused", "invalid mode")
	data.server.mode = mode
	dirty = true
end

function S.flush(force)
	if not dirty and not force then return true end
	storage:set_string(key, minetest.serialize(data))
	dirty = false
	return true
end

function S._reset_for_tests()
	data.players = {}
	data.server = {mode = "active"}
	dirty = true
end
