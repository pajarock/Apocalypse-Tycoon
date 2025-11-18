# ✨ FEATURES - Apocalypse Tycoon

Lista completa de features implementadas, organizadas por categoría.

---

## 🎯 GAMEPLAY CORE

### 🏗️ Base System
- **HP System:** Bases con vida, regeneración automática y sistema de shields
- **Damage System:** Recibe daño de meteoritos, con visual feedback
- **Regeneration:** Regenera HP automáticamente después de 5 segundos sin daño
- **Shield Upgrades:** Reduce daño recibido hasta 15% por nivel
- **Repair System:** Repara tu base manualmente gastando coins (10 coins/HP)
- **Visual States:** Colores cambian según HP (Normal → Damaged → Critical → Burning)
- **Procedural Generation:** Cada base es única visualmente

### 💰 Economy System
- **Starting Cash:** Empiezas con 100 coins
- **Passive Income:** Genera dinero cada segundo (configurable)
- **Kill Rewards:** Gana coins extra al destruir meteoritos/enemigos
- **Offline Earnings:** Gana hasta 2 horas de ingresos offline (50% rate)
- **DataStore:** Progreso se guarda automáticamente cada 2 minutos
- **Max Cash:** Límite de 1 quadrillón (1e15)

### 🌊 Wave System
- **Progressive Difficulty:** Cada wave aumenta la dificultad
- **Boss Waves:** Boss aparece cada X oleadas (configurable)
- **Mini-Boss Waves:** Mini-Boss aparece entre bosses
- **Auto-Spawn:** Al skip waves con debug, spawns Boss/Mini-Boss automáticamente
- **Wave Counter UI:** UI épica muestra progreso actual
- **Wave Sync:** Sistema sincronizado servidor-cliente sin duplicación

### 🎯 Shop & Upgrades
- **10+ Upgrades disponibles:**
  - **Damage:** Aumenta daño base
  - **Attack Speed:** Aumenta velocidad de ataque
  - **Income:** Aumenta ingresos pasivos
  - **Max HP:** Aumenta vida máxima de la base
  - **Regen Rate:** Mejora velocidad de regeneración
  - **Shield:** Reduce daño recibido
  - **Range:** Aumenta rango de ataque
  - **Critical Chance:** Aumenta probabilidad de críticos
  - **Critical Multiplier:** Aumenta daño de críticos
  - **Auto-Collect:** Colecta coins automáticamente

- **UI Features:**
  - Slide-in animation al abrir
  - Hover effects (scale + glow)
  - Purchase feedback (bounce + particles)
  - Precio visible y actualización en tiempo real
  - Tooltip con descripción de upgrade

---

## ⚡ COMBAT & MOVEMENT

### 🏃 Dash System
- **Direccional Dash:** Shift + WASD para dash en cualquier dirección
- **Forward Dash:** Solo Shift para dash hacia adelante
- **Cooldown:** 2.5 segundos entre dashes
- **Cooldown UI:** Visual feedback del tiempo restante
- **Distance:** 30 studs por dash
- **Speed:** Dash rápido y responsive

### 🛡️ Evasion Mechanics
- **Invulnerability:** 0.3 segundos de invulnerabilidad durante dash
- **Efecto Fantasmal:** Player se vuelve semi-transparente (Transparency 0.6)
- **Meteor Evasion:** Evade meteoritos automáticamente durante dash
- **Visual Feedback:**
  - Screen flash verde al evadir exitosamente
  - Texto "¡EVADIDO!" flotante estilo grafiti
  - Particles de éxito
  - Sound effect
- **Server Authority:** Validación en servidor previene cheating

### 💥 Meteor System
- **3 Tipos de Meteoritos:**
  - **Small:** Rápido (60 speed), bajo daño (10), pequeño (3x3x3)
  - **Normal:** Medio (45 speed), daño medio (25), mediano (6x6x6)
  - **Large:** Lento (30 speed), alto daño (50), grande (10x10x10)

- **Meteor Features:**
  - Trail épico con colores dinámicos
  - Explosión espectacular al impactar
  - Daño a bases en radio
  - HP individual (pueden ser destruidos)
  - Rotación aleatoria
  - Spawn desde el cielo

### 🦖 Enemy System (Base)
- **Boss:** Enemigos épicos con mucha HP y daño
- **Mini-Boss:** Versión reducida del Boss
- **Spawn System:** Aparecen en waves específicas
- **Target System:** Atacan bases automáticamente

