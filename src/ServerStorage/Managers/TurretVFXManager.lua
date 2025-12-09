--!strict
--[[
	TurretVFXManager.lua - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Manager para efectos visuales de torretas defensivas.

	RESPONSABILIDADES:
	- Beams para Machine Gun y Laser
	- Explosiones para Missile Launcher
	- Cadenas eléctricas para Tesla Coil
	- Shield Dome visual
	- Efectos de upgrade

	OPTIMIZACIÓN:
	- Usa object pooling para particles
	- Limpia efectos automáticamente con Debris
	- VFX simples pero efectivos

	═══════════════════════════════════════════════════════════════════════
]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------

local CONSTRUCTION_DURATION = 1 -- Segundos de animación de construcción
local CONSTRUCTION_START_OFFSET = -10 -- Studs bajo tierra al inicio
local GLOW_PULSE_SPEED = 1 -- Velocidad del pulso (segundos)
local PARTICLE_RATE = 5 -- Partículas por segundo (más sutil que generadores)
local PLACEMENT_SOUND_ID = "rbxassetid://9116673678" -- Sonido al colocar
local UPGRADE_SOUND_ID = "rbxassetid://85188753846582" -- Sonido de upgrade

-------------------------------------------------------------------------
-- TIER CONFIGURATIONS
-------------------------------------------------------------------------

type TierConfig = {
	Name: string,
	Color: Color3,
	GlowColor: Color3,
	ParticleColor: ColorSequence,
	ParticleTexture: string,
}

-- Configuración visual por tier (T1 → T5, progresivamente más dramático)
local TIER_CONFIGS: {[number]: TierConfig} = {
	-- Tier 1: Gris básico
	[1] = {
		Name = "Basic",
		Color = Color3.fromRGB(120, 120, 140),
		GlowColor = Color3.fromRGB(150, 150, 180),
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 120)),
		}),
		ParticleTexture = "rbxasset://textures/particles/smoke_main.dds",
	},

	-- Tier 2: Gris azulado
	[2] = {
		Name = "Advanced",
		Color = Color3.fromRGB(140, 140, 160),
		GlowColor = Color3.fromRGB(170, 180, 200),
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 210, 230)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 130, 160)),
		}),
		ParticleTexture = "rbxasset://textures/particles/smoke_main.dds",
	},

	-- Tier 3: Gris plateado
	[3] = {
		Name = "Elite",
		Color = Color3.fromRGB(160, 160, 180),
		GlowColor = Color3.fromRGB(200, 210, 230),
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 230, 250)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 150, 180)),
		}),
		ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
	},

	-- Tier 4: Gris brillante con tinte azul
	[4] = {
		Name = "Supreme",
		Color = Color3.fromRGB(180, 190, 210),
		GlowColor = Color3.fromRGB(220, 230, 255),
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(240, 245, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 170, 200)),
		}),
		ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
	},

	-- Tier 5: Blanco brillante (MAX)
	[5] = {
		Name = "MAX",
		Color = Color3.fromRGB(200, 210, 230),
		GlowColor = Color3.fromRGB(255, 255, 255),
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 220)),
		}),
		ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
	},
}

-- Configuración de partículas por tipo de torreta
local TURRET_TYPE_PARTICLES = {
	MachineGun = {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(150, 150, 150)),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(1, 3),
	},
	Laser = {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 100, 100)),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(2, 4),
	},
	Missile = {
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(255, 150, 50)),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(1, 2),
	},
	Tesla = {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(100, 150, 255)),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(3, 5),
	},
	ShieldDome = {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(1, 2),
	},
}

-------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------

local TurretVFXManager = {}

