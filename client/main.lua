ESX = nil

cachedData = {
	["motels"] = {},
	["storages"] = {},
	["insideMotel"] = false
}

Citizen.CreateThread(function()
	while not ESX do
		--Fetching esx library, due to new to esx using this.

		TriggerEvent("esx:getSharedObject", function(library) 
			ESX = library 
		end)

		Citizen.Wait(25)
	end

	if ESX.IsPlayerLoaded() then
		Init()
	end

	AddTextEntry("Instructions", Config.HelpTextMessage)
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(playerData)
	ESX.PlayerData = playerData

	Init()
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(newJob)
	ESX.PlayerData["job"] = newJob
end)

RegisterNetEvent("motel:eventHandler")
AddEventHandler("motel:eventHandler", function(response, eventData)
	if response == "update_motels" then
		cachedData["motels"] = eventData
	elseif response == "update_storages" then
		cachedData["storages"][eventData["storageId"]] = eventData["newTable"]

		if ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), "main_storage_menu_" .. eventData["storageId"]) then
			local openedMenu = ESX.UI.Menu.GetOpened("default", GetCurrentResourceName(), "main_storage_menu_" .. eventData["storageId"])

			if openedMenu then
				openedMenu.close()

				OpenStorage(eventData["storageId"])
			end
		end
	elseif response == "invite_player" then
		if eventData["player"]["source"] == GetPlayerServerId(PlayerId()) then
			Citizen.CreateThread(function()
				local startedInvite = GetGameTimer()

				cachedData["invited"] = true

				while GetGameTimer() - startedInvite < 7500 do
					Citizen.Wait(0)

					ESX.ShowHelpNotification("Odana davet ettin, " .. eventData["motel"]["room"] .. ". ~INPUT_DETONATE~ tuşuna basarak gir.")

					if IsControlJustPressed(0, 47) then
						EnterMotel(eventData["motel"])

						break
					end
				end

				cachedData["invited"] = false
			end)
		end
	elseif response == "knock_motel" then
		local currentInstance = DecorGetInt(PlayerPedId(), "currentInstance")

		if currentInstance and currentInstance == eventData["uniqueId"] then
			ESX.ShowNotification("Birileri kapını tıkladı.")
		end
	else
		-- print("Wrong event handler.")
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(50)

	cachedData["lastCheck"] = GetGameTimer() - 4750

	local pinkCageBlip = AddBlipForCoord(Config.LandLord["position"])

	SetBlipSprite(pinkCageBlip, 475)
	SetBlipScale(pinkCageBlip, 0.9)
	SetBlipColour(pinkCageBlip, 49)
	SetBlipAsShortRange(pinkCageBlip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Pink Cage Motel")
	EndTextCommandSetBlipName(pinkCageBlip)

	while true do
		local sleepThread = 500

		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)

		local yourMotel = GetPlayerMotel()

		for motelRoom, motelPos in ipairs(Config.MotelsEntrances) do
			local dstCheck = GetDistanceBetweenCoords(pedCoords, motelPos, true)
			local dstRange = yourMotel and (yourMotel["room"] == motelRoom and 35.0 or 3.0) or 3.0

			if dstCheck <= dstRange then
				sleepThread = 5

				DrawScriptMarker({
					["type"] = 2,
					["pos"] = motelPos,
					["r"] = 155,
					["g"] = 155,
					["b"] = 155,
					["sizeX"] = 0.3,
					["sizeY"] = 0.3,
					["sizeZ"] = 0.3,
					["rotate"] = true
				})

				if dstCheck <= 0.9 then
					local displayText = yourMotel and (yourMotel["room"] == motelRoom and "[~g~E~s~] Gir" or "") or ""; displayText = displayText .. " [~g~H~s~] Menü"

					if not cachedData["invited"] then
						DrawScriptText(motelPos - vector3(0.0, 0.0, 0.20), displayText)
					end

					if IsControlJustPressed(0, 38) then
						if yourMotel then
							if yourMotel["room"] == motelRoom then
								EnterMotel(yourMotel)
							end
						end
					elseif IsControlJustPressed(0, 74) then
						OpenMotelRoomMenu(motelRoom)
					end
				end
			end
		end

		local dstCheck = GetDistanceBetweenCoords(pedCoords, Config.LandLord["position"], true)

		if dstCheck <= 3.0 then
			sleepThread = 5
			
			DrawScriptMarker({
					["type"] = 2,
					["pos"] = motelPos,
					["r"] = 155,
					["g"] = 155,
					["b"] = 155,
					["sizeX"] = 0.3,
					["sizeY"] = 0.3,
					["sizeZ"] = 0.3,
					["rotate"] = true
				})

			if dstCheck <= 0.9 then
				local displayText = "[~g~E~s~] Motel Resepsiyon"
				
				if not cachedData["purchasing"] then
					DrawScriptText(Config.LandLord["position"], displayText)
				end

				if IsControlJustPressed(0, 38) then
					OpenLandLord()
				end
			end
		end

		Citizen.Wait(sleepThread)
	end
end)