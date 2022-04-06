COMSERV = {
	coords = vector3(168.528, -978.9825, 30.09193),
	radius = 20,
}

ADMIN_RANKS = {
	["admin"] = true,
}

function output(text, target)
	if IsDuplicityVersion() then --Server Side
		TriggerClientEvent("chat:addMessage", target or -1, {
			color = { 255, 0, 0 },
			multiline = true,
			args = { "Server", text },
		})
	else
		TriggerEvent("chat:addMessage", {
			color = { 255, 0, 0 },
			multiline = true,
			args = { "Server", text },
		})
	end
end
