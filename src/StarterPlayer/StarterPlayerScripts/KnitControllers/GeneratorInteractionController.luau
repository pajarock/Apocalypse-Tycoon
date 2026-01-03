--!strict
--[[
	GeneratorInteractionController - Sistema de interacción con generadores

	CARACTERÍSTICAS:
	- Menú de interacción para generadores (idéntico al de torretas)
	- Manejo de ProximityPrompt único (E key)
	- Display de stats del generador
	- Sistema de upgrade desde UI
	- Sistema de venta con 50% refund

	ARQUITECTURA DE UI:
	┌──────────────────────────────────────┐
	│ PlayerGui                            │
	│  └── GeneratorManagementUI          │
	│      └── MainPanel (Frame)          │
	│          ├── Header                 │
	│          ├── CloseButton            │
	│          ├── InfoContainer          │
	│          │   ├── NameLabel          │
	│          │   └── StatsLabel         │
	│          └── ButtonsContainer       │
	│              ├── UpgradeButton      │
	│              └── SellButton         │
	└──────────────────────────────────────┘

	AUTHOR: Generator Interaction System v2 (diseño idéntico a TurretManagementUI)
	CLIENT-SIDE: UI logic + communication con server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Knit)

--[[────────────────────────────────────────────────────────────────────────
	TYPES & CONSTANTS
────────────────────────────────────────────────────────────────────────]]

local DEBUG_MODE = true

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

--[[────────────────────────────────────────────────────────────────────────
	UI HELPER FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un botón estándar con el estilo del TurretManagementUI.
]]
local function createButton(name: string, text: string, position: UDim2, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 50)
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		local lightenedColor = Color3.new(
			math.min(color.R + 0.1, 1),
			math.min(color.G + 0.1, 1),
			math.min(color.B + 0.1, 1)
		)
		button.BackgroundColor3 = lightenedColor
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = color
	end)

	return button
end

--[[
	Muestra una notificación temporal en pantalla.
]]
local function showNotification(message: string, isSuccess: boolean)
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 400, 0, 60)
	notification.Position = UDim2.new(0.5, -200, 0.1, 0)
	notification.BackgroundColor3 = isSuccess and Color3.fromRGB(30, 100, 30) or Color3.fromRGB(100, 30, 30)
	notification.BorderSizePixel = 2
	notification.BorderColor3 = isSuccess and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
	notification.Parent = playerGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notification

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Parent = notification

	-- Animación de entrada
	notification.Position = UDim2.new(0.5, -200, -0.1, 0)
	local tweenIn = TweenService:Create(
		notification,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -200, 0.1, 0) }
	)
	tweenIn:Play()

	-- Auto-cerrar después de 2.5 segundos
	task.delay(2.5, function()
		local tweenOut = TweenService:Create(
			notification,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, -200, -0.1, 0) }
		)
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

