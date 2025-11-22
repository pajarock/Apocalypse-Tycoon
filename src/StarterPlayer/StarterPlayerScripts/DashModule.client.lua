--!strict
--[[
	DASH SYSTEM CLIENT - Apocalypse Tycoon
	-----------------------------------------------------------------------

	FEATURES:
	- Detecta Shift + WASD para dash direccional
	- Cooldown UI visible
	- Efectos visuales (trail, screen flash)
		- Efectos visuales (trail, screen flash, particles)
	- Efecto fantasmal: Player semi-transparente durante el dash (0.3s)
	- Sonido de dash

	CONTROLS:
	- Shift + W/A/S/D: Dash en dirección de movimiento
	- Solo Shift (sin WASD): Dash hacia adelante
	-----------------------------------------------------------------------
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

local DashEvaded = Remotes:WaitForChild("DashEvaded", 10) :: RemoteEvent
assert(DashEvaded, "[DashModule] Falta DashEvaded remote")

-- Config
local DEBUG = true
local DASH_COOLDOWN = 2.5 -- ? Reducido de 4s para acción más rápida
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
dashUI.DisplayOrder = 8 -- Debajo del HUD permanente
dashUI.Parent = playerGui

local cooldownFrame = Instance.new("Frame")
cooldownFrame.Name = "CooldownFrame"
cooldownFrame.Size = UDim2.fromOffset(90, 90)
cooldownFrame.Position = UDim2.new(0.2, -45, 1, -110) -- Centro inferior - NO tapa BaseHUD
cooldownFrame.AnchorPoint = Vector2.new(0.5, 0)
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
icon.Text = "??"
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

	-- ? ARREGLADO: Valores correctos para dirección de cámara
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
	-- ? Trail azul brillante detrás del personaje
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

	-- ? Flash azul brillante en pantalla
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

	-- ? Partículas de velocidad
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

-- ? EFECTO FANTASMAL: Hacer al player semi-transparente durante el dash
local function applyGhostEffect()
	if not character then return end

	-- Transparencia fantasmal (70-80%)
	local GHOST_TRANSPARENCY = .80

	-- Tabla para guardar transparencias originales
	local originalTransparencies = {}

	-- Hacer transparentes todas las partes del body
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") then
			-- Guardar transparencia original
			originalTransparencies[part] = part.Transparency

			-- Aplicar transparencia fantasmal
			part.Transparency = GHOST_TRANSPARENCY
		end

		-- También hacer transparentes los accesorios
		if part:IsA("Decal") or part:IsA("Texture") then
			originalTransparencies[part] = part.Transparency
			part.Transparency = GHOST_TRANSPARENCY
		end
	end

	-- Restaurar después del dash
	task.delay(DASH_INVULN_DURATION, function()
		for part, originalTransparency in pairs(originalTransparencies) do
			if part and part.Parent then
				-- Tween suave de regreso para efecto épico
				if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Part") or part:IsA("Decal") or part:IsA("Texture") then
					TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = originalTransparency
					}):Play()
				end
			end
		end

		if DEBUG then
			print("[DASH] ?? Efecto fantasmal terminado - restaurando visibilidad")
		end
	end)

	if DEBUG then
		print("[DASH] ?? Efecto fantasmal aplicado!")
	end
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
	applyGhostEffect() -- ?? Efecto fantasmal de invisibilidad

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

-------------------------------------------------------------------------
-- EVASION FEEDBACK
-------------------------------------------------------------------------

