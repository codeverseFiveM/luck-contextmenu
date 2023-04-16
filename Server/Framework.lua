if Config.EnableDefaultOptions and exports['qb-core'] then

    local QBCore = exports['qb-core']:GetCoreObject()

    RegisterNetEvent('luck-contextmenu:server:SetFastActions', function(fastactions, type)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local newFastActions = fastactions

        if type then
            newFastActions = Player.PlayerData.metadata["fastactions"]
            newFastActions[type] = fastactions
        end

        Player.Functions.SetMetaData("fastactions", newFastActions)
    end)

end