--[[────────────────────────────────────────────────────────────────────────
	MACHINE GUN VFX
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un tracer visual para disparos de Machine Gun.

	@param origin - Posición de inicio (torreta)
	@param target - Posición de destino (meteorito)
	@param color - Color del tracer (opcional)
]]
function TurretVFXManager:CreateMachineGunTracer(origin: Vector3, target: Vector3, color: Color3?)
	local tracerColor = color or Color3.fromRGB(255, 200, 50)  -- Amarillo brillante

	-- Crear Part invisible para attachment
	local tracerPart = Instance.new("Part")
	tracerPart.Anchored = true
	tracerPart.CanCollide = false
	tracerPart.Transparency = 1
	tracerPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tracerPart.Position = origin
	tracerPart.Parent = workspace

	-- Crear Attachment
	local attachment = Instance.new("Attachment")
	attachment.Parent = tracerPart

	-- Crear Beam desde torreta hasta target
	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment
	beam.Attachment1 = self:CreateTargetAttachment(target)
	beam.Color = ColorSequence.new(tracerColor)
	beam.Brightness = 2
	beam.Width0 = 0.2
	beam.Width1 = 0.1
	beam.FaceCamera = true
	beam.Parent = tracerPart

	-- Destruir después de un momento
	Debris:AddItem(tracerPart, 0.1)  -- Tracer muy corto (100ms)
end

--[[────────────────────────────────────────────────────────────────────────
	LASER VFX
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un beam láser continuo.

	@param origin - Posición de inicio (torreta)
	@param target - Posición de destino (meteorito)
	@param duration - Duración del beam en segundos
	@return Part - Part del beam para control posterior
]]
function TurretVFXManager:CreateLaserBeam(origin: Vector3, target: Vector3, duration: number?): Part?
	local beamDuration = duration or 0.3  -- Increased from 0.1 to 0.3 seconds for better visibility

	-- Crear Part invisible
	local beamPart = Instance.new("Part")
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.Transparency = 1
	beamPart.Size = Vector3.new(0.1, 0.1, 0.1)
	beamPart.Position = origin
	beamPart.Parent = workspace

	-- Attachments
	local att0 = Instance.new("Attachment")
	att0.Parent = beamPart

	local att1 = self:CreateTargetAttachment(target)

	-- Beam láser (rojo brillante, más grueso y brillante)
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
	beam.Brightness = 7  -- Increased from 3 to 7 for much better visibility
	beam.Width0 = 1.5  -- Increased from 0.4 to 1.5 studs
	beam.Width1 = 1.2  -- Increased from 0.3 to 1.2 studs
	beam.FaceCamera = true
	beam.Texture = "rbxasset://textures/particles/smoke_main.dds"  -- Textura suave
	beam.Parent = beamPart

	-- Efecto de impacto en el target más visible
	self:CreateImpactEffect(target, Color3.fromRGB(255, 100, 100))

	-- Destruir automáticamente
	Debris:AddItem(beamPart, beamDuration)

	return beamPart
end

--[[────────────────────────────────────────────────────────────────────────
	MISSILE VFX
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea una explosión visual para Missile Launcher.

	@param position - Posición de la explosión
	@param radius - Radio de la explosión (para scale)
]]
function TurretVFXManager:CreateMissileExplosion(position: Vector3, radius: number?)
	local explosionRadius = radius or 12

	-- Esfera de explosión
	local sphere = Instance.new("Part")
	sphere.Shape = Enum.PartType.Ball
	sphere.Material = Enum.Material.Neon
	sphere.Color = Color3.fromRGB(255, 150, 50)  -- Naranja brillante
	sphere.Size = Vector3.new(1, 1, 1)
	sphere.Transparency = 0.3
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.Position = position
	sphere.Parent = workspace

	-- Animación de expansión
	local targetSize = explosionRadius * 2
	local expandTime = 0.3

	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < expandTime do
			local alpha = (tick() - startTime) / expandTime
			sphere.Size = Vector3.new(targetSize * alpha, targetSize * alpha, targetSize * alpha)
			sphere.Transparency = 0.3 + (alpha * 0.7)  -- Fade out
			task.wait()
		end
		sphere:Destroy()
	end)

	-- Particles de explosión
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
	particleEmitter.Size = NumberSequence.new(2, 0)
	particleEmitter.Lifetime = NumberRange.new(0.5, 1)
	particleEmitter.Rate = 100
	particleEmitter.SpreadAngle = Vector2.new(180, 180)
	particleEmitter.Speed = NumberRange.new(10, 20)
	particleEmitter.Parent = sphere

	-- Detener emisión después de 0.2s
	task.delay(0.2, function()
		if particleEmitter then
			particleEmitter.Enabled = false
		end
	end)

	-- Destruir después de 1 segundo
	Debris:AddItem(sphere, 1)
