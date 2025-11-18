--!strict
--[[
	WAVE COUNTER UI
	═══════════════════════════════════════════════════════════════════════

	Muestra el número de wave actual en la esquina superior derecha
	Se actualiza automáticamente cuando ServerState.CurrentWave cambia

	INSTALACIÓN:
	1. Copiar este archivo a StarterGui en Roblox Studio
	2. Nombre: WaveCounterUI.client.lua (LocalScript)
	3. No requiere configuración adicional
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
-- SINCRONIZACIÓN CON SERVIDOR
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
	warn("[WaveCounterUI] ⚠️ Asegúrate de haber aplicado SNIPPET_MAIN_SERVER_WAVE_COUNTER.lua")
end

--═══════════════════════════════════════════════════════════════════════

if DEBUG then
	print("[WaveCounterUI] ✓ UI inicializada")
end
