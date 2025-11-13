--!strict
--[[
	SHOP CLIENT - Apocalypse Tycoon v2.0
	MEJORAS:
	- Sistema de tabs por categoría (Income, Defense, Utility)
	- Colores por categoría
	- Descripción de upgrades en tooltip
	- Límites visuales de MaxCount
	- ScrollingFrame para muchos upgrades
	- Feedback visual mejorado
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction
local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent

-------------------------------------------------------------------------
-- CONFIGURACIÓN
-------------------------------------------------------------------------
local CONFIG = {
	Colors = {
		Income = {
			Button = Color3.fromRGB(60, 150, 60),
			Background = Color3.fromRGB(40, 100, 40),
			Hover = Color3.fromRGB(80, 170, 80),
		},
		Defense = {
			Button = Color3.fromRGB(60, 100, 180),
			Background = Color3.fromRGB(40, 70, 130),
			Hover = Color3.fromRGB(80, 120, 200),
		},
		Utility = {
			Button = Color3.fromRGB(150, 60, 150),
			Background = Color3.fromRGB(100, 40, 100),
			Hover = Color3.fromRGB(170, 80, 170),
		},
		Default = {
			Button = Color3.fromRGB(70, 70, 70),
			Background = Color3.fromRGB(35, 35, 35),
			Hover = Color3.fromRGB(90, 90, 90),
		},
	},
	Sounds = {
		Purchase = "rbxassetid://17208380755",
		Fail = "rbxassetid://2390695935",
		MaxReached = "rbxassetid://1847058585",
	},
}

-------------------------------------------------------------------------
-- UI ROOT
-------------------------------------------------------------------------
local gui = script.Parent :: ScreenGui

-- Panel principal
local frame = Instance.new("Frame")
frame.Name = "ShopFrame"
frame.AnchorPoint = Vector2.new(0, 0)
frame.Position = UDim2.new(0, 20, 0, 100)
frame.Size = UDim2.fromOffset(320, 450)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = gui

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 12)

-------------------------------------------------------------------------
-- ?? EFECTOS VISUALES
-------------------------------------------------------------------------

-- ?? Partículas verdes de fondo
local particlesFrame = Instance.new("Frame")
particlesFrame.Name = "ParticlesBackground"
particlesFrame.Size = UDim2.fromScale(1, 1)
particlesFrame.Position = UDim2.fromScale(0, 0)
particlesFrame.BackgroundTransparency = 1
particlesFrame.ZIndex = 0
particlesFrame.Parent = frame

-- Crear partículas flotantes
local function createParticle()
	local particle = Instance.new("Frame")
	particle.Size = UDim2.fromOffset(math.random(2, 5), math.random(2, 5))
	particle.Position = UDim2.new(
		math.random(0, 100) / 100,
		0,
		math.random(0, 100) / 100,
		0
	)
	particle.BackgroundColor3 = Color3.fromRGB(
		math.random(100, 200),
		255,
		math.random(100, 200)
	)
	particle.BackgroundTransparency = math.random(40, 70) / 100
	particle.BorderSizePixel = 0
	particle.Parent = particlesFrame

	local corner = Instance.new("UICorner", particle)
	corner.CornerRadius = UDim.new(1, 0)

	-- Animación de movimiento
	task.spawn(function()
		while particle.Parent do
			local duration = math.random(3, 6)
			local newPos = UDim2.new(
				math.random(0, 100) / 100,
				0,
				math.random(0, 100) / 100,
				0
			)

			local tween = TweenService:Create(
				particle,
				TweenInfo.new(duration, Enum.EasingStyle.Linear),
				{Position = newPos, BackgroundTransparency = 0.9}
			)
			tween:Play()
			tween.Completed:Wait()

			-- Reset opacity
			particle.BackgroundTransparency = math.random(40, 70) / 100
			task.wait(0.1)
		end
	end)

	return particle
end

-- Generar 15 partículas
for i = 1, 15 do
	task.spawn(function()
		task.wait(i * 0.1)
		createParticle()
	end)
end

-- ?? Efecto de bounce al abrir
local originalPosition = frame.Position
local function playBounceAnimation()
	frame.Position = UDim2.new(0, 20, 0, 50)  -- Start más arriba
	frame.Size = UDim2.fromOffset(280, 400)   -- Start más pequeño

	-- Bounce in
	local bounceTween = TweenService:Create(
		frame,
		TweenInfo.new(
			0.6,
			Enum.EasingStyle.Bounce,
			Enum.EasingDirection.Out
		),
		{
			Position = originalPosition,
			Size = UDim2.fromOffset(320, 450)
		}
	)
	bounceTween:Play()
end

-- Ejecutar bounce al inicio
playBounceAnimation()

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.Text = "?? APOCALYPSE SHOP"
title.TextStrokeTransparency = 0.8
title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
title.Parent = frame

-- Efecto de pulso en el título
task.spawn(function()
	while true do
		for i = 1, 20 do
			title.TextTransparency = 0.1 + (math.sin(i / 10) * 0.1)
			task.wait(0.05)
		end
	end
end)

-- Info de Cash/IPS
local info = Instance.new("TextLabel")
info.Name = "Info"
info.Size = UDim2.new(1, -20, 0, 25)
info.Position = UDim2.fromOffset(10, 48)
info.BackgroundTransparency = 1
info.Font = Enum.Font.Gotham
info.TextSize = 14
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextColor3 = Color3.fromRGB(200, 200, 200)
info.Text = "Cash: $0 | IPS: 0/s"
info.Parent = frame

-------------------------------------------------------------------------
-- SISTEMA DE TABS
-------------------------------------------------------------------------
local tabsFrame = Instance.new("Frame")
tabsFrame.Name = "Tabs"
tabsFrame.Position = UDim2.fromOffset(10, 80)
tabsFrame.Size = UDim2.new(1, -20, 0, 35)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = frame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabsFrame

local currentTab = "Income"
local tabs = {}

local function createTab(name: string, order: number)
	local colors = CONFIG.Colors[name] or CONFIG.Colors.Default

	local btn = Instance.new("TextButton")
	btn.Name = name .. "Tab"
	btn.LayoutOrder = order
	btn.Size = UDim2.fromOffset(90, 35)
	btn.BackgroundColor3 = colors.Background
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = name:upper()
	btn.AutoButtonColor = false
	btn.Parent = tabsFrame

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 8)

	-- Indicador activo
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(1, -8, 0, 3)
	indicator.Position = UDim2.new(0, 4, 1, -5)
	indicator.BackgroundColor3 = colors.Button
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = btn

	local indCorner = Instance.new("UICorner", indicator)
	indCorner.CornerRadius = UDim.new(1, 0)

	tabs[name] = btn
	return btn
