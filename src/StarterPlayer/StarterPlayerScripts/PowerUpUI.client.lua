--!strict
--[[
	-----------------------------------------------------------------------
	POWERUP UI CLIENT - Apocalypse Tycoon
	-----------------------------------------------------------------------

	UI Cliente para mostrar:
	? Powerups activos con temporizador
	? Efectos visuales en el jugador (auras, trails, etc.)
	? Notificaciones al recoger powerups
	? HUD ÃÂ©pico y tÃÂ³xico

	-----------------------------------------------------------------------
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpActivated = Remotes:WaitForChild("PowerUpActivated") :: RemoteEvent
local PowerUpExpired = Remotes:WaitForChild("PowerUpExpired") :: RemoteEvent
local PowerUpCollected = Remotes:WaitForChild("PowerUpCollected") :: RemoteEvent

-- -----------------------------------------------------------------------
-- ESTADO
-- -----------------------------------------------------------------------

local ActivePowerUpFrames = {} -- {powerUpId: Frame}
local ActiveEffects = {} -- {powerUpId: {effects}}

-- -----------------------------------------------------------------------
-- CREAR HUD DE POWERUPS
-- -----------------------------------------------------------------------

local function createPowerUpHUD()
	-- Crear ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PowerUpHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Container de powerups activos (esquina superior derecha)
	local container = Instance.new("Frame")
	container.Name = "PowerUpContainer"
	container.Size = UDim2.new(0, 300, 0, 500)
	container.Position = UDim2.new(1, -320, 0, 20) -- Top right
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- UIListLayout para organizar powerups verticalmente
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = container

	return container
end

local powerUpContainer = createPowerUpHUD()

-- -----------------------------------------------------------------------
-- CREAR FRAME DE POWERUP INDIVIDUAL
-- -----------------------------------------------------------------------

local function createPowerUpFrame(powerUpId: string, duration: number, icon: string, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = powerUpId
	frame.Size = UDim2.new(1, 0, 0, 80)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0

	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Borde brillante del color del powerup
	local border = Instance.new("UIStroke")
	border.Color = color
	border.Thickness = 3
	border.Transparency = 0
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = frame

	-- Icono
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 60, 0, 60)
	iconLabel.Position = UDim2.new(0, 10, 0.5, -30)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Text = icon
	iconLabel.Parent = frame

	-- Nombre del powerup
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -80, 0, 30)
	nameLabel.Position = UDim2.new(0, 80, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.TextColor3 = color
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = powerUpId:gsub("(%u)", " %1"):sub(2) -- "GodShield" -> "God Shield"
	nameLabel.Parent = frame

	-- Barra de progreso
	local progressBack = Instance.new("Frame")
	progressBack.Name = "ProgressBack"
	progressBack.Size = UDim2.new(1, -90, 0, 8)
	progressBack.Position = UDim2.new(0, 80, 1, -20)
	progressBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressBack.BorderSizePixel = 0
	progressBack.Parent = frame

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(1, 0)
	progressCorner.Parent = progressBack

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.BackgroundColor3 = color
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBack

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(1, 0)
	progressBarCorner.Parent = progressBar

	-- Timer label
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(0, 60, 0, 30)
	timerLabel.Position = UDim2.new(0, 80, 0, 40)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextSize = 16
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Text = string.format("%.1fs", duration)
	timerLabel.Parent = frame

	-- AnimaciÃÂ³n de entrada (slide in desde la derecha)
	frame.Position = UDim2.new(1, 0, 0, 0) -- Start off-screen
	frame.Parent = powerUpContainer

	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, tweenInfo, {
		Position = UDim2.new(0, 0, 0, 0)
	})
	tween:Play()

	-- Efecto de brillo pulsante en el borde
	task.spawn(function()
		while frame and frame.Parent do
			local pulseTween = TweenService:Create(border, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.5
			})
			pulseTween:Play()
			pulseTween.Completed:Wait()

			pulseTween = TweenService:Create(border, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0
			})
			pulseTween:Play()
			pulseTween.Completed:Wait()
		end
	end)

	return frame
end

-- -----------------------------------------------------------------------
-- EFECTOS VISUALES EN EL PERSONAJE
-- -----------------------------------------------------------------------