end

--[[
	Crea un proyectil de misil que viaja hacia el target.

	@param origin - Posición de origen (torreta)
	@param target - Posición de destino
	@param speed - Velocidad del proyectil (default 120)
	@param onImpact - Callback cuando el proyectil llega al target
	@return Part - El proyectil para tracking
]]
function TurretVFXManager:CreateMissileProjectile(origin: Vector3, target: Vector3, speed: number?, onImpact: ((Vector3) -> ())?): Part?
	local projectileSpeed = speed or 120

	-- Crear proyectil del misil
	local missile = Instance.new("Part")
	missile.Name = "MissileProjectile"
	missile.Shape = Enum.PartType.Cylinder
	missile.Size = Vector3.new(3, 0.8, 0.8)  -- Cilindro alargado
	missile.Material = Enum.Material.Neon
	missile.Color = Color3.fromRGB(200, 200, 200)  -- Gris metálico
	missile.Anchored = false
	missile.CanCollide = false
	missile.Position = origin
	missile.Parent = workspace

	-- Orientar el misil hacia el target
	local direction = (target - origin).Unit
	missile.CFrame = CFrame.lookAt(origin, target) * CFrame.Angles(0, 0, math.pi/2)

	-- Trail de humo
	local att0 = Instance.new("Attachment", missile)
	local att1 = Instance.new("Attachment", missile)
	att1.Position = Vector3.new(-1.5, 0, 0)

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.5
	trail.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Parent = missile

	-- Particles de propulsión
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 10
	fire.Color = Color3.fromRGB(255, 150, 50)
	fire.SecondaryColor = Color3.fromRGB(255, 100, 0)
	fire.Parent = missile

	-- BodyVelocity para movimiento
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = direction * projectileSpeed
	bv.Parent = missile

	-- Detectar llegada al target (por distancia)
	local startTime = tick()
	local maxTravelTime = 5  -- Máximo 5 segundos de vuelo

	task.spawn(function()
		while missile and missile.Parent do
			local distanceToTarget = (missile.Position - target).Magnitude

			-- Si llegó al target (dentro de 5 studs) o timeout
			if distanceToTarget < 5 or (tick() - startTime) > maxTravelTime then
				if onImpact then
					onImpact(missile.Position)
				end
				missile:Destroy()
				break
			end

			task.wait()
		end
	end)

	-- Safety: destruir después de maxTravelTime
	Debris:AddItem(missile, maxTravelTime)

	return missile
end

--[[────────────────────────────────────────────────────────────────────────
	TESLA VFX
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea cadenas eléctricas visuales entre targets.

	@param targets - Array de posiciones Vector3 conectadas por cadenas
]]
function TurretVFXManager:CreateTeslaChain(targets: {Vector3})
	if #targets < 2 then
		return
	end

	for i = 1, #targets - 1 do
		local origin = targets[i]
		local target = targets[i + 1]

		-- Crear beam eléctrico
		local chainPart = Instance.new("Part")
		chainPart.Anchored = true
		chainPart.CanCollide = false
		chainPart.Transparency = 1
		chainPart.Size = Vector3.new(0.1, 0.1, 0.1)
		chainPart.Position = origin
		chainPart.Parent = workspace

		local att0 = Instance.new("Attachment")
		att0.Parent = chainPart

		local att1 = self:CreateTargetAttachment(target)

		-- Beam eléctrico (azul brillante con curva, mejorado para visibilidad)
		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Color = ColorSequence.new(Color3.fromRGB(100, 150, 255))
		beam.Brightness = 6  -- Increased from 4 to 6 for better visibility
		beam.Width0 = 1.5  -- Increased from 0.5 to 1.5 (3x thicker)
		beam.Width1 = 1.5  -- Increased from 0.5 to 1.5 (3x thicker)
		beam.FaceCamera = true
		beam.CurveSize0 = math.random(-8, 8)  -- Increased zigzag for dramatic effect
		beam.CurveSize1 = math.random(-8, 8)
		beam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		beam.Parent = chainPart

		-- Efecto de impacto en cada target
		self:CreateImpactEffect(target, Color3.fromRGB(150, 200, 255))

		-- Destruir después de 0.4s (increased from 0.2s for better visibility)
		Debris:AddItem(chainPart, 0.4)
	end
