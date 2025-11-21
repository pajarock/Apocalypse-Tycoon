# GENERATOR PHASE 4 - UPGRADE SYSTEM TESTING

Guía completa de testing para el sistema de upgrades de generadores.

---

## TEST 1: Diagnóstico Completo del Sistema

Ejecuta este script en la consola de Studio:

```lua
-- ══════════════════════════════════════════════════════════════
-- PHASE 4 DIAGNOSTIC SCRIPT
-- ══════════════════════════════════════════════════════════════

local Knit = require(game.ReplicatedStorage.Knit)
local UpgradeService = Knit.GetService("UpgradeService")
local BaseOwnershipService = Knit.GetService("BaseOwnershipService")
local UpgradeDefinitions = require(game.ServerScriptService.Services.UpgradeDefinitions)
local player = game.Players:GetPlayers()[1]

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔍 PHASE 4 UPGRADE SYSTEM DIAGNOSTIC")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Paso 1: Colocar un generator T1
print("\n[1/6] Colocando Generator T1...")
local model = UpgradeDefinitions.CreateModel("Generator")
if model then
    model:MoveTo(Vector3.new(100, 5, 0))
    model.Parent = workspace

    local objectId = "test_upgrade_" .. tostring(os.time())
    UpgradeService:RegisterUpgrade(objectId, player.UserId, "Generator", model)
    print("✅ Generator T1 colocado: " .. objectId)

    -- Paso 2: Dar dinero al jugador
    print("\n[2/6] Dando dinero al jugador...")
    local PlayerDataService = Knit.GetService("PlayerDataService")
    PlayerDataService:AddMoney(player.UserId, 5000)
    print("✅ $5000 agregados al jugador")

    -- Paso 3: Verificar que el generator existe en workspace
    print("\n[3/6] Verificando modelo en workspace...")
    local mainPart = model:FindFirstChild("MainPart")
    if mainPart then
        print("✅ MainPart encontrado")

        -- Verificar valores
        local tierValue = mainPart:FindFirstChild("Tier")
        local moneyPerSecValue = mainPart:FindFirstChild("MoneyPerSec")

        if tierValue then
            print("  └─ Tier actual: " .. tierValue.Value)
        else
            print("  └─ ❌ Tier value NO ENCONTRADO")
        end

        if moneyPerSecValue then
            print("  └─ MoneyPerSec actual: $" .. moneyPerSecValue.Value)
        else
            print("  └─ ❌ MoneyPerSec value NO ENCONTRADO")
        end

        -- Verificar ProximityPrompts
        local statsPrompt = mainPart:FindFirstChild("StatsPrompt")
        local upgradePrompt = mainPart:FindFirstChild("UpgradePrompt")

        if statsPrompt then
            print("  └─ ✅ StatsPrompt encontrado (E)")
        else
            print("  └─ ❌ StatsPrompt NO ENCONTRADO")
        end

        if upgradePrompt then
            print("  └─ ✅ UpgradePrompt encontrado (U)")
            print("      └─ Enabled: " .. tostring(upgradePrompt.Enabled))
        else
            print("  └─ ❌ UpgradePrompt NO ENCONTRADO")
        end
    else
        print("❌ MainPart NO encontrado")
    end

    -- Paso 4: Verificar upgrade definitions
    print("\n[4/6] Verificando upgrade definitions...")
    local canUpgrade = UpgradeDefinitions.CanUpgrade("Generator")
    local nextTier = UpgradeDefinitions.GetNextTier("Generator")
    local upgradeCost = UpgradeDefinitions.GetUpgradeCost("Generator")

    print("  └─ CanUpgrade: " .. tostring(canUpgrade))
    print("  └─ NextTier: " .. tostring(nextTier))
    print("  └─ UpgradeCost: $" .. tostring(upgradeCost))

    -- Paso 5: Intentar upgrade programáticamente
    print("\n[5/6] Intentando upgrade programático...")
    local success = UpgradeService:UpgradeGenerator(objectId, player.UserId)

    if success then
        print("✅ UPGRADE EXITOSO!")

        -- Verificar cambios
        task.wait(0.5)
        if tierValue then
            print("  └─ Nuevo Tier: " .. tierValue.Value)
        end
        if moneyPerSecValue then
            print("  └─ Nuevo MoneyPerSec: $" .. moneyPerSecValue.Value)
        end
        print("  └─ Nuevo tamaño: " .. tostring(mainPart.Size))
        print("  └─ Nuevo color: " .. tostring(mainPart.Color))
    else
        print("❌ UPGRADE FALLÓ")
    end

    -- Paso 6: Info del generator en UpgradeService
    print("\n[6/6] Verificando estado en UpgradeService...")
    local debugInfo = UpgradeService:GetDebugInfo()

    for i, gen in ipairs(debugInfo.Generators) do
        if gen.ObjectId == objectId then
            print("✅ Generator encontrado en UpgradeService:")
            print("  └─ Tier: " .. gen.Tier)
            print("  └─ Rate: $" .. gen.MoneyPerSecond .. "/s")
            print("  └─ Total Produced: $" .. gen.TotalProduced)
            break
        end
    end

    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📝 OBJECTID PARA TESTING MANUAL: " .. objectId)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    -- Guardar objectId globalmente para testing manual
    _G.TEST_GENERATOR_ID = objectId
    _G.TEST_GENERATOR_MODEL = model

else
    print("❌ Error al crear modelo")
end
```

