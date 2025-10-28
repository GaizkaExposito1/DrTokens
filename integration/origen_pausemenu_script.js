/* JAVASCRIPT PARA ORIGEN_PAUSEMENU - DRTOKENS */
/* Añadir este código al archivo app.js o main.js del origen_pausemenu */

// Variable global para almacenar tokens
let playerDrTokens = 0;
let drTokensLastReward = null;

// Función para actualizar los DrTokens en la interfaz
function updateDrTokens(tokens) {
    playerDrTokens = tokens;
    
    // Actualizar en la sección de estadísticas del jugador
    const drTokensElement = document.getElementById('player-drtokens');
    if (drTokensElement) {
        // Formatear número con comas
        const formattedTokens = tokens.toLocaleString();
        drTokensElement.textContent = formattedTokens;
        
        // Añadir clase especial para números grandes
        if (tokens >= 10000) {
            drTokensElement.classList.add('large-amount');
        }
        
        // Añadir animación de actualización
        const container = drTokensElement.closest('.drtokens-container');
        if (container) {
            container.classList.add('drtokens-updated');
            setTimeout(() => {
                container.classList.remove('drtokens-updated');
            }, 1500);
        }
    }
    
    // Actualizar en la barra superior (si existe)
    const headerTokensElement = document.getElementById('header-drtokens');
    if (headerTokensElement) {
        headerTokensElement.textContent = tokens.toLocaleString();
    }
}

// Función para formatear la fecha de última recompensa
function formatLastReward(dateString) {
    if (!dateString) return 'Nunca';
    
    const date = new Date(dateString);
    const now = new Date();
    const diffMinutes = Math.floor((now - date) / (1000 * 60));
    
    if (diffMinutes < 1) return 'Ahora mismo';
    if (diffMinutes < 60) return `Hace ${diffMinutes} min`;
    
    const diffHours = Math.floor(diffMinutes / 60);
    if (diffHours < 24) return `Hace ${diffHours}h`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `Hace ${diffDays}d`;
}

// Función para crear el HTML de DrTokens en las estadísticas
function createDrTokensHTML(tokens, lastReward) {
    const formattedTokens = tokens.toLocaleString();
    const formattedLastReward = formatLastReward(lastReward);
    
    return `
        <div class="drtokens-container">
            <div class="drtokens-icon">🪙</div>
            <div class="drtokens-info">
                <div class="drtokens-label">DrTokens</div>
                <div class="drtokens-amount ${tokens >= 10000 ? 'large-amount' : ''}" id="player-drtokens">${formattedTokens}</div>
                <div class="drtokens-last-reward drtokens-tooltip" data-tooltip="Última recompensa recibida">
                    Última recompensa: ${formattedLastReward}
                </div>
            </div>
        </div>
    `;
}

// Función para crear el indicador en la barra superior
function createHeaderDrTokensHTML(tokens) {
    return `
        <div class="header-drtokens">
            <div class="header-drtokens-icon"></div>
            <span class="header-drtokens-text" id="header-drtokens">${tokens.toLocaleString()}</span>
        </div>
    `;
}