end

--[[────────────────────────────────────────────────────────────────────────
	SHIELD DOME VFX
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un domo de escudo visual.

	@param center - Centro del domo
	@param radius - Radio del domo
	@return Part - Domo visual para control posterior
]]
function TurretVFXManager:CreateShieldDome(center: Vector3, radius: number): Part?
	-- Crear esfera transparente
	local dome = Instance.new("Part")
	dome.Shape = Enum.PartType.Ball
	dome.Material = Enum.Material.ForceField
	dome.Color = Color3.fromRGB(100, 200, 255)
	dome.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
	dome.Transparency = 0.7
	dome.Anchored = true
	dome.CanCollide = false
	dome.Position = center
	dome.Parent = workspace

	-- Efecto de activación (fade in)
	local originalTransparency = 0.7
	dome.Transparency = 1

	task.spawn(function()
		for i = 1, 10 do
			dome.Transparency = 1 - ((i / 10) * (1 - originalTransparency))
			task.wait(0.05)
		end
	end)

	-- Particles (opcional, efecto de energía)
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
	particles.Size = NumberSequence.new(0.5, 0.2)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Speed = NumberRange.new(2, 5)
	particles.Parent = dome

	return dome
end

--[[
	Destruye el domo de escudo con animación.

	@param dome - Domo a destruir
]]
function TurretVFXManager:DestroyShieldDome(dome: Part)
	if not dome or not dome.Parent then
		return
	end

	-- Animación de desaparición
	task.spawn(function()
		for i = 1, 10 do
			dome.Transparency = dome.Transparency + 0.03
			task.wait(0.05)
		end
		dome:Destroy()
	end)
end

--[[────────────────────────────────────────────────────────────────────────
	HELPER FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un Attachment temporal en una posición target.

	@param position - Posición del attachment
	@return Attachment - Attachment creado
]]
function TurretVFXManager:CreateTargetAttachment(position: Vector3): Attachment
	local targetPart = Instance.new("Part")
	targetPart.Anchored = true
	targetPart.CanCollide = false
	targetPart.Transparency = 1
	targetPart.Size = Vector3.new(0.1, 0.1, 0.1)
	targetPart.Position = position
	targetPart.Parent = workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = targetPart

	-- Auto-destruir después de 1 segundo
	Debris:AddItem(targetPart, 1)

	return attachment
end

--[[
	Crea un efecto de impacto en una posición.

	@param position - Posición del impacto
	@param color - Color del efecto (opcional)
]]
function TurretVFXManager:CreateImpactEffect(position: Vector3, color: Color3?)
	local impactColor = color or Color3.fromRGB(255, 200, 100)

	-- Crear part para particles
	local impactPart = Instance.new("Part")
	impactPart.Anchored = true
	impactPart.CanCollide = false
	impactPart.Transparency = 1
	impactPart.Size = Vector3.new(0.1, 0.1, 0.1)
	impactPart.Position = position
	impactPart.Parent = workspace

	-- Particles de impacto
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(impactColor)
	particles.Size = NumberSequence.new(0.5, 0)
	particles.Lifetime = NumberRange.new(0.2, 0.4)
	particles.Rate = 50
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Speed = NumberRange.new(5, 10)
	particles.Parent = impactPart

	-- Emitir burst y destruir
	particles:Emit(10)
	Debris:AddItem(impactPart, 0.5)
end

