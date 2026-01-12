--!strict
--[[
	GeneratorInteractionController - Sistema de interacción con generadores

	CARACTERÍSTICAS:
	- Menú de interacción SÚPER DIVERTIDO estilo cartoon/infantil 🎨
	- Colores vibrantes, animaciones bounce, efectos de brillo
	- Diseño optimizado para audiencia infantil
	- Sistema de upgrade y venta

	DISEÑO:
	- Fondo: Gradiente morado→azul brillante con borde neón
	- Header: Gradiente naranja→amarillo con sombra
	- Botones: Colores vibrantes con efectos hover animados
	- Iconos grandes y emojis divertidos

	AUTHOR: Generator Interaction System v3 (CARTOON EDITION!)
	CLIENT-SIDE: UI logic + communication con server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Knit)

-- RemoteEvents
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SellGeneratorRemote = Remotes:WaitForChild("SellGenerator")
local ActivateOverclockRemote = Remotes:WaitForChild("ActivateOverclock")

--[[────────────────────────────────────────────────────────────────────────
	TYPES & CONSTANTS
────────────────────────────────────────────────────────────────────────]]

local DEBUG_MODE = true

-- COLORES RADIOACTIVOS NEÓN ☢️💚💜
local COLORS = {
	-- Fondo principal (gradiente morado oscuro a verde radioactivo)
	BackgroundTop = Color3.fromRGB(80, 20, 140),       -- Morado oscuro profundo
	BackgroundBottom = Color3.fromRGB(20, 180, 80),    -- Verde radioactivo

	-- Header (gradiente morado brillante a magenta)
	HeaderTop = Color3.fromRGB(150, 50, 255),          -- Morado neón
	HeaderBottom = Color3.fromRGB(255, 50, 200),       -- Magenta brillante

	-- Info container (verde oscuro a verde neón)
	InfoTop = Color3.fromRGB(40, 150, 60),             -- Verde oscuro
	InfoBottom = Color3.fromRGB(100, 255, 150),        -- Verde neón claro

	-- Botones
	UpgradeGreen = Color3.fromRGB(50, 255, 50),        -- Verde radioactivo BRILLANTE
	UpgradeGreenDark = Color3.fromRGB(20, 200, 20),    -- Verde radioactivo oscuro
	OverclockYellow = Color3.fromRGB(255, 255, 50),    -- Amarillo eléctrico
	OverclockOrange = Color3.fromRGB(255, 150, 0),     -- Naranja eléctrico
	SellRed = Color3.fromRGB(255, 50, 255),            -- Magenta/fucsia
	SellRedDark = Color3.fromRGB(200, 20, 200),        -- Morado fucsia
	CloseRed = Color3.fromRGB(255, 0, 100),            -- Rosa neón intenso

	-- Bordes neón
	BorderNeon = Color3.fromRGB(0, 255, 150),          -- Verde neón brillante
	BorderPurple = Color3.fromRGB(200, 0, 255),        -- Morado neón INTENSO
	BorderYellow = Color3.fromRGB(200, 255, 0),        -- Amarillo-verde neón

	-- Texto
	TextWhite = Color3.new(1, 1, 1),
	TextGold = Color3.fromRGB(100, 255, 100),          -- Verde neón (en lugar de dorado)
	TextShadow = Color3.fromRGB(0, 0, 0),
}

--[[────────────────────────────────────────────────────────────────────────
	CONTROLLER
────────────────────────────────────────────────────────────────────────]]

local GeneratorInteractionController = Knit.CreateController({
	Name = "GeneratorInteractionController",
})

-- Estado del controller
local menuOpen = false
local currentGenerator: Model? = nil
local currentObjectId: string? = nil
local mainFrame: Frame? = nil
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local updateLoop: RBXScriptConnection? = nil

--[[────────────────────────────────────────────────────────────────────────
	UI HELPER FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un gradiente vertical
]]
local function createGradient(topColor: Color3, bottomColor: Color3): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	gradient.Rotation = 90  -- Vertical
	return gradient
end

--[[
	Crea un borde neón brillante
]]
local function createNeonStroke(color: Color3, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 4
	stroke.Transparency = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return stroke
end

--[[
	Crea una sombra para texto
]]
local function createTextShadow(textLabel: TextLabel)
	local shadow = Instance.new("UIStroke")
	shadow.Color = COLORS.TextShadow
	shadow.Thickness = 3
	shadow.Transparency = 0.5
	shadow.Parent = textLabel
end

--[[
	Crea un botón estilo cartoon con gradiente y efectos.
]]
local function createCartoonButton(name: string, text: string, emoji: string, position: UDim2, topColor: Color3, bottomColor: Color3, neonColor: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 60)  -- Más alto para ser más llamativo
	button.Position = position
	button.BackgroundColor3 = topColor
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.FredokaOne  -- Fuente divertida
	button.TextSize = 22
	button.TextColor3 = COLORS.TextWhite
	button.TextWrapped = true

	-- Texto con emoji GRANDE
	button.Text = string.format("%s  %s", emoji, text)

	-- Corner redondeado
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)  -- Más redondeado
	corner.Parent = button

	-- Gradiente
	local gradient = createGradient(topColor, bottomColor)
	gradient.Parent = button

	-- Borde neón
	local stroke = createNeonStroke(neonColor, 5)
	stroke.Parent = button

	-- Sombra en el texto
	createTextShadow(button)

	-- EFECTOS HOVER ANIMADOS 🎨
	local originalSize = button.Size
	local hoverTween: Tween? = nil

	button.MouseEnter:Connect(function()
		-- Cancelar tween anterior si existe
		if hoverTween then
			hoverTween:Cancel()
		end

		-- Crecer con animación Elastic
		hoverTween = TweenService:Create(
			button,
			TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{
				Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 70),
				BackgroundColor3 = Color3.new(
					math.min(topColor.R + 0.15, 1),
					math.min(topColor.G + 0.15, 1),
					math.min(topColor.B + 0.15, 1)
				)
			}
		)
		hoverTween:Play()

		-- Animar el borde para que brille más
		TweenService:Create(
			stroke,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Thickness = 7 }
		):Play()
	end)

	button.MouseLeave:Connect(function()
		-- Volver a tamaño original
		if hoverTween then
			hoverTween:Cancel()
		end

		hoverTween = TweenService:Create(
			button,
			TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{
				Size = originalSize,
				BackgroundColor3 = topColor
			}
		)
		hoverTween:Play()

		-- Reducir grosor del borde
		TweenService:Create(
			stroke,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Thickness = 5 }
		):Play()
	end)

	-- Efecto de "click" con animación
	button.MouseButton1Down:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 55) }
		):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(
			button,
			TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{ Size = originalSize }
		):Play()
	end)

	return button
