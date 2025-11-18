# 🔥 APOCALYPSE TYCOON

**Sobrevive al Apocalipsis. Construye tu Imperio. Derrota a los Dinosaurios.**

Un juego de tycoon para Roblox donde defiendes tu base de oleadas interminables de meteoritos y dinosaurios, mientras construyes un imperio económico y desbloqueas upgrades épicos.

---

## 🎮 GAMEPLAY

- **Defiende tu Base:** Sobrevive oleadas de meteoritos que caen del cielo
- **Sistema de Waves:** Enfréntate a Boss y Mini-Boss cada cierto número de oleadas
- **Economía Progresiva:** Gana dinero pasivamente y con cada meteorito destruido
- **Upgrades Estratégicos:** Mejora daño, velocidad de ataque, regeneración, shields y más
- **Dash & Evasion:** Esquiva meteoritos con un sistema de dash direccional + invulnerabilidad temporal
- **Efectos Visuales Épicos:** VFX procedurales, números de daño flotantes, UI con estilo urbano/grafiti
- **Procedural Generation:** Modelos de bases y enemigos generados proceduralmente

---

## ✨ FEATURES PRINCIPALES

### 🎯 Gameplay Core
- ✅ Sistema de Bases con HP, regeneración y shields
- ✅ Sistema de Meteoritos con diferentes tipos (Small, Normal, Large)
- ✅ Sistema de Oleadas (Waves) con dificultad progresiva
- ✅ Boss Fights y Mini-Boss cada X oleadas
- ✅ Economía con ingresos pasivos y rewards por kills
- ✅ Shop con 10+ upgrades estratégicos

### ⚡ Combat & Movement
- ✅ **Dash System:** Shift + WASD para dash direccional con cooldown visual
- ✅ **Evasion Mechanics:** Invulnerabilidad temporal (0.3s) durante dash
- ✅ **Efecto Fantasmal:** Player semi-transparente durante evasión
- ✅ **Feedback Visual:** Screen flash y particles al evadir exitosamente

### 🎨 Visual Effects
- ✅ **VFX Manager:** Sistema centralizado de efectos con object pooling
- ✅ **Meteor Trails:** Trails épicos con explosiones espectaculares
- ✅ **Damage Numbers:** Números flotantes con estilo grafiti urbano
- ✅ **UI Animations:** Slide-in, hover effects, bounce feedback
- ✅ **Camera Shake:** Shake dinámico en impactos y eventos importantes
- ✅ **Procedural Models:** Bases y enemigos con variación visual

### 🎨 UI/UX
- ✅ **Shop UI:** Diseño urbano/grafiti con animaciones suaves
- ✅ **Wave Counter:** UI épica con progreso de oleadas
- ✅ **Health Bar:** Barra de vida con indicadores visuales
- ✅ **Death Screen:** UI de muerte con stats y opciones
- ✅ **Notifications:** Sistema de notificaciones para eventos importantes

### 🛠️ Systems
- ✅ DataStore para persistencia de datos
- ✅ Tutorial Manager para nuevos jugadores
- ✅ Environment Manager para efectos ambientales
- ✅ Debug Controls para testing (Solo en Studio)

---

## 📁 ESTRUCTURA DEL PROYECTO

```
Apocalypse-Tycoon/
├── ServerStorage/
│   ├── Config/
│   │   ├── Config.lua ........................ Configuración global del juego
│   │   └── VFXConfig.lua ..................... Templates de efectos visuales
│   ├── Managers/
│   │   ├── VFXManager.lua .................... Sistema de partículas con pooling
│   │   ├── BaseVisualsManager.lua ............ Visuales de bases
│   │   ├── BuildEffectsManager.lua ........... Efectos de construcción
│   │   ├── EnvironmentManager.lua ............ Ambiente y clima
│   │   └── ProceduralModels.lua .............. Generación procedural
│   ├── EventManager_REFACTORED.lua ........... Sistema de meteoritos y eventos
│   ├── MeteorDamageSystem.lua ................ Sistema de daño
│   └── TutorialManager.lua ................... Tutorial para nuevos jugadores
│
├── StarterPlayerScripts/
│   ├── DashModule.client.lua ................. Sistema de dash del jugador
│   ├── WaveCounterUI.client.lua .............. UI de contador de oleadas
│   ├── PlayerHealthUI.client.lua ............. UI de salud
│   └── NotificationUI.client.lua ............. Sistema de notificaciones
│
├── src/
│   ├── StarterGui/
│   │   ├── ShopUI/Shop.client.lua ............ Cliente del shop con animaciones
│   │   ├── DamageNumbers.client.lua .......... Números de daño flotantes
│   │   ├── EventNotifier.client.lua .......... Notificador de eventos
│   │   ├── BaseDeathUI.client.lua ............ UI de muerte
│   │   └── BaseHUD/BaseHUD.client.lua ........ HUD principal
│   └── StarterPlayer/StarterPlayerScripts/
│       ├── ProximityUpgrades.client.lua ...... Sistema de compra por proximidad
│       └── DebugControls.client.lua .......... Controles de debug (M/N keys)
│
├── docs/
│   └── archive/ ............................. Documentación histórica
│
├── snippets/ ................................ Scripts de arreglos/testing
│
├── README.md ................................ Este archivo
├── FEATURES.md .............................. Lista detallada de features
└── CHANGELOG.md ............................. Historial de cambios
```

