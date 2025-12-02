# 🎯 SESIÓN: Integración Machine Gun + Meteoritos + Base Knit

## ⚠️ CONTEXTO DEL PROYECTO

### Estructura del Proyecto (Knit Framework)
```
Apocalypse-Tycoon/
├── src/
│   ├── ServerScriptService/
│   │   └── Services/           # 🔧 SERVICIOS KNIT (lógica del servidor)
│   │       ├── TurretService.luau
│   │       ├── TurretDefinitions.luau
│   │       └── UpgradeService.luau
│   ├── ServerStorage/
│   │   └── Managers/           # 📦 MANAGERS (sistemas auxiliares)
│   │       ├── TurretVFXManager.lua
│   │       ├── MeteorDamageSystem.lua  # ⚠️ LEGACY
│   │       └── EventManager.lua        # ⚠️ LEGACY
│   ├── ReplicatedStorage/
│   │   └── Knit/              # Framework
│   └── StarterPlayer/
│       └── StarterPlayerScripts/
│           └── Controllers/    # 🎮 CONTROLADORES KNIT (cliente)
```

### Convenciones de Código
- **Encoding**: UTF-8
- **Framework**: Knit (Services en servidor, Controllers en cliente)
- **Managers**: Sistemas auxiliares que NO son servicios Knit completos
- **Services**: Lógica principal del juego (usar Knit:CreateService)
- **Luau/Lua**: `.luau` para servicios Knit, `.lua` para managers legacy

### Cómo funciona el proyecto actualmente
1. **Base del jugador**: Se crea con `/testbase` (comando slash)
2. **Torretas**: Sistema Knit completo (TurretService + VFX funcionando)
3. **Meteoritos**: Sistema LEGACY (EventManager + MeteorDamageSystem)
4. **Problema**: Meteoritos caen en base legacy, NO en base Knit

---

## 🎯 OBJETIVO DE ESTA SESIÓN

**Hacer que Machine Gun funcione completamente:**
1. ✅ Visuales de upgrade (YA FUNCIONA - PR anterior)
2. ❌ Disparar a meteoritos (FALTA)
3. ❌ Meteoritos caigan en base Knit (FALTA)
4. ❌ Sistema de targeting (FALTA)
5. ❌ Damage/DPS funcional (FALTA)

---

## 📋 PLAN DE TRABAJO (PASO A PASO)

### FASE 1: INVESTIGACIÓN (30 min estimado)
**Objetivo**: Entender el código legacy antes de tocarlo

#### Paso 1.1: Leer sistema de meteoritos legacy
```bash
# Leer estos archivos COMPLETOS:
Read: src/ServerStorage/Managers/MeteorDamageSystem.lua
Read: src/ServerStorage/Managers/EventManager.lua
```

**Buscar y documentar:**
- ¿Cómo se spawnean los meteoritos? (función principal)
- ¿Dónde caen? (coordenadas, región, base específica)
- ¿Qué stats tienen? (HP, damage, speed, size)
- ¿Tipos de meteoritos? (small, medium, large, colosal, miniboss, boss)
- ¿Cómo se detecta el daño a la base?

#### Paso 1.2: Buscar sistema de base Knit
```bash
# Buscar el comando /testbase:
Grep: "testbase" (buscar en todo el proyecto)
Grep: "CreateBase" o "SpawnBase"
```

**Buscar y documentar:**
- ¿Dónde se define la base del jugador en Knit?
- ¿Cómo se identifica? (folder, attribute, región)
- ¿Tiene bounds/área definida?
- ¿Hay un BaseService o similar?

#### Paso 1.3: Entender estructura de Machine Gun
```bash
# Leer configuración actual:
Read: src/ServerScriptService/Services/TurretDefinitions.luau
# (buscar MachineGun T1-T5, ver stats: Damage, FireRate, Range, DPS)
```

**DOCUMENTAR EN CHAT** (para referencia):
```
FINDINGS:
- Meteoritos se spawnean en: [UBICACIÓN]
- Stats de meteoritos: [HP/DAMAGE/SPEED]
- Base Knit está en: [SERVICIO/UBICACIÓN]
- Base se identifica por: [MÉTODO]
```

---

### FASE 2: PLANIFICACIÓN (15 min estimado)
**Objetivo**: Decidir arquitectura ANTES de codificar

#### Decisiones clave:
1. **¿Crear MeteorService en Knit?**
   - Sí → Migrar lógica de EventManager legacy a Knit
   - No → Adaptar legacy para usar base Knit

2. **¿Crear TargetingManager?**
   - Sistema centralizado para que todas las torretas detecten enemigos
   - Debe soportar: meteoritos, futuros zombies, futuros jefes

3. **¿Cómo identificar "enemigos"?**
   - Tag "Enemy" usando CollectionService?
   - Folder "ActiveEnemies" en workspace?
   - Attribute en meteoritos?

**PREGUNTAR AL USUARIO** antes de continuar:
```
"He investigado el código. Propongo esta arquitectura:
[EXPLICAR PLAN]
¿Te parece bien o prefieres otro enfoque?"
```

---

### FASE 3: IMPLEMENTACIÓN (paso a paso)