end

--[[
	Muestra una notificación SÚPER DIVERTIDA en pantalla.
]]
local function showNotification(message: string, isSuccess: boolean)
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 450, 0, 80)
	notification.Position = UDim2.new(0.5, -225, 0.1, 0)
	notification.BackgroundColor3 = isSuccess and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
	notification.BorderSizePixel = 0
	notification.Parent = playerGui

	-- Corner redondeado
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = notification

	-- Borde neón
	local stroke = createNeonStroke(isSuccess and COLORS.BorderYellow or COLORS.BorderPurple, 6)
	stroke.Parent = notification

	-- Gradiente
	local gradient = createGradient(
		isSuccess and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150),
		isSuccess and Color3.fromRGB(100, 255, 200) or Color3.fromRGB(255, 100, 150)
	)
	gradient.Parent = notification

	-- Texto grande y bold
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 1, 0)
	label.Position = UDim2.new(0, 15, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = COLORS.TextWhite
	label.TextSize = 24
	label.Font = Enum.Font.FredokaOne
	label.TextWrapped = true
	label.Parent = notification

	-- Sombra en texto
	createTextShadow(label)

	-- Animación de entrada BOUNCE
	notification.Position = UDim2.new(0.5, -225, -0.15, 0)
	local tweenIn = TweenService:Create(
		notification,
		TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -225, 0.1, 0) }
	)
	tweenIn:Play()

	-- Auto-cerrar después de 3 segundos
	task.delay(3, function()
		local tweenOut = TweenService:Create(
			notification,
			TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{
				Position = UDim2.new(0.5, -225, -0.15, 0),
				Size = UDim2.new(0, 0, 0, 0)
			}
		)
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

--[[────────────────────────────────────────────────────────────────────────
	UI CREATION - DISEÑO CARTOON INFANTIL 🎨
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea el UI principal con diseño SÚPER DIVERTIDO para niños.
]]
local function createUI()
	if mainFrame then
		return -- Ya existe
	end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GeneratorManagementUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main Frame (Panel) - 420x540px (un poco más grande)
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 420, 0, 540)
	mainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
	mainFrame.BackgroundColor3 = COLORS.BackgroundTop
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- Gradiente de fondo morado→azul
	local bgGradient = createGradient(COLORS.BackgroundTop, COLORS.BackgroundBottom)
	bgGradient.Parent = mainFrame

	-- Corner MUY redondeado
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = mainFrame

	-- Borde neón CYAN
	local mainStroke = createNeonStroke(COLORS.BorderNeon, 6)
	mainStroke.Parent = mainFrame

	-- Header - Gradiente naranja→amarillo
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = COLORS.HeaderTop
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerGradient = createGradient(COLORS.HeaderTop, COLORS.HeaderBottom)
	headerGradient.Parent = header

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 20)
	headerCorner.Parent = header

	-- Borde del header
	local headerStroke = createNeonStroke(COLORS.BorderYellow, 4)
	headerStroke.Parent = header

	-- Título con emoji grande
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "⚡ Generator Control ⚡"
	title.TextColor3 = COLORS.TextWhite
	title.TextSize = 28
	title.Font = Enum.Font.FredokaOne
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = header

	-- Sombra en el título
	createTextShadow(title)

	-- Close Button - Botón X divertido
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -55, 0, 5)
	closeButton.BackgroundColor3 = COLORS.CloseRed
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✖"
	closeButton.TextColor3 = COLORS.TextWhite
	closeButton.TextSize = 28
	closeButton.Font = Enum.Font.FredokaOne
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(1, 0)  -- Circular
	closeCorner.Parent = closeButton

	local closeStroke = createNeonStroke(COLORS.BorderPurple, 4)
	closeStroke.Parent = closeButton

	-- Animación del botón close
	closeButton.MouseEnter:Connect(function()
		TweenService:Create(
			closeButton,
			TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 55, 0, 55), Rotation = 90 }
		):Play()
	end)

	closeButton.MouseLeave:Connect(function()
		TweenService:Create(
			closeButton,
			TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, 50, 0, 50), Rotation = 0 }
		):Play()
	end)

	closeButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:CloseMenu()
	end)

	-- Info Container - Gradiente rosa→cyan
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, -30, 0, 220)
	infoContainer.Position = UDim2.new(0, 15, 0, 75)
	infoContainer.BackgroundColor3 = COLORS.InfoTop
	infoContainer.BorderSizePixel = 0
	infoContainer.Parent = mainFrame

	local infoGradient = createGradient(COLORS.InfoTop, COLORS.InfoBottom)
	infoGradient.Parent = infoContainer

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 16)
	infoCorner.Parent = infoContainer

	local infoStroke = createNeonStroke(COLORS.BorderPurple, 4)
	infoStroke.Parent = infoContainer

	-- Icono grande del generador
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "IconLabel"
	iconLabel.Size = UDim2.new(0, 60, 0, 60)
	iconLabel.Position = UDim2.new(0, 10, 0, 10)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "⚙️"
	iconLabel.TextSize = 48
	iconLabel.Parent = infoContainer

	-- Animación del icono (girar suavemente)
	task.spawn(function()
		while true do
			TweenService:Create(
				iconLabel,
				TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
				{ Rotation = 360 }
			):Play()
			task.wait(2)
			iconLabel.Rotation = 0
		end
	end)

	-- Generator Name Label - Dorado brillante
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -90, 0, 35)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "🔥 Volcánico T1"
	nameLabel.TextColor3 = COLORS.TextGold
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = infoContainer

	createTextShadow(nameLabel)

	-- Stats Label - Texto grande y claro
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -20, 0, 120)
	statsLabel.Position = UDim2.new(0, 10, 0, 55)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Loading stats..."
	statsLabel.TextColor3 = COLORS.TextWhite
	statsLabel.TextSize = 20
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.Parent = infoContainer

	createTextShadow(statsLabel)

	-- Stability Bar Container (para Overclock system)
	local stabilityContainer = Instance.new("Frame")
	stabilityContainer.Name = "StabilityContainer"
	stabilityContainer.Size = UDim2.new(1, -20, 0, 30)
	stabilityContainer.Position = UDim2.new(0, 10, 0, 180)
	stabilityContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	stabilityContainer.BorderSizePixel = 0
	stabilityContainer.Parent = infoContainer

	local stabilityCorner = Instance.new("UICorner")
	stabilityCorner.CornerRadius = UDim.new(0, 8)
	stabilityCorner.Parent = stabilityContainer

	local stabilityStroke = createNeonStroke(COLORS.BorderYellow, 2)
	stabilityStroke.Parent = stabilityContainer

	-- Barra de estabilidad (fill bar)
	local stabilityBar = Instance.new("Frame")
	stabilityBar.Name = "StabilityBar"
	stabilityBar.Size = UDim2.new(1, 0, 1, 0)  -- Se ajustará dinámicamente
	stabilityBar.Position = UDim2.new(0, 0, 0, 0)
	stabilityBar.BackgroundColor3 = COLORS.OverclockYellow
	stabilityBar.BorderSizePixel = 0
	stabilityBar.Parent = stabilityContainer

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = stabilityBar

	local barGradient = createGradient(COLORS.OverclockYellow, COLORS.OverclockOrange)
	barGradient.Parent = stabilityBar

	-- Label de estabilidad
	local stabilityLabel = Instance.new("TextLabel")
	stabilityLabel.Name = "StabilityLabel"
	stabilityLabel.Size = UDim2.new(1, 0, 1, 0)
	stabilityLabel.Position = UDim2.new(0, 0, 0, 0)
	stabilityLabel.BackgroundTransparency = 1
	stabilityLabel.Text = "⚡ Stability: 100%"
	stabilityLabel.TextColor3 = COLORS.TextWhite
	stabilityLabel.TextSize = 16
	stabilityLabel.Font = Enum.Font.GothamBold
	stabilityLabel.ZIndex = 2
	stabilityLabel.Parent = stabilityContainer

	createTextShadow(stabilityLabel)

	-- Buttons Container
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, -30, 0, 280)
	buttonsContainer.Position = UDim2.new(0, 15, 0, 310)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = mainFrame

	-- Upgrade Button - Verde neón brillante
	local upgradeButton = createCartoonButton(
		"UpgradeButton",
		"UPGRADE!",
		"⬆️",
		UDim2.new(0, 0, 0, 0),
		COLORS.UpgradeGreen,
		COLORS.UpgradeGreenDark,
		COLORS.BorderYellow
	)
	upgradeButton.Parent = buttonsContainer
	upgradeButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:OnUpgradeClicked()
	end)

	-- Overclock Button - Amarillo eléctrico SÚPER LLAMATIVO
	local overclockButton = createCartoonButton(
		"OverclockButton",
		"⚡ OVERCLOCK! (+200%)",
		"⚡",
		UDim2.new(0, 0, 0, 75),
		COLORS.OverclockYellow,
		COLORS.OverclockOrange,
		COLORS.BorderYellow
	)
	overclockButton.Parent = buttonsContainer
	overclockButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:OnOverclockClicked()
	end)

	-- Sell Button - Rosa/rojo vibrante
	local sellButton = createCartoonButton(
		"SellButton",
		"SELL (50% back!)",
		"💰",
		UDim2.new(0, 0, 0, 150),
		COLORS.SellRed,
		COLORS.SellRedDark,
		COLORS.BorderPurple
	)
	sellButton.Parent = buttonsContainer
	sellButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:OnSellClicked()
	end)

	-- Fun Fact Button - Botón extra para diversión
	local funButton = createCartoonButton(
		"FunButton",
		"VIEW STATS",
		"📊",
		UDim2.new(0, 0, 0, 225),
		Color3.fromRGB(100, 150, 255),
		Color3.fromRGB(50, 100, 255),
		COLORS.BorderNeon
	)
	funButton.Parent = buttonsContainer
	funButton.MouseButton1Click:Connect(function()
		-- Mostrar stats extra
		showNotification("💡 This generator is producing money while you play! Keep upgrading!", true)
	end)

	print("[GeneratorInteractionController] 🎨✨ CARTOON UI Created!")