end

-- Crear tabs
local incomeTab = createTab("Income", 1)
local defenseTab = createTab("Defense", 2)
local utilityTab = createTab("Utility", 3)

-------------------------------------------------------------------------
-- SCROLLING FRAME PARA UPGRADES
-------------------------------------------------------------------------
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "UpgradesList"
scrollFrame.Position = UDim2.fromOffset(10, 125)
scrollFrame.Size = UDim2.new(1, -20, 1, -135)
scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scrollFrame.BackgroundTransparency = 0.5
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.CanvasSize = UDim2.fromScale(1, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = frame

local scrollCorner = Instance.new("UICorner", scrollFrame)
scrollCorner.CornerRadius = UDim.new(0, 8)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrollFrame

-------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------
local function fmtMoney(n: any): string
	local x = tonumber(n) or 0
	if x >= 1e9 then return string.format("$%.2fB", x/1e9) end
	if x >= 1e6 then return string.format("$%.1fM", x/1e6) end
	if x >= 1e3 then return string.format("$%.1fK", x/1e3) end
	return "$" .. tostring(math.floor(x))
end

local function playSound(soundId: string, volume: number?)
	local sound = Instance.new("Sound", workspace)
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 2)
end

local function fetchState()
	local ok, st = pcall(function()
		return RequestState:InvokeServer()
	end)

	if not ok then
		return {
			Cash = 0,
			IncomePerSec = 0,
			UpgradesInfo = {},
			ShieldLevel = 0,
		}
	end

	return st
end

-------------------------------------------------------------------------
-- UPGRADE BUTTONS
-------------------------------------------------------------------------
local buttons: {[string]: Frame} = {}

