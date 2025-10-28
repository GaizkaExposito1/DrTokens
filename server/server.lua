local QBCore = exports['qb-core']:GetCoreObject()

-- Tabla para llevar control del tiempo de jugadores
local PlayerTimeTracking = {}

-- Función para inicializar la tabla de tokens de un jugador
local function InitializePlayerTokens(citizenid)
    MySQL.query('SELECT * FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
        if not result[1] then
            MySQL.insert('INSERT INTO player_drtokens (citizenid, tokens) VALUES (?, ?)', {citizenid, 0})
        end
    end)
end

-- Función para obtener los tokens de un jugador
local function GetPlayerTokens(citizenid, cb)
    MySQL.query('SELECT tokens FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
        if result[1] then
            cb(result[1].tokens)
        else
            cb(0)
        end
    end)
end

-- Función para añadir tokens a un jugador
local function AddTokensToPlayer(citizenid, amount)
    MySQL.query('UPDATE player_drtokens SET tokens = tokens + ? WHERE citizenid = ?', {amount, citizenid}, function(affectedRows)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO player_drtokens (citizenid, tokens) VALUES (?, ?)', {citizenid, amount})
        end
    end)
end

-- Función para retirar tokens de un jugador
local function RemoveTokensFromPlayer(citizenid, amount)
    MySQL.query('SELECT tokens FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
        if result[1] then
            local currentTokens = result[1].tokens
            local newAmount = math.max(0, currentTokens - amount)
            MySQL.query('UPDATE player_drtokens SET tokens = ? WHERE citizenid = ?', {newAmount, citizenid})
        end
    end)
end

