--!strict
-- Shop.client.lua (LocalScript en StarterGui/ShopUI)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction
local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent

-- UI ROOT
local gui = script.Parent :: ScreenGui

-- Panel principal con estilo urbano
local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.Size = UDim2.fromOffset(280, 320)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Rotation = -1 -- Rotación sutil urbano
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- Sombra pronunciada
local shopShadow = Instance.new("Frame")
shopShadow.Size = UDim2.fromOffset(286, 326)
shopShadow.Position = UDim2.new(0, 17, 0, 103)
shopShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shopShadow.BackgroundTransparency = 0.6
shopShadow.BorderSizePixel = 0
shopShadow.Rotation = -1
shopShadow.ZIndex = 0
shopShadow.Parent = gui
Instance.new("UICorner", shopShadow).CornerRadius = UDim.new(0, 12)
frame.ZIndex = 1

-- Borde grueso vibrante
local shopStroke = Instance.new("UIStroke")
shopStroke.Color = Color3.fromRGB(255, 170, 50)
shopStroke.Thickness = 4
shopStroke.Transparency = 0
shopStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
shopStroke.Parent = frame

-- Gradiente en el borde
local shopGradient = Instance.new("UIGradient")
shopGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200))
})
shopGradient.Rotation = 45
shopGradient.Parent = shopStroke

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 32)
title.Position = UDim2.fromOffset(10, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.LuckiestGuy -- GRAFITI
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 200, 80)
title.Text = "SHOP"
title.TextStrokeTransparency = 0.3
title.TextStrokeColor3 = Color3.fromRGB(50, 25, 0)
title.Rotation = -2 -- Inclinación grafiti
title.ZIndex = 2
title.Parent = frame

local info = Instance.new("TextLabel")
info.Name = "Info"
info.Size = UDim2.new(1, -20, 0, 22)
info.Position = UDim2.fromOffset(10, 42)
info.BackgroundTransparency = 1
info.Font = Enum.Font.GothamBold
info.TextScaled = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextColor3 = Color3.fromRGB(100, 255, 140)
info.Text = "Cash: $0" -- ✅ FIX: Solo mostrar Cash, Income movido a widget separado
info.TextStrokeTransparency = 0.6
info.ZIndex = 2
info.Parent = frame

-- ✅ TABS DE CATEGORÍAS
local tabsContainer = Instance.new("Frame")
tabsContainer.Name = "TabsContainer"
tabsContainer.Size = UDim2.new(1, -20, 0, 30)
tabsContainer.Position = UDim2.fromOffset(10, 68)
tabsContainer.BackgroundTransparency = 1
tabsContainer.ZIndex = 2
tabsContainer.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 4)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabsContainer

local list = Instance.new("Frame")
list.Name = "List"
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(10, 105) -- ✅ FIX: Ajustado para tabs
list.Size = UDim2.new(1, -20, 1, -115) -- ✅ FIX: Ajustado para tabs
list.ZIndex = 2
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

-- Helpers
local function fmtMoney(n: any): string
	local x = tonumber(n) or 0
	if x >= 1e6 then return string.format("$%.1fM", x/1e6) end
	if x >= 1e3 then return string.format("$%.1fK", x/1e3) end
	return "$"..tostring(math.floor(x))
end

local buttons: {[string]: TextButton} = {}
local shieldLevel = 0

-- Función para obtener estado del servidor
local function fetchState()
	local ok, st = pcall(function()
		return RequestState:InvokeServer()
	end)
	if not ok then
		return { Cash = 0, IncomePerSec = 0, UpgradesInfo = {}, ShieldLevel = 0 }
	end
	return st
end

-- Crear fila de upgrade con estilo urbano
local function makeRow(upgId: string): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = upgId
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(25, 80, 45)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true -- FIX: Auto-escalar para evitar overflow
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = true
	btn.TextStrokeTransparency = 0.5
	btn.ZIndex = 3
	btn.Parent = list
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	-- Borde del botón
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(0, 255, 100)
	btnStroke.Thickness = 2
	btnStroke.Transparency = 0.3
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Parent = btn

	-- Padding
	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingLeft = UDim.new(0, 8)
	btnPadding.PaddingRight = UDim.new(0, 8)
	btnPadding.Parent = btn

	btn.MouseButton1Click:Connect(function()
		local currentState = fetchState()
		local upgradeInfo = currentState.UpgradesInfo and currentState.UpgradesInfo[upgId]

		if not upgradeInfo then return end

		local price = upgradeInfo.Price or 999999
		local cash = currentState.Cash or 0
		local count = upgradeInfo.Count or 0
		local maxCount = upgradeInfo.MaxCount  -- Necesitas pasar esto desde servidor

		-- Verificar MaxCount
		if maxCount and count >= maxCount then
			-- Sonido de límite alcanzado
			local sound = Instance.new("Sound", workspace)
			sound.SoundId = "rbxassetid://1847058585"
			sound.Volume = 0.3
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 2)
			return  -- No enviar compra
		end

		if cash >= price then
			RequestPurchase:FireServer(upgId)
			-- Sonido exitoso
			local sound = Instance.new("Sound", workspace)
			sound.SoundId = "rbxassetid://17208380755"
			sound.Volume = 0.5
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 2)
		else
			-- Sonido fallido
			local sound = Instance.new("Sound", workspace)
			sound.SoundId = "rbxassetid://2390695935"
			sound.Volume = 0.3
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 2)
		end
	end)

	buttons[upgId] = btn
	return btn