local function createGodShieldEffect(): {Instance}
	local effects = {}

	-- Aura brillante alrededor del jugador
	local aura = Instance.new("Part")
	aura.Name = "GodShieldAura"
	aura.Size = Vector3.new(8, 8, 8)
	aura.Anchored = true
	aura.CanCollide = false
	aura.Transparency = 0.7
	aura.Material = Enum.Material.Neon
	aura.Color = Color3.fromRGB(100, 200, 255)
	aura.Parent = character

	-- Mesh esfÃÂ©rico
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = aura

	-- PartÃÂ­culas
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200)),
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.LightEmission = 1
	particles.Parent = aura

	table.insert(effects, aura)

	-- Animar aura para seguir al jugador y pulsar
	task.spawn(function()
		local t = 0
		while aura and aura.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.016
			local scale = 1 + math.sin(t * 5) * 0.2 -- Pulsar
			mesh.Scale = Vector3.new(scale, scale, scale)
			aura.CFrame = humanoidRootPart.CFrame
			task.wait(0.016)
		end
	end)

	return effects
end

local function createSpeedBoostEffect(): {Instance}
	local effects = {}

	-- Trail detrÃÂ¡s del jugador
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailAttachment0"
	attachment0.Position = Vector3.new(0, -2, 0)
	attachment0.Parent = humanoidRootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailAttachment1"
	attachment1.Position = Vector3.new(0, 2, 0)
	attachment1.Parent = humanoidRootPart

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.5
	trail.LightEmission = 1
	trail.Parent = humanoidRootPart

	table.insert(effects, trail)
	table.insert(effects, attachment0)
	table.insert(effects, attachment1)

	return effects
end

local function createDoubleDamageEffect(): {Instance}
	local effects = {}

	-- Glow rojo en el personaje
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not part.Name:match("Attachment") then
			local originalColor = part.Color
			part.Color = Color3.fromRGB(255, 50, 50)

			-- Crear efecto de fuego
			local fire = Instance.new("Fire")
			fire.Color = Color3.fromRGB(255, 0, 0)
			fire.SecondaryColor = Color3.fromRGB(255, 100, 0)
			fire.Size = 3
			fire.Heat = 5
			fire.Parent = part

			table.insert(effects, fire)

			-- Restaurar color al terminar (se maneja en cleanup)
			task.spawn(function()
				while fire and fire.Parent do
					task.wait()
				end
				if part and part.Parent then
					part.Color = originalColor
				end
			end)
		end
	end

	return effects
end

local function createBaseShieldEffect(): {Instance}
	local effects = {}

	-- Dome/esfera protectora en la base del jugador
	-- (Esto irÃÂ­a en la base fÃÂ­sica, pero podemos hacer un indicador visual)

	local indicator = Instance.new("Part")
	indicator.Name = "BaseShieldIndicator"
	indicator.Size = Vector3.new(1, 10, 1)
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.Transparency = 0.5
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(0, 255, 150)
	indicator.CFrame = humanoidRootPart.CFrame
	indicator.Parent = workspace

	-- Mesh cilÃÂ­ndrico
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent = indicator

	-- Animar indicador
	task.spawn(function()
		local t = 0
		while indicator and indicator.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.016
			indicator.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, t * 2, 0)
			task.wait(0.016)
		end
	end)

	table.insert(effects, indicator)

	return effects
end

local function createCriticalParryEffect(): {Instance}
	local effects = {}

	-- Aura de carga violeta
	local chargeAura = Instance.new("Part")
	chargeAura.Name = "CriticalParryAura"
	chargeAura.Size = Vector3.new(6, 6, 6)
	chargeAura.Anchored = true
	chargeAura.CanCollide = false
	chargeAura.Transparency = 0.6
	chargeAura.Material = Enum.Material.Neon
	chargeAura.Color = Color3.fromRGB(255, 0, 255)
	chargeAura.Parent = character

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = chargeAura

	-- PartÃÂ­culas elÃÂ©ctricas
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 200))
	particles.Size = NumberSequence.new(0.5)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 30
	particles.Speed = NumberRange.new(3, 6)
	particles.LightEmission = 1
	particles.Parent = chargeAura

	table.insert(effects, chargeAura)

	-- Animar
	task.spawn(function()
		local t = 0
		while chargeAura and chargeAura.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.016
			chargeAura.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, t * 3, 0)
			task.wait(0.016)
		end
	end)

	return effects
end

