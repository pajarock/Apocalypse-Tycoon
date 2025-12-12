--!strict
--[[
	ShopUIController - Build Menu v2.0 (Knit)
	-----------------------------------------------------------------------

	Sistema completo de Shop/Build Menu con arquitectura moderna.

	CARACTER�STICAS:
	- 5 tabs principales: Income, Defense, Turrets, Utility, Eggs
	- 4 sub-tabs para Turrets: MG, Laser, Missile, Tesla
	- Grid adaptivo 3x4 con cards de 150x180px
	- Preview panel con stats comparison
	- Estados visuales: Available, Owned, Locked, Max
	- Auto-refresh cada 2 segundos
	- Keyboard toggle: Q key

	ARQUITECTURA:
	+-------------------------------------------------+
	� Header (Title + Cash + Close)                   �
	+-------------------------------------------------�
	� Main Tabs: Income|Defense|Turrets|Utility|Eggs  �
	� Sub-tabs (if Turrets): MG|Laser|Missile|Tesla   �
	+-------------------------------------------------�
	� Grid (60%)              �  Preview Panel (40%)  �
	� 3x4 cards (adaptive)    �  ViewportFrame 3D     �
	� Scroll 16px thick       �  Current vs After     �
	�                         �  Stats (4 max)        �
	�                         �  Buy button           �
	+-------------------------------------------------+
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Knit)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction
local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent

--[[------------------------------------------------------------------------
	TYPES & CONSTANTS
------------------------------------------------------------------------]]

type CardState = "Available" | "Owned" | "Locked" | "Max"

-- UI Constants
local MENU_SIZE = Vector2.new(800, 600)
local GRID_WIDTH_PERCENT = 0.6
local CARD_SIZE = Vector2.new(150, 180)
local CARD_PADDING = 8
local SCROLL_BAR_THICKNESS = 8  -- M�s delgado, apocal�ptico

-- Color scheme - APOCALYPTIC FINAL PALETTE ????
-- ONLY 4 COLORS + GRAYS for maximum cohesion
local COLORS = {
	-- FONDOS (radioactive industrial)
	Background = Color3.fromRGB(10, 10, 10),          -- Oscuro turbio
	BackgroundLight = Color3.fromRGB(24, 27, 17),
	BackgroundMid = Color3.fromRGB(20, 28, 20),
	BackgroundCard = Color3.fromRGB(5, 11, 5),

	-- NUCLEAR COLORS (controlados)
	NeonGreen = Color3.fromRGB(183, 255, 75),      -- Neon suave
	ToxicGreen = Color3.fromRGB(202, 255, 58),       -- Neon fuerte (usado solo en highlights)
	SludgeGreen = Color3.fromRGB(166, 190, 101),       -- Sludge industrial
	SludgeBright = Color3.fromRGB(180, 223, 112),     -- Sludge con vida
	NuclearYellow = Color3.fromRGB(220, 255, 140),  -- Amarillo radiactivo

	-- NEUTRALES
	White = Color3.fromRGB(255, 255, 255),
	LightGray = Color3.fromRGB(200, 200, 200),
	MidGray = Color3.fromRGB(150, 150, 150),
	DarkGray = Color3.fromRGB(70, 70, 70),
	DarkerGray = Color3.fromRGB(110, 110, 110),
	Shadow = Color3.fromRGB(0, 0, 0),

	-- UI ALIASES
	Header = Color3.fromRGB(110, 255, 110),         -- Verde neon suave (texto del t�tulo)
	BorderBright = Color3.fromRGB(70, 120, 70),     -- Sludge (borde del men�)
	TabActive = Color3.fromRGB(70, 120, 70),        -- Sludge activo (NO fosfo)
	TabInactive = Color3.fromRGB(20, 28, 20),       -- Sludge apagado

	Available = Color3.fromRGB(216, 255, 23),        -- Neon fuerte (solo items comprables)
	AvailableDark = Color3.fromRGB(20, 28, 20),

	Owned = Color3.fromRGB(220, 255, 140),          -- Amarillo nuclear
	OwnedDark = Color3.fromRGB(40, 40, 20),

	Locked = Color3.fromRGB(70, 70, 70),
	LockedDark = Color3.fromRGB(20, 28, 20),

	MaxTier = Color3.fromRGB(110, 255, 110),
	Gold = Color3.fromRGB(220, 255, 140),

	-- COMPAT PARA EL C�DIGO ANTERIOR
	LavaRed = Color3.fromRGB(70, 120, 70),          -- Antes rojo, ahora sludge
	FireYellow = Color3.fromRGB(220, 255, 140),
}






-- Tab definitions - CORRECT ORDER!
-- NO custom colors - all use apocalyptic palette
local MAIN_TABS = {
	{name = "INCOME", emoji = "💰"},
	{name = "TURRETS", emoji = "💀"},
	{name = "MY BASE", emoji = "🏠"},
	{name = "PETS", emoji = "🐾"},
	{name = "POWERUPS", emoji = "⚡"},
}

local TURRET_SUBTABS = {
	{name = "MachineGun", emoji = "💀", displayName = "MG"},  -- FIRST! Cheapest and easiest
	{name = "Laser", emoji = "⚡", displayName = "LASER"},
	{name = "Missile", emoji = "💥", displayName = "MISSILE LAUNCHER"},
	{name = "Tesla", emoji = "🔮", displayName = "TESLA COIL"},
}

-- Generator definitions (Income) - 5 TIERS!
local GENERATORS = {
	{
		id = "Generator",
		name = "Hand Crank Generator",
		icon = "⚙️",
		tier = 1,
		cost = 100,
		size = Vector3.new(6, 5, 6),
		description = "Basic money generator. Place many to increase income!",
		income = "$10/sec",
	},
	{
		id = "GeneratorT2",
		name = "Solar Panel",
		icon = "⚙️",
		tier = 2,
		cost = 500,
		size = Vector3.new(7, 6, 7),
		description = "Improved generator with better output!",
		income = "$50/sec",
	},
	{
		id = "GeneratorT3",
		name = "Wind Turbine",
		icon = "⚙️",
		tier = 3,
		cost = 2500,
		size = Vector3.new(8, 7, 8),
		description = "Advanced generator for serious income!",
		income = "$250/sec",
	},
	{
		id = "GeneratorT4",
		name = "Fusion Core",
		icon = "⚙️",
		tier = 4,
		cost = 12500,
		size = Vector3.new(9, 8, 9),
		description = "High-tech generator with massive output!",
		income = "$1,250/sec",
	},
	{
		id = "GeneratorT5",
		name = "Quantum Extractor",
		icon = "⚙️",
		tier = 5,
		cost = 62500,
		size = Vector3.new(10, 9, 10),
		description = "Ultimate generator - maximum money production!",
		income = "$6,250/sec",
	},
}

-- Turret type definitions (from TurretDefinitions.luau)
local TURRET_TYPES = {
	MachineGun = {
		{id = "MachineGunT1", tier = 1, cost = 5000, damage = 8, fireRate = 0.25, range = 50, placeable = true},
		{id = "MachineGunT2", tier = 2, cost = 20000, damage = 12, fireRate = 0.20, range = 60, placeable = false},
		{id = "MachineGunT3", tier = 3, cost = 80000, damage = 18, fireRate = 0.15, range = 70, placeable = false},
		{id = "MachineGunT4", tier = 4, cost = 350000, damage = 28, fireRate = 0.12, range = 80, placeable = false},
		{id = "MachineGunT5", tier = 5, cost = 1500000, damage = 45, fireRate = 0.10, range = 100, placeable = false},
	},
	Laser = {
		{id = "LaserT1", tier = 1, cost = 15000, dps = 100, range = 70, placeable = true},
		{id = "LaserT2", tier = 2, cost = 60000, dps = 200, range = 80, placeable = false},
		{id = "LaserT3", tier = 3, cost = 250000, dps = 400, range = 90, placeable = false},
		{id = "LaserT4", tier = 4, cost = 1000000, dps = 800, range = 100, placeable = false},
		{id = "LaserT5", tier = 5, cost = 4500000, dps = 1600, range = 120, placeable = false},
	},
	Missile = {
		{id = "MissileT1", tier = 1, cost = 40000, damage = 150, cooldown = 3.0, range = 100, placeable = true},
		{id = "MissileT2", tier = 2, cost = 150000, damage = 300, cooldown = 2.5, range = 110, placeable = false},
		{id = "MissileT3", tier = 3, cost = 600000, damage = 600, cooldown = 2.0, range = 120, placeable = false},
		{id = "MissileT4", tier = 4, cost = 2500000, damage = 1200, cooldown = 1.5, range = 130, placeable = false},
		{id = "MissileT5", tier = 5, cost = 10000000, damage = 2500, cooldown = 1.0, range = 150, placeable = false},
	},
	Tesla = {
		{id = "TeslaT1", tier = 1, cost = 100000, dps = 200, chains = 2, range = 60, placeable = true},
		{id = "TeslaT2", tier = 2, cost = 400000, dps = 400, chains = 3, range = 70, placeable = false},
		{id = "TeslaT3", tier = 3, cost = 1600000, dps = 800, chains = 4, range = 80, placeable = false},
		{id = "TeslaT4", tier = 4, cost = 6500000, dps = 1600, chains = 5, range = 90, placeable = false},
		{id = "TeslaT5", tier = 5, cost = 27000000, dps = 3200, chains = 6, range = 100, placeable = false},
	},
}

local TURRET_ICONS = {
	MachineGun = "💀", -- Skull for death machine
	Laser = "⚡",      -- Lightning bolt
	Missile = "💥",    -- Explosion
	Tesla = "🔮",      -- Crystal ball for electric
}

--[[------------------------------------------------------------------------
	CONTROLLER DEFINITION
------------------------------------------------------------------------]]

local ShopUIController = Knit.CreateController({
	Name = "ShopUIController",
})

-- Internal state
local player = Players.LocalPlayer
local screenGui: ScreenGui
local mainFrame: Frame
local shadow: Frame
local cashLabel: TextLabel
local closeButton: TextButton
local mainTabsRow: Frame
local subTabsRow: Frame
local gridContainer: ScrollingFrame
local previewPanel: Frame
local previewPlaceholder: TextLabel
local viewportFrame: ViewportFrame
local statsContainer: Frame
local statsGrid: Frame
local buyButton: TextButton
local descriptionLabel: TextLabel

local mainTabButtons: {[string]: TextButton} = {}
local subTabButtons: {[string]: TextButton} = {}
local cardInstances: {[string]: Frame} = {}
local cardGlows: {[string]: Frame} = {}  -- ✨ Para controlar el glow de selección

local currentMainTab = "INCOME"  -- Start with Income tab
local currentSubTab = "MachineGun"
local selectedItem: any? = nil
local isMenuOpen = false

-- Services & Controllers (obtained in KnitStart)
local BasePlacementController
local BaseOwnershipService
local UpgradeTurretRemote: RemoteEvent

-- Ambient audio
local ambientSound: Sound? = nil

-- ☢️ Visual Effects & Audio
local slimeDripContainer: Frame? = nil
local particleContainer: Frame? = nil
local clickSound: Sound? = nil
local menuOpenSound: Sound? = nil
local slimeDripActive = false
local particlesActive = false

--[[------------------------------------------------------------------------
	UTILITY FUNCTIONS
------------------------------------------------------------------------]]

local function formatMoney(amount: number): string
	if amount >= 1e12 then
		return string.format("$%.2fT", amount / 1e12)
	elseif amount >= 1e9 then
		return string.format("$%.2fB", amount / 1e9)
	elseif amount >= 1e6 then
		return string.format("$%.2fM", amount / 1e6)
	elseif amount >= 1e3 then
		return string.format("$%.2fK", amount / 1e3)
	else
		return string.format("$%d", math.floor(amount))
	end
end

local function createUICorner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createUIStroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

--[[------------------------------------------------------------------------
	☢️ VISUAL EFFECTS & AUDIO SYSTEM
------------------------------------------------------------------------]]

-- 💧 TOXIC SLIME DRIP EFFECT
local slimeDripStartFunc = nil
local function createSlimeDrip(parentFrame: Frame)
	local container = Instance.new("Frame")
	container.Name = "SlimeDripContainer"
	container.Size = UDim2.new(1, 0, 0, 100)
	container.Position = UDim2.new(0, 0, 0, 0)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = false
	container.ZIndex = 10
	container.Parent = parentFrame

	-- Función para crear una gota - MÁS VISIBLE 💧
	local function createDrip(xPercent: number)
		local drip = Instance.new("Frame")
		drip.Name = "SlimeDrip"
		drip.Size = UDim2.new(0, 6, 0, 0)  -- Más ancho (era 3, ahora 6)
		drip.Position = UDim2.new(xPercent, 0, 0, 0)
		drip.BackgroundColor3 = COLORS.ToxicGreen
		drip.BorderSizePixel = 0
		drip.ZIndex = 11

		local glow = Instance.new("UIStroke")
		glow.Color = COLORS.NeonGreen
		glow.Thickness = 3  -- Más grueso (era 2, ahora 3)
		glow.Transparency = 0.2  -- Más visible (era 0.3, ahora 0.2)
		glow.Parent = drip

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = drip

		drip.Parent = container

		local dripLength = math.random(25, 60)  -- Más largo (era 15-40, ahora 25-60)
		local dripSpeed = math.random(8, 15) / 10

		local growTween = TweenService:Create(drip, TweenInfo.new(dripSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 6, 0, dripLength)
		})

		growTween:Play()
		growTween.Completed:Connect(function()
			local fadeTween = TweenService:Create(drip, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
				BackgroundTransparency = 1
			})
			local fadeGlow = TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
				Transparency = 1
			})

			fadeTween:Play()
			fadeGlow:Play()

			fadeTween.Completed:Connect(function()
				drip:Destroy()
			end)
		end)
	end

	-- Sistema de generación - GUARDAR FUNCIÓN PARA REINICIAR
	slimeDripStartFunc = function()
		task.spawn(function()
			while slimeDripActive and container.Parent do
				local numDrips = math.random(2, 4)  -- Más gotas (era 1-3, ahora 2-4)
				for i = 1, numDrips do
					local xPos = math.random(5, 95) / 100
					createDrip(xPos)
					task.wait(math.random(1, 2) / 10)  -- Más frecuente
				end
				task.wait(math.random(15, 30) / 10)  -- Menos espera (era 20-40, ahora 15-30)
			end
		end)
	end

	return container