end

-- ✅ Categorías de upgrades
local CATEGORIES = {
	{Name = "INCOME", Icon = "💰", Upgrades = {"Upgrade_1", "Upgrade_2", "Upgrade_3", "Upgrade_4", "Upgrade_5", "Upgrade_9"}},
	{Name = "DEFENSE", Icon = "🛡️", Upgrades = {"Upgrade_6", "Upgrade_7", "Upgrade_8"}},
	{Name = "UTILITY", Icon = "⚙️", Upgrades = {"Upgrade_10", "Upgrade_11"}},
	{Name = "PETS", Icon = "🥚", Upgrades = {"Upgrade_12"}},
}

local currentCategory = 1 -- Categoría actual seleccionada
local tabButtons: {[number]: TextButton} = {}

-- ✅ Crear tabs de categorías
local function createCategoryTabs()
	for i, category in ipairs(CATEGORIES) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab_" .. category.Name
		tab.Size = UDim2.fromOffset(60, 28)
		tab.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
		tab.BorderSizePixel = 0
		tab.Font = Enum.Font.GothamBold
		tab.TextScaled = true
		tab.TextColor3 = Color3.fromRGB(150, 150, 150)
		tab.Text = category.Icon
		tab.ZIndex = 3
		tab.LayoutOrder = i
		tab.Parent = tabsContainer

		Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)

		-- Borde del tab
		local tabStroke = Instance.new("UIStroke")
		tabStroke.Color = Color3.fromRGB(100, 100, 100)
		tabStroke.Thickness = 2
		tabStroke.Transparency = 0.5
		tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		tabStroke.Parent = tab

		-- Padding
		local tabPadding = Instance.new("UIPadding")
		tabPadding.PaddingLeft = UDim.new(0, 4)
		tabPadding.PaddingRight = UDim.new(0, 4)
		tabPadding.Parent = tab

		-- Click event
		tab.MouseButton1Click:Connect(function()
			currentCategory = i
			refreshAll()
		end)

		tabButtons[i] = tab
	end
end

-- ✅ Actualizar estilo de tabs según categoría activa
local function updateTabStyles()
	for i, tab in ipairs(tabButtons) do
		if i == currentCategory then
			-- Tab activa: brillante y naranja
			tab.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
			tab.TextColor3 = Color3.fromRGB(255, 255, 255)
			local stroke = tab:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Color3.fromRGB(255, 200, 100)
				stroke.Transparency = 0
			end
		else
			-- Tab inactiva: oscura
			tab.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
			tab.TextColor3 = Color3.fromRGB(150, 150, 150)
			local stroke = tab:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = Color3.fromRGB(100, 100, 100)
				stroke.Transparency = 0.5
			end
		end
	end
end

-- Refrescar UI
local function refreshAll()
	local st = fetchState()
	local cash = tonumber(st.Cash) or 0
	local ips = tonumber(st.IncomePerSec) or 0
	shieldLevel = st.ShieldLevel or 0

	-- Actualizar título y tabs
	local categoryName = CATEGORIES[currentCategory] and CATEGORIES[currentCategory].Name or "SHOP"
	title.Text = string.format("%s | SHIELD L%d", categoryName, shieldLevel)
	info.Text = string.format("💰 %s", fmtMoney(cash))
	updateTabStyles()

	-- ✅ FIX: Ocultar TODOS los botones primero
	for _, btn in pairs(buttons) do
		btn.Visible = false
	end

	-- ✅ FIX: Solo mostrar upgrades de la categoría actual
	local categoryUpgrades = CATEGORIES[currentCategory] and CATEGORIES[currentCategory].Upgrades or {}

	for _, upgId in ipairs(categoryUpgrades) do
		local infoU = st.UpgradesInfo and st.UpgradesInfo[upgId]
		if infoU then
			local btn = buttons[upgId] or makeRow(upgId)
			btn.Visible = true
			local label = string.format("%s | %s | x%d",
				tostring(infoU.Title or upgId),
				fmtMoney(infoU.Price or 0),
				tonumber(infoU.Count) or 0
			)
			if upgId == "Upgrade_6" then
				label = label .. string.format(" (L%d)", shieldLevel)
			end
			btn.Text = label
		end
	end
end

-- Toggle con G
local open = true
local function setOpen(v: boolean)
	open = v
	frame.Visible = open
	shopShadow.Visible = open -- ✅ FIX: También ocultar la sombra
end
setOpen(true)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G then
		setOpen(not open)
	end
end)

-- ✅ Inicializar tabs y UI
createCategoryTabs()
refreshAll()

-- Loop de refresco
task.spawn(function()
	while true do
		refreshAll()
		task.wait(1)
	end
end)