--[[────────────────────────────────────────────────────────────────────────
	UI CREATION (IDÉNTICO A TurretManagementUI)
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea el UI principal (se ejecuta una sola vez).
	DISEÑO IDÉNTICO a TurretManagementUI.lua
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

	-- Main Frame (Panel) - 400x500px, RGB(30, 30, 35)
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainPanel"
	mainFrame.Size = UDim2.new(0, 400, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	-- UICorner para bordes redondeados
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Header - 50px height, RGB(40, 40, 45)
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	header.BorderSizePixel = 0
	header.Text = "Generator Management"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextSize = 24
	header.Font = Enum.Font.GothamBold
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Close Button - 40x40px, RGB(200, 50, 50)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:CloseMenu()
	end)

	-- Info Container - 200px height, RGB(40, 40, 45)
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(1, -20, 0, 200)
	infoContainer.Position = UDim2.new(0, 10, 0, 60)
	infoContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	infoContainer.BorderSizePixel = 0
	infoContainer.Parent = mainFrame

	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 8)
	infoCorner.Parent = infoContainer

	-- Generator Name Label - RGB(255, 200, 100), 20px, GothamBold
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Volcánico T1"
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	nameLabel.TextSize = 20
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = infoContainer

	-- Stats Label - White, 16px, Gotham
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -10, 0, 160)
	statsLabel.Position = UDim2.new(0, 5, 0, 40)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = "Loading stats..."
	statsLabel.TextColor3 = Color3.new(1, 1, 1)
	statsLabel.TextSize = 16
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.Parent = infoContainer

	-- Buttons Container - at Y:270, 200px height
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, -20, 0, 200)
	buttonsContainer.Position = UDim2.new(0, 10, 0, 270)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = mainFrame

	-- Upgrade Button - RGB(50, 150, 50)
	local upgradeButton = createButton("UpgradeButton", "Upgrade ($0)", UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 150, 50))
	upgradeButton.Parent = buttonsContainer
	upgradeButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:OnUpgradeClicked()
	end)

	-- Sell Button - RGB(200, 50, 50) at Y:60
	local sellButton = createButton("SellButton", "Sell (50% refund)", UDim2.new(0, 0, 0, 60), Color3.fromRGB(200, 50, 50))
	sellButton.Parent = buttonsContainer
	sellButton.MouseButton1Click:Connect(function()
		GeneratorInteractionController:OnSellClicked()
	end)

	print("[GeneratorInteractionController] ✅ UI Created (diseño idéntico a TurretManagementUI)")
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

	-- Actualizar nombre
	local nameLabel = infoContainer:FindFirstChild("NameLabel") :: TextLabel
	if nameLabel and generatorInfo.Name then
		nameLabel.Text = generatorInfo.Name
	end

	-- Actualizar stats
	local statsLabel = infoContainer:FindFirstChild("StatsLabel") :: TextLabel
	if statsLabel then
		local stats = generatorInfo.Stats or {}
		local uptimeMinutes = math.floor((stats.Uptime or 0) / 60)
		local uptimeSeconds = (stats.Uptime or 0) % 60

		local statsText = string.format(
			"Tier: %d\nIncome: $%d/s\nTotal Produced: $%.0f\nUptime: %dm %ds",
			stats.Tier or 1,
			stats.IncomeRate or 0,
			stats.TotalProduced or 0,
			uptimeMinutes,
			uptimeSeconds
		)

		statsLabel.Text = statsText
	end

	-- Actualizar botón de upgrade
	local buttonsContainer = mainFrame:FindFirstChild("ButtonsContainer") :: Frame
	if buttonsContainer then
		local upgradeButton = buttonsContainer:FindFirstChild("UpgradeButton") :: TextButton
		if upgradeButton then
			if generatorInfo.CanUpgrade then
				local upgradeInfo = generatorInfo.UpgradeInfo or {}
				local costText = string.format("$%d", upgradeInfo.Cost or 0)
				local nextIncomeText = string.format("$%d/s", upgradeInfo.NextIncome or 0)
				upgradeButton.Text = string.format("Upgrade (Cost: %s → %s)", costText, nextIncomeText)
				upgradeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
				upgradeButton.TextColor3 = Color3.new(1, 1, 1)
			else
				upgradeButton.Text = "MAX TIER"
				upgradeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				upgradeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end
	end
end

--[[────────────────────────────────────────────────────────────────────────
	MENU LOGIC
────────────────────────────────────────────────────────────────────────]]

--[[
	Abre el menú de interacción del generador.
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

	-- Obtener datos del generador
	local mainPart = generator:FindFirstChild("MainPart")
	if not mainPart then
		warn("[GeneratorInteractionController] MainPart not found")
		return
	end

	-- Construir info del generador
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
		return UpgradeService:GetUpgradeInfo(objectId)
	end)

	if success and result then
		upgradeInfo = {
			Cost = result.UpgradeCost,
			NextIncome = result.NextIncome,
		}
		canUpgrade = result.CanUpgrade
	end

	local generatorInfo = {
		Name = generatorName,
		Stats = {
			Tier = tier,
			IncomeRate = moneyPerSec,
			TotalProduced = totalProduced,
			Uptime = uptime,
		},
		CanUpgrade = canUpgrade,
		UpgradeInfo = upgradeInfo,
	}

	-- Actualizar UI
	updateUI(generatorInfo)

	-- Mostrar panel con animación (idéntico a TurretManagementUI)
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 500),
		Position = UDim2.new(0.5, -200, 0.5, -250)
	})
	tween:Play()

	if DEBUG_MODE then
		print("[GeneratorInteractionController] ✅ Menu opened for:", objectId)
	end
end

