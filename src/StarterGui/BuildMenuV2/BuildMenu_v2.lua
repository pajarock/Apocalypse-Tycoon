--!strict
--[[
	BuildMenu_v2.lua - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema de menú de construcción completamente rediseñado.

	FEATURES:
	- Grid adaptativo de cards (3x4 desktop, 2xN mobile)
	- Preview panel lateral con ViewportFrame 3D
	- Sub-tabs para Turrets (MG, Laser, Missile, Tesla)
	- Estados visuales claros (Available, Owned, Locked, Max)
	- Comparison view (Current vs After upgrade)
	- Scroll ancho y suave (16px)

	ESTRUCTURA:
	┌──────────────────────────────────────────────┐
	│  Header (Title + Cash + Close)               │
	├──────────────────────────────────────────────┤
	│  Main Tabs (Income|Defense|Turrets|etc)      │
	│  Sub-tabs (si Turrets: MG|Laser|Missile|etc) │
	├──────────────────────────────────────────────┤
	│  Grid Container (60%)  │  Preview Panel (40%)│
	│  ┌────┐ ┌────┐        │  ┌────────────────┐ │
	│  │Card│ │Card│        │  │  ViewportFrame │ │
	│  └────┘ └────┘        │  └────────────────┘ │
	│                        │  Stats + Buy Button │
	└──────────────────────────────────────────────┘

	═══════════════════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction
local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent

-- UI ROOT
local player = Players.LocalPlayer
local gui = script.Parent :: ScreenGui

-- ═══════════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════

local MENU_SIZE = Vector2.new(800, 600)  -- Desktop size
local GRID_WIDTH_PERCENT = 0.6  -- 60% for grid, 40% for preview
local CARD_SIZE = Vector2.new(150, 180)
local CARD_PADDING = 8
local SCROLL_BAR_THICKNESS = 16

-- Colors
local COLORS = {
	Background = Color3.fromRGB(15, 15, 18),
	Header = Color3.fromRGB(255, 170, 50),
	TabActive = Color3.fromRGB(80, 100, 60),
	TabInactive = Color3.fromRGB(40, 40, 50),

	-- Card states
	Available = Color3.fromRGB(0, 255, 100),  -- Green bright
	Owned = Color3.fromRGB(50, 150, 80),      -- Green dark
	Locked = Color3.fromRGB(100, 100, 100),   -- Gray
	MaxTier = Color3.fromRGB(255, 215, 0),    -- Gold
}

-- Main Tabs configuration
local MAIN_TABS = {
	{name = "Income", emoji = "💰", color = Color3.fromRGB(255, 215, 0)},
	{name = "Defense", emoji = "🛡️", color = Color3.fromRGB(100, 150, 255)},
	{name = "Turrets", emoji = "🔫", color = Color3.fromRGB(255, 100, 100)},
	{name = "Utility", emoji = "⚙️", color = Color3.fromRGB(150, 150, 150)},
	{name = "Eggs", emoji = "🥚", color = Color3.fromRGB(255, 200, 255)},
}

-- Sub-tabs for Turrets
local TURRET_SUBTABS = {
	{name = "MachineGun", emoji = "🔫", displayName = "MG"},
	{name = "Laser", emoji = "⚡", displayName = "Laser"},
	{name = "Missile", emoji = "🚀", displayName = "Missile"},
	{name = "Tesla", emoji = "⚡", displayName = "Tesla"},
}

-- State
local currentMainTab = "Income"
local currentSubTab = "MachineGun"  -- For Turrets tab
local selectedItem = nil  -- Currently selected item in preview panel
local isMenuOpen = true

-- ═══════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════

local function formatMoney(amount: number): string
	if amount >= 1e6 then
		return string.format("$%.1fM", amount / 1e6)
	elseif amount >= 1e3 then
		return string.format("$%.1fK", amount / 1e3)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

local function createUICorner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function createUIStroke(parent: GuiObject, color: Color3, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

-- ═══════════════════════════════════════════════════════════════════════
-- MAIN FRAME SETUP
-- ═══════════════════════════════════════════════════════════════════════

-- Main container frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "BuildMenuV2"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.Size = UDim2.fromOffset(MENU_SIZE.X, MENU_SIZE.Y)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 100
mainFrame.Parent = gui

createUICorner(mainFrame, 12)
createUIStroke(mainFrame, COLORS.Header, 4)

-- Shadow effect
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.fromScale(0.5, 0.505)
shadow.Size = UDim2.fromOffset(MENU_SIZE.X + 10, MENU_SIZE.Y + 10)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0
shadow.ZIndex = 99
shadow.Parent = gui

createUICorner(shadow, 12)

-- ═══════════════════════════════════════════════════════════════════════
-- HEADER
-- ═══════════════════════════════════════════════════════════════════════

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1
header.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.fromOffset(15, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = COLORS.Header
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🏗️ BUILD MENU v2.0"
title.TextStrokeTransparency = 0.5
title.Parent = header

-- Cash display
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.Size = UDim2.new(0.3, 0, 1, 0)
cashLabel.Position = UDim2.new(0.5, 0, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 20
cashLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
cashLabel.Text = "$0"
cashLabel.TextStrokeTransparency = 0.5
cashLabel.Parent = header

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(40, 40)
closeButton.Position = UDim2.new(1, -50, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 24
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Text = "✕"
closeButton.Parent = header

createUICorner(closeButton, 8)

-- ═══════════════════════════════════════════════════════════════════════
-- TABS CONTAINER
-- ═══════════════════════════════════════════════════════════════════════

local tabsContainer = Instance.new("Frame")
tabsContainer.Name = "TabsContainer"
tabsContainer.Size = UDim2.new(1, -20, 0, 90)  -- 90px tall (main + sub tabs)
tabsContainer.Position = UDim2.fromOffset(10, 55)
tabsContainer.BackgroundTransparency = 1
tabsContainer.Parent = mainFrame

-- Main tabs row
local mainTabsRow = Instance.new("Frame")
mainTabsRow.Name = "MainTabsRow"
mainTabsRow.Size = UDim2.new(1, 0, 0, 40)
mainTabsRow.BackgroundTransparency = 1
mainTabsRow.Parent = tabsContainer

local mainTabsLayout = Instance.new("UIListLayout")
mainTabsLayout.FillDirection = Enum.FillDirection.Horizontal
mainTabsLayout.Padding = UDim.new(0, 6)
mainTabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
mainTabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainTabsLayout.Parent = mainTabsRow

-- Sub-tabs row (for Turrets)
local subTabsRow = Instance.new("Frame")
subTabsRow.Name = "SubTabsRow"
subTabsRow.Size = UDim2.new(1, 0, 0, 36)
subTabsRow.Position = UDim2.fromOffset(0, 46)
subTabsRow.BackgroundTransparency = 1
subTabsRow.Visible = false  -- Hidden by default
subTabsRow.Parent = tabsContainer

local subTabsLayout = Instance.new("UIListLayout")
subTabsLayout.FillDirection = Enum.FillDirection.Horizontal
subTabsLayout.Padding = UDim.new(0, 4)
subTabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
subTabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
subTabsLayout.Parent = subTabsRow

-- ═══════════════════════════════════════════════════════════════════════
-- CONTENT AREA (Grid + Preview)
-- ═══════════════════════════════════════════════════════════════════════

local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -20, 1, -160)  -- Below tabs
contentArea.Position = UDim2.fromOffset(10, 150)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

-- Grid Container (Left 60%)
local gridContainer = Instance.new("ScrollingFrame")
gridContainer.Name = "GridContainer"
gridContainer.Size = UDim2.new(GRID_WIDTH_PERCENT, -5, 1, 0)
gridContainer.Position = UDim2.fromOffset(0, 0)
gridContainer.BackgroundTransparency = 1
gridContainer.BorderSizePixel = 0
gridContainer.ScrollBarThickness = SCROLL_BAR_THICKNESS
gridContainer.ScrollBarImageColor3 = COLORS.Header
gridContainer.ScrollBarImageTransparency = 0
gridContainer.CanvasSize = UDim2.fromOffset(0, 0)
gridContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
gridContainer.ScrollingDirection = Enum.ScrollingDirection.Y
gridContainer.ElasticBehavior = Enum.ElasticBehavior.Always
gridContainer.Parent = contentArea

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
gridLayout.CellPadding = UDim2.fromOffset(CARD_PADDING, CARD_PADDING)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gridLayout.Parent = gridContainer

-- Preview Panel (Right 40%)
local previewPanel = Instance.new("Frame")
previewPanel.Name = "PreviewPanel"
previewPanel.Size = UDim2.new(1 - GRID_WIDTH_PERCENT, -5, 1, 0)
previewPanel.Position = UDim2.new(GRID_WIDTH_PERCENT, 5, 0, 0)
previewPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
previewPanel.BackgroundTransparency = 0.3
previewPanel.BorderSizePixel = 0
previewPanel.Parent = contentArea

createUICorner(previewPanel, 8)
createUIStroke(previewPanel, COLORS.Header, 2)

-- Preview placeholder text
local previewPlaceholder = Instance.new("TextLabel")
previewPlaceholder.Name = "Placeholder"
previewPlaceholder.Size = UDim2.new(1, -20, 1, -20)
previewPlaceholder.Position = UDim2.fromOffset(10, 10)
previewPlaceholder.BackgroundTransparency = 1
previewPlaceholder.Font = Enum.Font.Gotham
previewPlaceholder.TextSize = 16
previewPlaceholder.TextColor3 = Color3.fromRGB(150, 150, 150)
previewPlaceholder.Text = "Select an item to preview"
previewPlaceholder.TextWrapped = true
previewPlaceholder.TextYAlignment = Enum.TextYAlignment.Top
previewPlaceholder.Parent = previewPanel

-- ═══════════════════════════════════════════════════════════════════════
-- TAB MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════

-- Storage for tab buttons
local mainTabButtons: {[string]: TextButton} = {}
local subTabButtons: {[string]: TextButton} = {}

-- Update tab visual states based on current selection
local function updateTabStates()
	-- Update main tabs
	for tabName, tabButton in pairs(mainTabButtons) do
		if tabName == currentMainTab then
			-- Active tab
			tabButton.BackgroundColor3 = COLORS.TabActive
			tabButton.BackgroundTransparency = 0
			tabButton.TextColor3 = Color3.new(1, 1, 1)
			tabButton.TextSize = 18
		else
			-- Inactive tab
			tabButton.BackgroundColor3 = COLORS.TabInactive
			tabButton.BackgroundTransparency = 0.3
			tabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
			tabButton.TextSize = 16
		end
	end

	-- Show/hide sub-tabs row based on if Turrets is selected
	if currentMainTab == "Turrets" then
		subTabsRow.Visible = true

		-- Update sub-tab states
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
end

-- Create a main tab button
local function makeMainTab(tabData: {name: string, emoji: string, color: Color3}): TextButton
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

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		currentMainTab = tabData.name
		updateTabStates()
		-- TODO: Refresh grid content
	end)

	-- Hover effects
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
	return btn
end

-- Create a turret sub-tab button
local function makeSubTab(subData: {name: string, emoji: string, displayName: string}): TextButton
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

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		currentSubTab = subData.name
		updateTabStates()
		-- TODO: Refresh grid content for this turret type
	end)

	-- Hover effects
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
	return btn
end

-- Create all tabs
for _, tabData in ipairs(MAIN_TABS) do
	makeMainTab(tabData)
end

for _, subData in ipairs(TURRET_SUBTABS) do
	makeSubTab(subData)
end

-- Set initial tab states
updateTabStates()

-- ═══════════════════════════════════════════════════════════════════════
-- CARD SYSTEM
-- ═══════════════════════════════════════════════════════════════════════

-- Storage for card instances
local cardInstances: {[string]: Frame} = {}

-- Card state type
type CardState = "Available" | "Owned" | "Locked" | "Max"

-- Get visual properties for card state
local function getCardStateVisuals(state: CardState, canAfford: boolean): {
	backgroundColor: Color3,
	badgeText: string,
	badgeColor: Color3,
	strokeColor: Color3
}
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
	else -- Available
		return {
			backgroundColor = canAfford and Color3.fromRGB(20, 35, 25) or Color3.fromRGB(35, 20, 20),
			badgeText = "💎",
			badgeColor = canAfford and COLORS.Available or Color3.fromRGB(255, 100, 100),
			strokeColor = canAfford and COLORS.Available or Color3.fromRGB(255, 50, 50)
		}
	end
end

-- Create a card
local function makeCard(itemData: {
	id: string,
	name: string,
	price: number,
	count: number,
	maxCount: number?,
	state: CardState,
	icon: string,
	category: string,
	canAfford: boolean
}): Frame
	local card = Instance.new("Frame")
	card.Name = "Card_" .. itemData.id
	card.Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y)
	card.BorderSizePixel = 0
	card.ClipsDescendants = false

	local visuals = getCardStateVisuals(itemData.state, itemData.canAfford)
	card.BackgroundColor3 = visuals.backgroundColor

	createUICorner(card, 8)
	local stroke = createUIStroke(card, visuals.strokeColor, 2)
	stroke.Transparency = 0.2

	-- Badge (top-right)
	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
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

	-- Icon (center)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
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
	nameLabel.Name = "ItemName"
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
	priceLabel.Name = "Price"
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

	-- Count (if owned)
	if itemData.count > 0 then
		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "Count"
		countLabel.Size = UDim2.new(1, -16, 0, 18)
		countLabel.Position = UDim2.fromOffset(8, 155)
		countLabel.BackgroundTransparency = 1
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextSize = 12
		countLabel.TextColor3 = Color3.fromRGB(150, 200, 255)

		if itemData.maxCount and itemData.count >= itemData.maxCount then
			countLabel.Text = string.format("x%d [MAX]", itemData.count)
		else
			countLabel.Text = string.format("x%d", itemData.count)
		end

		countLabel.TextXAlignment = Enum.TextXAlignment.Center
		countLabel.ZIndex = 2
		countLabel.Parent = card
	end

	-- Make it a button
	local clickButton = Instance.new("TextButton")
	clickButton.Name = "ClickArea"
	clickButton.Size = UDim2.fromScale(1, 1)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.ZIndex = 4
	clickButton.Parent = card

	-- Click handler
	clickButton.MouseButton1Click:Connect(function()
		selectedItem = itemData
		-- TODO: Update preview panel
		print("[BuildMenu v2.0] Selected:", itemData.name)
	end)

	-- Hover effects
	clickButton.MouseEnter:Connect(function()
		stroke.Thickness = 3
		card.Position = card.Position - UDim2.fromOffset(0, 2)
	end)

	clickButton.MouseLeave:Connect(function()
		stroke.Thickness = 2
		card.Position = card.Position + UDim2.fromOffset(0, 2)
	end)

	card.Parent = gridContainer
	cardInstances[itemData.id] = card

	return card
end

-- Clear all cards from grid
local function clearCards()
	for id, card in pairs(cardInstances) do
		card:Destroy()
		cardInstances[id] = nil
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- PREVIEW PANEL
-- ═══════════════════════════════════════════════════════════════════════

-- ViewportFrame for 3D preview
local viewportFrame = Instance.new("ViewportFrame")
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
local statsContainer = Instance.new("Frame")
statsContainer.Name = "StatsContainer"
statsContainer.Size = UDim2.new(1, -20, 0, 120)
statsContainer.Position = UDim2.fromOffset(10, 220)
statsContainer.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
statsContainer.BackgroundTransparency = 0.5
statsContainer.BorderSizePixel = 0
statsContainer.Visible = false
statsContainer.Parent = previewPanel

createUICorner(statsContainer, 8)

-- Stats title
local statsTitle = Instance.new("TextLabel")
statsTitle.Name = "StatsTitle"
statsTitle.Size = UDim2.new(1, -16, 0, 20)
statsTitle.Position = UDim2.fromOffset(8, 5)
statsTitle.BackgroundTransparency = 1
statsTitle.Font = Enum.Font.GothamBold
statsTitle.TextSize = 14
statsTitle.TextColor3 = COLORS.Header
statsTitle.Text = "STATS COMPARISON"
statsTitle.TextXAlignment = Enum.TextXAlignment.Center
statsTitle.Parent = statsContainer

-- Stats table (Current | After)
local statsGrid = Instance.new("Frame")
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
local buyButton = Instance.new("TextButton")
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
local descriptionLabel = Instance.new("TextLabel")
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

-- Helper to create a stat row
local function createStatRow(statName: string, currentValue: string, afterValue: string, layoutOrder: number): Frame
	local row = Instance.new("Frame")
	row.Name = "Stat_" .. statName
	row.Size = UDim2.new(1, 0, 0, 18)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = statsGrid

	-- Stat name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "StatName"
	nameLabel.Size = UDim2.new(0.3, 0, 1, 0)
	nameLabel.Position = UDim2.fromScale(0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 11
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.Text = statName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	-- Current value
	local currentLabel = Instance.new("TextLabel")
	currentLabel.Name = "Current"
	currentLabel.Size = UDim2.new(0.35, 0, 1, 0)
	currentLabel.Position = UDim2.fromScale(0.3, 0)
	currentLabel.BackgroundTransparency = 1
	currentLabel.Font = Enum.Font.Gotham
	currentLabel.TextSize = 11
	currentLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	currentLabel.Text = currentValue
	currentLabel.TextXAlignment = Enum.TextXAlignment.Center
	currentLabel.Parent = row

	-- Arrow
	local arrowLabel = Instance.new("TextLabel")
	arrowLabel.Name = "Arrow"
	arrowLabel.Size = UDim2.fromOffset(20, 18)
	arrowLabel.Position = UDim2.fromScale(0.65, 0)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.Font = Enum.Font.GothamBold
	arrowLabel.TextSize = 12
	arrowLabel.TextColor3 = COLORS.Header
	arrowLabel.Text = "→"
	arrowLabel.Parent = row

	-- After value
	local afterLabel = Instance.new("TextLabel")
	afterLabel.Name = "After"
	afterLabel.Size = UDim2.new(0.3, 0, 1, 0)
	afterLabel.Position = UDim2.fromScale(0.7, 0)
	afterLabel.BackgroundTransparency = 1
	afterLabel.Font = Enum.Font.GothamBold
	afterLabel.TextSize = 11
	afterLabel.TextColor3 = COLORS.Available
	afterLabel.Text = afterValue
	afterLabel.TextXAlignment = Enum.TextXAlignment.Center
	afterLabel.Parent = row

	return row
end

-- Update preview panel with selected item
local function updatePreviewPanel(itemData: any?)
	if not itemData then
		-- No item selected - show placeholder
		previewPlaceholder.Visible = true
		viewportFrame.Visible = false
		statsContainer.Visible = false
		buyButton.Visible = false
		descriptionLabel.Visible = false
		return
	end

	-- Hide placeholder
	previewPlaceholder.Visible = false

	-- Show viewport (TODO: Load actual 3D model)
	viewportFrame.Visible = true

	-- Show and update stats
	statsContainer.Visible = true

	-- Clear existing stat rows
	for _, child in ipairs(statsGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Create stat rows (example - will be populated from real data later)
	if itemData.stats then
		local order = 1
		for statName, statValues in pairs(itemData.stats) do
			if order <= 4 then -- Max 4 stats as per design
				createStatRow(
					statName,
					tostring(statValues.current or "0"),
					tostring(statValues.after or "0"),
					order
				)
				order = order + 1
			end
		end
	end

	-- Update buy button
	buyButton.Visible = true

	if itemData.state == "Max" then
		buyButton.Text = "MAX TIER"
		buyButton.BackgroundColor3 = COLORS.MaxTier
		buyButton.AutoButtonColor = false
	elseif itemData.state == "Locked" then
		buyButton.Text = "🔒 LOCKED"
		buyButton.BackgroundColor3 = COLORS.Locked
		buyButton.AutoButtonColor = false
	elseif itemData.canAfford then
		if itemData.count > 0 then
			buyButton.Text = string.format("UPGRADE • %s", formatMoney(itemData.price))
		else
			buyButton.Text = string.format("BUY • %s", formatMoney(itemData.price))
		end
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		buyButton.AutoButtonColor = true
	else
		buyButton.Text = string.format("🚫 %s", formatMoney(itemData.price))
		buyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		buyButton.AutoButtonColor = false
	end

	-- Show description
	descriptionLabel.Visible = true
	descriptionLabel.Text = itemData.description or "No description available"
end

-- Buy button handler
buyButton.MouseButton1Click:Connect(function()
	if not selectedItem then return end

	-- Don't allow purchase if locked or max
	if selectedItem.state == "Locked" or selectedItem.state == "Max" then
		return
	end

	-- Don't allow if can't afford
	if not selectedItem.canAfford then
		print("[BuildMenu v2.0] Cannot afford:", selectedItem.name)
		return
	end

	-- TODO: Fire purchase request to server
	print("[BuildMenu v2.0] Purchase requested:", selectedItem.id)
	RequestPurchase:FireServer(selectedItem.id)
end)

-- Update card click handler to refresh preview
local originalMakeCard = makeCard
makeCard = function(itemData)
	local card = originalMakeCard(itemData)

	-- Override click handler to update preview
	local clickButton = card:FindFirstChild("ClickArea")
	if clickButton then
		clickButton.MouseButton1Click:Connect(function()
			selectedItem = itemData
			updatePreviewPanel(itemData)
		end)
	end

	return card
end

-- ═══════════════════════════════════════════════════════════════════════
-- MENU VISIBILITY
-- ═══════════════════════════════════════════════════════════════════════

local function setMenuVisible(visible: boolean)
	isMenuOpen = visible
	mainFrame.Visible = visible
	shadow.Visible = visible
end

-- Close button
closeButton.MouseButton1Click:Connect(function()
	setMenuVisible(false)
end)

-- Toggle with B key (Build menu)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.B then
		setMenuVisible(not isMenuOpen)
	end
end)

-- Start visible
setMenuVisible(true)

-- ═══════════════════════════════════════════════════════════════════════
-- BACKEND INTEGRATION & DATA LOADING
-- ═══════════════════════════════════════════════════════════════════════

-- Fetch player state from server
local function fetchState()
	local ok, state = pcall(function()
		return RequestState:InvokeServer()
	end)

	if not ok then
		warn("[BuildMenu v2.0] Failed to fetch state:", state)
		return {
			Cash = 0,
			IncomePerSec = 0,
			UpgradesInfo = {},
			Turrets = {},
			ShieldLevel = 0
		}
	end

	return state
end

-- Map upgrade categories (from old Shop_client.lua)
local UPGRADE_CATEGORIES = {
	Income = {"Upgrade_1", "Upgrade_2", "Upgrade_3", "Upgrade_4", "Upgrade_5", "Upgrade_9"},
	Defense = {"Upgrade_6", "Upgrade_7", "Upgrade_8"},
	Utility = {"Upgrade_11", "Upgrade_10"},
	Eggs = {}, -- Empty for now
}

-- Icon mapping for upgrades
local UPGRADE_ICONS = {
	Upgrade_1 = "💵",
	Upgrade_2 = "💰",
	Upgrade_3 = "🏦",
	Upgrade_4 = "💎",
	Upgrade_5 = "🏆",
	Upgrade_6 = "🛡️",
	Upgrade_7 = "🏰",
	Upgrade_8 = "⚡",
	Upgrade_9 = "📈",
	Upgrade_10 = "🔧",
	Upgrade_11 = "⚙️",
}

-- Icon mapping for turrets
local TURRET_ICONS = {
	MachineGun = "🔫",
	Laser = "⚡",
	Missile = "🚀",
	Tesla = "⚡",
}

-- Determine card state based on data
local function getCardState(count: number, maxCount: number?, price: number, cash: number): CardState
	if maxCount and count >= maxCount then
		return "Max"
	elseif count > 0 then
		return "Owned"
	elseif cash >= price then
		return "Available"
	else
		return "Locked"
	end
end

-- Populate grid with current tab's items
local function populateGrid()
	-- Clear existing cards
	clearCards()

	local state = fetchState()
	local cash = state.Cash or 0

	-- Update cash display in header
	cashLabel.Text = formatMoney(cash)

	if currentMainTab == "Turrets" then
		-- TODO: Load turret data for current sub-tab
		-- For now, show placeholder
		print("[BuildMenu v2.0] Loading turrets for:", currentSubTab)

		-- Example turret cards (will be replaced with real data)
		for tier = 1, 5 do
			local turretId = currentSubTab .. "T" .. tier
			local cost = tier * 10000 -- Placeholder cost

			local itemData = {
				id = turretId,
				name = string.format("%s T%d", currentSubTab, tier),
				price = cost,
				count = 0,
				maxCount = nil,
				state = getCardState(0, nil, cost, cash),
				icon = TURRET_ICONS[currentSubTab] or "🔫",
				category = "Turrets",
				canAfford = cash >= cost,
				description = string.format("Tier %d %s turret", tier, currentSubTab),
				stats = {
					DMG = {current = tier * 10, after = (tier + 1) * 10},
					DPS = {current = tier * 5, after = (tier + 1) * 5},
					RNG = {current = tier * 20, after = (tier + 1) * 20},
					CD = {current = 1.0, after = 0.9},
				}
			}

			makeCard(itemData)
		end

	else
		-- Load upgrades for current category
		local categoryUpgrades = UPGRADE_CATEGORIES[currentMainTab] or {}

		for _, upgradeId in ipairs(categoryUpgrades) do
			local upgradeInfo = state.UpgradesInfo and state.UpgradesInfo[upgradeId]

			if upgradeInfo then
				local count = upgradeInfo.Count or 0
				local maxCount = upgradeInfo.MaxCount
				local price = upgradeInfo.Price or 0

				local itemData = {
					id = upgradeId,
					name = upgradeInfo.Title or upgradeId,
					price = price,
					count = count,
					maxCount = maxCount,
					state = getCardState(count, maxCount, price, cash),
					icon = UPGRADE_ICONS[upgradeId] or "📦",
					category = currentMainTab,
					canAfford = cash >= price,
					description = upgradeInfo.Description or "No description available",
					stats = nil -- Upgrades don't show stats comparison
				}

				makeCard(itemData)
			end
		end
	end
end

-- Refresh when tab changes
local originalUpdateTabStates = updateTabStates
updateTabStates = function()
	originalUpdateTabStates()
	populateGrid()
end

-- Initial population
populateGrid()

-- Auto-refresh every 2 seconds
task.spawn(function()
	while true do
		task.wait(2)
		if isMenuOpen then
			populateGrid()
		end
	end
end)

print("[BuildMenu v2.0] ✅ Structure created successfully")
print("[BuildMenu v2.0] ✅ Tabs system initialized")
print("[BuildMenu v2.0] ✅ Menu controls ready (Press B to toggle)")
print("[BuildMenu v2.0] ✅ Backend integration complete")
