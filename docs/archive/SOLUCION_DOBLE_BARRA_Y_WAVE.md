# 🎯 SOLUCIÓN: Doble Barra + Wave Counter

## 🔴 PROBLEMA 1: Doble Barra de Vida

### ❌ El Código Duplicado Sigue Ahí

En **Main.Server.lua**, función `assignBase`, **HAY DOS BLOQUES** creando bases:

**BLOQUE 1 (✅ CORRECTO)** - Líneas 413-427:
```lua
-- 🆕 USAR BaseVisualsManager en lugar de crear base manualmente
local plate = BaseVisualsManager:CreateBase(
	plr.UserId,
	center,
	plr.Name,
	Config.BASE_SIZE
)

plate.Parent = getBasesFolder()
BasePartByUser[plr.UserId] = plate
plr:SetAttribute("BaseSlot", slot)

if DEBUG then
	print(("[BASE] Asignada base slot %d a %s"):format(slot, plr.Name))
end
```

**BLOQUE 2 (❌ DUPLICADO - BORRAR)** - Líneas 428-456:
```lua
local plate = Instance.new("Part")         ← ESTE ES EL PROBLEMA
plate.Name = plr.Name .. "_Base"
plate.Size = Config.BASE_SIZE
plate.Anchored = true
plate.Position = center
plate.Material = Enum.Material.Concrete
plate.Color = Config.BASE_COLORS.Default
plate:SetAttribute("OwnerUserId", plr.UserId)
plate.Parent = getBasesFolder()

-- Decoraciones
local border = Instance.new("Part")
border.Name = "Border"
border.Size = Vector3.new(Config.BASE_SIZE.X + 2, 0.5, Config.BASE_SIZE.Z + 2)
border.Anchored = true
border.Material = Enum.Material.Metal
border.Color = Color3.fromRGB(100, 100, 100)
border.CFrame = plate.CFrame * CFrame.new(0, -0.75, 0)
border.Parent = plate

--createBaseBillboard(plate, plr.Name, plr.UserId)

BasePartByUser[plr.UserId] = plate
plr:SetAttribute("BaseSlot", slot)

if DEBUG then
	print(("[BASE] Asignada base slot %d a %s"):format(slot, plr.Name))
end
```

### ✅ PASOS PARA ARREGLAR:

1. Abre **ServerScriptService.Main.Server**
2. Busca la función `assignBase` (Ctrl+F: "assignBase")
3. **MANTÉN** solo el primer bloque (líneas 413-427)
4. **BORRA COMPLETAMENTE** desde `local plate = Instance.new("Part")` hasta el segundo `if DEBUG then`
5. La función debe terminar con:
```lua
	if DEBUG then
		print(("[BASE] Asignada base slot %d a %s"):format(slot, plr.Name))
	end
end  -- ← Fin de la función assignBase
```

6. **Guarda** (Ctrl+S)

---

## 📊 PROBLEMA 2: Wave Counter No Visible

### ❌ Falta el Archivo Cliente

El servidor está sincronizando correctamente (viste el mensaje `[MAIN] ✅ Wave actualizada a 6`), pero **FALTA** el archivo que muestra la UI en pantalla.

### ✅ SOLUCIÓN: Crear WaveCounterUI.client.lua

**Ubicación:** `StarterGui` (NO StarterPlayerScripts)

**Nombre:** `WaveCounterUI.client.lua`

