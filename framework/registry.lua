local T = trickster
local U = T.util

local personas = {}
local interactions = {}
local effects = {}

T.registry = {
	personas = personas,
	interactions = interactions,
}

local function copy_traits(traits)
	local result = {}
	for name, value in pairs(traits or {}) do
		assert(U.valid_id(name), "invalid trait id: " .. tostring(name))
		assert(type(value) == "number", "trait must be numeric: " .. name)
		result[name] = U.clamp(value, 0, 1)
	end
	return result
end

function T.register_persona(def)
	assert(type(def) == "table", "persona definition required")
	assert(U.valid_id(def.id), "persona id must be a meaningless lowercase technical id")
	assert(not personas[def.id], "persona already registered: " .. def.id)
	local persona = {
		id = def.id,
		domain = U.deep_copy(def.domain or {}),
		traits = copy_traits(def.traits),
		taboos = U.deep_copy(def.taboos or {}),
		defaults = U.deep_copy(def.defaults or {}),
		is_available = def.is_available,
		activation = def.activation,
	}
	if persona.is_available ~= nil then
		assert(type(persona.is_available) == "function", "is_available must be a function")
	end
	assert(type(persona.activation) == "function", "persona requires activation")
	personas[persona.id] = persona
	return persona.id
end

function T.register_interaction(def)
	assert(type(def) == "table", "interaction definition required")
	assert(U.valid_id(def.id), "invalid interaction id")
	assert(U.valid_id(def.persona_id), "invalid persona id")
	assert(personas[def.persona_id], "persona must be registered first")
	local key = def.persona_id .. ":" .. def.id
	assert(not interactions[key], "interaction already registered: " .. key)
	assert(type(def.build_plan) == "function", "interaction requires build_plan")
	interactions[key] = {
		key = key,
		id = def.id,
		persona_id = def.persona_id,
		intents = U.deep_copy(def.intents or {}),
		tiers = U.deep_copy(def.tiers or {}),
		weight = math.max(0, tonumber(def.weight) or 1),
		build_plan = def.build_plan,
		is_available = def.is_available,
	}
	if interactions[key].is_available ~= nil then
		assert(type(interactions[key].is_available) == "function", "is_available must be a function")
	end
	return key
end

function T.get_persona(id)
	return personas[id]
end

function T.get_interaction(key)
	return interactions[key]
end

function T.list_personas()
	local result = {}
	for _, persona in pairs(personas) do result[#result + 1] = persona end
	table.sort(result, function(a, b) return a.id < b.id end)
	return result
end

function T.list_persona_interactions(persona_id)
	local result = {}
	for _, interaction in pairs(interactions) do
		if interaction.persona_id == persona_id then result[#result + 1] = interaction end
	end
	table.sort(result, function(a, b) return a.key < b.key end)
	return result
end

-- Effect handlers are core-owned. Persona modules receive no registration hook
-- for executable effects; they may only request names already present here.
function T._register_core_effect(name, handler)
	assert(U.valid_id(name), "invalid core effect id")
	assert(type(handler) == "table", "effect handler required")
	assert(type(handler.prepare) == "function", "effect requires prepare")
	assert(type(handler.apply) == "function", "effect requires apply")
	assert(type(handler.recover) == "function", "effect requires recover")
	assert(not effects[name], "effect already registered: " .. name)
	effects[name] = handler
end

function T._get_core_effect(name)
	return effects[name]
end

function T.list_effects()
	local result = {}
	for name in pairs(effects) do result[#result + 1] = name end
	table.sort(result)
	return result
end
