local self = {}

CreateThread(function()
	while not ESX.IsPlayerLoaded() do
		Wait(1)
	end

	Wait(500)

	CommunityService:init()

	AdminPanel:init()
	AdminPanel:setVisible(true) --TODO!
end)

CommunityService = {
	value = false,
	radiusBlip = nil,
	markerBlip = nil,
	marker = nil,
	objectNet = nil,

	init = function(self)
		ESX.TriggerServerCallback("requestPlayerComserv", function(value)
			if value then
				local playerPed = PlayerPedId()
				local playerCoords = GetEntityCoords(playerPed)

				local distance = #(COMSERV.coords - playerCoords)
				if distance > COMSERV.radius then
					SetEntityCoords(playerPed, COMSERV.coords)

					Wait(2500)
				end
			end

			self:update(value)
		end)

		RegisterNetEvent("updateComserv", function(data)
			self:update(data)
		end)
	end,

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
			while self.value do
				local playerPed = PlayerPedId()
				local playerCoords = GetEntityCoords(playerPed)

				local distance = #(COMSERV.coords - playerCoords)
				if distance > COMSERV.radius then
					SetEntityCoords(playerPed, COMSERV.coords)
					output("You cannot leave this place")
					self:nextTask()
					Wait(2500)
				end

				Wait(250)
			end
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

		local playerPed = PlayerPedId()
		local radius = COMSERV.radius * 0.7
		local posX, posY =
			COMSERV.coords.x + math.random(-radius, radius), COMSERV.coords.y + math.random(-radius, radius)
		local _, posZ = GetGroundZFor_3dCoord(posX, posY, 9999.0, true)

		self.marker = vector3(posX, posY, posZ)
		self.markerBlip = AddBlipForCoord(self.marker)
		SetBlipSprite(self.markerBlip, COMSERV.blip and COMSERV.blip.icon or 1)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentSubstringPlayerName(COMSERV.blip and COMSERV.blip.name or "")
		EndTextCommandSetBlipName(self.markerBlip)

		CreateThread(function()
			local r, g, b, a = table.unpack(COMSERV.marker.color or { 200, 150, 0, 150 })

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

			ESX.TriggerServerCallback("decreaseComservCount", function(value)
				CommunityService:update(value)
			end)
		end)
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
		RegisterNUICallback("closeAdminPanel", function()
			self:setVisible(false)
		end)

		RegisterNUICallback("removeUser", function(data, cb)
			print(ESX.DumpTable(data))
			cb({ users = 1 })
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
			end, data.identifier)
		end)
	end,
}
AdminPanel.__index = AdminPanel