-- Función para dar recompensa por hora
local function GiveHourlyReward(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local baseReward = Config.HourlyReward
    local totalReward = baseReward
    local bonusMessages = {}
    
    -- Calcular bonificaciones si están habilitadas
    if Config.Bonuses.Enabled then
        -- Bonificación de fin de semana
        if Config.Bonuses.Weekend.enabled then
            local dayOfWeek = tonumber(os.date('%w')) -- 0 = Domingo, 6 = Sábado
            if dayOfWeek == 0 or dayOfWeek == 6 then
                local weekendBonus = math.floor(baseReward * (Config.Bonuses.Weekend.multiplier - 1))
                totalReward = totalReward + weekendBonus
                table.insert(bonusMessages, 'Bonificación fin de semana: +' .. weekendBonus)
            end
        end
        
        -- Bonificación por horas consecutivas
        if Config.Bonuses.ConsecutiveHours.enabled and PlayerTimeTracking[src] then
            local currentTime = os.time()
            local totalTimeToday = currentTime - PlayerTimeTracking[src].startTime
            local hoursToday = math.floor(totalTimeToday / 3600)
            
            for _, bonus in ipairs(Config.Bonuses.ConsecutiveHours.bonuses) do
                if hoursToday >= bonus.hours then
                    -- Verificar si ya recibió esta bonificación hoy
                    local today = os.date('%Y-%m-%d')
                    local bonusKey = 'consecutive_' .. bonus.hours .. '_' .. today
                    
                    -- Solo dar bonificación si no la ha recibido hoy
                    if not PlayerTimeTracking[src][bonusKey] then
                        totalReward = totalReward + bonus.bonus
                        PlayerTimeTracking[src][bonusKey] = true
                        table.insert(bonusMessages, 'Bonificación ' .. bonus.hours .. 'h consecutivas: +' .. bonus.bonus)
                    end
                end
            end
        end
    end
    
    AddTokensToPlayer(citizenid, totalReward)
    
    -- Actualizar el tiempo de última recompensa
    MySQL.query('UPDATE player_drtokens SET last_reward = NOW() WHERE citizenid = ?', {citizenid})
    
    -- Mensaje principal
    TriggerClientEvent('QBCore:Notify', src, 
        'Has recibido ' .. totalReward .. ' DrTokens por jugar una hora completa!', 
        'success', 5000)
    
    -- Mensajes de bonificaciones
    for _, message in ipairs(bonusMessages) do
        TriggerClientEvent('QBCore:Notify', src, '🎉 ' .. message, 'success', 4000)
    end
    
    -- Log de Discord para recompensa por hora
    GetPlayerTokens(citizenid, function(newTotalTokens)
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local bonusText = #bonusMessages > 0 and '\n**Bonificaciones:** ' .. table.concat(bonusMessages, ', ') or ''
        
        LogCustomEvent(
            '⏰ Recompensa por Hora',
            string.format('**%s** ha recibido **%d DrTokens** por jugar una hora completa%s', 
                playerName, totalReward, bonusText),
            {
                {name = '👤 Jugador', value = playerName .. ' (ID: ' .. src .. ')', inline = true},
                {name = '💰 Tokens Base', value = baseReward .. ' DrTokens', inline = true},
                {name = '🎉 Total Recibido', value = totalReward .. ' DrTokens', inline = true},
                {name = '🏦 Total Actual', value = newTotalTokens .. ' DrTokens', inline = true}
            },
            'Success',
            'HourlyRewards'
        )
    end)
end

-- Event cuando un jugador se conecta
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        local citizenid = Player.PlayerData.citizenid
        InitializePlayerTokens(citizenid)
        
        -- Inicializar tiempo de seguimiento
        PlayerTimeTracking[src] = {
            startTime = os.time(),
            totalTime = 0
        }
        
        -- Bonificación por login diario
        if Config.Bonuses.Enabled and Config.Bonuses.DailyLogin.enabled then
            local today = os.date('%Y-%m-%d')
            MySQL.query('SELECT last_reward FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
                local shouldGiveDailyBonus = true
                
                if result[1] and result[1].last_reward then
                    local lastRewardDate = os.date('%Y-%m-%d', os.time({
                        year = tonumber(string.sub(result[1].last_reward, 1, 4)),
                        month = tonumber(string.sub(result[1].last_reward, 6, 7)),
                        day = tonumber(string.sub(result[1].last_reward, 9, 10))
                    }))
                    
                    if lastRewardDate == today then
                        shouldGiveDailyBonus = false
                    end
                end
                
                if shouldGiveDailyBonus then
                    AddTokensToPlayer(citizenid, Config.Bonuses.DailyLogin.bonus)
                    
                    TriggerClientEvent('QBCore:Notify', src, 
                        '🌅 Bonificación de conexión diaria: +' .. Config.Bonuses.DailyLogin.bonus .. ' DrTokens!', 
                        'success', 5000)
                    
                    -- Log de bonificación diaria
                    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
                    LogCustomEvent(
                        '🌅 Bonificación Diaria',
                        string.format('**%s** ha recibido **%d DrTokens** por conexión diaria', 
                            playerName, Config.Bonuses.DailyLogin.bonus),
                        {
                            {name = '👤 Jugador', value = playerName .. ' (ID: ' .. src .. ')', inline = true},
                            {name = '💰 Bonificación', value = Config.Bonuses.DailyLogin.bonus .. ' DrTokens', inline = true},
                            {name = '📅 Fecha', value = today, inline = true}
                        },
                        'Success',
                        'PlayerActions'
                    )
                end
            end)
        end
        
        -- Log de Discord para conexión
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        LogPlayerConnection(playerName, src, 'login')
    end
end)

-- Event cuando un jugador se desconecta
RegisterNetEvent('QBCore:Server:OnPlayerUnload', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Log de Discord para desconexión
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        LogPlayerConnection(playerName, src, 'logout')
    end
    
    if PlayerTimeTracking[src] then
        PlayerTimeTracking[src] = nil
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        -- Log de Discord para desconexión forzada
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        LogPlayerConnection(playerName, src, 'logout')
    end
    
    if PlayerTimeTracking[src] then
        PlayerTimeTracking[src] = nil
    end
end)

