local DAY_SECONDS = 60 * 60 * 24

local function createSQLColumn(name)
	local p = promise.new()

	local exists = MySQL.scalar.await("SHOW COLUMNS FROM `users` LIKE '" .. name .. "'")
	if exists then
		return p:resolve(false)
	end

	MySQL.query(([[
			ALTER TABLE `users`
			ADD COLUMN %s TEXT NULL DEFAULT "";
		]]):format(name), function()
		p:resolve(true)
	end)

	return p
end

local function loadPlayerPunishment(player, xPlayer)
	local result = MySQL.single.await("SELECT comserv, jail FROM users WHERE identifier = ?", { xPlayer.identifier })

	for key, row in pairs(result) do 
		row = json.decode(row)

		if row then 
			TriggerClientEvent("updatePlayerPunishment", player, key, row)
			return
		end
	end
	
	TriggerClientEvent("updatePlayerPunishment", player, "clear")
end
AddEventHandler("esx:playerLoaded", loadPlayerPunishment)

local function sendToDiscord(title, message, color)
	if not WEBHOOK or WEBHOOK:len() <= 0 then
		return
	end

	local embeds = {
		{
        ["color"] = color,
        ["title"] = "**".. title .."**\n",
        ["description"] = message,
        ["footer"] = {
          ["text"] = "fl_punishment by FiveM Land",
        },
		}
	}

	PerformHttpRequest(WEBHOOK, function() end, "POST", json.encode({ embeds = embeds }), { ["Content-Type"] = "application/json" })
end

CreateThread(function()
	Citizen.Await(createSQLColumn("comserv"))
	Citizen.Await(createSQLColumn("jail"))
	Citizen.Await(createSQLColumn("ban"))

	for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
		loadPlayerPunishment(xPlayer.source, xPlayer)
	end
end)

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

		output(Translate("adminjail_over"), player)
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
			TriggerClientEvent("updatePlayerPunishment", xTarget.source, "comserv", false)
		elseif selectedTab == "jail" then
			TriggerClientEvent("updatePlayerPunishment", xTarget.source, "jail", false)
		end
	end

	output(Translate("removed_punishment"), player)

	cb(getPunishmentUsers(selectedTab))
end)

