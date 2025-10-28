Config = {}

-- Configuración de recompensas
Config.HourlyReward = 10  -- Cantidad de DrTokens que recibe el jugador cada hora

-- Configuración de bonificaciones especiales
Config.Bonuses = {
    Enabled = true,              -- Habilitar sistema de bonificaciones
    
    -- Bonificación por horas consecutivas (mismo día)
    ConsecutiveHours = {
        enabled = true,
        bonuses = {
            {hours = 3, bonus = 5},   -- +5 tokens adicionales a las 3 horas
            {hours = 6, bonus = 15},  -- +15 tokens adicionales a las 6 horas
            {hours = 10, bonus = 30}, -- +30 tokens adicionales a las 10 horas
        }
    },
    
    -- Bonificación de fin de semana (Sábado y Domingo)
    Weekend = {
        enabled = true,
        multiplier = 1.5,  -- 1.5x tokens los fines de semana
    },
    
    -- Bonificación por primera conexión del día
    DailyLogin = {
        enabled = true,
        bonus = 20,  -- +20 tokens por primera conexión del día
    }
}

-- Configuración de comandos (puedes cambiar los nombres si quieres)
Config.Commands = {
    AddTokens = 'addtokens',        -- Comando para añadir tokens (solo admins)
    RemoveTokens = 'removetokens',  -- Comando para retirar tokens (solo admins)
    SetTokens = 'settokens',        -- Comando para establecer cantidad exacta (solo admins)
    MyTokens = 'mytokens',          -- Comando para ver tokens propios
    GiveTokens = 'givetokens',      -- Comando para transferir tokens entre jugadores
    TopTokens = 'toptokens',        -- Comando para ver ranking de tokens
    TokenTime = 'tokentime',        -- Comando para ver tiempo restante
    TokenInfo = 'tokeninfo'         -- Comando para ver información del sistema
}

-- Configuración de notificaciones
Config.Notifications = {
    HourlyReward = {
        enabled = true,
        message = 'Has recibido %s DrTokens por jugar una hora completa!',
        type = 'success',
        duration = 5000
    },
    AdminAdd = {
        message = 'Has añadido %s DrTokens a %s',
        type = 'success'
    },
    AdminRemove = {
        message = 'Has retirado %s DrTokens de %s',
        type = 'success'
    },
    PlayerReceived = {
        message = 'Has recibido %s DrTokens de un administrador',
        type = 'success'
    },
    PlayerRemoved = {
        message = 'Se te han retirado %s DrTokens por un administrador',
        type = 'error'
    }
}

-- Configuración de permisos
Config.Permissions = {
    AdminGroup = 'admin',  -- Grupo que puede usar comandos de administrador
    ModGroup = 'mod',      -- Si quieres que moderadores también puedan usar comandos (opcional)
    
    -- Configuración específica para transferencias entre jugadores
    RequireAdminForTransfers = false,  -- true = solo admins pueden usar /givetokens, false = todos pueden
}

-- Configuración de tiempo
Config.TimeSettings = {
    CheckInterval = 60000,    -- Cada cuánto tiempo se verifica (en milisegundos) - 60000 = 1 minuto
    HourlyTime = 3600,        -- Tiempo en segundos para recompensa (3600 = 1 hora)
    EnableTimeReset = true    -- Si se reinicia el tiempo al desconectarse
}

-- Configuración de logs
Config.Logging = {
    EnableLogs = true,           -- Habilitar logs en consola
    LogAdminActions = true,      -- Log cuando admins añaden/retiran tokens
    LogHourlyRewards = false     -- Log cuando se dan recompensas por hora (puede ser spam)
}

-- Configuración de Discord Webhooks
Config.Discord = {
    EnableWebhooks = true,       -- Habilitar webhooks de Discord
    
    -- URLs de los webhooks (configura tus propios webhooks aquí)
    Webhooks = {
        AdminActions = 'https://discord.com/api/webhooks/TU_WEBHOOK_ADMIN_AQUI',        -- Acciones de admins
        HourlyRewards = 'https://discord.com/api/webhooks/TU_WEBHOOK_REWARDS_AQUI',    -- Recompensas por hora
        PlayerActions = 'https://discord.com/api/webhooks/TU_WEBHOOK_PLAYERS_AQUI',    -- Acciones de jugadores
        General = 'https://discord.com/api/webhooks/TU_WEBHOOK_GENERAL_AQUI'           -- Logs generales
    },
    
    -- Configuración de colores para embeds
    Colors = {
        Success = 65280,    -- Verde
        Error = 16711680,   -- Rojo
        Info = 3447003,     -- Azul
        Warning = 16776960, -- Amarillo
        Admin = 9109504     -- Morado
    },
    
    -- Configuración de logs específicos
    LogTypes = {
        AdminAddTokens = {
            enabled = true,
            webhook = 'AdminActions',
            color = 'Success',
            title = '💰 Tokens Añadidos por Admin'
        },
        AdminRemoveTokens = {
            enabled = true,
            webhook = 'AdminActions',
            color = 'Warning',
            title = '🚫 Tokens Retirados por Admin'
        },
        AdminSetTokens = {
            enabled = true,
            webhook = 'AdminActions',
            color = 'Admin',
            title = '⚙️ Tokens Establecidos por Admin'
        },
        TokenTransfer = {
            enabled = true,
            webhook = 'PlayerActions',
            color = 'Info',
            title = '🔄 Transferencia de Tokens'
        },
        HourlyReward = {
            enabled = false,  -- Puede ser spam, cambiar a true si quieres
            webhook = 'HourlyRewards',
            color = 'Success',
            title = '⏰ Recompensa por Hora'
        },
        BonusReward = {
            enabled = true,
            webhook = 'HourlyRewards',
            color = 'Success',
            title = '🎁 Bonificación Especial'
        },
        PlayerLogin = {
            enabled = true,
            webhook = 'PlayerActions',
            color = 'Info',
            title = '🔓 Jugador Conectado'
        },
        PlayerLogout = {
            enabled = true,
            webhook = 'PlayerActions',
            color = 'Info',
            title = '🔒 Jugador Desconectado'
        },
        RankingCommand = {
            enabled = true,
            webhook = 'PlayerActions',
            color = 'Info',
            title = '🏆 Consulta de Ranking'
        },
        PermissionDenied = {
            enabled = true,
            webhook = 'AdminActions',
            color = 'Warning',
            title = '🚫 Acceso Denegado'
        },
        SystemStart = {
            enabled = true,
            webhook = 'General',
            color = 'Success',
            title = '🚀 Sistema DrTokens Iniciado'
        }
    },
    
    -- Configuración del servidor
    ServerInfo = {
        name = 'Tu Servidor FiveM',  -- Nombre de tu servidor
        icon = 'https://i.imgur.com/placeholder.png',  -- URL del icono de tu servidor
        footer = 'DrTokens System v1.0'
    }
}

-- Configuración de base de datos
Config.Database = {
    TableName = 'player_drtokens',
    InitializeNewPlayers = true  -- Crear entrada automáticamente para nuevos jugadores
}