-- Event para checkear el tiempo cada minuto
CreateThread(function()
    while true do
        Wait(60000) -- Cada minuto
        
        for src, data in pairs(PlayerTimeTracking) do
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                local currentTime = os.time()
                local timeOnline = currentTime - data.startTime
                
                -- Si ha estado online por una hora completa (3600 segundos)
                if timeOnline >= 3600 then
                    GiveHourlyReward(src)
                    -- Reiniciar el contador
                    PlayerTimeTracking[src].startTime = currentTime
                end
            else
                -- Limpiar si el jugador ya no está online
                PlayerTimeTracking[src] = nil
            end
        end
    end
end)

-- Comando para que admins añadan tokens
QBCore.Commands.Add('addtokens', 'Añadir DrTokens a un jugador', {
    {name = 'id', help = 'ID del jugador'},
    {name = 'amount', help = 'Cantidad de tokens'}
}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Verificar permisos de admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        TriggerClientEvent('QBCore:Notify', src, 'Uso: /addtokens [id] [cantidad]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Jugador no encontrado', 'error')
        return
    end
    
    local targetCitizenid = TargetPlayer.PlayerData.citizenid
    AddTokensToPlayer(targetCitizenid, amount)
    
    TriggerClientEvent('QBCore:Notify', src, 
        'Has añadido ' .. amount .. ' DrTokens a ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname, 
        'success')
    
    TriggerClientEvent('QBCore:Notify', targetId, 
        'Has recibido ' .. amount .. ' DrTokens de un administrador', 
        'success')
    
    -- Log para administradores (consola)
    print('[DrTokens] Admin ' .. Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. 
          ' añadió ' .. amount .. ' tokens a ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname)
    
    -- Log de Discord para acción de admin
    local adminName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    LogAdminAction(adminName, src, 'add', targetName, targetId, amount)
end)

-- Comando para que admins retiren tokens
QBCore.Commands.Add('removetokens', 'Retirar DrTokens de un jugador', {
    {name = 'id', help = 'ID del jugador'},
    {name = 'amount', help = 'Cantidad de tokens'}
}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Verificar permisos de admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        TriggerClientEvent('QBCore:Notify', src, 'Uso: /removetokens [id] [cantidad]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Jugador no encontrado', 'error')
        return
    end
    
    local targetCitizenid = TargetPlayer.PlayerData.citizenid
    RemoveTokensFromPlayer(targetCitizenid, amount)
    
    TriggerClientEvent('QBCore:Notify', src, 
        'Has retirado ' .. amount .. ' DrTokens de ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname, 
        'success')
    
    TriggerClientEvent('QBCore:Notify', targetId, 
        'Se te han retirado ' .. amount .. ' DrTokens por un administrador', 
        'error')
    
    -- Log para administradores (consola)
    print('[DrTokens] Admin ' .. Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .. 
          ' retiró ' .. amount .. ' tokens de ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname)
    
    -- Log de Discord para acción de admin
    local adminName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    LogAdminAction(adminName, src, 'remove', targetName, targetId, amount)
end)

-- Comando para que los jugadores vean sus tokens
QBCore.Commands.Add('mytokens', 'Ver tus DrTokens', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    GetPlayerTokens(citizenid, function(tokens)
        TriggerClientEvent('QBCore:Notify', src, 'Tienes ' .. tokens .. ' DrTokens', 'primary', 3000)
        
        -- Log de Discord para comando de jugador
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        LogPlayerCommand(playerName, src, '/mytokens', tokens)
    end)
end)

-- Comando para transferir tokens entre jugadores
QBCore.Commands.Add('givetokens', 'Transferir DrTokens a otro jugador', {
    {name = 'id', help = 'ID del jugador destinatario'},
    {name = 'amount', help = 'Cantidad de tokens a transferir'}
}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar si se requiere permiso de admin para transferencias
    if Config.Permissions.RequireAdminForTransfers then
        if not QBCore.Functions.HasPermission(src, 'admin') then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para transferir tokens', 'error')
            return
        end
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Uso: /givetokens [id] [cantidad]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Jugador no encontrado', 'error')
        return
    end
    
    if src == targetId then
        TriggerClientEvent('QBCore:Notify', src, 'No puedes transferirte tokens a ti mismo', 'error')
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    GetPlayerTokens(citizenid, function(currentTokens)
        if currentTokens < amount then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes suficientes DrTokens (Tienes: ' .. currentTokens .. ')', 'error')
            return
        end
        
        -- Realizar la transferencia
        local targetCitizenid = TargetPlayer.PlayerData.citizenid
        RemoveTokensFromPlayer(citizenid, amount)
        AddTokensToPlayer(targetCitizenid, amount)
        
        -- Notificaciones
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
        
        TriggerClientEvent('QBCore:Notify', src, 
            'Has transferido ' .. amount .. ' DrTokens a ' .. targetName, 'success')
        
        TriggerClientEvent('QBCore:Notify', targetId, 
            'Has recibido ' .. amount .. ' DrTokens de ' .. playerName, 'success')
        
        -- Log de Discord para transferencia
        LogCustomEvent(
            '🔄 Transferencia de Tokens',
            string.format('**%s** ha transferido **%d DrTokens** a **%s**', playerName, amount, targetName),
            {
                {name = '👤 De', value = playerName .. ' (ID: ' .. src .. ')', inline = true},
                {name = '👤 Para', value = targetName .. ' (ID: ' .. targetId .. ')', inline = true},
                {name = '💰 Cantidad', value = amount .. ' DrTokens', inline = true}
            },
            'Info',
            'PlayerActions'
        )
        
        -- Log en consola
        print('[DrTokens] ' .. playerName .. ' transfirió ' .. amount .. ' tokens a ' .. targetName)
    end)
end)

-- Comando para ver el top de jugadores con más tokens
QBCore.Commands.Add('toptokens', 'Ver el ranking de DrTokens', {}, false, function(source, args)
    local src = source
    
    MySQL.query('SELECT citizenid, tokens FROM player_drtokens ORDER BY tokens DESC LIMIT 10', {}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('QBCore:Notify', src, 'No hay datos de tokens disponibles', 'error')
            return
        end
        
        TriggerClientEvent('QBCore:Notify', src, '🏆 TOP 10 DRTOKENS 🏆', 'primary', 8000)
        
        for i, data in ipairs(result) do
            -- Obtener nombre del jugador
            MySQL.query('SELECT charinfo FROM players WHERE citizenid = ?', {data.citizenid}, function(playerResult)
                if playerResult[1] then
                    local charinfo = json.decode(playerResult[1].charinfo)
                    local playerName = charinfo.firstname .. ' ' .. charinfo.lastname
                    local medal = i == 1 and '🥇' or (i == 2 and '🥈' or (i == 3 and '🥉' or '🏅'))
                    
                    TriggerClientEvent('QBCore:Notify', src, 
                        medal .. ' #' .. i .. ' ' .. playerName .. ': ' .. data.tokens .. ' tokens', 
                        'primary', 5000)
                end
            end)
        end
        
        -- Log del comando
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            LogPlayerCommand(playerName, src, '/toptokens')
        end
    end)
end)

-- Comando para establecer cantidad exacta de tokens (solo admins)
QBCore.Commands.Add('settokens', 'Establecer cantidad exacta de DrTokens', {
    {name = 'id', help = 'ID del jugador'},
    {name = 'amount', help = 'Cantidad exacta de tokens'}
}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Verificar permisos de admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount or amount < 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Uso: /settokens [id] [cantidad]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Jugador no encontrado', 'error')
        return
    end
    
    local targetCitizenid = TargetPlayer.PlayerData.citizenid
    
    -- Establecer cantidad exacta
    MySQL.query('UPDATE player_drtokens SET tokens = ? WHERE citizenid = ?', {amount, targetCitizenid}, function(affectedRows)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO player_drtokens (citizenid, tokens) VALUES (?, ?)', {targetCitizenid, amount})
        end
    end)
    
    TriggerClientEvent('QBCore:Notify', src, 
        'Has establecido ' .. amount .. ' DrTokens para ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname, 
        'success')
    
    TriggerClientEvent('QBCore:Notify', targetId, 
        'Tus DrTokens han sido establecidos en ' .. amount .. ' por un administrador', 
        'primary')
    
    -- Log para administradores
    local adminName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    
    LogCustomEvent(
        '⚙️ Tokens Establecidos por Admin',
        string.format('**%s** ha establecido **%d DrTokens** para **%s**', adminName, amount, targetName),
        {
            {name = '👮‍♂️ Administrador', value = adminName .. ' (ID: ' .. src .. ')', inline = true},
            {name = '👤 Jugador Objetivo', value = targetName .. ' (ID: ' .. targetId .. ')', inline = true},
            {name = '💰 Cantidad', value = amount .. ' DrTokens', inline = true}
        },
        'Admin',
        'AdminActions'
    )
    
    print('[DrTokens] Admin ' .. adminName .. ' estableció ' .. amount .. ' tokens para ' .. targetName)
end)

-- Comando para ver tiempo restante para próxima recompensa
QBCore.Commands.Add('tokentime', 'Ver tiempo restante para próxima recompensa', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if not PlayerTimeTracking[src] then
        TriggerClientEvent('QBCore:Notify', src, 'Error: No se encontró tu sesión de tiempo', 'error')
        return
    end
    
    local currentTime = os.time()
    local timeOnline = currentTime - PlayerTimeTracking[src].startTime
    local timeRemaining = Config.TimeSettings.HourlyTime - timeOnline
    
    if timeRemaining <= 0 then
        TriggerClientEvent('QBCore:Notify', src, '¡Ya puedes recibir tu recompensa! Espera unos segundos...', 'success')
    else
        local minutes = math.floor(timeRemaining / 60)
        local seconds = timeRemaining % 60
        
        TriggerClientEvent('QBCore:Notify', src, 
            'Próxima recompensa en: ' .. minutes .. 'm ' .. seconds .. 's', 'primary', 5000)
    end
    
    -- Log del comando
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    LogPlayerCommand(playerName, src, '/tokentime')
end)

-- Event para obtener tokens (para otros scripts)
RegisterNetEvent('drtokens:server:getTokens', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    GetPlayerTokens(citizenid, function(tokens)
        TriggerClientEvent('drtokens:client:receiveTokens', src, tokens)
    end)
end)

-- Callback específico para origen_pausemenu
QBCore.Functions.CreateCallback('drtokens:server:getPlayerTokens', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb(0)
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    GetPlayerTokens(citizenid, function(tokens)
        cb(tokens)
    end)
end)

-- Callback para obtener información completa del jugador (para estadísticas)
QBCore.Functions.CreateCallback('drtokens:server:getPlayerInfo', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then 
        cb({tokens = 0, lastReward = nil})
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    MySQL.query('SELECT tokens, last_reward FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
        if result[1] then
            cb({
                tokens = result[1].tokens,
                lastReward = result[1].last_reward
            })
        else
            cb({tokens = 0, lastReward = nil})
        end
    end)
end)

-- Exports para que otros scripts puedan usar el sistema
exports('GetPlayerTokens', GetPlayerTokens)
exports('AddTokensToPlayer', AddTokensToPlayer)
exports('RemoveTokensFromPlayer', RemoveTokensFromPlayer)

-- Log de inicio del sistema en Discord
LogSystemStart()

print('[DrTokens] Sistema de tokens iniciado correctamente')