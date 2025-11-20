# 🧪 Testing: Generator Integration

## 📋 Resumen
Este documento explica cómo testear la integración del sistema de economía legacy con los generadores de Knit.

**Branch**: `claude/feature/generator-integration-01C944AuDAUepscDb49YbK1Z`

**Cambios realizados**:
- ✅ Creado `PlayerDataService.luau` como wrapper de `EconomyModule.lua`
- ✅ Integración automática con `UpgradeService`
- ✅ Los generadores ahora deberían producir dinero

---

## 🎯 Objetivo del Test

Verificar que:
1. `PlayerDataService` se carga correctamente
2. `UpgradeService` detecta el servicio (sin warning)
3. Los **generadores producen dinero cada segundo** ($5/seg por default)
4. El dinero se refleja en el sistema de economía legacy

---

## 🚀 Instrucciones de Testing

### PASO 1: Abrir Roblox Studio

1. Abre el proyecto `Apocalypse-Tycoon` en Roblox Studio
2. Asegúrate de estar en la branch correcta:
   ```
   claude/feature/generator-integration-01C944AuDAUepscDb49YbK1Z
   ```

### PASO 2: Verificar que los servicios se carguen

**En el Output window de Roblox Studio**, al iniciar el juego deberías ver:

```
[PlayerDataService] ⚙️ Initialized (EconomyModule wrapper)
[PlayerDataService] ✅ Started - Ready to process money operations
[PlayerDataService] 🔗 Connected to EconomyModule (legacy)
[PlayerDataService] 📊 EconomyModule stats: Purchases=0, Ticks=0
```

```
[UpgradeService] ⚙️ Initialized
[UpgradeService] ✅ Started - Update loops running
[UpgradeService] Generators: 0 | Turrets: 0 | Repair Stations: 0
```

**❌ SI VES ESTE WARNING, ALGO ESTÁ MAL**:
```
[UpgradeService] PlayerDataService no encontrado - generators no darán dinero
```

### PASO 3: Spawnear una base

1. Inicia el juego en Roblox Studio (F5)
2. Espera a que tu jugador aparezca
3. El sistema debería spawnear automáticamente tu base
4. Verifica en el Output:
   ```
   [TEST] ✅ Base spawneada exitosamente en posición: ...
   ```

### PASO 4: Comprar y colocar un generador

**Opción A: Usando el sistema UI existente**
1. Abre el menú de construcción
2. Busca "Generator" en la lista de upgrades
3. Cómpralo (si tienes dinero suficiente)
4. Colócalo en tu base

**Opción B: Usando comandos de chat (si existen)**
Si hay comandos de testing para comprar upgrades, úsalos aquí.

**Opción C: Dar dinero manualmente para testing**
En un Script de servidor (o en el Command Bar):
```lua
local EconomyModule = require(game.ServerScriptService.EconomyModule)
local player = game.Players:GetPlayers()[1]
EconomyModule.AdminGiveCash(player.UserId, 10000)
print("💰 Dinero dado:", 10000)
```

### PASO 5: Verificar producción de dinero

Una vez que el generador esté colocado, deberías ver en el Output (cada segundo):

```
[UpgradeService] 💰 Generator registered: [objectId] (Owner: [userId], Rate: $5/s)
```

**Verificar generadores activos (NUEVO MÉTODO DE DEBUG):**

Usa este script en el Command Bar (F9 → Command Bar):
```lua
local Knit = require(game.ReplicatedStorage.Knit)
local UpgradeService = Knit.GetService("UpgradeService")

-- Método 1: Conteo rápido (lightweight)
local counts = UpgradeService:GetActiveUpgradeCounts()
print("🔢 Generators activos:", counts.Generators)
print("🔢 Turrets activas:", counts.Turrets)
print("🔢 Repair Stations activas:", counts.RepairStations)

-- Método 2: Información detallada (full debug)
local debugInfo = UpgradeService:GetDebugInfo()
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📊 UPGRADE DEBUG INFO")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Total Generators:", debugInfo.GeneratorCount)

if debugInfo.GeneratorCount > 0 then
    for i, gen in ipairs(debugInfo.Generators) do
        print(string.format(
            "  Generator #%d: Owner=%d, Rate=$%d/s, LastProduction=%ds ago",
            i, gen.UserId, gen.MoneyPerSecond, gen.SecondsSinceProduction
        ))
    end
end
```

**Monitorear dinero del jugador:**

Usa este script en el Command Bar (F9 → Command Bar):
```lua
local EconomyModule = require(game.ServerScriptService.EconomyModule)
local player = game.Players:GetPlayers()[1]
local state = EconomyModule.GetState(player.UserId)
if state then
    print("💵 Dinero actual:", state.Cash)
    print("📈 Ingreso/seg:", state.IncomePerSec)
else
    print("❌ No se pudo obtener estado del jugador")
end
```

**Ejecutar cada 5 segundos para ver el incremento:**
```lua
task.spawn(function()
    local EconomyModule = require(game.ServerScriptService.EconomyModule)
    local player = game.Players:GetPlayers()[1]

    for i = 1, 10 do
        local state = EconomyModule.GetState(player.UserId)
        if state then
            print(string.format("[TEST %d/10] 💵 Cash: $%.2f | 📈 Income: $%.2f/s",
                i, state.Cash, state.IncomePerSec))
        end
        task.wait(5)
    end
end)
```

---

## ✅ Criterios de Éxito

### Test PASADO ✅ si:

