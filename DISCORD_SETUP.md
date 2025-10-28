# 🔗 Configuración de Discord Webhooks para DrTokens

Esta guía te explica cómo configurar los webhooks de Discord para recibir logs del sistema DrTokens directamente en tus canales de Discord.

## 📋 Requisitos Previos

- ✅ Servidor de Discord con permisos de administrador
- ✅ Script DrTokens instalado y funcionando
- ✅ Acceso al archivo `config.lua`

## 🛠️ Paso 1: Crear Webhooks en Discord

### 1.1 Crear Canales (Recomendado)
Crea los siguientes canales en tu servidor de Discord:
- `🔧-admin-actions` - Para acciones de administradores
- `⏰-hourly-rewards` - Para recompensas por hora (opcional)
- `👥-player-actions` - Para conexiones/desconexiones
- `📊-drtokens-general` - Para logs generales

### 1.2 Configurar Webhooks
Para cada canal:

1. **Clic derecho en el canal** → `Editar Canal`
2. Ve a **`Integraciones`** → **`Webhooks`**
3. Clic en **`Crear Webhook`**
4. **Configura el webhook:**
   - **Nombre**: `DrTokens Bot`
   - **Avatar**: Sube una imagen (opcional)
   - **Canal**: Selecciona el canal correcto
5. **Copia la URL del webhook** - La necesitarás para el config.lua

Repite este proceso para cada canal que quieras usar.

## ⚙️ Paso 2: Configurar el Script

### 2.1 Editar config.lua
Abre el archivo `config.lua` y busca la sección `Config.Discord.Webhooks`:

```lua
Webhooks = {
    AdminActions = 'TU_WEBHOOK_ADMIN_AQUI',
    HourlyRewards = 'TU_WEBHOOK_REWARDS_AQUI', 
    PlayerActions = 'TU_WEBHOOK_PLAYERS_AQUI',
    General = 'TU_WEBHOOK_GENERAL_AQUI'
},
```

**Reemplaza cada URL** con las URLs de webhook que copiaste de Discord:

```lua
Webhooks = {
    AdminActions = 'https://discord.com/api/webhooks/123456789/abcdef...',
    HourlyRewards = 'https://discord.com/api/webhooks/987654321/fedcba...',
    PlayerActions = 'https://discord.com/api/webhooks/456789123/ghijkl...',
    General = 'https://discord.com/api/webhooks/321654987/mnopqr...'
},
```

### 2.2 Configurar Información del Servidor
En la sección `Config.Discord.ServerInfo`:

```lua
ServerInfo = {
    name = 'Mi Servidor FiveM',  -- Nombre de tu servidor
    icon = 'https://i.imgur.com/tu-logo.png',  -- URL del logo de tu servidor
    footer = 'DrTokens System v1.0'
}
```

### 2.3 Activar/Desactivar Logs
En la sección `Config.Discord.LogTypes` puedes activar o desactivar cada tipo de log:

```lua
LogTypes = {
    AdminAddTokens = {
        enabled = true,     -- Cambiar a false para desactivar
        webhook = 'AdminActions',
        color = 'Success',
        title = '💰 Tokens Añadidos por Admin'
    },
    -- ... otros logs
}
```

## 🎨 Paso 3: Personalización

### 3.1 Cambiar Colores
Puedes cambiar los colores de los embeds:

```lua
Colors = {
    Success = 65280,    -- Verde (decimal)
    Error = 16711680,   -- Rojo
    Info = 3447003,     -- Azul
    Warning = 16776960, -- Amarillo
    Admin = 9109504     -- Morado
}
```

### 3.2 Personalizar Títulos y Mensajes
Cada tipo de log tiene un título personalizable:

```lua
AdminAddTokens = {
    enabled = true,
    webhook = 'AdminActions',
    color = 'Success',
    title = '💰 Tu Título Personalizado'  -- Cambiar aquí
},
```

## 📊 Tipos de Logs Disponibles

### 🔧 Admin Actions (Acciones de Admins)
- **Añadir tokens**: Cuando un admin usa `/addtokens`
- **Retirar tokens**: Cuando un admin usa `/removetokens`

**Información mostrada**:
- Nombre del administrador
- Jugador objetivo
- Cantidad de tokens
- Hora y fecha

### ⏰ Hourly Rewards (Recompensas por Hora)
- **Recompensa recibida**: Cuando un jugador recibe tokens por hora

**Información mostrada**:
- Nombre del jugador
- Tokens recibidos
- Total de tokens del jugador
- Hora y fecha

### 👥 Player Actions (Acciones de Jugadores)
- **Conexión**: Cuando un jugador se conecta
- **Desconexión**: Cuando un jugador se desconecta
- **Comandos**: Cuando usan `/mytokens`

**Información mostrada**:
- Nombre del jugador
- Acción realizada
- Tokens actuales (para comandos)
- Hora y fecha

### 📊 General (Logs Generales)
- **Inicio del sistema**: Cuando se inicia DrTokens
- **Logs personalizados**: Para futuras funcionalidades

## 🔍 Ejemplo de Embed

Así se verá un log en Discord:

```
🔧 DrTokens Bot                                   HOY 15:30

💰 Tokens Añadidos por Admin

➕ Admin Juan Pérez ha añadido 50 DrTokens a María García

👮‍♂️ Administrador          👤 Jugador Objetivo          💰 Cantidad
Juan Pérez (ID: 1)          María García (ID: 15)        50 DrTokens

DrTokens System v1.0 • 28/10/2025 15:30:25
```

## 🚨 Solución de Problemas

### Webhook no funciona:
1. ✅ Verifica que la URL sea correcta
2. ✅ Confirma que el bot tenga permisos en el canal
3. ✅ Revisa la consola del servidor por errores

### No aparecen logs:
1. ✅ Verifica que `EnableWebhooks = true`
2. ✅ Confirma que el tipo de log esté `enabled = true`
3. ✅ Revisa que el webhook esté asignado correctamente

### Logs duplicados:
1. ✅ Verifica que no tengas webhooks duplicados
2. ✅ Confirma que no hay conflictos con otros scripts

## ⚡ Configuración Rápida

Si quieres configuración mínima, solo necesitas:

1. **Crear un webhook** en Discord
2. **Cambiar esta línea** en config.lua:
```lua
EnableWebhooks = true,
```
3. **Pegar tu webhook** en:
```lua
AdminActions = 'TU_WEBHOOK_AQUI',
```

Con esto ya tendrás logs de acciones de administradores.

## 🎯 Configuración Avanzada

### Webhook Específico por Acción
Puedes usar diferentes webhooks para diferentes acciones editando la sección `LogTypes`.

### Formato de Mensajes Personalizado
Los mensajes se pueden personalizar editando las funciones en `server/discord.lua`.

### Filtros Avanzados
Puedes añadir condiciones adicionales en las funciones de log para filtrar qué se envía a Discord.

## 📱 Testing

Para probar que funciona:

1. **Reinicia el resource**: `restart drtokens`
2. **Ejecuta un comando**: `/addtokens [id] 10`
3. **Verifica Discord**: Deberías ver el log

## 🔒 Seguridad

- ⚠️ **No compartas** las URLs de webhook públicamente
- 🔐 **Usa permisos** adecuados en los canales de Discord
- 🛡️ **Regenera webhooks** si se comprometen

¡Ya tienes configurados los logs de Discord para DrTokens! 🎉