---

## 🎨 VISUAL EFFECTS (VFX)

### 💫 VFX Manager
- **Object Pooling:** Reusa partículas para mejor performance
- **Centralized System:** Todos los efectos desde un solo manager
- **Data-Driven:** Configuración en VFXConfig.lua
- **Mobile-Optimized:** Auto-reduce intensity en mobile (50%)
- **Performance Stats:** Tracking de active/pooled effects

### 🎆 Effect Types
- **Meteor Trail:** Trail colorido que sigue al meteorito
- **Meteor Explosion:** Explosión épica con particles y light
- **Purchase Success:** Efecto al comprar upgrade en shop
- **Damage Hit:** Feedback visual al recibir daño
- **Income Popup:** Visualización de coins ganados
- **Construction Build:** Efectos al construir/mejorar
- **Dash Trail:** Trail durante el dash
- **Evasion Success:** Particles al evadir meteorito

### 📊 Damage Numbers
- **Floating Damage:** Números flotan y desaparecen
- **Estilo Grafiti Urbano:** Font y colores tipo street art
- **Color Coding:**
  - Rojo para daño normal
  - Amarillo para críticos
  - Verde para evasiones exitosas
- **Scale Animation:** Bounce effect al aparecer
- **Fade Out:** Desvanecimiento suave

### 📹 Camera Effects
- **Camera Shake:** Shake dinámico en impactos
  - Heavy: Impactos de meteoritos grandes
  - Medium: Impactos normales
  - Light: Efectos menores
- **Screen Flash:** Flash de color en eventos importantes
  - Rojo: Daño a tu base
  - Verde: Evasión exitosa
  - Amarillo: Warning de Boss
- **Mobile-Safe:** Intensity reducida en dispositivos móviles

---

## 🎨 UI/UX

### 🏪 Shop UI
- **Diseño Urbano/Grafiti:** Estética street art
- **Animaciones:**
  - Slide-in desde el lado (0.4s)
  - Slide-out al cerrar (0.3s)
  - Hover effects en botones
  - Bounce feedback al comprar
