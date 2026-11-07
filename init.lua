trickster = rawget(_G, "trickster") or {}
local T = trickster

T.modname = minetest.get_current_modname()
T.modpath = minetest.get_modpath(T.modname)
T.api_version = 1

local function load(name)
	dofile(T.modpath .. "/framework/" .. name .. ".lua")
end

load("config")
load("util")
load("log")
load("registry")
load("state")
load("safety")
load("transactions")
load("vault")
load("inventory")
load("effects")
load("plans")
load("director")

dofile(T.modpath .. "/integrations/sounds.lua")
dofile(T.modpath .. "/personas/underground_01/init.lua")

load("runtime")

T.transactions.recover_all()
T.runtime.start()

minetest.log("action", string.format("[%s] framework API v%d loaded", T.modname, T.api_version))
