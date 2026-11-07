local T = trickster
local U = T.util
local X = T.transactions
local P = {}
T.plans = P

local queue = {}
local allowed_origins = {
	automatic_persona_event = true,
	admin_directed = true,
}

local function validate_effect(effect)
	if type(effect) ~= "table" or not U.valid_id(effect.type) then
		return false, "invalid_effect"
	end
	if not T._get_core_effect(effect.type) then return false, "unknown_effect" end
	if type(effect.request) ~= "table" then return false, "missing_effect_request" end
	return true
end

local function normalize_plan(plan, origin)
	if type(plan) ~= "table" then return nil, "invalid_plan" end
	if not U.valid_id(plan.persona_id) or not T.get_persona(plan.persona_id) then
		return nil, "unknown_persona"
	end
	if type(plan.player_name) ~= "string" or plan.player_name == "" then
		return nil, "invalid_player"
	end
	if type(plan.effects) ~= "table" or #plan.effects < 1 then
		return nil, "empty_plan"
	end
	-- API v1 has transaction-safe individual effects, but no cross-effect rollback.
	-- Refuse compound plans until a plan-wide transaction coordinator exists.
	if #plan.effects > 1 then return nil, "compound_plan_not_supported" end
	if #plan.effects > T.config.max_effects_per_plan then
		return nil, "effect_budget"
	end
	for _, effect in ipairs(plan.effects) do
		local ok, reason = validate_effect(effect)
		if not ok then return nil, reason end
	end
	local cooldowns = plan.cooldowns or {}
	local normalized = {
		id = U.random_id("plan"),
		created_at = U.now(),
		persona_id = plan.persona_id,
		player_name = plan.player_name,
		intent = U.valid_id(plan.intent) and plan.intent or "unspecified",
		tier = math.max(0, math.min(4, math.floor(tonumber(plan.tier) or 0))),
		effects = U.deep_copy(plan.effects),
		origin = allowed_origins[origin] and origin or "automatic_persona_event",
		cooldowns = {
			player = math.max(0, tonumber(cooldowns.player) or 0),
			persona = math.max(0, tonumber(cooldowns.persona) or 0),
			danger = math.max(0, tonumber(cooldowns.danger) or 0),
		},
	}
	return normalized
end

function P.submit(plan, origin)
	if #queue >= T.config.max_queue then return nil, "queue_full" end
	local mode = T.state.get_mode()
	if mode == "paused" then return nil, "paused" end
	if mode == "directing" and origin ~= "admin_directed" then return nil, "directing_mode" end
	local normalized, reason = normalize_plan(plan, origin)
	if not normalized then return nil, reason end
	local cooldown = T.state.cooldown_reason(normalized.player_name, normalized.persona_id)
	if cooldown then return nil, cooldown end
	queue[#queue + 1] = normalized
	T.audit(normalized.origin, {
		action = "plan_queued", plan = normalized.id, persona = normalized.persona_id,
		player = normalized.player_name, tier = normalized.tier,
	})
	return normalized.id
end

function T.request_interaction(key, context)
	local interaction = T.get_interaction(key)
	if not interaction then return nil, "unknown_interaction" end
	context = U.deep_copy(context or {})
	local ok, plan = pcall(interaction.build_plan, context)
	if not ok then
		T.log("error", "interaction plan builder failed: " .. tostring(plan))
		return nil, "plan_builder_error"
	end
	if type(plan) ~= "table" then return nil, "interaction_declined" end
	plan.persona_id = interaction.persona_id
	return P.submit(plan, "automatic_persona_event")
end

local function execute_effect(plan, effect, index)
	local handler = T._get_core_effect(effect.type)
	local request = U.deep_copy(effect.request)
	request.player_name = plan.player_name
	local ok, prepared, reason = pcall(handler.prepare, request)
	if not ok then return false, "prepare_error" end
	if not prepared then return false, reason or "prepare_denied" end
	if T.config.dry_run then return true, "dry_run" end
	local transaction_id, tx_or_reason = X.begin("effect", {
		effect = effect.type,
		prepared = prepared,
	}, {
		origin = plan.origin,
		plan = plan.id,
		persona = plan.persona_id,
		player = plan.player_name,
		effect = effect.type,
		effect_index = index,
	})
	if not transaction_id then return false, tx_or_reason end
	local applied, success, apply_reason = pcall(handler.apply, prepared, transaction_id)
	if not applied then
		T.log("error", "effect apply failed transaction=" .. transaction_id .. " error=" .. tostring(success))
		return false, "apply_error"
	end
	if not success then
		local recovered, recovery_reason = handler.recover(prepared, "apply_failed")
		if recovered then X.finish(transaction_id, "rejected_" .. tostring(apply_reason)) end
		return false, apply_reason or recovery_reason or "apply_denied"
	end
	X.finish(transaction_id, "committed")
	return true
end

function P.execute(plan)
	if T.state.get_mode() == "paused" then return false, "paused" end
	local cooldown = T.state.cooldown_reason(plan.player_name, plan.persona_id)
	if cooldown then return false, cooldown end
	for index, effect in ipairs(plan.effects) do
		local ok, reason = execute_effect(plan, effect, index)
		if not ok then
			T.audit(plan.origin, {
				action = "plan_rejected", plan = plan.id, persona = plan.persona_id,
				player = plan.player_name, reason = reason, effect_index = index,
			})
			return false, reason
		end
	end
	if T.config.dry_run then
		T.audit(plan.origin, {
			action = "plan_validated_dry_run", plan = plan.id, persona = plan.persona_id,
			player = plan.player_name, intent = plan.intent, tier = plan.tier,
		})
		return true, "dry_run"
	end
	local now = U.now()
	T.state.set_cooldowns(plan.player_name, plan.persona_id, {
		player = now + plan.cooldowns.player,
		persona = now + plan.cooldowns.persona,
		danger = plan.tier >= 3 and (now + plan.cooldowns.danger) or 0,
	})
	T.audit(plan.origin, {
		action = "plan_committed", plan = plan.id, persona = plan.persona_id,
		player = plan.player_name, intent = plan.intent, tier = plan.tier,
	})
	return true
end

function P.pop()
	if #queue == 0 then return nil end
	return table.remove(queue, 1)
end

function P.clear(reason)
	local count = #queue
	queue = {}
	if count > 0 then T.audit("admin_directed", {action = "queue_cleared", count = count, reason = reason}) end
	return count
end

function P.queue_size()
	return #queue
end
