--!strict
--[[
	DASH SYSTEM CLIENT - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	FEATURES:
	- Detecta Shift + WASD para dash direccional
	- Cooldown UI visible
	- Efectos visuales (trail, screen flash)
	- Sonido de dash

	CONTROLS:
	- Shift + W/A/S/D: Dash en dirección de movimiento
	- Solo Shift (sin WASD): Dash hacia adelante
	═══════════════════════════════════════════════════════════════════════
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
assert(Remotes, "[DashModule] Falta carpeta Remotes")

local DashRequest = Remotes:WaitForChild("DashRequest", 10) :: RemoteEvent
assert(DashRequest, "[DashModule] Falta DashRequest remote")

-- Config
local DEBUG = true
local DASH_COOLDOWN = 4 -- segundos
local DASH_INVULN_DURATION = 0.3

-- Estado
local lastDashTime = 0
local isDashing = false

-- UI de cooldown
local playerGui = player:WaitForChild("PlayerGui")

-- Crear UI de cooldown
local dashUI = Instance.new("ScreenGui")
dashUI.Name = "DashUI"
dashUI.ResetOnSpawn = false
dashUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
dashUI.DisplayOrder = 15
dashUI.Parent = playerGui

local cooldownFrame = Instance.new("Frame")
cooldownFrame.Name = "CooldownFrame"
cooldownFrame.Size = UDim2.fromOffset(80, 80)
cooldownFrame.Position = UDim2.new(1, -100, 1, -100) -- Esquina inferior derecha
cooldownFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
cooldownFrame.BackgroundTransparency = 0.2
cooldownFrame.BorderSizePixel = 0
cooldownFrame.Parent = dashUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = cooldownFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 200, 255)
stroke.Thickness = 3
stroke.Transparency = 0
stroke.Parent = cooldownFrame

-- Icono
local icon = Instance.new("TextLabel")
icon.Name = "Icon"
icon.Size = UDim2.fromScale(1, 0.6)
icon.Position = UDim2.fromScale(0, 0.05)
icon.BackgroundTransparency = 1
icon.Text = "💨"
icon.TextScaled = true
icon.Font = Enum.Font.GothamBold
icon.Parent = cooldownFrame

-- Label de cooldown
local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Name = "CooldownLabel"
cooldownLabel.Size = UDim2.fromScale(1, 0.3)
cooldownLabel.Position = UDim2.fromScale(0, 0.65)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.Text = "READY"
cooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
cooldownLabel.TextScaled = true
cooldownLabel.Font = Enum.Font.GothamBold
cooldownLabel.TextStrokeTransparency = 0.7
cooldownLabel.Parent = cooldownFrame

-- Overlay de cooldown
local cooldownOverlay = Instance.new("Frame")
cooldownOverlay.Name = "Overlay"
cooldownOverlay.Size = UDim2.fromScale(1, 0)
cooldownOverlay.Position = UDim2.fromScale(0, 1)
cooldownOverlay.AnchorPoint = Vector2.new(0, 1)
cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cooldownOverlay.BackgroundTransparency = 0.4
cooldownOverlay.BorderSizePixel = 0
cooldownOverlay.Parent = cooldownFrame

local overlayCorner = Instance.new("UICorner")
overlayCorner.CornerRadius = UDim.new(0, 10)
overlayCorner.Parent = cooldownOverlay

-------------------------------------------------------------------------
-- FUNCIONES DE DASH
-------------------------------------------------------------------------

local function getCameraRelativeDirection(): Vector3
	local camera = workspace.CurrentCamera
	if not camera then return Vector3.new(0, 0, -1) end

	-- Obtener input de movimiento
	local moveVector = Vector3.new(0, 0, 0)

	-- ✅ ARREGLADO: Valores correctos para dirección de cámara
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveVector += Vector3.new(0, 0, 1)  -- Forward (positivo)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveVector += Vector3.new(0, 0, -1)  -- Backward (negativo)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveVector += Vector3.new(-1, 0, 0)  -- Left
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveVector += Vector3.new(1, 0, 0)  -- Right
	end

	-- Si no hay input, dash hacia adelante
	if moveVector.Magnitude == 0 then
		moveVector = Vector3.new(0, 0, 1)  -- Forward
	end

	-- Convertir a dirección relativa a la cámara
	local cameraCFrame = camera.CFrame
	local direction = (cameraCFrame.RightVector * moveVector.X) + (cameraCFrame.LookVector * moveVector.Z)

	-- Proyectar en plano horizontal (ignorar Y)
	direction = Vector3.new(direction.X, 0, direction.Z)

	if direction.Magnitude > 0 then
		return direction.Unit
	else
		return cameraCFrame.LookVector
	end
end

local function canDash(): boolean
	local now = tick()
	return (now - lastDashTime >= DASH_COOLDOWN) and not isDashing and humanoid.Health > 0
end

local function playDashVFX()
	-- ✅ Trail azul brillante detrás del personaje
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "DashTrailStart"
	attachment0.Parent = humanoidRootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "DashTrailEnd"
	attachment1.Position = Vector3.new(0, 1, 0)
	attachment1.Parent = humanoidRootPart

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.8
	trail.MinLength = 0
	trail.FaceCamera = true
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200))
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	trail.LightEmission = 1
	trail.Parent = humanoidRootPart

	-- Limpiar después
	task.delay(1, function()
		trail:Destroy()
		attachment0:Destroy()
		attachment1:Destroy()
	end)

	-- ✅ Flash azul brillante en pantalla
	local flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 10
	flash.Parent = playerGui

	TweenService:Create(flash, TweenInfo.new(DASH_INVULN_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	}):Play()

	task.delay(DASH_INVULN_DURATION + 0.1, function()
		flash:Destroy()
	end)

	-- ✅ Partículas de velocidad
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(0.3, 0.5)
	particles.Rate = 50
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(20, 20)
	particles.LightEmission = 1
	particles.Parent = humanoidRootPart

	task.delay(0.2, function()
		particles.Enabled = false
		game.Debris:AddItem(particles, 1)
	end)
