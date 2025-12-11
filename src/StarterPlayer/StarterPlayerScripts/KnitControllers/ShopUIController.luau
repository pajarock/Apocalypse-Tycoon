--!strict
--[[
	ShopUIController - Build Menu v2.0 (Knit)
	═══════════════════════════════════════════════════════════════════════

	Sistema completo de Shop/Build Menu con arquitectura moderna.

	CARACTERÍSTICAS:
	- 5 tabs principales: Income, Defense, Turrets, Utility, Eggs
	- 4 sub-tabs para Turrets: MG, Laser, Missile, Tesla
	- Grid adaptivo 3x4 con cards de 150x180px
	- Preview panel con stats comparison
	- Estados visuales: Available, Owned, Locked, Max
	- Auto-refresh cada 2 segundos
	- Keyboard toggle: B key

	ARQUITECTURA:
	┌─────────────────────────────────────────────────┐
	│ Header (Title + Cash + Close)                   │
	├─────────────────────────────────────────────────┤
	│ Main Tabs: Income|Defense|Turrets|Utility|Eggs  │
	│ Sub-tabs (if Turrets): MG|Laser|Missile|Tesla   │
	├─────────────────────────────────────────────────┤
	│ Grid (60%)              │  Preview Panel (40%)  │
	│ 3x4 cards (adaptive)    │  ViewportFrame 3D     │
	│ Scroll 16px thick       │  Current vs After     │
	│                         │  Stats (4 max)        │
	│                         │  Buy button           │
	└─────────────────────────────────────────────────┘
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

--[[────────────────────────────────────────────────────────────────────────
	TYPES & CONSTANTS
────────────────────────────────────────────────────────────────────────]]

type CardState = "Available" | "Owned" | "Locked" | "Max"

-- UI Constants
local MENU_SIZE = Vector2.new(800, 600)
local GRID_WIDTH_PERCENT = 0.6
local CARD_SIZE = Vector2.new(150, 180)
local CARD_PADDING = 8
local SCROLL_BAR_THICKNESS = 8  -- Más delgado, apocalíptico

-- Color scheme - APOCALYPTIC FINAL PALETTE 🔥💀
-- ONLY 4 COLORS + GRAYS for maximum cohesion
local COLORS = {
	-- BASE (Grays)
	Background = Color3.fromRGB(15, 15, 15),        -- #0F0F0F Negro carbón PRINCIPAL
	BackgroundLight = Color3.fromRGB(26, 26, 26),   -- #1A1A1A
	BackgroundMid = Color3.fromRGB(42, 42, 42),     -- #2A2A2A
	BackgroundCard = Color3.fromRGB(24, 37, 22),    -- #182516 Verde oscuro para generator cards

	-- APOCALYPSE PALETTE (ONLY THESE 4!)
	LavaRed = Color3.fromRGB(255, 36, 0),           -- #FF2400 Crítico/Peligro/Activo
	ToxicGreen = Color3.fromRGB(57, 255, 20),       -- #39FF14 Energía/Disponible
	FireYellow = Color3.fromRGB(255, 165, 0),       -- #FFA500 UI/Warnings

	-- NEUTRALS
	White = Color3.fromRGB(255, 255, 255),          -- #FFFFFF
	LightGray = Color3.fromRGB(204, 204, 204),      -- #CCCCCC
	MidGray = Color3.fromRGB(187, 187, 187),        -- #BBBBBB
	DarkGray = Color3.fromRGB(51, 51, 51),          -- #333333
	DarkerGray = Color3.fromRGB(119, 119, 119),     -- #777777
	Shadow = Color3.fromRGB(0, 0, 0),               -- #000000

	-- ALIASES (for compatibility)
	Header = Color3.fromRGB(255, 36, 0),            -- Rojo lava
	BorderBright = Color3.fromRGB(255, 36, 0),      -- Rojo lava
	TabActive = Color3.fromRGB(255, 36, 0),         -- Rojo lava
	TabInactive = Color3.fromRGB(26, 26, 26),       -- #1A1A1A
	Available = Color3.fromRGB(57, 255, 20),        -- Verde tóxico
	AvailableDark = Color3.fromRGB(24, 37, 22),     -- #182516 Verde oscuro
	Owned = Color3.fromRGB(255, 165, 0),            -- Amarillo fuego (no más naranja!)
	OwnedDark = Color3.fromRGB(42, 42, 42),         -- Gris oscuro
	Locked = Color3.fromRGB(51, 51, 51),            -- #333333 Gris
	LockedDark = Color3.fromRGB(26, 26, 26),        -- #1A1A1A
	MaxTier = Color3.fromRGB(255, 36, 0),           -- Rojo lava (mítico)
	Gold = Color3.fromRGB(255, 165, 0),             -- Amarillo fuego (precio)
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
	{name = "Missile", emoji = "💥", displayName = "MISSILE"},
	{name = "Tesla", emoji = "🔮", displayName = "TESLA"},
}

-- Generator definitions (Income) - 5 TIERS!
local GENERATORS = {
	{
		id = "GeneratorT1",
		name = "Generator T1",
		icon = "⚙️",
		tier = 1,
		cost = 100,
		size = Vector3.new(6, 5, 6),
		description = "Basic money generator. Place many to increase income!",
		income = "$10/sec",
	},
	{
		id = "GeneratorT2",
		name = "Generator T2",
		icon = "⚙️",
		tier = 2,
		cost = 500,
		size = Vector3.new(7, 6, 7),
		description = "Improved generator with better output!",
		income = "$50/sec",
	},
	{
		id = "GeneratorT3",
		name = "Generator T3",
		icon = "⚙️",
		tier = 3,
		cost = 2500,
		size = Vector3.new(8, 7, 8),
		description = "Advanced generator for serious income!",
		income = "$250/sec",
	},
	{
		id = "GeneratorT4",
		name = "Generator T4",
		icon = "⚙️",
		tier = 4,
		cost = 12500,
		size = Vector3.new(9, 8, 9),
		description = "High-tech generator with massive output!",
		income = "$1,250/sec",
	},
	{
		id = "GeneratorT5",
		name = "Generator T5",
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

--[[────────────────────────────────────────────────────────────────────────
	CONTROLLER DEFINITION
────────────────────────────────────────────────────────────────────────]]

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

--[[────────────────────────────────────────────────────────────────────────
	UTILITY FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

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

--[[────────────────────────────────────────────────────────────────────────
	UI CREATION
────────────────────────────────────────────────────────────────────────]]

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
	createUICorner(mainFrame, 16)  -- 🔥 Más redondeado, más premium
	createUIStroke(mainFrame, COLORS.Header, 3)  -- Stroke rojo lava

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = COLORS.BackgroundLight
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	createUICorner(header, 12)

	-- Padding para que no esté pegado
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
	title.Font = Enum.Font.Bangers  -- 🔥 APOCALYPTIC GRAFFITI STYLE!
	title.TextSize = 28  -- Bigger, bolder!
	title.TextColor3 = COLORS.Header  -- Rojo lava
	title.Text = "🏗️ BUILD MENU V2.0"
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
	gridContainer.ScrollBarImageColor3 = COLORS.LavaRed  -- 🔥 Rojo lava!
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
	previewPlaceholder.Size = UDim2.fromScale(1, 0.3)
	previewPlaceholder.Position = UDim2.fromScale(0, 0.35)
	previewPlaceholder.BackgroundTransparency = 1
	previewPlaceholder.Font = Enum.Font.Gotham
	previewPlaceholder.TextSize = 16
	previewPlaceholder.TextColor3 = Color3.fromRGB(120, 120, 120)
	previewPlaceholder.Text = "Select an item to preview..."
	previewPlaceholder.TextWrapped = true
	previewPlaceholder.TextYAlignment = Enum.TextYAlignment.Top
	previewPlaceholder.Parent = previewPanel

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
	statsTitle.Text = "📊 ITEM INFO"
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
	buyButton.BackgroundColor3 = COLORS.ToxicGreen  -- Verde tóxico por default
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 22
	buyButton.TextColor3 = COLORS.Background  -- Negro carbón #0F0F0F
	buyButton.Text = "BUY"
	buyButton.AutoButtonColor = true
	buyButton.Visible = false
	buyButton.Parent = previewPanel
	createUICorner(buyButton, 10)

	-- Add a THICK stroke to the buy button - Borde amarillo fuego o negro según estado
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

	-- 🔥 AMBIENT AUDIO - Brasas/Carbón encendido
	-- TODO: Add SoundId when asset is ready
	ambientSound = Instance.new("Sound")
	ambientSound.Name = "AmbientForge"
	ambientSound.SoundId = ""  -- TODO: rbxassetid://XXXXXXXXX (brasas/carbon loop)
	ambientSound.Volume = 0.08  -- 8% volumen (5-12% range)
	ambientSound.Looped = true
	ambientSound.PlaybackSpeed = 1
	ambientSound.Parent = mainFrame
	-- Note: Will play when menu opens, stop when closes
end

--[[────────────────────────────────────────────────────────────────────────
	TAB SYSTEM
────────────────────────────────────────────────────────────────────────]]

local function updateTabStates()
	for tabName, tabButton in pairs(mainTabButtons) do
		if tabName == currentMainTab then
			-- ACTIVO: Rojo lava con texto negro carbón
			tabButton.BackgroundColor3 = COLORS.LavaRed
			tabButton.BackgroundTransparency = 0
			tabButton.TextColor3 = COLORS.Background  -- Negro carbón #0F0F0F
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
				-- ACTIVO: Rojo lava con texto negro carbón
				subButton.BackgroundColor3 = COLORS.LavaRed
				subButton.BackgroundTransparency = 0
				subButton.TextColor3 = COLORS.Background  -- Negro carbón
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
	btn.Font = Enum.Font.Bangers  -- 🔥 Apocalyptic font!
	btn.TextSize = 17  -- Slightly bigger for Bangers
	btn.TextColor3 = COLORS.LightGray  -- #CCCCCC
	btn.Text = tabData.emoji .. " " .. tabData.name
	btn.AutoButtonColor = false
	btn.Parent = mainTabsRow

	createUICorner(btn, 8)
	local stroke = createUIStroke(btn, COLORS.LavaRed, 2)  -- 🔥 Rojo lava border
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
	btn.Font = Enum.Font.Bangers  -- 🔥 Apocalyptic font!
	btn.TextSize = 15  -- Slightly bigger for Bangers
	btn.TextColor3 = COLORS.LightGray  -- #CCCCCC
	btn.Text = subData.emoji .. " " .. subData.displayName
	btn.AutoButtonColor = false
	btn.Parent = subTabsRow

	createUICorner(btn, 6)
	local stroke = createUIStroke(btn, COLORS.LavaRed, 1)  -- 🔥 Rojo lava border
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

--[[────────────────────────────────────────────────────────────────────────
	CARD SYSTEM
────────────────────────────────────────────────────────────────────────]]

local function getCardStateVisuals(state: CardState, canAfford: boolean)
	if state == "Max" then
		-- MAX TIER: Rojo lava (mítico apocalíptico)
		return {
			backgroundColor = Color3.fromRGB(60, 20, 10),  -- Rojo oscuro
			badgeText = "⭐",
			badgeColor = COLORS.LavaRed,
			strokeColor = COLORS.LavaRed,
			glowColor = COLORS.LavaRed
		}
	elseif state == "Owned" then
		-- OWNED: Amarillo fuego (no más naranja!)
		return {
			backgroundColor = COLORS.OwnedDark,  -- #2A2A2A gris oscuro
			badgeText = "✅",
			badgeColor = COLORS.FireYellow,
			strokeColor = COLORS.FireYellow,
			glowColor = COLORS.FireYellow
		}
	elseif state == "Locked" then
		-- LOCKED: Gris
		return {
			backgroundColor = COLORS.LockedDark,  -- #1A1A1A
			badgeText = "🔒",
			badgeColor = COLORS.DarkGray,  -- #333333
			strokeColor = COLORS.DarkGray,
			glowColor = COLORS.DarkGray
		}
	else
		-- AVAILABLE: Verde tóxico radioactivo!
		return {
			backgroundColor = canAfford and COLORS.AvailableDark or COLORS.LockedDark,  -- #182516 o #1A1A1A
			badgeText = "💎",
			badgeColor = canAfford and COLORS.ToxicGreen or COLORS.DarkGray,
			strokeColor = canAfford and COLORS.ToxicGreen or COLORS.DarkGray,  -- 🔥 Verde tóxico!
			glowColor = canAfford and COLORS.ToxicGreen or COLORS.DarkGray
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

	-- Shadow frame - 🔥 AAA look!
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
	local card = Instance.new("Frame")
	card.Name = "Card_" .. itemData.id
	card.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	card.Position = UDim2.fromOffset(0, 0)
	card.BorderSizePixel = 0
	card.ZIndex = 2
	card.Parent = container

	local visuals = getCardStateVisuals(itemData.state, itemData.canAfford)
	card.BackgroundColor3 = visuals.backgroundColor

	createUICorner(card, 10)  -- 🔥 Más redondeado para look premium
	local stroke = createUIStroke(card, visuals.strokeColor, 3)  -- 3px para más presencia
	stroke.Transparency = 0

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
	nameLabel.Font = Enum.Font.Bangers  -- 🔥 Apocalyptic font!
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
		selectedItem = itemData
		ShopUIController:UpdatePreviewPanel(itemData)
	end)

	clickButton.MouseEnter:Connect(function()
		stroke.Thickness = 3
	end)

	clickButton.MouseLeave:Connect(function()
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
end

--[[────────────────────────────────────────────────────────────────────────
	PREVIEW PANEL
────────────────────────────────────────────────────────────────────────]]

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

	-- Value (right side) - VERDE TÓXICO!
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.55, 0, 1, 0)
	valueLabel.Position = UDim2.fromScale(0.45, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 14
	valueLabel.TextColor3 = COLORS.ToxicGreen  -- #39FF14 Verde tóxico radioactivo!
	valueLabel.Text = value
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = row
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

	-- Create stats - simplified, no comparison
	if itemData.stats then
		local order = 1
		for statName, statValues in pairs(itemData.stats) do
			if order <= 5 then  -- Show up to 5 stats
				-- Just show the value, no "current" vs "after"
				local value = tostring(statValues.current or statValues.after or "0")
				createStatRow(statName, value, order)
				order += 1
			end
		end
	end

	-- Update button based on item type - APOCALYPTIC COLORS!
	buyButton.Visible = true
	local itemType = itemData.itemType
	local btnStroke = buyButton:FindFirstChildOfClass("UIStroke")

	if itemType == "placeholder" then
		buyButton.Text = "⏳ COMING SOON"
		buyButton.BackgroundColor3 = COLORS.DarkGray  -- #333333
		buyButton.TextColor3 = COLORS.DarkerGray  -- #777777
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.Shadow end
	elseif itemType == "owned" then
		buyButton.Text = "✅ OWNED"
		buyButton.BackgroundColor3 = COLORS.FireYellow
		buyButton.TextColor3 = COLORS.Background
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.FireYellow end
	elseif itemType == "locked" or itemData.state == "Locked" then
		buyButton.Text = "🔒 LOCKED"
		buyButton.BackgroundColor3 = COLORS.DarkGray  -- #333333
		buyButton.TextColor3 = COLORS.DarkerGray  -- #777777
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.Shadow end
	elseif itemType == "generator" or itemType == "place" then
		-- PLACE: Verde tóxico con texto negro, borde amarillo
		buyButton.Text = itemType == "generator"
			and string.format("PLACE FOR %s", formatMoney(itemData.price))
			or string.format("PLACE T1 FOR %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = COLORS.ToxicGreen  -- #39FF14
		buyButton.TextColor3 = COLORS.Background  -- #0F0F0F Negro carbón
		buyButton.AutoButtonColor = true
		if btnStroke then btnStroke.Color = COLORS.FireYellow end  -- Borde amarillo fuego
	elseif itemType == "upgrade" then
		-- UPGRADE: Amarillo fuego con texto negro, borde amarillo
		buyButton.Text = string.format("UPGRADE FOR %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = COLORS.FireYellow  -- #FFA500
		buyButton.TextColor3 = COLORS.Background  -- #0F0F0F Negro carbón
		buyButton.AutoButtonColor = true
		if btnStroke then btnStroke.Color = COLORS.FireYellow end
	else
		buyButton.Text = "🚫 " .. formatMoney(itemData.price)
		buyButton.BackgroundColor3 = COLORS.DarkGray
		buyButton.TextColor3 = COLORS.DarkerGray
		buyButton.AutoButtonColor = false
		if btnStroke then btnStroke.Color = COLORS.Shadow end
	end

	descriptionLabel.Visible = true
	descriptionLabel.Text = itemData.description or "No description"
end

--[[────────────────────────────────────────────────────────────────────────
	DATA LOADING
────────────────────────────────────────────────────────────────────────]]

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
	local objects = BaseOwnershipService:GetMyObjects(player)
	if not objects then return nil end

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
				local icon = "📦"
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
				icon = "🏗️",
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
		-- 	icon = "🛡️",
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
			icon = "🐾",
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
			icon = "⚡",
			category = "PowerUps",
			canAfford = false,
			description = "Coming soon: Improved vending machine system",
			stats = nil,
			itemType = "placeholder",
		})
	end
end

--[[────────────────────────────────────────────────────────────────────────
	PUBLIC API
────────────────────────────────────────────────────────────────────────]]

function ShopUIController:ToggleMenu()
	isMenuOpen = not isMenuOpen
	mainFrame.Visible = isMenuOpen
	shadow.Visible = isMenuOpen

	-- 🔥 Ambient audio control
	if ambientSound then
		if isMenuOpen and ambientSound.SoundId ~= "" then
			ambientSound:Play()
		else
			ambientSound:Stop()
		end
	end

	-- Refresh data when opening menu
	if isMenuOpen then
		self:PopulateGrid()
	end
end

function ShopUIController:SetVisible(visible: boolean)
	isMenuOpen = visible
	mainFrame.Visible = visible
	shadow.Visible = visible

	-- 🔥 Ambient audio control
	if ambientSound then
		if visible and ambientSound.SoundId ~= "" then
			ambientSound:Play()
		else
			ambientSound:Stop()
		end
	end

	-- Refresh data when opening menu
	if visible then
		self:PopulateGrid()
	end
end

--[[────────────────────────────────────────────────────────────────────────
	KNIT LIFECYCLE
────────────────────────────────────────────────────────────────────────]]

function ShopUIController:KnitInit()
	print("[ShopUIController] Initializing...")
end

function ShopUIController:KnitStart()
	print("[ShopUIController] Starting...")

	-- Get services and controllers
	BasePlacementController = Knit.GetController("BasePlacementController")
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	-- Get RemoteEvents
	UpgradeTurretRemote = Remotes:WaitForChild("UpgradeTurret")

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

	print("[ShopUIController] ✅ Ready (Press Q to toggle)")
end

return ShopUIController
