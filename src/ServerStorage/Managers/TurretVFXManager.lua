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
	local beamDuration = duration or 0.1  -- Default 100ms

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

	-- Beam láser (rojo brillante)
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
	beam.Brightness = 3
	beam.Width0 = 0.4
	beam.Width1 = 0.3
	beam.FaceCamera = true
	beam.Texture = "rbxasset://textures/particles/smoke_main.dds"  -- Textura suave
	beam.Parent = beamPart

	-- Efecto de impacto en el target
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

		-- Beam eléctrico (azul brillante con curva)
		local beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Color = ColorSequence.new(Color3.fromRGB(100, 150, 255))
		beam.Brightness = 4
		beam.Width0 = 0.5
		beam.Width1 = 0.5
		beam.FaceCamera = true
		beam.CurveSize0 = math.random(-5, 5)  -- Zigzag aleatorio
		beam.CurveSize1 = math.random(-5, 5)
		beam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		beam.Parent = chainPart

		-- Efecto de impacto en cada target
		self:CreateImpactEffect(target, Color3.fromRGB(150, 200, 255))

		-- Destruir después de 0.2s
		Debris:AddItem(chainPart, 0.2)
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
	local mainPart = model:FindFirstChild("MainPart") :: Part?
	if not mainPart then
		return
	end

	local position = mainPart.Position

	-- Efecto de luz ascendente
	local beam = Instance.new("Part")
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(100, 255, 100)
	beam.Size = Vector3.new(0.1, 8, 8)
	beam.Transparency = 0.5
	beam.Anchored = true
	beam.CanCollide = false
	beam.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = workspace

	-- Particles de upgrade
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
	particles.Size = NumberSequence.new(1, 0)
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 100
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Speed = NumberRange.new(10, 20)
	particles.Parent = mainPart

	-- Detener después de 0.5s
	task.delay(0.5, function()
		if particles then
			particles.Enabled = false
		end
	end)

	-- Destruir beam
	Debris:AddItem(beam, 1)
end

return TurretVFXManager
