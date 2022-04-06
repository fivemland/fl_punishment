CreateThread(function()
	MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `punishments` (
      `identifier` VARCHAR(64) NOT NULL DEFAULT '',
      `comserv` TEXT NOT NULL,
      `jail` TEXT NOT NULL,
      `ban` TEXT NOT NULL,
      PRIMARY KEY (`identifier`)
    )
    COLLATE='utf8_general_ci';
  ]])
end)

function getPlayerComserv(xPlayer)
	if type(xPlayer) ~= "table" then
		xPlayer = ESX.GetPlayerFromId(xPlayer)
	end

	local result = MySQL.query.await("SELECT comserv FROM punishments WHERE identifier = ?", { xPlayer.identifier })
	if not result or #result < 1 then
		return false
	end

	return json.decode(result[1].comserv)
end

ESX.RegisterServerCallback("requestPlayerComserv", function(player, cb)
	cb(getPlayerComserv(player))
end)

ESX.RegisterServerCallback("decreaseComservCount", function(player, cb)
	local xPlayer = ESX.GetPlayerFromId(player)
	local comserv = getPlayerComserv(player)

	comserv.count = comserv.count - 1
	if comserv.count <= 0 then
		comserv = nil
	end

	MySQL.query("UPDATE punishments SET comserv = ? WHERE identifier = ?", {
		json.encode(comserv),
		xPlayer.identifier,
	})

	cb(comserv)
end)

RegisterCommand("comserv", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)

	if #args < 3 then
		return output("/comserv [Target Player] [Count] [Reason]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found", player)
	end

	local count = tonumber(args[2])
	if not count then
		return output("Count is invalid!", player)
	end
	count = math.abs(math.floor(count))

	table.remove(args, 1)
	table.remove(args, 1)

	local reason = table.concat(args, " ")

	if getPlayerComserv(xTarget) then
		return output("Player is already in community service", player)
	end

	local comserv = {
		count = count,
		reason = reason,
		start = os.time(os.date("!*t")),
		admin = {
			name = GetPlayerName(player),
			identifier = xPlayer.identifier,
		},
	}

	MySQL.insert(
		"INSERT INTO punishments SET identifier = ?, comserv = ? ON DUPLICATE KEY UPDATE comserv = ?",
		{ xTarget.identifier, json.encode(comserv), json.encode(comserv) }
	)
	TriggerClientEvent("updateComserv", xTarget.source, comserv)

	output("Work allocated to the player. Reason: " .. reason, player)

	output(GetPlayerName(player) .. " has assigned you " .. count .. " community service assignment.", xTarget.source)
	output("Reason: " .. reason, xTarget.source)
end, false)

RegisterCommand("removecomserv", function(player, args)
	if #args < 1 then
		return output("/removecomserv [Target Player]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found", player)
	end

	local comserv = getPlayerComserv(xTarget)
	print(ESX.DumpTable(comserv))
	if not comserv then
		return output("Player not in community service.", player)
	end

	exports.oxmysql:update(
		"INSERT INTO punishments SET identifier = ? ON DUPLICATE KEY UPDATE comserv = ''",
		{ xTarget.identifier }
	)
	TriggerClientEvent("updateComserv", xTarget.source, false)

	output("You remove player from community service.", player)
	output(GetPlayerName(player) .. " has removed you from community service", xTarget.source)
end, false)
