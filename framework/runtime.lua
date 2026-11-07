local T = trickster
local R = {started = false}
T.runtime = R

local accumulator = 0
local flush_accumulator = 0
local recovery_accumulator = 0

function R.set_mode(mode, actor)
	T.state.set_mode(mode)
	if mode == "paused" then T.plans.clear("emergency_stop") end
	T.state.flush(true)
	T.audit("admin_directed", {
		action = "mode_changed", mode = mode, actor = actor or "server",
	})
end

function R.start()
	if R.started then return end
	R.started = true
	minetest.register_globalstep(function(dtime)
		T.director.step(dtime)
		accumulator = accumulator + dtime
		flush_accumulator = flush_accumulator + dtime
		recovery_accumulator = recovery_accumulator + dtime
		if flush_accumulator >= T.config.state_flush_interval then
			flush_accumulator = 0
			T.state.flush()
		end
		if recovery_accumulator >= 30 then
			recovery_accumulator = 0
			if next(T.transactions._pending()) then T.transactions.recover_all() end
		end
		if not T.config.enabled or T.state.get_mode() == "paused" then return end
		if accumulator < T.config.runtime_interval then return end
		accumulator = accumulator % T.config.runtime_interval
		local plan = T.plans.pop()
		if plan then T.plans.execute(plan) end
	end)

	minetest.register_on_shutdown(function()
		T.state.flush(true)
	end)
	minetest.register_on_joinplayer(function()
		if next(T.transactions._pending()) then
			minetest.after(0, T.transactions.recover_all)
		end
	end)
	minetest.register_on_leaveplayer(function(player)
		T.director.forget_player(player:get_player_name())
	end)

	local privilege = T.modname .. "_admin"
	minetest.register_privilege(privilege, {
		description = "Control the " .. T.modname .. " framework",
		give_to_singleplayer = false,
	})
	minetest.register_chatcommand(T.modname .. "_mode", {
		params = "active|directing|paused",
		description = "Set framework operation mode",
		privs = {[privilege] = true},
		func = function(name, param)
			if param ~= "active" and param ~= "directing" and param ~= "paused" then
				return false, "mode must be active, directing or paused"
			end
			R.set_mode(param, name)
			return true, "mode: " .. param
		end,
	})
	minetest.register_chatcommand(T.modname .. "_status", {
		description = "Show framework status",
		privs = {[privilege] = true},
		func = function()
			return true, string.format("mode=%s queued=%d pending_transactions=%d open_contracts=%d",
				T.state.get_mode(), T.plans.queue_size(), T.util.table_size(T.transactions._pending()),
				T.util.table_size(T.vault.open_contracts()))
		end,
	})
end