local function showEvasionFeedback(damageEvaded: number)
	if DEBUG then
		print(("[DASH] ??? showEvasionFeedback llamado con damage: %d"):format(damageEvaded))
	end

	-- Verificar que tenemos referencias válidas
	if not character or not humanoidRootPart then
		warn("[DASH] No se puede mostrar feedback - character o HRP no disponible")
		return
	end

	-- ? TEXTO "EVADED!" ESTILO GRAFITI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EvadedFeedback"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Flash dorado en toda la pantalla
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 100
	flash.Parent = screenGui

	-- Texto EVADED estilo grafiti
	local evadedLabel = Instance.new("TextLabel")
	evadedLabel.Name = "EvadedText"
	evadedLabel.Size = UDim2.fromOffset(600, 150)
	evadedLabel.Position = UDim2.fromScale(0.5, 0.35)
	evadedLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	evadedLabel.BackgroundTransparency = 1
	evadedLabel.Text = "? EVADED! ?"
	evadedLabel.Font = Enum.Font.LuckiestGuy -- Font estilo grafiti/street art
	evadedLabel.TextSize = 80
	evadedLabel.TextColor3 = Color3.fromRGB(255, 230, 100) -- Amarillo dorado
	evadedLabel.TextStrokeTransparency = 0
	evadedLabel.TextStrokeColor3 = Color3.fromRGB(50, 30, 0) -- Borde café oscuro
	evadedLabel.TextTransparency = 0
	evadedLabel.ZIndex = 101
	evadedLabel.Rotation = -5 -- Ligera inclinación estilo grafiti
	evadedLabel.Parent = screenGui

	-- Damage evadido (texto pequeño debajo)
	local damageLabel = Instance.new("TextLabel")
	damageLabel.Name = "DamageText"
	damageLabel.Size = UDim2.fromOffset(400, 60)
	damageLabel.Position = UDim2.fromScale(0.5, 0.5)
	damageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	damageLabel.BackgroundTransparency = 1
	damageLabel.Text = string.format("Blocked %d damage!", damageEvaded)
	damageLabel.Font = Enum.Font.GothamBold
	damageLabel.TextSize = 28
	damageLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	damageLabel.TextStrokeTransparency = 0.5
	damageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	damageLabel.TextTransparency = 0
	damageLabel.ZIndex = 101
	damageLabel.Parent = screenGui

	-- Animación: aparecer con bounce
	evadedLabel.Size = UDim2.fromOffset(0, 0)
	damageLabel.TextTransparency = 1
	damageLabel.TextStrokeTransparency = 1

	local appearTween = TweenService:Create(evadedLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(600, 150)
	})
	appearTween:Play()

	task.delay(0.15, function()
		TweenService:Create(damageLabel, TweenInfo.new(0.2), {
			TextTransparency = 0,
			TextStrokeTransparency = 0.5
		}):Play()
	end)

	-- Flash dorado (3 pulsos)
	task.spawn(function()
		for i = 1, 3 do
			TweenService:Create(flash, TweenInfo.new(0.1), {
				BackgroundTransparency = 0.6
			}):Play()
			task.wait(0.1)
			TweenService:Create(flash, TweenInfo.new(0.1), {
				BackgroundTransparency = 1
			}):Play()
			task.wait(0.1)
		end
	end)

	-- Desaparecer después de 1.2s
	task.delay(1.2, function()
		local fadeOut = TweenService:Create(evadedLabel, TweenInfo.new(0.4), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.25)
		})
		fadeOut:Play()

		TweenService:Create(damageLabel, TweenInfo.new(0.4), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}):Play()

		fadeOut.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)

	-- ? Anillo dorado expandiéndose en 3D
	local ring = Instance.new("Part")
	ring.Name = "EvadeRing"
	ring.Size = Vector3.new(2, 0.5, 2)
	ring.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(math.rad(90), 0, 0)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Transparency = 0.3
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 220, 100)
	ring.Parent = workspace

	-- Mesh de anillo
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://3270017" -- Anillo/Ring mesh
	mesh.Scale = Vector3.new(2, 2, 0.5)
	mesh.Parent = ring

	-- Animar: expandir y desvanecer
	TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(20, 0.5, 20)
	}):Play()

	TweenService:Create(mesh, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = Vector3.new(10, 10, 0.5)
	}):Play()

	game.Debris:AddItem(ring, 1)

	-- ? Sonido de éxito
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://6026984224" -- Epic shield/block sound
	sound.Volume = 0.7
	sound.PlaybackSpeed = 1.1
	sound.Parent = humanoidRootPart
	sound:Play()
	game.Debris:AddItem(sound, 3)

	if DEBUG then
		print(("[DASH] ? EVADED visual feedback mostrado!"):format())
	end
end

-- Escuchar eventos de evasión
DashEvaded.OnClientEvent:Connect(function(damageEvaded: number)
	if DEBUG then
		print(("[DASH] ??? DashEvaded event recibido! Damage: %d"):format(damageEvaded))
	end

	local success, err = pcall(function()
		showEvasionFeedback(damageEvaded)
	end)

	if not success then
		warn(("[DASH] ? Error en showEvasionFeedback: %s"):format(tostring(err)))
	end
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
	print("[DashModule] ? Cliente inicializado - Presiona Shift + WASD para dashear")
end