--[[
	Cierra el menú de interacción.
]]
function GeneratorInteractionController:CloseMenu()
	if not mainFrame or not menuOpen then
		return
	end

	-- Animación de cierre (idéntico a TurretManagementUI)
	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		mainFrame.Visible = false
		currentObjectId = nil
		currentGenerator = nil
		menuOpen = false
	end)

	if DEBUG_MODE then
		print("[GeneratorInteractionController] ✅ Menu closed")
	end
end

--[[────────────────────────────────────────────────────────────────────────
	BUTTON HANDLERS
────────────────────────────────────────────────────────────────────────]]

--[[
	Maneja clic en botón de Upgrade.
]]
function GeneratorInteractionController:OnUpgradeClicked()
	if not currentObjectId then
		return
	end

	-- Guardar referencias ANTES de cerrar
	local generator = currentGenerator
	local objectId = currentObjectId

	print("[GeneratorInteractionController] 🔼 Requesting upgrade for:", objectId)

	-- Obtener UpgradeService
	local UpgradeService = Knit.GetService("UpgradeService")

	-- Llamar al método de upgrade
	local success, result = pcall(function()
		return UpgradeService:UpgradeGenerator(objectId)
	end)

	if not success then
		warn("[GeneratorInteractionController] ❌ Upgrade request failed:", result)
		showNotification("❌ Upgrade failed! Server error.", false)
		return
	end

	if result then
		print("[GeneratorInteractionController] ✅ Upgrade successful!")
		showNotification("✅ Generator upgraded successfully!", true)

		-- Cerrar menú
		self:CloseMenu()

		-- Re-abrir menú automáticamente después de un pequeño delay
		task.wait(0.15)

		if generator and generator.Parent then
			self:OpenMenu(generator, objectId)
			if DEBUG_MODE then
				print("[GeneratorInteractionController] 🔄 Menu re-opened with updated values")
			end
		end
	else
		warn("[GeneratorInteractionController] ❌ Upgrade failed (insufficient funds or max tier)")
		showNotification("❌ Upgrade failed! Not enough money or max tier reached.", false)
	end
end

--[[
	Maneja clic en botón de Sell.
]]
function GeneratorInteractionController:OnSellClicked()
	if not currentObjectId then
		return
	end

	local objectId = currentObjectId

	print("[GeneratorInteractionController] 💰 Requesting sell for:", objectId)

	-- Obtener BaseDataService
	local BaseDataService = Knit.GetService("BaseDataService")

	-- Llamar al método de venta (50% refund)
	local success, result = pcall(function()
		return BaseDataService:SellObject(objectId, 0.5)
	end)

	if not success then
		warn("[GeneratorInteractionController] ❌ Sell request failed:", result)
		showNotification("❌ Sell failed! Server error.", false)
		return
	end

	if result and result > 0 then
		print("[GeneratorInteractionController] ✅ Sell successful! Refund: $" .. result)
		showNotification(string.format("✅ Generator sold! Refunded: $%d", result), true)

		-- Cerrar menú (el generador ya no existe)
		self:CloseMenu()
	else
		warn("[GeneratorInteractionController] ❌ Sell failed (not owner or invalid object)")
		showNotification("❌ Sell failed! You don't own this generator.", false)
	end
end

--[[────────────────────────────────────────────────────────────────────────
	INITIALIZATION
────────────────────────────────────────────────────────────────────────]]

function GeneratorInteractionController:KnitStart()
	-- Crear UI
	createUI()

	-- Manejar tecla ESC para cerrar
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

	-- Escuchar ProximityPrompt.Triggered en todos los generadores
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") and descendant.Name == "InteractPrompt" then
			descendant.Triggered:Connect(function(player)
				if player ~= Players.LocalPlayer then
					return
				end

				-- Obtener el generador (parent del MainPart que contiene el prompt)
				local mainPart = descendant.Parent
				if mainPart and mainPart:IsA("BasePart") then
					local generator = mainPart.Parent
					if generator and generator:IsA("Model") then
						-- Obtener objectId
						local objectIdValue = mainPart:FindFirstChild("ObjectId")
						if objectIdValue and objectIdValue:IsA("StringValue") then
							self:OpenMenu(generator, objectIdValue.Value)
						end
					end
				end
			end)
		end
	end)

	if DEBUG_MODE then
		print("[GeneratorInteractionController] ✅ Initialized (diseño idéntico a TurretManagementUI)")
	end
end

function GeneratorInteractionController:KnitInit()
	-- Inicialización
end

return GeneratorInteractionController
