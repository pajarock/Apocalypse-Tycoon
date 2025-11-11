--!strict
--[[
	BASE DEATH UI - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Muestra pantalla roja dramática cuando tu base es destruida.

	CARACTERÍSTICAS:
	✅ Pantalla roja completa con texto grande
	✅ Muestra cuánto dinero perdiste
	✅ Cooldown visible para respawn
	✅ Animación de fade in/out
	✅ Audio de explosión (opcional)

	INSTALACIÓN:
	1. Copia este script a StarterGui como LocalScript
	2. Asegúrate que existe ReplicatedStorage.Remotes.BaseDead

	USO DESDE SERVIDOR (BaseModule):
		local BaseDead = ReplicatedStorage.Remotes.BaseDead
		BaseDead:FireClient(player, moneyLost, respawnTime)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Wait for RemoteEvent
local Remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local BaseDead = Remotes:WaitForChild("BaseDead") :: RemoteEvent

-------------------------------------------------------------------------
-- CREATE UI
-------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BaseDeathUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100 -- Por encima de todo
screenGui.IgnoreGuiInset = true
screenGui.Enabled = false -- Oculto por default
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Background rojo
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.Position = UDim2.fromScale(0, 0)
background.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
background.BackgroundTransparency = 0.3
background.BorderSizePixel = 0
background.ZIndex = 1
background.Parent = screenGui

-- Vignette (oscurecer bordes)
local vignette = Instance.new("ImageLabel")
vignette.Name = "Vignette"
vignette.Size = UDim2.fromScale(1, 1)
vignette.Position = UDim2.fromScale(0, 0)
vignette.BackgroundTransparency = 1
vignette.Image = "rbxasset://textures/ui/VignetteOverlay.png"
vignette.ImageColor3 = Color3.fromRGB(100, 0, 0)
vignette.ImageTransparency = 0.5
vignette.ZIndex = 2
vignette.Parent = screenGui

-- Texto principal "BASE DESTROYED"
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
titleLabel.Position = UDim2.new(0, 0, 0.25, 0)
titleLabel.AnchorPoint = Vector2.new(0, 0.5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "BASE DESTROYED"
titleLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 80
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.ZIndex = 3
titleLabel.Parent = screenGui

-- Gradiente en el texto
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 50, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 0))
})
gradient.Rotation = 90
gradient.Parent = titleLabel

-- Subtítulo "Money Lost"
local moneyLostLabel = Instance.new("TextLabel")
moneyLostLabel.Name = "MoneyLost"
moneyLostLabel.Size = UDim2.new(1, 0, 0.15, 0)
moneyLostLabel.Position = UDim2.new(0, 0, 0.45, 0)
moneyLostLabel.AnchorPoint = Vector2.new(0, 0.5)
moneyLostLabel.BackgroundTransparency = 1
moneyLostLabel.Text = "You lost $0"
moneyLostLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
moneyLostLabel.Font = Enum.Font.GothamBold
moneyLostLabel.TextSize = 36
moneyLostLabel.TextStrokeTransparency = 0.5
moneyLostLabel.ZIndex = 3
moneyLostLabel.Parent = screenGui

-- Countdown "Respawning in..."
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "Countdown"
countdownLabel.Size = UDim2.new(1, 0, 0.15, 0)
countdownLabel.Position = UDim2.new(0, 0, 0.6, 0)
countdownLabel.AnchorPoint = Vector2.new(0, 0.5)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = "Respawning in 10s..."
countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countdownLabel.Font = Enum.Font.Gotham
countdownLabel.TextSize = 28
countdownLabel.TextStrokeTransparency = 0.5
countdownLabel.ZIndex = 3
countdownLabel.Parent = screenGui

-------------------------------------------------------------------------
-- ANIMATIONS
-------------------------------------------------------------------------

local function pulseAnimation()
	-- Hacer que el título pulse
	local originalSize = titleLabel.TextSize

	while screenGui.Enabled do
		-- Expand
		TweenService:Create(
			titleLabel,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextSize = originalSize + 10}
		):Play()

		task.wait(0.8)

		-- Shrink
		TweenService:Create(
			titleLabel,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextSize = originalSize}
		):Play()

		task.wait(0.8)
	end
end

local function shakeBackground()
	-- Hacer que el fondo tiemble
	local originalTransparency = background.BackgroundTransparency

	while screenGui.Enabled do
		-- Darker
		TweenService:Create(
			background,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 0.1}
		):Play()

		task.wait(0.5)

		-- Lighter
		TweenService:Create(
			background,
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{BackgroundTransparency = 0.3}
		):Play()

		task.wait(0.5)
	end
end

-------------------------------------------------------------------------
-- EVENT HANDLER
-------------------------------------------------------------------------

BaseDead.OnClientEvent:Connect(function(moneyLost: number, respawnTime: number)
	-- Validate parameters
	moneyLost = moneyLost or 0
	respawnTime = respawnTime or 10

	-- Update text
	moneyLostLabel.Text = string.format("You lost $%s",
		tostring(math.floor(moneyLost)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	)

	-- Show UI
	screenGui.Enabled = true

	-- Start animations
	task.spawn(pulseAnimation)
	task.spawn(shakeBackground)

	-- Countdown
	local countdown = respawnTime
	while countdown > 0 do
		countdownLabel.Text = string.format("Respawning in %ds...", countdown)
		task.wait(1)
		countdown -= 1
	end

	-- Fade out
	local fadeOut = TweenService:Create(
		screenGui,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)

	TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(titleLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	TweenService:Create(moneyLostLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	TweenService:Create(countdownLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	TweenService:Create(vignette, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()

	task.wait(0.5)

	-- Hide UI
	screenGui.Enabled = false

	-- Reset transparencies para la próxima vez
	background.BackgroundTransparency = 0.3
	titleLabel.TextTransparency = 0
	titleLabel.TextStrokeTransparency = 0
	moneyLostLabel.TextTransparency = 0
	moneyLostLabel.TextStrokeTransparency = 0.5
	countdownLabel.TextTransparency = 0
	countdownLabel.TextStrokeTransparency = 0.5
	vignette.ImageTransparency = 0.5

	print("[BaseDeathUI] Respawn animation completed")
end)

print("[BaseDeathUI] ✓ Listening for base death events")