- **Colores Neón:** Acentos cyan/magenta (#00FFFF, #FF00FF)
- **Gradientes:** Backgrounds con degradados
- **Responsive:** Se adapta a diferentes tamaños de pantalla
- **Toggle con B:** Abre/cierra con tecla B

### 📊 Wave Counter UI
- **Display Épico:** Muestra wave actual prominentemente
- **Progress Bar:** Barra de progreso para siguiente Boss/Mini-Boss
- **Boss Indicator:** Alerta visual cuando Boss está cerca
- **Style Matching:** Estética consistente con Shop UI
- **Real-time Update:** Actualización instantánea al cambiar wave

### ❤️ Health Bar
- **Visual HP:** Barra de vida colorida
- **HP Text:** Número actual / máximo
- **Color Transitions:**
  - Verde: HP alto (>66%)
  - Amarillo: HP medio (33-66%)
  - Rojo: HP bajo (<33%)
- **Smooth Animations:** Transiciones suaves al recibir daño

### 💀 Death Screen UI
- **Stats Display:** Muestra estadísticas de la partida
  - Waves sobrevividas
  - Meteoritos destruidos
  - Tiempo jugado
  - Coins ganados
- **Opciones:**
  - Respawn (si disponible)
  - Volver al lobby
- **Estilo Grafiti:** Matching con el resto del UI

### 🔔 Notifications System
- **Event Notifications:** Alertas para eventos importantes
  - Boss incoming
  - Mini-Boss spawned
  - Wave completed
  - Achievement unlocked
- **Toast Style:** Aparecen y desaparecen automáticamente
- **Color Coding:** Diferentes colores según importancia
- **Sound Effects:** Audio feedback opcional

---

## 🛠️ SYSTEMS & MANAGERS

### 💾 DataStore System
- **Auto-Save:** Guarda progreso cada 2 minutos
- **Data Schema:**
  - Cash
  - Upgrades comprados y niveles
  - Stats (waves, kills, playtime)
  - Offline time tracking
- **Versioning:** Sistema de versiones para migrations
- **Error Handling:** Retry logic para fallos de conexión
- **Backup:** Guarda última data válida

### 📚 Tutorial Manager
- **New Player Tutorial:** Guía paso a paso para nuevos jugadores
- **Progressive:** Se desbloquea según avanza el jugador
- **Skippable:** Opción de skip para veteranos
- **Highlight System:** Resalta elementos importantes
- **One-Time:** Solo se muestra una vez (guardado en DataStore)

### 🌍 Environment Manager
- **Ambient Effects:** Efectos ambientales del mundo
- **Lighting Control:** Control de iluminación dinámica
- **Weather Base:** Base para futuros sistemas de clima
- **Optimization:** Efectos ajustados según device performance

### 🎨 Procedural Generation
- **Base Models:** Cada base es única visualmente
- **Variation System:** Diferentes shapes, colors, patterns
- **Performance-Friendly:** Modelos optimizados
- **Deterministic:** Misma seed = mismo resultado

### 🏗️ Build Effects Manager
- **Construction VFX:** Efectos al construir
- **Upgrade VFX:** Efectos al mejorar estructuras
- **Particle System:** Particles durante construcción
- **Sound Integration:** Audio feedback

---

## 🐛 DEBUG & TOOLS

### 🎮 Debug Controls (Solo Studio)
- **M Key:** Spawn meteorito manual en tu base
- **N Key:** Skip a la siguiente wave
- **Debug Logs:** Información detallada en Output
- **Performance Stats:** FPS y memory usage
- **Auto-Enabled:** Se activa automáticamente en Studio

### 🔍 Debug Features
- **Verbose Logging:** Logs detallados de eventos
- **Error Tracking:** Catch y log de errores
- **State Inspection:** Ver estado interno de sistemas
- **Remote Monitoring:** Monitor de RemoteEvents

---

## 📱 OPTIMIZATION

### ⚡ Performance Features
- **Object Pooling:** VFX reusados para reducir instancing
- **LOD System:** Efectos reducidos a distancia
- **Mobile Detection:** Auto-ajusta quality en mobile
- **Frame Budget:** Mantiene 60 FPS en PC, 30 en mobile
- **Memory Management:** Cleanup automático de assets no usados

### 📊 Benchmarks
| Escenario | PC (FPS) | Mobile (FPS) |
|-----------|----------|--------------|
| Idle | 60 | 30 |
| 10 Meteoritos | 58 | 28 |
| 30 Meteoritos | 50 | 24 |
| Boss Fight | 55 | 26 |

---

## 🚧 EN DESARROLLO

### ⚡ Power-Ups System (Próximo)
- Power-ups temporales que dropean de enemigos
- Tipos: Shield, Slow-Mo, Coin Rain, Auto-Repair
- Visual feedback épico
- Drop rate configurable

### 🐾 Pet Gacha System (Próximo)
- Huevos que se abren con RNG
- Pets te siguen a todos lados
- Bonuses pasivos (income, damage, etc.)
- Raridades: Common, Rare, Epic, Legendary
- Colección de pets

---

## 📊 STATS

### 📈 Métricas Implementadas
- **Total Features:** 50+
- **Scripts:** 30+ archivos .lua
- **UI Elements:** 8 interfaces principales
- **VFX Effects:** 10+ tipos de efectos
- **Upgrades:** 10 tipos diferentes
- **Managers:** 6 sistemas principales

### 🎯 Coverage
- ✅ Core Gameplay: 100%
- ✅ Combat System: 100%
- ✅ Economy: 100%
- ✅ VFX: 100%
- ✅ UI/UX: 100%
- 🔄 Meta Systems: 60% (Achievements, Quests pendientes)
- 🔄 Social: 0% (Guilds, Trading pendientes)

---

## 🎉 QUALITY OF LIFE

### ✨ UX Features
- **Hotkeys:** B para shop, Shift para dash
- **Auto-Save:** No necesitas guardar manualmente
- **Responsive UI:** Se adapta a diferentes pantallas
- **Visual Feedback:** Siempre sabes qué está pasando
- **Sound Design:** Audio para todas las acciones importantes
- **Tutorial:** Aprende jugando
- **Debug Mode:** Testing fácil en Studio

### 🔄 Polish
- **Smooth Animations:** Todas las transiciones son suaves
- **Consistent Style:** UI unificada estilo grafiti/urbano
- **Performance:** 60 FPS target en PC
- **Mobile Support:** Funciona bien en tablets/phones
- **Error Handling:** El juego no crashea por errores
- **Recovery:** Auto-reconexión si se pierde conexión

---

¿Quieres saber más sobre alguna feature específica? Checa el código fuente o abre un issue en GitHub.
