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

--═══════════════════════════════════════════════════════════════════════
-- MENSAJE DE WAVE COMPLETADA
--═══════════════════════════════════════════════════════════════════════

-- Función para mostrar mensaje temporal de "WAVE X COMPLETADA"
local function showWaveCompletedMessage(waveNumber: number)
	-- Crear UI temporal
	local completedGui = Instance.new("ScreenGui")
	completedGui.Name = "WaveCompletedNotification"
	completedGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	completedGui.Parent = player:WaitForChild("PlayerGui")
	
	-- Frame contenedor (centro de la pantalla)
	local notifContainer = Instance.new("Frame")
	notifContainer.Size = UDim2.new(0, 400, 0, 100)
	notifContainer.Position = UDim2.new(0.5, -200, 0.3, 0)
	notifContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	notifContainer.BackgroundTransparency = 0.1
	notifContainer.BorderSizePixel = 0
	notifContainer.Parent = completedGui
	
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 15)
	notifCorner.Parent = notifContainer
	
	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = Color3.fromRGB(0, 255, 100) -- Verde para completada
	notifStroke.Thickness = 3
	notifStroke.Parent = notifContainer
	
	-- Icono
	local checkIcon = Instance.new("TextLabel")
	checkIcon.Size = UDim2.fromScale(0.2, 1)
	checkIcon.BackgroundTransparency = 1
	checkIcon.Text = "✅"
	checkIcon.Font = Enum.Font.GothamBold
	checkIcon.TextSize = 48
	checkIcon.Parent = notifContainer
	
	-- Texto principal
	local mainText = Instance.new("TextLabel")
	mainText.Size = UDim2.fromScale(0.8, 0.5)
	mainText.Position = UDim2.fromScale(0.2, 0.1)
	mainText.BackgroundTransparency = 1
	mainText.Text = string.format("WAVE %d", waveNumber)
	mainText.TextColor3 = Color3.fromRGB(255, 255, 100) -- Amarillo
	mainText.Font = Enum.Font.GothamBold
	mainText.TextSize = 32
	mainText.TextXAlignment = Enum.TextXAlignment.Left
	mainText.Parent = notifContainer
	
	-- Subtítulo
	local subText = Instance.new("TextLabel")
	subText.Size = UDim2.fromScale(0.8, 0.4)
	subText.Position = UDim2.fromScale(0.2, 0.55)
	subText.BackgroundTransparency = 1
	subText.Text = "COMPLETADA!"
	subText.TextColor3 = Color3.fromRGB(0, 255, 100) -- Verde
	subText.Font = Enum.Font.GothamBold
	subText.TextSize = 24
	subText.TextXAlignment = Enum.TextXAlignment.Left
	subText.Parent = notifContainer
	
	-- Animación de entrada
	notifContainer.Position = UDim2.new(0.5, -200, -0.2, 0)
	local enterTween = TweenService:Create(
		notifContainer,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, -200, 0.3, 0)}
	)
	enterTween:Play()
	
	-- Efecto de pulso en el borde
	task.spawn(function()
		for i = 1, 3 do
			TweenService:Create(
				notifStroke,
				TweenInfo.new(0.3),
				{Thickness = 5}
			):Play()
			task.wait(0.3)
			TweenService:Create(
				notifStroke,
				TweenInfo.new(0.3),
				{Thickness = 3}
			):Play()
			task.wait(0.3)
		end
	end)
	
	-- Destruir después de 5 segundos
	task.delay(4.5, function()
		local exitTween = TweenService:Create(
			notifContainer,
			TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, -200, -0.2, 0)}
		)
		exitTween:Play()
		exitTween.Completed:Connect(function()
			completedGui:Destroy()
		end)
	end)
	
	print(("[WaveCounterUI] ✅ Wave %d completada!"):format(waveNumber))
end

-- Escuchar evento de wave completada
local function connectToWaveCompletedEvent()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then return end
	
	local waveCompleted = remotes:WaitForChild("WaveCompleted", 5)
	if waveCompleted and waveCompleted:IsA("RemoteEvent") then
		waveCompleted.OnClientEvent:Connect(showWaveCompletedMessage)
		print("[WaveCounterUI] ✓ Conectado a WaveCompleted RemoteEvent")
	end
end

-- Conectar al evento de wave completada
connectToWaveCompletedEvent()
