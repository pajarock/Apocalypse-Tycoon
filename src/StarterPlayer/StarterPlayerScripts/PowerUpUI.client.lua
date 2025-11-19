--!strict
--[[
	═══════════════════════════════════════════════════════════════════════
	POWERUP UI CLIENT - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	UI Cliente para mostrar:
	✓ Powerups activos con temporizador
	✓ Efectos visuales en el jugador (auras, trails, etc.)
	✓ Notificaciones al recoger powerups
	✓ HUD épico y tóxico

	═══════════════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════════════════════

local ActivePowerUpFrames = {} -- {powerUpId: Frame}
local ActiveEffects = {} -- {powerUpId: {effects}}

-- ═══════════════════════════════════════════════════════════════════════
-- CREAR HUD DE POWERUPS
-- ═══════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════
-- CREAR FRAME DE POWERUP INDIVIDUAL
-- ═══════════════════════════════════════════════════════════════════════

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

	-- Animación de entrada (slide in desde la derecha)
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

-- ═══════════════════════════════════════════════════════════════════════
-- EFECTOS VISUALES EN EL PERSONAJE
-- ═══════════════════════════════════════════════════════════════════════

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

	-- Mesh esférico
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = aura

	-- Partículas
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

	-- Trail detrás del jugador
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
	-- (Esto iría en la base física, pero podemos hacer un indicador visual)

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

	-- Mesh cilíndrico
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

	-- Partículas eléctricas
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

	-- Partículas de velocidad
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

	-- Burst de partículas verdes curativas
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

	-- Desactivar después del burst inicial
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

	-- Animar expansión
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

	-- Partículas tech
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

	-- Pulsos electromagnéticos
	local jammer = Instance.new("Part")
	jammer.Name = "MeteorJammer"
	jammer.Size = Vector3.new(4, 4, 4)
	jammer.Anchored = true
	jammer.CanCollide = false
	jammer.Transparency = 0.5
	jammer.Material = Enum.Material.Neon
	jammer.Color = Color3.fromRGB(200, 100, 255)
	jammer.Parent = character

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = jammer

	-- Animar pulsos
	task.spawn(function()
		local t = 0
		while jammer and jammer.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.05
			local scale = 1 + math.sin(t * 8) * 0.5
			mesh.Scale = Vector3.new(scale, scale, scale)
			jammer.Transparency = 0.3 + math.abs(math.sin(t * 8)) * 0.4
			jammer.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 3, 0)
			task.wait(0.05)
		end
	end)

	table.insert(effects, jammer)

	return effects
end

local function createDefensiveBurstEffect(): {Instance}
	local effects = {}

	-- Explosión naranja masiva
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

	-- Expandir explosión
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

	-- Rayos eléctricos blancos
	local charge = Instance.new("Part")
	charge.Name = "UltraCharge"
	charge.Size = Vector3.new(6, 10, 6)
	charge.Anchored = true
	charge.CanCollide = false
	charge.Transparency = 0.3
	charge.Material = Enum.Material.Neon
	charge.Color = Color3.fromRGB(255, 255, 255)
	charge.Parent = character

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Cylinder
	mesh.Parent = charge

	-- Partículas eléctricas
	local lightning = Instance.new("ParticleEmitter")
	lightning.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	lightning.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	lightning.Size = NumberSequence.new(1)
	lightning.Lifetime = NumberRange.new(0.2, 0.5)
	lightning.Rate = 100
	lightning.Speed = NumberRange.new(15, 25)
	lightning.SpreadAngle = Vector2.new(180, 180)
	lightning.LightEmission = 1
	lightning.Parent = charge

	-- Animar
	task.spawn(function()
		local t = 0
		while charge and charge.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.05
			charge.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, 0, t * 10)
			task.wait(0.05)
		end
	end)

	table.insert(effects, charge)

	return effects
end

local function createEggCatalystEffect(): {Instance}
	local effects = {}

	-- Sparkles dorados
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Color3.fromRGB(255, 220, 100)
	sparkles.Parent = humanoidRootPart

	-- Partículas de huevo
	local eggParticles = Instance.new("ParticleEmitter")
	eggParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	eggParticles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
	eggParticles.Size = NumberSequence.new(0.5)
	eggParticles.Lifetime = NumberRange.new(1, 2)
	eggParticles.Rate = 30
	eggParticles.Speed = NumberRange.new(3, 6)
	eggParticles.LightEmission = 0.8
	eggParticles.Parent = humanoidRootPart

	table.insert(effects, sparkles)
	table.insert(effects, eggParticles)

	return effects
end

