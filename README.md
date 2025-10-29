# DrTokens - Sistema de Tokens para FiveM QBCore

## 📋 Descripción
Script para FiveM con QB-Core que implementa un sistema de tokens (DrTokens) que los jugadores reciben automáticamente cada hora que permanecen conectados al servidor. Los administradores pueden gestionar los tokens de los jugadores.

## ✨ Características
- ✅ Recompensas automáticas cada hora de juego continuo
- ✅ **Sistema de bonificaciones especiales** 🆕
- ✅ **Transferencias entre jugadores** 🆕
- ✅ **Ranking de jugadores** 🆕
- ✅ Sistema de base de datos para persistencia
- ✅ Comandos de administración completos
- ✅ Comando para que jugadores vean sus tokens
- ✅ Configuración personalizable
- ✅ Sistema de logs para administradores
- ✅ **Logs de Discord con webhooks** 
- ✅ **Integración con origen_pausemenu** 
- ✅ Exports para integración con otros scripts
- ✅ Reinicio de tiempo al desconectarse (como solicitaste)

## 🚀 Instalación

### 1. Base de Datos
Ejecuta el archivo `drtokens.sql` en tu base de datos MySQL para crear la tabla necesaria.

### 2. Archivos del Resource
1. Copia la carpeta `drtokens` a tu directorio de resources
2. Añade `ensure drtokens` a tu server.cfg

### 3. Dependencias
- QB-Core Framework
- oxmysql (para base de datos)

### 4. Configurar Discord (Opcional)
Para recibir logs en Discord, sigue la guía en `DISCORD_SETUP.md`:
1. Crea webhooks en tu servidor de Discord
2. Configura las URLs en `config.lua`
3. Personaliza los tipos de logs que quieres recibir

### 5. Integrar con origen_pausemenu (Opcional)
Para mostrar tokens en el pause menu, sigue la guía en `integration/INSTALACION_ORIGEN_PAUSEMENU.md`:
1. Modifica los archivos de origen_pausemenu
2. Añade el código de integración
3. Personaliza la apariencia según tus gustos

## 🎮 Comandos Disponibles

### 👥 Para Jugadores
- `/mytokens` - Ver la cantidad de DrTokens que tienes
- `/tokeninfo` - Ver información sobre el sistema de tokens
- `/transfertokens [id] [cantidad]` - Transferir tokens a otro jugador 🆕 *(Configurable si requiere permisos)*
- `/toptokens` - Ver el ranking de los 10 jugadores con más tokens 🆕
- `/tokentime` - Ver tiempo restante para la próxima recompensa 🆕

### 🛡️ Para Administradores (Solo roles de Admin)
- `/givetokens [id] [cantidad]` - Añadir tokens a un jugador
- `/removetokens [id] [cantidad]` - Retirar tokens de un jugador
- `/settokens [id] [cantidad]` - Establecer cantidad exacta de tokens 🆕
- `/checktokens [id]` - Ver tokens de cualquier jugador

### 🖥️ Comandos de Consola del Servidor (Para administradores de servidor)
- `drp_giveall [cantidad]` - Dar tokens a todos los jugadores conectados 🆕
- `drp_help` - Mostrar ayuda completa de comandos de consola 🆕
- `drp_stats` - Ver estadísticas del sistema de tokens 🆕
- `drp_config` - Ver configuración actual del sistema 🆕
- `drp_testwebhook [tipo]` - Probar webhook específico (admin/player/reward/general) 🆕
- `drp_testallwebhooks` - Probar todos los webhooks disponibles 🆕
- `drp_webhookstatus` - Ver estado de configuración de webhooks 🆕
- `drp_webhookhelp` - Ayuda específica para sistema de webhooks 🆕

## ⚙️ Configuración Avanzada

### 🛠️ Opciones Principales
Edita el archivo `config.lua` para personalizar:

- **HourlyReward**: Cantidad de tokens por hora (por defecto: 10)
- **CheckInterval**: Frecuencia de verificación en milisegundos
- **Permissions**: Grupos que pueden usar comandos de admin
- **Notifications**: Mensajes y tipos de notificaciones
- **Logging**: Configuración de logs del servidor

