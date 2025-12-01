--!strict
--[[
	GeneratorInteractionController - Sistema de interacción con generadores

	CARACTERÍSTICAS:
	- Menú de interacción para generadores (View Stats / Upgrade)
	- Manejo de ProximityPrompt único (E key)
	- Display de stats del generador
	- Sistema de upgrade desde UI

	ARQUITECTURA DE UI:
	┌──────────────────────────────────────┐
	│ PlayerGui                            │
	│  └── GeneratorMenuUI (ScreenGui)    │
	│      └── MenuPanel (Frame)          │
	│          ├── Title (TextLabel)      │
	│          ├── ViewStatsButton        │
	│          ├── UpgradeButton          │
	│          └── CloseButton            │
	└──────────────────────────────────────┘

	FLUJO DE INTERACCIÓN:
	1. Usuario presiona E cerca del generador → Abrir menú
	2. Usuario clickea "View Stats" → Mostrar stats panel
	3. Usuario clickea "Upgrade" → Llamar UpgradeService
	4. Usuario clickea "Close" o ESC → Cerrar menú

	AUTHOR: Generator Interaction System v1
	CLIENT-SIDE: UI logic + communication con server
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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
local menuUI: ScreenGui? = nil
local statsPanel: Frame? = nil

--[[────────────────────────────────────────────────────────────────────────
	UI CREATION
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea la UI del menú de interacción si no existe.
]]
local function createMenuUI(): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Verificar si ya existe
	local existing = playerGui:FindFirstChild("GeneratorMenuUI")
	if existing then
		return existing :: ScreenGui
	end

	-- Crear ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GeneratorMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Panel principal (altura aumentada para acomodar upgrade button más grande)
	local menuPanel = Instance.new("Frame")
	menuPanel.Name = "MenuPanel"
	menuPanel.Size = UDim2.new(0, 300, 0, 280)
	menuPanel.Position = UDim2.new(0.5, -150, 0.5, -140)
	menuPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	menuPanel.BorderSizePixel = 2
	menuPanel.BorderColor3 = Color3.fromRGB(100, 100, 100)
	menuPanel.Visible = false
	menuPanel.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = menuPanel

	-- Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "⚙️ Generator Menu"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = menuPanel

	-- Función helper para crear botones
	local function createButton(name: string, text: string, icon: string, yOffset: number, height: number?): TextButton
		local buttonHeight = height or 50
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(1, -40, 0, buttonHeight)
		button.Position = UDim2.new(0, 20, 0, yOffset)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.BorderSizePixel = 0
		button.Text = icon .. " " .. text
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 18
		button.Font = Enum.Font.Gotham
		button.TextWrapped = true
		button.Parent = menuPanel

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 8)
		buttonCorner.Parent = button

		-- Hover effect
		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		end)
		button.MouseLeave:Connect(function()
			button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end)

		return button
	end

	-- Botón View Stats
	local viewStatsButton = createButton("ViewStatsButton", "View Stats", "📊", 60)

	-- Botón Upgrade (más alto para mostrar costo y beneficios)
	local upgradeButton = createButton("UpgradeButton", "Upgrade Generator", "⬆️", 120, 80)
	upgradeButton.TextSize = 15  -- Texto más pequeño para que quepa mejor

	-- Botón Close (movido hacia abajo para dar espacio al upgradeButton)
	local closeButton = createButton("CloseButton", "Close", "❌", 210)
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	end)

	if DEBUG_MODE then
		print("[GeneratorInteractionController] Menu UI created")
	end

	return screenGui
end

--[[
	Crea el panel de stats (similar al StatsBillboard pero en ScreenGui)
]]
local function createStatsPanel(): Frame
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Buscar o crear ScreenGui para stats
	local statsGui = playerGui:FindFirstChild("GeneratorStatsUI")
	if not statsGui then
		statsGui = Instance.new("ScreenGui")
		statsGui.Name = "GeneratorStatsUI"
		statsGui.ResetOnSpawn = false
		statsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		statsGui.Parent = playerGui
	end

	-- Panel de stats
	local panel = Instance.new("Frame")
	panel.Name = "StatsPanel"
	panel.Size = UDim2.new(0, 400, 0, 300)
	panel.Position = UDim2.new(0.5, -200, 0.5, -150)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 2
	panel.BorderColor3 = Color3.fromRGB(100, 200, 100)
	panel.Visible = false
	panel.Parent = statsGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	-- Texto de stats
	local statsText = Instance.new("TextLabel")
	statsText.Name = "StatsText"
	statsText.Size = UDim2.new(1, -40, 1, -80)
	statsText.Position = UDim2.new(0, 20, 0, 20)
	statsText.BackgroundTransparency = 1
	statsText.TextColor3 = Color3.new(1, 1, 1)
	statsText.TextSize = 20
	statsText.Font = Enum.Font.Code
	statsText.TextXAlignment = Enum.TextXAlignment.Left
	statsText.TextYAlignment = Enum.TextYAlignment.Top
	statsText.Text = "Loading stats..."
	statsText.Parent = panel

	-- Botón Close
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseStatsButton"
	closeButton.Size = UDim2.new(0, 150, 0, 40)
	closeButton.Position = UDim2.new(0.5, -75, 1, -50)
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "❌ Close"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = 18
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = panel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	return panel
end

