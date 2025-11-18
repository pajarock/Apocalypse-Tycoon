# 📝 CHANGELOG - Apocalypse Tycoon

Historial de cambios importantes del proyecto.

---

## [5.0.0] - 2024 - DASH SYSTEM & VISUAL OVERHAUL

### 🎉 Major Features

#### ⚡ Dash System con Evasion
- **Dash Direccional:** Shift + WASD para dash en cualquier dirección
- **Cooldown Visual:** UI muestra tiempo restante para siguiente dash
- **Invulnerabilidad:** 0.3s de invulnerabilidad durante dash
- **Efecto Fantasmal:** Player se vuelve semi-transparente durante evasión
- **Feedback Visual Épico:**
  - Screen flash verde al evadir
  - Texto "¡EVADIDO!" flotante estilo grafiti
  - Particles de éxito
  - Sound effects

#### 🎨 Visual Effects Overhaul
- **VFX Manager:** Sistema centralizado con object pooling
- **Meteor Effects:** Trails y explosiones espectaculares
- **Damage Numbers:** Números flotantes estilo grafiti urbano
- **Camera Shake:** Shake dinámico en impactos
- **UI Animations:** Slide-in, hover, bounce effects

#### 🎨 UI Redesign - Estilo Urbano/Grafiti
- **Shop UI:** Rediseño completo con estética street art
- **Wave Counter:** UI épica con progreso visual
- **Health Bar:** Barra de vida con color transitions
- **Death Screen:** UI de muerte con stats
- **Notifications:** Sistema de notificaciones toast

### 🐛 Bug Fixes

#### Wave System
- **Fix:** Doble barra de progreso en Wave Counter (eliminada duplicación)
- **Fix:** Boss/Mini-Boss no spawneaban al skip waves (ahora auto-spawn)
- **Fix:** Sync issues entre servidor-cliente en wave counter
- **Fix:** Wave counter no se actualizaba correctamente

#### Dash System
- **Fix:** Teleport bugs al dash cerca de paredes
- **Fix:** Evasion VFX no se mostraban correctamente
- **Fix:** Dash cooldown no se reseteaba en ciertas condiciones
- **Fix:** Múltiples dashes simultáneos (explotación)

#### Shop & UI
- **Fix:** Shop UI DisplayOrder incorrecto (layering problems)
- **Fix:** Botones del shop no respondían correctamente
- **Fix:** Popup de "-$XXX" no se mostraba al comprar
- **Fix:** Hover effects no se removían al cerrar shop

#### Base System
- **Fix:** Guardian (base defender) duraba demasiado (ajustada duración)
- **Fix:** Múltiples muertes de base (death event duplicado)
- **Fix:** Penalizaciones de muerte se aplicaban incorrectamente
- **Fix:** Repair Shop no funcionaba correctamente

### ✨ Improvements

#### Performance
- **Object Pooling:** VFX reusados reducen instancing lag 40%
- **Mobile Optimization:** Auto-reduce efectos en dispositivos móviles
- **Frame Rate:** Mantiene 60 FPS en PC, 30 en mobile
- **Memory:** Mejor cleanup de assets no usados

#### UX/Polish
- **Consistent Styling:** UI unificada estilo grafiti urbano
- **Smooth Animations:** Todas las transiciones son fluidas
- **Visual Feedback:** Siempre sabes qué está pasando
- **Sound Design:** Audio para todas las acciones importantes
- **Error Messages:** Mensajes de error más claros

#### Balance
- **Dash Cooldown:** Reducido de 4s a 2.5s para más acción
- **Invulnerability:** Ajustada a 0.3s (antes era muy corta)
- **Meteor Damage:** Rebalanceado para nueva dificultad
- **Economy:** Ajustes en costos de upgrades

---

## [4.0.0] - 2024 - WAVE SYSTEM & BOSS FIGHTS

### 🎉 Major Features
- **Wave System:** Sistema de oleadas con dificultad progresiva
- **Boss Fights:** Bosses épicos cada X oleadas
- **Mini-Bosses:** Versión reducida entre bosses
- **Wave Counter UI:** Interfaz muestra progreso actual
- **Progressive Difficulty:** Cada wave es más difícil

### 🐛 Bug Fixes
- **Fix:** Wave skip con debug no funcionaba correctamente
- **Fix:** Boss no spawneaba en wave correcta
- **Fix:** Rewards de Boss no se otorgaban

### ✨ Improvements
- **Auto-Save:** DataStore guarda progreso cada 2 minutos
- **Tutorial:** Sistema de tutorial para nuevos jugadores
- **Debug Controls:** M/N keys para testing en Studio

---

