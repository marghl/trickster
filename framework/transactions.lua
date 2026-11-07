local T = trickster
local U = T.util
local storage = minetest.get_mod_storage()
local storage_key = "transactions_v1"
local decoded = minetest.deserialize(storage:get_string(storage_key))
local pending = type(decoded) == "table" and decoded or {}
local kinds = {}
local X = {}
T.transactions = X

local function save()
	storage:set_string(storage_key, next(pending) and minetest.serialize(pending) or "")
end

function X.register_kind(name, handler)
	assert(U.valid_id(name), "invalid transaction kind")
	assert(type(handler) == "table" and type(handler.recover) == "function",
		"transaction kind requires recover")
	assert(not kinds[name], "transaction kind already registered: " .. name)
	kinds[name] = handler
end

function X.begin(kind, payload, audit)
	assert(kinds[kind], "unknown transaction kind: " .. tostring(kind))
	if U.table_size(pending) >= T.config.transaction_limit then
		return nil, "transaction_limit"
	end
	local id = U.random_id("tx")
	pending[id] = {
		id = id,
		kind = kind,
		stage = "prepared",
		created_at = U.now(),
		payload = U.deep_copy(payload),
		audit = U.deep_copy(audit or {}),
	}
	save()
	return id, pending[id]
end

function X.set_stage(id, stage, patch)
	local tx = pending[id]
	if not tx then return false, "unknown_transaction" end
	tx.stage = stage
	for key, value in pairs(patch or {}) do tx.payload[key] = U.deep_copy(value) end
	save()
	return true
end

function X.finish(id, result)
	local tx = pending[id]
	if not tx then return false, "unknown_transaction" end
	local audit = tx.audit or {}
	audit.transaction = id
	audit.transaction_kind = tx.kind
	audit.result = result or "committed"
	pending[id] = nil
	save()
	T.audit(audit.origin or "automatic_persona_event", audit)
	return true
end

function X.get(id)
	return pending[id] and U.deep_copy(pending[id]) or nil
end

function X.recover_all()
	for id, tx in pairs(U.deep_copy(pending)) do
		local handler = kinds[tx.kind]
		if not handler then
			T.log("error", "unknown pending transaction kind " .. tostring(tx.kind) .. " id=" .. id)
		else
			local ok, recovered, reason = pcall(handler.recover, tx)
			if ok and recovered then
				X.finish(id, reason or "recovered")
			elseif not ok then
				T.log("error", "transaction recovery failed id=" .. id .. " error=" .. tostring(recovered))
			else
				T.log("warning", "transaction remains pending id=" .. id .. " reason=" .. tostring(reason))
			end
		end
	end
end

function X._pending()
	return U.deep_copy(pending)
end

