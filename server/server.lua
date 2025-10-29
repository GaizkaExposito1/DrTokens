local QBCore = exports['qb-core']:GetCoreObject()

-- Tabla para llevar control del tiempo de jugadores
local PlayerTimeTracking = {}

-- Función para inicializar la tabla de tokens de un jugador
local function InitializePlayerTokens(citizenid)
    if not citizenid or citizenid == '' then
        print('[DrTokens] ERROR: Attempting to initialize with invalid citizenid')
        return
    end
    
    MySQL.query('SELECT * FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
        if not result[1] then
            MySQL.insert('INSERT INTO player_drtokens (citizenid, tokens) VALUES (?, ?)', {citizenid, 0})
        end
    end)
end

-- Función para obtener los tokens de un jugador
local function GetPlayerTokens(citizenid, cb)
    if not citizenid or citizenid == '' then
        print('[DrTokens] ERROR: Attempting to get tokens with invalid citizenid')
        cb(0)
        return
    end
    
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
    if not citizenid or citizenid == '' then
        print('[DrTokens] ERROR: Attempting to add tokens with invalid citizenid')
        return
    end
    
    MySQL.query('UPDATE player_drtokens SET tokens = tokens + ? WHERE citizenid = ?', {amount, citizenid}, function(result)
        local affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affectedRows == 0 then
            MySQL.insert('INSERT INTO player_drtokens (citizenid, tokens) VALUES (?, ?)', {citizenid, amount})
        end
    end)
end

-- Función para retirar tokens de un jugador
local function RemoveTokensFromPlayer(citizenid, amount)
    if not citizenid or citizenid == '' then
        print('[DrTokens] ERROR: Attempting to remove tokens with invalid citizenid')
        return
    end
    
    MySQL.query('SELECT tokens FROM player_drtokens WHERE citizenid = ?', {citizenid}, function(result)
        if result[1] then
            local currentTokens = result[1].tokens
            local newAmount = math.max(0, currentTokens - amount)
            MySQL.query('UPDATE player_drtokens SET tokens = ? WHERE citizenid = ?', {newAmount, citizenid})
        end
    end)
end

-- Función para validar configuración
local function ValidateConfig()
    if not Config then
        print('[DrTokens] ERROR CRÍTICO: Config no está cargado')
        return false
    end
    
    if not Config.Security then
        print('[DrTokens] ERROR: Config.Security no está definido en config.lua')
        return false
    end
    
    if not Config.Security.MaxTokensConsole then
        print('[DrTokens] ERROR: Config.Security.MaxTokensConsole no está definido')
        return false
    end
    
    if not Config.Security.ConsoleConfirmationThreshold then
        print('[DrTokens] ERROR: Config.Security.ConsoleConfirmationThreshold no está definido')
        return false
    end
    
    return true
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

-- Función para verificar si el comando viene de la consola del servidor
local function IsConsoleCommand(source)
    return source == 0
end

-- Función para log de comandos ejecutados desde consola
local function LogConsoleCommandAttempt(commandName, source)
    if IsConsoleCommand(source) then
        -- Solo hacer log si está habilitado en la configuración
        if Config.Logging.LogConsoleCommands then
            print('[DrTokens] ⚠️  ADVERTENCIA: Intento de usar comando de jugador "' .. commandName .. '" desde la consola del servidor')
            print('[DrTokens] ℹ️  Este comando requiere ser ejecutado por un jugador conectado al servidor')
            
            -- Log en Discord si está habilitado y configurado correctamente
            if Config.Discord.EnableWebhooks then
                -- Verificar si el webhook está configurado antes de intentar enviar
                local logConfig = Config.Discord.LogTypes['ConsoleCommand']
                if logConfig and logConfig.enabled then
                    local webhookUrl = Config.Discord.Webhooks[logConfig.webhook]
                    if webhookUrl and not string.find(webhookUrl, 'TU_WEBHOOK') then
                        LogConsoleCommand(commandName)
                    else
                        if Config.Logging.VerboseWebhooks then
                            print('[DrTokens] Webhook ConsoleCommand no configurado, solo mostrando en consola')
                        end
                    end
                else
                    if Config.Logging.VerboseWebhooks then
                        print('[DrTokens] Tipo ConsoleCommand deshabilitado en Discord config')
                    end
                end
            end
        end
        return true
    end
    return false
end

-- Función para verificar permisos de admin de manera segura
local function CheckAdminPermission(source)
    -- Si es consola del servidor (source = 0), no permitir
    if source == 0 then
        return false, 'console'
    end
    
    -- Verificar si el jugador existe
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return false, 'no_player'
    end
    
    -- Verificar permisos de admin
    local hasPermission = QBCore.Functions.HasPermission(source, 'admin')
    if not hasPermission then
        return false, 'no_permission'
    end
    
    return true, 'success', Player