---

## 🚀 CÓMO EMPEZAR

### Para Desarrolladores

1. **Abre el proyecto en Roblox Studio**
2. **Estructura de carpetas:**
   - `ServerStorage/` → Scripts del servidor
   - `StarterPlayerScripts/` → Scripts del cliente
   - `ReplicatedStorage/` → Scripts compartidos y Remotes

3. **Testing en Studio:**
   - Presiona **Play** para iniciar el juego
   - Presiona **M** para spawnear meteorito manual (debug)
   - Presiona **N** para skip a la siguiente wave (debug)
   - Presiona **B** para abrir/cerrar el shop

4. **Debug Mode:**
   - Automáticamente activado en Studio
   - Ver logs en Output para troubleshooting

### Para Jugadores

1. **Spawneo Inicial:**
   - Al entrar al juego, se te asigna una base automáticamente
   - Tu base aparece en un círculo alrededor del centro del mapa

2. **Controles:**
   - **WASD** → Movimiento
   - **Shift + WASD** → Dash direccional (evade meteoritos)
   - **B** → Abrir/Cerrar Shop
   - **Click** en botones del shop para comprar upgrades

3. **Objetivo:**
   - Sobrevive el mayor número de oleadas posible
   - Gana dinero para comprar upgrades
   - Derrota Bosses y Mini-Bosses para grandes recompensas

---

## 🔧 CONFIGURACIÓN

### Ajustar Dificultad

Edita `ServerStorage/Config/Config.lua`:

```lua
-- Vida de la base
Config.BASE_MAX_HP = 100 -- Sube para hacer el juego más fácil

-- Daño de meteoritos
Config.METEOR_TYPES.Normal.Damage = 25 -- Baja para reducir dificultad

-- Cooldown del dash
-- En DashModule.client.lua línea 42
local DASH_COOLDOWN = 2.5 -- Baja para más dashes
```

### Ajustar Economía

```lua
-- En Config.lua
Config.START_CASH = 100 -- Cash inicial
Config.INCOME_TICK_INTERVAL = 1 -- Frecuencia de ingresos pasivos
```

### Cambiar Efectos Visuales

Edita `ServerStorage/Config/VFXConfig.lua` para cambiar colores, intensidad y duración de efectos visuales.

---

## 📈 ROADMAP

### 🚧 En Desarrollo
- ✅ **Power-Ups System:** Power-ups temporales que dropean de meteoritos *(COMPLETADO)*
- 🔄 **Pet Gacha System:** Huevos con pets que te siguen y dan bonuses *(PRÓXIMO)*

### 💡 Futuras Features
- ⏳ Sistema de Logros/Achievements
- ⏳ Misiones Diarias/Semanales
- ⏳ Sistema de Clima Dinámico
- ⏳ Modo PvP (competición de bases)
- ⏳ Leaderboards globales

---

## 🐛 TROUBLESHOOTING

### El juego no inicia
- Verifica que todos los módulos estén en las carpetas correctas
- Checa la consola (F9) para errores
- Asegúrate de tener `ReplicatedStorage/Remotes/` con los RemoteEvents necesarios

### Dash no funciona
- Verifica que `DashModule.client.lua` esté en `StarterPlayerScripts/`
- Checa que exista `ReplicatedStorage/Remotes/DashRequest` (RemoteEvent)
- Cooldown default es 2.5s, espera entre dashes

### Shop no abre con B
- Verifica que `Shop.client.lua` esté en `StarterGui/ShopUI/`
- Asegúrate que el Frame principal del Shop se llame `ShopFrame`

### Meteoritos no causan daño
- Verifica que `MeteorDamageSystem.lua` esté en `ServerStorage/`
- Checa que `EventManager_REFACTORED.lua` esté activo

---

## 📞 SOPORTE

Para reportar bugs o sugerir features:
1. Abre un **Issue** en GitHub
2. Incluye:
   - Descripción del problema
   - Pasos para reproducir
   - Screenshots/Videos si es posible
   - Logs de la consola (F9 en Roblox)

---

## 📝 LICENCIA

Este proyecto es privado y propiedad de **pajarock**.

---

## 🎉 CRÉDITOS

**Desarrollado con 💥 para crear la experiencia de tycoon apocalíptico definitiva**

*"Sobrevive. Construye. Domina."*

---

## 🔗 LINKS ÚTILES

- [FEATURES.md](FEATURES.md) - Lista completa de features implementadas
- [CHANGELOG.md](CHANGELOG.md) - Historial de cambios
- [docs/archive/](docs/archive/) - Documentación histórica