end

--[[────────────────────────────────────────────────────────────────────────
	UI LOGIC
────────────────────────────────────────────────────────────────────────]]

--[[
	Actualiza la UI con los datos del generador.
]]
local function updateUI(generatorInfo: any)
	if not mainFrame then
		return
	end

	local infoContainer = mainFrame:FindFirstChild("InfoContainer") :: Frame
	if not infoContainer then
		return
	end

	-- Actualizar nombre con emoji
	local nameLabel = infoContainer:FindFirstChild("NameLabel") :: TextLabel
	if nameLabel and generatorInfo.Name then
		-- Emojis según tier
		local tierEmojis = {"🔥", "⚡", "💎", "☢️", "🌟"}
		local tier = generatorInfo.Stats.Tier or 1
		local emoji = tierEmojis[tier] or "⚙️"
		nameLabel.Text = string.format("%s %s", emoji, generatorInfo.Name)
	end

	-- Actualizar stats con formato divertido
	local statsLabel = infoContainer:FindFirstChild("StatsLabel") :: TextLabel
	if statsLabel then
		local stats = generatorInfo.Stats or {}
		local uptimeMinutes = math.floor((stats.Uptime or 0) / 60)
		local uptimeSeconds = (stats.Uptime or 0) % 60

		-- Verificar si Overclock está activo
		local overclockData = generatorInfo.Overclock or {}
		local isOverclocked = overclockData.IsActive or false
		local baseIncome = stats.IncomeRate or 0
		local currentIncome = baseIncome

		if isOverclocked then
			currentIncome = baseIncome * 3  -- +200% boost = 3x multiplier
		end

		-- Formato de stats con boost visual
		local incomeText = ""
		if isOverclocked then
			incomeText = string.format("💰 Making: $%d/s → $%d/s ⚡BOOSTED⚡", baseIncome, currentIncome)
		else
			incomeText = string.format("💰 Making: $%d per second!", baseIncome)
		end

		local statsText = string.format(
			"🎯 Tier %d\n%s\n📈 Total Made: $%.0f\n⏰ Running: %dm %ds",
			stats.Tier or 1,
			incomeText,
			stats.TotalProduced or 0,
			uptimeMinutes,
			uptimeSeconds
		)

		statsLabel.Text = statsText
	end

	-- Actualizar barra de estabilidad
	local stabilityContainer = infoContainer:FindFirstChild("StabilityContainer") :: Frame
	if stabilityContainer then
		local stabilityBar = stabilityContainer:FindFirstChild("StabilityBar") :: Frame
		local stabilityLabel = stabilityContainer:FindFirstChild("StabilityLabel") :: TextLabel

		local stability = generatorInfo.Overclock and generatorInfo.Overclock.Stability or 100

		if stabilityBar then
			local stabilityScale = math.max(0, math.min(1, stability / 100))
			stabilityBar.Size = UDim2.new(stabilityScale, 0, 1, 0)

			-- Cambiar color según estabilidad
			if stability > 70 then
				stabilityBar.BackgroundColor3 = COLORS.OverclockYellow
			elseif stability > 30 then
				stabilityBar.BackgroundColor3 = COLORS.OverclockOrange
			else
				stabilityBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)  -- Rojo si muy baja
			end
		end

		if stabilityLabel then
			stabilityLabel.Text = string.format("⚡ Stability: %d%%", stability)
		end
	end

	-- Actualizar botón de upgrade
	local buttonsContainer = mainFrame:FindFirstChild("ButtonsContainer") :: Frame
	if buttonsContainer then
		local upgradeButton = buttonsContainer:FindFirstChild("UpgradeButton") :: TextButton
		if upgradeButton then
			if generatorInfo.CanUpgrade then
				local upgradeInfo = generatorInfo.UpgradeInfo or {}
				upgradeButton.Text = string.format("⬆️  UPGRADE!\n💵 Cost: $%d → $%d/s",
					upgradeInfo.Cost or 0,
					upgradeInfo.NextIncome or 0
				)
				upgradeButton.BackgroundColor3 = COLORS.UpgradeGreen
			else
				upgradeButton.Text = "🏆  MAX TIER!\nYou're awesome!"
				upgradeButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)  -- Dorado
			end
		end

		-- Actualizar botón de Overclock
		local overclockButton = buttonsContainer:FindFirstChild("OverclockButton") :: TextButton
		if overclockButton then
			local overclockData = generatorInfo.Overclock or {}
			local isActive = overclockData.IsActive or false
			local cooldownRemaining = overclockData.CooldownRemaining or 0

			-- Calcular costo basado en tier
			local tier = generatorInfo.Stats.Tier or 1
			local overclockCost = 500 * tier  -- $500, $1000, $1500, $2000, $2500

			if isActive then
				overclockButton.Text = "⚡ OVERCLOCKED!\n🔥 ACTIVE!"
				overclockButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)  -- Naranja intenso
			elseif cooldownRemaining > 0 then
				overclockButton.Text = string.format("⏰ COOLDOWN\n%ds remaining", math.ceil(cooldownRemaining))
				overclockButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)  -- Gris
			else
				overclockButton.Text = string.format("⚡ OVERCLOCK! (+200%%)\n💵 Cost: $%d", overclockCost)
				overclockButton.BackgroundColor3 = COLORS.OverclockYellow
			end
		end
	end