end

-- ☢️ RADIOACTIVE PARTICLE SYSTEM
local particleStartFunc = nil
local function createRadioactiveParticles(parentFrame: Frame)
	local container = Instance.new("Frame")
	container.Name = "ParticleContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.ClipsDescendants = true
	container.ZIndex = 5
	container.Parent = parentFrame

	local function createParticle()
		local particle = Instance.new("Frame")
		particle.Name = "RadParticle"

		local size = math.random(2, 5)
		particle.Size = UDim2.new(0, size, 0, size)

		local startX = math.random(0, 100) / 100
		particle.Position = UDim2.new(startX, 0, 1, 0)

		local colorChoice = math.random(1, 3)
		if colorChoice == 1 then
			particle.BackgroundColor3 = COLORS.NeonGreen
		elseif colorChoice == 2 then
			particle.BackgroundColor3 = COLORS.ToxicGreen
		else
			particle.BackgroundColor3 = COLORS.SludgeBright
		end

		particle.BackgroundTransparency = 0.3
		particle.BorderSizePixel = 0
		particle.ZIndex = 6

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		local glow = Instance.new("UIStroke")
		glow.Color = COLORS.NeonGreen
		glow.Thickness = 1
		glow.Transparency = 0.5
		glow.Parent = particle

		particle.Parent = container

		local floatTime = math.random(30, 50) / 10
		local endY = -0.2
		local horizontalDrift = (math.random(-10, 10) / 100)

		local floatTween = TweenService:Create(particle, TweenInfo.new(floatTime, Enum.EasingStyle.Linear), {
			Position = UDim2.new(startX + horizontalDrift, 0, endY, 0),
			BackgroundTransparency = 1
		})

		local glowFade = TweenService:Create(glow, TweenInfo.new(floatTime, Enum.EasingStyle.Linear), {
			Transparency = 1
		})

		floatTween:Play()
		glowFade:Play()

		floatTween.Completed:Connect(function()
			particle:Destroy()
		end)
	end

	-- GUARDAR FUNCIÓN PARA REINICIAR
	particleStartFunc = function()
		task.spawn(function()
			while particlesActive and container.Parent do
				local numParticles = math.random(1, 2)
				for i = 1, numParticles do
					createParticle()
				end
				task.wait(math.random(3, 8) / 10)
			end
		end)
	end

	return container
