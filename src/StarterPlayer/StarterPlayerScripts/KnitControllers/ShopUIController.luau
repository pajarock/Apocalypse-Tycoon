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
local SCROLL_BAR_THICKNESS = 16

-- Color scheme
local COLORS = {
	Background = Color3.fromRGB(15, 15, 20),
	Header = Color3.fromRGB(100, 150, 255),
	Shadow = Color3.fromRGB(0, 0, 0),
	TabActive = Color3.fromRGB(60, 100, 180),
	TabInactive = Color3.fromRGB(30, 30, 35),
	Available = Color3.fromRGB(0, 255, 100),
	Owned = Color3.fromRGB(0, 180, 80),
	Locked = Color3.fromRGB(100, 100, 110),
	MaxTier = Color3.fromRGB(255, 215, 0),
}

-- Tab definitions
local MAIN_TABS = {
	{name = "Income", emoji = "💰", color = Color3.fromRGB(255, 215, 0)},
	{name = "Turrets", emoji = "🔫", color = Color3.fromRGB(255, 100, 100)},
	{name = "Defense", emoji = "🛡️", color = Color3.fromRGB(100, 150, 255)},
	{name = "Pets", emoji = "🐾", color = Color3.fromRGB(255, 150, 200)},
	{name = "PowerUps", emoji = "⚡", color = Color3.fromRGB(255, 255, 100)},
}

local TURRET_SUBTABS = {
	{name = "MachineGun", emoji = "🔫", displayName = "MG"},
	{name = "Laser", emoji = "⚡", displayName = "Laser"},
	{name = "Missile", emoji = "🚀", displayName = "Missile"},
	{name = "Tesla", emoji = "⚡", displayName = "Tesla"},
}