### 🎁 Sistema de Bonificaciones
- **Bonificación diaria**: +20 tokens por primera conexión del día
- **Fin de semana**: Multiplicador 1.5x los sábados y domingos
- **Horas consecutivas**: Bonus adicionales (3h: +5, 6h: +15, 10h: +30)
- **Configurable**: Todos los bonus se pueden ajustar en config.lua

### 🔐 Sistema de Permisos
- **RequireAdminForTransfers**: Controla si las transferencias requieren permisos admin
- **AdminGroups**: Lista de grupos con acceso a comandos administrativos
- **Flexible**: Configuración granular de cada función

### 📡 Discord Webhooks
- **Logging completo**: 11 tipos diferentes de logs
- **4 webhooks organizados**: Admin, Jugadores, Recompensas, General
- **Tiempo real**: Notificaciones instantáneas de todas las actividades
- **Configurable**: Habilita/deshabilita logs específicos según necesites

## � Características del Sistema

### 🎯 **Funcionalidades Principales**
- ⏰ **Recompensas automáticas** cada hora de juego
- 🎁 **Sistema de bonificaciones** por tiempo y días especiales
- �🔄 **Transferencias entre jugadores** (configurable)
- 🏆 **Ranking de jugadores** con top 10
- 🛡️ **Comandos administrativos** completos
- 📡 **Logging Discord** en tiempo real
- 🎮 **Integración origen_pausemenu** para mostrar tokens

### 💎 **Sistema de Tokens Inteligente**
- **Persistencia**: Los tokens se guardan automáticamente en la base de datos
- **Anti-farm**: El tiempo se reinicia al desconectarse
- **Bonificaciones dinámicas**: Multiplicadores por tiempo jugado y días especiales
- **Transferencias seguras**: Sistema de intercambio entre jugadores con logs
- **Control administrativo**: Herramientas completas para gestión de la economía

### 🔐 **Seguridad y Control**
- **Permisos granulares**: Control fino sobre quién puede usar cada función
- **Logs completos**: Registro de todas las actividades en Discord
- **Validaciones**: Verificación de existencia de jugadores y cantidades válidas
- **Anti-abuse**: Sistema de detección de intentos no autorizados

## 🔄 Cómo Funciona el Sistema

### **🎮 Mecánica Principal**
1. **Conexión**: Cuando un jugador se conecta, el sistema inicia el contador de tiempo
2. **Bonificación diaria**: Primera conexión del día otorga bonus adicional (+20 tokens)
3. **Tiempo**: Cada minuto se verifica si ha pasado una hora completa (3600 segundos)
4. **Recompensa**: Al completar una hora, el jugador recibe tokens automáticamente
5. **Bonificaciones**: Se aplican multiplicadores especiales según el día y tiempo jugado
6. **Reinicio**: El contador se reinicia al recibir la recompensa o **al desconectarse**

### **🎁 Sistema de Bonificaciones Automáticas**
- **🌅 Login diario**: +20 tokens por primera conexión del día
- **🎉 Fin de semana**: 1.5x tokens los sábados y domingos  
- **⏰ Horas consecutivas**: Bonus adicionales escalonados:
  - 3 horas jugadas: +5 tokens extra
  - 6 horas jugadas: +15 tokens extra  
  - 10 horas jugadas: +30 tokens extra
- **🔄 Transferencias**: Los jugadores pueden enviarse tokens entre ellos

### **🏆 Ranking y Progreso**
- **📊 Top jugadores**: Ranking actualizado de los 10 jugadores con más tokens
- **⏰ Progreso individual**: Comando para ver tiempo restante para próxima recompensa
- **� Estadísticas**: Tracking completo de actividad y recompensas otorgadas
- **🎯 Competencia sana**: Sistema que fomenta el tiempo de juego y la participación

## 📊 Exports para Otros Scripts

