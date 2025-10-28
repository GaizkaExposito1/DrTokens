# 🎮 Integración DrTokens con Origen PauseMenu

Esta guía te explica paso a paso cómo integrar el sistema de DrTokens con el **origen_pausemenu** para mostrar los tokens del jugador directamente en el menú de pausa junto con sus otras estadísticas.

## 📋 Requisitos Previos

- ✅ **origen_pausemenu** instalado y funcionando
- ✅ **Script drtokens** instalado y funcionando
- ✅ Acceso a los archivos de origen_pausemenu para modificación
- ✅ Conocimientos básicos de edición de archivos

## 🛠️ Paso 1: Preparar DrTokens

### 1.1 Verificar Callbacks
Los callbacks necesarios ya están añadidos automáticamente al servidor de DrTokens:
- `drtokens:server:getPlayerTokens`
- `drtokens:server:getPlayerInfo`

### 1.2 Verificar Funcionamiento
Asegúrate de que DrTokens funciona correctamente:
```lua
-- En el chat del juego, prueba:
/mytokens  -- Debe mostrar tu cantidad de tokens
```

## 📝 Paso 2: Modificar Origen PauseMenu

### 2.1 Modificar Client.lua
1. **Localiza** el archivo `client.lua` de **origen_pausemenu**
2. **Abre** el archivo `integration/origen_pausemenu_client.lua` de DrTokens
3. **Copia todo el contenido** y **pégalo al final** del client.lua de origen_pausemenu

### 2.2 Añadir HTML (UI)
1. **Localiza** el archivo HTML principal de origen_pausemenu (usualmente `ui/index.html` o `html/index.html`)
2. **Busca** la sección donde están las estadísticas del jugador
3. **Añade** un contenedor para DrTokens:

```html
<!-- Dentro de la sección de estadísticas del jugador -->
<div id="player-stats-container">
    <!-- Otras estadísticas existentes como dinero, banco, trabajo, etc. -->
    
    <!-- AÑADIR ESTA LÍNEA -->
    <div id="drtokens-stat"></div>
    
</div>

<!-- OPCIONAL: Para la barra superior -->
<div id="header-stats-container">
    <!-- Otros elementos del header -->
    
    <!-- AÑADIR ESTA LÍNEA SI QUIERES TOKENS EN LA BARRA SUPERIOR -->
    <div id="header-drtokens-container"></div>
    
</div>
```

### 2.3 Añadir CSS
1. **Localiza** el archivo CSS principal de origen_pausemenu
2. **Abre** el archivo `integration/origen_pausemenu_styles.css` de DrTokens
3. **Copia todo el contenido** y **pégalo al final** del CSS de origen_pausemenu

### 2.4 Añadir JavaScript
1. **Localiza** el archivo JavaScript principal (usualmente `app.js`, `main.js`, o `script.js`)
2. **Abre** el archivo `integration/origen_pausemenu_script.js` de DrTokens
3. **Copia todo el contenido** y **pégalo al final** del JS de origen_pausemenu

### 2.5 Integrar con la Función de Apertura del Menú
1. **Busca** la función que se ejecuta cuando se abre el menú de pausa
2. **Añade** esta línea dentro de esa función:

```javascript
// En la función de abrir menú, añadir:
initializeDrTokens();

// O alternativamente:
window.DrTokensUI.initialize();
```

**Ejemplo completo:**
```javascript
function openPauseMenu() {
    // ... código existente del origen_pausemenu
    
    isMenuOpen = true;
    
    // Cargar datos del jugador
    loadPlayerData();
    
    // AÑADIR ESTA LÍNEA:
    initializeDrTokens();
    
    // ... resto del código
}
```

## 🎨 Paso 3: Personalización (Opcional)

### 3.1 Cambiar Posición
Para cambiar donde aparecen los tokens en las estadísticas, modifica esta parte del JavaScript:

```javascript
// En origen_pausemenu_script.js, busca esta línea:
statsContainer.insertBefore(drTokensDiv, statsContainer.firstChild);

// Cámbiala por:
statsContainer.appendChild(drTokensDiv); // Para ponerlo al final
```

### 3.2 Cambiar Colores
En el CSS, puedes cambiar los colores:

```css
.drtokens-amount {
    color: #tu-color-aqui; /* Cambiar el dorado por tu color */
}

.drtokens-icon {
    background: linear-gradient(45deg, #tu-color1, #tu-color2);
}
```

### 3.3 Cambiar Icono
En el JavaScript, cambia el emoji:

```javascript
// Busca esta línea:
<div class="drtokens-icon">🪙</div>

// Cámbiala por:
<div class="drtokens-icon">💰</div> // O el emoji que prefieras
```

### 3.4 Personalizar Texto
Puedes cambiar el texto en el JavaScript:

```javascript
<div class="drtokens-label">DrTokens</div>
// Cambiar por:
<div class="drtokens-label">Tus Tokens</div>
```

## 🔄 Paso 4: Actualización Automática

