--!strict
--[[
	═══════════════════════════════════════════════════════════════════════
	POWERUP INVENTORY UI CLIENT
	═══════════════════════════════════════════════════════════════════════

	Sistema de inventario para powerups comprados en la máquina expendedora.

	FEATURES:
	✓ 5 slots de inventario
	✓ Click para usar powerups
	✓ Sincronización automática con servidor
	✓ Iconos y nombres de powerups

	═══════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UpdateInventory = Remotes:WaitForChild("UpdateInventory", 10) :: RemoteEvent?
local UseFromInventory = Remotes:WaitForChild("UseFromInventory", 10) :: RemoteEvent?

-- Config
local PowerUpConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("PowerUpConfig"))

-- Estado del inventario local
local CurrentInventory: {string} = {}

--═══════════════════════════════════════════════════════════════════════
-- CREAR GUI DE INVENTARIO
--═══════════════════════════════════════════════════════════════════════

local function createInventoryGUI(): ScreenGui
	-- ScreenGui principal
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PowerUpInventoryGUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Frame contenedor
	local container = Instance.new("Frame")
	container.Name = "InventoryContainer"
	container.Size = UDim2.new(0, 400, 0, 90)
	container.Position = UDim2.new(0.5, -200, 1, -120) -- Bottom center
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = screenGui

	-- UICorner para el contenedor
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 12)
	containerCorner.Parent = container

	-- UIStroke para bordes
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(100, 100, 150)
	containerStroke.Thickness = 2
	containerStroke.Transparency = 0.5
	containerStroke.Parent = container

	-- Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "🎁 POWERUP INVENTORY"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.Parent = container

	-- Frame para los slots
	local slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "SlotsFrame"
	slotsFrame.Size = UDim2.new(1, -20, 0, 50)
	slotsFrame.Position = UDim2.new(0, 10, 0, 30)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = container

	-- UIListLayout para organizar slots
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = slotsFrame

	-- Crear 5 slots
	for i = 1, 5 do
		local slot = Instance.new("TextButton")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 60, 0, 50)
		slot.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		slot.BorderSizePixel = 0
		slot.Text = ""
		slot.AutoButtonColor = false
		slot:SetAttribute("SlotIndex", i)
		slot.Parent = slotsFrame

		-- UICorner
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = slot

		-- UIStroke
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(80, 80, 120)
		stroke.Thickness = 2
		stroke.Transparency = 0.5
		stroke.Parent = slot

		-- Icon Label (emoji del powerup)
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 0.6, 0)
		icon.Position = UDim2.new(0, 0, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = "?"
		icon.TextSize = 20
		icon.Font = Enum.Font.GothamBold
		icon.TextColor3 = Color3.fromRGB(200, 200, 200)
		icon.Parent = slot

		-- Name Label (nombre del powerup)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
		nameLabel.Position = UDim2.new(0, 0, 0.6, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "Empty"
		nameLabel.TextSize = 8
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		nameLabel.TextScaled = true
		nameLabel.Parent = slot

		-- Click handler
		slot.MouseButton1Click:Connect(function()
			if UseFromInventory then
				UseFromInventory:FireServer(i)

				-- Efecto visual de click
				TweenService:Create(slot, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 80, 120)}):Play()
				task.wait(0.1)
				TweenService:Create(slot, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 60)}):Play()
			end
		end)

		-- Hover effects
		slot.MouseEnter:Connect(function()
			if CurrentInventory[i] then
				TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0, Color = Color3.fromRGB(150, 150, 255)}):Play()
			end
		end)

		slot.MouseLeave:Connect(function()
			TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.5, Color = Color3.fromRGB(80, 80, 120)}):Play()
		end)
	end

	return screenGui
end

--═══════════════════════════════════════════════════════════════════════
-- ACTUALIZAR SLOTS VISUALES
--═══════════════════════════════════════════════════════════════════════

local function updateSlots(inventory: {string})
	CurrentInventory = inventory

	local gui = playerGui:FindFirstChild("PowerUpInventoryGUI")
	if not gui then return end

	local slotsFrame = gui:FindFirstChild("InventoryContainer") and gui.InventoryContainer:FindFirstChild("SlotsFrame")
	if not slotsFrame then return end

	-- Actualizar cada slot
	for i = 1, 5 do
		local slot = slotsFrame:FindFirstChild("Slot" .. i)
		if slot then
			local powerUpId = inventory[i]

			local icon = slot:FindFirstChild("Icon") :: TextLabel?
			local nameLabel = slot:FindFirstChild("NameLabel") :: TextLabel?

			if powerUpId and PowerUpConfig.PowerUps[powerUpId] then
				local def = PowerUpConfig.PowerUps[powerUpId]

				-- Actualizar icono
				if icon then
					icon.Text = def.Icon or "⭐"
					icon.TextColor3 = def.VFX and def.VFX.ParticleColor and def.VFX.ParticleColor.Keypoints[1].Value or Color3.fromRGB(255, 255, 255)
				end

				-- Actualizar nombre
				if nameLabel then
					nameLabel.Text = def.DisplayName or powerUpId
					nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end

				-- Cambiar color de fondo para indicar que hay algo
				slot.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
			else
				-- Slot vacío
				if icon then
					icon.Text = "?"
					icon.TextColor3 = Color3.fromRGB(100, 100, 100)
				end

				if nameLabel then
					nameLabel.Text = "Empty"
					nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
				end

				slot.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			end
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
--═══════════════════════════════════════════════════════════════════════

-- Crear GUI
local inventoryGUI = createInventoryGUI()

-- Escuchar actualizaciones del servidor
if UpdateInventory then
	UpdateInventory.OnClientEvent:Connect(function(inventory: {string})
		print("[PowerUpInventory] 📦 Inventario actualizado:", inventory)
		updateSlots(inventory)
	end)
end

-- Inicializar con inventario vacío
updateSlots({})

print("[PowerUpInventory] ✅ Sistema de inventario inicializado")
