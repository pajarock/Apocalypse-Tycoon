--!strict
--[[
	REWARD NOTIFICATION UI - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema de notificaciones ÉPICAS para recompensas de waves.
	Pantalla completa, animaciones dramáticas, imposible de ignorar.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════════
-- CREAR UI
-- ═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RewardNotificationUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000 -- Por encima de todo
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Fondo semi-transparente (oscurecimiento de pantalla)
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.Position = UDim2.fromScale(0, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 1
overlay.Parent = screenGui

-- Contenedor principal (centro de pantalla, ENORME)
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Position = UDim2.fromScale(0.5, 0.5)
mainContainer.Size = UDim2.fromOffset(800, 300) -- MUCHO MÁS GRANDE
mainContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainContainer.BackgroundTransparency = 1
mainContainer.BorderSizePixel = 0
mainContainer.Visible = false
mainContainer.ZIndex = 2
mainContainer.Parent = overlay

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainContainer

-- Borde brillante épico
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 0) -- Oro
stroke.Thickness = 6
stroke.Transparency = 1
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainContainer

-- Barra superior (indicador de tipo de recompensa)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 15)
topBar.Position = UDim2.fromOffset(0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
topBar.BackgroundTransparency = 1
topBar.BorderSizePixel = 0
topBar.ZIndex = 3
topBar.Parent = mainContainer

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 20)
topBarCorner.Parent = topBar

-- Icono épico (arriba del frame)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.AnchorPoint = Vector2.new(0.5, 0.5)
iconContainer.Position = UDim2.new(0.5, 0, 0.2, 0)
iconContainer.Size = UDim2.fromOffset(120, 120)
iconContainer.BackgroundTransparency = 1
iconContainer.ZIndex = 4
iconContainer.Parent = mainContainer

local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "IconLabel"
iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
iconLabel.Position = UDim2.fromScale(0.5, 0.5)
iconLabel.Size = UDim2.fromScale(1, 1)
iconLabel.BackgroundTransparency = 1
iconLabel.Font = Enum.Font.GothamBold
iconLabel.Text = "💰"
iconLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
iconLabel.TextScaled = true
iconLabel.TextStrokeTransparency = 0.5
iconLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
iconLabel.TextTransparency = 1
iconLabel.ZIndex = 5
iconLabel.Parent = iconContainer

-- Texto del título (centro-superior)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.Position = UDim2.new(0.5, 0, 0.45, 0)
titleLabel.Size = UDim2.new(0.9, 0, 0, 60)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "WAVE SURVIVED!"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.TextWrapped = true
titleLabel.TextStrokeTransparency = 0.5
titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
titleLabel.TextTransparency = 1
titleLabel.ZIndex = 5
titleLabel.Parent = mainContainer

-- Texto de recompensa (centro-inferior, MÁS GRANDE)
local rewardLabel = Instance.new("TextLabel")
rewardLabel.Name = "RewardLabel"
rewardLabel.AnchorPoint = Vector2.new(0.5, 0)
rewardLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
rewardLabel.Size = UDim2.new(0.9, 0, 0, 80)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Font = Enum.Font.GothamBold
rewardLabel.Text = "+$500"
rewardLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
rewardLabel.TextScaled = true
rewardLabel.TextWrapped = true
rewardLabel.TextStrokeTransparency = 0.3
rewardLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
rewardLabel.TextTransparency = 1
rewardLabel.ZIndex = 5
rewardLabel.Parent = mainContainer

-- ═══════════════════════════════════════════════════════════════════════
-- EFECTOS DE PARTÍCULAS
-- ═══════════════════════════════════════════════════════════════════════

local particlesContainer = Instance.new("Frame")
particlesContainer.Name = "ParticlesContainer"
particlesContainer.AnchorPoint = Vector2.new(0.5, 0.5)
particlesContainer.Position = UDim2.fromScale(0.5, 0.5)
particlesContainer.Size = UDim2.fromScale(1, 1)
particlesContainer.BackgroundTransparency = 1
particlesContainer.ClipsDescendants = false
particlesContainer.ZIndex = 10
particlesContainer.Parent = mainContainer

local function createParticle(color: Color3): Frame
	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(math.random(4, 8), math.random(4, 8))
	p.Position = UDim2.new(
		0.5 + (math.random() - 0.5) * 0.3,
		0,
		0.5 + (math.random() - 0.5) * 0.3,
		0
	)
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.BackgroundColor3 = color
	p.BackgroundTransparency = 0.2
	p.BorderSizePixel = 0
	p.ZIndex = 11
	p.Rotation = math.random(0, 360)
	p.Parent = particlesContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0) -- Círculo
	corner.Parent = p

	return p
end

