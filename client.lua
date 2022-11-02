CommunityService = {
	value = false,
	radiusBlip = nil,
	markerBlip = nil,
	marker = nil,
	objectNet = nil,

	update = function(self, value)
		if value then
			self:apply(value)
		else
			self:clear()
		end
	end,

	apply = function(self, value)
		if type(value) ~= "table" then
			return
		end

		self.value = value

		if not DoesBlipExist(self.radiusBlip) then
			local blip = AddBlipForRadius(COMSERV.coords, COMSERV.radius + 0.0)
			SetBlipColour(blip, 1)
			SetBlipAlpha(blip, 150)

			self.radiusBlip = blip
		end

		SendNUIMessage({ comserv = self.value })

		CreateThread(function()
			local lastTick = GetGameTimer()

			while self.value do
				local playerPed = PlayerPedId()
				local playerCoords = GetEntityCoords(playerPed)

				SetCurrentPedWeapon(playerPed, GetHashKey("weapon_unarmed"), true)

				local distance = #(COMSERV.coords - playerCoords)
				if distance > COMSERV.radius then
					SetEntityCoords(playerPed, COMSERV.coords)
					output("You cannot leave this place")
					self:nextTask()
					Wait(2500)
				end

				if lastTick + 1000 < GetGameTimer() then 
					SendNUIMessage({ comserv = self.value })
					lastTick = GetGameTimer()
				end

				Wait(250)
			end
		end)

		CreateThread(function()
			self:disabler()
		end)

		if not self.marker then
			self:nextTask()
		end
	end,

	clear = function(self)
		if DoesBlipExist(self.radiusBlip) then
			RemoveBlip(self.radiusBlip)
		end

		self:deleteTask()

		self.value = false
		SendNUIMessage({ comserv = false })
	end,

	nextTask = function(self)
		self:deleteTask()

		Wait(1)

		local radius = math.ceil(COMSERV.radius * 0.7)
		local posX, posY =
        COMSERV.coords.x + math.random(-radius, radius), COMSERV.coords.y + math.random(-radius, radius)
		local _, posZ = GetGroundZFor_3dCoord(posX, posY, 9999.0, true)

		self.marker = vector3(posX, posY, posZ)


		if DoesBlipExist(self.markerBlip) then
			RemoveBlip(self.markerBlip)
		end
		self.markerBlip = AddBlipForCoord(self.marker)
		SetBlipSprite(self.markerBlip, COMSERV.blip and COMSERV.blip.icon or 1)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentSubstringPlayerName(COMSERV.blip and COMSERV.blip.name or "")
		EndTextCommandSetBlipName(self.markerBlip)


		CreateThread(function()
			local r, g, b, a = table.unpack(COMSERV.marker.color or { 200, 150, 0, 150 })
			local lastTick = GetGameTimer()

			while self.value and self.marker do
				local playerPed = PlayerPedId()
				local playerCoords = GetEntityCoords(playerPed)

				local distance = #(playerCoords - self.marker)
				if distance <= (COMSERV.marker.size or 1) then
					ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to start work")
					if IsControlJustPressed(0, 38) then
						self:startTaskProcess()
					end
				end

				local currentTick = GetGameTimer()
				if lastTick + 2000 < currentTick then 
					local _, posZ = GetGroundZFor_3dCoord(self.marker.x, self.marker.y, 9999.0, true)

          self.marker = vector3(self.marker.x, self.marker.y, posZ)
					SetBlipCoords(self.markerBlip, self.marker)
					lastTick = currentTick
				end
				
				if IsSphereVisible(self.marker, 0.0099999998) then
					DrawMarker(
						COMSERV.marker.typ or 1,
						self.marker,
						vector3(0, 0, 0),
						vector3(0, 0, 0),
						vector3((COMSERV.marker.size or 1), (COMSERV.marker.size or 1), (COMSERV.marker.size or 1)),
						r or 200,
						g or 150,
						b or 0,
						a or 150,
						COMSERV.marker.upDown or false,
						true,
						2,
						false,
						nil,
						nil,
						false
					)
					Wait(0)
				else 
					Wait(250)
				end
			end
		end)
	end,

	deleteTask = function(self)
		if DoesBlipExist(self.markerBlip) then
			RemoveBlip(self.markerBlip)
		end
		self.markerBlip = nil
		self.marker = nil
	end,

	startTaskProcess = function(self)
		self:deleteTask()

		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)

		local object = CreateObject(COMSERV.model, playerCoords - vector3(0, 0, 3), true, true, true)
		self.objectNet = ObjToNet(object)
		FreezeEntityPosition(PlayerPedId(), true)

		ESX.Streaming.RequestAnimDict("amb@world_human_janitor@male@idle_a", function()
			TaskPlayAnim(
				playerPed,
				"amb@world_human_janitor@male@idle_a",
				"idle_a",
				8.0,
				-8.0,
				-1,
				0,
				0,
				false,
				false,
				false
			)
			AttachEntityToEntity(
				object,
				playerPed,
				GetPedBoneIndex(playerPed, 28422),
				-0.005,
				0.0,
				0.0,
				360.0,
				360.0,
				0.0,
				true,
				true,
				false,
				true,
				false,
				true
			)
		end)

		CreateThread(function()
			Wait(10000)
			local object = NetToObj(self.objectNet)
			if not DoesEntityExist(object) then
				return
			end

			DetachEntity(object, true, true)
			DeleteEntity(object)
			self.objectNet = nil
			ClearPedTasks(PlayerPedId())
			FreezeEntityPosition(PlayerPedId(), false)

			ESX.TriggerServerCallback("decreaseComservCount", function(value)
				CommunityService:update(value)
			end)
		end)
	end,

	disabler = function(self)
		while self.value do
			DisableControlAction(0, 24, true)
			DisableControlAction(0, 25, true)
			Wait(0)
		end
	end,
}
CommunityService.__index = CommunityService

