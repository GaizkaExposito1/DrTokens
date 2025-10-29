-- Funciones para Discord Webhooks

-- Función para enviar webhook a Discord
local function SendDiscordWebhook(webhookType, title, description, fields, color)
    if not Config.Discord.EnableWebhooks then return end
    
    local logConfig = Config.Discord.LogTypes[webhookType]
    if not logConfig or not logConfig.enabled then 
        if Config.Logging.EnableLogs then
            print('[DrTokens] Webhook deshabilitado para tipo: ' .. webhookType)
        end
        return 
    end
    
    local webhookUrl = Config.Discord.Webhooks[logConfig.webhook]
    if not webhookUrl then
        print('[DrTokens] Error: No webhook URL found for ' .. logConfig.webhook .. ' (type: ' .. webhookType .. ')')
        return 
    end
    
    if string.find(webhookUrl, 'TU_WEBHOOK') then 
        print('[DrTokens] Warning: Webhook URL not configured for ' .. webhookType .. ' (' .. logConfig.webhook .. ')')
        print('[DrTokens] Please configure a real Discord webhook URL in config.lua')
        return 
    end
    
    -- Validar que la URL sea válida
    if not string.match(webhookUrl, 'https://discord%.com/api/webhooks/%d+/[%w%-_]+') then
        print('[DrTokens] Error: Invalid webhook URL format for ' .. webhookType)
        return
    end
    
    local embedColor = Config.Discord.Colors[color or logConfig.color] or Config.Discord.Colors.Info
    
    -- Validar campos
    local validFields = {}
    if fields then
        for _, field in ipairs(fields) do
            if field.name and field.value then
                table.insert(validFields, {
                    name = tostring(field.name),
                    value = tostring(field.value),
                    inline = field.inline or false
                })
            end
        end
    end
    
    local embed = {
        {
            title = title or logConfig.title or 'DrTokens Event',
            description = description or 'Sin descripción',
            color = embedColor,
            fields = validFields,
            footer = {
                text = Config.Discord.ServerInfo.footer .. ' • ' .. os.date('%d/%m/%Y %H:%M:%S'),
                icon_url = Config.Discord.ServerInfo.icon
            },
            author = {
                name = Config.Discord.ServerInfo.name,
                icon_url = Config.Discord.ServerInfo.icon
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }
    }
    
    PerformHttpRequest(webhookUrl, function(err, text, headers) 
        if err == 200 or err == 204 then
            -- 200 = OK, 204 = No Content (ambos son éxito para webhooks)
            if Config.Logging.EnableLogs and Config.Logging.VerboseWebhooks then
                print('[DrTokens] Discord webhook enviado correctamente (' .. webhookType .. ')')
            end
        else
            print('[DrTokens] Error sending Discord webhook (' .. webhookType .. '): HTTP ' .. err)
            if text then
                print('[DrTokens] Response: ' .. text)
            end
        end
    end, 'POST', json.encode({
        username = 'DrTokens Bot',
        avatar_url = Config.Discord.ServerInfo.icon or '',
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Función para log de acciones de administrador
function LogAdminAction(adminName, adminId, action, targetName, targetId, amount)
    if not Config.Discord.EnableWebhooks then return end
    
    local actionType = action == 'add' and 'AdminAddTokens' or 'AdminRemoveTokens'
    local actionText = action == 'add' and 'añadido' or 'retirado'
    local emoji = action == 'add' and '➕' or '➖'
    
    local description = string.format('%s **%s** ha %s **%d DrTokens** %s **%s**', 
        emoji, adminName, actionText, amount, action == 'add' and 'a' or 'de', targetName)
    
    local fields = {
        {
            name = '👮‍♂️ Administrador',
            value = string.format('%s (ID: %s)', adminName, adminId),
            inline = true
        },
        {
            name = '👤 Jugador Objetivo',
            value = string.format('%s (ID: %s)', targetName, targetId),
            inline = true
        },
        {
            name = '💰 Cantidad',
            value = string.format('%d DrTokens', amount),
            inline = true
        }
    }
    
    SendDiscordWebhook(actionType, nil, description, fields)
end

-- Función para log de recompensas por hora
function LogHourlyReward(playerName, playerId, amount, totalTokens)
    if not Config.Discord.EnableWebhooks then return end
    
    local description = string.format('⏰ **%s** ha recibido **%d DrTokens** por jugar una hora completa', 
        playerName, amount)
    
    local fields = {
        {
            name = '👤 Jugador',
            value = string.format('%s (ID: %s)', playerName, playerId),
            inline = true
        },
        {
            name = '💰 Tokens Recibidos',
            value = string.format('%d DrTokens', amount),
            inline = true
        },
        {
            name = '🏦 Total de Tokens',
            value = string.format('%d DrTokens', totalTokens),
            inline = true
        }
    }
    
    SendDiscordWebhook('HourlyReward', nil, description, fields)
end

-- Función para log de transferencias entre jugadores 🆕
function LogTokenTransfer(fromName, fromId, toName, toId, amount)
    if not Config.Discord.EnableWebhooks then return end
    
    local description = string.format('🔄 **%s** ha transferido **%d DrTokens** a **%s**', 
        fromName, amount, toName)
    
    local fields = {
        {
            name = '👤 De',
            value = string.format('%s (ID: %s)', fromName, fromId),
            inline = true
        },
        {
            name = '👤 Para',
            value = string.format('%s (ID: %s)', toName, toId),
            inline = true
        },
        {
            name = '💰 Cantidad',
            value = string.format('%d DrTokens', amount),
            inline = true
        }
    }
    
    SendDiscordWebhook('PlayerActions', '🔄 Transferencia de Tokens', description, fields, 'Info')
end

-- Función para log de bonificaciones especiales 🆕
function LogBonusReward(playerName, playerId, bonusType, amount, totalReceived)
    if not Config.Discord.EnableWebhooks then return end
    
    local bonusEmojis = {
        daily = '🌅',
        weekend = '🎉',
        consecutive = '⏰'
    }
    
    local bonusNames = {
        daily = 'Bonificación Diaria',
        weekend = 'Bonificación de Fin de Semana',
        consecutive = 'Bonificación por Horas Consecutivas'
    }
    
    local emoji = bonusEmojis[bonusType] or '🎁'
    local bonusName = bonusNames[bonusType] or 'Bonificación Especial'
    
    local description = string.format('%s **%s** ha recibido **%d DrTokens** por %s', 
        emoji, playerName, amount, bonusName:lower())
    
    local fields = {
        {
            name = '👤 Jugador',
            value = string.format('%s (ID: %s)', playerName, playerId),
            inline = true
        },
        {
            name = '🎁 Tipo de Bonus',
            value = bonusName,
            inline = true
        },
        {
            name = '💰 Bonus Recibido',
            value = string.format('%d DrTokens', amount),
            inline = true
        }
    }
    
    if totalReceived then
        table.insert(fields, {
            name = '🏆 Total Recibido',
            value = string.format('%d DrTokens', totalReceived),
            inline = true
        })
    end
    
    SendDiscordWebhook('HourlyRewards', emoji .. ' ' .. bonusName, description, fields, 'Success')
end

-- Función para log de comandos de ranking 🆕
function LogRankingCommand(playerName, playerId)
    if not Config.Discord.EnableWebhooks then return end
    
    local description = string.format('🏆 **%s** ha consultado el ranking de DrTokens', playerName)
    
    local fields = {
        {
            name = '👤 Jugador',
            value = string.format('%s (ID: %s)', playerName, playerId),
            inline = true
        },
        {
            name = '📊 Comando',
            value = '/toptokens',
            inline = true
        },
        {
            name = '🕐 Hora',
            value = os.date('%H:%M:%S'),
            inline = true
        }
    }
    
    SendDiscordWebhook('PlayerActions', '🏆 Consulta de Ranking', description, fields, 'Info')
end

-- Función para log de permisos denegados 🆕
function LogPermissionDenied(playerName, playerId, command, reason)
    if not Config.Discord.EnableWebhooks then return end
    
    local description = string.format('🚫 **%s** intentó usar **%s** pero se le denegó el acceso', 
        playerName, command)
    
    local fields = {
        {
            name = '👤 Jugador',
            value = string.format('%s (ID: %s)', playerName, playerId),
            inline = true
        },
        {
            name = '⌨️ Comando',
            value = command,
            inline = true
        },
        {
            name = '🚫 Razón',
            value = reason or 'Sin permisos',
            inline = true
        }
    }
    
    SendDiscordWebhook('AdminActions', '🚫 Acceso Denegado', description, fields, 'Warning')
end

-- Función para log de conexión de jugadores
function LogPlayerConnection(playerName, playerId, action)
    if not Config.Discord.EnableWebhooks then return end
    
    local actionType = action == 'login' and 'PlayerLogin' or 'PlayerLogout'
    local actionText = action == 'login' and 'conectado' or 'desconectado'
    local emoji = action == 'login' and '🔓' or '🔒'
    
    local description = string.format('%s **%s** se ha %s al servidor', 
        emoji, playerName, actionText)
    
    local fields = {
        {
            name = '👤 Jugador',
            value = string.format('%s (ID: %s)', playerName, playerId),
            inline = true
        },
        {
            name = '🕐 Hora',
            value = os.date('%H:%M:%S'),
            inline = true
        }
    }
    
    SendDiscordWebhook(actionType, nil, description, fields)
end

-- Función para log de inicio del sistema
function LogSystemStart()
    if not Config.Discord.EnableWebhooks then return end
    
    local description = '🚀 **Sistema DrTokens iniciado correctamente**\n\n' ..
                       '📊 **Configuración Actual:**\n' ..
                       string.format('• Recompensa por hora: **%d tokens**\n', Config.HourlyReward) ..
                       string.format('• Verificación cada: **%d segundos**\n', Config.TimeSettings.CheckInterval / 1000) ..
                       string.format('• Logs habilitados: **%s**', Config.Logging.EnableLogs and 'Sí' or 'No')
    
    local fields = {
        {
            name = '⚙️ Estado',
            value = 'Sistema Operativo',
            inline = true
        },
        {
            name = '📅 Fecha',
            value = os.date('%d/%m/%Y'),
            inline = true
        },
        {
            name = '🕐 Hora',
            value = os.date('%H:%M:%S'),
            inline = true
        }
    }
    
    SendDiscordWebhook('SystemStart', nil, description, fields)
end

-- Función para log de comandos de jugadores
function LogPlayerCommand(playerName, playerId, command, tokens)
    if not Config.Discord.EnableWebhooks then return end
    
    local description = string.format('📋 **%s** ha usado el comando **%s**', 
        playerName, command)
    
    local fields = {
        {
            name = '👤 Jugador',
            value = string.format('%s (ID: %s)', playerName, playerId),
            inline = true
        },
        {
            name = '⌨️ Comando',
            value = command,
            inline = true
        }
    }
    
    if tokens then
        table.insert(fields, {
            name = '💰 Tokens Actuales',
            value = string.format('%d DrTokens', tokens),
            inline = true
        })
    end
    
    SendDiscordWebhook('PlayerActions', '📋 Comando Ejecutado', description, fields)
end

-- Función para log de comandos desde consola
function LogConsoleCommand(commandName)
    if not Config.Discord.EnableWebhooks then return end
    
    local description = string.format('⚠️ Se intentó ejecutar el comando **%s** desde la consola del servidor.\n\nEste comando requiere ser ejecutado por un jugador conectado.', commandName)
    
    local fields = {
        {
            name = '⌨️ Comando',
            value = commandName,
            inline = true
        },
        {
            name = '🖥️ Origen',
            value = 'Consola del Servidor',
            inline = true
        },
        {
            name = '🕐 Hora',
            value = os.date('%H:%M:%S'),
            inline = true
        }
    }
    
    SendDiscordWebhook('ConsoleCommand', '⚠️ Comando desde Consola', description, fields, 'Warning')
end

-- Función para log de tokens dados a todos los jugadores
function LogTokensToAll(adminName, adminId, amount, playersCount, isConsole)
    if not Config.Discord.EnableWebhooks then return end
    
    local origin = isConsole and 'Consola del Servidor' or ('Jugador Admin (ID: ' .. adminId .. ')')
    local description = string.format('🎉 **%s** ha dado **%d DrTokens** a **%d jugadores** online', 
        adminName, amount, playersCount)
    
    local fields = {
        {
            name = '👮‍♂️ Ejecutado por',
            value = adminName,
            inline = true
        },
        {
            name = '🖥️ Origen',
            value = origin,
            inline = true
        },
        {
            name = '💰 Cantidad por Jugador',
            value = amount .. ' DrTokens',
            inline = true
        },
        {
            name = '👥 Jugadores Afectados',
            value = playersCount .. ' jugadores online',
            inline = true
        },
        {
            name = '🏦 Total Distribuido',
            value = (amount * playersCount) .. ' DrTokens',
            inline = true
        },
        {
            name = '🕐 Hora',
            value = os.date('%H:%M:%S'),
            inline = true
        }
    }
    
    SendDiscordWebhook('MassTokens', '🎉 Tokens Masivos Distribuidos', description, fields, 'Success')
end

-- Función para probar webhook (solo para admins)
function TestDiscordWebhook(webhookType)
    webhookType = webhookType or 'General'
    
    local description = '🧪 **Test de webhook desde DrTokens**\n\nSi ves este mensaje, el webhook está funcionando correctamente.'
    
    local fields = {
        {
            name = '🔧 Tipo de Test',
            value = webhookType,
            inline = true
        },
        {
            name = '📅 Fecha',
            value = os.date('%d/%m/%Y'),
            inline = true
        },
        {
            name = '🕐 Hora',
            value = os.date('%H:%M:%S'),
            inline = true
        }
    }
    
    SendDiscordWebhook(webhookType, '🧪 Test de Webhook', description, fields, 'Info')
end

-- Función para log personalizado
function LogCustomEvent(title, description, fields, color, webhookType)
    if not Config.Discord.EnableWebhooks then return end
    
    webhookType = webhookType or 'General'
    SendDiscordWebhook(webhookType, title, description, fields, color)
end

-- Exports para usar desde otros archivos
exports('LogAdminAction', LogAdminAction)
exports('LogAdminSetTokens', LogAdminSetTokens)
exports('LogHourlyReward', LogHourlyReward)
exports('LogBonusReward', LogBonusReward)
exports('LogTokenTransfer', LogTokenTransfer)
exports('LogRankingCommand', LogRankingCommand)
exports('LogPermissionDenied', LogPermissionDenied)
exports('LogPlayerConnection', LogPlayerConnection)
exports('LogSystemStart', LogSystemStart)
exports('LogPlayerCommand', LogPlayerCommand)
exports('LogConsoleCommand', LogConsoleCommand)
exports('LogTokensToAll', LogTokensToAll)
exports('TestDiscordWebhook', TestDiscordWebhook)
exports('LogCustomEvent', LogCustomEvent)