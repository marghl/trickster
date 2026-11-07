local T = trickster

-- These are compatibility capabilities, not persona definitions. They are
-- enabled only when Minetest Game's default mod is actually present.
if minetest.get_modpath("default") then
	T.register_sound_profile("hard_footstep", {
		sound = "default_hard_footstep",
		max_gain = 0.35,
		max_distance = 12,
	})
	T.register_sound_profile("stone_work", {
		sound = "default_dig_cracky",
		max_gain = 0.35,
		max_distance = 12,
	})
	T.register_sound_profile("hard_place", {
		sound = "default_place_node_hard",
		max_gain = 0.35,
		max_distance = 12,
	})
end