local function createSuperDashEffect(): {Instance}
	local effects = {}

	-- Trail amarillo brillante
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "DashTrailAttachment0"
	attachment0.Position = Vector3.new(0, -2, 0)
	attachment0.Parent = humanoidRootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "DashTrailAttachment1"
	attachment1.Position = Vector3.new(0, 2, 0)
	attachment1.Parent = humanoidRootPart

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 100))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.8
	trail.LightEmission = 1
	trail.Parent = humanoidRootPart

	-- PartÃÂ­culas de velocidad
	local speedParticles = Instance.new("ParticleEmitter")
	speedParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	speedParticles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
	speedParticles.Size = NumberSequence.new(1.5)
	speedParticles.Lifetime = NumberRange.new(0.3, 0.5)
	speedParticles.Rate = 50
	speedParticles.Speed = NumberRange.new(10, 15)
	speedParticles.SpreadAngle = Vector2.new(30, 30)
	speedParticles.LightEmission = 1
	speedParticles.Parent = humanoidRootPart

	table.insert(effects, trail)
	table.insert(effects, attachment0)
	table.insert(effects, attachment1)
	table.insert(effects, speedParticles)

	return effects
end

local function createFullHealEffect(): {Instance}
	local effects = {}

	-- Burst de partÃÂ­culas verdes curativas
	local healBurst = Instance.new("ParticleEmitter")
	healBurst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	healBurst.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100))
	healBurst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	healBurst.Lifetime = NumberRange.new(1, 2)
	healBurst.Rate = 100
	healBurst.Speed = NumberRange.new(10, 20)
	healBurst.SpreadAngle = Vector2.new(180, 180)
	healBurst.LightEmission = 1
	healBurst.Parent = humanoidRootPart

	-- Desactivar despuÃÂ©s del burst inicial
	task.delay(0.5, function()
		if healBurst and healBurst.Parent then
			healBurst.Enabled = false
		end
	end)

	-- Aura verde temporal
	local healAura = Instance.new("Part")
	healAura.Name = "HealAura"
	healAura.Size = Vector3.new(8, 8, 8)
	healAura.Anchored = true
	healAura.CanCollide = false
	healAura.Transparency = 0.7
	healAura.Material = Enum.Material.Neon
	healAura.Color = Color3.fromRGB(0, 255, 100)
	healAura.CFrame = humanoidRootPart.CFrame
	healAura.Parent = workspace

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = healAura

	-- Animar expansiÃÂ³n
	task.spawn(function()
		for i = 1, 10 do
			if healAura and healAura.Parent then
				healAura.Size = healAura.Size + Vector3.new(2, 2, 2)
				healAura.Transparency = 0.7 + (i * 0.03)
				task.wait(0.05)
			end
		end
		if healAura and healAura.Parent then
			healAura:Destroy()
		end
	end)

	table.insert(effects, healBurst)
	table.insert(effects, healAura)

	return effects
end

local function createMiniDroneEffect(): {Instance}
	local effects = {}

	-- Mini dron visual orbitando al jugador
	local drone = Instance.new("Part")
	drone.Name = "MiniDrone"
	drone.Size = Vector3.new(2, 1, 2)
	drone.Material = Enum.Material.Neon
	drone.Color = Color3.fromRGB(150, 150, 255)
	drone.Anchored = true
	drone.CanCollide = false
	drone.Parent = workspace

	-- PointLight azul
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 15
	light.Color = Color3.fromRGB(150, 150, 255)
	light.Parent = drone

	-- PartÃÂ­culas tech
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	particles.Size = NumberSequence.new(0.3)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 20
	particles.Speed = NumberRange.new(2, 4)
	particles.LightEmission = 1
	particles.Parent = drone

	-- Orbitar alrededor del jugador
	task.spawn(function()
		local angle = 0
		while drone and drone.Parent and humanoidRootPart and humanoidRootPart.Parent do
			angle += 0.05
			local offset = CFrame.new(
				math.cos(angle) * 8,
				math.sin(angle * 2) * 2 + 5,
				math.sin(angle) * 8
			)
			drone.CFrame = humanoidRootPart.CFrame * offset * CFrame.Angles(0, angle, 0)
			task.wait(0.016)
		end
	end)

	table.insert(effects, drone)

	return effects
end