AdminPanel = {
	visible = false,

	setVisible = function(self, state)
		self.visible = state
		SendNUIMessage({ adminPanel = state })
		SetNuiFocus(self.visible, self.visible)
	end,

	init = function(self)
		RegisterNetEvent("togglePunishmentsAdmin", function()
			self:setVisible(not self.visible)
		end)

		RegisterNUICallback("closeAdminPanel", function()
			self:setVisible(false)
		end)

		RegisterNUICallback("removeUser", function(data, cb)
			ESX.TriggerServerCallback("removeUserFromPunishment", function(users)
				cb({ users = users })
			end, data.selectedTab, data.identifier)
		end)

		RegisterNUICallback("requestUsers", function(data, cb)
			if not data.selectedTab then
				return cb({ error = "Users not found!" })
			end

			ESX.TriggerServerCallback("requestPunishmentUsers", function(users)
				if not users then
					return cb({ error = "User loading error!" })
				end

				cb({ users = users })
			end, data.selectedTab)
		end)

		RegisterNUICallback("requestUserData", function(data, cb)
			if not data.identifier then
				return cb({ error = "User not found!" })
			end

			ESX.TriggerServerCallback("requestPunishmentUserData", function(error, userData)
				if error then
					return cb({ error = error })
				end

				cb({ userInfo = userData })
			end, data.selectedTab, data.identifier)
		end)
	end,
}
AdminPanel.__index = AdminPanel

Jail = {
	data = false,
	timer = false,

	update = function(self, data, isLogin)
		if isLogin then 
			SendNUIMessage({ jail = false })
			return
		end

		SendNUIMessage({ jail = data })

		if not data then
			return self:removePlayer()
		end

		self.data = false
		Wait(5)

		self:addPlayer(data)
	end,

	addPlayer = function(self, data)
		self.data = data

		local playerPed = PlayerPedId()

		if not self.coords then
			self.coords = JAIL.cells[math.random(1, #JAIL.cells)]
		end

		local playerCoords = GetEntityCoords(playerPed)
		if #(playerCoords - self.coords) > JAIL.distance then
			SetEntityCoords(playerPed, self.coords)
		end

		CreateThread(function()
			self:distanceChecker()
		end)

		CreateThread(function()
			self:disabler()
		end)

		CreateThread(function()
			Wait(1000 * 60)

			if Jail.data then
				ESX.TriggerServerCallback("increaseAdminJailTime", function(data)
					Jail:update(data)
				end)
			end
		end)
	end,

	removePlayer = function(self)
		self.data = false

		Wait(150)

		SetPlayerInvincible(PlayerId(), false)

		local playerPed = PlayerPedId()

		SetEntityCoords(playerPed, JAIL.outCoords)

		SendNUIMessage({ jail = false })
	end,

	distanceChecker = function(self)
		local lastTick = GetGameTimer()

		while self.data do
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local distance = #(playerCoords - self.coords)
			if distance >= JAIL.distance then
				SetEntityCoords(playerPed, self.coords)
				Wait(2500)
			end

			SetPlayerInvincible(PlayerId(), true)
			SetCurrentPedWeapon(playerPed, GetHashKey("weapon_unarmed"), true)


			if lastTick + 1000 < GetGameTimer() then 
				SendNUIMessage({ jail = self.data })
				lastTick = GetGameTimer()
			end

			Wait(250)
		end
	end,

	disabler = function(self)
		while self.data do
			DisableControlAction(0, 24, true)
			DisableControlAction(0, 25, true)
			Wait(0)
		end
	end,
}
Jail.__index = Jail

RegisterNetEvent("updatePlayerPunishment", function(name, data)
	if name == "clear" then 
		CommunityService:update(false)
		Jail:update(false, true)
		return
	end

	if name == "comserv" then 
		if data then
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local distance = #(COMSERV.coords - playerCoords)
			if distance > COMSERV.radius then
				SetEntityCoords(playerPed, COMSERV.coords)

				Wait(2500)
			end
		end

		CommunityService:update(data)
	elseif name == "jail" then 
		Jail:update(data)
	end
end)

-- Add chat suggestions
CreateThread(function()
	AdminPanel:init()
	
	TriggerEvent('chat:addSuggestion', '/punishments', 'Open Punishment List (Comserv, Jail, Ban)')

	TriggerEvent('chat:addSuggestion', '/comserv', 'Put player to community service', {
    { name = "id", help = "Target Player ID" },
    { name = "count", help = "Tasks Count" },
    { name = "reason", help = "Reason" },
	})
	TriggerEvent('chat:addSuggestion', '/removecomserv', 'Remove player from community service', {
    { name = "id", help = "Target Player ID" },
	})

	TriggerEvent('chat:addSuggestion', '/ban', 'Ban Player', {
    { name = "id", help = "Target Player ID" },
    { name = "days", help = "Days (0 - Infinity)" },
    { name = "reason", help = "Reason" },
	})
	TriggerEvent('chat:addSuggestion', '/unban', 'Remove player ban', {
    { name = "name", help = "Identifier / Character Name" },
	})

	TriggerEvent('chat:addSuggestion', '/adminjail', 'Put player to jail', {
    { name = "id", help = "Target Player ID" },
    { name = "minutes", help = "Minutes" },
    { name = "reason", help = "Reason" },
	})
	TriggerEvent('chat:addSuggestion', '/unjail', 'Remove player from jail', {
    { name = "id", help = "Target Player ID" },
	})
end)