end

--[[────────────────────────────────────────────────────────────────────────
	MENU LOGIC
────────────────────────────────────────────────────────────────────────]]

--[[
	Obtiene los datos frescos del generador actual para actualizar el UI.
]]
local function getGeneratorInfo(): any?
	if not currentGenerator or not currentObjectId then
		return nil
	end

	local mainPart = currentGenerator:FindFirstChild("MainPart")
	if not mainPart then
		return nil
	end

	-- Obtener valores básicos
	local tierValue = mainPart:FindFirstChild("Tier")
	local moneyPerSecValue = mainPart:FindFirstChild("MoneyPerSec")
	local totalProducedValue = mainPart:FindFirstChild("TotalProduced")
	local spawnTimeValue = mainPart:FindFirstChild("SpawnTime")
	local nameTag = mainPart:FindFirstChild("NameTag")

	local tier = tierValue and tierValue.Value or 1
	local moneyPerSec = moneyPerSecValue and moneyPerSecValue.Value or 0
	local totalProduced = totalProducedValue and totalProducedValue.Value or 0
	local spawnTime = spawnTimeValue and spawnTimeValue.Value or os.time()
	local uptime = os.time() - spawnTime

	local generatorName = "Unknown Generator"
	if nameTag and nameTag:IsA("BillboardGui") then
		local label = nameTag:FindFirstChild("TextLabel")
		if label and label:IsA("TextLabel") then
			generatorName = label.Text
		end
	end

	-- Obtener upgrade info del servidor
	local UpgradeService = Knit.GetService("UpgradeService")
	local upgradeInfo = nil
	local canUpgrade = false

	local success, result = pcall(function()
		return UpgradeService:GetUpgradeInfo(currentObjectId)
	end)

	if success and result then
		upgradeInfo = {
			Cost = result.UpgradeCost,
			NextIncome = result.NextIncome,
		}
		canUpgrade = result.CanUpgrade
	end

	-- Obtener datos de Overclock del servidor (desde los attributes del MainPart)
	local overclockActive = mainPart:GetAttribute("OverclockActive") or false
	local overclockEndTime = mainPart:GetAttribute("OverclockEndTime") or 0
	local overclockCooldownEndTime = mainPart:GetAttribute("OverclockCooldownEndTime") or 0
	local stability = mainPart:GetAttribute("Stability") or 100

	local currentTime = tick()
	local cooldownRemaining = math.max(0, overclockCooldownEndTime - currentTime)

	return {
		Name = generatorName,
		Stats = {
			Tier = tier,
			IncomeRate = moneyPerSec,
			TotalProduced = totalProduced,
			Uptime = uptime,
		},
		CanUpgrade = canUpgrade,
		UpgradeInfo = upgradeInfo,
		Overclock = {
			IsActive = overclockActive,
			CooldownRemaining = cooldownRemaining,
			Stability = stability,
		},
	}