end

-- 🔊 CLICK SOUND
local function createClickSound(parentFrame: Frame): Sound
	local sound = Instance.new("Sound")
	sound.Name = "ClickSound"
	sound.SoundId = "rbxassetid://12221967"  -- Cambiar por tu asset ID
	sound.Volume = 0.3
	sound.PlaybackSpeed = 1.2
	sound.Parent = parentFrame
	return sound
end

local function addClickSoundToButton(button: GuiButton)
	button.MouseButton1Click:Connect(function()
		if clickSound then
			local soundClone = clickSound:Clone()
			soundClone.Parent = clickSound.Parent
			soundClone:Play()
			soundClone.Ended:Connect(function()
				soundClone:Destroy()
			end)
		end
	end)
end

-- 🔊 MENU OPEN SOUND
local function createMenuOpenSound(parentFrame: Frame): Sound
	local sound = Instance.new("Sound")
	sound.Name = "MenuOpenSound"
	sound.SoundId = "rbxassetid://3398620867"  -- Cambiar por tu asset ID
	sound.Volume = 0.4
	sound.PlaybackSpeed = 1.0
	sound.Parent = parentFrame
	return sound
end

-- 🎬 MENU ANIMATIONS
local function playOpenAnimation(frame: Frame)
	-- Estado inicial
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.55, 0)
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Rotation = -5

	-- Reproducir sonido
	if menuOpenSound then
		menuOpenSound:Play()
	end

	-- Animación
	local openTween = TweenService:Create(frame, TweenInfo.new(
		0.4,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	), {
		Size = UDim2.new(0, MENU_SIZE.X, 0, MENU_SIZE.Y),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Rotation = 0
	})

	openTween:Play()
	return openTween
end

local function playCloseAnimation(frame: Frame)
	local closeTween = TweenService:Create(frame, TweenInfo.new(
		0.25,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.45, 0),
		Rotation = 5
	})

	closeTween:Play()
	return closeTween
end

--[[------------------------------------------------------------------------
	UI CREATION
------------------------------------------------------------------------]]