## [3.0.0] - 2024 - PROCEDURAL GENERATION

### 🎉 Major Features
- **Procedural Bases:** Cada base es única visualmente
- **Procedural Enemies:** Dinosaurios con variación visual
- **Environment Manager:** Efectos ambientales dinámicos
- **Build Effects:** VFX durante construcción

### ✨ Improvements
- **Performance:** Optimización de modelos procedurales
- **Variety:** Mayor variedad visual en el mundo

---

## [2.0.0] - 2024 - ECONOMY & SHOP

### 🎉 Major Features
- **Shop System:** 10+ upgrades disponibles
- **Economy:** Sistema económico completo
- **Upgrades:** Damage, Speed, Income, HP, Regen, Shield, etc.
- **DataStore:** Persistencia de datos

### ✨ Improvements
- **Offline Earnings:** Gana coins mientras estás offline (hasta 2h)
- **Auto-Save:** Guarda progreso automáticamente
- **Balance:** Sistema económico balanceado

---

## [1.0.0] - 2024 - INITIAL RELEASE

### 🎉 Initial Features
- **Base System:** Bases con HP y regeneración
- **Meteor System:** Meteoritos caen del cielo
- **Damage System:** Sistema de daño a bases
- **Basic Economy:** Generación pasiva de coins
- **Basic UI:** HUD con información básica

---

## 📊 VERSION HISTORY

| Versión | Fecha | Features Principales |
|---------|-------|---------------------|
| **5.0.0** | 2024 | Dash System, Visual Overhaul, UI Redesign |
| **4.0.0** | 2024 | Wave System, Boss Fights |
| **3.0.0** | 2024 | Procedural Generation |
| **2.0.0** | 2024 | Economy & Shop |
| **1.0.0** | 2024 | Initial Release |

---

## 🚀 ROADMAP

### 🔄 Version 5.1.0 (En Desarrollo)
- **Power-Ups System:** Power-ups temporales que dropean de enemigos
- **Pet Gacha System:** Huevos con pets que te siguen y dan bonuses

### 💡 Version 6.0.0 (Planeado)
- **Achievements System:** Logros con recompensas
- **Daily Quests:** Misiones diarias con rewards
- **Leaderboards:** Rankings globales

### 💡 Version 7.0.0 (Futuro)
- **Weather System:** Clima dinámico (tormentas, niebla)
- **Day/Night Cycle:** Ciclo día/noche con efectos visuales
- **PvP Mode:** Competición entre bases de jugadores

---

## 📈 STATS

### Development Progress
- **Total Commits:** 100+
- **Pull Requests Merged:** 16+
- **Lines of Code:** 10,000+
- **Features Implemented:** 50+
- **Bug Fixes:** 30+

### Current Version Stats
- **Game Version:** 5.0.0
- **DataStore Version:** 5
- **Total Scripts:** 30+
- **UI Elements:** 8
- **VFX Types:** 10+

---

## 🎯 MIGRATION GUIDES

### Migrating to 5.0.0 from 4.x

#### Breaking Changes
- **EventManager:** Ahora usa EventManager_REFACTORED.lua (reemplazar archivo)
- **Shop_client:** Ahora usa Shop_client_REFACTORED.lua con animaciones
- **Remotes:** Nuevos RemoteEvents requeridos (DashRequest, DashEvaded)

#### New Requirements
- **Carpetas:** ServerStorage/Managers/ (crear si no existe)
- **VFXManager:** Copiar a ServerStorage/Managers/VFXManager.lua
- **Controllers:** StarterPlayerScripts/Controllers/ (crear carpeta)

#### Steps
1. Backup de archivos antiguos (renombrar _OLD)
2. Copiar nuevos módulos a ubicaciones correctas
3. Crear RemoteEvents faltantes en ReplicatedStorage/Remotes/
4. Test en Studio antes de publicar

---

## 🐛 KNOWN ISSUES

### Version 5.0.0
- Ningún issue crítico conocido ✅

### Fixed in 5.0.0
- ✅ Doble barra en Wave Counter
- ✅ Boss no spawneaba al skip waves
- ✅ Teleport bugs en Dash System
- ✅ Shop UI layering problems
- ✅ Múltiples muertes de base

---

## 📞 FEEDBACK

¿Encontraste un bug? ¿Tienes una sugerencia?
1. Abre un **Issue** en GitHub
2. Incluye versión del juego (visible en Config.lua)
3. Pasos para reproducir el problema
4. Screenshots/Videos si es posible

---

**Desarrollado con 💥 para crear la mejor experiencia de tycoon apocalíptico**

*"Cada update nos acerca más al juego perfecto"*