local function createMeteorJammerEffect(): {Instance}
	local effects = {}

	-- ?? PULSOS ELECTROMAGNÃÂTICOS EXPANDIÃÂNDOSE (sin burbuja)
	-- Crear mÃÂºltiples anillos que se expanden desde el jugador
	local function createPulseRing()
		local ring = Instance.new("Part")
		ring.Name = "JammerRing"
		ring.Size = Vector3.new(0.5, 0.5, 2)
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.2
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(200, 100, 255)
		ring.CFrame = humanoidRootPart.CFrame
		ring.Parent = workspace

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Scale = Vector3.new(0.1, 1, 1)
		mesh.Parent = ring

		-- Expandir y desvanecer
		task.spawn(function()
			for i = 1, 30 do
				if ring and ring.Parent then
					local scale = i * 0.8
					ring.Size = Vector3.new(0.5, 0.5, 2 + scale)
					ring.Transparency = 0.2 + (i / 30) * 0.8
					ring.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
					task.wait(0.05)
				end
			end
			if ring and ring.Parent then
				ring:Destroy()
			end
		end)

		return ring
	end

	-- PartÃÂ­culas elÃÂ©ctricas moradas
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(200, 100, 255))
	particles.Size = NumberSequence.new(1)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 50
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.LightEmission = 1
	particles.Parent = humanoidRootPart

	-- PointLight pulsante
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 15
	light.Color = Color3.fromRGB(200, 100, 255)
	light.Parent = humanoidRootPart

	-- Generar pulsos continuos
	task.spawn(function()
		local t = 0
		while humanoidRootPart and humanoidRootPart.Parent do
			t += 1
			if t % 10 == 0 then  -- Cada 0.5 segundos
				local ring = createPulseRing()
				table.insert(effects, ring)
			end

			-- Pulsar light
			light.Brightness = 2 + math.sin(t * 0.3) * 0.8

			task.wait(0.05)

			if t > 600 then break end  -- Safety timeout
		end
	end)

	table.insert(effects, particles)
	table.insert(effects, light)

	return effects
end

local function createDefensiveBurstEffect(): {Instance}
	local effects = {}

	-- ExplosiÃÂ³n naranja masiva
	local burst = Instance.new("Part")
	burst.Name = "DefensiveBurst"
	burst.Size = Vector3.new(5, 5, 5)
	burst.Anchored = true
	burst.CanCollide = false
	burst.Transparency = 0.5
	burst.Material = Enum.Material.Neon
	burst.Color = Color3.fromRGB(255, 150, 0)
	burst.CFrame = humanoidRootPart.CFrame
	burst.Parent = workspace

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = burst

	-- Expandir explosiÃÂ³n
	task.spawn(function()
		for i = 1, 20 do
			if burst and burst.Parent then
				burst.Size = burst.Size + Vector3.new(10, 10, 10)
				burst.Transparency = 0.5 + (i * 0.025)
				task.wait(0.03)
			end
		end
		if burst and burst.Parent then
			burst:Destroy()
		end
	end)

	table.insert(effects, burst)

	return effects
end

local function createUltraChargeEffect(): {Instance}
	local effects = {}

	-- ? EXPLOSIÃÂN MASIVA DE RAYOS ELÃÂCTRICOS
	local lightning = Instance.new("ParticleEmitter")
	lightning.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	lightning.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	lightning.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(0.5, 3),
		NumberSequenceKeypoint.new(1, 0)
	})
	lightning.Lifetime = NumberRange.new(0.3, 0.7)
	lightning.Rate = 150
	lightning.Speed = NumberRange.new(20, 35)
	lightning.SpreadAngle = Vector2.new(180, 180)
	lightning.LightEmission = 1
	lightning.Parent = humanoidRootPart

	-- MÃÂºltiples anillos de energÃÂ­a girando
	local rings = {}
	for i = 1, 3 do
		local ring = Instance.new("Part")
		ring.Name = "ChargeRing" .. i
		ring.Size = Vector3.new(0.5, 0.5, 6 + (i * 2))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Transparency = 0.2 + (i * 0.1)
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Parent = workspace

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Cylinder
		mesh.Scale = Vector3.new(0.1, 1, 1)
		mesh.Parent = ring

		table.insert(rings, ring)
		table.insert(effects, ring)
	end

	-- PointLight pulsante MASIVA
	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Range = 30
	light.Color = Color3.fromRGB(255, 255, 255)
	light.Parent = humanoidRootPart

	-- Sparkles extra
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 255, 255)
	sparkles.Parent = humanoidRootPart

	-- Animar anillos con diferentes velocidades
	task.spawn(function()
		local t = 0
		while humanoidRootPart and humanoidRootPart.Parent do
			t += 0.05

			for i, ring in ipairs(rings) do
				if ring and ring.Parent then
					local speed = 5 + (i * 2)
					local angle = i % 2 == 0 and t * speed or -t * speed
					local yOffset = math.sin(t * 3 + i) * 2
					ring.CFrame = humanoidRootPart.CFrame * CFrame.new(0, yOffset, 0) * CFrame.Angles(0, 0, math.rad(angle))
				end
			end

			-- Pulsar light dramÃÂ¡ticamente
			light.Brightness = 4 + math.sin(t * 10) * 2

			task.wait(0.05)
		end
	end)

	table.insert(effects, lightning)
	table.insert(effects, light)
	table.insert(effects, sparkles)

	return effects