local function createMainUI(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "ShopUIv2"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 5
	return gui
end

local function createStructure()
	-- Shadow
	shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromOffset(MENU_SIZE.X + 10, MENU_SIZE.Y + 10)
	shadow.Position = UDim2.new(0.5, -MENU_SIZE.X/2 + 5, 0.5, -MENU_SIZE.Y/2 + 5)
	shadow.BackgroundColor3 = COLORS.Shadow
	shadow.BackgroundTransparency = 0.5
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1
	shadow.Parent = screenGui
	createUICorner(shadow, 12)

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.fromOffset(MENU_SIZE.X, MENU_SIZE.Y)
	mainFrame.Position = UDim2.new(0.5, -MENU_SIZE.X/2, 0.5, -MENU_SIZE.Y/2)
	mainFrame.BackgroundColor3 = COLORS.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 2
	mainFrame.Parent = screenGui
	createUICorner(mainFrame, 16)  -- ?? M�s redondeado, m�s premium
	createUIStroke(mainFrame, COLORS.BorderBright, 3)


	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = COLORS.BackgroundLight
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	createUICorner(header, 12)

	-- Padding para que no est� pegado
	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingTop = UDim.new(0, 8)
	headerPadding.PaddingBottom = UDim.new(0, 8)
	headerPadding.PaddingLeft = UDim.new(0, 16)
	headerPadding.PaddingRight = UDim.new(0, 16)
	headerPadding.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.5, -60, 1, 0)
	title.Position = UDim2.fromOffset(20, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Bangers  -- ?? APOCALYPTIC GRAFFITI STYLE!
	title.TextSize = 28  -- Bigger, bolder!
	title.TextColor3 = COLORS.Header  -- Rojo lava
	title.Text = "??? BUILD MENU V2.0"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Add stroke for better visibility - sombra negra
	local titleStroke = createUIStroke(title, COLORS.Shadow, 4)
	titleStroke.Transparency = 0.4

	cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "Cash"
	cashLabel.Size = UDim2.new(0.4, 0, 1, 0)
	cashLabel.Position = UDim2.new(0.3, 0, 0, 0)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.TextSize = 20
	cashLabel.TextColor3 = COLORS.FireYellow  -- #FFA500 Amarillo fuego
	cashLabel.Text = "$0"
	cashLabel.TextXAlignment = Enum.TextXAlignment.Center
	cashLabel.Parent = header

	closeButton = Instance.new("TextButton")
	closeButton.Name = "Close"
	closeButton.Size = UDim2.fromOffset(40, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = 20
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Text = "X"  -- Simple X works better than special characters
	closeButton.Parent = header
	createUICorner(closeButton, 8)

	-- Tabs container
	local tabsContainer = Instance.new("Frame")
	tabsContainer.Name = "TabsContainer"
	tabsContainer.Size = UDim2.new(1, 0, 0, 90)
	tabsContainer.Position = UDim2.fromOffset(0, 50)
	tabsContainer.BackgroundTransparency = 1
	tabsContainer.Parent = mainFrame

	mainTabsRow = Instance.new("Frame")
	mainTabsRow.Name = "MainTabs"
	mainTabsRow.Size = UDim2.new(1, -20, 0, 40)
	mainTabsRow.Position = UDim2.fromOffset(10, 5)
	mainTabsRow.BackgroundTransparency = 1
	mainTabsRow.Parent = tabsContainer

	local mainTabsLayout = Instance.new("UIListLayout")
	mainTabsLayout.FillDirection = Enum.FillDirection.Horizontal
	mainTabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mainTabsLayout.Padding = UDim.new(0, 8)
	mainTabsLayout.Parent = mainTabsRow

	subTabsRow = Instance.new("Frame")
	subTabsRow.Name = "SubTabs"
	subTabsRow.Size = UDim2.new(1, -20, 0, 36)
	subTabsRow.Position = UDim2.fromOffset(10, 50)
	subTabsRow.BackgroundTransparency = 1
	subTabsRow.Visible = false
	subTabsRow.Parent = tabsContainer

	local subTabsLayout = Instance.new("UIListLayout")
	subTabsLayout.FillDirection = Enum.FillDirection.Horizontal
	subTabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	subTabsLayout.Padding = UDim.new(0, 6)
	subTabsLayout.Parent = subTabsRow

	-- Content area
	local contentArea = Instance.new("Frame")
	contentArea.Name = "Content"
	contentArea.Size = UDim2.new(1, -20, 1, -160)
	contentArea.Position = UDim2.fromOffset(10, 145)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent = mainFrame

	-- Grid container
	gridContainer = Instance.new("ScrollingFrame")
	gridContainer.Name = "GridContainer"
	gridContainer.Size = UDim2.new(GRID_WIDTH_PERCENT, -5, 1, 0)
	gridContainer.Position = UDim2.fromScale(0, 0)
	gridContainer.BackgroundColor3 = COLORS.BackgroundLight
	gridContainer.BackgroundTransparency = 0.3
	gridContainer.BorderSizePixel = 0
	gridContainer.ScrollBarThickness = SCROLL_BAR_THICKNESS  -- 8px delgado
	gridContainer.ScrollBarImageColor3 = COLORS.LavaRed  -- ?? Rojo lava!
	gridContainer.ScrollBarImageTransparency = 0.2  -- Con opacidad
	gridContainer.CanvasSize = UDim2.fromScale(1, 0)
	gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	gridContainer.ScrollingDirection = Enum.ScrollingDirection.Y  -- ONLY VERTICAL SCROLL!
	gridContainer.Parent = contentArea
	createUICorner(gridContainer, 8)

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	gridLayout.CellPadding = UDim2.fromOffset(CARD_PADDING, CARD_PADDING)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- IMPORTANTE: m�ximo 3 columnas
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.FillDirectionMaxCells = 3
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	gridLayout.Parent = gridContainer

	local gridPadding = Instance.new("UIPadding")
	gridPadding.PaddingTop = UDim.new(0, 8)
	gridPadding.PaddingBottom = UDim.new(0, 8)
	gridPadding.PaddingLeft = UDim.new(0, 8)
	gridPadding.PaddingRight = UDim.new(0, 8)
	gridPadding.Parent = gridContainer

	-- Preview panel
	previewPanel = Instance.new("Frame")
	previewPanel.Name = "PreviewPanel"
	previewPanel.Size = UDim2.new(1 - GRID_WIDTH_PERCENT, -5, 1, 0)
	previewPanel.Position = UDim2.new(GRID_WIDTH_PERCENT, 5, 0, 0)
	previewPanel.BackgroundColor3 = COLORS.BackgroundLight
	previewPanel.BackgroundTransparency = 0.3
	previewPanel.BorderSizePixel = 0
	previewPanel.Parent = contentArea
	createUICorner(previewPanel, 8)

	previewPlaceholder = Instance.new("TextLabel")
	previewPlaceholder.Name = "Placeholder"
	previewPlaceholder.Size = UDim2.fromScale(1, 1)
	previewPlaceholder.Position = UDim2.fromScale(0, 0)
	previewPlaceholder.BackgroundTransparency = 1
	previewPlaceholder.Font = Enum.Font.GothamBold
	previewPlaceholder.TextSize = 120  -- HUGE nuclear icon
	previewPlaceholder.TextColor3 = COLORS.NuclearYellow  -- Nuclear yellow
	previewPlaceholder.TextTransparency = 0.7  -- Semi-transparent
	previewPlaceholder.Text = "☢️"  -- Nuclear icon
	previewPlaceholder.TextWrapped = false
	previewPlaceholder.TextYAlignment = Enum.TextYAlignment.Center
	previewPlaceholder.TextXAlignment = Enum.TextXAlignment.Center
	previewPlaceholder.Parent = previewPanel

	-- Add glow to nuclear icon
	local nuclearGlow = Instance.new("UIStroke")
	nuclearGlow.Color = COLORS.ToxicGreen
	nuclearGlow.Thickness = 3
	nuclearGlow.Transparency = 0.6
	nuclearGlow.Parent = previewPlaceholder

	-- ViewportFrame
	viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "ViewportFrame"
	viewportFrame.Size = UDim2.new(1, -20, 0, 200)
	viewportFrame.Position = UDim2.fromOffset(10, 10)
	viewportFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	viewportFrame.BackgroundTransparency = 0.5
	viewportFrame.BorderSizePixel = 0
	viewportFrame.Visible = false
	viewportFrame.Parent = previewPanel
	createUICorner(viewportFrame, 8)

	-- Stats container - APOCALYPTIC PANEL!
	statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(1, -20, 0, 140)
	statsContainer.Position = UDim2.fromOffset(10, 220)
	statsContainer.BackgroundColor3 = COLORS.BackgroundLight  -- #1A1A1A
	statsContainer.BackgroundTransparency = 0
	statsContainer.BorderSizePixel = 0
	statsContainer.Visible = false
	statsContainer.Parent = previewPanel
	createUICorner(statsContainer, 8)

	-- Borde rojo lava para el panel
	local statsStroke = createUIStroke(statsContainer, COLORS.LavaRed, 2)
	statsStroke.Transparency = 0

	local statsTitle = Instance.new("TextLabel")
	statsTitle.Size = UDim2.new(1, -16, 0, 25)
	statsTitle.Position = UDim2.fromOffset(8, 5)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.TextSize = 16
	statsTitle.TextColor3 = COLORS.FireYellow  -- #FFA500 Amarillo fuego
	statsTitle.Text = "?? ITEM INFO"
	statsTitle.TextXAlignment = Enum.TextXAlignment.Center
	statsTitle.Parent = statsContainer

	statsGrid = Instance.new("Frame")
	statsGrid.Name = "StatsGrid"
	statsGrid.Size = UDim2.new(1, -16, 1, -35)
	statsGrid.Position = UDim2.fromOffset(8, 33)
	statsGrid.BackgroundTransparency = 1
	statsGrid.Parent = statsContainer

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.Padding = UDim.new(0, 3)
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Parent = statsGrid

	-- Buy button - APOCALYPTIC STYLE!
	buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(1, -20, 0, 60)
	buyButton.Position = UDim2.fromOffset(10, 370)
	buyButton.BackgroundColor3 = COLORS.ToxicGreen  -- Verde t�xico por default
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 22
	buyButton.TextColor3 = COLORS.Background  -- Negro carb�n #0F0F0F
	buyButton.Text = "BUY"
	buyButton.AutoButtonColor = true
	buyButton.Visible = false
	buyButton.Parent = previewPanel
	createUICorner(buyButton, 10)

	-- Add a THICK stroke to the buy button - Borde amarillo fuego o negro seg�n estado
	local buyButtonStroke = createUIStroke(buyButton, COLORS.FireYellow, 3)  -- 3px thick!
	buyButtonStroke.Transparency = 0

	-- Description - NOW VISIBLE! Moved inside statsContainer at the bottom
	descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "Description"
	descriptionLabel.Size = UDim2.new(1, -16, 0, 35)
	descriptionLabel.Position = UDim2.fromOffset(8, 105)  -- Below stats grid
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.TextSize = 11
	descriptionLabel.TextColor3 = COLORS.MidGray  -- #BBBBBB Gris suave
	descriptionLabel.Text = ""
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.Visible = false
	descriptionLabel.Parent = statsContainer  -- NOW inside statsContainer!

	-- ?? AMBIENT AUDIO - Brasas/Carb�n encendido
	-- TODO: Add SoundId when asset is ready
	ambientSound = Instance.new("Sound")
	ambientSound.Name = "AmbientForge"
	ambientSound.SoundId = "rbxassetid://158853971"
	ambientSound.Volume = 0.08  -- 8% volumen (5-12% range)
	ambientSound.Looped = true
	ambientSound.PlaybackSpeed = 1
	ambientSound.Parent = mainFrame
	-- Note: Will play when menu opens, stop when closes
end

--[[------------------------------------------------------------------------
	TAB SYSTEM
------------------------------------------------------------------------]]

local function updateTabStates()
	for tabName, tabButton in pairs(mainTabButtons) do
		if tabName == currentMainTab then
			-- ACTIVO: Rojo lava con texto negro carb�n
			tabButton.BackgroundColor3 = COLORS.LavaRed
			tabButton.BackgroundTransparency = 0
			tabButton.TextColor3 = COLORS.NuclearYellow  -- Negro carb�n #0F0F0F
			tabButton.TextSize = 18
		else
			-- INACTIVO: Gris oscuro con texto gris claro
			tabButton.BackgroundColor3 = COLORS.TabInactive
			tabButton.BackgroundTransparency = 0
			tabButton.TextColor3 = COLORS.LightGray  -- #CCCCCC
			tabButton.TextSize = 16
		end
	end

	if currentMainTab == "TURRETS" then
		subTabsRow.Visible = true
		for subName, subButton in pairs(subTabButtons) do
			if subName == currentSubTab then
				-- ACTIVO: Rojo lava con texto negro carb�n
				subButton.BackgroundColor3 = COLORS.LavaRed
				subButton.BackgroundTransparency = 0
				subButton.TextColor3 = COLORS.Background  -- Negro carb�n
			else
				-- INACTIVO: Gris con texto gris claro
				subButton.BackgroundColor3 = COLORS.TabInactive
				subButton.BackgroundTransparency = 0
				subButton.TextColor3 = COLORS.LightGray
			end
		end
	else
		subTabsRow.Visible = false
	end

	ShopUIController:PopulateGrid()
end

local function createMainTab(tabData: {name: string, emoji: string})
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. tabData.name
	btn.Size = UDim2.fromOffset(130, 40)
	btn.BackgroundColor3 = COLORS.TabInactive
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Bangers  -- ?? Apocalyptic font!
	btn.TextSize = 17  -- Slightly bigger for Bangers
	btn.TextColor3 = COLORS.LightGray  -- #CCCCCC
	btn.Text = tabData.emoji .. " " .. tabData.name
	btn.AutoButtonColor = false
	btn.Parent = mainTabsRow

	createUICorner(btn, 8)
	local stroke = createUIStroke(btn, COLORS.LavaRed, 2)  -- ?? Rojo lava border
	stroke.Transparency = 0

	btn.MouseButton1Click:Connect(function()
		currentMainTab = tabData.name
		updateTabStates()
	end)

	btn.MouseEnter:Connect(function()
		if currentMainTab ~= tabData.name then
			-- PRONOUNCED BOUNCE animation - scale up with bounce!
			local tweenInfo = TweenInfo.new(
				0.4,  -- Duration
				Enum.EasingStyle.Bounce,  -- Bounce style!
				Enum.EasingDirection.Out
			)
			local goal = {Size = UDim2.fromOffset(140, 45)}  -- Bigger!
			local tween = TweenService:Create(btn, tweenInfo, goal)
			tween:Play()
			btn.BackgroundTransparency = 0.1
		end
	end)

	btn.MouseLeave:Connect(function()
		if currentMainTab ~= tabData.name then
			-- Return to normal size smoothly
			local tweenInfo = TweenInfo.new(
				0.3,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)
			local goal = {Size = UDim2.fromOffset(130, 40)}
			local tween = TweenService:Create(btn, tweenInfo, goal)
			tween:Play()
			btn.BackgroundTransparency = 0.3
		end
	end)

	mainTabButtons[tabData.name] = btn
end

local function createSubTab(subData: {name: string, emoji: string, displayName: string})
	local btn = Instance.new("TextButton")
	btn.Name = "SubTab_" .. subData.name
	btn.Size = UDim2.fromOffset(90, 36)
	btn.BackgroundColor3 = COLORS.TabInactive
	btn.BackgroundTransparency = 0
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Bangers  -- ?? Apocalyptic font!
	btn.TextSize = 15  -- Slightly bigger for Bangers
	btn.TextColor3 = COLORS.LightGray  -- #CCCCCC
	btn.Text = subData.emoji .. " " .. subData.displayName
	btn.AutoButtonColor = false
	btn.Parent = subTabsRow

	createUICorner(btn, 6)
	local stroke = createUIStroke(btn, COLORS.LavaRed, 1)  -- ?? Rojo lava border
	stroke.Transparency = 0

	btn.MouseButton1Click:Connect(function()
		currentSubTab = subData.name
		updateTabStates()
	end)

	btn.MouseEnter:Connect(function()
		if currentSubTab ~= subData.name then
			-- PRONOUNCED BOUNCE animation for subtabs too!
			local tweenInfo = TweenInfo.new(
				0.4,
				Enum.EasingStyle.Bounce,
				Enum.EasingDirection.Out
			)
			local goal = {Size = UDim2.fromOffset(96, 40)}  -- Slightly bigger
			local tween = TweenService:Create(btn, tweenInfo, goal)
			tween:Play()
			btn.BackgroundTransparency = 0.1
		end
	end)

	btn.MouseLeave:Connect(function()
		if currentSubTab ~= subData.name then
			-- Return to normal size
			local tweenInfo = TweenInfo.new(
				0.3,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			)
			local goal = {Size = UDim2.fromOffset(90, 36)}
			local tween = TweenService:Create(btn, tweenInfo, goal)
			tween:Play()
			btn.BackgroundTransparency = 0.3
		end
	end)

	subTabButtons[subData.name] = btn
end

--[[------------------------------------------------------------------------
	CARD SYSTEM
------------------------------------------------------------------------]]

local function getCardStateVisuals(state: CardState, canAfford: boolean)
	if state == "Max" then
		return {
			backgroundColor = COLORS.BackgroundCard,
			badgeText = "⭐",
			badgeColor = COLORS.MaxTier,
			strokeColor = COLORS.MaxTier,
			glowColor   = COLORS.MaxTier,
		}

	elseif state == "Owned" then
		return {
			backgroundColor = COLORS.BackgroundCard,
			badgeText = "💎",
			badgeColor = COLORS.Owned,
			strokeColor = COLORS.Owned,
			glowColor   = COLORS.Owned,
		}

	elseif state == "Locked" then
		return {
			backgroundColor = COLORS.BackgroundCard,
			badgeText = "🔒",
			badgeColor = COLORS.DarkGray,
			strokeColor = COLORS.DarkGray,
			glowColor   = COLORS.DarkGray,
		}

	else
		-- AVAILABLE
		local activeColor = canAfford and COLORS.Available or COLORS.DarkGray

		return {
			backgroundColor = COLORS.BackgroundCard,
			badgeText = "✓",
			badgeColor = activeColor,
			strokeColor = activeColor,
			glowColor = COLORS.NuclearYellow,

		}
	end
end




local function makeCard(itemData: any): Frame
	-- Container para card + shadow
	local container = Instance.new("Frame")
	container.Name = "CardContainer_" .. itemData.id
	container.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0

	-- Shadow frame - ?? AAA look!
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	shadow.Position = UDim2.fromOffset(3, 3)  -- Offset para profundidad
	shadow.BackgroundColor3 = COLORS.Shadow
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1
	shadow.Parent = container
	createUICorner(shadow, 10)

	-- Card actual
	local container = Instance.new("Frame")
	container.Name = "CardContainer_" .. itemData.id
	container.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = gridContainer

	-- Shadow
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	shadow.Position = UDim2.fromOffset(3, 3)
	shadow.BackgroundColor3 = COLORS.Shadow
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1
	shadow.Parent = container
	createUICorner(shadow, 10)

	-- VISUALES PRIMERO
	local visuals = getCardStateVisuals(itemData.state, itemData.canAfford)

	-- Card
	local card = Instance.new("Frame")
	card.Name = "Card_" .. itemData.id
	card.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	card.Position = UDim2.fromOffset(0, 0)
	card.BackgroundColor3 = visuals.backgroundColor or COLORS.BackgroundCard
	card.BorderSizePixel = 0
	card.ZIndex = 5
	card.Parent = container
	createUICorner(card, 10)

	local stroke = createUIStroke(card, visuals.strokeColor, 3)
	stroke.Transparency = 0.30

	-- ✨ Glow - SOLO VISIBLE EN CARD SELECCIONADA
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1, 20, 1, 1)
	glow.Position = UDim2.fromOffset(-16, -16)
	glow.BackgroundColor3 = visuals.glowColor or visuals.strokeColor
	glow.BackgroundTransparency = 1  -- ✨ INVISIBLE por default
	glow.ZIndex = 3
	glow.Parent = container
	createUICorner(glow, 20)

	-- Guardar referencia al glow
	cardGlows[itemData.id] = glow


	-- Badge
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(32, 32)
	badge.Position = UDim2.new(1, -36, 0, 4)
	badge.BackgroundColor3 = visuals.badgeColor
	badge.BackgroundTransparency = 0.2
	badge.BorderSizePixel = 0
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 18
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.Text = visuals.badgeText
	badge.ZIndex = 3
	badge.Parent = card
	createUICorner(badge, 6)

	-- Icon - BIGGER!
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, -16, 0, 70)
	iconLabel.Position = UDim2.fromOffset(8, 35)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 56
	iconLabel.TextColor3 = COLORS.White
	iconLabel.Text = itemData.icon
	iconLabel.ZIndex = 2
	iconLabel.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -16, 0, 22)
	nameLabel.Position = UDim2.fromOffset(8, 108)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Bangers  -- ?? Apocalyptic font!
	nameLabel.TextSize = 13  -- Slightly bigger for Bangers
	nameLabel.TextColor3 = COLORS.White
	nameLabel.Text = itemData.name
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.ZIndex = 2
	nameLabel.Parent = card

	-- Price - BIGGER and MORE PROMINENT!
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -16, 0, 28)
	priceLabel.Position = UDim2.fromOffset(8, 133)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 18
	priceLabel.TextColor3 = COLORS.FireYellow  -- #FFA500 Amarillo fuego
	priceLabel.Text = formatMoney(itemData.price)
	priceLabel.TextXAlignment = Enum.TextXAlignment.Center
	priceLabel.ZIndex = 2
	priceLabel.Parent = card

	-- Count
	if itemData.count > 0 then
		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -16, 0, 18)
		countLabel.Position = UDim2.fromOffset(8, 155)
		countLabel.BackgroundTransparency = 1
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextSize = 12
		countLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
		countLabel.Text = itemData.maxCount and itemData.count >= itemData.maxCount
			and string.format("x%d [MAX]", itemData.count)
			or string.format("x%d", itemData.count)
		countLabel.TextXAlignment = Enum.TextXAlignment.Center
		countLabel.ZIndex = 2
		countLabel.Parent = card
	end

	-- Click button
	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.fromScale(1, 1)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.ZIndex = 4
	clickButton.Parent = card

	clickButton.MouseButton1Click:Connect(function()
		-- Check if player can't afford this item
		if not itemData.canAfford and itemData.state ~= "Owned" and itemData.state ~= "Max" then
			-- SHAKE effect - slight position shake
			local originalPos = card.Position
			local shakeSequence = {
				UDim2.fromOffset(3, 2),
				UDim2.fromOffset(-3, -2),
				UDim2.fromOffset(2, -3),
				UDim2.fromOffset(-2, 3),
				UDim2.fromOffset(0, 0)
			}

			task.spawn(function()
				for _, offset in ipairs(shakeSequence) do
					card.Position = UDim2.fromOffset(offset.X.Offset, offset.Y.Offset)
					task.wait(0.05)
				end
				card.Position = originalPos
			end)

			-- Price label turns RED briefly
			local originalColor = priceLabel.TextColor3
			priceLabel.TextColor3 = Color3.fromRGB(255, 60, 60) -- Bright red
			task.delay(0.2, function()
				priceLabel.TextColor3 = originalColor
			end)

			return -- Don't select the item
		end

		selectedItem = itemData
		ShopUIController:UpdatePreviewPanel(itemData)

		-- ✨ Actualizar glows: Solo la seleccionada brilla
		for cardId, cardGlow in pairs(cardGlows) do
			if cardId == itemData.id then
				-- Mostrar glow en card seleccionada
				TweenService:Create(cardGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					BackgroundTransparency = 0.5
				}):Play()
			else
				-- Ocultar glow en otras cards
				TweenService:Create(cardGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					BackgroundTransparency = 1
				}):Play()
			end
		end
	end)

	clickButton.MouseEnter:Connect(function()
		-- Hover effect: grow 10% + brightness increase
		local newSize = UDim2.fromOffset(CARD_SIZE.X * 1.1, CARD_SIZE.Y * 1.1)
		local hoverTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = newSize
		})
		hoverTween:Play()

		-- Increase brightness by making background lighter
		local brighterColor = Color3.fromRGB(
			math.min(255, visuals.backgroundColor.R * 255 * 1.3),
			math.min(255, visuals.backgroundColor.G * 255 * 1.3),
			math.min(255, visuals.backgroundColor.B * 255 * 1.3)
		)
		local colorTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = brighterColor
		})
		colorTween:Play()

		stroke.Thickness = 3
	end)

	clickButton.MouseLeave:Connect(function()
		-- Return to normal size and color
		local normalSize = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
		local leaveTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = normalSize,
			BackgroundColor3 = visuals.backgroundColor
		})
		leaveTween:Play()

		stroke.Thickness = 2
	end)

	container.Parent = gridContainer
	cardInstances[itemData.id] = container  -- Guardamos el container, no el card
	return container