local function animateParticles(color: Color3, duration: number)
	for i = 1, 30 do
		task.delay(math.random() * 0.5, function()
			local p = createParticle(color)

			-- Explotar hacia afuera
			local angle = math.random() * math.pi * 2
			local distance = 0.4 + math.random() * 0.3
			local targetX = 0.5 + math.cos(angle) * distance
			local targetY = 0.5 + math.sin(angle) * distance

			local tween = TweenService:Create(
				p,
				TweenInfo.new(duration * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Position = UDim2.fromScale(targetX, targetY),
					BackgroundTransparency = 1,
					Rotation = p.Rotation + math.random(-180, 180)
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				p:Destroy()
			end)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- PULSO BRILLANTE
-- ═══════════════════════════════════════════════════════════════════════

local pulseConnections: {RBXScriptConnection} = {}

local function pulseGlow()
	local t = 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		if mainContainer.Visible then
			t += dt * 3
			stroke.Transparency = 0.2 + math.sin(t) * 0.3
			topBar.BackgroundTransparency = 0.3 + math.sin(t) * 0.2
		else
			conn:Disconnect()
		end
	end)
	table.insert(pulseConnections, conn)
end

local function clearPulse()
	for _, conn in ipairs(pulseConnections) do
		conn:Disconnect()
	end
	table.clear(pulseConnections)
end

-- ═══════════════════════════════════════════════════════════════════════
-- FUNCIÓN PRINCIPAL: MOSTRAR RECOMPENSA
-- ═══════════════════════════════════════════════════════════════════════

local busy = false

local function showReward(rewardType: string, title: string, reward: string, color: Color3?)
	if busy then return end
	busy = true

	clearPulse()

	-- Colores por tipo
	local rewardColors = {
		normal = Color3.fromRGB(100, 200, 255), -- Azul
		miniboss = Color3.fromRGB(255, 150, 50), -- Naranja
		boss = Color3.fromRGB(255, 50, 50), -- Rojo
		victory = Color3.fromRGB(0, 255, 100) -- Verde
	}

	local iconsByType = {
		normal = "✅",
		miniboss = "💀",
		boss = "👑",
		victory = "🏆"
	}

	color = color or rewardColors[rewardType] or Color3.fromRGB(255, 215, 0)
	local icon = iconsByType[rewardType] or "💰"

	-- Configurar colores
	stroke.Color = color
	topBar.BackgroundColor3 = color
	iconLabel.Text = icon
	iconLabel.TextColor3 = color
	titleLabel.Text = string.upper(title)
	rewardLabel.Text = reward
	rewardLabel.TextColor3 = color

	-- Mostrar overlay y container
	overlay.Visible = true
	mainContainer.Visible = true

	-- Reset transparencias
	overlay.BackgroundTransparency = 1
	mainContainer.BackgroundTransparency = 1
	stroke.Transparency = 1
	topBar.BackgroundTransparency = 1
	iconLabel.TextTransparency = 1
	titleLabel.TextTransparency = 1
	rewardLabel.TextTransparency = 1

	-- Reset tamaño
	mainContainer.Size = UDim2.fromOffset(400, 150)
	iconContainer.Size = UDim2.fromOffset(60, 60)

	-- ═══════════════════════════════════════════════════════════════════
	-- ANIMACIÓN DE ENTRADA
	-- ═══════════════════════════════════════════════════════════════════

	-- Oscurecer pantalla
	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.6
	}):Play()

	-- Expandir frame
	TweenService:Create(mainContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(800, 300),
		BackgroundTransparency = 0.1
	}):Play()

	-- Borde y barra superior
	TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.2}):Play()
	TweenService:Create(topBar, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()

	task.wait(0.2)

	-- Icono con IMPACTO
	iconContainer.Size = UDim2.fromOffset(60, 60)
	TweenService:Create(iconContainer, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(120, 120)
	}):Play()

	TweenService:Create(iconLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

	task.wait(0.3)

	-- Título aparece
	TweenService:Create(titleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

	task.wait(0.2)

	-- Recompensa aparece MÁS GRANDE
	rewardLabel.Size = UDim2.new(0.7, 0, 0, 60)
	TweenService:Create(rewardLabel, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.9, 0, 0, 100),
		TextTransparency = 0
	}):Play()

	-- Efectos visuales
	pulseGlow()
	animateParticles(color, 2.5)

	-- Permanencia
	task.wait(3)

	-- ═══════════════════════════════════════════════════════════════════
	-- ANIMACIÓN DE SALIDA
	-- ═══════════════════════════════════════════════════════════════════

	TweenService:Create(rewardLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	task.wait(0.1)
	TweenService:Create(titleLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	task.wait(0.1)
	TweenService:Create(iconLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()

	task.wait(0.2)

	TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
	TweenService:Create(topBar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

	TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(400, 150),
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(overlay, TweenInfo.new(0.4), {
		BackgroundTransparency = 1
	}):Play()

	task.wait(0.5)

	overlay.Visible = false
	mainContainer.Visible = false
	clearPulse()

	busy = false
end

-- ═══════════════════════════════════════════════════════════════════════
-- CONECTAR CON SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if remotes then
	-- Crear remote si no existe
	local rewardNotif = remotes:FindFirstChild("ShowRewardNotification")
	if not rewardNotif then
		rewardNotif = remotes:WaitForChild("ShowRewardNotification", 5)
	end

	if rewardNotif and rewardNotif:IsA("RemoteEvent") then
		(rewardNotif :: RemoteEvent).OnClientEvent:Connect(function(rewardType: string, title: string, reward: string)
			showReward(rewardType, title, reward)
		end)
		print("[RewardNotificationUI] ✅ Sistema de recompensas épicas listo")
	else
		warn("[RewardNotificationUI] ⚠️ ShowRewardNotification remote no encontrado")
	end
else
	warn("[RewardNotificationUI] ⚠️ Remotes folder no encontrado")
end

-- Exportar función para uso local (debugging)
_G.ShowReward = showReward
