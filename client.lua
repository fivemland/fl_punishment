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

	local blip = AddBlipForRadius(COMSERV.coords, COMSERV.radius + 0.0)
	SetBlipColour(blip, 1)
	SetBlipAlpha(blip, 150)

	Comserv.blip = blip

	SendNUIMessage({ comserv = Comserv })

	CreateThread(function()
		while Comserv do
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)

			local distance = #(COMSERV.coords - playerCoords)
			if distance > COMSERV.radius then
				SetEntityCoords(playerPed, COMSERV.coords)
				output("You cannot leave this place")
				Wait(2500)
			end

			Wait(250)
		end
	end)
end

function clearComserv()
	if DoesBlipExist(Comserv.blip) then
		RemoveBlip(Comserv.blip)
	end

	Comserv = false
	SendNUIMessage({ hideComserv = true })
end