end

local function createEggCatalystEffect(): {Instance}
	local effects = {}

	-- ?? EXPLOSIÃÂN DORADA MÃÂGICA
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 220, 100)
	sparkles.Parent = humanoidRootPart

	-- PartÃÂ­culas masivas doradas
	local eggParticles = Instance.new("ParticleEmitter")
	eggParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	eggParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 50))
	})
	eggParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 1.5),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	eggParticles.Lifetime = NumberRange.new(1.5, 3)
	eggParticles.Rate = 60
	eggParticles.Speed = NumberRange.new(5, 10)
	eggParticles.SpreadAngle = Vector2.new(60, 60)
	eggParticles.LightEmission = 1
	eggParticles.RotSpeed = NumberRange.new(100, 200)
	eggParticles.Rotation = NumberRange.new(0, 360)
	eggParticles.Parent = humanoidRootPart

	-- Anillo dorado en el suelo
	local ring = Instance.new("Part")
	ring.Name = "EggRing"
	ring.Size = Vector3.new(0.5, 0.5, 10)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Transparency = 0.3
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 200, 100)
	ring.Parent = workspace

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Scale = Vector3.new(0.2, 1, 1)
	mesh.Parent = ring

	-- PointLight cÃÂ¡lida
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 18
	light.Color = Color3.fromRGB(255, 200, 100)
	light.Parent = humanoidRootPart

	-- Animar anillo giratorio
	task.spawn(function()
		local t = 0
		while ring and ring.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.05
			ring.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(t * 3))

			-- Pulsar
			local scale = 1 + math.sin(t * 5) * 0.1
			mesh.Scale = Vector3.new(0.2, scale, scale)

			light.Brightness = 2.5 + math.sin(t * 6) * 0.8

			task.wait(0.05)
		end
	end)

	table.insert(effects, sparkles)
	table.insert(effects, eggParticles)
	table.insert(effects, ring)
	table.insert(effects, light)

	return effects
end

local function createIncomeBoostEffect(): {Instance}
	local effects = {}

	-- ?? EXPLOSIÃÂN MASIVA DE MONEDAS
	local coinBurst = Instance.new("ParticleEmitter")
	coinBurst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	coinBurst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
	})
	coinBurst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	coinBurst.Lifetime = NumberRange.new(2, 4)
	coinBurst.Rate = 80
	coinBurst.Speed = NumberRange.new(8, 15)
	coinBurst.SpreadAngle = Vector2.new(180, 180)
	coinBurst.LightEmission = 1
	coinBurst.RotSpeed = NumberRange.new(200, 400)
	coinBurst.Rotation = NumberRange.new(0, 360)
	coinBurst.Parent = humanoidRootPart

	-- ?? Anillo dorado girando en el suelo (tipo EVADE)
	local ring = Instance.new("Part")
	ring.Name = "GoldRing"
	ring.Size = Vector3.new(0.5, 0.5, 8)
	ring.Anchored = true
	ring.CanCollide = false
	ring.Transparency = 0.3
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 215, 0)
	ring.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2.5, 0)
	ring.Parent = workspace

	local ringMesh = Instance.new("SpecialMesh")
	ringMesh.MeshType = Enum.MeshType.Cylinder
	ringMesh.Scale = Vector3.new(0.2, 1, 1)
	ringMesh.Parent = ring

	-- Segundo anillo mÃÂ¡s grande
	local ring2 = ring:Clone()
	ring2.Size = Vector3.new(0.5, 0.5, 12)
	ring2.Transparency = 0.5
	ring2.Parent = workspace

	-- PointLight dorada brillante
	local light = Instance.new("PointLight")
	light.Brightness = 3
	light.Range = 20
	light.Color = Color3.fromRGB(255, 215, 0)
	light.Parent = humanoidRootPart

	-- Sparkles en el torso
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
	sparkles.Parent = humanoidRootPart

	-- Animar anillos giratorios
	task.spawn(function()
		local t = 0
		while ring and ring.Parent and ring2 and ring2.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.05
			ring.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, t * 5, math.rad(90))
			ring2.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, -t * 3, math.rad(90))

			-- Pulsar light
			light.Brightness = 3 + math.sin(t * 8) * 1

			task.wait(0.05)
		end
	end)

	table.insert(effects, coinBurst)
	table.insert(effects, ring)
	table.insert(effects, ring2)
	table.insert(effects, light)
	table.insert(effects, sparkles)

	return effects
