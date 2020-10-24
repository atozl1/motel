if Config.CreateTableInDatabase then
    MySQL.ready(function()
        local sqlTasks = {}

        table.insert(sqlTasks, function(callback)        
            MySQL.Async.execute([[
                CREATE TABLE IF NOT EXISTS `characters_motels` (
                  `userIdentifier` varchar(50) NOT NULL,
                  `motelData` longtext NOT NULL
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
            ]], {
                callback(true)
            }, function(rowsChanged)
                ESX.Trace("Refreshed motels in database.")
            end)
        end)

        table.insert(sqlTasks, function(callback)     
            MySQL.Async.execute([[
                CREATE TABLE IF NOT EXISTS `characters_storages` (
                `storageId` varchar(255) NOT NULL,
                `storageData` longtext NOT NULL,
                PRIMARY KEY (`storageId`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1; 
            ]], {
                callback(true)
            }, function(rowsChanged)
                ESX.Trace("Refreshed storages in database.")
            end)
        end)

        Async.parallel(sqlTasks, function(responses)
            ESX.Trace("SQL Tasks finished.")
        end)
    end)
end