--[[
	Muestra una notificación temporal en pantalla

	@param message - Mensaje a mostrar
	@param isSuccess - true para mensaje de éxito (verde), false para error (rojo)
]]
local function showNotification(message: string, isSuccess: boolean)
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Crear notificación
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
	local TweenService = game:GetService("TweenService")
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
	MENU LOGIC
────────────────────────────────────────────────────────────────────────]]

--[[
	Abre el menú de interacción del generador
]]
function GeneratorInteractionController:OpenMenu(generator: Model, objectId: string)
	if menuOpen then
		return
	end

	currentGenerator = generator
	currentObjectId = objectId
	menuOpen = true

	local menuPanel = menuUI:FindFirstChild("MenuPanel") :: Frame
	if menuPanel then
		menuPanel.Visible = true

		-- Actualizar botón de upgrade según tier y obtener info del servidor
		local upgradeButton = menuPanel:FindFirstChild("UpgradeButton") :: TextButton
		if upgradeButton then
			-- IMPORTANTE: Obtener UpgradeService antes de usarlo
			local UpgradeService = Knit.GetService("UpgradeService")

			-- Obtener información del upgrade desde el servidor
			print("[DEBUG] Calling GetUpgradeInfo for objectId:", objectId)
			local success, upgradeInfo = pcall(function()
				return UpgradeService:GetUpgradeInfo(objectId)
			end)

			print("[DEBUG] GetUpgradeInfo success:", success)
			print("[DEBUG] upgradeInfo:", upgradeInfo)

			if success and upgradeInfo then
				print("[DEBUG] upgradeInfo.CanUpgrade:", upgradeInfo.CanUpgrade)
				if not upgradeInfo.CanUpgrade then
					-- Max tier alcanzado
					upgradeButton.Text = "🏆 MAX TIER REACHED"
					upgradeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					upgradeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
				else
					-- Mostrar costo y beneficio del upgrade
					local costText = string.format("$%d", upgradeInfo.UpgradeCost)
					local benefitText = string.format("$%d/s → $%d/s", upgradeInfo.CurrentIncome, upgradeInfo.NextIncome)
					local buttonText = string.format("⬆️ Upgrade to Tier %d\n💰 Cost: %s\n📈 Income: %s",
						upgradeInfo.NextTier, costText, benefitText)
					print("[DEBUG] Setting button text to:", buttonText)
					upgradeButton.Text = buttonText
					upgradeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					upgradeButton.TextColor3 = Color3.new(1, 1, 1)
				end
			else
				-- Fallback si no se puede obtener info del servidor
				print("[DEBUG] Falling back to default text. Error:", upgradeInfo)
				upgradeButton.Text = "⬆️ Upgrade Generator"
				upgradeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				upgradeButton.TextColor3 = Color3.new(1, 1, 1)
			end
		end
	end

	if DEBUG_MODE then
		print("[GeneratorInteractionController] Menu opened for generator:", objectId)
	end
end

--[[
	Cierra el menú de interacción
]]
function GeneratorInteractionController:CloseMenu()
	if not menuOpen then
		return
	end

	menuOpen = false
	currentGenerator = nil
	currentObjectId = nil

	local menuPanel = menuUI:FindFirstChild("MenuPanel") :: Frame
	if menuPanel then
		menuPanel.Visible = false
	end

	-- Cerrar stats panel si está abierto
	if statsPanel and statsPanel.Visible then
		statsPanel.Visible = false
	end

	if DEBUG_MODE then
		print("[GeneratorInteractionController] Menu closed")
	end
end

--[[
	Muestra el panel de stats del generador
]]
function GeneratorInteractionController:ShowStats()
	if not currentGenerator or not statsPanel then
		return
	end

	-- IMPORTANTE: Guardar referencias ANTES de cerrar el menú
	-- (CloseMenu() setea currentGenerator = nil)
	local generator = currentGenerator
	local objectId = currentObjectId

	-- Cerrar el menú principal
	self:CloseMenu()

	-- Mostrar stats panel
	statsPanel.Visible = true

	-- Obtener datos del generador (usar referencia local, no currentGenerator)
	local mainPart = generator:FindFirstChild("MainPart")
	if not mainPart then
		warn("[GeneratorInteractionController] MainPart not found in generator")
		return
	end

	local tierValue = mainPart:FindFirstChild("Tier")
	local moneyPerSecValue = mainPart:FindFirstChild("MoneyPerSec")
	local totalProducedValue = mainPart:FindFirstChild("TotalProduced")
	local spawnTimeValue = mainPart:FindFirstChild("SpawnTime")

	local tier = tierValue and tierValue.Value or 1
	local moneyPerSec = moneyPerSecValue and moneyPerSecValue.Value or 0
	local totalProduced = totalProducedValue and totalProducedValue.Value or 0
	local spawnTime = spawnTimeValue and spawnTimeValue.Value or os.time()

	-- Calcular uptime
	local uptime = os.time() - spawnTime
	local uptimeMinutes = math.floor(uptime / 60)
	local uptimeSeconds = uptime % 60

	-- Nombre del tier
	local tierNames = {
		[1] = "Tier 1 Generator",
		[2] = "Tier 2 Generator",
		[3] = "Tier 3 Generator",
		[4] = "Tier 4 Nuclear",
		[5] = "Tier 5 Quantum (MAX)",
	}
	local tierName = tierNames[tier] or "Unknown Generator"

	-- Actualizar texto
	local statsText = statsPanel:FindFirstChild("StatsText") :: TextLabel
	if statsText then
		statsText.Text = string.format([[
⚙️ %s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 Income Rate: $%d/second
💵 Total Produced: $%.0f
⏱️ Uptime: %dm %ds
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ObjectID: %s
]], tierName, moneyPerSec, totalProduced, uptimeMinutes, uptimeSeconds, objectId or "Unknown")
	end

	if DEBUG_MODE then
		print("[GeneratorInteractionController] Stats displayed")
	end