end

-- -----------------------------------------------------------------------
-- MENSAJES ÃÂPICOS DE ACTIVACIÃÂN
-- -----------------------------------------------------------------------

local PowerUpMessages = {
	GodShield = {
		MainText = "??? GOD SHIELD! ???",
		SubText = "Invulnerable!",
	},
	DoubleDamage = {
		MainText = "?? 2X DAMAGE! ??",
		SubText = "Destroy everything!",
	},
	SuperDash = {
		MainText = "?? SUPER DASH! ??",
		SubText = "No cooldown!",
	},
	FullHeal = {
		MainText = "?? FULL HEAL! ??",
		SubText = "100% HP restored!",
	},
	MiniDrone = {
		MainText = "?? MINI DRONE! ??",
		SubText = "Auto-defense active!",
	},
	SpeedBoost = {
		MainText = "? 2X SPEED! ?",
		SubText = "Lightning fast!",
	},
	BaseShield = {
		MainText = "??? BASE SHIELD! ???",
		SubText = "Next meteor blocked!",
	},
	MeteorJammer = {
		MainText = "?? METEOR JAMMER! ??",
		SubText = "Slowing down attacks!",
	},
	DefensiveBurst = {
		MainText = "?? DEFENSIVE BURST! ??",
		SubText = "Area cleared!",
	},
	CriticalParry = {
		MainText = "?? CRITICAL PARRY! ??",
		SubText = "Next hit = explosion!",
	},
	UltraCharge = {
		MainText = "? ULTRA CHARGE! ?",
		SubText = "All cooldowns reset!",
	},
	EggCatalyst = {
		MainText = "?? EGG CATALYST! ??",
		SubText = "Pet egg chance boosted!",
	},
	IncomeBoost = {
		MainText = "?? 2X INCOME! ??",
		SubText = "Double your money per second!",
	},
}

local function showEpicPowerUpMessage(powerUpId: string, color: Color3)
	local messageData = PowerUpMessages[powerUpId]
	if not messageData then return end

	-- ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "EpicPowerUpMessage"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	-- ?? TEXTO PRINCIPAL GIGANTE (estilo EVADED!)
	local mainText = Instance.new("TextLabel")
	mainText.Name = "MainText"
	mainText.Size = UDim2.new(0.8, 0, 0.3, 0)
	mainText.Position = UDim2.new(0.1, 0, 0.35, 0)
	mainText.BackgroundTransparency = 1
	mainText.Text = messageData.MainText
	mainText.TextColor3 = color
	mainText.TextSize = 80
	mainText.Font = Enum.Font.LuckiestGuy -- ?? GRAFITI FONT
	mainText.TextScaled = true
	mainText.Rotation = -5 -- InclinaciÃÂ³n urbana
	mainText.Parent = gui

	-- Stroke GRUESO para el texto
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(0, 0, 0)
	mainStroke.Thickness = 8
	mainStroke.Parent = mainText

	-- ?? SUBTEXTO
	local subText = Instance.new("TextLabel")
	subText.Name = "SubText"
	subText.Size = UDim2.new(0.6, 0, 0.1, 0)
	subText.Position = UDim2.new(0.2, 0, 0.58, 0)
	subText.BackgroundTransparency = 1
	subText.Text = messageData.SubText
	subText.TextColor3 = Color3.fromRGB(255, 255, 255)
	subText.TextSize = 28
	subText.Font = Enum.Font.GothamBold
	subText.TextTransparency = 1 -- Start invisible
	subText.Parent = gui

	-- Subtexto stroke
	local subStroke = Instance.new("UIStroke")
	subStroke.Color = Color3.fromRGB(0, 0, 0)
	subStroke.Thickness = 4
	subStroke.Transparency = 1
	subStroke.Parent = subText

	-- ?? ANIMACIÃÂN ÃÂPICA DE BOUNCE
	-- Empezar pequeÃÂ±o
	mainText.TextTransparency = 1
	mainText.Size = UDim2.new(0.4, 0, 0.15, 0)

	-- Bounce in
	TweenService:Create(mainText, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.8, 0, 0.3, 0),
		TextTransparency = 0
	}):Play()

	-- Aparecer subtexto despuÃÂ©s
	task.delay(0.15, function()
		TweenService:Create(subText, TweenInfo.new(0.2), {
			TextTransparency = 0
		}):Play()

		TweenService:Create(subStroke, TweenInfo.new(0.2), {
			Transparency = 0
		}):Play()
	end)

	-- Mantener visible por 2 segundos
	task.wait(2.5)

	-- Fade out
	TweenService:Create(mainText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		Position = UDim2.new(0.1, 0, 0.25, 0) -- Slide up
	}):Play()

	TweenService:Create(subText, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	}):Play()

	TweenService:Create(subStroke, TweenInfo.new(0.5), {
		Transparency = 1
	}):Play()

	task.wait(0.5)
	gui:Destroy()