```lua
-- Obtener tokens de un jugador
exports['drtokens']:GetPlayerTokens(citizenid, function(tokens)
    print('El jugador tiene: ' .. tokens .. ' DrTokens')
end)

-- Añadir tokens a un jugador
exports['drtokens']:AddPlayerTokens(citizenid, amount, function(success, newBalance)
    if success then
        print('Tokens añadidos. Nuevo balance: ' .. newBalance)
    end
end)

-- Remover tokens de un jugador
exports['drtokens']:RemovePlayerTokens(citizenid, amount, function(success, newBalance)
    if success then
        print('Tokens removidos. Nuevo balance: ' .. newBalance)
    end
end)

-- Establecer cantidad exacta de tokens
exports['drtokens']:SetPlayerTokens(citizenid, amount, function(success, newBalance)
    if success then
        print('Tokens establecidos en: ' .. newBalance)
    end
end)

-- Transferir tokens entre jugadores
exports['drtokens']:TransferTokens(fromCitizenid, toCitizenid, amount, function(success, fromBalance, toBalance)
    if success then
        print('Transferencia exitosa')
    end
end)

-- Obtener top 10 de jugadores
exports['drtokens']:GetTopPlayers(function(topPlayers)
    for i, player in ipairs(topPlayers) do
        print(i .. '. ' .. player.name .. ' - ' .. player.drtokens .. ' tokens')
    end
end)

-- Obtener tokens locales (client-side)
local tokens = exports['drtokens']:GetLocalTokens()
```

## 🎛️ Eventos para Otros Scripts

```lua
-- Evento cuando un jugador recibe tokens por hora
RegisterNetEvent('drtokens:hourlyReward', function(playerId, tokens, totalTokens)
    -- Tu código aquí
end)

-- Evento cuando un jugador recibe bonificación
RegisterNetEvent('drtokens:bonusReward', function(playerId, bonusAmount, bonusType, totalTokens)
    -- Tu código aquí
end)

-- Evento cuando se transfieren tokens
RegisterNetEvent('drtokens:tokenTransfer', function(fromPlayerId, toPlayerId, amount)
    -- Tu código aquí
end)

-- Evento cuando un admin modifica tokens
RegisterNetEvent('drtokens:adminAction', function(adminId, targetId, action, amount, newBalance)
    -- Tu código aquí
end)

-- Evento cuando se ejecuta distribución masiva 🆕
RegisterNetEvent('drtokens:massDistribution', function(amount, playersAffected, totalDistributed)
    -- Tu código aquí
end)
```

## 🖥️ Sistema de Comandos de Consola Avanzado 🆕

### 📋 **Guía Completa de Comandos de Consola**
El sistema DrTokens incluye un conjunto completo de comandos especializados para la administración desde la consola del servidor. Estos comandos están diseñados específicamente para administradores de servidor y ofrecen funcionalidades avanzadas no disponibles en los comandos de juego.

### 🎯 **Comandos Principales**

#### 📊 **Información y Estadísticas**
```console
drp_help                    # Muestra ayuda completa con todos los comandos
drp_stats                   # Estadísticas del sistema (jugadores, tokens, etc.)
drp_config                  # Configuración actual del sistema
```

#### 🎁 **Distribución Masiva de Tokens**
```console
drp_giveall [cantidad]      # Da tokens a todos los jugadores conectados
                            # - Sistema de confirmación para cantidades >100
                            # - Logging completo en consola y Discord
                            # - Manejo robusto de errores
```

**Ejemplo de uso:**
```console
drp_giveall 50             # Da 50 tokens a todos los jugadores
drp_giveall 150            # Requiere confirmación (cantidad >100)
```

#### 🔧 **Sistema de Testing de Webhooks**
```console
drp_testwebhook [tipo]      # Prueba webhook específico
drp_testallwebhooks         # Prueba todos los webhooks
drp_webhookstatus           # Estado de configuración de webhooks
drp_webhookhelp            # Ayuda específica para webhooks
```

**Tipos de webhook disponibles:**
- `admin` - Webhook de acciones administrativas
- `player` - Webhook de acciones de jugadores  
- `reward` - Webhook de recompensas
- `general` - Webhook general del sistema