end

local function clearCards()
	for id, card in pairs(cardInstances) do
		card:Destroy()
		cardInstances[id] = nil
	end
	-- ✨ Limpiar glows también
	for id, glow in pairs(cardGlows) do
		cardGlows[id] = nil
	end
end

--[[------------------------------------------------------------------------
	PREVIEW PANEL
------------------------------------------------------------------------]]

-- Simplified stat row - APOCALYPTIC COLORS!
local function createStatRow(statName: string, value: string, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = statsGrid

	-- Stat name (left side) - Gris claro
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = COLORS.LightGray  -- #CCCCCC Gris claro
	nameLabel.Text = statName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	-- Value (right side) - VERDE T�XICO!
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.55, 0, 1, 0)
	valueLabel.Position = UDim2.fromScale(0.45, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 14
	valueLabel.TextColor3 = COLORS.ToxicGreen  -- #39FF14 Verde t�xico radioactivo!
	valueLabel.Text = value
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = row
end

-- ☢️ NEW: Create decorative stat bar with animated fill
local function createStatBar(statName: string, fillPercent: number, order: number)
	local barContainer = Instance.new("Frame")
	barContainer.Name = "StatBar_" .. statName
	barContainer.Size = UDim2.new(1, 0, 0, 26)
	barContainer.BackgroundTransparency = 1
	barContainer.LayoutOrder = order
	barContainer.Parent = statsGrid

	-- Stat label
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.35, 0, 0, 12)
	label.Position = UDim2.fromOffset(0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.TextColor3 = COLORS.LightGray
	label.Text = statName
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = barContainer

	-- Bar background
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0, 12)
	barBg.Position = UDim2.fromOffset(0, 14)
	barBg.BackgroundColor3 = COLORS.BackgroundCard
	barBg.BorderSizePixel = 0
	barBg.Parent = barContainer
	createUICorner(barBg, 4)

	local barStroke = createUIStroke(barBg, COLORS.DarkGray, 1)
	barStroke.Transparency = 0.5

	-- Bar fill (animated)
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)  -- Start at 0 width
	barFill.Position = UDim2.fromOffset(0, 0)
	barFill.BackgroundColor3 = COLORS.NuclearYellow  -- Nuclear yellow!
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	createUICorner(barFill, 4)

	-- Glow effect on fill
	local fillGlow = createUIStroke(barFill, COLORS.ToxicGreen, 2)
	fillGlow.Transparency = 0.3

	-- Animate fill
	local targetSize = UDim2.new(math.clamp(fillPercent, 0, 1), 0, 1, 0)
	local fillTween = TweenService:Create(barFill, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = targetSize
	})
	fillTween:Play()

	return barContainer