end

-- Función para dar tokens a todos los jugadores online
local function GiveTokensToAll(amount, adminName, adminId, isConsole)
    local players = QBCore.Functions.GetPlayers()
    local successCount = 0
    
    if not players or #players == 0 then
        return 0, 'No hay jugadores online'
    end
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            AddTokensToPlayer(Player.PlayerData.citizenid, amount)
            
            -- Notificar al jugador
            TriggerClientEvent('QBCore:Notify', playerId, 
                '🎉 Has recibido ' .. amount .. ' DrTokens del servidor!', 
                'success', 5000)
            
            successCount = successCount + 1
        end
    end
    
    -- Log en Discord
    if successCount > 0 then
        LogTokensToAll(adminName, adminId or 0, amount, successCount, isConsole)
        
        -- Log en consola
        print('[DrTokens] ' .. adminName .. ' dio ' .. amount .. ' tokens a ' .. successCount .. ' jugadores online')
    end
    
    return successCount, 'success'
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
    
    -- Verificar permisos de admin de manera segura
    local hasPermission, reason, Player = CheckAdminPermission(src)
    if not hasPermission then
        if reason == 'console' then
            print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
        elseif reason == 'no_player' then
            print('[DrTokens] Error: No se pudo obtener información del jugador')
        elseif reason == 'no_permission' then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        end
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
    
    -- Verificar permisos de admin de manera segura
    local hasPermission, reason, Player = CheckAdminPermission(src)
    if not hasPermission then
        if reason == 'console' then
            print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
        elseif reason == 'no_player' then
            print('[DrTokens] Error: No se pudo obtener información del jugador')
        elseif reason == 'no_permission' then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        end
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
    
    -- Verificar si el comando viene de la consola
    if LogConsoleCommandAttempt('/mytokens', src) then
        return
    end
    
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
    
    -- Verificar si el comando viene de la consola
    if LogConsoleCommandAttempt('/givetokens', src) then
        return
    end
    
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
    
    -- Verificar si el comando viene de la consola
    if LogConsoleCommandAttempt('/toptokens', src) then
        return
    end
    
    MySQL.query('SELECT citizenid, tokens FROM player_drtokens WHERE citizenid IS NOT NULL AND citizenid != "" ORDER BY tokens DESC LIMIT 10', {}, function(result)
        if not result or #result == 0 then
            TriggerClientEvent('QBCore:Notify', src, 'No hay datos de tokens disponibles', 'error')
            return
        end
        
        TriggerClientEvent('QBCore:Notify', src, '🏆 TOP 10 DRTOKENS 🏆', 'primary', 8000)
        
        for i, data in ipairs(result) do
            -- Verificar que citizenid no sea null
            if data.citizenid and data.citizenid ~= '' then
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
    
    -- Verificar permisos de admin de manera segura
    local hasPermission, reason, Player = CheckAdminPermission(src)
    if not hasPermission then
        if reason == 'console' then
            print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
        elseif reason == 'no_player' then
            print('[DrTokens] Error: No se pudo obtener información del jugador')
        elseif reason == 'no_permission' then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        end
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
    MySQL.query('UPDATE player_drtokens SET tokens = ? WHERE citizenid = ?', {amount, targetCitizenid}, function(result)
        local affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
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

-- Comando para dar tokens a todos los jugadores online (solo admins)
QBCore.Commands.Add('givealltoken', 'Dar DrTokens a todos los jugadores online', {
    {name = 'amount', help = 'Cantidad de tokens para cada jugador'}
}, true, function(source, args)
    local src = source
    
    -- Verificar permisos de admin de manera segura
    local hasPermission, reason, Player = CheckAdminPermission(src)
    if not hasPermission then
        if reason == 'console' then
            print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
            print('[DrTokens] 💡 Usa desde la consola: drp_giveall [cantidad]')
        elseif reason == 'no_player' then
            print('[DrTokens] Error: No se pudo obtener información del jugador')
        elseif reason == 'no_permission' then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        end
        return
    end
    
    local amount = tonumber(args[1])
    
    if not amount or amount <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Uso: /givealltoken [cantidad]', 'error')
        return
    end
    
    if amount > Config.Security.MaxTokensPerPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Cantidad máxima: ' .. Config.Security.MaxTokensPerPlayer .. ' tokens por jugador', 'error')
        return
    end
    
    -- Confirmar acción (cantidad alta)
    if amount > Config.Security.ConfirmationThreshold then
        TriggerClientEvent('QBCore:Notify', src, 
            '⚠️ Vas a dar ' .. amount .. ' tokens a TODOS los jugadores online. Usa el comando nuevamente para confirmar.', 
            'warning', 8000)
        
        -- Sistema de confirmación simple
        if not Player.PlayerData.tokenConfirm or Player.PlayerData.tokenConfirm ~= amount then
            Player.PlayerData.tokenConfirm = amount
            return
        else
            Player.PlayerData.tokenConfirm = nil
        end
    end
    
    local adminName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    local successCount, result = GiveTokensToAll(amount, adminName, src, false)
    
    if successCount > 0 then
        TriggerClientEvent('QBCore:Notify', src, 
            '✅ ' .. amount .. ' DrTokens dados a ' .. successCount .. ' jugadores online', 
            'success', 6000)
    else
        TriggerClientEvent('QBCore:Notify', src, 
            '❌ No se pudieron dar tokens: ' .. (result or 'Error desconocido'), 
            'error')
    end
end)

-- Comandos especiales para consola del servidor (sin verificación de permisos)
RegisterCommand('drp_addtokens', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        print('[DrTokens] Uso: drp_addtokens [id] [cantidad]')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        print('[DrTokens] Jugador no encontrado')
        return
    end
    
    local targetCitizenid = TargetPlayer.PlayerData.citizenid
    AddTokensToPlayer(targetCitizenid, amount)
    
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    print('[DrTokens] ✅ Añadidos ' .. amount .. ' DrTokens a ' .. targetName)
    
    TriggerClientEvent('QBCore:Notify', targetId, 
        'Has recibido ' .. amount .. ' DrTokens del servidor', 'success')
end, true)

RegisterCommand('drp_removetokens', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    
    if not targetId or not amount then
        print('[DrTokens] Uso: drp_removetokens [id] [cantidad]')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        print('[DrTokens] Jugador no encontrado')
        return
    end
    
    local targetCitizenid = TargetPlayer.PlayerData.citizenid
    RemoveTokensFromPlayer(targetCitizenid, amount)
    
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    print('[DrTokens] ✅ Retirados ' .. amount .. ' DrTokens de ' .. targetName)
    
    TriggerClientEvent('QBCore:Notify', targetId, 
        'Se te han retirado ' .. amount .. ' DrTokens del servidor', 'error')
end, true)

RegisterCommand('drp_checkconfig', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    print('[DrTokens] 📊 Estado de configuración:')
    print('[DrTokens] - Recompensa por hora: ' .. Config.HourlyReward .. ' tokens')
    print('[DrTokens] - Bonificaciones habilitadas: ' .. (Config.Bonuses.Enabled and 'SÍ' or 'NO'))
    print('[DrTokens] - Discord webhooks: ' .. (Config.Discord.EnableWebhooks and 'SÍ' or 'NO'))
    print('[DrTokens] - Logs habilitados: ' .. (Config.Logging.EnableLogs and 'SÍ' or 'NO'))
    print('[DrTokens] - Jugadores online con tracking: ' .. (PlayerTimeTracking and #PlayerTimeTracking or 0))
end, true)

RegisterCommand('drp_giveall', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    -- Validar configuración antes de proceder
    if not ValidateConfig() then
        print('[DrTokens] No se puede ejecutar el comando debido a errores de configuración')
        return
    end
    
    local amount = tonumber(args[1])
    
    if not amount then
        print('[DrTokens] Uso: drp_giveall [cantidad]')
        print('[DrTokens] Ejemplo: drp_giveall 50')
        return
    end
    
    if amount <= 0 then
        print('[DrTokens] La cantidad debe ser mayor a 0')
        return
    end
    
    -- Verificar que Config.Security existe
    if not Config.Security then
        print('[DrTokens] ERROR: Configuración de seguridad no encontrada. Verifica config.lua')
        return
    end
    
    if amount > Config.Security.MaxTokensConsole then
        print('[DrTokens] Cantidad máxima desde consola: ' .. Config.Security.MaxTokensConsole .. ' tokens por jugador')
        return
    end
    
    -- Advertencia para cantidades altas
    if amount > Config.Security.ConsoleConfirmationThreshold then
        print('[DrTokens] ⚠️  ADVERTENCIA: Vas a dar ' .. amount .. ' tokens a TODOS los jugadores online')
        print('[DrTokens] ⚠️  Esto puede afectar significativamente la economía del servidor')
        print('[DrTokens] ⚠️  Escribe nuevamente el comando para confirmar')
        
        -- Sistema de confirmación para consola
        if not _G.DrTokensConsoleConfirm or _G.DrTokensConsoleConfirm ~= amount then
            _G.DrTokensConsoleConfirm = amount
            return
        else
            _G.DrTokensConsoleConfirm = nil
            print('[DrTokens] ✅ Confirmación recibida, distribuyendo tokens...')
        end
    end
    
    local successCount, result = GiveTokensToAll(amount, 'Consola del Servidor', 0, true)
    
    if successCount > 0 then
        print('[DrTokens] ✅ ' .. amount .. ' DrTokens dados a ' .. successCount .. ' jugadores online')
        print('[DrTokens] 💰 Total distribuido: ' .. (amount * successCount) .. ' DrTokens')
        
        -- Enviar mensaje global opcional
        for _, playerId in ipairs(QBCore.Functions.GetPlayers()) do
            TriggerClientEvent('QBCore:Notify', playerId, 
                '📢 El servidor ha dado ' .. amount .. ' DrTokens a todos los jugadores online!', 
                'success', 8000)
        end
    else
        print('[DrTokens] ❌ Error al distribuir tokens: ' .. (result or 'Error desconocido'))
    end
end, true)

RegisterCommand('drp_help', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    print('[DrTokens] 📋 ===== COMANDOS DE CONSOLA DISPONIBLES =====')
    print('[DrTokens] 💰 drp_addtokens [id] [cantidad] - Añadir tokens a un jugador específico')
    print('[DrTokens] 💸 drp_removetokens [id] [cantidad] - Retirar tokens de un jugador específico')
    print('[DrTokens] 🎉 drp_giveall [cantidad] - Dar tokens a TODOS los jugadores online')
    print('[DrTokens] � drp_giveadmins [cantidad] - Dar tokens solo a administradores online')
    print('[DrTokens] �📊 drp_checkconfig - Ver estado de configuración del sistema')
    print('[DrTokens] 🔗 drp_webhookstatus - Ver estado completo de webhooks')
    print('[DrTokens] 🧪 drp_testwebhook [tipo] - Probar un webhook específico')
    print('[DrTokens] 🧪 drp_testallwebhooks - Probar TODOS los webhooks configurados')
    print('[DrTokens] ❓ drp_help - Mostrar esta ayuda')
    print('[DrTokens] ')
    print('[DrTokens] 📋 ===== COMANDOS DE JUGADOR (con /[comando]) =====')
    print('[DrTokens] 💰 /mytokens - Ver tus tokens actuales')
    print('[DrTokens] 🔄 /givetokens [id] [cantidad] - Transferir tokens a otro jugador')
    print('[DrTokens] 🏆 /toptokens - Ver ranking de tokens')
    print('[DrTokens] ⏰ /tokentime - Ver tiempo para próxima recompensa')
    print('[DrTokens] ')
    print('[DrTokens] 📋 ===== COMANDOS DE ADMIN (con /[comando]) =====')
    print('[DrTokens] ➕ /addtokens [id] [cantidad] - Añadir tokens (admin)')
    print('[DrTokens] ➖ /removetokens [id] [cantidad] - Retirar tokens (admin)')
    print('[DrTokens] ⚙️ /settokens [id] [cantidad] - Establecer cantidad exacta (admin)')
    print('[DrTokens] 🎉 /givealltoken [cantidad] - Dar tokens a todos (admin)')
    print('[DrTokens] 🧹 /cleanuptokens - Limpiar registros inválidos (admin)')
    print('[DrTokens] 🔧 /testwebhook [tipo] - Probar webhook (admin)')
    print('[DrTokens] 📊 /checkwebhooks - Verificar webhooks (admin)')
    print('[DrTokens] =============================================')
end, true)

RegisterCommand('drp_giveadmins', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    local amount = tonumber(args[1])
    
    if not amount then
        print('[DrTokens] Uso: drp_giveadmins [cantidad]')
        print('[DrTokens] Este comando da tokens solo a los administradores online')
        return
    end
    
    if amount <= 0 or amount > Config.Security.MaxTokensConsole then
        print('[DrTokens] Cantidad debe estar entre 1 y ' .. Config.Security.MaxTokensConsole)
        return
    end
    
    local players = QBCore.Functions.GetPlayers()
    local adminCount = 0
    
    if not players or #players == 0 then
        print('[DrTokens] No hay jugadores online')
        return
    end
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData and Player.PlayerData.citizenid then
            -- Verificar si es admin
            if QBCore.Functions.HasPermission(playerId, 'admin') then
                AddTokensToPlayer(Player.PlayerData.citizenid, amount)
                
                -- Notificar al admin
                TriggerClientEvent('QBCore:Notify', playerId, 
                    '👑 Has recibido ' .. amount .. ' DrTokens como administrador!', 
                    'success', 5000)
                
                adminCount = adminCount + 1
            end
        end
    end
    
    if adminCount > 0 then
        print('[DrTokens] ✅ ' .. amount .. ' DrTokens dados a ' .. adminCount .. ' administradores online')
        
        -- Log en Discord
        LogTokensToAll('Consola del Servidor (Solo Admins)', 0, amount, adminCount, true)
    else
        print('[DrTokens] ❌ No hay administradores online')
    end
end, true)

RegisterCommand('drp_testwebhook', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    local webhookType = args[1]
    
    if not webhookType then
        print('[DrTokens] 📋 Tipos de webhook disponibles para probar:')
        print('[DrTokens] - AdminActions     (acciones de administradores)')
        print('[DrTokens] - PlayerActions    (acciones de jugadores)')
        print('[DrTokens] - HourlyRewards    (recompensas por hora)')
        print('[DrTokens] - General          (logs generales)')
        print('[DrTokens] - ConsoleCommand   (comandos desde consola)')
        print('[DrTokens] - MassTokens       (tokens masivos)')
        print('[DrTokens] ')
        print('[DrTokens] Uso: drp_testwebhook [tipo]')
        print('[DrTokens] Ejemplo: drp_testwebhook AdminActions')
        return
    end
    
    -- Validar tipo de webhook
    local validTypes = {
        'AdminActions', 'PlayerActions', 'HourlyRewards', 
        'General', 'ConsoleCommand', 'MassTokens'
    }
    
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if string.lower(validType) == string.lower(webhookType) then
            webhookType = validType  -- Asegurar capitalización correcta
            isValidType = true
            break
        end
    end
    
    if not isValidType then
        print('[DrTokens] ❌ Tipo de webhook inválido: ' .. webhookType)
        print('[DrTokens] Usa: drp_testwebhook sin parámetros para ver los tipos disponibles')
        return
    end
    
    -- Verificar si el webhook está configurado
    local logConfig = Config.Discord.LogTypes[webhookType]
    if not logConfig or not logConfig.enabled then
        print('[DrTokens] ❌ El webhook ' .. webhookType .. ' está deshabilitado en la configuración')
        return
    end
    
    local webhookUrl = Config.Discord.Webhooks[logConfig.webhook]
    if not webhookUrl or string.find(webhookUrl, 'TU_WEBHOOK') then
        print('[DrTokens] ❌ URL del webhook no configurada para ' .. webhookType)
        print('[DrTokens] Configura la URL en Config.Discord.Webhooks.' .. logConfig.webhook)
        return
    end
    
    print('[DrTokens] 🧪 Enviando webhook de prueba para: ' .. webhookType)
    
    -- Enviar webhook de prueba específico según el tipo
    if webhookType == 'AdminActions' then
        TestDiscordWebhook(webhookType)
    elseif webhookType == 'PlayerActions' then
        LogPlayerCommand('Usuario de Prueba', 999, '/mytokens', 150)
    elseif webhookType == 'HourlyRewards' then
        LogHourlyReward('Jugador de Prueba', 999, 25, 275)
    elseif webhookType == 'General' then
        LogSystemStart()
    elseif webhookType == 'ConsoleCommand' then
        LogConsoleCommand('/testcommand')
    elseif webhookType == 'MassTokens' then
        LogTokensToAll('Administrador de Prueba', 999, 100, 5, true)
    end
    
    print('[DrTokens] ✅ Webhook de prueba enviado. Revisa tu canal de Discord.')
end, true)

RegisterCommand('drp_testallwebhooks', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    if not Config.Discord.EnableWebhooks then
        print('[DrTokens] ❌ Los webhooks están deshabilitados en la configuración')
        print('[DrTokens] Cambia Config.Discord.EnableWebhooks = true')
        return
    end
    
    print('[DrTokens] 🧪 Iniciando prueba de TODOS los webhooks configurados...')
    print('[DrTokens] ')
    
    local delay = 0
    
    -- Probar cada tipo de webhook con un pequeño delay
    for webhookType, logConfig in pairs(Config.Discord.LogTypes) do
        if logConfig.enabled then
            local webhookUrl = Config.Discord.Webhooks[logConfig.webhook]
            if webhookUrl and not string.find(webhookUrl, 'TU_WEBHOOK') then
                
                -- Usar un timer para espaciar los webhooks
                SetTimeout(delay * 2000, function()  -- 2 segundos entre cada uno
                    print('[DrTokens] 📤 Enviando: ' .. webhookType .. ' (' .. logConfig.title .. ')')
                    
                    -- Enviar webhook específico según el tipo
                    if webhookType == 'AdminAddTokens' then
                        LogAdminAction('Admin de Prueba', 999, 'add', 'Jugador de Prueba', 888, 50)
                    elseif webhookType == 'AdminRemoveTokens' then
                        LogAdminAction('Admin de Prueba', 999, 'remove', 'Jugador de Prueba', 888, 25)
                    elseif webhookType == 'TokenTransfer' then
                        LogTokenTransfer('Jugador A', 777, 'Jugador B', 888, 30)
                    elseif webhookType == 'PlayerLogin' then
                        LogPlayerConnection('Jugador de Prueba', 999, 'login')
                    elseif webhookType == 'PlayerLogout' then
                        LogPlayerConnection('Jugador de Prueba', 999, 'logout')
                    elseif webhookType == 'HourlyReward' then
                        LogHourlyReward('Jugador de Prueba', 999, 25, 275)
                    elseif webhookType == 'BonusReward' then
                        LogBonusReward('Jugador de Prueba', 999, 'daily', 20, 45)
                    elseif webhookType == 'SystemStart' then
                        LogSystemStart()
                    elseif webhookType == 'ConsoleCommand' then
                        LogConsoleCommand('/testcommand')
                    elseif webhookType == 'MassTokens' then
                        LogTokensToAll('Admin de Prueba', 999, 100, 8, false)
                    else
                        -- Para tipos personalizados, usar TestDiscordWebhook
                        TestDiscordWebhook(webhookType)
                    end
                end)
                
                delay = delay + 1
            else
                print('[DrTokens] ⚠️  Saltando ' .. webhookType .. ': URL no configurada')
            end
        else
            print('[DrTokens] ⚠️  Saltando ' .. webhookType .. ': Deshabilitado en config')
        end
    end
    
    if delay > 0 then
        print('[DrTokens] ')
        print('[DrTokens] ⏳ Enviando ' .. delay .. ' webhooks de prueba...')
        print('[DrTokens] ⏳ Tiempo estimado: ' .. (delay * 2) .. ' segundos')
        print('[DrTokens] ')
        
        -- Mensaje final después de todos los webhooks
        SetTimeout((delay + 1) * 2000, function()
            print('[DrTokens] ✅ Prueba de webhooks completada!')
            print('[DrTokens] 📋 Revisa tus canales de Discord para ver los resultados')
        end)
    else
        print('[DrTokens] ❌ No hay webhooks configurados para probar')
        print('[DrTokens] 💡 Configura las URLs en Config.Discord.Webhooks')
    end
end, true)

RegisterCommand('drp_webhookstatus', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    print('[DrTokens] 📊 ===== ESTADO DE WEBHOOKS =====')
    print('[DrTokens] ')
    print('[DrTokens] Sistema: ' .. (Config.Discord.EnableWebhooks and '✅ HABILITADO' or '❌ DESHABILITADO'))
    print('[DrTokens] ')
    
    -- Verificar URLs de webhook
    print('[DrTokens] 🔗 URLs de Webhook:')
    local configuredWebhooks = 0
    local totalWebhooks = 0
    
    for name, url in pairs(Config.Discord.Webhooks) do
        totalWebhooks = totalWebhooks + 1
        if url and not string.find(url, 'TU_WEBHOOK') then
            print('[DrTokens] ✅ ' .. name .. ': Configurado')
            configuredWebhooks = configuredWebhooks + 1
        else
            print('[DrTokens] ❌ ' .. name .. ': NO configurado')
        end
    end
    
    print('[DrTokens] ')
    print('[DrTokens] 📋 Tipos de Log:')
    local enabledTypes = 0
    local totalTypes = 0
    
    for typeName, config in pairs(Config.Discord.LogTypes) do
        totalTypes = totalTypes + 1
        local webhook = Config.Discord.Webhooks[config.webhook]
        local isConfigured = webhook and not string.find(webhook, 'TU_WEBHOOK')
        
        if config.enabled and isConfigured then
            print('[DrTokens] ✅ ' .. typeName .. ': Habilitado y configurado → ' .. config.webhook)
            enabledTypes = enabledTypes + 1
        elseif config.enabled and not isConfigured then
            print('[DrTokens] ⚠️  ' .. typeName .. ': Habilitado pero webhook no configurado → ' .. config.webhook)
        else
            print('[DrTokens] ❌ ' .. typeName .. ': Deshabilitado')
        end
    end
    
    print('[DrTokens] ')
    print('[DrTokens] 📈 Resumen:')
    print('[DrTokens] - URLs configuradas: ' .. configuredWebhooks .. '/' .. totalWebhooks)
    print('[DrTokens] - Tipos habilitados: ' .. enabledTypes .. '/' .. totalTypes)
    print('[DrTokens] - Tipos funcionales: ' .. enabledTypes .. ' (habilitados + URL configurada)')
    
    if configuredWebhooks == 0 then
        print('[DrTokens] ')
        print('[DrTokens] 💡 Para configurar webhooks:')
        print('[DrTokens] 1. Ve a tu servidor de Discord')
        print('[DrTokens] 2. Configuración → Integraciones → Webhooks')
        print('[DrTokens] 3. Crear webhook y copiar URL')
        print('[DrTokens] 4. Pegar URL en Config.Discord.Webhooks')
    elseif enabledTypes > 0 then
        print('[DrTokens] ')
        print('[DrTokens] 🧪 Comandos de prueba disponibles:')
        print('[DrTokens] - drp_testwebhook [tipo]')
        print('[DrTokens] - drp_testallwebhooks')
    end
    
    print('[DrTokens] =============================')
end, true)

RegisterCommand('drp_webhookhelp', function(source, args)
    if source ~= 0 then
        print('[DrTokens] Este comando solo puede ser usado desde la consola del servidor')
        return
    end
    
    print('[DrTokens] 🔗 ===== COMANDOS DE WEBHOOK =====')
    print('[DrTokens] ')
    print('[DrTokens] 📊 drp_webhookstatus        - Ver estado de webhooks')
    print('[DrTokens] 🧪 drp_testwebhook [tipo]   - Probar webhook específico')
    print('[DrTokens] 🧪 drp_testallwebhooks      - Probar todos los webhooks')
    print('[DrTokens] ')
    print('[DrTokens] 🎯 Tipos de webhook disponibles:')
    print('[DrTokens] - AdminActions     (acciones de admin)')
    print('[DrTokens] - PlayerActions    (acciones de jugadores)')
    print('[DrTokens] - HourlyRewards    (recompensas automáticas)')
    print('[DrTokens] - General          (logs generales)')
    print('[DrTokens] - ConsoleCommand   (comandos desde consola)')
    print('[DrTokens] - MassTokens       (distribución masiva)')
    print('[DrTokens] ')
    print('[DrTokens] 📋 Ejemplos de uso:')
    print('[DrTokens] drp_webhookstatus')
    print('[DrTokens] drp_testwebhook AdminActions')
    print('[DrTokens] drp_testallwebhooks')
    print('[DrTokens] ===================================')
end, true)

-- Comando para limpiar registros inválidos (solo admins)
QBCore.Commands.Add('cleanuptokens', 'Limpiar registros inválidos de DrTokens', {}, true, function(source, args)
    local src = source
    
    -- Verificar permisos de admin de manera segura
    local hasPermission, reason, Player = CheckAdminPermission(src)
    if not hasPermission then
        if reason == 'console' then
            print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
        elseif reason == 'no_player' then
            print('[DrTokens] Error: No se pudo obtener información del jugador')
        elseif reason == 'no_permission' then
            TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        end
        return
    end
    
    -- Limpiar registros con citizenid NULL o vacío
    MySQL.query('DELETE FROM player_drtokens WHERE citizenid IS NULL OR citizenid = ""', {}, function(result)
        local affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affectedRows > 0 then
            TriggerClientEvent('QBCore:Notify', src, 
                'Limpieza completada: ' .. affectedRows .. ' registros inválidos eliminados', 'success')
            
            -- Log de la acción
            local adminName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
            print('[DrTokens] Admin ' .. adminName .. ' ejecutó limpieza de base de datos: ' .. affectedRows .. ' registros eliminados')
        else
            TriggerClientEvent('QBCore:Notify', src, 'No se encontraron registros inválidos para limpiar', 'primary')
        end
    end)
end)

-- Comando para probar webhooks de Discord (solo admins)
QBCore.Commands.Add('testwebhook', 'Probar webhook de Discord', {
    {name = 'type', help = 'Tipo de webhook (AdminActions, PlayerActions, General, HourlyRewards)'}
}, true, function(source, args)
    local src = source
    
    -- Verificar si es consola del servidor
    if src == 0 then
        print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print('[DrTokens] Error: No se pudo obtener información del jugador')
        return
    end
    
    -- Verificar permisos de admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        return
    end
    
    local webhookType = args[1] or 'General'
    
    -- Validar tipo de webhook
    local validTypes = {'AdminActions', 'PlayerActions', 'General', 'HourlyRewards'}
    local isValidType = false
    for _, validType in ipairs(validTypes) do
        if validType == webhookType then
            isValidType = true
            break
        end
    end
    
    if not isValidType then
        TriggerClientEvent('QBCore:Notify', src, 
            'Tipo de webhook inválido. Usa: ' .. table.concat(validTypes, ', '), 'error')
        return
    end
    
    -- Enviar webhook de prueba
    TestDiscordWebhook(webhookType)
    
    TriggerClientEvent('QBCore:Notify', src, 
        'Webhook de prueba enviado para: ' .. webhookType, 'success')
    
    local adminName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    print('[DrTokens] Admin ' .. adminName .. ' probó webhook: ' .. webhookType)
end)

-- Comando para verificar configuración de webhooks (solo admins)
QBCore.Commands.Add('checkwebhooks', 'Verificar configuración de webhooks', {}, true, function(source, args)
    local src = source
    
    -- Verificar si es consola del servidor
    if src == 0 then
        print('[DrTokens] ⚠️ Este comando debe ser ejecutado por un jugador admin, no desde la consola')
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print('[DrTokens] Error: No se pudo obtener información del jugador')
        return
    end
    
    -- Verificar permisos de admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'No tienes permisos para usar este comando', 'error')
        return
    end
    
    TriggerClientEvent('QBCore:Notify', src, '🔍 Verificando configuración de webhooks...', 'primary')
    
    -- Verificar estado general
    local status = {}
    status.enabled = Config.Discord.EnableWebhooks
    status.configured = 0
    status.total = 0
    
    -- Verificar cada webhook
    for name, url in pairs(Config.Discord.Webhooks) do
        status.total = status.total + 1
        if url and not string.find(url, 'TU_WEBHOOK') then
            status.configured = status.configured + 1
            print('[DrTokens] ✅ ' .. name .. ': Configurado')
        else
            print('[DrTokens] ❌ ' .. name .. ': NO configurado (placeholder)')
        end
    end
    
    -- Verificar tipos de log
    local enabledTypes = 0
    local totalTypes = 0
    for typeName, config in pairs(Config.Discord.LogTypes) do
        totalTypes = totalTypes + 1
        if config.enabled then
            enabledTypes = enabledTypes + 1
        end
    end
    
    print('[DrTokens] 📊 Resumen:')
    print('[DrTokens] - Webhooks habilitados: ' .. (status.enabled and 'SÍ' or 'NO'))
    print('[DrTokens] - URLs configuradas: ' .. status.configured .. '/' .. status.total)
    print('[DrTokens] - Tipos de log habilitados: ' .. enabledTypes .. '/' .. totalTypes)
    
    TriggerClientEvent('QBCore:Notify', src, 
        'Webhooks: ' .. (status.enabled and 'ON' or 'OFF') .. ' | URLs: ' .. status.configured .. '/' .. status.total, 
        status.configured > 0 and 'success' or 'warning')
end)

-- Comando de prueba para el sistema de logging de consola (solo para testear)
QBCore.Commands.Add('testconsole', 'Comando de prueba para logging de consola', {}, false, function(source, args)
    local src = source
    
    -- Verificar si el comando viene de la consola
    if LogConsoleCommandAttempt('/testconsole', src) then
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    TriggerClientEvent('QBCore:Notify', src, 'Comando de prueba ejecutado correctamente por un jugador', 'success')
end)

-- Comando para ver tiempo restante para próxima recompensa
QBCore.Commands.Add('tokentime', 'Ver tiempo restante para próxima recompensa', {}, false, function(source, args)
    local src = source
    
    -- Verificar si el comando viene de la consola
    if LogConsoleCommandAttempt('/tokentime', src) then
        return
    end
    
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

-- Función de limpieza de datos inválidos
local function CleanupInvalidRecords()
    -- Limpiar registros con citizenid NULL o vacío
    MySQL.query('DELETE FROM player_drtokens WHERE citizenid IS NULL OR citizenid = ""', {}, function(result)
        local affectedRows = type(result) == 'number' and result or (result and result.affectedRows or 0)
        if affectedRows > 0 then
            print('[DrTokens] Limpieza completada: ' .. affectedRows .. ' registros inválidos eliminados')
        end
    end)
end

-- Validar configuración al inicializar
if ValidateConfig() then
    print('[DrTokens] ✅ Configuración validada correctamente')
    
    -- Ejecutar limpieza al iniciar
    CleanupInvalidRecords()
    
    -- Log de inicio del sistema en Discord
    LogSystemStart()
else
    print('[DrTokens] ❌ ERROR: Configuración inválida, el sistema puede no funcionar correctamente')
end

print('[DrTokens] Sistema de tokens iniciado correctamente')