**Código completo:**
```lua
--!strict
--[[
	WAVE COUNTER UI
	═══════════════════════════════════════════════════════════════════════

	Muestra el número de wave actual en la esquina superior derecha
	Se actualiza automáticamente cuando ServerState.CurrentWave cambia

	Opciones de sincronización:
	- Opción A: IntValue en ReplicatedStorage (RECOMENDADO)
	- Opción B: RemoteEvent
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--═══════════════════════════════════════════════════════════════════════
-- CONFIG
--═══════════════════════════════════════════════════════════════════════
local DEBUG = true

--═══════════════════════════════════════════════════════════════════════
-- CREAR UI
--═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaveCounterGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Frame contenedor
local frame = Instance.new("Frame")
frame.Name = "WaveFrame"
frame.Size = UDim2.fromOffset(220, 80)
frame.Position = UDim2.new(1, -230, 0, 10) -- Esquina superior derecha
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 150, 0)
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = frame

-- Label "WAVE"
local labelWave = Instance.new("TextLabel")
labelWave.Name = "LabelWave"
labelWave.Size = UDim2.fromScale(1, 0.4)
labelWave.Position = UDim2.fromScale(0, 0.1)
labelWave.BackgroundTransparency = 1
labelWave.Text = "WAVE"
labelWave.TextColor3 = Color3.fromRGB(255, 150, 0)
labelWave.TextScaled = true
labelWave.Font = Enum.Font.GothamBold
labelWave.Parent = frame

-- Label número
local labelNumber = Instance.new("TextLabel")
labelNumber.Name = "LabelNumber"
labelNumber.Size = UDim2.fromScale(1, 0.5)
labelNumber.Position = UDim2.fromScale(0, 0.45)
labelNumber.BackgroundTransparency = 1
labelNumber.Text = "1"
labelNumber.TextColor3 = Color3.new(1, 1, 1)
labelNumber.TextScaled = true
labelNumber.Font = Enum.Font.GothamBlack
labelNumber.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 5)
padding.PaddingBottom = UDim.new(0, 5)
padding.Parent = frame

--═══════════════════════════════════════════════════════════════════════
-- ANIMACIONES
--═══════════════════════════════════════════════════════════════════════

local function playPulseAnimation()
	local tweenInfo = TweenInfo.new(
		0.3,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out,
		0,
		true
	)

	local tween = TweenService:Create(frame, tweenInfo, {
		Size = UDim2.fromOffset(240, 90)
	})

	tween:Play()
end

local function playFlash()
	-- Flash del borde
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	stroke.Transparency = 0
	local tween = TweenService:Create(stroke, tweenInfo, {
		Transparency = 0.5
	})
	tween:Play()

	-- Flash del texto
	labelWave.TextColor3 = Color3.new(1, 1, 1)
	local tweenText = TweenService:Create(labelWave, tweenInfo, {
		TextColor3 = Color3.fromRGB(255, 150, 0)
	})
	tweenText:Play()
end

local function updateWave(newWave: number)
	labelNumber.Text = tostring(newWave)

	-- Animaciones épicas
	playPulseAnimation()
	playFlash()

	if DEBUG then
		print(("[WaveCounterUI] 🎉 Wave %d alcanzada!"):format(newWave))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- OPCIÓN A: SINCRONIZACIÓN CON INTVALUE (RECOMENDADO)
--═══════════════════════════════════════════════════════════════════════

local currentWaveValue = ReplicatedStorage:WaitForChild("CurrentWave", 10)

if currentWaveValue and currentWaveValue:IsA("IntValue") then
	-- Valor inicial
	labelNumber.Text = tostring(currentWaveValue.Value)

	-- Escuchar cambios
	currentWaveValue:GetPropertyChangedSignal("Value"):Connect(function()
		updateWave(currentWaveValue.Value)
	end)

	if DEBUG then
		print("[WaveCounterUI] ✓ Conectado a CurrentWave IntValue")
	end
else
	warn("[WaveCounterUI] ⚠️ No se encontró CurrentWave en ReplicatedStorage")
end

--═══════════════════════════════════════════════════════════════════════
-- OPCIÓN B: SINCRONIZACIÓN CON REMOTEEVENT (ALTERNATIVA)
--═══════════════════════════════════════════════════════════════════════

--[[
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if Remotes then
	local WaveUpdate = Remotes:FindFirstChild("WaveUpdate")
	if WaveUpdate and WaveUpdate:IsA("RemoteEvent") then
		WaveUpdate.OnClientEvent:Connect(function(newWave: number)
			updateWave(newWave)
		end)

		if DEBUG then
			print("[WaveCounterUI] ✓ Conectado a WaveUpdate RemoteEvent")
		end
	end
end
--]]

--═══════════════════════════════════════════════════════════════════════

if DEBUG then
	print("[WaveCounterUI] ✓ UI inicializada")
end
```

### 📋 PASOS PARA IMPLEMENTAR:

1. En Roblox Studio, ve a **StarterGui**
2. Click derecho → Insert Object → Script
3. Cambia el nombre a: **`WaveCounterUI`**
4. Cambia la extensión a: **`.client.lua`** (LocalScript)
5. Pega el código completo de arriba
6. Guarda (Ctrl+S)

---

## 🧪 TESTING COMPLETO

### Test 1: Doble Barra
1. Aplica los cambios en Main.Server
2. Reinicia el servidor
3. Únete al juego
4. **Verifica:** Solo 1 base visible, solo 1 health bar

### Test 2: Wave Counter
1. Aplica el WaveCounterUI.client.lua
2. Reinicia el servidor
3. Únete al juego
4. **Verifica:** Contador "WAVE 1" en esquina superior derecha
5. Espera ~30 segundos (primera wave)
6. **Verifica:** Contador cambia a "WAVE 2" con animación épica

---

## ✅ RESULTADO ESPERADO

### Output del Servidor:
```
[MAIN] ✅ IntValue 'CurrentWave' creado en ReplicatedStorage
[WAVE] Iniciando Wave 2
[MAIN] ✅ Wave actualizada a 2 (sincronizada con cliente)
```

### Output del Cliente:
```
[WaveCounterUI] ✓ Conectado a CurrentWave IntValue
[WaveCounterUI] ✓ UI inicializada
[WaveCounterUI] 🎉 Wave 2 alcanzada!
```

### Visual:
- ✅ Solo 1 health bar por jugador
- ✅ Contador "WAVE X" en esquina superior derecha
- ✅ Animación de "pulse" + flash naranja al cambiar wave
- ✅ Se actualiza automáticamente

---

## 🎨 MEJORAS OPCIONALES (DESPUÉS)

Si quieres hacer el Wave Counter más épico:

1. **Notificación Grande en Centro:**
   - "WAVE 2 COMPLETED!"
   - Aparece 3 segundos
   - Desvanece

2. **Sonido:**
   - "whoosh" al cambiar wave
   - "fanfare" al completar wave 5, 10, 15...

3. **Recompensas:**
   - "+$500 Wave Bonus!"
   - Mostrar en pantalla

Pero primero asegúrate de que lo básico funcione. 🎯
