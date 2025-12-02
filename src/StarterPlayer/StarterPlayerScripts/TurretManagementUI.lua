--[[
	TurretManagementUI.lua
	═══════════════════════════════════════════════════════════════════════

	UI Module para gestión de torretas defensivas.

	FEATURES:
	- Panel visual con información de torreta
	- Botón de Upgrade (T1→T2→T3→T4→T5)
	- Selector de prioridad de targeting
	- Botón de venta (Sell) con confirmación
	- Muestra stats: Damage, Range, Fire Rate, etc.

	COMUNICACIÓN:
	- RemoteEvents hacia TurretService (server)
	- RemoteFunction para obtener info de torreta

	═══════════════════════════════════════════════════════════════════════
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpgradeTurretRemote = Remotes:WaitForChild("UpgradeTurret")
local ChangePriorityRemote = Remotes:WaitForChild("ChangeTurretPriority")
local SellTurretRemote = Remotes:WaitForChild("SellTurret")
local GetTurretInfoRemote = Remotes:WaitForChild("GetTurretInfo")

--[[────────────────────────────────────────────────────────────────────────
	MODULE DEFINITION
────────────────────────────────────────────────────────────────────────]]

local TurretManagementUI = {}

-- State
local currentObjectId: string? = nil
local currentTurretInfo: table? = nil
local mainFrame: Frame? = nil

--[[────────────────────────────────────────────────────────────────────────
	UI CREATION
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea el UI principal (se ejecuta una sola vez).
]]
local function createUI()
	if mainFrame then
		return -- Ya existe
	end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TurretManagementUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main Frame (Panel)
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

	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	header.BorderSizePixel = 0
	header.Text = "Turret Management"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextSize = 24
	header.Font = Enum.Font.GothamBold
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Close Button
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
		TurretManagementUI.CloseUI()
	end)

	-- Info Container
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

	-- Turret Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 30)
	nameLabel.Position = UDim2.new(0, 5, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Machine Gun T1"
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	nameLabel.TextSize = 20
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = infoContainer

	-- Stats Label
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

	-- Buttons Container
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(1, -20, 0, 200)
	buttonsContainer.Position = UDim2.new(0, 10, 0, 270)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = mainFrame

	-- Upgrade Button
	local upgradeButton = createButton("UpgradeButton", "Upgrade ($0)", UDim2.new(0, 0, 0, 0), Color3.fromRGB(50, 150, 50))
	upgradeButton.Parent = buttonsContainer
	upgradeButton.MouseButton1Click:Connect(function()
		TurretManagementUI.OnUpgradeClicked()
	end)

	-- Priority Button
	local priorityButton = createButton("PriorityButton", "Change Priority", UDim2.new(0, 0, 0, 60), Color3.fromRGB(50, 100, 200))
	priorityButton.Parent = buttonsContainer
	priorityButton.MouseButton1Click:Connect(function()
		TurretManagementUI.OnPriorityClicked()
	end)

	-- Sell Button
	local sellButton = createButton("SellButton", "Sell (50% refund)", UDim2.new(0, 0, 0, 120), Color3.fromRGB(200, 50, 50))
	sellButton.Parent = buttonsContainer
	sellButton.MouseButton1Click:Connect(function()
		TurretManagementUI.OnSellClicked()
	end)

	print("[TurretManagementUI] ✅ UI Created")
end

--[[
	Crea un botón estándar.
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

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

--[[────────────────────────────────────────────────────────────────────────
	UI LOGIC
────────────────────────────────────────────────────────────────────────]]

--[[
	Abre el UI para una torreta específica.

	@param objectId - ID de la torreta
]]
function TurretManagementUI.OpenTurretUI(objectId: string)
	if not mainFrame then
		createUI()
	end

	currentObjectId = objectId

	-- Obtener info de la torreta desde el servidor
	local turretInfo = GetTurretInfoRemote:InvokeServer(objectId)
	if not turretInfo then
		warn("[TurretManagementUI] ❌ Failed to get turret info for:", objectId)
		return
	end

	currentTurretInfo = turretInfo

	-- Actualizar UI con la info
	updateUI(turretInfo)

	-- Mostrar panel con animación
	mainFrame.Visible = true
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 500),
		Position = UDim2.new(0.5, -200, 0.5, -250)
	})
	tween:Play()

	print("[TurretManagementUI] ✅ Opened for turret:", objectId)
end

