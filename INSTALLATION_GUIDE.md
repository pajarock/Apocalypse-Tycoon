# 📥 GUÍA DE INSTALACIÓN RÁPIDA

## ⏱️ Tiempo total: 10 minutos

---

## PASO 1: ESTRUCTURA DE CARPETAS (2 min)

En Roblox Studio, crea estas carpetas si no existen:

```
ServerStorage/
├── Managers/       ← CREAR SI NO EXISTE
└── Config/         ← YA DEBERÍA EXISTIR

StarterPlayer/
└── StarterPlayerScripts/
    └── Controllers/    ← CREAR SI NO EXISTE
```

---

## PASO 2: COPIAR MÓDULOS SERVER-SIDE (3 min)

### 2.1 VFXManager

1. En `ServerStorage`, crear carpeta `Managers`
2. Dentro de `Managers`, crear **ModuleScript** llamado `VFXManager`
3. Copiar contenido de `VFXManager.lua` en ese ModuleScript

**Ruta final:** `ServerStorage.Managers.VFXManager`

### 2.2 VFXConfig

1. En `ServerStorage.Config`, crear **ModuleScript** llamado `VFXConfig`
2. Copiar contenido de `VFXConfig.lua` en ese ModuleScript

**Ruta final:** `ServerStorage.Config.VFXConfig`

### 2.3 EventManager Refactored

1. En `ServerStorage`, encontrar tu `EventManager` actual
2. **RENOMBRAR** a `EventManager_OLD` (backup)
3. Crear nuevo **ModuleScript** llamado `EventManager`
4. Copiar contenido de `EventManager_REFACTORED.lua` en ese ModuleScript

**Ruta final:** `ServerStorage.EventManager`

---

## PASO 3: COPIAR MÓDULOS CLIENT-SIDE (3 min)

### 3.1 CameraController

1. En `StarterPlayer.StarterPlayerScripts`, crear carpeta `Controllers`
2. Dentro de `Controllers`, crear **ModuleScript** llamado `CameraController`
3. Copiar contenido de `CameraController.lua` en ese ModuleScript

**Ruta final:** `StarterPlayer.StarterPlayerScripts.Controllers.CameraController`

### 3.2 UIController

1. En `Controllers`, crear **ModuleScript** llamado `UIController`
2. Copiar contenido de `UIController.lua` en ese ModuleScript

**Ruta final:** `StarterPlayer.StarterPlayerScripts.Controllers.UIController`

### 3.3 CameraShake Client Bridge

1. En `StarterPlayer.StarterPlayerScripts`, crear **LocalScript** llamado `CameraShake_Client`
2. Copiar contenido de `CameraShake_Client.lua` en ese LocalScript

**Ruta final:** `StarterPlayer.StarterPlayerScripts.CameraShake_Client`

### 3.4 Shop Client Refactored

1. En tu `StarterGui`, encontrar la carpeta de Shop (probablemente `ShopUI` o similar)
2. Encontrar el script cliente actual (probablemente `Shop_client`)
3. **RENOMBRAR** a `Shop_client_OLD` (backup)
4. Crear nuevo **LocalScript** llamado `Shop_client`
5. Copiar contenido de `Shop_client_REFACTORED.lua` en ese LocalScript

**Ruta final:** `StarterGui.ShopUI.Shop_client` (o donde estaba antes)

---

## PASO 4: CREAR REMOTEEVENT (1 min)

1. Ir a `ReplicatedStorage.Remotes`
2. Crear **RemoteEvent** llamado `CameraShake`

**Ruta final:** `ReplicatedStorage.Remotes.CameraShake`

> **Nota:** Si no lo creas, `EventManager_REFACTORED` lo creará automáticamente, pero es mejor hacerlo manualmente.

---

## PASO 5: VERIFICAR (1 min)

### Checklist de archivos:

```
✅ ServerStorage.Managers.VFXManager (ModuleScript)
✅ ServerStorage.Config.VFXConfig (ModuleScript)
✅ ServerStorage.EventManager (ModuleScript) - refactored
✅ ServerStorage.EventManager_OLD (ModuleScript) - backup

✅ StarterPlayerScripts.Controllers.CameraController (ModuleScript)
✅ StarterPlayerScripts.Controllers.UIController (ModuleScript)
✅ StarterPlayerScripts.CameraShake_Client (LocalScript)
✅ StarterGui.ShopUI.Shop_client (LocalScript) - refactored
✅ StarterGui.ShopUI.Shop_client_OLD (LocalScript) - backup

✅ ReplicatedStorage.Remotes.CameraShake (RemoteEvent)
```

---

## PASO 6: TESTING

1. Presiona **Play** en Roblox Studio

2. Verifica la consola:
   ```
   ✓ [VFXManager] Módulo cargado con object pooling
   ✓ [CameraController] Módulo cargado
   ✓ [UIController] Módulo cargado
   ✓ [EVENTMANAGER REFACTORED] Módulo cargado con VFX épicos
   ✓ [QuickBuy REFACTORED] UI inicializada con animaciones
   ```

3. **Tests en-game:**
   - Presiona **M** → Debería spawnear meteorito con trail épico + explosión
   - Presiona **B** → Shop debería deslizarse suavemente
   - Hover sobre botones de shop → Deberían crecer y brillar
   - Compra un upgrade → Debería hacer bounce con partículas verdes

---

## 🐛 TROUBLESHOOTING RÁPIDO

### ❌ Error: "VFXManager not found"

**Solución:** Revisa que esté en `ServerStorage.Managers.VFXManager` (no en otra carpeta)

### ❌ Meteoritos sin explosión

**Solución:**
1. Deshabilita `EventManager_OLD` (Enabled = false)
2. Verifica que `main_server.lua` requiera el nuevo `EventManager`

### ❌ Shop no anima

**Solución:** Revisa que `UIController` esté en `StarterPlayerScripts.Controllers.UIController`

### ❌ Camera shake no funciona

**Solución:** Crea manualmente `ReplicatedStorage.Remotes.CameraShake` (RemoteEvent)

---

## ✅ ¡LISTO!

**Tu tycoon ahora tiene efectos visuales AAA.**

Presiona **M** en-game y disfruta del espectáculo 🎆

---

**Siguiente paso:** Lee `README.md` para ejemplos de uso avanzado.