end

-- -----------------------------------------------------------------------
-- MAPEO DE EFECTOS VISUALES
-- -----------------------------------------------------------------------

local PowerUpVFXMap = {
	GodShield = createGodShieldEffect,
	SpeedBoost = createSpeedBoostEffect,
	DoubleDamage = createDoubleDamageEffect,
	BaseShield = createBaseShieldEffect,
	CriticalParry = createCriticalParryEffect,
	SuperDash = createSuperDashEffect,
	FullHeal = createFullHealEffect,
	MiniDrone = createMiniDroneEffect,
	MeteorJammer = createMeteorJammerEffect,
	DefensiveBurst = createDefensiveBurstEffect,
	UltraCharge = createUltraChargeEffect,
	EggCatalyst = createEggCatalystEffect,
	IncomeBoost = createIncomeBoostEffect,
}

-- -----------------------------------------------------------------------
-- MANEJO DE EVENTOS DE POWERUPS
-- -----------------------------------------------------------------------

local PowerUpColors = {
	GodShield = Color3.fromRGB(100, 200, 255),
	DoubleDamage = Color3.fromRGB(255, 50, 50),
	SuperDash = Color3.fromRGB(255, 255, 100),
	FullHeal = Color3.fromRGB(0, 255, 100),
	MiniDrone = Color3.fromRGB(150, 150, 255),
	SpeedBoost = Color3.fromRGB(255, 255, 0),
	BaseShield = Color3.fromRGB(100, 255, 100),
	MeteorJammer = Color3.fromRGB(200, 100, 255),
	DefensiveBurst = Color3.fromRGB(255, 150, 0),
	CriticalParry = Color3.fromRGB(255, 0, 255),
	UltraCharge = Color3.fromRGB(255, 255, 255),
	EggCatalyst = Color3.fromRGB(255, 200, 100),
	IncomeBoost = Color3.fromRGB(255, 215, 0),
}

local PowerUpIcons = {
	GodShield = "???",
	DoubleDamage = "??",
	SuperDash = "??",
	FullHeal = "??",
	MiniDrone = "??",
	SpeedBoost = "?",
	BaseShield = "???",
	MeteorJammer = "??",
	DefensiveBurst = "??",
	CriticalParry = "??",
	UltraCharge = "?",
	EggCatalyst = "??",
	IncomeBoost = "??",
}