---

## TEST 2: Testing Manual del UpgradePrompt

Después de ejecutar TEST 1, usa estos comandos:

```lua
-- Verificar que el UpgradePrompt existe y está configurado
local model = _G.TEST_GENERATOR_MODEL
local mainPart = model:FindFirstChild("MainPart")
local upgradePrompt = mainPart:FindFirstChild("UpgradePrompt")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("UPGRADE PROMPT DEBUG")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Exists:", upgradePrompt ~= nil)
print("Enabled:", upgradePrompt.Enabled)
print("ActionText:", upgradePrompt.ActionText)
print("KeyboardKeyCode:", upgradePrompt.KeyboardKeyCode)
print("MaxActivationDistance:", upgradePrompt.MaxActivationDistance)
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
```

---

## TEST 3: Forzar Upgrade Manual

Si el ProximityPrompt no funciona, prueba upgrade directo:

```lua
local Knit = require(game.ReplicatedStorage.Knit)
local UpgradeService = Knit.GetService("UpgradeService")
local player = game.Players:GetPlayers()[1]

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("FORCING UPGRADE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local objectId = _G.TEST_GENERATOR_ID
if objectId then
    local success = UpgradeService:UpgradeGenerator(objectId, player.UserId)
    print("Upgrade result:", success)

    if not success then
        print("\n❌ DEBUGGING FAILURE...")

        -- Verificar dinero
        local PlayerDataService = Knit.GetService("PlayerDataService")
        -- El método para verificar dinero puede variar según tu implementación
        print("Player cash: Check in leaderstats")

        -- Verificar tier actual
        local debugInfo = UpgradeService:GetDebugInfo()
        for i, gen in ipairs(debugInfo.Generators) do
            if gen.ObjectId == objectId then
                print("Current tier:", gen.Tier)
                print("Can upgrade?", gen.Tier < 3)
            end
        end
    end
else
    print("❌ No TEST_GENERATOR_ID found. Run TEST 1 first.")
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
```

---

## TEST 4: Verificar Conexión de Eventos

```lua
local model = _G.TEST_GENERATOR_MODEL
if not model then
    print("❌ Run TEST 1 first")
    return
end

local mainPart = model:FindFirstChild("MainPart")
local upgradePrompt = mainPart:FindFirstChild("UpgradePrompt")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("EVENT CONNECTION TEST")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

if upgradePrompt then
    -- Conectar listener de debug
    upgradePrompt.Triggered:Connect(function(player)
        print("🎯 UPGRADE PROMPT TRIGGERED BY:", player.Name)
        print("   This should call UpgradeService:UpgradeGenerator()")
    end)

    print("✅ Debug listener connected")
    print("📝 Try pressing U near the generator")
else
    print("❌ UpgradePrompt not found")
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
```

---

## TEST 5: Verificar BaseOwnershipService

El problema podría ser que no se encuentra el objectId:

```lua
local Knit = require(game.ReplicatedStorage.Knit)
local BaseOwnershipService = Knit.GetService("BaseOwnershipService")
local model = _G.TEST_GENERATOR_MODEL

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("CHECKING BASEOWNERSHIP")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local allObjects = BaseOwnershipService:GetAllObjects()
local found = false

for objectId, data in pairs(allObjects) do
    if data.Model == model then
        print("✅ Found in BaseOwnership:")
        print("  ObjectId:", objectId)
        print("  Owner:", data.Owner)
        print("  Type:", data.ObjectType)
        found = true
        break
    end
end

if not found then
    print("❌ Generator NOT found in BaseOwnership")
    print("   This is the problem! UpgradePrompt can't find objectId")
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
```

---

## PROBLEMAS COMUNES

### Problema 1: UpgradePrompt.Enabled = false
**Causa:** El prompt solo se habilita cuando StatsPrompt está visible
**Solución:** Presiona E primero para abrir stats, LUEGO presiona U

### Problema 2: objectId no encontrado
**Causa:** GetAllObjects() no devuelve el formato esperado
**Solución:** Necesitamos verificar cómo está implementado BaseOwnershipService

### Problema 3: No tiene dinero suficiente
**Causa:** El jugador no tiene los $400 necesarios
**Solución:** Usa TEST 1 que da $5000 automáticamente

### Problema 4: Ya está en Tier 3
**Causa:** El generator ya fue upgradeado al máximo
**Solución:** Crea un nuevo generator con TEST 1

---

## CHECKLIST DE VERIFICACIÓN

- [ ] Generator T1 colocado en workspace
- [ ] Jugador tiene suficiente dinero ($400+)
- [ ] MainPart tiene Tier value = 1
- [ ] StatsPrompt existe (tecla E)
- [ ] UpgradePrompt existe (tecla U)
- [ ] UpgradePrompt.Enabled = true después de presionar E
- [ ] BaseOwnershipService tiene el objectId registrado
- [ ] UpgradeDefinitions.CanUpgrade("Generator") = true
- [ ] UpgradeService:UpgradeGenerator() retorna true

---

**Ejecuta TEST 1 y comparte TODO el output para diagnosticar el problema.**
