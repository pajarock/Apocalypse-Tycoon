# 🎯 Knit Framework - Estructura Completa

## ✅ FASE 1 COMPLETADA

Knit está **instalado, configurado y funcionando** en tu proyecto.

---

## 📁 Estructura de Carpetas

```
src/
├── ReplicatedStorage/
│   ├── Knit/                          ← Framework Knit (ModuleScript con hijos)
│   │   ├── init.luau                  ← Entry point principal
│   │   ├── KnitServer.luau            ← Lógica del servidor
│   │   └── KnitClient.luau            ← Lógica del cliente
│   └── Shared/                        ← Módulos compartidos servidor/cliente
│
├── ServerScriptService/
│   ├── KnitServer.luau                ← Bootstrap servidor (carga Services)
│   ├── Services/                      ← Services de Knit (NUEVOS)
│   │   └── HelloService.luau          ← Ejemplo: servicio de prueba
│   ├── Main.Server.lua                ← Tu código actual (sigue funcionando)
│   └── [otros scripts actuales...]
│
└── StarterPlayer/StarterPlayerScripts/
    ├── KnitClient.luau                ← Bootstrap cliente (carga KnitControllers)
    ├── KnitControllers/               ← Controllers de Knit (NUEVOS) ⭐
    │   └── DebugController.luau       ← Ejemplo: controller de prueba
    ├── Controllers/                   ← Controllers antiguos (NO Knit)
    │   ├── UIController.lua           ← Siguen funcionando normalmente
    │   ├── CameraController.lua
    │   └── PowerUpController.lua
    └── [otros scripts actuales...]
```

---

## 🔑 Convenciones Importantes

### **Services (Servidor)**

- **Ubicación:** `ServerScriptService/Services/`
- **Naming:** `*Service.luau` (ej: `EconomyService.luau`, `BaseService.luau`)
- **Se cargan automáticamente** por `KnitServer.luau`
- **Accesibles desde cliente** via métodos Client

**Ejemplo:**
```lua
local Knit = require(ReplicatedStorage.Knit)

local MyService = Knit.CreateService({
    Name = "MyService",
    Client = {
        -- Métodos expuestos al cliente
        DoSomething = function(self, player)
            return "Hello!"
        end
    },
})

function MyService:KnitStart()
    print("Service started!")
end

return MyService
```

---

### **Controllers (Cliente)**

- **Ubicación:** `StarterPlayer/StarterPlayerScripts/KnitControllers/` ⭐
- **Naming:** `*Controller.luau` (ej: `ShopController.luau`, `UIController.luau`)
- **Se cargan automáticamente** por `KnitClient.luau`
- **Pueden comunicarse con Services** del servidor

**Ejemplo:**
```lua
local Knit = require(ReplicatedStorage.Knit)

local MyController = Knit.CreateController({
    Name = "MyController",
})

function MyController:KnitStart()
    -- Comunicarse con el servidor
    local MyService = Knit.GetService("MyService")
    local response = MyService:DoSomething()
    print(response)
end

return MyController
```

---

### **Controllers Antiguos (No Knit)**

- **Ubicación:** `StarterPlayer/StarterPlayerScripts/Controllers/`
- **NO son de Knit** - siguen siendo scripts `.client.lua` normales
- **Siguen funcionando como siempre** - sin cambios necesarios
- **Ejemplos:** UIController, CameraController, PowerUpController, etc.

**NO necesitas modificarlos** - conviven pacíficamente con Knit.

---

## 🚀 Cómo Usar Knit

### **1. Crear un Nuevo Service (Servidor)**

1. Crea archivo `ServerScriptService/Services/MiService.luau`
2. Copia el template de arriba
3. Implementa tu lógica
4. **NO necesitas registrarlo manualmente** - se carga automáticamente

### **2. Crear un Nuevo Controller (Cliente)**

1. Crea archivo `StarterPlayerScripts/KnitControllers/MiController.luau` ⭐
2. Copia el template de arriba
3. Implementa tu lógica
4. **NO necesitas registrarlo manualmente** - se carga automáticamente

### **3. Comunicación Cliente ↔ Servidor**

**Servidor → Cliente (Remote):**
```lua
-- En Service
function MyService.Client:Ping(player)
    return "Pong!"
end

-- En Controller
local MyService = Knit.GetService("MyService")
local response = MyService:Ping()  -- Automáticamente usa RemoteFunction
```

**NO necesitas crear RemoteEvents/RemoteFunctions manualmente** - Knit lo hace por ti.

---

## 📊 Estado Actual

### ✅ Funcionando
- ✅ Knit instalado (versión simplificada sin dependencias)
- ✅ KnitServer bootstrap funcionando
- ✅ KnitClient bootstrap funcionando
- ✅ HelloService (ejemplo) funcionando
- ✅ DebugController (ejemplo) funcionando
- ✅ Comunicación cliente-servidor verificada
- ✅ Código antiguo sigue funcionando sin cambios

### 📦 Archivos de Ejemplo
- `Services/HelloService.luau` - Template para crear Services
- `KnitControllers/DebugController.luau` - Template para crear Controllers

**Puedes eliminarlos cuando crees tus propios Services/Controllers reales.**

---

## 🎯 Próximos Pasos

### **FASE 2: Implementar Sistema de Bases (Recomendado)**

Ya que quieres implementar bases antes de migrar módulos existentes:

1. **Crear BaseSpawnerService.luau** - Spawnea bases para jugadores
2. **Crear BaseOwnershipService.luau** - Maneja ownership de bases
3. **Crear BasePlacementController.luau** - UI para colocar upgrades

### **FASE 3: Migrar Módulos Existentes (Después)**

Cuando estés listo:

1. `EconomyModule.lua` → `EconomyService.luau`
2. `BaseModule.lua` → `BaseHealthService.luau`
3. `PowerUpModule.lua` → `PowerUpService.luau`
4. `EventManager.lua` → `MeteorService.luau`

---

## ⚠️ Notas Importantes

1. **NO toques los controllers en `Controllers/`** - son código antiguo que sigue funcionando
2. **SOLO agrega controllers nuevos en `KnitControllers/`** ⭐
3. **Knit simplificado** - Versión sin dependencias externas para FASE 1
4. **Migraremos a Knit oficial** con Wally en fases futuras si es necesario

---

## 🐛 Debugging

**Ver qué Services se cargaron:**
```
Output (Servidor): ✅ [KnitServer] Started successfully
```

**Ver qué Controllers se cargaron:**
```
Output (Cliente): 🔵 [KnitClient] Loaded controller: DebugController
Output (Cliente): ✅ [KnitClient] Started successfully
```

---

## 📚 Recursos

- Documentación oficial de Knit: https://sleitnick.github.io/Knit/
- Ejemplos en este repo: `Services/HelloService.luau`, `KnitControllers/DebugController.luau`

---

**Última actualización:** FASE 1 completada - Infraestructura lista para producción