### 4.1 Habilitar Actualizaciones en Tiempo Real
Para que los tokens se actualicen automáticamente cuando cambien, asegúrate de que esta función esté en el client.lua de origen_pausemenu:

```lua
-- Esta función ya está incluida en el código de integración
RegisterNetEvent('drtokens:client:updateTokensInMenu', function()
    if isMenuOpen then
        local tokens = GetDrTokens()
        SendNUIMessage({
            action = "updateDrTokens",
            tokens = tokens
        })
    end
end)
```

### 4.2 Actualización Periódica (Opcional)
Si quieres que se actualice cada 30 segundos, descomenta esta línea en el JavaScript:

```javascript
// Al final del archivo origen_pausemenu_script.js:
startDrTokensUpdateInterval(); // Descomenta esta línea
```

## 📱 Paso 5: Testing y Verificación

### 5.1 Reiniciar Resources
```
restart origen_pausemenu
restart drtokens
```

### 5.2 Probar la Integración
1. **Conéctate** al servidor
2. **Abre** el menú de pausa (ESC)
3. **Ve** a la sección de estadísticas del jugador
4. **Verifica** que aparezcan tus DrTokens

### 5.3 Probar Actualización
1. **Usa** el comando `/addtokens [tu_id] 100` (si eres admin)
2. **Abre** el menú de pausa
3. **Verifica** que se muestren los tokens actualizados

## 🎯 Ejemplo Visual

Así se verá en el origen_pausemenu:

```
┌─────────────────────────────────┐
│ 📊 Estadísticas del Jugador    │
├─────────────────────────────────┤
│ 💵 Dinero: $5,250              │
│ 🏦 Banco: $25,000              │
│ 🪙 DrTokens: 1,250             │
│    Última: Hace 30 minutos     │
│ 💼 Trabajo: Policía            │
│ 🎖️ Grado: Oficial              │
└─────────────────────────────────┘
```

## 🚨 Solución de Problemas

### Los tokens no aparecen:
1. ✅ Verifica que los callbacks estén añadidos al servidor de DrTokens
2. ✅ Revisa la consola F8 por errores JavaScript
3. ✅ Confirma que el HTML tenga el contenedor `id="player-stats-container"`
4. ✅ Verifica que `initializeDrTokens()` se llame al abrir el menú

### Los tokens no se actualizan:
1. ✅ Confirma que el event `drtokens:client:updateTokensInMenu` esté registrado
2. ✅ Verifica que el callback `getDrTokens` esté en el client.lua de origen_pausemenu
3. ✅ Revisa que no haya errores en la consola del navegador (F12)

### Errores de CSS/Estilo:
1. ✅ Verifica que el CSS esté añadido correctamente
2. ✅ Confirma que no haya conflictos con estilos existentes
3. ✅ Revisa que las clases CSS tengan nombres únicos

### Problemas de JavaScript:
1. ✅ Verifica que no haya errores de sintaxis
2. ✅ Confirma que las variables como `isMenuOpen` existan
3. ✅ Revisa la consola del navegador por errores

## 🔧 Configuración Avanzada

### Mostrar Solo en Ciertas Secciones
Si solo quieres mostrar tokens en ciertas páginas del menú:

```javascript
// Añadir condición en initializeDrTokens():
function initializeDrTokens() {
    if (currentMenuPage !== 'statistics') return; // Solo en estadísticas
    // ... resto del código
}
```

### Formato Personalizado de Números
Para cambiar cómo se muestran los números:

```javascript
// En lugar de:
const formattedTokens = tokens.toLocaleString();

// Usar:
const formattedTokens = tokens.toLocaleString('es-ES'); // Formato español
// O:
const formattedTokens = tokens.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
```

### Añadir Sonidos
Para añadir sonidos cuando se actualicen los tokens:

```javascript
function updateDrTokens(tokens) {
    // ... código existente
    
    // Añadir sonido
    PlaySound(-1, "TRANSACTION_POSITIVE", "HUD_RETICLE_SOUNDS", 0, 0, 1);
}
```

## 📋 Checklist Final

- [ ] Código Lua añadido al client.lua de origen_pausemenu
- [ ] HTML modificado con contenedores necesarios
- [ ] CSS añadido al archivo de estilos
- [ ] JavaScript añadido al archivo principal
- [ ] Función `initializeDrTokens()` llamada al abrir menú
- [ ] Resources reiniciados
- [ ] Funcionalidad probada en el juego

## 🎉 ¡Listo!

Si has seguido todos los pasos correctamente, ahora deberías ver tus DrTokens integrados perfectamente en el origen_pausemenu junto con todas tus otras estadísticas del jugador.

### 📞 Soporte

Si tienes problemas:
1. Revisa los logs de la consola (F8 en FiveM)
2. Verifica la consola del navegador (F12)
3. Confirma que ambos scripts estén funcionando por separado
4. Revisa que todos los archivos estén modificados correctamente

¡Disfruta de tu nuevo sistema de tokens integrado! 🪙✨