end

--[[
	Loop de actualización en tiempo real del menú (cada 0.5s).
]]
local function startMenuUpdateLoop()
	-- Detener loop anterior si existe
	if updateLoop then
		updateLoop:Disconnect()
		updateLoop = nil
	end

	-- Crear nuevo loop
	local lastUpdate = tick()
	updateLoop = game:GetService("RunService").Heartbeat:Connect(function()
		if not menuOpen or not mainFrame or not mainFrame.Visible then
			return
		end

		-- Actualizar cada 0.5 segundos
		local now = tick()
		if now - lastUpdate >= 0.5 then
			lastUpdate = now

			local generatorInfo = getGeneratorInfo()
			if generatorInfo then
				updateUI(generatorInfo)
			end
		end
	end)
end

--[[
	Abre el menú con animación BOUNCE divertida.
]]
function GeneratorInteractionController:OpenMenu(generator: Model, objectId: string)
	if not mainFrame then
		createUI()
	end

	if menuOpen then
		return
	end

	currentGenerator = generator
	currentObjectId = objectId
	menuOpen = true

	-- Obtener datos del generador (usando función auxiliar)
	local generatorInfo = getGeneratorInfo()
	if not generatorInfo then
		warn("[GeneratorInteractionController] Failed to get generator info")
		menuOpen = false
		currentGenerator = nil
		currentObjectId = nil
		return
	end

	-- Actualizar UI inicial
	updateUI(generatorInfo)

	-- Iniciar loop de actualización en tiempo real
	startMenuUpdateLoop()

	-- Mostrar panel con animación BOUNCE (más divertida que Back)
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Rotation = -15  -- Girado al inicio

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 540),
		Position = UDim2.new(0.5, -210, 0.5, -270),
		Rotation = 0
	})
	tween:Play()

	if DEBUG_MODE then
		print("[GeneratorInteractionController] 🎨 Cartoon menu opened!")
	end
