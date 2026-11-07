local T = trickster

T.register_persona({
	id = "underground_01",
	domain = {
		kind = "underground",
		upper_y = -500,
		full_activity_y = -2500,
	},
	traits = {
		mischief = 0.90,
		helpfulness = 0.15,
		secrecy = 0.95,
		curiosity = 0.75,
		resentment = 0.80,
		anger = 0.55,
		mercy = 0.35,
		malice = 0.45,
		danger = 0.50,
	},
	taboos = {
		"canonical_name",
		"visible_confirmation",
		"technical_safety_bypass",
		"untracked_item_loss",
	},
	defaults = {
		check_interval = 30,
		mean_wait_at_maximum = 3600,
		alone_radius = 32,
	},
	activation = function(context)
		local y = context.position.y
		if y >= -500 then return {in_domain = false, factor = 0} end
		local depth = T.director.depth_factor(y, -500, -2500)
		local stay = T.director.stay_factor(context.seconds_present, 120, 720)
		local solitude
		if context.nearby_players == 0 then
			solitude = 1
		elseif context.nearby_players == 1 then
			solitude = 0.08
		else
			solitude = 0
		end
		return {
			in_domain = true,
			factor = depth * stay * solitude,
		}
	end,
})

