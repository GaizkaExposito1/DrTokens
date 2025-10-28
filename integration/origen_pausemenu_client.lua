-- INTEGRACIÓN CON ORIGEN_PAUSEMENU - PARTE CLIENTE
-- Añadir este código al archivo client.lua de origen_pausemenu

-- Función para obtener DrTokens
local function GetDrTokens()
    local promise = promise.new()
    
    QBCore.Functions.TriggerCallback('drtokens:server:getPlayerTokens', function(tokens)
        promise:resolve(tokens)
    end)
    
    return Citizen.Await(promise)
end

-- Función para obtener información completa de DrTokens
local function GetDrTokensInfo()
    local promise = promise.new()
    
    QBCore.Functions.TriggerCallback('drtokens:server:getPlayerInfo', function(data)
        promise:resolve(data)
    end)
    
    return Citizen.Await(promise)
end

-- Event para actualizar tokens cuando cambien
RegisterNetEvent('drtokens:client:updateTokensInMenu', function()
    if isMenuOpen then -- Variable del origen_pausemenu que indica si está abierto
        local tokens = GetDrTokens()
        SendNUIMessage({
            action = "updateDrTokens",
            tokens = tokens
        })
    end
end)

-- Export para que nuestro script de DrTokens pueda actualizar el menu
exports('UpdateTokensDisplay', function()
    TriggerEvent('drtokens:client:updateTokensInMenu')
end)

-- Callback NUI para obtener tokens (llamado desde el HTML/JS)
RegisterNUICallback('getDrTokens', function(data, cb)
    QBCore.Functions.TriggerCallback('drtokens:server:getPlayerInfo', function(tokenData)
        SendNUIMessage({
            action = "updatePlayerStats",
            data = {
                drTokens = tokenData.tokens,
                drTokensLastReward = tokenData.lastReward
            }
        })
    end)
    cb('ok')
end)

--[[
    INTEGRACIÓN EN EL ORIGEN_PAUSEMENU:
    
    1. Busca la función que se ejecuta cuando se abre el menú
    2. Añade esta línea dentro de esa función:
    
    local drTokens = GetDrTokens()
    local drTokensInfo = GetDrTokensInfo()
    
    -- Enviar al NUI
    SendNUIMessage({
        action = "updatePlayerStats",
        data = {
            -- ... otras estadísticas existentes del jugador
            drTokens = drTokens,
            drTokensLastReward = drTokensInfo.lastReward
        }
    })
    
    3. O si prefieres, puedes llamar directamente:
    TriggerEvent('drtokens:client:updateTokensInMenu')
]]