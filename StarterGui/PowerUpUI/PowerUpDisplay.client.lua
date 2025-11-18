--!strict
--[[
	POWER-UP DISPLAY (CLIENT) - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	UI que muestra los power-ups activos con iconos y timers en tiempo real.

	UBICACIÓN: Esquina superior derecha
	ESTILO: Matching con el resto del UI (grafiti urbano)

	FEATURES:
	✅ Lista de power-ups activos
	✅ Timer countdown en tiempo real
	✅ Barra de progreso visual
	✅ Animaciones de entrada/salida
	✅ Warning cuando está por expirar (< 3s)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpCollected = RemotesFolder:WaitForChild("PowerUpCollected") :: RemoteEvent
local PowerUpExpired = RemotesFolder:WaitForChild("PowerUpExpired") :: RemoteEvent

--═══════════════════════════════════════════════════════════════════════
-- CONFIG
--═══════════════════════════════════════════════════════════════════════

local CONFIG = {
	-- Power-up data (matching PowerUpConfig)
	PowerUps = {
		ShieldBubble = {
			Icon = "🛡️",
			Name = "Shield Bubble",
			Color = Color3.fromRGB(0, 170, 255),
		},
		SlowMotion = {
			Icon = "⏱️",
			Name = "Slow Motion",
			Color = Color3.fromRGB(150, 50, 200),
		},
		CoinRain = {
			Icon = "💰",
			Name = "Coin Rain x2",
			Color = Color3.fromRGB(255, 215, 0),
		},
		AutoRepair = {
			Icon = "🔧",
			Name = "Auto-Repair",
			Color = Color3.fromRGB(0, 255, 100),
		},
		DamageBoost = {
			Icon = "💥",
			Name = "Damage Boost x3",
			Color = Color3.fromRGB(255, 50, 50),
		},
	},

	-- UI Settings
	Position = UDim2.new(1, -220, 0, 120), -- Top right
	EntrySize = UDim2.new(0, 200, 0, 50),
	Padding = 10,
	WarningThreshold = 3, -- segundos
}

--═══════════════════════════════════════════════════════════════════════
-- CREAR UI CONTAINER
--═══════════════════════════════════════════════════════════════════════

local function createMainUI(): ScreenGui
	-- Buscar si ya existe
	local existing = playerGui:FindFirstChild("PowerUpDisplayUI")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PowerUpDisplayUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Container para los power-ups
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 220, 1, 0)
	container.Position = CONFIG.Position
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- UIListLayout para organizar verticalmente
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, CONFIG.Padding)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.Parent = container

	return screenGui
end

--═══════════════════════════════════════════════════════════════════════
-- CREAR ENTRY DE POWER-UP
--═══════════════════════════════════════════════════════════════════════

local function createPowerUpEntry(powerUpType: string, duration: number): Frame
	local data = CONFIG.PowerUps[powerUpType]
	if not data then
		warn("[PowerUpDisplay] Power-up desconocido:", powerUpType)
		return nil
	end

	-- Frame principal
	local entry = Instance.new("Frame")
	entry.Name = "PowerUp_" .. powerUpType
	entry.Size = CONFIG.EntrySize
	entry.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	entry.BorderSizePixel = 0

	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = entry

	-- Stroke (borde) con color del power-up
	local stroke = Instance.new("UIStroke")
	stroke.Color = data.Color
	stroke.Thickness = 2
	stroke.Parent = entry

	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.new(1, 20, 1, 20)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	glow.ImageColor3 = data.Color
	glow.ImageTransparency = 0.7
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(10, 10, 10, 10)
	glow.ZIndex = 0
	glow.Parent = entry

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 5, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = data.Icon
	icon.TextSize = 28
	icon.Font = Enum.Font.FredokaOne
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = entry

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -90, 0, 20)
	nameLabel.Position = UDim2.new(0, 50, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.Name
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = entry

	-- Timer label
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(0, 50, 0, 20)
	timerLabel.Position = UDim2.new(1, -55, 0, 5)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = string.format("%.1fs", duration)
	timerLabel.TextSize = 14
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextColor3 = data.Color
	timerLabel.Parent = entry

	-- Progress bar background
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -60, 0, 6)
	progressBg.Position = UDim2.new(0, 50, 1, -12)
	progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = entry

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 3)
	progressCorner.Parent = progressBg

	-- Progress bar fill
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = data.Color
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 3)
	progressFillCorner.Parent = progressFill

	-- Attributes para tracking
	entry:SetAttribute("StartTime", tick())
	entry:SetAttribute("Duration", duration)
	entry:SetAttribute("PowerUpType", powerUpType)

	-- Animación de entrada
	entry.Size = UDim2.new(0, 0, 0, 50)
	entry.Position = UDim2.new(1, 0, 0, 0)

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(entry, tweenInfo, {
		Size = CONFIG.EntrySize
	})
	tween:Play()

	return entry