**Ejemplos:**
```console
drp_testwebhook admin      # Prueba solo el webhook de admin
drp_testallwebhooks        # Ejecuta prueba completa de todos
drp_webhookstatus          # Verifica configuración actual
```

### 🛡️ **Características de Seguridad**

#### ⚠️ **Sistema de Confirmación**
- **Distribuciones masivas >100 tokens**: Requieren confirmación adicional
- **Logging automático**: Todas las operaciones se registran automáticamente
- **Validación de entrada**: Verificación de parámetros y rangos válidos

#### 📝 **Logging Especializado**
- **Consola del servidor**: Logs detallados con timestamps y contexto
- **Discord webhooks**: Notificaciones automáticas de operaciones masivas
- **Separación de contextos**: Logs diferentes para consola vs. comandos de jugador

### 🔍 **Troubleshooting con Comandos de Consola**

#### 🔧 **Diagnóstico de Webhooks**
1. **Verificar configuración**: `drp_webhookstatus`
2. **Probar conexión individual**: `drp_testwebhook [tipo]`
3. **Prueba completa**: `drp_testallwebhooks`
4. **Ayuda específica**: `drp_webhookhelp`

#### 📊 **Monitoreo del Sistema**
1. **Ver estadísticas**: `drp_stats`
2. **Revisar configuración**: `drp_config`
3. **Ayuda general**: `drp_help`

### 💡 **Casos de Uso Comunes**

#### 🎉 **Eventos Especiales**
```console
# Evento de doble tokens para todos
drp_giveall 100

# Verificar que los webhooks funcionan antes del evento
drp_testallwebhooks
```

#### 🔧 **Mantenimiento**
```console
# Verificar estado del sistema
drp_stats
drp_config

# Probar comunicación Discord
drp_webhookstatus
drp_testwebhook admin
```

#### 🚀 **Puesta en Producción**
```console
# Lista de verificación pre-lanzamiento
drp_config                  # Verificar configuración
drp_testallwebhooks        # Probar todos los webhooks
drp_stats                  # Verificar estadísticas base
```

## 📁 Estructura de Archivos Completa
```
drtokens/
├── fxmanifest.lua                      # Manifiesto principal del resource
├── config.lua                         # Configuración completa del sistema
├── drtokens.sql                       # Script de base de datos
├── server/
│   ├── server.lua                     # Lógica principal del servidor
│   └── discord.lua                    # Sistema completo de webhooks Discord 🆕
├── client/
│   └── client.lua                     # Lógica del cliente
├── integration/                       # Integración con origen_pausemenu 🆕
│   ├── origen_pausemenu_client.lua    # Código de integración
│   ├── origen_pausemenu_styles.css    # Estilos CSS personalizados
│   ├── origen_pausemenu_script.js     # JavaScript para UI
│   └── INSTALACION_ORIGEN_PAUSEMENU.md # Guía de instalación
├── README.md                          # Este archivo
├── DISCORD_SETUP.md                   # Guía de configuración Discord
├── DISCORD_WEBHOOK_GUIDE.md           # Guía completa de webhooks 🆕
└── WEBHOOK_UPDATE_SUMMARY.md          # Resumen de actualizaciones 🆕
```

## � Sistema de Logs Completo

### 🖥️ **Logs de Consola Avanzados** 🆕
- **Registro completo**: Todas las acciones importantes se registran automáticamente
- **Comandos de consola**: Sistema especial de logging para comandos ejecutados desde consola
- **Debugging avanzado**: Información detallada de errores con contexto completo
- **Seguimiento de operaciones**: Monitoreo de todas las operaciones de base de datos
- **Logs separados**: Diferentes niveles de logging para consola vs. Discord webhooks
- **Sistema administrativo**: Logging especial para acciones masivas como `drp_giveall`

### 📡 **Discord Webhooks** (11 tipos de logs)
El sistema incluye un sistema completo de logging a Discord con **11 tipos diferentes** de logs:

