function createSQLColumn(name)
	local p = promise.new()

	local exists = MySQL.scalar.await("SHOW COLUMNS FROM `users` LIKE '" .. name .. "'")
	if exists then
		return p:resolve(false)
	end

	MySQL.query([[
			ALTER TABLE `users`
			ADD COLUMN `]] .. name .. [[` TEXT NULL DEFAULT '';
		]], function()
		p:resolve(true)
	end)

	return p
end

CreateThread(function()
	Citizen.Await(createSQLColumn("comserv"))
	Citizen.Await(createSQLColumn("jail"))
	Citizen.Await(createSQLColumn("ban"))
end)

function getPlayerComserv(xPlayer)
	if type(xPlayer) ~= "table" then
		xPlayer = ESX.GetPlayerFromId(xPlayer)
	end

	local result = MySQL.query.await("SELECT comserv FROM users WHERE identifier = ?", { xPlayer.identifier })
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

	MySQL.query("UPDATE users SET comserv = '' WHERE identifier = ?", {
		xPlayer.identifier,
	})

	cb(comserv)
end)

function getPunishmentUsers(selectedTab)
	local result = MySQL.query.await(
		"SELECT identifier, firstname, lastname, ?? FROM users WHERE NOT (?? = '' OR ?? = 'null')",
		{ selectedTab, selectedTab, selectedTab }
	)

	local newResult = {}

	for _, row in pairs(result) do
		row[selectedTab] = json.decode(row[selectedTab])
		row.name = row.firstname .. " " .. row.lastname
		table.insert(newResult, row)
	end

	return newResult
end

ESX.RegisterServerCallback("requestPunishmentUsers", function(player, cb, selectedTab)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not ADMIN_RANKS[xPlayer.getGroup()] then
		return cb(false)
	end

	cb(getPunishmentUsers(selectedTab))
end)

ESX.RegisterServerCallback("removeUserFromPunishment", function(player, cb, selectedTab, identifier)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not ADMIN_RANKS[xPlayer.getGroup()] then
		return cb(false)
	end

	MySQL.query.await("UPDATE users SET	?? = '' WHERE identifier = ?", { selectedTab, identifier })

	local xTarget = ESX.GetPlayerFromIdentifier(identifier)
	if xTarget then
		TriggerClientEvent("updateComserv", xTarget.source, false)
	end

	cb(getPunishmentUsers(selectedTab))
end)

ESX.RegisterServerCallback("requestPunishmentUserData", function(player, cb, selectedTab, identifier)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not ADMIN_RANKS[xPlayer.getGroup()] then
		return cb("You are not an admin!")
	end

	local result = MySQL.query.await(
		"SELECT identifier, firstname, lastname, accounts, job, ?? FROM users WHERE identifier = ?",
		{ selectedTab, identifier }
	)

	if not result or #result <= 0 then
		return cb("User not found!")
	end

	cb(_, result[1])
end)

RegisterCommand("punishments", function(player)
	if not isAdmin(player) then
		return
	end

	TriggerClientEvent("togglePunishmentsAdmin", player)
end, false)

RegisterCommand("comserv", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not isAdmin(xPlayer) then
		return
	end

	if #args < 3 then
		return output("/comserv [Target Player] [Count] [Reason]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found", player)
	end

	local count = tonumber(args[2])
	if not count or count <= 0 then
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
		all = count,
		reason = reason,
		start = os.time(os.date("!*t")),
		admin = {
			name = GetPlayerName(player),
			identifier = xPlayer.identifier,
		},
	}

	MySQL.insert("UPDATE users SET comserv = ? WHERE identifier = ?", { json.encode(comserv), xTarget.identifier })
	TriggerClientEvent("updateComserv", xTarget.source, comserv)

	output("Work allocated to the player. Reason: " .. reason, player)

	output(GetPlayerName(player) .. " has assigned you " .. count .. " community service assignment.", xTarget.source)
	output("Reason: " .. reason, xTarget.source)
end, false)

RegisterCommand("removecomserv", function(player, args)
	if not isAdmin(player) then
		return
	end

	if #args < 1 then
		return output("/removecomserv [Target Player]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found", player)
	end

	local comserv = getPlayerComserv(xTarget)
	if not comserv then
		return output("Player not in community service.", player)
	end

	exports.oxmysql:update("UPDATE users SET comserv = '' WHERE identifier = ?", { xTarget.identifier })
	TriggerClientEvent("updateComserv", xTarget.source, false)

	output("You remove player from community service.", player)
	output(GetPlayerName(player) .. " has removed you from community service", xTarget.source)
end, false)