end

local function playDashSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://3084314259" -- Whoosh sound
	sound.Volume = 0.5
	sound.PlaybackSpeed = 1.2
	sound.Parent = humanoidRootPart
	sound:Play()
	game.Debris:AddItem(sound, 2)
end

local function executeDash()
	if not canDash() then
		if DEBUG then
			print("[DASH] En cooldown o no disponible")
		end
		return
	end

	-- Calcular dirección
	local direction = getCameraRelativeDirection()

	if DEBUG then
		print(("[DASH] Ejecutando dash en dirección: %s"):format(tostring(direction)))
	end

	-- Enviar al servidor
	DashRequest:FireServer(direction)

	-- Estado local
	lastDashTime = tick()
	isDashing = true

	-- Efectos visuales locales
	playDashVFX()
	playDashSound()

	-- Actualizar UI
	updateCooldownUI()

	-- Restaurar estado después de la invulnerabilidad
	task.delay(DASH_INVULN_DURATION, function()
		isDashing = false
	end)
end

function updateCooldownUI()
	local now = tick()
	local elapsed = now - lastDashTime
	local remaining = math.max(0, DASH_COOLDOWN - elapsed)

	if remaining > 0 then
		-- En cooldown
		cooldownLabel.Text = string.format("%.1f", remaining)
		cooldownLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		stroke.Color = Color3.fromRGB(255, 100, 100)

		-- Overlay de progreso
		local progress = elapsed / DASH_COOLDOWN
		cooldownOverlay.Size = UDim2.fromScale(1, 1 - progress)
	else
		-- Disponible
		cooldownLabel.Text = "READY"
		cooldownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		stroke.Color = Color3.fromRGB(100, 200, 255)
		cooldownOverlay.Size = UDim2.fromScale(1, 0)
	end
end

-------------------------------------------------------------------------
-- INPUT HANDLING
-------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Detectar Shift (tanto izquierdo como derecho)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		executeDash()
	end
end)

-- Actualizar UI cada frame
RunService.RenderStepped:Connect(function()
	updateCooldownUI()
end)

-- Re-conectar cuando cambie el personaje
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart") :: BasePart
	humanoid = newChar:WaitForChild("Humanoid") :: Humanoid
	lastDashTime = 0
	isDashing = false
end)

if DEBUG then
	print("[DashModule] ✅ Cliente inicializado - Presiona Shift + WASD para dashear")
end
