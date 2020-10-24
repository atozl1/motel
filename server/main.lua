ESX = nil

cachedData = {
    ["motels"] = {},
    ["storages"] = {},
    ["names"] = {}
}

TriggerEvent("esx:getSharedObject", function(library) 
	ESX = library 
end)

RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(src)
    local player = ESX.GetPlayerFromId(src)

    GetCharacterName(player)
end)

RegisterNetEvent("esx:playerDropped")
AddEventHandler("esx:playerDropped", function(src)
    local player = ESX.GetPlayerFromId(src)

    if cachedData["names"][player["identifier"]] then
        cachedData["names"][player["identifier"]] = nil
    end
end)

MySQL.ready(function()
    local sqlTasks = {}
    
    local firstSqlQuery = [[
        SELECT
            userIdentifier, motelData
        FROM
            characters_motels
    ]]

    table.insert(sqlTasks, function(callback)    
        MySQL.Async.fetchAll(firstSqlQuery, {
            
        }, function(response)
            for motelIndex, motelData in ipairs(response) do
                local decodedData = json.decode(motelData["motelData"])
    
                if not cachedData["motels"][decodedData["room"]] then
                    cachedData["motels"][decodedData["room"]] = {}
                    cachedData["motels"][decodedData["room"]]["rooms"] = {}
                end
    
                table.insert(cachedData["motels"][decodedData["room"]]["rooms"], {
                    ["motelData"] = decodedData
                })
            end
            
            callback(true)
        end)
    end)

    local secondSqlQuery = [[
        SELECT
            storageId, storageData
        FROM
            characters_storages
    ]]

    table.insert(sqlTasks, function(callback)    
        MySQL.Async.fetchAll(secondSqlQuery, {
            
        }, function(response)
            for storageIndex, storageData in ipairs(response) do
                local decodedData = json.decode(storageData["storageData"])

                if not cachedData["storages"][storageData["storageId"]] then
                    cachedData["storages"][storageData["storageId"]] = {}
                    cachedData["storages"][storageData["storageId"]]["items"] = {}
                end

                cachedData["storages"][storageData["storageId"]] = decodedData
            end

            callback(true)
        end)
    end)

    Async.parallel(sqlTasks, function(responses)
        -- print(json.encode(responses))
    end)

    GetCharacterNames()
end)

RegisterServerEvent("motel:globalEvent")
AddEventHandler("motel:globalEvent", function(options)
    TriggerClientEvent("motel:eventHandler", -1, options["event"] or "none", options["data"] or nil)
end)

ESX.RegisterServerCallback("motel:fetchMotels", function(source, callback)
    local player = ESX.GetPlayerFromId(source)

    if player then
        callback(cachedData["motels"], cachedData["storages"], cachedData["names"][player["identifier"]] or nil)
    else
        callback(false)
    end
end)

ESX.RegisterServerCallback("motel:addItemToStorage", function(source, callback, newTable, newItem, storageId)
    local player = ESX.GetPlayerFromId(source)

    if player then
        cachedData["storages"][storageId] = newTable

        if newItem["type"] == "item" then
            player.removeInventoryItem(newItem["name"], newItem["count"])
        elseif newItem["type"] == "weapon" then
            player.removeWeapon(newItem["name"], newItem["count"])
        elseif newItem["type"] == "black_money" then
            player.removeAccountMoney("black_money", newItem["count"])
        end

        TriggerClientEvent("motel:eventHandler", -1, "update_storages", {
            ["newTable"] = newTable,
            ["storageId"] = storageId
        })

        UpdateStorageDatabase(storageId, newTable)

        callback(true)
    else
        callback(false)
    end
end)

ESX.RegisterServerCallback("motel:takeItemFromStorage", function(source, callback, newTable, newItem, storageId)
    local player = ESX.GetPlayerFromId(source)

    if player then
        cachedData["storages"][storageId] = newTable

        if newItem["type"] == "item" then
            player.addInventoryItem(newItem["name"], newItem["count"])
        elseif newItem["type"] == "weapon" then
            player.addWeapon(newItem["name"], newItem["count"])
        elseif newItem["type"] == "black_money" then
            player.addAccountMoney("black_money", newItem["count"])
        end

        TriggerClientEvent("motel:eventHandler", -1, "update_storages", {
            ["newTable"] = newTable,
            ["storageId"] = storageId
        })

        UpdateStorageDatabase(storageId, newTable)

        callback(true)
    else
        callback(false)
    end
end)

ESX.RegisterServerCallback("motel:retreivePlayers", function(source, callback, playersSent)
	local player = ESX.GetPlayerFromId(source)

	if #playersSent <= 0 then
		callback(false)

		return
	end

	if player then
		local newPlayers = {}

		for playerIndex = 1, #playersSent do
			local player = ESX.GetPlayerFromId(playersSent[playerIndex])

            local characterNames = cachedData["names"][player["identifier"]]

			if player then
				if player["source"] ~= source then
					table.insert(newPlayers, {
						["firstname"] = characterNames["firstname"] or GetPlayerName(source),
						["lastname"] = characterNames["lastname"] or GetPlayerName(source),
						["source"] = player["source"]
					})
				end
			end
		end

		callback(newPlayers)
	else
		callback(false)
	end
end)

ESX.RegisterServerCallback("motel:buyMotel", function(source, callback, room)
	local player = ESX.GetPlayerFromId(source)

    if player then
        if player.getMoney() >= Config.MotelPrice then
            player.removeMoney(Config.MotelPrice)
        elseif player.getAccount("bank")["money"] >= Config.MotelPrice then
            player.removeAccountMoney("bank", Config.MotelPrice)
        else
            return callback(false)
        end

        CreateMotel(source, room, function(confirmed)
            if confirmed then
                callback(true)
            else
                callback(false)
            end
        end)
	else
		callback(false)
	end
end)

ESX.RegisterServerCallback("motel:getPlayerDressing", function(source, cb)
    local xPlayer  = ESX.GetPlayerFromId(source)
  
    TriggerEvent("esx_datastore:getDataStore", "property", xPlayer.identifier, function(store)
        local count = store.count("dressing")
        local labels = {}
  
        for i=1, count, 1 do
            local entry = store.get("dressing", i)
            table.insert(labels, entry.label)
        end
  
        cb(labels)
    end)
end)
  
ESX.RegisterServerCallback("motel:getPlayerOutfit", function(source, cb, num)
    local xPlayer  = ESX.GetPlayerFromId(source)

    TriggerEvent("esx_datastore:getDataStore", "property", xPlayer.identifier, function(store)
        local outfit = store.get("dressing", num)
        cb(outfit.skin)
    end)
end)