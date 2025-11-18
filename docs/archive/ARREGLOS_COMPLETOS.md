# 🔧 ARREGLOS COMPLETOS - Apocalypse Tycoon

## 📋 RESUMEN

Este documento contiene las soluciones a los 5 problemas reportados:

1. ✅ **Camera Shake NO funciona** - Solución lista
2. ✅ **ProceduralModels NO se usan** - Código de integración incluido
3. ✅ **Barra de vida duplicada** - Instrucciones para eliminar
4. ✅ **Wall Sections se sobreponen** - YA ARREGLADO en GitHub
5. ⚠️ **Contador de waves NO sube** - UI necesaria (código incluido)

---

## 🔴 PROBLEMA #1: Camera Shake NO Funciona

### **Causa:**
El archivo `EventManager.lua` que tienes en Studio es la versión ANTIGUA (420 líneas) que **NO tiene soporte para camera shake**.

### **Solución:**

#### **Opción A: Reemplazar EventManager completo** (RECOMENDADO)

1. En Roblox Studio, abre `ServerScriptService.EventManager`
2. Elimina TODO el código actual
3. Ve a GitHub: `ServerStorage/EventManager_REFACTORED.lua`
4. Copia TODO el código de EventManager_REFACTORED.lua
5. Pégalo en `ServerScriptService.EventManager`
6. Guarda y prueba

#### **Opción B: Agregar solo las líneas necesarias** (Si prefieres editar)

Si prefieres mantener tu EventManager actual y solo agregar camera shake, agrega esto:

**Al inicio del archivo (después de los requires):**
```lua
-- RemoteEvents
local RemotesFolder = game.ReplicatedStorage:WaitForChild("Remotes")

-- Camera shake remote
local CameraShake = RemotesFolder:FindFirstChild("CameraShake")
if not CameraShake then
	CameraShake = Instance.new("RemoteEvent")
	CameraShake.Name = "CameraShake"
	CameraShake.Parent = RemotesFolder
	warn("[EventManager] RemoteEvent 'CameraShake' creado automáticamente")
end
```

**En la función de impacto de meteorito (donde aplicas daño a la base):**
```lua
-- Camera shake para el jugador afectado
local ownerPlr = Players:GetPlayerByUserId(userId)
if ownerPlr and CameraShake then
	-- Shake intensity basada en tipo de meteorito
	local shakeIntensity = "Medium"
	if meteorType == "Large" then
		shakeIntensity = "Heavy"
	elseif meteorType == "Small" then
		shakeIntensity = "Light"
	end

	CameraShake:FireClient(ownerPlr, shakeIntensity, 0.5)
end
```

### **Verificación:**
1. Presiona **Play** en Studio
2. Presiona **M** para spawnar meteorito
3. Deberías sentir vibración de cámara cuando impacta

---

## 🟡 PROBLEMA #2: ProceduralModels NO se Usan

### **Causa:**
Tu `main.server.lua` crea **placeholders** (cubos genéricos) en lugar de usar los modelos procedurales que ya existen en `ServerStorage.Managers.ProceduralModels`.

### **Solución:**

Busca en tu `main.server.lua` la sección donde creas los modelos al comprar upgrades. Probablemente se ve así:

**ANTES (código antiguo que crea placeholders):**
```lua
-- Al comprar un upgrade
local model = Instance.new("Part")
model.Name = def.Name
model.Size = Vector3.new(5, 5, 5)
model.Color = Color3.fromRGB(100, 100, 100)
model.Material = Enum.Material.Metal
model.Anchored = true
model.Position = position
model.Parent = workspace.Bases:FindFirstChild(plr.Name .. "_Base")
```

**DESPUÉS (usando ProceduralModels):**
```lua
-- 🔥 NUEVO: Cargar ProceduralModels
local ProceduralModels = require(game.ServerStorage.Managers.ProceduralModels)

-- Al comprar un upgrade
if def.ModelName and ProceduralModels:ModelExists(def.ModelName) then
	-- Crear modelo procedural
	local model = ProceduralModels:CreateModel(def.ModelName)

	if model then
		-- Posicionar el modelo
		model:SetPrimaryPartCFrame(CFrame.new(position))
		model.Parent = workspace.Bases:FindFirstChild(plr.Name .. "_Base")

		print(("[PURCHASE] Modelo procedural creado: %s"):format(def.ModelName))
	else
		warn(("[PURCHASE] No se pudo crear modelo: %s"):format(def.ModelName))
	end
else
	-- Fallback: Crear placeholder si no hay modelo
	local placeholder = Instance.new("Part")
	placeholder.Name = def.Name .. "_Placeholder"
	placeholder.Size = Vector3.new(5, 5, 5)
	placeholder.Color = Color3.fromRGB(150, 150, 150)
	placeholder.Material = Enum.Material.Metal
	placeholder.Anchored = true
	placeholder.Position = position
	placeholder.Parent = workspace.Bases:FindFirstChild(plr.Name .. "_Base")

	warn(("[PURCHASE] Usando placeholder para: %s"):format(def.Name))
end
```

