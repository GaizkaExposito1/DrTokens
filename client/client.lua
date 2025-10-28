local QBCore = exports['qb-core']:GetCoreObject()

-- Variables locales
local playerTokens = 0
local isLoggedIn = false

-- Event cuando el jugador está listo
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
    -- Solicitar tokens actuales al servidor
    TriggerServerEvent('drtokens:server:getTokens')
end)

-- Event cuando el jugador se desconecta
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
    playerTokens = 0
end)

-- Event para recibir los tokens del servidor
RegisterNetEvent('drtokens:client:receiveTokens', function(tokens)
    playerTokens = tokens
    
    -- Notificar a origen_pausemenu si está disponible
    if GetResourceState('origen_pausemenu') == 'started' then
        exports['origen_pausemenu']:UpdateTokensDisplay()
    end
end)

-- Event cuando se dan tokens por recompensa (notificar al menu)
RegisterNetEvent('drtokens:client:tokensUpdated', function(newAmount)
    playerTokens = newAmount
    
    -- Actualizar en origen_pausemenu si está disponible
    if GetResourceState('origen_pausemenu') == 'started' then
        exports['origen_pausemenu']:UpdateTokensDisplay()
    end
    
    -- Mostrar animación si el menú está abierto
    TriggerEvent('drtokens:client:showTokenAnimation', newAmount)
end)

-- Función para obtener tokens localmente (para HUD u otros scripts)
function GetLocalTokens()
    return playerTokens
end

-- Export para que otros scripts puedan obtener los tokens
exports('GetLocalTokens', GetLocalTokens)

-- Función para actualizar tokens desde el servidor
function UpdateTokensFromServer()
    if isLoggedIn then
        TriggerServerEvent('drtokens:server:getTokens')
    end
end

-- Export para actualizar tokens
exports('UpdateTokens', UpdateTokensFromServer)

-- Comando local para mostrar información
RegisterCommand('tokeninfo', function()
    if isLoggedIn then
        QBCore.Functions.Notify('DrTokens - Sistema de recompensas por tiempo', 'primary', 5000)
        QBCore.Functions.Notify('Recibes tokens cada hora que juegas sin desconectarte', 'primary', 5000)
        QBCore.Functions.Notify('Usa /mytokens para ver tu cantidad actual', 'primary', 3000)
    else
        QBCore.Functions.Notify('Debes estar logueado para usar este comando', 'error')
    end
end)

-- Event para mostrar notificaciones especiales
RegisterNetEvent('drtokens:client:showSpecialNotification', function(message, type, duration)
    QBCore.Functions.Notify(message, type or 'primary', duration or 3000)
end)

-- Event para mostrar animación de tokens recibidos en el menú
RegisterNetEvent('drtokens:client:showTokenAnimation', function(amount)
    -- Solo si origen_pausemenu está disponible y el menú está abierto
    if GetResourceState('origen_pausemenu') == 'started' then
        -- Trigger para mostrar animación en la UI
        SendNUIMessage({
            action = "showDrTokensNotification",
            message = "Has recibido " .. amount .. " DrTokens!",
            type = "success",
            duration = 3000
        })
    end
end)

-- Export para que origen_pausemenu pueda obtener tokens actualizados
exports('GetCurrentTokens', function()
    return playerTokens
end)

-- Export para forzar actualización de tokens
exports('ForceTokenUpdate', function()
    if isLoggedIn then
        TriggerServerEvent('drtokens:server:getTokens')
    end
end)

print('[DrTokens] Cliente iniciado correctamente')