--[[
	Cierra el UI.
]]
function TurretManagementUI.CloseUI()
	if not mainFrame then
		return
	end

	local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		mainFrame.Visible = false
		currentObjectId = nil
		currentTurretInfo = nil
	end)

	print("[TurretManagementUI] ✅ Closed")
end

--[[
	Actualiza el UI con la info de la torreta.

	@param info - Tabla con info de la torreta
]]
local function updateUI(info: table)
	-- Actualizar nombre
	local nameLabel = mainFrame:FindFirstChild("InfoContainer"):FindFirstChild("NameLabel")
	nameLabel.Text = info.DisplayName

	-- Actualizar stats
	local statsLabel = mainFrame:FindFirstChild("InfoContainer"):FindFirstChild("StatsLabel")
	local statsText = string.format(
		"Damage: %s\nRange: %s studs\nFire Rate: %.2fs\nPriority: %s\n\nCurrent Tier: %s\n%s",
		tostring(info.Stats.Damage),
		tostring(info.Stats.Range),
		info.Stats.FireRate,
		info.Stats.TargetPriority,
		info.CurrentTier,
		info.CanUpgrade and "Can upgrade to: " .. info.NextTier or "MAX TIER"
	)
	statsLabel.Text = statsText

	-- Actualizar botón de upgrade
	local upgradeButton = mainFrame:FindFirstChild("ButtonsContainer"):FindFirstChild("UpgradeButton")
	if info.CanUpgrade then
		upgradeButton.Text = string.format("Upgrade to %s ($%d)", info.NextTier, info.UpgradeCost)
		upgradeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		upgradeButton.Active = true
	else
		upgradeButton.Text = "MAX TIER"
		upgradeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		upgradeButton.Active = false
	end
end

--[[────────────────────────────────────────────────────────────────────────
	BUTTON HANDLERS
────────────────────────────────────────────────────────────────────────]]

--[[
	Maneja clic en botón de Upgrade.
]]
function TurretManagementUI.OnUpgradeClicked()
	if not currentObjectId or not currentTurretInfo then
		return
	end

	if not currentTurretInfo.CanUpgrade then
		warn("[TurretManagementUI] ❌ Cannot upgrade (max tier)")
		return
	end

	print("[TurretManagementUI] 🔼 Requesting upgrade for:", currentObjectId)

	-- Enviar solicitud al servidor
	UpgradeTurretRemote:FireServer(currentObjectId)

	-- Cerrar UI (se reabrirá con nueva info si el jugador lo desea)
	TurretManagementUI.CloseUI()
end

--[[
	Maneja clic en botón de Priority.
]]
function TurretManagementUI.OnPriorityClicked()
	if not currentObjectId or not currentTurretInfo then
		return
	end

	-- TODO: Mostrar menú de prioridades (por ahora, rotar entre opciones)
	local priorities = {"Closest", "Furthest", "Strongest", "Weakest"}
	local currentPriority = currentTurretInfo.Stats.TargetPriority
	local currentIndex = 1

	for i, priority in ipairs(priorities) do
		if priority == currentPriority then
			currentIndex = i
			break
		end
	end

	-- Siguiente prioridad
	local nextIndex = (currentIndex % #priorities) + 1
	local newPriority = priorities[nextIndex]

	print("[TurretManagementUI] 🎯 Changing priority to:", newPriority)

	-- Enviar solicitud al servidor
	ChangePriorityRemote:FireServer(currentObjectId, newPriority)

	-- Actualizar UI local inmediatamente
	currentTurretInfo.Stats.TargetPriority = newPriority
	updateUI(currentTurretInfo)
end

--[[
	Maneja clic en botón de Sell.
]]
function TurretManagementUI.OnSellClicked()
	if not currentObjectId or not currentTurretInfo then
		return
	end

	-- TODO: Mostrar confirmación (por ahora, vender directamente)
	local refundAmount = math.floor(currentTurretInfo.Cost * 0.5)

	print(string.format("[TurretManagementUI] 💰 Selling turret (Refund: $%d)", refundAmount))

	-- Enviar solicitud al servidor
	SellTurretRemote:FireServer(currentObjectId)

	-- Cerrar UI
	TurretManagementUI.CloseUI()
end

--[[────────────────────────────────────────────────────────────────────────
	INITIALIZATION
────────────────────────────────────────────────────────────────────────]]

print("[TurretManagementUI] ✅ Module Loaded")

return TurretManagementUI
