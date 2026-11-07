local T = trickster
local U = T.util
local storage = minetest.get_mod_storage()
local storage_key = "effect_vault_v1"
local decoded = minetest.deserialize(storage:get_string(storage_key))
local contracts = type(decoded) == "table" and decoded or {}
local V = {}
T.vault = V

local valid_return_kinds = {
	identical = true,
	equivalent = true,
	transformed = true,
}

local function save()
	storage:set_string(storage_key, next(contracts) and minetest.serialize(contracts) or "")
end

local function prune()
	local cutoff = U.now() - 30 * 24 * 60 * 60
	for id, contract in pairs(contracts) do
		local completed = contract.fulfilled_at or contract.returned_at
		if completed and completed < cutoff then contracts[id] = nil end
	end
end

local function stack_table(stack)
	stack = ItemStack(stack)
	return stack:to_table()
end

function V.create(def)
	assert(type(def) == "table", "vault contract required")
	assert(type(def.player_name) == "string" and def.player_name ~= "", "contract player required")
	assert(U.valid_id(def.persona_id), "contract persona required")
	assert(valid_return_kinds[def.return_kind], "invalid return kind")
	assert(type(def.purpose) == "string" and def.purpose ~= "", "contract purpose required")
	assert(type(def.fallback) == "table", "contract fallback required")
	local stack = ItemStack(def.stack)
	assert(not stack:is_empty(), "contract stack must not be empty")
	prune()
	local open = 0
	for _, contract in pairs(contracts) do
		if contract.state == "reserved" or contract.state == "secured" then open = open + 1 end
	end
	if open >= T.config.transaction_limit then return nil, "vault_limit" end
	local id = U.random_id("vault")
	contracts[id] = {
		id = id,
		state = "reserved",
		created_at = U.now(),
		player_name = def.player_name,
		persona_id = def.persona_id,
		stack = stack_table(stack),
		return_kind = def.return_kind,
		purpose = def.purpose,
		recipe = U.deep_copy(def.recipe),
		fallback = U.deep_copy(def.fallback),
		result = nil,
	}
	save()
	return id
end

function V.get(id)
	return contracts[id] and U.deep_copy(contracts[id]) or nil
end

function V.mark_secured(id)
	local contract = contracts[id]
	if not contract or contract.state ~= "reserved" then return false, "invalid_contract_state" end
	contract.state = "secured"
	save()
	return true
end

function V.fulfill(id, result)
	local contract = contracts[id]
	if not contract or contract.state ~= "secured" then return false, "invalid_contract_state" end
	assert(type(result) == "table", "fulfillment result required")
	contract.state = "fulfilled"
	contract.result = U.deep_copy(result)
	contract.fulfilled_at = U.now()
	save()
	return true
end

function V.mark_returned(id, result)
	local contract = contracts[id]
	if not contract or (contract.state ~= "reserved" and contract.state ~= "secured") then
		return false, "invalid_contract_state"
	end
	contract.state = "returned"
	contract.result = U.deep_copy(result or {})
	contract.returned_at = U.now()
	save()
	return true
end

function V.open_contracts()
	local result = {}
	for id, contract in pairs(contracts) do
		if contract.state == "reserved" or contract.state == "secured" then
			result[id] = U.deep_copy(contract)
		end
	end
	return result
end
