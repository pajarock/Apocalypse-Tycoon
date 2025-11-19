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

-- ═══════════════════════════════════════════════════════════════════════
-- POWERUP DISPLAY CONFIG (solo info de UI, no lógica de juego)
-- ═══════════════════════════════════════════════════════════════════════
local PowerUpDisplayInfo = {
	GodShield = {
		DisplayName = "God Shield",
		Icon = "🛡️",
		Color = Color3.fromRGB(100, 200, 255),
	},
	DoubleDamage = {
		DisplayName = "Double Damage",
		Icon = "⚔️",
		Color = Color3.fromRGB(255, 50, 50),
	},
	SuperDash = {
		DisplayName = "Super Dash",
		Icon = "💨",
		Color = Color3.fromRGB(255, 255, 100),
	},
	FullHeal = {
		DisplayName = "Full Heal",
		Icon = "❤️",
		Color = Color3.fromRGB(0, 255, 100),
	},
	MiniDrone = {
		DisplayName = "Mini Drone",
		Icon = "🛸",
		Color = Color3.fromRGB(150, 150, 255),
	},
	SpeedBoost = {
		DisplayName = "Speed Boost",
		Icon = "⚡",
		Color = Color3.fromRGB(255, 255, 0),
	},
	BaseShield = {
		DisplayName = "Base Shield",
		Icon = "🛡️",
		Color = Color3.fromRGB(100, 255, 100),
	},
	MeteorJammer = {
		DisplayName = "Meteor Jammer",
		Icon = "📡",
		Color = Color3.fromRGB(200, 100, 255),
	},
	DefensiveBurst = {
		DisplayName = "Defensive Burst",
		Icon = "💥",
		Color = Color3.fromRGB(255, 150, 0),
	},
	CriticalParry = {
		DisplayName = "Critical Parry",
		Icon = "🔥",
		Color = Color3.fromRGB(255, 0, 255),
	},
	UltraCharge = {
		DisplayName = "Ultra Charge",
		Icon = "⚡",
		Color = Color3.fromRGB(255, 255, 255),
	},
	EggCatalyst = {
		DisplayName = "Egg Catalyst",
		Icon = "🥚",
		Color = Color3.fromRGB(255, 200, 100),
	},
	IncomeBoost = {
		DisplayName = "Income Boost",
		Icon = "💰",
		Color = Color3.fromRGB(255, 215, 0),
	},
}

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

	-- 🎨 Frame contenedor - ESTILO GRAFITI
	local container = Instance.new("Frame")
	container.Name = "InventoryContainer"
	container.Size = UDim2.new(0, 500, 0, 110)
	container.Position = UDim2.new(0.5, -250, 1, -140) -- Bottom center
	container.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Rotation = -1 -- Leve inclinación urbana
	container.Parent = screenGui

	-- UICorner más redondeado
	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 20)
	containerCorner.Parent = container

	-- 💎 STROKE NEÓN ÉPICO
	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(0, 255, 200)
	containerStroke.Thickness = 4
	containerStroke.Transparency = 0
	containerStroke.Parent = container

	-- Glow exterior
	local glow = Instance.new("UIGradient")
	glow.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200)),
	})
	glow.Rotation = 90
	glow.Parent = containerStroke

	-- 🎯 TÍTULO ÉPICO ESTILO GRAFITI
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "⚡ POWERUP STASH ⚡"
	title.TextColor3 = Color3.fromRGB(255, 255, 100)
	title.TextSize = 22
	title.Font = Enum.Font.LuckiestGuy -- 🔥 GRAFITI FONT
	title.Rotation = -2
	title.Parent = container

	-- Stroke para el título
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 3
	titleStroke.Parent = title

	-- Frame para los slots
	local slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "SlotsFrame"
	slotsFrame.Size = UDim2.new(1, -20, 0, 65)
	slotsFrame.Position = UDim2.new(0, 10, 0, 40)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = container

	-- UIListLayout para organizar slots
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 15)
	listLayout.Parent = slotsFrame

	-- 🎁 Crear 5 slots ÉPICOS
	for i = 1, 5 do
		local slot = Instance.new("TextButton")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 75, 0, 65)
		slot.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
		slot.BorderSizePixel = 0
		slot.Text = ""
		slot.AutoButtonColor = false
		slot:SetAttribute("SlotIndex", i)
		slot.Rotation = math.random(-3, 3) -- Rotación random para look urbano
		slot.Parent = slotsFrame

		-- UICorner más redondeado
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 15)
		corner.Parent = slot

		-- 💎 STROKE NEÓN GRUESO
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(60, 60, 100)
		stroke.Thickness = 4
		stroke.Transparency = 0
		stroke.Name = "Stroke"
		stroke.Parent = slot

		-- Icon Label (emoji del powerup) - MÁS GRANDE
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 0.6, 0)
		icon.Position = UDim2.new(0, 0, 0, 0)
		icon.BackgroundTransparency = 1
		icon.Text = "?"
		icon.TextSize = 32 -- MÁS GRANDE
		icon.Font = Enum.Font.GothamBold
		icon.TextColor3 = Color3.fromRGB(150, 150, 150)
		icon.Parent = slot

		-- Icon stroke
		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = Color3.fromRGB(0, 0, 0)
		iconStroke.Thickness = 2
		iconStroke.Parent = icon

		-- Name Label - ESTILO GRAFITI
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
		nameLabel.Position = UDim2.new(0, 0, 0.65, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "EMPTY"
		nameLabel.TextSize = 10
		nameLabel.Font = Enum.Font.LuckiestGuy -- 🔥 GRAFITI
		nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		nameLabel.TextScaled = true
		nameLabel.Parent = slot

		-- Name stroke
		local nameStroke = Instance.new("UIStroke")
		nameStroke.Color = Color3.fromRGB(0, 0, 0)
		nameStroke.Thickness = 2
		nameStroke.Parent = nameLabel

		-- 🎯 Click handler con ANIMACIÓN ÉPICA
		slot.MouseButton1Click:Connect(function()
			if UseFromInventory then
				UseFromInventory:FireServer(i)

				-- 💥 BOUNCE ÉPICO
				local originalSize = slot.Size
				TweenService:Create(slot, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 85, 0, 75)
				}):Play()

				task.wait(0.1)

				TweenService:Create(slot, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
					Size = originalSize
				}):Play()
			end
		end)

		-- 🌟 Hover effects ÉPICOS
		slot.MouseEnter:Connect(function()
			if CurrentInventory[i] then
				-- Glow neón
				TweenService:Create(stroke, TweenInfo.new(0.2), {
					Transparency = 0,
					Color = Color3.fromRGB(0, 255, 200),
					Thickness = 6
				}):Play()

				-- Scale up suave
				TweenService:Create(slot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 80, 0, 70)
				}):Play()
			end
		end)

		slot.MouseLeave:Connect(function()
			TweenService:Create(stroke, TweenInfo.new(0.2), {
				Transparency = 0,
				Color = Color3.fromRGB(60, 60, 100),
				Thickness = 4
			}):Play()

			TweenService:Create(slot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 75, 0, 65)
			}):Play()
		end)
	end

	-- 💫 Animación de entrada épica
	container.Position = UDim2.new(0.5, -250, 1, 50)
	TweenService:Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -250, 1, -140)
	}):Play()

	return screenGui
