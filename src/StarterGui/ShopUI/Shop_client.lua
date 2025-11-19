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

-- Panel principal con estilo urbano (tamaño original)
local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.Size = UDim2.fromOffset(280, 360) -- ? Tamaño fijo que no desborda
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Rotation = -1 -- Rotación sutil urbano
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- Sombra pronunciada
local shopShadow = Instance.new("Frame")
shopShadow.Size = UDim2.fromOffset(286, 366) -- ? Ajustado
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
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.fromOffset(10, 6)
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

-- ? PESTAÑAS (TABS) - Contenedor horizontal
local tabsContainer = Instance.new("Frame")
tabsContainer.Name = "TabsContainer"
tabsContainer.Size = UDim2.new(1, -20, 0, 32)
tabsContainer.Position = UDim2.fromOffset(10, 38)
tabsContainer.BackgroundTransparency = 1
tabsContainer.ZIndex = 2
tabsContainer.Parent = frame

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 4)
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsLayout.Parent = tabsContainer

-- ? Lista de upgrades (con scroll)
local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(10, 76) -- Debajo de pestañas
list.Size = UDim2.new(1, -20, 1, -86) -- Ajustado para no desbordar
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = Color3.fromRGB(255, 170, 50)
list.CanvasSize = UDim2.fromOffset(0, 0) -- Se auto-ajusta
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
local tabButtons: {[string]: TextButton} = {}
local shieldLevel = 0
local currentTab = "Income" -- ? Pestaña activa por defecto

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
	btn.Size = UDim2.new(1, -6, 0, 32) -- ? Ajustado para scrollbar
	btn.BackgroundColor3 = Color3.fromRGB(25, 80, 45)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
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
		local maxCount = upgradeInfo.MaxCount

		-- Verificar MaxCount
		if maxCount and count >= maxCount then
			-- Sonido de límite alcanzado
			local sound = Instance.new("Sound", workspace)
			sound.SoundId = "rbxassetid://1847058585"
			sound.Volume = 0.3
			sound:Play()
			game:GetService("Debris"):AddItem(sound, 2)
			return
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

-- ? NUEVO: Upgrades organizados por categoría con 4 pestañas
local CATEGORIES = {
	{ name = "Income", emoji = "??", upgrades = {"Upgrade_1", "Upgrade_2", "Upgrade_3", "Upgrade_4", "Upgrade_5", "Upgrade_9"} },
	{ name = "Defense", emoji = "???", upgrades = {"Upgrade_6", "Upgrade_7", "Upgrade_8"} },
	{ name = "Utility", emoji = "??", upgrades = {"Upgrade_11", "Upgrade_10"} },
	{ name = "Eggs", emoji = "??", upgrades = {} }, -- ? 4ta pestaña para gacha (vacía por ahora)
}

-- ? Crear botón de pestaña
local function makeTabButton(category: {name: string, emoji: string}): TextButton
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name = "Tab_" .. category.name
	tabBtn.Size = UDim2.fromOffset(64, 30)
	tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	tabBtn.BackgroundTransparency = 0.3
	tabBtn.BorderSizePixel = 0
	tabBtn.Font = Enum.Font.GothamBold
	tabBtn.TextSize = 16
	tabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
	tabBtn.Text = category.emoji
	tabBtn.ZIndex = 3
	tabBtn.Parent = tabsContainer
	Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

	local tabStroke = Instance.new("UIStroke")
	tabStroke.Color = Color3.fromRGB(100, 100, 120)
	tabStroke.Thickness = 2
	tabStroke.Transparency = 0.5
	tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tabStroke.Parent = tabBtn

	-- Click handler
	tabBtn.MouseButton1Click:Connect(function()
		currentTab = category.name
		refreshAll()
	end)

	tabButtons[category.name] = tabBtn
	return tabBtn
end

-- Crear todas las pestañas
for _, category in ipairs(CATEGORIES) do
	makeTabButton(category)
end

-- Refrescar UI
local function refreshAll()
	local st = fetchState()
	local cash = tonumber(st.Cash) or 0
	local ips = tonumber(st.IncomePerSec) or 0
	shieldLevel = st.ShieldLevel or 0

	-- ? FIX: Mostrar reducción de daño del shield actual (18% por nivel - BALANCEADO)
	local shieldReduction = shieldLevel * 18
	if shieldLevel > 0 then
		title.Text = string.format("SHOP | ??? L%d (-%d%%)", shieldLevel, shieldReduction)
	else
		title.Text = "SHOP | ??? NO SHIELD"
	end

	-- ? Actualizar estilo de pestañas (activa vs inactiva)
	for categoryName, tabBtn in pairs(tabButtons) do
		if categoryName == currentTab then
			tabBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 60)
			tabBtn.BackgroundTransparency = 0
			tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tabBtn.Parent.BorderColor3 = Color3.fromRGB(0, 255, 100)
		else
			tabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			tabBtn.BackgroundTransparency = 0.3
			tabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
		end
	end

	-- ? Mostrar solo upgrades de la categoría activa
	local layoutOrder = 0
	for _, category in ipairs(CATEGORIES) do
		if category.name == currentTab then
			for _, upgId in ipairs(category.upgrades) do
				local infoU = st.UpgradesInfo and st.UpgradesInfo[upgId]
				if infoU then
					local btn = buttons[upgId] or makeRow(upgId)
					btn.LayoutOrder = layoutOrder
					btn.Visible = true
					layoutOrder = layoutOrder + 1

					local count = tonumber(infoU.Count) or 0
					local maxCount = infoU.MaxCount

					local label = string.format("%s | %s | x%d",
						tostring(infoU.Title or upgId),
						fmtMoney(infoU.Price or 0),
						count
					)

					-- Info especial para shields
					if upgId == "Upgrade_6" then
						local nextReduction = (shieldLevel + 1) * 18
						label = label .. string.format(" (L%d ? -%d%%)", shieldLevel, nextReduction)
					end

					if maxCount and count >= maxCount then
						label = label .. " [MAX]"
					end

					btn.Text = label
				end
			end
		else
			-- Ocultar botones de otras categorías
			for _, upgId in ipairs(category.upgrades) do
				if buttons[upgId] then
					buttons[upgId].Visible = false
				end
			end
		end
	end
end

-- Toggle con G
local open = true
local function setOpen(v: boolean)
	open = v
	frame.Visible = open
	shopShadow.Visible = open
end
setOpen(true)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G then
		setOpen(not open)
	end
end)

-- Loop de refresco
task.spawn(function()
	while true do
		refreshAll()
		task.wait(1)
	end
end)

refreshAll()