-- Activar powerup
PowerUpActivated.OnClientEvent:Connect(function(powerUpId: string, duration: number)
	print(("[PowerUpUI] ?? Activando powerup: %s (duraciÃÂ³n: %.1fs)"):format(powerUpId, duration or 0))

	-- ? LIMPIAR powerup existente si ya estÃÂ¡ activo
	if ActivePowerUpFrames[powerUpId] then
		print(("[PowerUpUI] ?? Ya existe powerup activo: %s - Limpiando..."):format(powerUpId))

		-- Remover frame viejo
		if ActivePowerUpFrames[powerUpId].Frame and ActivePowerUpFrames[powerUpId].Frame.Parent then
			ActivePowerUpFrames[powerUpId].Frame:Destroy()
		end

		-- Remover efectos viejos
		if ActiveEffects[powerUpId] then
			for _, effect in ipairs(ActiveEffects[powerUpId]) do
				if effect and effect.Parent then
					effect:Destroy()
				end
			end
			ActiveEffects[powerUpId] = nil
		end

		ActivePowerUpFrames[powerUpId] = nil
	end

	local color = PowerUpColors[powerUpId] or Color3.new(1, 1, 1)
	local icon = PowerUpIcons[powerUpId] or "?"

	-- Crear frame de UI
	local frame = createPowerUpFrame(powerUpId, duration, icon, color)
	ActivePowerUpFrames[powerUpId] = {
		Frame = frame,
		StartTime = tick(),
		Duration = duration,
	}

	-- Crear efectos visuales
	if PowerUpVFXMap[powerUpId] then
		local effects = PowerUpVFXMap[powerUpId]()
		ActiveEffects[powerUpId] = effects
		print(("[PowerUpUI] ? Efectos visuales creados para: %s"):format(powerUpId))
	end

	-- ?? MOSTRAR MENSAJE ÃÂPICO ESTILO GRAFITI
	task.spawn(function()
		showEpicPowerUpMessage(powerUpId, color)
	end)
end)

-- Expirar powerup
PowerUpExpired.OnClientEvent:Connect(function(powerUpId: string)
	print(("[PowerUpUI] ?? Expirando powerup: %s"):format(powerUpId))

	-- Remover frame de UI
	if ActivePowerUpFrames[powerUpId] then
		local data = ActivePowerUpFrames[powerUpId]
		if data.Frame and data.Frame.Parent then
			-- AnimaciÃÂ³n de salida (fade out)
			local tweenOut = TweenService:Create(data.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 0, 0, 0)
			})
			tweenOut:Play()
			tweenOut.Completed:Wait()
			data.Frame:Destroy()
		end
		ActivePowerUpFrames[powerUpId] = nil
		print(("[PowerUpUI] ? Frame de UI removido: %s"):format(powerUpId))
	else
		print(("[PowerUpUI] ?? No se encontrÃÂ³ frame activo para: %s"):format(powerUpId))
	end

	-- Remover efectos visuales
	if ActiveEffects[powerUpId] then
		for _, effect in ipairs(ActiveEffects[powerUpId]) do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end
		ActiveEffects[powerUpId] = nil
		print(("[PowerUpUI] ? Efectos visuales removidos: %s"):format(powerUpId))
	end
end)

-- Powerup recogido (feedback instantÃÂ¡neo)
PowerUpCollected.OnClientEvent:Connect(function(powerUpId: string)
	-- Sonido de pickup (puedes agregar un SoundService aquÃÂ­)
	-- Por ahora solo print
	print(("[PowerUpUI] PowerUp recogido: %s"):format(powerUpId))
end)

-- -----------------------------------------------------------------------
-- UPDATE LOOP PARA TIMERS
-- -----------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	local now = tick()

	for powerUpId, data in pairs(ActivePowerUpFrames) do
		if data.Frame and data.Frame.Parent then
			local elapsed = now - data.StartTime
			local remaining = math.max(0, data.Duration - elapsed)
			local progress = data.Duration > 0 and (remaining / data.Duration) or 0

			-- Actualizar timer label
			local timerLabel = data.Frame:FindFirstChild("Timer")
			if timerLabel then
				timerLabel.Text = string.format("%.1fs", remaining)
			end

			-- Actualizar barra de progreso
			local progressBar = data.Frame:FindFirstChild("ProgressBack"):FindFirstChild("ProgressBar")
			if progressBar then
				progressBar.Size = UDim2.new(progress, 0, 1, 0)
			end
		end
	end
end)

-- -----------------------------------------------------------------------
-- CHARACTER RESPAWN HANDLER
-- -----------------------------------------------------------------------

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	-- Limpiar efectos anteriores
	for _, effects in pairs(ActiveEffects) do
		for _, effect in ipairs(effects) do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end
	end
	ActiveEffects = {}
end)

print("[PowerUpUI] ? PowerUp UI Client inicializado")