--[[
	Efecto visual de upgrade para torretas.

	@param model - Modelo de la torreta
	@param oldTier - Tier anterior
	@param newTier - Nuevo tier
]]
function TurretVFXManager:PlayUpgradeEffect(model: Model, oldTier: number, newTier: number)
	print(string.format("[TurretVFXManager] 🎨 PlayUpgradeEffect CALLED: T%d → T%d", oldTier, newTier))

	local mainPart = model:FindFirstChild("MainPart") :: Part?
	if not mainPart then
		warn("[TurretVFXManager] ❌ PlayUpgradeEffect: MainPart not found!")
		return
	end

	print("[TurretVFXManager] ✅ MainPart found, creating upgrade effects...")

	local position = mainPart.Position

	-- Reproducir sonido de upgrade
	local upgradeSound = Instance.new("Sound")
	upgradeSound.SoundId = UPGRADE_SOUND_ID
	upgradeSound.Volume = 0.8
	upgradeSound.Parent = mainPart
	upgradeSound:Play()
	Debris:AddItem(upgradeSound, 3)

	-- Crear flash de luz DORADO
	local flashLight = Instance.new("PointLight")
	flashLight.Brightness = 10
	flashLight.Range = 30
	flashLight.Color = Color3.fromRGB(255, 215, 0) -- Dorado
	flashLight.Parent = mainPart

	-- Fade out del flash
	local flashTween = TweenService:Create(
		flashLight,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }
	)
	flashTween:Play()
	Debris:AddItem(flashLight, 2)

	-- Crear partículas DORADAS explosivas
	local upgradeParticles = Instance.new("ParticleEmitter")
	upgradeParticles.Name = "UpgradeParticles"
	upgradeParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	upgradeParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),   -- Dorado
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 150)), -- Amarillo claro
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 0)),    -- Dorado oscuro
	})
	upgradeParticles.Rate = 0  -- Usaremos Emit() para burst
	upgradeParticles.Lifetime = NumberRange.new(1, 1.5)
	upgradeParticles.Speed = NumberRange.new(10, 20)
	upgradeParticles.SpreadAngle = Vector2.new(180, 180)
	upgradeParticles.Rotation = NumberRange.new(0, 360)
	upgradeParticles.RotSpeed = NumberRange.new(-100, 100)
	upgradeParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	upgradeParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	upgradeParticles.Parent = mainPart

	-- Burst de partículas DORADAS
	upgradeParticles:Emit(50)

	-- Limpiar partículas después
	Debris:AddItem(upgradeParticles, 2)

	-- Crear anillos de energía expandiéndose (3 anillos)
	for i = 1, 3 do
		task.delay(i * 0.2, function()
			local ring = Instance.new("Part")
			ring.Name = "UpgradeRing"
			ring.Size = Vector3.new(0.5, 0.5, 0.5)
			ring.Shape = Enum.PartType.Ball
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(255, 215, 0)  -- Dorado
			ring.Transparency = 0.3
			ring.Anchored = true
			ring.CanCollide = false
			ring.Position = position
			ring.Parent = workspace

			-- Expandir el anillo
			local ringTween = TweenService:Create(
				ring,
				TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = Vector3.new(15, 15, 15),
					Transparency = 1
				}
			)
			ringTween:Play()
			Debris:AddItem(ring, 1)
		end)
	end

	-- Mensaje flotante de upgrade
	local upgradeBillboard = Instance.new("BillboardGui")
	upgradeBillboard.Size = UDim2.new(8, 0, 2, 0)
	upgradeBillboard.StudsOffset = Vector3.new(0, 6, 0)
	upgradeBillboard.AlwaysOnTop = true
	upgradeBillboard.MaxDistance = 100
	upgradeBillboard.Adornee = mainPart

	-- Parent debe ser workspace o Effects folder
	local effectsFolder = workspace:FindFirstChild("Effects")
	if not effectsFolder then
		effectsFolder = Instance.new("Folder")
		effectsFolder.Name = "Effects"
		effectsFolder.Parent = workspace
	end
	upgradeBillboard.Parent = effectsFolder

	local upgradeLabel = Instance.new("TextLabel")
	upgradeLabel.Size = UDim2.new(1, 0, 1, 0)
	upgradeLabel.BackgroundTransparency = 1
	upgradeLabel.Text = string.format("✨ UPGRADED TO TIER %d! ✨", newTier)
	upgradeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	upgradeLabel.TextStrokeTransparency = 0
	upgradeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	upgradeLabel.Font = Enum.Font.GothamBold
	upgradeLabel.TextScaled = true
	upgradeLabel.Parent = upgradeBillboard

	-- Animar el texto flotando y desvaneciéndose
	local textTween = TweenService:Create(
		upgradeBillboard,
		TweenInfo.new(2.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ StudsOffset = Vector3.new(0, 10, 0) }
	)
	textTween:Play()

	-- Fade out del texto
	local fadeTween = TweenService:Create(
		upgradeLabel,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	fadeTween:Play()

	Debris:AddItem(upgradeBillboard, 3)

	print(string.format("[TurretVFXManager] ✨ Upgrade effect complete: T%d → T%d", oldTier, newTier))
end

--[[────────────────────────────────────────────────────────────────────────
	CONSTRUCTION & PLACEMENT SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Anima la construcción de una torreta (aparece desde abajo).

	@param model - Modelo de la torreta
	@param finalPosition - Posición final donde debe quedar
	@param turretName - Nombre de la torreta (ej: "MachineGunT1")
]]
function TurretVFXManager:PlayConstructionAnimation(model: Model, finalPosition: Vector3, turretName: string)
	-- Obtener PrimaryPart o MainPart
	local primaryPart = model.PrimaryPart or model:FindFirstChild("MainPart")
	if not primaryPart then
		warn("[TurretVFXManager] No PrimaryPart or MainPart found for construction animation")
		return
	end

	-- Posición inicial (bajo tierra)
	local startPosition = finalPosition + Vector3.new(0, CONSTRUCTION_START_OFFSET, 0)

	-- Mover a posición inicial
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(startPosition))
	else
		primaryPart.Position = startPosition
	end

	-- Reproducir sonido de placement
	local placementSound = Instance.new("Sound")
	placementSound.SoundId = PLACEMENT_SOUND_ID
	placementSound.Volume = 0.7
	placementSound.Parent = primaryPart
	placementSound:Play()
	Debris:AddItem(placementSound, 3)

	-- Crear partículas temporales de construcción (polvo gris)
	local constructionParticles = Instance.new("ParticleEmitter")
	constructionParticles.Name = "ConstructionParticles"
	constructionParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	constructionParticles.Color = ColorSequence.new(Color3.fromRGB(100, 100, 100))
	constructionParticles.Rate = 50
	constructionParticles.Lifetime = NumberRange.new(0.5, 1)
	constructionParticles.Speed = NumberRange.new(5, 10)
	constructionParticles.SpreadAngle = Vector2.new(180, 180)
	constructionParticles.EmissionDirection = Enum.NormalId.Top
	constructionParticles.Parent = primaryPart

	-- Tween de construcción
	local tweenInfo = TweenInfo.new(
		CONSTRUCTION_DURATION,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

	local tween
	if model.PrimaryPart then
		tween = TweenService:Create(
			model.PrimaryPart,
			tweenInfo,
			{ CFrame = CFrame.new(finalPosition) }
		)
	else
		tween = TweenService:Create(
			primaryPart,
			tweenInfo,
			{ Position = finalPosition }
		)
	end

	tween:Play()

	-- Limpiar partículas de construcción después de la animación
	task.delay(CONSTRUCTION_DURATION, function()
		constructionParticles:Destroy()

		-- Reproducir sonido de "clank" al terminar
		local clankSound = Instance.new("Sound")
		clankSound.SoundId = "rbxassetid://3765689841"
		clankSound.Volume = 0.6
		clankSound.Parent = primaryPart
		clankSound:Play()
		Debris:AddItem(clankSound, 2)
	end)

	print("[TurretVFXManager] Construction animation started for", turretName)
end

--[[────────────────────────────────────────────────────────────────────────
	IDLE VFX SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Aplica un efecto de glow pulsante al MainPart de la torreta.

	@param model - Modelo de la torreta
	@param tier - Tier de la torreta (1-5)
]]
function TurretVFXManager:ApplyGlowPulse(model: Model, tier: number)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[TurretVFXManager] MainPart not found in turret model")
		return
	end

	local tierConfig = TIER_CONFIGS[tier] or TIER_CONFIGS[1]

	-- Aplicar material Neon (el color ya está establecido por TurretDefinitions)
	mainPart.Material = Enum.Material.Neon
	-- NO sobrescribir el color - TurretDefinitions controla el color del modelo

	-- Crear PointLight para el glow (si no existe ya)
	local existingLight = mainPart:FindFirstChild("TurretGlow") :: PointLight?
	if not existingLight then
		local pointLight = Instance.new("PointLight")
		pointLight.Name = "TurretGlow"
		pointLight.Color = tierConfig.GlowColor
		pointLight.Brightness = 2
		pointLight.Range = 12
		pointLight.Parent = mainPart

		-- Animación de pulso infinita
		local pulseTween = TweenService:Create(
			pointLight,
			TweenInfo.new(
				GLOW_PULSE_SPEED,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1, -- Infinite
				true -- Reverses
			),
			{ Brightness = 4 }
		)

		pulseTween:Play()
	end

	print(string.format("[TurretVFXManager] Applied glow pulse to Tier %d turret", tier))
end

--[[
	Crea un sistema de partículas idle para la torreta.

	Combina el tier (color) con el tipo de torreta (estilo de partículas).

	@param model - Modelo de la torreta
	@param turretName - Nombre de la torreta (ej: "MachineGunT1")
	@param tier - Tier de la torreta (1-5)
	@return ParticleEmitter - El emitter creado
]]
function TurretVFXManager:CreateParticles(model: Model, turretName: string, tier: number): ParticleEmitter?
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[TurretVFXManager] MainPart not found in turret model")
		return nil
	end

	-- Verificar si ya existe
	local existingEmitter = mainPart:FindFirstChild("TurretParticles") :: ParticleEmitter?
	if existingEmitter then
		return existingEmitter
	end

	-- Obtener configuración del tier
	local tierConfig = TIER_CONFIGS[tier] or TIER_CONFIGS[1]

	-- Determinar tipo de torreta (MachineGun, Laser, Missile, Tesla, ShieldDome)
	local turretType = "MachineGun" -- Default
	if string.match(turretName, "^MachineGun") then
		turretType = "MachineGun"
	elseif string.match(turretName, "^Laser") then
		turretType = "Laser"
	elseif string.match(turretName, "^Missile") then
		turretType = "Missile"
	elseif string.match(turretName, "^Tesla") then
		turretType = "Tesla"
	elseif turretName == "ShieldDome" then
		turretType = "ShieldDome"
	end

	local typeConfig = TURRET_TYPE_PARTICLES[turretType] or TURRET_TYPE_PARTICLES.MachineGun

	-- Crear nuevo emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TurretParticles"
	emitter.Texture = typeConfig.Texture
	emitter.Color = tierConfig.ParticleColor -- Color del tier
	emitter.Rate = PARTICLE_RATE
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = typeConfig.Speed
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-50, 50)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	emitter.EmissionDirection = typeConfig.EmissionDirection
	emitter.VelocityInheritance = 0
	emitter.Acceleration = Vector3.new(0, 2, 0) -- Flotan hacia arriba sutilmente
	emitter.Parent = mainPart

	print(string.format("[TurretVFXManager] Created particles for %s Tier %d", turretType, tier))

	return emitter
end

--[[────────────────────────────────────────────────────────────────────────
	UTILITY FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Remueve todos los efectos visuales idle de una torreta.

	IMPORTANTE: Solo remueve efectos idle (luz, partículas),
	NO remueve ProximityPrompts ni BillboardGui.

	@param model - Modelo de la torreta
]]
function TurretVFXManager:RemoveEffects(model: Model)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return
	end

	-- Remover luz
	local light = mainPart:FindFirstChild("TurretGlow")
	if light then
		light:Destroy()
	end

	-- Remover partículas
	local particles = mainPart:FindFirstChild("TurretParticles")
	if particles then
		particles:Destroy()
	end

	print("[TurretVFXManager] Removed visual effects from turret")
end

--[[
	Obtiene la configuración de un tier específico.

	@param tier - Número de tier (1-5)
	@return TierConfig - Configuración del tier
]]
function TurretVFXManager:GetTierConfig(tier: number): TierConfig
	return TIER_CONFIGS[tier] or TIER_CONFIGS[1]
end

return TurretVFXManager