#### 🛡️ **Logs Administrativos** (AdminActions webhook)
- **AdminAddTokens**: Cuando un admin añade tokens
- **AdminRemoveTokens**: Cuando un admin retira tokens  
- **AdminSetTokens**: Cuando un admin establece cantidad exacta 🆕
- **PermissionDenied**: Intentos de acceso no autorizado 🆕

#### 👥 **Logs de Jugadores** (PlayerActions webhook)
- **TokenTransfer**: Transferencias entre jugadores 🆕
- **PlayerLogin**: Conexiones al servidor
- **PlayerLogout**: Desconexiones del servidor
- **RankingCommand**: Consultas del comando /toptokens 🆕

#### 🎁 **Logs de Recompensas** (HourlyRewards webhook)
- **HourlyReward**: Recompensas por hora (opcional, puede causar spam)
- **BonusReward**: Bonificaciones especiales por tiempo jugado 🆕

#### ⚙️ **Logs del Sistema** (General webhook)
- **SystemStart**: Inicio del sistema con configuración actual
- **ConsoleCommand**: Comandos ejecutados desde la consola del servidor 🆕
- **MassDistribution**: Distribución masiva de tokens (drp_giveall) 🆕
- **WebhookTest**: Pruebas de webhooks realizadas desde consola 🆕

### 🎨 **Características de los Logs Discord**
- **Embeds ricos**: Información organizada y visualmente atractiva
- **Colores codificados**: Verde (éxito), Naranja (advertencia), Rojo (error), Azul (info), Morado (admin)
- **Campos detallados**: Jugador, cantidad, saldos, timestamps, etc.
- **Tiempo real**: Notificaciones instantáneas sin retrasos
- **Configurables**: Cada tipo de log se puede habilitar/deshabilitar individualmente

## 🛠️ Personalización Avanzada

### 🖥️ **Sistema de Comandos de Consola** 🆕
El sistema incluye un conjunto completo de comandos para administrar desde la consola del servidor:

#### 📋 **Comandos Básicos**
- **drp_help**: Muestra ayuda completa con todos los comandos disponibles
- **drp_stats**: Estadísticas del sistema (jugadores online, tokens distribuidos, etc.)
- **drp_config**: Muestra la configuración actual del sistema

#### 🎁 **Distribución Masiva**
- **drp_giveall [cantidad]**: Da tokens a todos los jugadores conectados
  - Sistema de confirmación para cantidades superiores a 100 tokens
  - Logging completo de la operación en consola y Discord
  - Manejo de errores robusto

#### 🔧 **Testing de Webhooks**
- **drp_testwebhook [tipo]**: Prueba webhook específico (admin/player/reward/general)
- **drp_testallwebhooks**: Ejecuta prueba completa de todos los webhooks
- **drp_webhookstatus**: Verifica estado y configuración de webhooks
- **drp_webhookhelp**: Guía específica para troubleshooting de webhooks

### ⏰ **Cambiar Tiempo de Recompensa**
En `config.lua`, modifica `Config.TimeSettings.HourlyTime` (en segundos):
```lua
HourlyTime = 3600  -- 1 hora (por defecto)
HourlyTime = 1800  -- 30 minutos
HourlyTime = 7200  -- 2 horas
```

### 🎁 **Configurar Bonificaciones**
```lua
Config.Bonuses = {
    DailyLogin = {
        enabled = true,
        amount = 20        -- Tokens por primer login del día
    },
    WeekendMultiplier = {
        enabled = true,
        multiplier = 1.5   -- 1.5x tokens en fin de semana
    },
    ConsecutiveHours = {
        enabled = true,
        bonuses = {
            [3] = 5,          -- +5 tokens a las 3 horas
            [6] = 15,         -- +15 tokens a las 6 horas
            [10] = 30         -- +30 tokens a las 10 horas
        }
    }
}
```

### 🔐 **Personalizar Permisos**
```lua
Config.Permissions = {
    AdminGroups = {'admin', 'god', 'owner'},
    RequireAdminForTransfers = false,  -- true = solo admins pueden transferir
}
```