### **Modelos Disponibles:**

Verifica que tus upgrades en `Upgrades.lua` tengan el campo `ModelName`:

```lua
-- Income
{ID = 1, Name = "Solar Panel", ..., ModelName = "SolarPanel"}
{ID = 2, Name = "Wind Turbine", ..., ModelName = "WindTurbine"}
{ID = 3, Name = "Miner Drill", ..., ModelName = "MinerDrill"}
{ID = 4, Name = "Nuclear Reactor", ..., ModelName = "NuclearReactor"}

-- Defense
{ID = 5, Name = "Shield Generator", ..., ModelName = "ShieldGenerator"}
{ID = 6, Name = "Turret", ..., ModelName = "Turret"}
{ID = 7, Name = "Wall Section", ..., ModelName = "WallSection"}

-- Utility
{ID = 8, Name = "Storage Container", ..., ModelName = "StorageContainer"}
{ID = 9, Name = "Auto-Repair Drone", ..., ModelName = "AutoRepairDrone"}
{ID = 10, Name = "Water Pump", ..., ModelName = "WaterPump"}
```

### **Verificación:**
1. Compra un upgrade (por ejemplo, Solar Panel)
2. Deberías ver un modelo 3D detallado en lugar de un cubo gris
3. Algunos modelos tienen animaciones (turbinas rotan, drones flotan, etc.)

---

## 🟡 PROBLEMA #3: Barra de Vida Duplicada

### **Causa:**
Hay DOS barras de HP de la base:
1. **Billboard** en `BaseVisualsManager` (encima de la base) ✅ Funciona correctamente
2. **UI en pantalla** (StarterGui?) ❌ Duplicado innecesario

### **Solución:**

**Opción A: Eliminar UI de pantalla** (RECOMENDADO)

1. En Studio, ve a **StarterGui**
2. Busca un ScreenGui llamado `BaseHUD` o similar
3. Si existe, **elimínalo**
4. La barra Billboard es suficiente

**Opción B: Eliminar Billboard**

Si prefieres usar la UI de pantalla en lugar del Billboard:

1. Abre `ServerStorage.Managers.BaseVisualsManager`
2. Busca la línea 449:
   ```lua
   local billboard = createBillboard(basePart, playerName, userId)
   ```
3. Coméntala:
   ```lua
   -- local billboard = createBillboard(basePart, playerName, userId)
   local billboard = nil -- Deshabilitado
   ```

### **Verificación:**
1. Inicia el juego
2. Deberías ver solo UNA barra de HP de la base (no dos)

---

## ✅ PROBLEMA #4: Wall Sections se Sobreponen

### **Estado:** **YA ARREGLADO en GitHub** ✅

### **Causa:**
`BaseVisualsManager` creaba 4 muros decorativos **por default** al crear la base.
Cuando comprabas `Upgrade_7: Wall Section`, se creaban más muros en la misma posición.

### **Solución:**
Ya deshabilitélos muros por default en el código de GitHub.

### **Acción Requerida:**
1. Ve a GitHub: `ServerStorage/Managers/BaseVisualsManager.lua`
2. Copia el archivo actualizado a Studio
3. Reemplaza tu versión actual

**O edita manualmente:**

Busca línea ~445 en `BaseVisualsManager.lua`:
```lua
-- ANTES
local walls = createWalls(basePart)

-- DESPUÉS
-- DESHABILITADO: Muros por default (ahora se crean con Upgrade_7: Wall Section)
-- local walls = createWalls(basePart)
local walls = {} -- Sin muros por default
```

### **Verificación:**
1. Inicia el juego
2. Tu base NO debería tener muros al inicio
3. Compra `Wall Section` (Upgrade_7)
4. Ahora SÍ deberían aparecer los muros, sin solaparse

---

## 🟢 PROBLEMA #5: Contador de Waves NO Sube

### **Causa:**
El contador `ServerState.CurrentWave` **SÍ se incrementa** en el servidor, pero **NO hay UI** que lo muestre al jugador.

### **Solución:**

Crea un nuevo archivo: `StarterPlayerScripts/WaveCounterUI.client.lua`