local function createIncomeBoostEffect(): {Instance}
	local effects = {}

	-- Lluvia de monedas doradas
	local coinRain = Instance.new("ParticleEmitter")
	coinRain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	coinRain.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	coinRain.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	coinRain.Lifetime = NumberRange.new(2, 3)
	coinRain.Rate = 40
	coinRain.Speed = NumberRange.new(5, 10)
	coinRain.SpreadAngle = Vector2.new(30, 30)
	coinRain.LightEmission = 1
	coinRain.Parent = humanoidRootPart

	-- Aura dorada
	local goldAura = Instance.new("Part")
	goldAura.Name = "GoldAura"
	goldAura.Size = Vector3.new(6, 6, 6)
	goldAura.Anchored = true
	goldAura.CanCollide = false
	goldAura.Transparency = 0.7
	goldAura.Material = Enum.Material.Neon
	goldAura.Color = Color3.fromRGB(255, 215, 0)
	goldAura.Parent = character

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = goldAura

	-- Animar aura
	task.spawn(function()
		local t = 0
		while goldAura and goldAura.Parent and humanoidRootPart and humanoidRootPart.Parent do
			t += 0.016
			local scale = 1 + math.sin(t * 4) * 0.3
			mesh.Scale = Vector3.new(scale, scale, scale)
			goldAura.CFrame = humanoidRootPart.CFrame
			task.wait(0.016)
		end
	end)

	table.insert(effects, coinRain)
	table.insert(effects, goldAura)

	return effects
end

-- ═══════════════════════════════════════════════════════════════════════
-- MAPEO DE EFECTOS VISUALES
-- ═══════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════
-- MANEJO DE EVENTOS DE POWERUPS
-- ═══════════════════════════════════════════════════════════════════════

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
	GodShield = "🛡️",
	DoubleDamage = "⚔️",
	SuperDash = "💨",
	FullHeal = "❤️",
	MiniDrone = "🛸",
	SpeedBoost = "⚡",
	BaseShield = "🛡️",
	MeteorJammer = "📡",
	DefensiveBurst = "💥",
	CriticalParry = "🔥",
	UltraCharge = "⚡",
	EggCatalyst = "🥚",
	IncomeBoost = "💰",
}

-- Activar powerup
PowerUpActivated.OnClientEvent:Connect(function(powerUpId: string, duration: number)
	print(("[PowerUpUI] 🎁 Activando powerup: %s (duración: %.1fs)"):format(powerUpId, duration or 0))

	-- ✅ LIMPIAR powerup existente si ya está activo
	if ActivePowerUpFrames[powerUpId] then
		print(("[PowerUpUI] ⚠️ Ya existe powerup activo: %s - Limpiando..."):format(powerUpId))

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
	local icon = PowerUpIcons[powerUpId] or "✨"

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
		print(("[PowerUpUI] ✅ Efectos visuales creados para: %s"):format(powerUpId))
	end

	-- Notificación flotante
	local notification = Instance.new("ScreenGui")
	notification.Name = "PowerUpNotification"
	notification.ResetOnSpawn = false
	notification.Parent = playerGui

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, 400, 0, 100)
	notifFrame.Position = UDim2.new(0.5, -200, 0, -150) -- Start above screen
	notifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	notifFrame.BackgroundTransparency = 0.2
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notification

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = notifFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 4
	stroke.Parent = notifFrame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 80, 0, 80)
	iconLabel.Position = UDim2.new(0, 10, 0.5, -40)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Text = icon
	iconLabel.Parent = notifFrame

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -100, 1, 0)
	textLabel.Position = UDim2.new(0, 100, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 24
	textLabel.TextColor3 = color
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Text = "POWERUP ACTIVATED!\n" .. powerUpId:gsub("(%u)", " %1"):sub(2)
	textLabel.Parent = notifFrame

	-- Animar notificación (slide in, hold, slide out)
	local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0, 50)
	})
	tweenIn:Play()

	task.wait(2)

	local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -200, 0, -150)
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	notification:Destroy()
end)

-- Expirar powerup
PowerUpExpired.OnClientEvent:Connect(function(powerUpId: string)
	print(("[PowerUpUI] 🔄 Expirando powerup: %s"):format(powerUpId))

	-- Remover frame de UI
	if ActivePowerUpFrames[powerUpId] then
		local data = ActivePowerUpFrames[powerUpId]
		if data.Frame and data.Frame.Parent then
			-- Animación de salida (fade out)
			local tweenOut = TweenService:Create(data.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 0, 0, 0)
			})
			tweenOut:Play()
			tweenOut.Completed:Wait()
			data.Frame:Destroy()
		end
		ActivePowerUpFrames[powerUpId] = nil
		print(("[PowerUpUI] ✅ Frame de UI removido: %s"):format(powerUpId))
	else
		print(("[PowerUpUI] ⚠️ No se encontró frame activo para: %s"):format(powerUpId))
	end

	-- Remover efectos visuales
	if ActiveEffects[powerUpId] then
		for _, effect in ipairs(ActiveEffects[powerUpId]) do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end
		ActiveEffects[powerUpId] = nil
		print(("[PowerUpUI] ✅ Efectos visuales removidos: %s"):format(powerUpId))
	end
end)

-- Powerup recogido (feedback instantáneo)
PowerUpCollected.OnClientEvent:Connect(function(powerUpId: string)
	-- Sonido de pickup (puedes agregar un SoundService aquí)
	-- Por ahora solo print
	print(("[PowerUpUI] PowerUp recogido: %s"):format(powerUpId))
end)

-- ═══════════════════════════════════════════════════════════════════════
-- UPDATE LOOP PARA TIMERS
-- ═══════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════
-- CHARACTER RESPAWN HANDLER
-- ═══════════════════════════════════════════════════════════════════════

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

print("[PowerUpUI] ✅ PowerUp UI Client inicializado")