1. **No hay warnings** de `PlayerDataService no encontrado`
2. **Los generadores se registran** correctamente con mensaje en Output
3. **El dinero AUMENTA** cada segundo ($5 por generador)
4. **El dinero se refleja** en `EconomyModule.GetState(userId).Cash`
5. **No hay errores** en el Output

### Test FALLIDO ❌ si:

1. Hay warning de `PlayerDataService no encontrado`
2. Los generadores no se registran
3. El dinero NO aumenta después de 10 segundos
4. Hay errores de tipo `attempt to call nil value` en `AddMoney`
5. Crash del servidor

---

## 🐛 Troubleshooting

### Problema: "PlayerDataService no encontrado"

**Causa**: El servicio no se está cargando correctamente

**Solución**:
1. Verifica que `PlayerDataService.luau` existe en `ServerScriptService/Services/`
2. Verifica que `KnitServer.luau` esté en `ServerScriptService/`
3. Verifica que no haya errores de sintaxis en `PlayerDataService.luau`

### Problema: El dinero no aumenta

**Causa 1**: El generador no está registrado

**Verificar**:
```lua
-- En Command Bar
local Knit = require(game.ReplicatedStorage.Knit)
local UpgradeService = Knit.GetService("UpgradeService")

-- CORRECTO: Usar método público de debugging
local counts = UpgradeService:GetActiveUpgradeCounts()
print("Generators activos:", counts.Generators)

-- Si hay 0 generators, significa que no se registró
if counts.Generators == 0 then
    print("❌ No hay generadores registrados")
    print("👉 Verifica que hayas colocado un generador en tu base")
else
    -- Ver detalles de los generadores
    local debugInfo = UpgradeService:GetDebugInfo()
    for i, gen in ipairs(debugInfo.Generators) do
        print(string.format("Generator #%d: Owner=%d, $%d/s",
            i, gen.UserId, gen.MoneyPerSecond))
    end
end
```

**Causa 2**: El jugador no está inicializado en EconomyModule

**Verificar**:
```lua
-- En Command Bar
local EconomyModule = require(game.ServerScriptService.EconomyModule)
local player = game.Players:GetPlayers()[1]
local state = EconomyModule.GetState(player.UserId)
print("Estado jugador:", state)
```

Si `state == nil`, el jugador no fue inicializado. Esto debería hacerlo `Main.Server.lua` al unirse.

### Problema: Error "attempt to call nil value (method 'AddMoney')"

**Causa**: PlayerDataService no expone el método `AddMoney` correctamente

**Verificar**:
```lua
-- En Command Bar
local PlayerDataService = require(game.ReplicatedStorage.Knit).GetService("PlayerDataService")
print("AddMoney method:", PlayerDataService.AddMoney)
```

Si es `nil`, hay un problema con la definición del método en `PlayerDataService.luau`.

---

## 📊 Resultados Esperados

Después de **10 segundos** con **1 generador** activo:

- **Dinero inicial**: $0 (o el START_CASH configurado)
- **Dinero esperado**: Inicial + ($5/s × 10s) = Inicial + $50
- **IncomePerSec**: $5

Con **3 generadores**:

- **Dinero después de 10s**: Inicial + ($15/s × 10s) = Inicial + $150
- **IncomePerSec**: $15

---

## 🔄 Integración con Sistema Legacy

**Flujo completo**:

1. **Jugador se une** → `Main.Server.lua` inicializa economía
2. **Compra generador** → `EconomyModule.Purchase()` deduce dinero
3. **Coloca generador** → `BaseOwnershipService` crea objeto
4. **UpgradeService detecta generador** → `RegisterGenerator()`
5. **Cada segundo**: `UpgradeService` → `PlayerDataService:AddMoney()` → `EconomyModule.AdminGiveCash()`
6. **UI actualiza** → Muestra nuevo balance

---

## 📝 Notas Importantes

1. **Sistema híbrido**: Este es un wrapper temporal. El sistema legacy sigue siendo la fuente de verdad para el dinero.

2. **Performance**: Los generadores usan un update loop de 1 segundo (no cada frame), optimizado para múltiples generadores.

3. **Compatibilidad**: Este cambio NO rompe funcionalidad existente. Si `PlayerDataService` falla, el juego seguirá funcionando (solo sin generadores).

4. **Testing en producción**: Recomendado hacer soft-launch con pocos jugadores antes de merge a main.

---

## ✅ Checklist de Testing

Antes de hacer merge a main:

- [ ] PlayerDataService se carga sin errores
- [ ] UpgradeService detecta PlayerDataService correctamente
- [ ] Generadores se registran al colocarlos
- [ ] Dinero aumenta $5/segundo por generador
- [ ] Múltiples generadores acumulan correctamente ($15/s con 3 generadores)
- [ ] El sistema no afecta otras funcionalidades (compras, repairs, waves)
- [ ] No hay memory leaks (monitor después de 5 minutos)
- [ ] Funciona con múltiples jugadores simultáneos
- [ ] DataStore guarda y carga correctamente el dinero generado

---

## 🎉 Siguiente Paso

Una vez que este test pase exitosamente:

1. **Commit y push** a la branch actual
2. **Crear Pull Request** para merge a main
3. **Integrar otros upgrades**: Turrets, Storage, RepairStation
4. **Documentar** el sistema completo

---

**Fecha de creación**: 2025-11-20
**Autor**: Claude (Knit Integration Team)
**Branch**: `claude/feature/generator-integration-01C944AuDAUepscDb49YbK1Z`