### 📡 **Configurar Discord Webhooks**
```lua
Config.Discord = {
    EnableWebhooks = true,
    Webhooks = {
        General = 'tu_webhook_general',
        AdminActions = 'tu_webhook_admin',
        PlayerActions = 'tu_webhook_players',
        HourlyRewards = 'tu_webhook_rewards'
    },
    LogTypes = {
        -- Habilitar/deshabilitar logs específicos
        HourlyReward = { enabled = false },  -- Evita spam
        AdminAddTokens = { enabled = true },
        TokenTransfer = { enabled = true },
        ConsoleCommand = { enabled = true },  -- 🆕 Comandos de consola
        MassDistribution = { enabled = true },  -- 🆕 Distribución masiva
        WebhookTest = { enabled = true },  -- 🆕 Pruebas de webhooks
        -- ... más configuraciones
    }
}
```

### Cambiar Cantidad de Tokens
En `config.lua`, modifica `Config.HourlyReward`:
```lua
Config.HourlyReward = 25  -- 25 tokens por hora
```

### Configurar Discord Webhooks
Sigue la guía completa en `DISCORD_SETUP.md` o configuración rápida:

```lua
-- En config.lua
Config.Discord.EnableWebhooks = true
Config.Discord.Webhooks.AdminActions = 'TU_WEBHOOK_DE_DISCORD'
```

### Configurar Permisos de Transferencias
Para controlar quién puede usar `/givetokens`:

```lua
-- En config.lua
Config.Permissions.RequireAdminForTransfers = false  -- Cualquiera puede transferir
Config.Permissions.RequireAdminForTransfers = true   -- Solo admins pueden transferir
```

