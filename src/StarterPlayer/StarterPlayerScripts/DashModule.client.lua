--!strict
--[[
	DASH/DODGE SYSTEM - Apocalypse Tycoon

	MECÁNICA:
	- Tecla: Left Shift
	- Efecto: 0.3s de invulnerabilidad
	- Cooldown: 4 segundos
	- Visual: Trail de partículas + flash en borde pantalla

	IMPLEMENTACIÓN:
	- Input local detecta Shift
	- Comunica al servidor para aplicar invulnerabilidad
	- VFX del lado del cliente
	- UI de cooldown
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")

-- Crear RemoteEvent para Dash si no existe
local DashRemote = Remotes:FindFirstChild("DashRequest") :: RemoteEvent?
if not DashRemote then
	warn("[DashModule] ⚠️ RemoteEvent 'DashRequest' no existe - creando...")
	DashRemote = Instance.new("RemoteEvent")
	DashRemote.Name = "DashRequest"
	DashRemote.Parent = Remotes
end

-- CONFIG
local DASH_COOLDOWN = 4 -- segundos
local DASH_DURATION = 0.3 -- duración de invulnerabilidad
local DASH_KEY = Enum.KeyCode.LeftShift

-- STATE
local lastDashTime = 0
local isDashing = false

-- 🎨 UI: Cooldown Indicator
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("DashUI")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DashUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")
end

-- Frame de cooldown (círculo en bottom-right)
local cooldownFrame = screenGui:FindFirstChild("CooldownFrame")
if not cooldownFrame then
	cooldownFrame = Instance.new("Frame")
	cooldownFrame.Name = "CooldownFrame"
	cooldownFrame.Size = UDim2.new(0, 80, 0, 80)
	cooldownFrame.Position = UDim2.new(1, -100, 1, -100) -- Bottom-right
	cooldownFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	cooldownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	cooldownFrame.BackgroundTransparency = 0.3
	cooldownFrame.BorderSizePixel = 0
	cooldownFrame.Parent = screenGui

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0) -- Círculo
	corner.Parent = cooldownFrame

	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 3
	stroke.Transparency = 0.5
	stroke.Parent = cooldownFrame
end

-- Label de cooldown
local cooldownLabel = cooldownFrame:FindFirstChild("Label")
if not cooldownLabel then
	cooldownLabel = Instance.new("TextLabel")
	cooldownLabel.Name = "Label"
	cooldownLabel.Size = UDim2.new(1, 0, 1, 0)
	cooldownLabel.BackgroundTransparency = 1
	cooldownLabel.Text = "DASH"
	cooldownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownLabel.TextScaled = true
	cooldownLabel.Font = Enum.Font.GothamBold
	cooldownLabel.Parent = cooldownFrame
end

-- Overlay de cooldown (visual feedback)
local cooldownOverlay = cooldownFrame:FindFirstChild("Overlay")
if not cooldownOverlay then
	cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "Overlay"
	cooldownOverlay.Size = UDim2.new(1, 0, 0, 0) -- Crece desde 0
	cooldownOverlay.Position = UDim2.new(0, 0, 1, 0)
	cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
	cooldownOverlay.BackgroundTransparency = 0.5
	cooldownOverlay.BorderSizePixel = 0
	cooldownOverlay.ZIndex = 2
	cooldownOverlay.Parent = cooldownFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = cooldownOverlay
end

-------------------------------------------------------------------------
-- 💨 VFX: Dash Trail
-------------------------------------------------------------------------
local function createDashTrail()
	-- Trail de partículas siguiendo al jugador
	local attachment = rootPart:FindFirstChild("DashAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = rootPart
	end

	-- Eliminar trail viejo si existe
	local oldTrail = rootPart:FindFirstChild("DashTrail")
	if oldTrail then oldTrail:Destroy() end

	-- Crear nuevo trail
	local trail = Instance.new("Trail")
	trail.Name = "DashTrail"
	trail.Lifetime = 0.5
	trail.MinLength = 0.1
	trail.Attachment0 = attachment
	trail.Attachment1 = attachment
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 200))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	trail.Parent = rootPart

	-- Auto-eliminar después de 1s
	task.delay(DASH_DURATION + 0.5, function()
		if trail and trail.Parent then
			trail.Enabled = false
			task.wait(1)
			trail:Destroy()
		end
	end)

	return trail
end

-------------------------------------------------------------------------
-- 🌟 VFX: Screen Flash
-------------------------------------------------------------------------
local function createScreenFlash()
	local flash = screenGui:FindFirstChild("DashFlash")
	if not flash then
		flash = Instance.new("Frame")
		flash.Name = "DashFlash"
		flash.Size = UDim2.new(1, 0, 1, 0)
		flash.BackgroundColor3 = Color3.fromRGB(0, 200, 255)  -- ✅ Azul más brillante
		flash.BackgroundTransparency = 1
		flash.BorderSizePixel = 0
		flash.ZIndex = 10
		flash.Parent = screenGui
	end

	-- ✅ Flash más visible: empieza en 0.3 (70% visible) en lugar de 0.7 (30% visible)
	flash.BackgroundTransparency = 0.3
	TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	}):Play()
end

-------------------------------------------------------------------------
-- 🏃 FUNCIÓN PRINCIPAL: Dash
-------------------------------------------------------------------------
local function performDash()
	local now = tick()

	-- Verificar cooldown
	if now - lastDashTime < DASH_COOLDOWN then
		local remaining = math.ceil(DASH_COOLDOWN - (now - lastDashTime))
		cooldownLabel.Text = tostring(remaining)
		return
	end

	if isDashing then return end

	-- Iniciar dash
	isDashing = true
	lastDashTime = now

	-- VFX
	createDashTrail()
	createScreenFlash()

	-- UI Feedback
	cooldownLabel.Text = "DASH!"
	cooldownFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 150)

	-- Animar overlay (cooldown visual)
	cooldownOverlay.Size = UDim2.new(1, 0, 0, 0)
	TweenService:Create(cooldownOverlay, TweenInfo.new(DASH_COOLDOWN, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0)
	}):Play()

	-- Comunicar al servidor (aplicar invulnerabilidad)
	if DashRemote then
		DashRemote:FireServer()
	end

	-- Feedback auditivo (opcional)
	-- local sound = Instance.new("Sound")
	-- sound.SoundId = "rbxassetid://XXXXX"
	-- sound.Volume = 0.5
	-- sound.Parent = rootPart
	-- sound:Play()
	-- sound.Ended:Connect(function() sound:Destroy() end)

	-- Terminar dash
	task.delay(DASH_DURATION, function()
		isDashing = false
		cooldownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end)

	-- Actualizar UI cada segundo durante cooldown
	for i = DASH_COOLDOWN - 1, 0, -1 do
		task.wait(1)
		if i > 0 then
			cooldownLabel.Text = tostring(i)
		else
			cooldownLabel.Text = "READY"
		end
	end
end

-------------------------------------------------------------------------
-- 🎮 INPUT: Detectar Shift
-------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignorar si está en chat/UI

	if input.KeyCode == DASH_KEY then
		performDash()
	end
end)

-- Respawn handling
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")

	-- Reset cooldown
	lastDashTime = 0
	isDashing = false
	cooldownLabel.Text = "READY"
	cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
end)

print("[DashModule] ✅ Dash System cargado - Presiona Left Shift para dash!")