end

--[[
	Solicita upgrade del generador al servidor via Knit RemoteFunction
]]
function GeneratorInteractionController:RequestUpgrade()
	if not currentObjectId then
		warn("[GeneratorInteractionController] Cannot upgrade: No generator selected")
		return
	end

	-- Guardar referencias ANTES de cerrar (para re-abrir después del upgrade)
	local generator = currentGenerator
	local objectId = currentObjectId

	-- Obtener UpgradeService del servidor (Knit lo maneja automáticamente)
	local UpgradeService = Knit.GetService("UpgradeService")

	-- Llamar al método Client del servidor (Knit usa RemoteFunctions síncronamente)
	-- IMPORTANTE: En Knit, Service.Client methods son síncronos, no Promises
	local success, result = pcall(function()
		return UpgradeService:UpgradeGenerator(objectId)
	end)

	if not success then
		-- Error en la llamada remota
		warn("[GeneratorInteractionController] ❌ Upgrade request failed:", result)
		showNotification("❌ Upgrade failed! Server error.", false)
		return
	end

	-- result contiene el valor booleano retornado por el servidor
	if result then
		print("[GeneratorInteractionController] ✅ Upgrade successful!")
		showNotification("✅ Generator upgraded successfully!", true)

		-- Cerrar menú
		self:CloseMenu()

		-- Re-abrir menú automáticamente después de un pequeño delay
		-- (para que el servidor tenga tiempo de actualizar el modelo)
		task.wait(0.15)

		-- Verificar que el generator sigue existiendo antes de re-abrir
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

--[[────────────────────────────────────────────────────────────────────────
	INITIALIZATION
────────────────────────────────────────────────────────────────────────]]

function GeneratorInteractionController:KnitStart()
	-- Crear UI
	menuUI = createMenuUI()
	statsPanel = createStatsPanel()

	-- Conectar botones del menú
	local menuPanel = menuUI:FindFirstChild("MenuPanel") :: Frame
	if menuPanel then
		local viewStatsButton = menuPanel:FindFirstChild("ViewStatsButton") :: TextButton
		if viewStatsButton then
			viewStatsButton.Activated:Connect(function()
				self:ShowStats()
			end)
		end

		local upgradeButton = menuPanel:FindFirstChild("UpgradeButton") :: TextButton
		if upgradeButton then
			upgradeButton.Activated:Connect(function()
				-- Verificar si puede upgradear
				if currentGenerator then
					local mainPart = currentGenerator:FindFirstChild("MainPart")
					if mainPart then
						local tierValue = mainPart:FindFirstChild("Tier")
						local currentTier = tierValue and tierValue.Value or 1
						if currentTier < 3 then
							self:RequestUpgrade()
						else
							print("[GeneratorInteractionController] Cannot upgrade: Max tier reached")
						end
					end
				end
			end)
		end

		local closeButton = menuPanel:FindFirstChild("CloseButton") :: TextButton
		if closeButton then
			closeButton.Activated:Connect(function()
				self:CloseMenu()
			end)
		end
	end

	-- Conectar botón de close del stats panel
	if statsPanel then
		local closeStatsButton = statsPanel:FindFirstChild("CloseStatsButton") :: TextButton
		if closeStatsButton then
			closeStatsButton.Activated:Connect(function()
				statsPanel.Visible = false
			end)
		end
	end

	-- Manejar tecla ESC para cerrar
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape then
			if menuOpen then
				self:CloseMenu()
			elseif statsPanel and statsPanel.Visible then
				statsPanel.Visible = false
			end
		end
	end)

	-- Escuchar ProximityPrompt.Triggered en todos los generadores
	-- (Esto se conectará cuando el servidor cree los generadores)
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
		print("[GeneratorInteractionController] Initialized successfully")
	end
end

function GeneratorInteractionController:KnitInit()
	-- Inicialización
end

return GeneratorInteractionController