end

--[[
	Cierra el menú con animación divertida.
]]
function GeneratorInteractionController:CloseMenu()
	if not mainFrame or not menuOpen then
		return
	end

	-- Detener loop de actualización
	if updateLoop then
		updateLoop:Disconnect()
		updateLoop = nil
	end

	-- Animación de cierre con rotación
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Rotation = 15
	})
	tween:Play()

	tween.Completed:Connect(function()
		mainFrame.Visible = false
		mainFrame.Rotation = 0
		currentObjectId = nil
		currentGenerator = nil
		menuOpen = false
	end)

	if DEBUG_MODE then
		print("[GeneratorInteractionController] 👋 Menu closed!")
	end
end

--[[────────────────────────────────────────────────────────────────────────
	BUTTON HANDLERS
────────────────────────────────────────────────────────────────────────]]

function GeneratorInteractionController:OnUpgradeClicked()
	if not currentObjectId then
		return
	end

	local generator = currentGenerator
	local objectId = currentObjectId

	print("[GeneratorInteractionController] 🔼 Requesting upgrade for:", objectId)

	local UpgradeService = Knit.GetService("UpgradeService")

	local success, result = pcall(function()
		return UpgradeService:UpgradeGenerator(objectId)
	end)

	if not success then
		warn("[GeneratorInteractionController] ❌ Upgrade request failed:", result)
		showNotification("❌ Oops! Upgrade failed! Try again!", false)
		return
	end

	if result then
		print("[GeneratorInteractionController] ✅ Upgrade successful!")
		showNotification("🎉 AWESOME! Generator upgraded!", true)

		self:CloseMenu()

		task.wait(0.15)

		if generator and generator.Parent then
			self:OpenMenu(generator, objectId)
			if DEBUG_MODE then
				print("[GeneratorInteractionController] 🔄 Menu re-opened!")
			end
		end
	else
		warn("[GeneratorInteractionController] ❌ Upgrade failed")
		showNotification("❌ Not enough money or max tier!", false)
	end
