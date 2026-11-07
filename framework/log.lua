local T = trickster

local function clean(value)
	return tostring(value or ""):gsub("[%c]", " ")
end

function T.log(level, message)
	minetest.log(level or "action", string.format("[%s] %s", T.modname, clean(message)))
end

function T.audit(kind, fields)
	if not T.config.diagnostic_log then return end
	local parts = {"origin=" .. clean(kind)}
	local keys = {}
	for key in pairs(fields or {}) do keys[#keys + 1] = key end
	table.sort(keys)
	for _, key in ipairs(keys) do
		parts[#parts + 1] = clean(key) .. "=" .. clean(fields[key])
	end
	T.log("action", table.concat(parts, " "))
end

