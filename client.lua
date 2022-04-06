local Comserv = {}

CreateThread(function()
	while not ESX.IsPlayerLoaded() do
		Wait(1)
	end

	Wait(500)

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

		updateComserv(value)
	end)
end)

function updateComserv(value)
	if value then
		applyComserv(value)
	else
		clearComserv()
	end
end
RegisterNetEvent("updateComserv", updateComserv)

function applyComserv(value)
	if type(value) ~= "table" then
		return
	end

	Comserv = value

	if not DoesBlipExist(Comserv.radiusBlip) then
		local blip = AddBlipForRadius(COMSERV.coords, COMSERV.radius + 0.0)
		SetBlipColour(blip, 1)
		SetBlipAlpha(blip, 150)

		Comserv.radiusBlip = blip
	end

	SendNUIMessage({ comserv = Comserv })

	CreateThread(function()
		while Comserv do
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local distance = #(COMSERV.coords - playerCoords)
			if distance > COMSERV.radius then
				SetEntityCoords(playerPed, COMSERV.coords)
				output("You cannot leave this place")
				makeNextJob()
				Wait(2500)
			end

			Wait(250)
		end
	end)

	if not Comserv.marker then
		makeNextJob()
	end
end

function clearComserv()
	if DoesBlipExist(Comserv.radiusBlip) then
		RemoveBlip(Comserv.radiusBlip)
	end

	deleteJobMarker()

	Comserv = false
	SendNUIMessage({ hideComserv = true })
end

function makeNextJob()
	deleteJobMarker()

	local playerPed = PlayerPedId()
	local radius = COMSERV.radius * 0.7
	local posX, posY = COMSERV.coords.x + math.random(-radius, radius), COMSERV.coords.y + math.random(-radius, radius)
	local _, posZ = GetGroundZFor_3dCoord(posX, posY, 9999.0, true)

	Comserv.marker = vector3(posX, posY, posZ)
	Comserv.markerBlip = AddBlipForCoord(Comserv.marker)
	SetBlipSprite(Comserv.markerBlip, COMSERV.blip and COMSERV.blip.icon or 1)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(COMSERV.blip and COMSERV.blip.name or "")
	EndTextCommandSetBlipName(Comserv.markerBlip)

	CreateThread(function()
		local r, g, b, a = table.unpack(COMSERV.marker.color or { 200, 150, 0, 150 })

		while Comserv.marker do
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local distance = #(playerCoords - Comserv.marker)
			if distance <= (COMSERV.marker.size or 1) then
				ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to start work")
				if IsControlJustPressed(0, 38) then
					startTaskProcess()
				end
			end

			DrawMarker(
				COMSERV.marker.typ or 1,
				Comserv.marker,
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
end

function deleteJobMarker()
	if DoesBlipExist(Comserv.markerBlip) then
		RemoveBlip(Comserv.markerBlip)
	end
	Comserv.markerBlip = nil
	Comserv.marker = nil
end

function startTaskProcess()
	deleteJobMarker()

	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)

	local object = CreateObject(COMSERV.model, playerCoords - vector3(0, 0, 3), true, true, true)
	Comserv.objectNet = ObjToNet(object)

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
		local object = NetToObj(Comserv.objectNet)
		if not DoesEntityExist(object) then
			return
		end

		DetachEntity(object, true, true)
		DeleteEntity(object)
		Comserv.objectNet = nil
		ClearPedTasks(PlayerPedId())

		ESX.TriggerServerCallback("decreaseComservCount", function(value)
			updateComserv(value)
		end)
	end)
end