// Event listeners para los mensajes del cliente
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'updatePlayerStats':
            // Cuando se actualizan las estadísticas del jugador
            if (data.data.drTokens !== undefined) {
                updateDrTokens(data.data.drTokens);
                drTokensLastReward = data.data.drTokensLastReward;
                
                // Si tienes acceso al contenedor de estadísticas, añadir DrTokens
                const statsContainer = document.getElementById('player-stats-container');
                if (statsContainer && !document.getElementById('drtokens-stat')) {
                    const drTokensHTML = createDrTokensHTML(data.data.drTokens, data.data.drTokensLastReward);
                    const drTokensDiv = document.createElement('div');
                    drTokensDiv.id = 'drtokens-stat';
                    drTokensDiv.innerHTML = drTokensHTML;
                    
                    // Insertar después de dinero/banco si existe, sino al inicio
                    const moneyElement = statsContainer.querySelector('[id*="money"], [id*="bank"]');
                    if (moneyElement) {
                        moneyElement.parentNode.insertBefore(drTokensDiv, moneyElement.nextSibling);
                    } else {
                        statsContainer.insertBefore(drTokensDiv, statsContainer.firstChild);
                    }
                }
                
                // Añadir a la barra superior si existe el contenedor
                const headerContainer = document.getElementById('header-stats-container');
                if (headerContainer && !document.getElementById('header-drtokens-container')) {
                    const headerHTML = createHeaderDrTokensHTML(data.data.drTokens);
                    const headerDiv = document.createElement('div');
                    headerDiv.id = 'header-drtokens-container';
                    headerDiv.innerHTML = headerHTML;
                    headerContainer.appendChild(headerDiv);
                }
            }
            break;
            
        case 'updateDrTokens':
            // Cuando solo se actualizan los tokens
            updateDrTokens(data.tokens);
            break;
            
        case 'showDrTokensNotification':
            // Mostrar notificación especial para DrTokens
            if (typeof showNotification === 'function') {
                showNotification(data.message, data.type || 'success', data.duration || 3000);
            }
            break;
    }
});

// Función para inicializar DrTokens en el menu (llamar cuando se abra el menu)
function initializeDrTokens() {
    // Solicitar tokens al cliente
    fetch(`https://${GetParentResourceName()}/getDrTokens`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).catch(error => {
        console.log('Error fetching DrTokens:', error);
    });
}

// Función para actualizar tokens periódicamente (opcional)
function startDrTokensUpdateInterval() {
    setInterval(() => {
        if (isMenuOpen) { // Usar la variable del origen_pausemenu
            initializeDrTokens();
        }
    }, 30000); // Actualizar cada 30 segundos
}

// Función utilitaria para obtener el nombre del resource padre
function GetParentResourceName() {
    return window.location.hostname.split('.')[0] || 'origin_pausemenu';
}

// Función para mostrar animación de tokens recibidos
function showTokensReceivedAnimation(amount) {
    const container = document.querySelector('.drtokens-container');
    if (!container) return;
    
    // Crear elemento de animación
    const animationElement = document.createElement('div');
    animationElement.className = 'tokens-received-animation';
    animationElement.textContent = `+${amount}`;
    animationElement.style.cssText = `
        position: absolute;
        color: #ffd700;
        font-weight: bold;
        font-size: 18px;
        z-index: 1000;
        animation: tokensReceived 2s ease-out forwards;
        pointer-events: none;
    `;
    
    // Añadir CSS de animación si no existe
    if (!document.getElementById('tokens-animation-style')) {
        const style = document.createElement('style');
        style.id = 'tokens-animation-style';
        style.textContent = `
            @keyframes tokensReceived {
                0% {
                    opacity: 1;
                    transform: translateY(0) scale(1);
                }
                50% {
                    opacity: 1;
                    transform: translateY(-20px) scale(1.2);
                }
                100% {
                    opacity: 0;
                    transform: translateY(-40px) scale(0.8);
                }
            }
        `;
        document.head.appendChild(style);
    }
    
    container.style.position = 'relative';
    container.appendChild(animationElement);
    
    // Eliminar elemento después de la animación
    setTimeout(() => {
        if (animationElement.parentNode) {
            animationElement.parentNode.removeChild(animationElement);
        }
    }, 2000);
}

// Exportar funciones para uso externo
window.DrTokensUI = {
    updateTokens: updateDrTokens,
    initialize: initializeDrTokens,
    showReceivedAnimation: showTokensReceivedAnimation,
    formatLastReward: formatLastReward
};

// Auto-inicializar si está en el contexto correcto
if (typeof isMenuOpen !== 'undefined') {
    // startDrTokensUpdateInterval(); // Descomenta si quieres actualizaciones automáticas
}