end

function ShopUIController:UpdatePreviewPanel(itemData: any?)
	if not itemData then
		previewPlaceholder.Visible = true
		viewportFrame.Visible = false
		statsContainer.Visible = false
		buyButton.Visible = false
		descriptionLabel.Visible = false
		return
	end

	previewPlaceholder.Visible = false
	viewportFrame.Visible = true
	statsContainer.Visible = true

	-- Clear stats
	for _, child in ipairs(statsGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create stats - 3 DECORATIVE BARS: Income, Range, Fire Rate
	if itemData.stats then
		-- Define the 3 stats we want to show as bars
		local statsToShow = {
			{name = "INCOME", key = "INCOME", maxValue = 10000, icon = "💰"},
			{name = "RANGE", key = "RNG", maxValue = 150, icon = "🎯"},
			{name = "FIRE RATE", key = "FR", maxValue = 2, icon = "⚡"},
		}

		local order = 1
		for _, statConfig in ipairs(statsToShow) do
			local statData = itemData.stats[statConfig.key]
			if statData then
				-- Extract numeric value from stat
				local value = statData.current or statData.after or 0

				-- If value is string (like "0.25s"), try to extract number
				if type(value) == "string" then
					local numMatch = string.match(value, "([%d%.]+)")
					value = tonumber(numMatch) or 0
				end

				-- Calculate fill percent (0-1)
				local fillPercent = math.min(1, tonumber(value) / statConfig.maxValue)

				-- Create decorative bar
				createStatBar(statConfig.icon .. " " .. statConfig.name, fillPercent, order)
				order += 1
			end
		end

		-- If we didn't find the expected stats, fallback to showing any stats as rows
		if order == 1 then
			for statName, statValues in pairs(itemData.stats) do
				if order <= 3 then
					local value = tostring(statValues.current or statValues.after or "0")
					createStatRow(statName, value, order)
					order += 1
				end
			end
		end
	end

	-- Update button based on item type - APOCALYPTIC COLORS!
	buyButton.Visible = true
	local itemType = itemData.itemType
	local btnStroke = buyButton:FindFirstChildOfClass("UIStroke")

	if itemType == "placeholder" then
		buyButton.Text = "? COMING SOON"
		buyButton.BackgroundColor3 = COLORS.DarkGray  -- #333333
		buyButton.TextColor3 = COLORS.DarkerGray  -- #777777
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.Shadow end
	elseif itemType == "owned" then
		buyButton.Text = "? OWNED"
		buyButton.BackgroundColor3 = COLORS.FireYellow
		buyButton.TextColor3 = COLORS.Background
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.FireYellow end
	elseif itemType == "locked" or itemData.state == "Locked" then
		buyButton.Text = "?? LOCKED"
		buyButton.BackgroundColor3 = COLORS.DarkGray  -- #333333
		buyButton.TextColor3 = COLORS.DarkerGray  -- #777777
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.Shadow end
	elseif itemType == "generator" or itemType == "place" then
		-- PLACE: Verde t�xico con texto negro, borde amarillo
		buyButton.Text = itemType == "generator"
			and string.format("PLACE FOR %s", formatMoney(itemData.price))
			or string.format("PLACE T1 FOR %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = COLORS.ToxicGreen  -- #39FF14
		buyButton.TextColor3 = COLORS.Background  -- #0F0F0F Negro carb�n
		buyButton.AutoButtonColor = true
		if btnStroke then btnStroke.Color = COLORS.FireYellow end  -- Borde amarillo fuego
	elseif itemType == "upgrade" then
		-- UPGRADE: Amarillo fuego con texto negro, borde amarillo
		buyButton.Text = string.format("UPGRADE FOR %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = COLORS.FireYellow  -- #FFA500
		buyButton.TextColor3 = COLORS.Background  -- #0F0F0F Negro carb�n
		buyButton.AutoButtonColor = true
		if btnStroke then btnStroke.Color = COLORS.FireYellow end
	else
		buyButton.Text = "?? " .. formatMoney(itemData.price)
		buyButton.BackgroundColor3 = COLORS.DarkGray
		buyButton.TextColor3 = COLORS.DarkerGray
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.Shadow end
	end

	descriptionLabel.Visible = true
	descriptionLabel.Text = itemData.description or "No description"
end

--[[------------------------------------------------------------------------
	DATA LOADING
------------------------------------------------------------------------]]

local function fetchState()
	local ok, state = pcall(function()
		return RequestState:InvokeServer()
	end)
	if not ok then
		warn("[ShopUIController] Failed to fetch state:", state)
		return {Cash = 0, UpgradesInfo = {}}
	end
	return state
end

local function getCardState(count: number, maxCount: number?, price: number, cash: number): CardState
	if maxCount and count >= maxCount then return "Max"
	elseif count > 0 then return "Owned"
	elseif cash >= price then return "Available"
	else return "Locked" end
end

-- Helper: Get player's turrets of a specific type and find highest tier
local function getPlayerTurretTier(turretType: string): number?
	local ok, objects = pcall(function()
		return BaseOwnershipService:GetMyObjects(player)
	end)

	if not ok then
		warn("[ShopUIController] Error getting objects:", objects)
		return nil
	end

	if not objects or type(objects) ~= "table" then
		return nil
	end

	local highestTier = nil
	for i, obj in ipairs(objects) do
		if obj.ObjectType and obj.ObjectType:match("^" .. turretType) then
			-- Extract tier from type (e.g., "MachineGunT2" -> 2)
			local tierStr = obj.ObjectType:match("T(%d+)$")
			if tierStr then
				local tier = tonumber(tierStr)
				if not highestTier or tier > highestTier then
					highestTier = tier
				end
			end
		end
	end
	return highestTier
end

-- Helper: Get ObjectId of a specific turret type
local function getTurretObjectId(turretType: string): string?
	local ok, objects = pcall(function()
		return BaseOwnershipService:GetMyObjects(player)
	end)

	if not ok or not objects then
		warn("[ShopUIController] Error getting objects for turret ObjectId")
		return nil
	end

	for _, obj in ipairs(objects) do
		if obj.ObjectType and obj.ObjectType:match("^" .. turretType) then
			return obj.ObjectId
		end
	end

	return nil
end


function ShopUIController:PopulateGrid()
	clearCards()
	local state = fetchState()
	local cash = state.Cash or 0
	cashLabel.Text = formatMoney(cash)

	if currentMainTab == "MY BASE" then
		-- Show all owned items in the base
		local objects = BaseOwnershipService:GetMyObjects(player)
		if objects and #objects > 0 then
			-- Group objects by type for cleaner display
			local groupedObjects = {}
			for _, obj in ipairs(objects) do
				local objType = obj.ObjectType
				if objType then
					if not groupedObjects[objType] then
						groupedObjects[objType] = 0
					end
					groupedObjects[objType] += 1
				end
			end

			-- Create cards for each type
			for objType, count in pairs(groupedObjects) do
				-- Extract tier if it's a turret
				local tierStr = objType:match("T(%d+)$")
				local tier = tierStr and tonumber(tierStr) or 1

				-- Determine icon based on type
				local icon = "⚙️"
				local displayName = objType
				if objType:match("^MachineGun") then
					icon = "💀"
					displayName = string.format("Machine Gun T%d", tier)
				elseif objType:match("^Laser") then
					icon = "⚡"
					displayName = string.format("Laser T%d", tier)
				elseif objType:match("^Missile") then
					icon = "💥"
					displayName = string.format("Missile T%d", tier)
				elseif objType:match("^Tesla") then
					icon = "🔮"
					displayName = string.format("Tesla T%d", tier)
				elseif objType:match("Generator") then
					icon = "⚙️"
					displayName = "Generator"
				end

				makeCard({
					id = objType .. "_owned",
					name = displayName,
					price = 0,
					count = count,
					maxCount = nil,
					state = "Owned",
					icon = icon,
					category = "MyBase",
					canAfford = false,
					description = string.format("You own %d of these. Click turrets to upgrade!", count),
					stats = nil,
					itemType = "owned",
				})
			end
		else
			-- No items owned yet - show placeholder
			makeCard({
				id = "empty_base",
				name = "Empty Base",
				price = 0,
				count = 0,
				state = "Locked",
				icon = "???",
				category = "MyBase",
				canAfford = false,
				description = "Build your first structure! Check Income or Turrets tab",
				stats = nil,
				itemType = "placeholder",
			})
		end

	elseif currentMainTab == "INCOME" then
		-- Show generators
		for _, gen in ipairs(GENERATORS) do
			-- Build stats for generator
			local stats = nil
			if gen.income then
				stats = {
					INCOME = {current = gen.income},
				}
			end

			makeCard({
				id = gen.id,
				name = gen.name,
				price = gen.cost,
				count = 0,
				state = cash >= gen.cost and "Available" or "Locked",
				icon = gen.icon,
				category = "Income",
				canAfford = cash >= gen.cost,
				description = gen.description,
				stats = stats,
				itemType = "generator",
				size = gen.size,
			})
		end

	elseif currentMainTab == "TURRETS" then
		-- ONLY SHOW T1 TURRETS (upgrades done via TurretManagementUI)
		local turretList = TURRET_TYPES[currentSubTab]
		if not turretList then return end

		-- Get only T1 (first item in the list)
		local t1Data = turretList[1]
		if t1Data and t1Data.tier == 1 then
			local canAfford = cash >= t1Data.cost

			-- Build stats display
			local stats = nil
			if t1Data.damage and t1Data.fireRate then
				-- Machine Gun
				stats = {
					DMG = {current = t1Data.damage, after = t1Data.damage},
					FR = {current = string.format("%.2fs", t1Data.fireRate), after = string.format("%.2fs", t1Data.fireRate)},
					RNG = {current = t1Data.range, after = t1Data.range},
				}
			elseif t1Data.dps and t1Data.chains then
				-- Tesla (has chains)
				stats = {
					DPS = {current = t1Data.dps, after = t1Data.dps},
					CHAIN = {current = t1Data.chains, after = t1Data.chains},
					RNG = {current = t1Data.range, after = t1Data.range},
				}
			elseif t1Data.dps then
				-- Laser (no chains)
				stats = {
					DPS = {current = t1Data.dps, after = t1Data.dps},
					RNG = {current = t1Data.range, after = t1Data.range},
				}
			elseif t1Data.cooldown and t1Data.damage then
				-- Missile
				stats = {
					DMG = {current = t1Data.damage, after = t1Data.damage},
					CD = {current = string.format("%.1fs", t1Data.cooldown), after = string.format("%.1fs", t1Data.cooldown)},
					RNG = {current = t1Data.range, after = t1Data.range},
				}
			end

			makeCard({
				id = t1Data.id,
				name = string.format("%s T1", currentSubTab),
				price = t1Data.cost,
				count = 0,  -- Never show count for T1
				maxCount = nil,  -- No max limit
				state = canAfford and "Available" or "Locked",
				icon = TURRET_ICONS[currentSubTab] or "💀",
				category = "Turrets",
				canAfford = canAfford,
				description = string.format("%s Tier 1 - Place multiple turrets! Upgrade via turret menu", currentSubTab),
				stats = stats,
				itemType = canAfford and "place" or "locked",
				turretType = currentSubTab,
				objectId = nil,
				size = Vector3.new(7, 9, 7),
			})
		end

		-- NOTE: Defense tab removed from MAIN_TABS, keeping code commented for future use
		-- elseif currentMainTab == "DEFENSE" then
		-- Shield Dome placeholder
		-- makeCard({
		-- 	id = "ShieldDome",
		-- 	name = "Shield Dome",
		-- 	price = 2500000,
		-- 	count = 0,
		-- 	state = "Locked",
		-- 	icon = "???",
		-- 	category = "Defense",
		-- 	canAfford = false,
		-- 	description = "Coming soon: Emergency protection dome",
		-- 	stats = nil,
		-- 	itemType = "placeholder",
		-- })

	elseif currentMainTab == "PETS" then
		-- Pets placeholder
		makeCard({
			id = "PetSystem",
			name = "Pet System",
			price = 0,
			count = 0,
			state = "Locked",
			icon = "⚙️",
			category = "Pets",
			canAfford = false,
			description = "Coming soon: Gachapon pet system with buffs",
			stats = nil,
			itemType = "placeholder",
		})

	elseif currentMainTab == "POWERUPS" then
		-- PowerUps placeholder
		makeCard({
			id = "PowerUps",
			name = "Power-Ups",
			price = 0,
			count = 0,
			state = "Locked",
			icon = "?",
			category = "PowerUps",
			canAfford = false,
			description = "Coming soon: Improved vending machine system",
			stats = nil,
			itemType = "placeholder",
		})
	end
end

--[[------------------------------------------------------------------------
	PUBLIC API
------------------------------------------------------------------------]]

function ShopUIController:ToggleMenu()
	isMenuOpen = not isMenuOpen

	if isMenuOpen then
		-- ═══ ABRIR MENU ═══
		screenGui.Enabled = true
		shadow.Visible = true
		mainFrame.Visible = true

		-- 🎬 Animación de apertura + sonido
		playOpenAnimation(mainFrame)

		-- Update UI
		self:PopulateGrid()

		-- 🔄 Ambient audio
		if ambientSound and ambientSound.SoundId ~= "158853971" then
			ambientSound:Play()
		end

		-- ☢️ REINICIAR efectos
		slimeDripActive = true
		particlesActive = true
		if slimeDripStartFunc then slimeDripStartFunc() end
		if particleStartFunc then particleStartFunc() end

	else
		-- ═══ CERRAR MENU ═══

		-- 🎬 Animación de cierre
		local closeTween = playCloseAnimation(mainFrame)

		-- Esperar a que termine animación
		closeTween.Completed:Connect(function()
			screenGui.Enabled = false
			shadow.Visible = false
			mainFrame.Visible = false
		end)

		-- 🔇 Ambient audio stop
		if ambientSound then
			ambientSound:Stop()
		end

		-- ☢️ Desactivar efectos
		slimeDripActive = false
		particlesActive = false
	end
end

function ShopUIController:SetVisible(visible: boolean)
	isMenuOpen = visible

	if visible then
		-- ═══ ABRIR MENU ═══
		screenGui.Enabled = true
		shadow.Visible = true
		mainFrame.Visible = true

		-- 🎬 Animación de apertura + sonido
		playOpenAnimation(mainFrame)

		-- Update UI
		self:PopulateGrid()

		-- 🔄 Ambient audio
		if ambientSound and ambientSound.SoundId ~= "158853971" then
			ambientSound:Play()
		end

		-- ☢️ REINICIAR efectos
		slimeDripActive = true
		particlesActive = true
		if slimeDripStartFunc then slimeDripStartFunc() end
		if particleStartFunc then particleStartFunc() end

	else
		-- ═══ CERRAR MENU ═══

		-- 🎬 Animación de cierre
		local closeTween = playCloseAnimation(mainFrame)

		-- Esperar a que termine animación
		closeTween.Completed:Connect(function()
			screenGui.Enabled = false
			shadow.Visible = false
			mainFrame.Visible = false
		end)

		-- 🔇 Ambient audio stop
		if ambientSound then
			ambientSound:Stop()
		end

		-- ☢️ Desactivar efectos
		slimeDripActive = false
		particlesActive = false
	end
end

--[[------------------------------------------------------------------------
	KNIT LIFECYCLE
------------------------------------------------------------------------]]

function ShopUIController:KnitInit()
	print("[ShopUIController] Initializing...")
end

function ShopUIController:KnitStart()
	print("[ShopUIController] Starting...")

	-- Get services and controllers
	BasePlacementController = Knit.GetController("BasePlacementController")
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	-- Get RemoteEvents
	UpgradeTurretRemote = Remotes:WaitForChild("UpgradeTurret") :: RemoteEvent

	-- Create UI
	screenGui = createMainUI()
	createStructure()

	-- Create tabs
	for _, tabData in ipairs(MAIN_TABS) do
		createMainTab(tabData)
	end
	for _, subData in ipairs(TURRET_SUBTABS) do
		createSubTab(subData)
	end

	updateTabStates()

	-- ☢️ SETUP VISUAL EFFECTS & AUDIO
	print("🎨 Setting up visual effects...")

	-- 1. Toxic slime drip
	slimeDripContainer = createSlimeDrip(mainFrame)
	print("✓ Toxic slime drip created")

	-- 2. Radioactive particles
	particleContainer = createRadioactiveParticles(mainFrame)
	print("✓ Radioactive particles created")

	-- 3. Click sound
	clickSound = createClickSound(mainFrame)
	print("✓ Click sound created")

	-- 4. Menu open sound
	menuOpenSound = createMenuOpenSound(mainFrame)
	print("✓ Menu open sound created")

	-- 5. Add click sounds to all buttons
	for _, btn in pairs(mainTabButtons) do
		addClickSoundToButton(btn)
	end
	for _, btn in pairs(subTabButtons) do
		addClickSoundToButton(btn)
	end
	addClickSoundToButton(buyButton)
	addClickSoundToButton(closeButton)
	print("✓ Click sounds added to all buttons")

	print("🔥 Visual effects initialized!")

	-- Close button
	closeButton.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	-- Buy button
	buyButton.MouseButton1Click:Connect(function()
		if not selectedItem or not selectedItem.canAfford then
			return
		end

		local itemType = selectedItem.itemType

		if itemType == "generator" then
			-- Place generator
			print("[ShopUIController] Placing generator")
			self:SetVisible(false)
			BasePlacementController:StartPlacement(selectedItem.id, selectedItem.size)

		elseif itemType == "place" then
			-- Place T1 turret
			print("[ShopUIController] Placing turret:", selectedItem.id)
			self:SetVisible(false)
			BasePlacementController:StartPlacement(selectedItem.id, selectedItem.size)

		elseif itemType == "upgrade" then
			-- Upgrade turret T2-T5
			if not selectedItem.objectId then
				warn("[ShopUIController] No ObjectId found for upgrade")
				return
			end
			print("[ShopUIController] Upgrading turret:", selectedItem.id, "ObjectId:", selectedItem.objectId)
			UpgradeTurretRemote:FireServer(selectedItem.objectId)
			-- Refresh after upgrade
			task.wait(0.5)
			self:PopulateGrid()

		elseif itemType == "owned" or itemType == "placeholder" or itemType == "locked" then
			-- Do nothing
			print("[ShopUIController] Item not purchasable:", itemType)
		end
	end)

	-- Keyboard toggle (Q key)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Q then
			self:ToggleMenu()
			-- ToggleMenu() already refreshes when opening, no need to refresh again here
		end
	end)

	-- Initial load
	self:PopulateGrid()

	-- Parent to PlayerGui
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Start visible
	self:SetVisible(true)

	print("[ShopUIController] ? Ready (Press Q to toggle)")
end

return ShopUIController