end

--═══════════════════════════════════════════════════════════════════════
-- ACTUALIZAR TIMERS
--═══════════════════════════════════════════════════════════════════════

local function updateTimers(container: Frame)
	for _, entry in ipairs(container:GetChildren()) do
		if entry:IsA("Frame") and entry.Name:match("^PowerUp_") then
			local startTime = entry:GetAttribute("StartTime")
			local duration = entry:GetAttribute("Duration")
			local powerUpType = entry:GetAttribute("PowerUpType")

			if not startTime or not duration then continue end

			local elapsed = tick() - startTime
			local remaining = math.max(0, duration - elapsed)

			-- Update timer label
			local timerLabel = entry:FindFirstChild("TimerLabel") :: TextLabel
			if timerLabel then
				timerLabel.Text = string.format("%.1fs", remaining)

				-- Warning color si está por expirar
				if remaining <= CONFIG.WarningThreshold then
					timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)

					-- Pulse effect
					if remaining > 0 then
						local pulse = math.sin(tick() * 10) * 0.5 + 0.5
						timerLabel.TextTransparency = pulse * 0.5
					end
				end
			end

			-- Update progress bar
			local progressFill = entry:FindFirstChild("ProgressBg"):FindFirstChild("ProgressFill") :: Frame
			if progressFill then
				local progress = remaining / duration
				progressFill.Size = UDim2.new(progress, 0, 1, 0)
			end
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
--═══════════════════════════════════════════════════════════════════════

local mainUI: ScreenGui = nil
local container: Frame = nil

local function onPowerUpCollected(powerUpType: string, duration: number)
	if not container then return end

	-- Si ya existe, removerlo primero (stack)
	local existing = container:FindFirstChild("PowerUp_" .. powerUpType)
	if existing then
		existing:Destroy()
	end

	-- Crear nuevo entry
	local entry = createPowerUpEntry(powerUpType, duration)
	if entry then
		entry.Parent = container
	end
end

local function onPowerUpExpired(powerUpType: string)
	if not container then return end

	local entry = container:FindFirstChild("PowerUp_" .. powerUpType)
	if not entry then return end

	-- Animación de salida
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local tween = TweenService:Create(entry, tweenInfo, {
		Size = UDim2.new(0, 0, 0, 50),
		Position = UDim2.new(1, 50, 0, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		entry:Destroy()
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- INIT
--═══════════════════════════════════════════════════════════════════════

mainUI = createMainUI()
container = mainUI:FindFirstChild("Container")

-- Connections
PowerUpCollected.OnClientEvent:Connect(onPowerUpCollected)
PowerUpExpired.OnClientEvent:Connect(onPowerUpExpired)

-- Update loop para timers
RunService.Heartbeat:Connect(function()
	if container then
		updateTimers(container)
	end
end)

print("[PowerUpDisplay] ✓ UI inicializada")