#### ✅ Paso 3.1: Crear sistema de targeting
**Archivo**: `src/ServerStorage/Managers/TargetingManager.lua`

**Funcionalidad**:
```lua
local TargetingManager = {}

-- Encuentra el enemigo más cercano dentro del rango
function TargetingManager:FindNearestEnemy(position: Vector3, range: number): Model?
    -- Buscar en workspace.ActiveEnemies o usando CollectionService
    -- Filtrar por distancia
    -- Retornar el más cercano
end

-- Verifica si un enemigo está vivo
function TargetingManager:IsValidTarget(enemy: Model): boolean
    -- Verificar que tenga Humanoid o Health
    -- Verificar que Health > 0
    -- Verificar que exista en workspace
end

return TargetingManager
```

**Testing**:
- Crear meteorito dummy en workspace
- Llamar FindNearestEnemy desde TurretService
- Verificar que detecte el meteorito

---

#### ✅ Paso 3.2: Machine Gun disparo básico
**Archivo**: `src/ServerScriptService/Services/TurretService.luau`

**Agregar función**:
```lua
local TargetingManager = require(ServerStorage.Managers.TargetingManager)

function TurretService:StartTurretFiring(model: Model, turretData: any)
    local tierConfig = TurretDefinitions:GetTierConfig(turretData.Type, turretData.Tier)

    -- Loop de disparo
    task.spawn(function()
        while model.Parent do
            local target = TargetingManager:FindNearestEnemy(
                model:GetPivot().Position,
                tierConfig.Range
            )

            if target and TargetingManager:IsValidTarget(target) then
                -- Disparar
                self:FireBullet(model, target, tierConfig.Damage)
            end

            task.wait(tierConfig.FireRate)
        end
    end)
end

function TurretService:FireBullet(turret: Model, target: Model, damage: number)
    -- Crear efecto visual de bala (rayo láser, tracer)
    -- Aplicar daño al target
    -- Efectos de sonido
end
```

**Testing**:
- Colocar Machine Gun T1
- Spawnar meteorito cerca
- Verificar que dispare y haga daño

---

#### ✅ Paso 3.3: Migrar meteoritos a base Knit
**Opción A** (si base Knit tiene región definida):
```lua
-- En MeteorDamageSystem o nuevo MeteorService
local function GetPlayerBaseRegion(player: Player): Region3?
    -- Obtener base del jugador desde BaseService
    -- Retornar Region3 o bounds
end

local function SpawnMeteor(player: Player)
    local baseRegion = GetPlayerBaseRegion(player)
    if not baseRegion then return end

    -- Spawnar meteorito en posición aleatoria dentro de baseRegion
    local randomPos = GetRandomPositionInRegion(baseRegion)
    -- Crear meteorito físico
end
```

**Opción B** (si no hay región definida):
```lua
-- Buscar folder de base del jugador
local playerBase = workspace:FindFirstChild(player.Name .. "_Base")
if playerBase then
    -- Spawnar cerca del centro de la base
end
```

---

#### ✅ Paso 3.4: Stats de meteoritos
**Archivo**: `src/ServerScriptService/Services/MeteorDefinitions.luau` (NUEVO)

```lua
local MeteorDefinitions = {}

MeteorDefinitions.Types = {
    Small = {
        HP = 50,
        Damage = 10,
        Speed = 20,
        Size = Vector3.new(3, 3, 3),
        Color = Color3.fromRGB(100, 50, 0),
    },
    Medium = {
        HP = 150,
        Damage = 25,
        Speed = 15,
        Size = Vector3.new(5, 5, 5),
        Color = Color3.fromRGB(150, 70, 0),
    },
    Large = {
        HP = 400,
        Damage = 50,
        Speed = 10,
        Size = Vector3.new(8, 8, 8),
        Color = Color3.fromRGB(200, 90, 0),
    },
    Colosal = {
        HP = 1000,
        Damage = 100,
        Speed = 5,
        Size = Vector3.new(12, 12, 12),
        Color = Color3.fromRGB(255, 100, 0),
    },
}

return MeteorDefinitions
```

---

### FASE 4: TESTING COMPLETO

#### Test Checklist:
```
□ Machine Gun T1 detecta meteorito Small a 50 studs
□ Machine Gun dispara cada 0.25s (FireRate correcto)
□ Meteorito pierde HP cuando recibe disparo
□ Meteorito muere cuando HP = 0
□ Machine Gun T2 dispara más rápido (0.20s)
□ Machine Gun T5 mata meteorito rápido (DPS 450)
□ Meteoritos caen en base Knit (NO legacy)
□ Múltiples meteoritos se targetean correctamente
□ Machine Gun prioriza meteorito más cercano
```

---

## 🚫 QUÉ NO HACER

1. ❌ NO implementar otras torretas (Laser, Missile, Tesla) todavía
2. ❌ NO crear efectos visuales elaborados para disparos (solo básico)
3. ❌ NO implementar bosses/minibosses todavía (solo meteoritos básicos)
4. ❌ NO crear UI de stats de torretas
5. ❌ NO optimizar rendimiento todavía (primero que funcione)
6. ❌ NO tocar el sistema de visuales de upgrade (ya funciona perfecto)