end

--═══════════════════════════════════════════════════════════════════════
-- ACTUALIZAR SLOTS VISUALES
--═══════════════════════════════════════════════════════════════════════

local function updateSlots(inventory: {string})
	local gui = playerGui:FindFirstChild("PowerUpInventoryGUI")
	if not gui then return end

	local slotsFrame = gui:FindFirstChild("InventoryContainer") and gui.InventoryContainer:FindFirstChild("SlotsFrame")
	if not slotsFrame then return end

	-- Actualizar cada slot
	for i = 1, 5 do
		local slot = slotsFrame:FindFirstChild("Slot" .. i)
		if slot then
			local powerUpId = inventory[i]
			local oldPowerUpId = CurrentInventory[i]

			local icon = slot:FindFirstChild("Icon") :: TextLabel?
			local nameLabel = slot:FindFirstChild("NameLabel") :: TextLabel?
			local stroke = slot:FindFirstChild("Stroke") :: UIStroke?

			if powerUpId and PowerUpDisplayInfo[powerUpId] then
				local info = PowerUpDisplayInfo[powerUpId]
				local isNewItem = (oldPowerUpId ~= powerUpId)

				-- 💥 ANIMACIÓN ÉPICA SI ES NUEVO ITEM
				if isNewItem then
					-- Bounce épico
					local originalSize = slot.Size
					slot.Size = UDim2.new(0, 50, 0, 50)
					TweenService:Create(slot, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
						Size = originalSize
					}):Play()

					-- Flash del stroke
					if stroke then
						stroke.Color = info.Color
						stroke.Thickness = 8
						TweenService:Create(stroke, TweenInfo.new(0.3), {
							Thickness = 4
						}):Play()
					end
				end

				-- Actualizar icono
				if icon then
					icon.Text = info.Icon or "⭐"
					icon.TextColor3 = info.Color or Color3.fromRGB(255, 255, 255)
				end

				-- Actualizar nombre
				if nameLabel then
					nameLabel.Text = string.upper(info.DisplayName or powerUpId)
					nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end

				-- Color de fondo con gradiente
				slot.BackgroundColor3 = Color3.fromRGB(40, 40, 70)

				-- Stroke con color del powerup
				if stroke then
					stroke.Color = info.Color
				end
			else
				-- Slot vacío
				if icon then
					icon.Text = "?"
					icon.TextColor3 = Color3.fromRGB(100, 100, 100)
				end

				if nameLabel then
					nameLabel.Text = "EMPTY"
					nameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
				end

				slot.BackgroundColor3 = Color3.fromRGB(25, 25, 40)

				if stroke then
					stroke.Color = Color3.fromRGB(60, 60, 100)
				end
			end
		end
	end

	-- Actualizar inventario local
	CurrentInventory = inventory
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
