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

	-- Panel principal
	local menuPanel = Instance.new("Frame")
	menuPanel.Name = "MenuPanel"
	menuPanel.Size = UDim2.new(0, 300, 0, 250)
	menuPanel.Position = UDim2.new(0.5, -150, 0.5, -125)
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
	local function createButton(name: string, text: string, icon: string, yOffset: number): TextButton
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(1, -40, 0, 50)
		button.Position = UDim2.new(0, 20, 0, yOffset)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		button.BorderSizePixel = 0
		button.Text = icon .. " " .. text
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextSize = 18
		button.Font = Enum.Font.Gotham
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

	-- Botón Upgrade
	local upgradeButton = createButton("UpgradeButton", "Upgrade Generator", "⬆️", 120)

	-- Botón Close
	local closeButton = createButton("CloseButton", "Close", "❌", 180)
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

		-- Actualizar botón de upgrade según tier
		local mainPart = generator:FindFirstChild("MainPart")
		if mainPart then
			local tierValue = mainPart:FindFirstChild("Tier")
			local currentTier = tierValue and tierValue.Value or 1

			local upgradeButton = menuPanel:FindFirstChild("UpgradeButton") :: TextButton
			if upgradeButton then
				if currentTier >= 3 then
					upgradeButton.Text = "🏆 MAX TIER REACHED"
					upgradeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					upgradeButton.TextColor3 = Color3.fromRGB(150, 150, 150)
				else
					-- Obtener costo de upgrade (esto debería venir del servidor)
					local nextTier = currentTier + 1
					upgradeButton.Text = string.format("⬆️ Upgrade to Tier %d", nextTier)
					upgradeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					upgradeButton.TextColor3 = Color3.new(1, 1, 1)
				end
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

	-- Cerrar el menú principal
	self:CloseMenu()

	-- Mostrar stats panel
	statsPanel.Visible = true

	-- Obtener datos del generador
	local mainPart = currentGenerator:FindFirstChild("MainPart")
	if not mainPart then
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
		[3] = "Tier 3 Generator (MAX)",
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
]], tierName, moneyPerSec, totalProduced, uptimeMinutes, uptimeSeconds, currentObjectId or "Unknown")
	end

	if DEBUG_MODE then
		print("[GeneratorInteractionController] Stats displayed")
	end
end

--[[
	Solicita upgrade del generador al servidor
]]
function GeneratorInteractionController:RequestUpgrade()
	if not currentObjectId then
		warn("[GeneratorInteractionController] Cannot upgrade: No generator selected")
		return
	end

	-- TODO: Llamar al UpgradeService via RemoteEvent
	-- Por ahora, usar el método directo (temporalmente)
	local UpgradeService = Knit.GetService("UpgradeService")
	local success = UpgradeService:UpgradeGenerator(currentObjectId, Players.LocalPlayer.UserId)

	if success then
		print("[GeneratorInteractionController] ✅ Upgrade successful!")
		-- Cerrar menú
		self:CloseMenu()
	else
		warn("[GeneratorInteractionController] ❌ Upgrade failed")
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
