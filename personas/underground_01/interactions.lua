local T = trickster

local sound_ids = {"hard_footstep", "stone_work", "hard_place"}

local function available_sounds()
	local result = {}
	for _, id in ipairs(sound_ids) do
		if T.has_sound_profile(id) then result[#result + 1] = id end
	end
	return result
end

local function random_between(low, high)
	return low + math.random() * (high - low)
end

T.register_interaction({
	id = "stray_sound",
	persona_id = "underground_01",
	intents = {"confuse", "observe"},
	tiers = {0},
	weight = 1,
	is_available = function()
		return #available_sounds() > 0
	end,
	build_plan = function(context)
		local sounds = available_sounds()
		if #sounds == 0 then return nil end
		local look = context.look_direction
		local horizontal_length = math.sqrt(look.x * look.x + look.z * look.z)
		if horizontal_length < 0.001 then return nil end
		local forward_x = look.x / horizontal_length
		local forward_z = look.z / horizontal_length
		local side_x, side_z = -forward_z, forward_x
		local distance = random_between(3, 7)
		local lateral = random_between(-2.5, 2.5)
		local position = {
			x = context.position.x - forward_x * distance + side_x * lateral,
			y = context.position.y + random_between(0, 1.5),
			z = context.position.z - forward_z * distance + side_z * lateral,
		}
		return {
			player_name = context.player_name,
			intent = math.random() < 0.75 and "confuse" or "observe",
			tier = 0,
			cooldowns = {
				player = math.random(3600, 10800),
				persona = math.random(7200, 21600),
			},
			effects = {{
				type = "sound",
				request = {
					profile = sounds[math.random(#sounds)],
					pos = position,
					gain = random_between(0.18, 0.32),
					pitch = random_between(0.92, 1.08),
				},
			}},
		}
	end,
})