local function createUpgradeButton(upgId: string, info: any): Frame
	local category = info.Category or "Income"
	local colors = CONFIG.Colors[category] or CONFIG.Colors.Default

	local container = Instance.new("Frame")
	container.Name = upgId
	container.Size = UDim2.new(1, -12, 0, 70)
	container.BackgroundColor3 = colors.Background
	container.BorderSizePixel = 0
	container.Parent = scrollFrame

	local corner = Instance.new("UICorner", container)
	corner.CornerRadius = UDim.new(0, 8)

	-- Botón de compra
	local btn = Instance.new("TextButton")
	btn.Name = "BuyButton"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = container

	-- Icono de categoría
	local categoryIcon = Instance.new("TextLabel")
	categoryIcon.Size = UDim2.fromOffset(50, 50)
	categoryIcon.Position = UDim2.fromOffset(10, 10)
	categoryIcon.BackgroundColor3 = colors.Button
	categoryIcon.TextColor3 = Color3.new(1, 1, 1)
	categoryIcon.Font = Enum.Font.GothamBlack
	categoryIcon.TextSize = 24
	categoryIcon.Text = (category == "Income" and "??") or (category == "Defense" and "???") or "??"
	categoryIcon.Parent = container

	local iconCorner = Instance.new("UICorner", categoryIcon)
	iconCorner.CornerRadius = UDim.new(0, 8)

	-- Nombre del upgrade
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -160, 0, 20)
	nameLabel.Position = UDim2.fromOffset(70, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = info.Title or upgId
	nameLabel.Parent = container

	-- Descripción
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(1, -160, 0, 15)
	descLabel.Position = UDim2.fromOffset(70, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 11
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	descLabel.Text = info.Description or ""
	descLabel.TextTruncate = Enum.TextTruncate.AtEnd
	descLabel.Parent = container

	-- Precio
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(1, -160, 0, 18)
	priceLabel.Position = UDim2.fromOffset(70, 46)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 13
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.TextColor3 = colors.Button
	priceLabel.Text = fmtMoney(info.Price or 0)
	priceLabel.Parent = container

	-- Contador
	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "CountLabel"
	countLabel.Size = UDim2.fromOffset(80, 50)
	countLabel.Position = UDim2.new(1, -90, 0, 10)
	countLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 16
	countLabel.TextColor3 = Color3.new(1, 1, 1)
	countLabel.Text = string.format("x%d", info.Count or 0)
	countLabel.Parent = container

	local countCorner = Instance.new("UICorner", countLabel)
	countCorner.CornerRadius = UDim.new(0, 6)

	-- MaxCount indicator
	if info.MaxCount then
		local maxLabel = Instance.new("TextLabel")
		maxLabel.Name = "MaxLabel"
		maxLabel.Size = UDim2.new(1, 0, 0, 12)
		maxLabel.Position = UDim2.new(0, 0, 1, -14)
		maxLabel.BackgroundTransparency = 1
		maxLabel.Font = Enum.Font.Gotham
		maxLabel.TextSize = 9
		maxLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		maxLabel.Text = string.format("Max: %d", info.MaxCount)
		maxLabel.Parent = countLabel
	end

	-- Hover effect
	btn.MouseEnter:Connect(function()
		local tween = TweenService:Create(
			container,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{BackgroundColor3 = colors.Hover}
		)
		tween:Play()
	end)

	btn.MouseLeave:Connect(function()
		local tween = TweenService:Create(
			container,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{BackgroundColor3 = colors.Background}
		)
		tween:Play()
	end)

	-- Click handler
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
			playSound(CONFIG.Sounds.MaxReached, 0.3)

			-- Flash rojo
			local originalColor = container.BackgroundColor3
			container.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
			task.wait(0.1)
			container.BackgroundColor3 = originalColor

			return
		end

		-- Verificar dinero
		if cash >= price then
			RequestPurchase:FireServer(upgId)
			playSound(CONFIG.Sounds.Purchase, 0.5)

			-- ?? EFECTO DE PARTÍCULAS AL COMPRAR
			for i = 1, 12 do
				task.spawn(function()
					local particle = Instance.new("Frame")
					particle.Size = UDim2.fromOffset(6, 6)
					particle.Position = UDim2.fromScale(0.5, 0.5)
					particle.AnchorPoint = Vector2.new(0.5, 0.5)
					particle.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
					particle.BorderSizePixel = 0
					particle.ZIndex = 10
					particle.Parent = container

					local corner = Instance.new("UICorner", particle)
					corner.CornerRadius = UDim.new(1, 0)

					-- Explotar en dirección aleatoria
					local angle = (i / 12) * math.pi * 2
					local distance = math.random(50, 100)
					local endPos = UDim2.new(
						0.5,
						math.cos(angle) * distance,
						0.5,
						math.sin(angle) * distance
					)

					local tween = TweenService:Create(
						particle,
						TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Position = endPos,
							Size = UDim2.fromOffset(2, 2),
							BackgroundTransparency = 1
						}
					)

					tween:Play()
					tween.Completed:Wait()
					particle:Destroy()
				end)
			end

			-- Flash verde
			local originalColor = container.BackgroundColor3
			container.BackgroundColor3 = colors.Button
			task.wait(0.1)
			container.BackgroundColor3 = originalColor

			-- Bounce del container
			local originalSize = container.Size
			container.Size = UDim2.new(1, -12, 0, 75)
			local bounce = TweenService:Create(
				container,
				TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
				{Size = originalSize}
			)
			bounce:Play()

			task.wait(0.1)
			refreshAll()
		else
			playSound(CONFIG.Sounds.Fail, 0.3)

			-- Flash rojo
			local originalColor = priceLabel.TextColor3
			priceLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
			task.wait(0.2)
			priceLabel.TextColor3 = originalColor
		end
	end)

	buttons[upgId] = container
	return container
