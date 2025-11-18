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

-- Panel principal con estilo urbano (✅ Más alto para categorías)
local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.Size = UDim2.fromOffset(280, 420) -- ✅ AUMENTADO: 320→420 para categorías
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Rotation = -1 -- Rotación sutil urbano
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)

-- Sombra pronunciada
local shopShadow = Instance.new("Frame")
shopShadow.Size = UDim2.fromOffset(286, 426) -- ✅ Ajustado a nuevo tamaño
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

-- ✅ ELIMINADO: Widget de income movido a CashIncomeWidget centralizado

local list = Instance.new("Frame")
list.Name = "List"
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(10, 50) -- Ajustado: más arriba sin el info widget
list.Size = UDim2.new(1, -20, 1, -60) -- Más espacio para la lista
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
local categoryHeaders: {[string]: TextLabel} = {}
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

-- ✅ NUEVO: Crear header de categoría
local function makeCategoryHeader(categoryName: string, emoji: string): TextLabel
	local header = Instance.new("TextLabel")
	header.Name = "Header_" .. categoryName
	header.Size = UDim2.new(1, 0, 0, 24)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	header.BackgroundTransparency = 0.3
	header.BorderSizePixel = 0
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.TextColor3 = Color3.fromRGB(255, 200, 80)
	header.Text = string.format("%s %s", emoji, categoryName:upper())
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextStrokeTransparency = 0.5
	header.ZIndex = 3
	header.Parent = list
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)

	-- Padding interno
	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingLeft = UDim.new(0, 8)
	headerPadding.Parent = header

	return header
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

-- ✅ NUEVO: Upgrades organizados por categoría
local CATEGORIES = {
	{ name = "Income", emoji = "💰", upgrades = {"Upgrade_1", "Upgrade_2", "Upgrade_3", "Upgrade_4", "Upgrade_5", "Upgrade_9"} },
	{ name = "Defense", emoji = "🛡️", upgrades = {"Upgrade_6", "Upgrade_7", "Upgrade_8"} },
	{ name = "Utility", emoji = "⚙️", upgrades = {"Upgrade_11", "Upgrade_10"} },
}

-- Refrescar UI
local function refreshAll()
	local st = fetchState()
	local cash = tonumber(st.Cash) or 0
	local ips = tonumber(st.IncomePerSec) or 0
	shieldLevel = st.ShieldLevel or 0

	-- ✅ FIX: Mostrar reducción de daño del shield actual (18% por nivel - BALANCEADO)
	local shieldReduction = shieldLevel * 18 -- ✅ BALANCEADO: 18% por nivel (antes 15%)
	if shieldLevel > 0 then
		title.Text = string.format("SHOP | 🛡️ L%d (-%d%%)", shieldLevel, shieldReduction)
	else
		title.Text = "SHOP | 🛡️ NO SHIELD"
	end

	-- ✅ NUEVO: Organizar por categorías
	local layoutOrder = 0
	for _, category in ipairs(CATEGORIES) do
		-- Crear/actualizar header de categoría
		local header = categoryHeaders[category.name]
		if not header then
			header = makeCategoryHeader(category.name, category.emoji)
			categoryHeaders[category.name] = header
		end
		header.LayoutOrder = layoutOrder
		layoutOrder = layoutOrder + 1

		-- Crear/actualizar botones de upgrades en esta categoría
		for _, upgId in ipairs(category.upgrades) do
			local infoU = st.UpgradesInfo and st.UpgradesInfo[upgId]
			if infoU then
				local btn = buttons[upgId] or makeRow(upgId)
				btn.LayoutOrder = layoutOrder
				layoutOrder = layoutOrder + 1

				local count = tonumber(infoU.Count) or 0
				local maxCount = infoU.MaxCount

				-- ✅ FIX: Mostrar más claramente el estado del upgrade
				local label = string.format("%s | %s | x%d",
					tostring(infoU.Title or upgId),
					fmtMoney(infoU.Price or 0),
					count
				)

				-- Agregar info especial para shields (18% por nivel - BALANCEADO)
				if upgId == "Upgrade_6" then
					local nextReduction = (shieldLevel + 1) * 18  -- ✅ BALANCEADO: 18% por nivel
					label = label .. string.format(" (L%d → -%d%%)", shieldLevel, nextReduction)
				end

				-- Mostrar si alcanzó el máximo
				if maxCount and count >= maxCount then
					label = label .. " [MAX]"
				end

				btn.Text = label
			end
		end
	end
end

-- Toggle con G
local open = true
local function setOpen(v: boolean)
	open = v
	frame.Visible = open
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