-- Generator definitions (Income)
local GENERATORS = {
	{
		id = "Generator",
		name = "Generator",
		icon = "⚙️",
		cost = 100,
		size = Vector3.new(8, 6, 8),
		description = "Produces money passively over time",
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
	MachineGun = "🔫", Laser = "⚡",
	Missile = "🚀", Tesla = "⚡",
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

local currentMainTab = "Income"
local currentSubTab = "MachineGun"
local selectedItem: any? = nil
local isMenuOpen = false

-- Services & Controllers (obtained in KnitStart)
local BasePlacementController
local BaseOwnershipService
local UpgradeTurretRemote: RemoteEvent

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
	createUICorner(mainFrame, 12)
	createUIStroke(mainFrame, COLORS.Header, 3)

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	createUICorner(header, 12)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.5, -60, 1, 0)
	title.Position = UDim2.fromOffset(20, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextColor3 = COLORS.Header
	title.Text = "🏗️ BUILD MENU v2.0"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	cashLabel = Instance.new("TextLabel")
	cashLabel.Name = "Cash"
	cashLabel.Size = UDim2.new(0.4, 0, 1, 0)
	cashLabel.Position = UDim2.new(0.3, 0, 0, 0)
	cashLabel.BackgroundTransparency = 1
	cashLabel.Font = Enum.Font.GothamBold
	cashLabel.TextSize = 20
	cashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
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
	closeButton.TextSize = 24
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Text = "✕"
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
	gridContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	gridContainer.BackgroundTransparency = 0.5
	gridContainer.BorderSizePixel = 0
	gridContainer.ScrollBarThickness = SCROLL_BAR_THICKNESS
	gridContainer.ScrollBarImageColor3 = COLORS.Header
	gridContainer.CanvasSize = UDim2.fromScale(1, 0)
	gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
	previewPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	previewPanel.BackgroundTransparency = 0.5
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

	-- Stats container
	statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(1, -20, 0, 120)
	statsContainer.Position = UDim2.fromOffset(10, 220)
	statsContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	statsContainer.BackgroundTransparency = 0.5
	statsContainer.BorderSizePixel = 0
	statsContainer.Visible = false
	statsContainer.Parent = previewPanel
	createUICorner(statsContainer, 8)

	local statsTitle = Instance.new("TextLabel")
	statsTitle.Size = UDim2.new(1, -16, 0, 20)
	statsTitle.Position = UDim2.fromOffset(8, 5)
	statsTitle.BackgroundTransparency = 1
	statsTitle.Font = Enum.Font.GothamBold
	statsTitle.TextSize = 14
	statsTitle.TextColor3 = COLORS.Header
	statsTitle.Text = "STATS COMPARISON"
	statsTitle.TextXAlignment = Enum.TextXAlignment.Center
	statsTitle.Parent = statsContainer

	statsGrid = Instance.new("Frame")
	statsGrid.Name = "StatsGrid"
	statsGrid.Size = UDim2.new(1, -16, 1, -30)
	statsGrid.Position = UDim2.fromOffset(8, 28)
	statsGrid.BackgroundTransparency = 1
	statsGrid.Parent = statsContainer

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.Padding = UDim.new(0, 3)
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Parent = statsGrid

	-- Buy button
	buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(1, -20, 0, 50)
	buyButton.Position = UDim2.fromOffset(10, 350)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 20
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.Text = "BUY"
	buyButton.AutoButtonColor = true
	buyButton.Visible = false
	buyButton.Parent = previewPanel
	createUICorner(buyButton, 8)

	-- Description
	descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Name = "Description"
	descriptionLabel.Size = UDim2.new(1, -20, 0, 30)
	descriptionLabel.Position = UDim2.fromOffset(10, 410)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.TextSize = 11
	descriptionLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descriptionLabel.Text = ""
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.Visible = false
	descriptionLabel.Parent = previewPanel
end

--[[────────────────────────────────────────────────────────────────────────
	TAB SYSTEM
────────────────────────────────────────────────────────────────────────]]

local function updateTabStates()
	for tabName, tabButton in pairs(mainTabButtons) do
		if tabName == currentMainTab then
			tabButton.BackgroundColor3 = COLORS.TabActive
			tabButton.BackgroundTransparency = 0
			tabButton.TextColor3 = Color3.new(1, 1, 1)
			tabButton.TextSize = 18
		else
			tabButton.BackgroundColor3 = COLORS.TabInactive
			tabButton.BackgroundTransparency = 0.3
			tabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
			tabButton.TextSize = 16
		end
	end

	if currentMainTab == "Turrets" then
		subTabsRow.Visible = true
		for subName, subButton in pairs(subTabButtons) do
			if subName == currentSubTab then
				subButton.BackgroundColor3 = COLORS.TabActive
				subButton.BackgroundTransparency = 0
				subButton.TextColor3 = Color3.new(1, 1, 1)
			else
				subButton.BackgroundColor3 = COLORS.TabInactive
				subButton.BackgroundTransparency = 0.3
				subButton.TextColor3 = Color3.fromRGB(180, 180, 180)
			end
		end
	else
		subTabsRow.Visible = false
	end

	ShopUIController:PopulateGrid()
end

local function createMainTab(tabData: {name: string, emoji: string, color: Color3})
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. tabData.name
	btn.Size = UDim2.fromOffset(130, 40)
	btn.BackgroundColor3 = COLORS.TabInactive
	btn.BackgroundTransparency = 0.3
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	btn.Text = tabData.emoji .. " " .. tabData.name
	btn.AutoButtonColor = false
	btn.Parent = mainTabsRow

	createUICorner(btn, 8)
	local stroke = createUIStroke(btn, tabData.color, 2)
	stroke.Transparency = 0.3

	btn.MouseButton1Click:Connect(function()
		currentMainTab = tabData.name
		updateTabStates()
	end)

	btn.MouseEnter:Connect(function()
		if currentMainTab ~= tabData.name then
			btn.BackgroundTransparency = 0.1
		end
	end)

	btn.MouseLeave:Connect(function()
		if currentMainTab ~= tabData.name then
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
	btn.BackgroundTransparency = 0.3
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	btn.Text = subData.emoji .. " " .. subData.displayName
	btn.AutoButtonColor = false
	btn.Parent = subTabsRow

	createUICorner(btn, 6)
	local stroke = createUIStroke(btn, COLORS.Header, 1)
	stroke.Transparency = 0.5

	btn.MouseButton1Click:Connect(function()
		currentSubTab = subData.name
		updateTabStates()
	end)

	btn.MouseEnter:Connect(function()
		if currentSubTab ~= subData.name then
			btn.BackgroundTransparency = 0.1
		end
	end)

	btn.MouseLeave:Connect(function()
		if currentSubTab ~= subData.name then
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
		return {
			backgroundColor = Color3.fromRGB(50, 45, 30),
			badgeText = "⭐",
			badgeColor = COLORS.MaxTier,
			strokeColor = COLORS.MaxTier
		}
	elseif state == "Owned" then
		return {
			backgroundColor = Color3.fromRGB(20, 40, 30),
			badgeText = "✅",
			badgeColor = COLORS.Owned,
			strokeColor = COLORS.Owned
		}
	elseif state == "Locked" then
		return {
			backgroundColor = Color3.fromRGB(25, 25, 28),
			badgeText = "🔒",
			badgeColor = COLORS.Locked,
			strokeColor = COLORS.Locked
		}
	else
		return {
			backgroundColor = canAfford and Color3.fromRGB(20, 35, 25) or Color3.fromRGB(35, 20, 20),
			badgeText = "💎",
			badgeColor = canAfford and COLORS.Available or Color3.fromRGB(255, 100, 100),
			strokeColor = canAfford and COLORS.Available or Color3.fromRGB(255, 50, 50)
		}
	end
end

local function makeCard(itemData: any): Frame
	local card = Instance.new("Frame")
	card.Name = "Card_" .. itemData.id
	card.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	card.BorderSizePixel = 0

	local visuals = getCardStateVisuals(itemData.state, itemData.canAfford)
	card.BackgroundColor3 = visuals.backgroundColor

	createUICorner(card, 8)
	local stroke = createUIStroke(card, visuals.strokeColor, 2)
	stroke.Transparency = 0.2

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

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, -16, 0, 60)
	iconLabel.Position = UDim2.fromOffset(8, 40)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 48
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Text = itemData.icon
	iconLabel.ZIndex = 2
	iconLabel.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -16, 0, 24)
	nameLabel.Position = UDim2.fromOffset(8, 105)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = itemData.name
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.ZIndex = 2
	nameLabel.Parent = card

	-- Price
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, -16, 0, 20)
	priceLabel.Position = UDim2.fromOffset(8, 132)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.Gotham
	priceLabel.TextSize = 14
	priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
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

	card.Parent = gridContainer
	cardInstances[itemData.id] = card
	return card
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

local function createStatRow(statName: string, currentValue: string, afterValue: string, order: number)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 18)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = statsGrid

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 11
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.Text = statName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local currentLabel = Instance.new("TextLabel")
	currentLabel.Size = UDim2.new(0.35, 0, 1, 0)
	currentLabel.Position = UDim2.fromScale(0.3, 0)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.Gotham
	currentLabel.TextSize = 11
	currentLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	currentLabel.Text = currentValue
	currentLabel.TextXAlignment = Enum.TextXAlignment.Center
	currentLabel.Parent = row

	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Size = UDim2.fromOffset(20, 18)
	arrowLabel.Position = UDim2.fromScale(0.65, 0)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.Font = Enum.Font.GothamBold
	arrowLabel.TextSize = 12
	arrowLabel.TextColor3 = COLORS.Header
	arrowLabel.Text = "→"
	arrowLabel.Parent = row

	local afterLabel = Instance.new("TextLabel")
	afterLabel.Size = UDim2.new(0.3, 0, 1, 0)
	afterLabel.Position = UDim2.fromScale(0.7, 0)
	afterLabel.BackgroundTransparency = 1
	afterLabel.Font = Enum.Font.GothamBold
	afterLabel.TextSize = 11
	afterLabel.TextColor3 = COLORS.Available
	afterLabel.Text = afterValue
	afterLabel.TextXAlignment = Enum.TextXAlignment.Center
	afterLabel.Parent = row
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

	-- Create stats
	if itemData.stats then
		local order = 1
		for statName, statValues in pairs(itemData.stats) do
			if order <= 4 then
				createStatRow(
					statName,
					tostring(statValues.current or "0"),
					tostring(statValues.after or "0"),
					order
				)
				order += 1
			end
		end
	end

	-- Update button based on item type
	buyButton.Visible = true
	local itemType = itemData.itemType

	if itemType == "placeholder" then
		buyButton.Text = "COMING SOON"
		buyButton.BackgroundColor3 = COLORS.Locked
		buyButton.AutoButtonColor = false
	elseif itemType == "owned" then
		buyButton.Text = "✅ OWNED"
		buyButton.BackgroundColor3 = COLORS.Owned
		buyButton.AutoButtonColor = false
	elseif itemType == "locked" or itemData.state == "Locked" then
		buyButton.Text = "🔒 LOCKED"
		buyButton.BackgroundColor3 = COLORS.Locked
		buyButton.AutoButtonColor = false
	elseif itemType == "generator" then
		buyButton.Text = string.format("PLACE • %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		buyButton.AutoButtonColor = true
	elseif itemType == "place" then
		buyButton.Text = string.format("PLACE T1 • %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		buyButton.AutoButtonColor = true
	elseif itemType == "upgrade" then
		buyButton.Text = string.format("UPGRADE • %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
		buyButton.AutoButtonColor = true
	else
		buyButton.Text = "🚫 " .. formatMoney(itemData.price)
		buyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		buyButton.AutoButtonColor = false
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
		warn("[ShopUI DEBUG] Error al obtener objetos:", objects)
		return nil
	end

	if not objects or type(objects) ~= "table" then
		print("[ShopUI DEBUG] GetMyObjects devolvió:", objects, "tipo:", type(objects))
		return nil
	end

	print(string.format("[ShopUI DEBUG] Buscando turrets tipo '%s', objetos encontrados: %d", turretType, #objects))
	local highestTier = nil
	for _, obj in ipairs(objects) do
		if obj.Type then
			print(string.format("[ShopUI DEBUG] - Type='%s', ObjectId='%s'", obj.Type, tostring(obj.ObjectId)))
		end
		if obj.Type and obj.Type:match("^" .. turretType) then
			print(string.format("[ShopUI DEBUG] ✅ Match! Type='%s' matchea con '^%s'", obj.Type, turretType))
			-- Extract tier from type (e.g., "MachineGunT2" -> 2)
			local tierStr = obj.Type:match("T(%d+)$")
			if tierStr then
				local tier = tonumber(tierStr)
				if not highestTier or tier > highestTier then
					highestTier = tier
				end
			end
		end
	end
	print(string.format("[ShopUI DEBUG] Tier más alto para '%s': %s", turretType, tostring(highestTier)))
	return highestTier
end

-- Helper: Get ObjectId of a specific turret type
local function getTurretObjectId(turretType: string): string?
	local objects = BaseOwnershipService:GetMyObjects(player)
	if not objects then return nil end

	for _, obj in ipairs(objects) do
		if obj.Type and obj.Type:match("^" .. turretType) then
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

	if currentMainTab == "Income" then
		-- Show generators
		for _, gen in ipairs(GENERATORS) do
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
				stats = nil,
				itemType = "generator",
				size = gen.size,
			})
		end

	elseif currentMainTab == "Turrets" then
		-- Smart turret system
		local turretList = TURRET_TYPES[currentSubTab]
		if not turretList then return end

		local currentTier = getPlayerTurretTier(currentSubTab) or 0
		local turretObjectId = getTurretObjectId(currentSubTab)

		for _, turretData in ipairs(turretList) do
			local tier = turretData.tier
			local itemState: CardState
			local canAfford = cash >= turretData.cost
			local actionType = "locked"

			if tier == 1 then
				-- T1 is always available for placement
				if currentTier >= 1 then
					itemState = "Owned"
					actionType = "owned"
				else
					itemState = canAfford and "Available" or "Locked"
					actionType = canAfford and "place" or "locked"
				end
			else
				-- T2-T5 require previous tier
				if currentTier >= tier then
					itemState = "Owned"
					actionType = "owned"
				elseif currentTier == tier - 1 then
					-- Next tier available for upgrade
					itemState = canAfford and "Available" or "Locked"
					actionType = canAfford and "upgrade" or "locked"
				else
					-- Locked until previous tier
					itemState = "Locked"
					actionType = "locked"
				end
			end

			-- Build stats display
			local stats = nil
			if turretData.damage and turretData.fireRate then
				-- Machine Gun
				stats = {
					DMG = {current = turretData.damage, after = turretData.damage},
					FR = {current = string.format("%.2fs", turretData.fireRate), after = string.format("%.2fs", turretData.fireRate)},
					RNG = {current = turretData.range, after = turretData.range},
				}
			elseif turretData.dps and turretData.chains then
				-- Tesla (has chains)
				stats = {
					DPS = {current = turretData.dps, after = turretData.dps},
					CHAIN = {current = turretData.chains, after = turretData.chains},
					RNG = {current = turretData.range, after = turretData.range},
				}
			elseif turretData.dps then
				-- Laser (no chains)
				stats = {
					DPS = {current = turretData.dps, after = turretData.dps},
					RNG = {current = turretData.range, after = turretData.range},
				}
			elseif turretData.cooldown and turretData.damage then
				-- Missile
				stats = {
					DMG = {current = turretData.damage, after = turretData.damage},
					CD = {current = string.format("%.1fs", turretData.cooldown), after = string.format("%.1fs", turretData.cooldown)},
					RNG = {current = turretData.range, after = turretData.range},
				}
			end

			makeCard({
				id = turretData.id,
				name = string.format("%s T%d", currentSubTab, tier),
				price = turretData.cost,
				count = currentTier >= tier and 1 or 0,
				maxCount = 1,
				state = itemState,
				icon = TURRET_ICONS[currentSubTab] or "🔫",
				category = "Turrets",
				canAfford = canAfford,
				description = string.format("Tier %d %s turret", tier, currentSubTab),
				stats = stats,
				itemType = actionType,
				turretType = currentSubTab,
				objectId = turretObjectId,
				size = Vector3.new(6 + tier, 8 + tier, 6 + tier),
			})
		end

	elseif currentMainTab == "Defense" then
		-- Shield Dome placeholder
		makeCard({
			id = "ShieldDome",
			name = "Shield Dome",
			price = 2500000,
			count = 0,
			state = "Locked",
			icon = "🛡️",
			category = "Defense",
			canAfford = false,
			description = "Coming soon: Emergency protection dome",
			stats = nil,
			itemType = "placeholder",
		})

	elseif currentMainTab == "Pets" then
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

	elseif currentMainTab == "PowerUps" then
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
end

function ShopUIController:SetVisible(visible: boolean)
	isMenuOpen = visible
	mainFrame.Visible = visible
	shadow.Visible = visible
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
		end
	end)

	-- Initial load
	self:PopulateGrid()

	-- Auto-refresh
	task.spawn(function()
		while true do
			task.wait(2)
			if isMenuOpen then
				self:PopulateGrid()
			end
		end
	end)

	-- Parent to PlayerGui
	screenGui.Parent = player:WaitForChild("PlayerGui")

	-- Start visible
	self:SetVisible(true)

	print("[ShopUIController] ✅ Ready (Press Q to toggle)")
end

return ShopUIController
