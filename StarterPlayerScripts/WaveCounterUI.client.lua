--!strict
--[[
	WAVE COUNTER UI - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Muestra el número de waves sobrevividas en la esquina superior derecha.

	INSTALACIÓN:
	1. Copia este archivo a StarterPlayer.StarterPlayerScripts
	2. En main.server.lua, agrega sincronización (ver abajo)

	SINCRONIZACIÓN DESDE SERVIDOR:
	Opción A - Usar IntValue (MÁS SIMPLE):
		local CurrentWaveValue = Instance.new("IntValue")
		CurrentWaveValue.Name = "CurrentWave"
		CurrentWaveValue.Value = 1
		CurrentWaveValue.Parent = game.ReplicatedStorage

		-- Cuando avanza wave:
		ServerState.CurrentWave += 1
		CurrentWaveValue.Value = ServerState.CurrentWave

	Opción B - Usar RemoteEvent:
		local WaveUpdate = Instance.new("RemoteEvent")
		WaveUpdate.Name = "WaveUpdate"
		WaveUpdate.Parent = game.ReplicatedStorage.Remotes

		-- Cuando avanza wave:
		ServerState.CurrentWave += 1
		WaveUpdate:FireAllClients(ServerState.CurrentWave)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

--═══════════════════════════════════════════════════════════════════════
-- CREAR UI
--═══════════════════════════════════════════════════════════════════════

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
stroke.Color = Color3.fromRGB(255, 150, 0) -- Naranja apocalíptico
stroke.Thickness = 2
stroke.Parent = container

-- Icono/Emoji
local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.fromScale(0.3, 1)
icon.Position = UDim2.fromScale(0, 0)
icon.BackgroundTransparency = 1
icon.Text = "☄️" -- Meteorito
icon.Font = Enum.Font.GothamBold
icon.TextSize = 28
icon.TextColor3 = Color3.fromRGB(255, 150, 0)
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
waveText.TextStrokeTransparency = 0.5
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

--═══════════════════════════════════════════════════════════════════════
-- ANIMACIONES
--═══════════════════════════════════════════════════════════════════════

local function pulseAnimation()
	-- Expandir
	local expandTween = TweenService:Create(
		container,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 210, 0, 65)}
	)
	expandTween:Play()

	task.wait(0.15)

	-- Contraer
	local shrinkTween = TweenService:Create(
		container,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = UDim2.new(0, 200, 0, 60)}
	)
	shrinkTween:Play()
end

local function flashBorder()
	-- Flash amarillo brillante
	stroke.Color = Color3.fromRGB(255, 255, 100)

	TweenService:Create(
		stroke,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Color = Color3.fromRGB(255, 150, 0)}
	):Play()
end

--═══════════════════════════════════════════════════════════════════════
-- ACTUALIZACIÓN
--═══════════════════════════════════════════════════════════════════════

local function updateWaveCounter(waveNumber: number)
	waveText.Text = "WAVE " .. waveNumber

	-- Animaciones de celebración
	pulseAnimation()
	flashBorder()

	if waveNumber > 1 then
		print(("[WaveCounterUI] 🎉 Wave %d alcanzada!"):format(waveNumber))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- SINCRONIZACIÓN CON SERVIDOR
--═══════════════════════════════════════════════════════════════════════

-- OPCIÓN 1: Escuchar IntValue en ReplicatedStorage (MÁS COMÚN)
local function connectToIntValue()
	local waveValue = ReplicatedStorage:WaitForChild("CurrentWave", 5)

	if waveValue and waveValue:IsA("IntValue") then
		-- Actualizar inmediatamente
		updateWaveCounter(waveValue.Value)

		-- Escuchar cambios
		waveValue:GetPropertyChangedSignal("Value"):Connect(function()
			updateWaveCounter(waveValue.Value)
		end)

		print("[WaveCounterUI] ✓ Conectado a CurrentWave IntValue")
		return true
	end

	return false
end

-- OPCIÓN 2: Escuchar RemoteEvent
local function connectToRemoteEvent()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return false end

	local waveUpdate = remotes:WaitForChild("WaveUpdate", 5)

	if waveUpdate and waveUpdate:IsA("RemoteEvent") then
		waveUpdate.OnClientEvent:Connect(updateWaveCounter)
		print("[WaveCounterUI] ✓ Conectado a WaveUpdate RemoteEvent")
		return true
	end

	return false
end

-- Intentar conectar (prioriza IntValue)
local connected = connectToIntValue()

if not connected then
	connected = connectToRemoteEvent()
end

if not connected then
	warn("[WaveCounterUI] ⚠️ No se encontró CurrentWave (IntValue) ni WaveUpdate (RemoteEvent)")
	warn("[WaveCounterUI] El contador no se actualizará automáticamente")
	warn("[WaveCounterUI] Ver instrucciones en el header de este script")

	-- Mostrar wave 1 por default
	updateWaveCounter(1)
end

print("[WaveCounterUI] ✓ UI de wave counter creada")