end

-------------------------------------------------------------------------
-- SISTEMA DE TABS
-------------------------------------------------------------------------
local function updateTabIndicators()
	for name, tab in pairs(tabs) do
		local indicator = tab:FindFirstChild("Indicator")
		if indicator then
			indicator.Visible = (name == currentTab)
		end

		if name == currentTab then
			tab.TextSize = 14
		else
			tab.TextSize = 13
		end
	end
end

local function switchTab(newTab: string)
	currentTab = newTab
	updateTabIndicators()
	refreshAll()
end

incomeTab.MouseButton1Click:Connect(function() switchTab("Income") end)
defenseTab.MouseButton1Click:Connect(function() switchTab("Defense") end)
utilityTab.MouseButton1Click:Connect(function() switchTab("Utility") end)

-------------------------------------------------------------------------
-- REFRESH UI
-------------------------------------------------------------------------
function refreshAll()
	local st = fetchState()
	local cash = tonumber(st.Cash) or 0
	local ips = tonumber(st.IncomePerSec) or 0
	local shieldLevel = st.ShieldLevel or 0

	-- Actualizar header
	title.Text = string.format("?? SHOP | ??? Shield: L%d", shieldLevel)
	info.Text = string.format("?? Cash: %s | ?? IPS: %d/s", fmtMoney(cash), ips)

	-- Limpiar botones existentes
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	buttons = {}

	-- Crear botones de la categoría actual
	local upgrades = {}
	for upgId, info in pairs(st.UpgradesInfo or {}) do
		local category = info.Category or "Income"
		if category == currentTab then
			table.insert(upgrades, {id = upgId, info = info})
		end
	end

	-- Ordenar por IncomePerSec descendente (o por precio si no tienen income)
	table.sort(upgrades, function(a, b)
		local incomeA = a.info.IncomePerSec or 0
		local incomeB = b.info.IncomePerSec or 0

		if incomeA == incomeB then
			return (a.info.Price or 0) < (b.info.Price or 0)
		end

		return incomeA < incomeB
	end)

	-- Crear botones
	for i, upg in ipairs(upgrades) do
		local btn = createUpgradeButton(upg.id, upg.info)
		btn.LayoutOrder = i
	end
end

-------------------------------------------------------------------------
-- TOGGLE CON TECLA G
-------------------------------------------------------------------------
local open = true

local function setOpen(v: boolean)
	open = v

	if v then
		-- Aparecer con bounce
		frame.Visible = true
		playBounceAnimation()
	else
		-- Desaparecer con tween suave
		local fadeOut = TweenService:Create(
			frame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(0, 20, 0, 50),
				Size = UDim2.fromOffset(280, 400)
			}
		)

		fadeOut:Play()
		fadeOut.Completed:Wait()
		frame.Visible = false

		-- Reset posición para próxima apertura
		frame.Position = originalPosition
		frame.Size = UDim2.fromOffset(320, 450)
	end
end

setOpen(true)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G then
		setOpen(not open)
	end
end)

-------------------------------------------------------------------------
-- LOOP DE REFRESCO
-------------------------------------------------------------------------
task.spawn(function()
	while true do
		refreshAll()
		task.wait(1)
	end
end)

-- Inicializar
updateTabIndicators()
refreshAll()

print("[SHOP CLIENT] ? Shop cargado con sistema de tabs")