ESX.RegisterServerCallback("requestPunishmentUserData", function(player, cb, selectedTab, identifier)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not ADMIN_RANKS[xPlayer.getGroup()] then
		return cb(Translate("not_admin"))
	end

	local result = MySQL.query.await(
		"SELECT identifier, firstname, lastname, accounts, job, ?? FROM users WHERE identifier = ?",
		{ selectedTab, identifier }
	)

	if not result or #result <= 0 then
		return cb(Translate("user_not_found"))
	end

	cb(false, result[1])
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
		return output(Translate('invalid_syntax'), player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output(Translate("user_not_found"), player)
	end

	local count = tonumber(args[2])
	if not count or count <= 0 then
		return output(Translate("count_invalid"), player)
	end
	count = math.abs(math.floor(count))

	table.remove(args, 1)
	table.remove(args, 1)

	local reason = table.concat(args, " ")

	if getPlayerPunishment(xTarget, "jail") then
		return output(Translate("player_in_jail"), player)
	end

	if getPlayerPunishment(xTarget, "comserv") then
		return output(Translate("player_in_comserv"), player)
	end

	local adminName = GetPlayerName(player)
	local comserv = {
		count = count,
		all = count,
		reason = reason,
		start = os.time(os.date("!*t")),
		admin = {
			name = adminName,
			identifier = xPlayer.identifier,
		},
	}

	MySQL.insert("UPDATE users SET comserv = ? WHERE identifier = ?", { json.encode(comserv), xTarget.identifier })
	TriggerClientEvent("updatePlayerPunishment", xTarget.source, "comserv", comserv)

	output(Translate("work_allocated", reason), player)

	output(Translate("assigned_you", adminName, count), xTarget.source)
	output(Translate("reason", reason), xTarget.source)

	sendToDiscord(
		"comserv", 
		Translate("comserv_log", adminName, GetPlayerName(xTarget.source), xTarget.getName(), count, reason)
		, 15105570
	)
end, false)

RegisterCommand("removecomserv", function(player, args)
	if not isAdmin(player) then
		return
	end

	if #args < 1 then
		return output(Translate("invalid_syntax"), player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output(Translate("user_not_found"), player)
	end

	local comserv = getPlayerPunishment(xTarget, "comserv")
	if not comserv then
		return output(Translate("player_not_in_comserv"), player)
	end

	exports.oxmysql:update("UPDATE users SET comserv = '' WHERE identifier = ?", { xTarget.identifier })
	TriggerClientEvent("updatePlayerPunishment", xTarget.source, "comserv", false)

	local adminName = GetPlayerName(player)

	output(Translate("removed_from_comserv"), player)
	output(Translate("removed_you_comserv", adminName), xTarget.source)

	sendToDiscord(
		"removecomserv", 
		Translate("removecomserv_log", adminName, GetPlayerName(xTarget.source), xTarget.getName())
		, 15105570
	)

end, false)

function banPlayer(admin, target, days, reason)
	admin = (type(admin) == "number" or type(admin) == "string") and ESX.GetPlayerFromId(admin) or admin
	target = (type(target) == "number" or type(target) == "string") and ESX.GetPlayerFromId(target) or target

	if not isAdmin(admin) then 
		print(("%s try ban player %s"):format(admin.getName(), target.getName()))
		return false
	end

	local currentTimestamp = os.time(os.date("!*t"))
	local adminName = GetPlayerName(admin.source)
	local ban = {
		count = days,
		start = currentTimestamp,
		endDate = currentTimestamp + ((days == 0 and 3650 or days) * DAY_SECONDS),
		reason = reason,
		admin = {
			name = adminName,
			identifier = admin.identifier,
		},
	}

	sendToDiscord(
	"ban", 
		Translate("ban_log", adminName, GetPlayerName(target.source), target.getName(), target.identifier, days == 0 and "Infinity" or days, reason)
		, 15105570
	)

	MySQL.query("UPDATE users SET ban = ? WHERE identifier = ?", { json.encode(ban), target.identifier })

	Wait(1000)
	DropPlayer(
		target.source,
		Translate("ban_message", adminName, days == 0 and Translate("infinity") or days, reason)
	)

	return true
end
exports("banPlayer", banPlayer)

RegisterCommand("ban", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 2 then
		return output(Translate("invalid_syntax"), player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output(Translate("user_not_found"), player)
	end

	local days = tonumber(args[2])
	if not days or days < 0 then
		return output(Translate("invalid_days"), player)
	end
	days = math.floor(days)

	table.remove(args, 1)
	table.remove(args, 1)

	local reason = table.concat(args, " ")
	if reason:len() <= 0 then
		reason = Translate("no_reason")
	end

	local targetCharName = xTarget.getName()

	banPlayer(xPlayer, xTarget, days, reason)

	output(Translate("you_banned", targetCharName), player)
	output(Translate("days", days == 0 and Translate("infinity") or days), player)
	output(Translate("reason", reason), player)
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

	deferrals.update(Translate("checking_ban"))
	
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
			Translate("you_banned_from_server", 
				result.admin.name, 
				(result.count == 0 and Translate("infinity") or result.count),
				os.date("%Y-%b-%d", result.endDate),
				result.reason,
				selectedId
			)
		)
	else
		Wait(1000)

		deferrals.update(Translate("ban_clear"))

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
		return output(Translate("invalid_syntax"), player)
	end

	local input = table.concat(args, " ")

	local result = MySQL.query.await(
		"SELECT identifier, firstname, lastname, ban FROM users WHERE identifier = ? OR LOWER(CONCAT(firstname, ' ', lastname)) = ?",
		{ input, input }
	)

	if not result or #result < 1 then
		return output(Translate("user_not_found"), player)
	end

	result = result[1]

	if result.ban:len() <= 0 then
		return output(Translate("player_not_banned"), player)
	end

	exports.oxmysql:update("UPDATE users SET ban = '' WHERE identifier = ?", { result.identifier })

	local charName = result.firstname .. " " .. result.lastname

	output(Translate("player_unbanned", charName), player)

	sendToDiscord(
		"unban", 
		Translate("unban_log", GetPlayerName(player), charName, result.identifier)
		, 15105570
	)
end, false)

RegisterCommand("adminjail", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 2 then
		return output(Translate("invalid_syntax"), player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output(Translate("user_not_found"), player)
	end

	if getPlayerPunishment(xTarget, "comserv") then
		return output(Translate("player_in_comserv"), player)
	end

	if getPlayerPunishment(xTarget, "jail") then
		return output(Translate("player_in_jail"), player)
	end

	local time = tonumber(args[2])
	if not time then
		return output(Translate("time_not_number"), player)
	end
	time = math.abs(math.floor(time))

	table.remove(args, 1)
	table.remove(args, 1)

	local reason = table.concat(args, " ")
	local adminName = GetPlayerName(player)
	local currentTimestamp = os.time(os.date("!*t"))
	local jail = {
		count = 0,
		start = currentTimestamp,
		all = time,
		reason = reason,
		admin = {
			name = adminName,
			identifier = xPlayer.identifier,
		},
	}

	exports.oxmysql:update("UPDATE users SET jail = ? WHERE identifier = ?", { json.encode(jail), xTarget.identifier })

	TriggerClientEvent("updatePlayerPunishment", xTarget.source, "jail", jail)

	output(Translate("jail_allocated", reason), player)

	output(Translate("jail_assigned", adminName, time), xTarget.source)
	output(Translate("reason", reason), xTarget.source)

	sendToDiscord(
		"adminjail", 
		Translate("adminjail_log", adminName, GetPlayerName(xTarget.source), xTarget.getName(), time, reason)
		, 15105570
	)
end, false)

RegisterCommand("unjail", function(player, args)
	local xPlayer = ESX.GetPlayerFromId(player)
	if not xPlayer or not isAdmin(xPlayer) then
		return
	end

	if #args < 1 then
		return output(Translate("invalid_syntax"), player)
	end

	local xTarget = ESX.GetPlayerFromId(args[1])
	if not xTarget then
		return output(Translate("user_not_found"))
	end

	if not getPlayerPunishment(xTarget, "jail") then
		return output(Translate("player_not_in_jail"), player)
	end

	local adminName = GetPlayerName(player)

	exports.oxmysql:update("UPDATE users SET jail = '' WHERE identifier = ?", { xTarget.identifier })
	TriggerClientEvent("updatePlayerPunishment", xTarget.source, "jail", false)

	output(Translate("you_remove_jail"), player)
	output(Translate("removed_from_jail", adminName), xTarget.source)

	sendToDiscord(
		"unjail", 
		Translate("unjail_log", adminName, GetPlayerName(xTarget.source), xTarget.getName())
		, 15105570
	)

end)
