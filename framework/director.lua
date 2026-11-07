local T = trickster
local U = T.util
local D = {}
T.director = D

local accumulator = 0
local states = {}

local function state_for(player_name, persona_id, now)
	local player_state = states[player_name]
	if not player_state then
		player_state = {next_check = now + math.random(1, 30), personas = {}}
		states[player_name] = player_state
	end
	local persona_state = player_state.personas[persona_id]
	if not persona_state then
		persona_state = {present_since = nil}
		player_state.personas[persona_id] = persona_state
	end
	return player_state, persona_state
end

local function nearby_count(player, players, radius)
	local pos = player:get_pos()
	local radius_sq = radius * radius
	local count = 0
	for _, other in ipairs(players) do
		if other ~= player then
			local other_pos = other:get_pos()
			local dx = other_pos.x - pos.x
			local dy = other_pos.y - pos.y
			local dz = other_pos.z - pos.z
			if dx * dx + dy * dy + dz * dz <= radius_sq then count = count + 1 end
		end
	end
	return count
end

local function choose_interaction(persona, context)
	local choices = {}
	local total = 0
	for _, interaction in ipairs(T.list_persona_interactions(persona.id)) do
		local available = true
		if interaction.is_available then
			local ok, result = pcall(interaction.is_available, U.deep_copy(context))
			available = ok and result == true
		end
		if available and interaction.weight > 0 then
			total = total + interaction.weight
			choices[#choices + 1] = {interaction = interaction, ceiling = total}
		end
	end
	if total <= 0 then return nil end
	local roll = math.random() * total
	for _, choice in ipairs(choices) do
		if roll <= choice.ceiling then return choice.interaction end
	end
	return choices[#choices].interaction
end

local function consider_persona(player, players, persona, now)
	local name = player:get_player_name()
	local _, persona_state = state_for(name, persona.id, now)
	if T.state.cooldown_reason(name, persona.id) then return false end
	if persona.is_available then
		local ok, available = pcall(persona.is_available, name)
		if not ok or available ~= true then return false end
	end
	local defaults = persona.defaults or {}
	local context = {
		player_name = name,
		position = U.copy_pos(player:get_pos()),
		look_direction = U.copy_pos(player:get_look_dir()),
		nearby_players = nearby_count(player, players, tonumber(defaults.alone_radius) or 32),
		seconds_present = persona_state.present_since and (now - persona_state.present_since) or 0,
		relationship = T.state.relationship(name, persona.id),
	}
	local ok, activation = pcall(persona.activation, U.deep_copy(context))
	if not ok then
		T.log("error", "persona activation failed id=" .. persona.id .. " error=" .. tostring(activation))
		return false
	end
	if type(activation) ~= "table" or activation.in_domain ~= true then
		persona_state.present_since = nil
		return false
	end
	if not persona_state.present_since then
		persona_state.present_since = now
		context.seconds_present = 0
	end
	local factor = U.clamp(tonumber(activation.factor) or 0, 0, 1)
	if factor <= 0 then return false end
	local mean_wait = math.max(60, tonumber(defaults.mean_wait_at_maximum) or 3600)
	local check_interval = math.max(5, tonumber(defaults.check_interval) or 30)
	local probability = 1 - math.exp(-(factor * check_interval) / mean_wait)
	if math.random() >= probability then return false end
	context.activation_factor = factor
	local interaction = choose_interaction(persona, context)
	if not interaction then return false end
	local plan_id = T.request_interaction(interaction.key, context)
	return plan_id ~= nil
end

local function check_player(player, players, now)
	local name = player:get_player_name()
	local player_state = states[name] or {next_check = now, personas = {}}
	states[name] = player_state
	local interval = 30
	player_state.next_check = now + interval * (0.9 + math.random() * 0.2)
	for _, persona in ipairs(T.list_personas()) do
		if consider_persona(player, players, persona, now) then return true end
	end
	return false
end

function D.step(dtime)
	accumulator = accumulator + dtime
	if accumulator < T.config.director_interval then return end
	accumulator = accumulator % T.config.director_interval
	if not T.config.enabled or T.state.get_mode() ~= "active" then return end
	local players = minetest.get_connected_players()
	local now = minetest.get_gametime()
	for _, player in ipairs(players) do
		local player_state = states[player:get_player_name()]
		if not player_state or now >= player_state.next_check then
			check_player(player, players, now)
			break -- hard budget: at most one player check per director interval
		end
	end
end

function D.forget_player(name)
	states[name] = nil
end

function D.depth_factor(y, upper_y, full_y)
	local span = upper_y - full_y
	if span <= 0 then return 0 end
	local t = U.clamp((upper_y - y) / span, 0, 1)
	return t * t * (3 - 2 * t)
end

function D.stay_factor(seconds, start_after, full_after)
	if full_after <= start_after then return seconds >= full_after and 1 or 0 end
	return U.clamp((seconds - start_after) / (full_after - start_after), 0, 1)
end

D._states = states

