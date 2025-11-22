--!strict
--[[
	POWER-UP NOTIFICATIONS (CLIENT) - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Sistema de notificaciones visuales ÉPICAS para power-ups.

	FEATURES:
	? Banner grande cuando colectas power-up
	? Floating income text cuando Coin Rain activo
	? Screen flash de colección
	? Sound effects impactantes
	? Animaciones fluidas

	UBICACIÓN: StarterPlayerScripts/Controllers/PowerUpNotifications
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

-------------------------------------------------------------------------
-- CONFIG
-------------------------------------------------------------------------

local CONFIG = {
	PowerUps = {
		ShieldBubble = {
			Icon = "???",
			Name = "SHIELD BUBBLE",
			Color = Color3.fromRGB(0, 170, 255),
			Message = "¡INVULNERABLE POR 10s!",
		},
		SlowMotion = {
			Icon = "??",
			Name = "SLOW MOTION",
			Color = Color3.fromRGB(150, 50, 200),
			Message = "¡Meteoritos 50% más lentos!",
		},
		CoinRain = {
			Icon = "??",
			Name = "COIN RAIN",
			Color = Color3.fromRGB(255, 215, 0),
			Message = "¡INGRESOS x2 POR 30s!",
		},
		AutoRepair = {
			Icon = "??",
			Name = "AUTO-REPAIR",
			Color = Color3.fromRGB(0, 255, 100),
			Message = "¡Regenerando +5 HP/s!",
		},
		DamageBoost = {
			Icon = "??",
			Name = "DAMAGE BOOST",
			Color = Color3.fromRGB(255, 50, 50),
			Message = "¡DAÑO x3 POR 15s!",
		},
	},

	-- Timing
	BannerDuration = 3, -- segundos
	FlashDuration = 0.3,
}

-------------------------------------------------------------------------
-- CREAR NOTIFICATION BANNER
-------------------------------------------------------------------------

local function createBanner(powerUpType: string): ScreenGui
	local data = CONFIG.PowerUps[powerUpType]
	if not data then return nil end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PowerUpBanner"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 100 -- Encima de todo
	screenGui.Parent = playerGui

	-- Container principal
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 400, 0, 100)
	container.Position = UDim2.new(0.5, 0, 0, -120) -- Arriba fuera de pantalla
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	-- Stroke con color del power-up
	local stroke = Instance.new("UIStroke")
	stroke.Color = data.Color
	stroke.Thickness = 3
	stroke.Parent = container

	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.new(1, 30, 1, 30)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	glow.ImageColor3 = data.Color
	glow.ImageTransparency = 0.5
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(10, 10, 10, 10)
	glow.ZIndex = 0
	glow.Parent = container

	-- Icon (grande)
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 70, 0, 70)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = data.Icon
	icon.TextSize = 50
	icon.Font = Enum.Font.FredokaOne
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = container

	-- Nombre del power-up
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -90, 0, 35)
	nameLabel.Position = UDim2.new(0, 85, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.Name
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = data.Color
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = container

	-- Mensaje descriptivo
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -90, 0, 25)
	messageLabel.Position = UDim2.new(0, 85, 0, 50)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = data.Message
	messageLabel.TextSize = 16
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.Parent = container

	-- Pulse del glow
	local pulseTween = TweenService:Create(
		glow,
		TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ ImageTransparency = 0.8 }
	)
	pulseTween:Play()

	return screenGui
end

-------------------------------------------------------------------------
-- ANIMACIONES
-------------------------------------------------------------------------

local function animateBanner(banner: ScreenGui)
	local container = banner:FindFirstChild("Container") :: Frame
	if not container then return end

	-- Slide down
	local slideDown = TweenService:Create(
		container,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 20) }
	)
	slideDown:Play()
	slideDown.Completed:Wait()

	-- Esperar
	task.wait(CONFIG.BannerDuration)

	-- Slide up y fade out
	local slideUp = TweenService:Create(
		container,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0, -120) }
	)
	slideUp:Play()
	slideUp.Completed:Wait()

	-- Destroy
	banner:Destroy()
end

-------------------------------------------------------------------------
-- SCREEN FLASH
-------------------------------------------------------------------------

local function screenFlash(color: Color3)
	-- Buscar si ya existe
	local existing = playerGui:FindFirstChild("PowerUpFlash")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PowerUpFlash"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 99
	screenGui.Parent = playerGui

	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.3
	flash.BorderSizePixel = 0
	flash.Parent = screenGui

	-- Fade out
	local tween = TweenService:Create(
		flash,
		TweenInfo.new(CONFIG.FlashDuration),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Wait()

	screenGui:Destroy()
end

-------------------------------------------------------------------------
-- FLOATING INCOME TEXT (Para Coin Rain)
-------------------------------------------------------------------------

local lastIncomeCheck = 0
local lastCash = 0

local function createFloatingIncomeText(amount: number)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. math.floor(amount) .. " (x2!)"
	label.TextSize = 24
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard

	-- Animación: sube y fade out
	task.spawn(function()
		local startPos = hrp.Position + Vector3.new(math.random(-2, 2), 5, math.random(-2, 2))
		local endPos = startPos + Vector3.new(0, 3, 0)

		for i = 0, 1, 0.05 do
			if not billboard or not billboard.Parent then break end

			billboard.StudsOffset = Vector3.new(0, 5 + (i * 3), 0)
			label.TextTransparency = i
			label.TextStrokeTransparency = 0.5 + (i * 0.5)

			task.wait(0.05)
		end

		billboard:Destroy()
	end)

	-- Attach to HRP
	billboard.Adornee = hrp
end

-- Monitor de income para Coin Rain
local function monitorCoinRain()
	RunService.Heartbeat:Connect(function()
		-- Solo chequear cada 0.5s
		if tick() - lastIncomeCheck < 0.5 then return end
		lastIncomeCheck = tick()

		-- Ver si tiene Coin Rain activo
		local multiplier = player:GetAttribute("CoinMultiplier")
		if not multiplier or multiplier <= 1 then
			lastCash = 0
			return
		end

		-- Obtener cash actual (si hay un leaderstats)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then return end

		local cashValue = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
		if not cashValue then return end

		local currentCash = cashValue.Value

		-- Si incrementó, mostrar floating text
		if lastCash > 0 and currentCash > lastCash then
			local diff = currentCash - lastCash
			if diff > 0 then
				createFloatingIncomeText(diff)
			end
		end

		lastCash = currentCash
	end)
end

-------------------------------------------------------------------------
-- EVENT HANDLERS
-------------------------------------------------------------------------

local function onPowerUpCollected(powerUpType: string, duration: number)
	local data = CONFIG.PowerUps[powerUpType]
	if not data then return end

	-- Screen flash
	screenFlash(data.Color)

	-- Banner notification
	local banner = createBanner(powerUpType)
	if banner then
		task.spawn(function()
			animateBanner(banner)
		end)
	end

	-- Sound effect (opcional)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://6026984224" -- Collect sound épico
	sound.Volume = 0.5
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	if powerUpType == "CoinRain" then
		print("[PowerUpNotifications] ?? COIN RAIN ACTIVO - Floating income text habilitado")
	end
end

-------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------

PowerUpCollected.OnClientEvent:Connect(onPowerUpCollected)

-- Iniciar monitor de Coin Rain
monitorCoinRain()

print("[PowerUpNotifications] ? Sistema de notificaciones cargado")