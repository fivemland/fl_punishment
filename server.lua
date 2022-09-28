local DAY_SECONDS = 60 * 60 * 24

CreateThread(function()
	Citizen.Await(createSQLColumn("comserv"))
	Citizen.Await(createSQLColumn("jail"))
	Citizen.Await(createSQLColumn("ban"))
end)

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

function getPlayerPunishment(xPlayer, name)
	if not (name == "comserv" or name == "jail") then
		return false
	end

	if type(xPlayer) ~= "table" then
		xPlayer = ESX.GetPlayerFromId(xPlayer)
	end

	local result = MySQL.scalar.await("SELECT ?? FROM users WHERE identifier = ?", { name, xPlayer.identifier })
	if not result or result:len() <= 0 then
		return false
	end

	return json.decode(result)
end
exports("getPlayerPunishment", getPlayerPunishment)

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

ESX.RegisterServerCallback("requestPlayerPunishment", function(player, cb, name)
	cb(getPlayerPunishment(player, name))
end)

ESX.RegisterServerCallback("decreaseComservCount", function(player, cb)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return cb(false)
	end
	local comserv = getPlayerPunishment(xPlayer, "comserv")
	if not comserv then
		return cb(false)
	end

	comserv.count = (comserv.count or comserv.all or 0) - 1
	if comserv.count <= 0 then
		comserv = nil
	end

	MySQL.query("UPDATE users SET comserv = ? WHERE identifier = ?", {
		json.encode(comserv),
		xPlayer.identifier,
	})

	cb(comserv)
end)

ESX.RegisterServerCallback("increaseAdminJailTime", function(player, cb)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer then
		return cb(false)
	end

	local jail = getPlayerPunishment(xPlayer, "jail")
	if not jail then
		return cb(false)
	end

	jail.count = (jail.count or 0) + 1
	if jail.count >= (jail.all or 0) then
		jail = nil

		output("Admin jail is over.", player)
	end

	MySQL.query("UPDATE users SET jail = ? WHERE identifier = ?", {
		json.encode(jail),
		xPlayer.identifier,
	})

	cb(jail)
end)

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
		if selectedTab == "comserv" then
			TriggerClientEvent("updateComserv", xTarget.source, false)
		elseif selectedTab == "jail" then
			TriggerClientEvent("updateAdminJail", xTarget.source, false)
		end
	end

	output("You removed punishment.", player)

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

	if getPlayerPunishment(xTarget, "jail") then
		return output("Player is already in admin jail!", player)
	end

	if getPlayerPunishment(xTarget, "comserv") then
		return output("Player is already in community service!", player)
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

	local comserv = getPlayerPunishment(xTarget, "comserv")
	if not comserv then
		return output("Player not in community service.", player)
	end

	exports.oxmysql:update("UPDATE users SET comserv = '' WHERE identifier = ?", { xTarget.identifier })
	TriggerClientEvent("updateComserv", xTarget.source, false)

	output("You remove player from community service.", player)
	output(GetPlayerName(player) .. " has removed you from community service", xTarget.source)
end, false)

RegisterCommand("ban", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 2 then
		return output("/ban [Target Player] [Days (0 - Infinity)] [Reason]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found!", player)
	end

	local days = tonumber(args[2])
	if not days or days < 0 then
		return output("Days value invalid!", player)
	end
	days = math.floor(days)

	table.remove(args, 1)
	table.remove(args, 1)

	local reason = table.concat(args, " ")
	if reason:len() <= 0 then
		reason = "No Reason"
	end

	local currentTimestamp = os.time(os.date("!*t"))
	local ban = {
		count = days,
		start = currentTimestamp,
		endDate = currentTimestamp + ((days == 0 and 3650 or days) * DAY_SECONDS),
		reason = reason,
		admin = {
			name = GetPlayerName(player),
			identifier = xPlayer.identifier,
		},
	}

	MySQL.query("UPDATE users SET ban = ? WHERE identifier = ?", { json.encode(ban), xTarget.identifier })

	output("You banned the player, " .. xTarget.getName(), player)
	output("Days: " .. (days == 0 and "Infinity" or days), player)
	output("Reason: " .. reason, player)

	Wait(1000)
	DropPlayer(
		xTarget.source,
		"You have been banned from the server\nAdmin: "
			.. GetPlayerName(player)
			.. "\nDays: "
			.. (days == 0 and "Infinity" or days)
			.. "\nReason: "
			.. reason
	)
end)

AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
	local player = source
	local identifiers = GetPlayerIdentifiers(player)
	local selectedId = false

	deferrals.defer()
	Wait(0)

	for _, id in pairs(identifiers) do
		if id:find("license:") then
			selectedId = id:gsub("license:", "")
			break
		end
	end

	deferrals.update("Checking ban status...")
	
	local banQuery = MySQL.query.await("SELECT ban FROM users WHERE SUBSTRING_INDEX(identifier, ':', -1) = ?", { selectedId })

	if not banQuery or #banQuery <= 0 then
		return deferrals.done()
	end

	-- Fix multicharacter ban check
	local result = nil
	for _, row in pairs(banQuery) do 
		if row.ban and row.ban ~= "" then 
      result = row.ban
			break
		end
	end

	if not result then
		return deferrals.done()
	end

	result = json.decode(result)

	local currentTimestamp = os.time(os.date("!*t"))

	if result.endDate > currentTimestamp then
		return deferrals.done(
			"\nYou have been banned from the server\nAdmin: "
				.. result.admin.name
				.. "\nDays: "
				.. (result.count == 0 and "Infinity" or result.count)
				.. "\nEnd Date: "
				.. os.date("%Y-%b-%d", result.endDate)
				.. "\nReason: "
				.. result.reason
				.. "\nIdentifier: "
				.. selectedId
		)
	else
		Wait(1000)

		deferrals.update("Ban clear.")

		exports.oxmysql:update("UPDATE users SET ban = '' WHERE identifier = ?", { selectedId })
	end

	Wait(1000)
	deferrals.done()
end)

RegisterCommand("unban", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 1 then
		return output("/unban [Identifier / Character Name]", player)
	end

	local input = table.concat(args, " ")

	local result = MySQL.query.await(
		"SELECT identifier, firstname, lastname, ban FROM users WHERE identifier = ? OR LOWER(CONCAT(firstname, ' ', lastname)) = ?",
		{ input, input }
	)

	if not result or #result < 1 then
		return output("Player not found!", player)
	end

	result = result[1]

	if result.ban:len() <= 0 then
		return output("Player not banned!", player)
	end

	exports.oxmysql:update("UPDATE users SET ban = '' WHERE identifier = ?", { result.identifier })

	output("Player unbanned. Name: " .. result.firstname .. " " .. result.lastname, player)
end, false)

RegisterCommand("adminjail", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 2 then
		return output("/adminjail [Target Player] [Minutes] [Reason]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found", player)
	end

	if getPlayerPunishment(xTarget, "comserv") then
		return output("Player is already in community service!", player)
	end

	if getPlayerPunishment(xTarget, "jail") then
		return output("Player is already in admin jail!", player)
	end

	local time = tonumber(args[2])
	if not time then
		return output("Time not a number!", player)
	end
	time = math.abs(math.floor(time))

	table.remove(args, 1)
	table.remove(args, 1)

	local reason = table.concat(args, " ")

	local currentTimestamp = os.time(os.date("!*t"))
	local jail = {
		count = 0,
		start = currentTimestamp,
		all = time,
		reason = reason,
		admin = {
			name = GetPlayerName(player),
			identifier = xPlayer.identifier,
		},
	}

	exports.oxmysql:update("UPDATE users SET jail = ? WHERE identifier = ?", { json.encode(jail), xTarget.identifier })

	TriggerClientEvent("updateAdminJail", xTarget.source, jail)

	output("Jail allocated to the player. Reason: " .. reason, player)

	output(GetPlayerName(player) .. " has assigned you " .. count .. " minute adminjail.", xTarget.source)
	output("Reason: " .. reason, xTarget.source)
end, false)

RegisterCommand("unjail", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 1 then
		return output("/unjail [Target Player]", player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output("Player not found!")
	end

	if not getPlayerPunishment(xTarget, "jail") then
		return output("Player not in admin jail!", player)
	end

	exports.oxmysql:update("UPDATE users SET jail = '' WHERE identifier = ?", { xTarget.identifier })
	TriggerClientEvent("updateAdminJail", xTarget.source, false)

	output("You remove player from adminjail.", player)
	output(GetPlayerName(player) .. " has removed you from adminjail", xTarget.source)
end)