### Añadir Más Grupos de Admin
```

### Cambiar Permisos de Admin
En `config.lua`:
```lua
Config.Permissions.AdminGroup = 'superadmin'  -- Cambiar grupo
```

## 🔍 Solución de Problemas Común

### ❌ **Los tokens no se dan automáticamente**
1. **Verifica la base de datos**: Ejecuta `drtokens.sql` y confirma que la tabla existe
2. **Revisa los logs**: Comprueba la consola del servidor para errores
3. **QB-Core**: Confirma que QB-Core esté funcionando correctamente
4. **oxmysql**: Verifica que oxmysql esté configurado y conectado

### ❌ **Comandos de admin no funcionan**
1. **Permisos**: Verifica que tengas el grupo 'admin' en QB-Core
2. **Jugador online**: Confirma que el jugador objetivo esté conectado
3. **Sintaxis**: Revisa que uses la sintaxis correcta `/givetokens [id] [cantidad]`
4. **Configuración**: Verifica `Config.Permissions.AdminGroups` en config.lua

### ❌ **Transferencias no funcionan**
1. **Configuración**: Revisa `Config.Permissions.RequireAdminForTransfers`
2. **Saldo suficiente**: El jugador debe tener tokens suficientes
3. **ID válido**: Verifica que el ID del destinatario sea correcto
4. **Permisos**: Si está configurado, solo admins pueden transferir

### ❌ **Discord webhooks no aparecen**
1. **URLs correctas**: Verifica que las URLs de webhook sean válidas
2. **Configuración**: Confirma que `EnableWebhooks = true`
3. **Logs específicos**: Revisa que el tipo de log esté habilitado
4. **Permisos Discord**: El webhook debe tener permisos de enviar mensajes
5. **Testing**: Usa `drp_testwebhook [tipo]` desde consola para probar 🆕
6. **Estado**: Ejecuta `drp_webhookstatus` para ver configuración actual 🆕

### ❌ **Origen pausemenu no muestra tokens**
1. **Integración**: Sigue la guía en `integration/INSTALACION_ORIGEN_PAUSEMENU.md`
2. **Archivos modificados**: Confirma que modificaste los archivos correctos
3. **Resource restart**: Reinicia el resource origen_pausemenu
4. **JavaScript**: Verifica que no hay errores en la consola F12

## 🎯 Características Destacadas

### 💎 **Sistema Inteligente**
- **⏰ Tiempo real preciso**: Sistema que cuenta exactamente cada minuto jugado
- **🔄 Anti-farm**: Imposible hacer farm desconectándose y reconectándose
- **🎁 Bonificaciones automáticas**: Sistema que recompensa la dedicación
- **🏆 Competencia sana**: Ranking que fomenta el tiempo de juego
- **🖥️ Administración de consola**: Sistema completo de comandos para administradores 🆕
- **🔧 Testing integrado**: Herramientas para probar webhooks y validar configuración 🆕

### 🛡️ **Seguridad Avanzada**
- **👮‍♂️ Control granular**: Permisos específicos para cada función
- **📡 Monitoreo total**: Logs completos de todas las actividades
- **🔒 Validaciones**: Verificación exhaustiva de datos y permisos
- **🚫 Anti-abuse**: Detección de intentos no autorizados
- **🖥️ Logging de consola**: Registro separado para comandos administrativos 🆕
- **⚠️ Sistema de confirmación**: Protección para operaciones masivas críticas 🆕

### 🔧 **Flexibilidad Total**
- **⚙️ Configuración completa**: Personaliza cada aspecto del sistema
- **🔗 Exports robustos**: Integración fácil con otros scripts
- **🎮 UI integrada**: Compatible con origen_pausemenu
- **📱 Discord ready**: Sistema de notificaciones profesional
- **🖥️ Administración avanzada**: Sistema completo de comandos de consola 🆕
- **🔍 Debugging integrado**: Herramientas de testing y diagnóstico built-in 🆕

## � Próximas Actualizaciones

### 🛒 **Versión 2.0 (Planificada)**
- **🏪 Sistema de tienda**: Compra items con DrTokens
- **🎰 Sistema de gambling**: Minijuegos con tokens
- **🏅 Sistema de logros**: Recompensas por objetivos
- **📊 Dashboard web**: Panel de administración

### 🔮 **Funcionalidades Futuras**
- **💱 Intercambio dinámico**: Conversión con otras monedas
- **📈 Economía avanzada**: Inflación y deflación automática
- **🎭 Eventos especiales**: Bonificaciones por eventos del servidor
- **🤝 Sistema de alianzas**: Grupos que comparten tokens

## 📄 Información del Resource

### 📋 **Detalles Técnicos**
- **Versión Actual**: 2.1.0 (Sistema de Consola Completo + Testing de Webhooks) 🆕
- **Compatible con**: QB-Core Framework
- **Dependencias**: oxmysql
- **Base de datos**: MySQL/MariaDB
- **Funcionalidades**: Sistema completo con comandos de consola y testing avanzado
- **Última Actualización**: Octubre 2025

### 👨‍💻 **Desarrollo**
- **Autor**: DrTokens System Development Team
- **Soporte**: Completo con documentación detallada y sistema de testing integrado 🆕
- **Licencia**: Open Source para servidores FiveM
- **Actualizaciones**: Sistema modular con comandos de consola para administración avanzada
- **Testing**: Herramientas integradas para validación de webhooks y sistema completo

---

### 💬 **Soporte y Comunidad**
Para obtener ayuda adicional, consulta:
- 📖 **DISCORD_WEBHOOK_GUIDE.md** - Guía completa de Discord
- 🔧 **integration/INSTALACION_ORIGEN_PAUSEMENU.md** - Integración UI
- 📊 **WEBHOOK_UPDATE_SUMMARY.md** - Resumen de características
- 🗃️ **config.lua** - Todas las opciones de configuración
- 🖥️ **Comandos de consola integrados** - Usa `drp_help` para ayuda en tiempo real 🆕

### 🛠️ **Herramientas de Diagnóstico Integradas** 🆕
El sistema incluye herramientas built-in para troubleshooting:
- **Webhook testing**: `drp_testallwebhooks` para verificar conectividad Discord
- **Estado del sistema**: `drp_stats` y `drp_config` para diagnóstico rápido
- **Ayuda contextual**: `drp_webhookhelp` para problemas específicos de webhooks
- **Logging avanzado**: Todos los comandos de consola se registran automáticamente

**¡Disfruta tu sistema DrTokens completo y profesional con herramientas de administración avanzadas! 🚀**