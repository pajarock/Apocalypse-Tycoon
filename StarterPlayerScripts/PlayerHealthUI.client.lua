--!strict
--[[
	PLAYER HEALTH UI - Apocalypse Tycoon
	Barra de vida simple y funcional para el jugador
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- Crear UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerHealthUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame contenedor
local container = Instance.new("Frame")
container.Name = "HealthBarContainer"
container.Size = UDim2.new(0, 300, 0, 40)
container.Position = UDim2.new(0.5, -150, 1, -60) -- Centrado abajo
container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
container.BackgroundTransparency = 0.3
container.BorderSizePixel = 0
container.Parent = screenGui

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

-- Barra de vida (verde)
local healthBar = Instance.new("Frame")
healthBar.Name = "HealthBar"
healthBar.Size = UDim2.new(1, -4, 1, -4)
healthBar.Position = UDim2.new(0, 2, 0, 2)
healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
healthBar.BorderSizePixel = 0
healthBar.Parent = container

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 6)
healthCorner.Parent = healthBar

-- Texto de HP
local healthText = Instance.new("TextLabel")
healthText.Name = "HealthText"
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.BackgroundTransparency = 1
healthText.Text = "100 / 100 HP"
healthText.TextColor3 = Color3.new(1, 1, 1)
healthText.Font = Enum.Font.GothamBold
healthText.TextSize = 18
healthText.TextStrokeTransparency = 0.5
healthText.Parent = container

-- Función para actualizar la barra
local function updateHealthBar()
	if not humanoid or humanoid.Health <= 0 then return end

	local health = humanoid.Health
	local maxHealth = humanoid.MaxHealth
	local percentage = health / maxHealth

	-- Actualizar tamaño de la barra
	healthBar.Size = UDim2.new(percentage, -4, 1, -4)

	-- Actualizar texto
	healthText.Text = string.format("%d / %d HP", math.floor(health), math.floor(maxHealth))

	-- Cambiar color según HP
	if percentage > 0.6 then
		healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Verde
	elseif percentage > 0.3 then
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Amarillo
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Rojo
	end
end

-- Actualizar cada frame
RunService.Heartbeat:Connect(updateHealthBar)

-- Actualizar inmediatamente
updateHealthBar()

-- Reconectar cuando el personaje respawnee
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	updateHealthBar()
end)

print("[PlayerHealthUI] ✓ Barra de vida del jugador creada")