```lua
--!strict
--[[
	WAVE COUNTER UI - Apocalypse Tycoon
	Muestra el número de waves sobrevividas
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Crear UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveCounterUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame contenedor (esquina superior derecha)
local container = Instance.new("Frame")
container.Name = "WaveCounter"
container.Size = UDim2.new(0, 200, 0, 60)
container.Position = UDim2.new(1, -220, 0, 20) -- Top-right
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BackgroundTransparency = 0.2
container.BorderSizePixel = 0
container.Parent = screenGui

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = container

-- Borde brillante
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 150, 0) -- Naranja
stroke.Thickness = 2
stroke.Parent = container

-- Icono/Emoji
local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.fromScale(0.3, 1)
icon.Position = UDim2.fromScale(0, 0)
icon.BackgroundTransparency = 1
icon.Text = "🌊" -- Wave emoji
icon.Font = Enum.Font.GothamBold
icon.TextSize = 28
icon.TextColor3 = Color3.fromRGB(100, 200, 255)
icon.Parent = container

-- Texto de wave number
local waveText = Instance.new("TextLabel")
waveText.Name = "WaveText"
waveText.Size = UDim2.fromScale(0.7, 0.5)
waveText.Position = UDim2.fromScale(0.3, 0)
waveText.BackgroundTransparency = 1
waveText.Text = "WAVE 1"
waveText.TextColor3 = Color3.new(1, 1, 1)
waveText.Font = Enum.Font.GothamBold
waveText.TextSize = 20
waveText.TextXAlignment = Enum.TextXAlignment.Left
waveText.Parent = container

-- Subtítulo
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.fromScale(0.7, 0.4)
subtitle.Position = UDim2.fromScale(0.3, 0.55)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Survived"
subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = container

-- Función para actualizar el contador
local function updateWaveCounter(waveNumber: number)
	waveText.Text = "WAVE " .. waveNumber

	-- Animación de pulse
	container.Size = UDim2.new(0, 210, 0, 65)
	task.wait(0.1)
	container.Size = UDim2.new(0, 200, 0, 60)
end

-- Escuchar cambios en el wave counter
-- OPCIÓN 1: Si tienes un RemoteEvent
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local waveUpdate = remotes:FindFirstChild("WaveUpdate")
	if waveUpdate and waveUpdate:IsA("RemoteEvent") then
		waveUpdate.OnClientEvent:Connect(updateWaveCounter)
	end
end

-- OPCIÓN 2: Si usas un IntValue en ReplicatedStorage
local waveValue = ReplicatedStorage:FindFirstChild("CurrentWave")
if waveValue and waveValue:IsA("IntValue") then
	-- Actualizar inmediatamente
	updateWaveCounter(waveValue.Value)

	-- Escuchar cambios
	waveValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateWaveCounter(waveValue.Value)
	end)
end

print("[WaveCounterUI] ✓ Wave counter UI creada")
```

### **Integración con el servidor:**

En tu `main.server.lua`, cuando incrementes el wave, TAMBIÉN actualiza un valor replicado:

**OPCIÓN 1: Usar IntValue** (Más simple)
```lua
-- Al inicio del script
local CurrentWaveValue = Instance.new("IntValue")
CurrentWaveValue.Name = "CurrentWave"
CurrentWaveValue.Value = 1
CurrentWaveValue.Parent = game.ReplicatedStorage

-- Cuando avanza el wave
ServerState.CurrentWave += 1
CurrentWaveValue.Value = ServerState.CurrentWave
```

**OPCIÓN 2: Usar RemoteEvent**
```lua
-- Al inicio
local WaveUpdate = Instance.new("RemoteEvent")
WaveUpdate.Name = "WaveUpdate"
WaveUpdate.Parent = game.ReplicatedStorage.Remotes

-- Cuando avanza el wave
ServerState.CurrentWave += 1
WaveUpdate:FireAllClients(ServerState.CurrentWave)
```

### **Verificación:**
1. Inicia el juego
2. Deberías ver "WAVE 1" en la esquina superior derecha
3. Sobrevive un wave completo
4. El contador debería cambiar a "WAVE 2" con una animación

---

## 🎯 CHECKLIST FINAL

Antes de testear, verifica que hayas hecho:

- [ ] **Camera Shake:** EventManager actualizado O líneas agregadas
- [ ] **ProceduralModels:** main.server.lua modificado para usar ProceduralModels:CreateModel()
- [ ] **Barra duplicada:** BaseHUD eliminado O Billboard deshabilitado
- [ ] **Wall Sections:** BaseVisualsManager actualizado (sin muros por default)
- [ ] **Wave Counter:** WaveCounterUI.client.lua creado + IntValue/RemoteEvent agregado

---

## 🚀 ORDEN DE IMPLEMENTACIÓN RECOMENDADO

1. **Primero:** Arregla Camera Shake (es el más rápido)
2. **Segundo:** Arregla Wall Sections (solo copiar archivo de GitHub)
3. **Tercero:** Elimina barra duplicada (buscar y eliminar BaseHUD)
4. **Cuarto:** Integra ProceduralModels (requiere editar main.server.lua)
5. **Quinto:** Agrega Wave Counter (crear nuevo archivo UI)

Cada arreglo es independiente, así que puedes testear después de cada uno.

---

## ❓ SI ALGO NO FUNCIONA

**Pásame:**
1. El error completo del Output
2. Qué archivo estás editando
3. En qué línea está el error

Y lo arreglo en minutos.

---

_Última actualización: Después de analizar todos los archivos actuales._