end

function GeneratorInteractionController:OnSellClicked()
	if not currentObjectId then
		return
	end

	local objectId = currentObjectId

	print("[GeneratorInteractionController] 💰 Selling generator:", objectId)

	-- Enviar solicitud al servidor via RemoteEvent
	SellGeneratorRemote:FireServer(objectId)

	-- Mostrar notificación y cerrar menú
	showNotification("💰 Generator sold! Money refunded!", true)

	-- Cerrar menú (el generador ya no existe)
	self:CloseMenu()
end

function GeneratorInteractionController:OnOverclockClicked()
	if not currentObjectId then
		return
	end

	local objectId = currentObjectId

	print("[GeneratorInteractionController] ⚡ Activating Overclock for:", objectId)

	-- Enviar solicitud al servidor via RemoteEvent
	ActivateOverclockRemote:FireServer(objectId)

	-- Mostrar notificación ÉPICA
	showNotification("⚡ OVERCLOCK ACTIVATED! +200% BOOST!", true)

	-- Mantener el menú abierto para ver el cambio en tiempo real
	-- (el servidor actualizará los valores de stability)
end

--[[────────────────────────────────────────────────────────────────────────
	INITIALIZATION
────────────────────────────────────────────────────────────────────────]]

function GeneratorInteractionController:KnitStart()
	createUI()

	-- Conectar RemoteEvent de Overheat para notificar al jugador
	local OverclockOverheatRemote = Remotes:WaitForChild("OverclockOverheat")
	OverclockOverheatRemote.OnClientEvent:Connect(function(objectId)
		-- Mostrar notificación DRAMÁTICA de overheat
		showNotification("🔥 GENERATOR OVERHEATED! System shutting down...", false)
		print("[GeneratorInteractionController] 🔥 Overheat notified for:", objectId)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			if menuOpen then
				self:CloseMenu()
			end
		end
	end)

	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") and descendant.Name == "InteractPrompt" then
			descendant.Triggered:Connect(function(player)
				if player ~= Players.LocalPlayer then
					return
				end

				local mainPart = descendant.Parent
				if mainPart and mainPart:IsA("BasePart") then
					local generator = mainPart.Parent
					if generator and generator:IsA("Model") then
						local objectIdValue = mainPart:FindFirstChild("ObjectId")
						if objectIdValue and objectIdValue:IsA("StringValue") then
							self:OpenMenu(generator, objectIdValue.Value)
						end
					end
				end
			end)
		end
	end)

	print("[GeneratorInteractionController] 🎨✨ CARTOON MODE ACTIVATED!")
end

function GeneratorInteractionController:KnitInit()
	-- Inicialización
end

return GeneratorInteractionController