---

## 📝 DEBUGGING TIPS

### Prints útiles:
```lua
print("[TurretService] 🎯 Target found:", target.Name, "Distance:", distance)
print("[TurretService] 💥 Firing at:", target.Name, "Damage:", damage)
print("[TargetingManager] 🔍 Enemies in range:", #enemiesInRange)
print("[MeteorSystem] ☄️ Spawned meteor at:", position)
```

### Comandos de testing:
```bash
# Ver enemigos activos
/testmeteor  # (crear este comando si no existe)

# Ver torretas activas
/listtowers
```

---

## 📦 ARCHIVOS QUE VAS A TOCAR

### Nuevos (crear):
- `src/ServerStorage/Managers/TargetingManager.lua`
- `src/ServerScriptService/Services/MeteorDefinitions.luau`
- `src/ServerScriptService/Services/MeteorService.luau` (OPCIONAL)

### Modificar:
- `src/ServerScriptService/Services/TurretService.luau`
  - Agregar `StartTurretFiring()`
  - Agregar `FireBullet()`
- `src/ServerStorage/Managers/MeteorDamageSystem.lua`
  - Cambiar spawn location a base Knit
- `src/ServerStorage/Managers/EventManager.lua` (OPCIONAL)
  - Integrar con Knit si es necesario

### Solo leer (NO modificar):
- `src/ServerScriptService/Services/TurretDefinitions.luau`
- `src/ServerStorage/Managers/TurretVFXManager.lua`

---

## 🔄 GIT WORKFLOW

### Branch:
```bash
# Crear nueva branch desde main
git checkout main
git pull origin main
git checkout -b claude/machine-gun-firing-[SESSION_ID]
```

### Commits:
```bash
# Después de cada fase funcional:
git add .
git commit -m "feat: Add targeting system for turrets"
git commit -m "feat: Implement Machine Gun firing mechanism"
git commit -m "feat: Integrate meteors with Knit base system"
```

### Push:
```bash
# Al final de la sesión
git push -u origin claude/machine-gun-firing-[SESSION_ID]
```

---

## ❓ PREGUNTAS PARA EL USUARIO (si surgen dudas)

1. "¿Los meteoritos deben hacer daño a la base del jugador o solo necesitan ser destruidos?"
2. "¿Prefieres que cree MeteorService en Knit o adapte el legacy?"
3. "¿Hay algún sistema de waves/oleadas o los meteoritos caen random?"
4. "¿La Machine Gun debe tener efecto visual de disparo (balas trazadoras) o solo damage?"

---

## 🎯 CRITERIO DE ÉXITO

**La sesión es exitosa cuando**:
1. ✅ Machine Gun T1-T5 detecta meteoritos en su rango
2. ✅ Dispara automáticamente con FireRate correcto
3. ✅ Hace daño según Tier (T1: 8 dmg, T5: 45 dmg)
4. ✅ Meteoritos spawned caen en base Knit
5. ✅ Meteoritos mueren cuando HP = 0
6. ✅ DPS es aproximadamente correcto (T1: 32, T5: 450)

**Todo lo demás es SECUNDARIO** para esta sesión.

---

## 🔧 HERRAMIENTAS DISPONIBLES

- `Read`: Leer archivos
- `Glob`: Buscar archivos por patrón (*.lua, *.luau)
- `Grep`: Buscar texto en archivos
- `Edit`: Modificar archivos existentes
- `Write`: Crear archivos nuevos
- `Bash`: Git commands
- `Task`: Lanzar agentes especializados (Explore para investigar codebase)

---

## 📊 ORDEN DE PRIORIDAD

1. **CRÍTICO**: Sistema de targeting funcional
2. **CRÍTICO**: Machine Gun dispara y hace daño
3. **IMPORTANTE**: Meteoritos caen en base Knit
4. **IMPORTANTE**: Stats correctos (damage, fire rate, range)
5. **DESEABLE**: Efectos visuales de disparo
6. **OPCIONAL**: Optimización, refactoring

---

## 💡 NOTAS FINALES

- **Itera rápido**: Haz que funcione básico primero, luego mejora
- **Pregunta antes de codificar**: Si algo no está claro, pregunta al usuario
- **Commits frecuentes**: No esperes a tener todo perfecto
- **Debug con prints**: Agrega logs para ver qué está pasando
- **Testing manual**: Prueba cada feature en Roblox Studio

**Recuerda**: El objetivo NO es hacer el sistema perfecto, es hacer que Machine Gun FUNCIONE. Perfección viene después.

---

## 🚀 MENSAJE INICIAL PARA LA NUEVA SESIÓN

```
Hola! Voy a trabajar en la integración de Machine Gun + Meteoritos + Base Knit.

Tengo el script completo en NEXT_SESSION_METEOR_INTEGRATION.md

Voy a empezar con FASE 1: INVESTIGACIÓN, leyendo:
1. MeteorDamageSystem.lua
2. EventManager.lua
3. Sistema de base Knit

Te reporto mis findings antes de codificar nada.
```
