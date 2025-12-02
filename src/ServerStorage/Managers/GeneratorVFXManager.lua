--!strict
--[[
	GENERATOR VFX MANAGER - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Sistema de efectos visuales para generadores con soporte multi-tier.

	FEATURES:
	✅ Billboard flotante animado (+$5, +$10, +$20)
	✅ Sistema de partículas modular (lava, cristal, energía)
	✅ Glow pulsante dinámico por tier
	✅ Performance-optimized con object pooling
	✅ Temática apocalíptica (3 tiers)
	✅ Sistema de sonidos (cash register, ambient, placement) [FASE 2]
	✅ Animación de construcción (tween desde abajo) [FASE 2]
	✅ ProximityPrompt con estadísticas [FASE 2]

	TIER SYSTEM:
	- Tier 1 (Volcánico): Rojo/Naranja, partículas de lava
	- Tier 2 (Meteórico): Púrpura, partículas de cristal
	- Tier 3 (Avanzado): Cyan, partículas de energía

	USAGE:
		local GeneratorVFXManager = require(ServerStorage.Managers.GeneratorVFXManager)

		-- Mostrar producción de dinero
		GeneratorVFXManager:ShowMoneyProduction(generatorModel, 5, 1) -- $5, Tier 1

		-- Aplicar glow pulsante
		GeneratorVFXManager:ApplyGlowPulse(generatorModel, 1) -- Tier 1

		-- Crear partículas
		GeneratorVFXManager:CreateParticles(generatorModel, 1) -- Tier 1

	API:
		:ShowMoneyProduction(model: Model, amount: number, tier: number)
		:ApplyGlowPulse(model: Model, tier: number)
		:CreateParticles(model: Model, tier: number) -> ParticleEmitter
		:RemoveEffects(model: Model)
		:GetTierConfig(tier: number) -> TierConfig
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------

local BILLBOARD_FLOAT_DURATION = 1.5 -- Segundos que flota el billboard
local BILLBOARD_FLOAT_HEIGHT = 5 -- Studs que sube
local GLOW_PULSE_SPEED = 1 -- Velocidad del pulso (segundos)
local PARTICLE_RATE = 10 -- Partículas por segundo
local DEBUG_MODE = true -- 🔍 Activado temporalmente para debugging de upgrades

-- FASE 2 Constants
local CONSTRUCTION_DURATION = 1 -- Segundos de animación de construcción
local CONSTRUCTION_START_OFFSET = -10 -- Studs bajo tierra al inicio
local CASH_REGISTER_SOUND_ID = "rbxassetid://1319346243" -- Sonido de cash register
local AMBIENT_SOUND_ID = "rbxassetid://128457230683862" -- Sonido ambient loop
local PLACEMENT_SOUND_ID = "rbxassetid://9116673678" -- Sonido al colocar
local AMBIENT_VOLUME = 0.3 -- Volumen del sonido ambient
local CASH_REGISTER_VOLUME = 0.5 -- Volumen del cash register
local PLACEMENT_VOLUME = 0.7 -- Volumen del placement

-- PHASE 4 Constants
local UPGRADE_SOUND_ID = "rbxassetid://5951069970" -- Sonido de upgrade mecánico/maquinaria
local UPGRADE_ANIMATION_DURATION = 1.5 -- Duración de animación de upgrade
local UPGRADE_PARTICLE_COUNT = 50 -- Cantidad de partículas de upgrade

-------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------

export type TierConfig = {
	Name: string,
	Color: Color3,
	GlowColor: Color3,
	ParticleColor: ColorSequence,
	ParticleTexture: string,
	MoneyColor: Color3,
}

-------------------------------------------------------------------------
-- TIER CONFIGURATIONS
-------------------------------------------------------------------------

local TIER_CONFIGS: {[number]: TierConfig} = {
	-- Tier 1: Extractor Volcánico
	[1] = {
		Name = "Volcánico",
		Color = Color3.fromRGB(255, 100, 50),      -- Naranja ardiente
		GlowColor = Color3.fromRGB(255, 80, 30),   -- Naranja más intenso
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 0)),   -- Naranja claro
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 0)),  -- Naranja medio
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 0)),    -- Rojo oscuro
		}),
		ParticleTexture = "rbxasset://textures/particles/smoke_main.dds",
		MoneyColor = Color3.fromRGB(255, 180, 50), -- Dorado cálido
	},

	-- Tier 2: Recolector Meteórico
	[2] = {
		Name = "Meteórico",
		Color = Color3.fromRGB(150, 50, 200),      -- Púrpura místico
		GlowColor = Color3.fromRGB(180, 70, 255),  -- Púrpura brillante
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 255)), -- Púrpura claro
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 50, 200)), -- Púrpura medio
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 30, 150)),  -- Púrpura oscuro
		}),
		ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		MoneyColor = Color3.fromRGB(200, 100, 255), -- Púrpura luminoso
	},

	-- Tier 3: Procesador Avanzado
	[3] = {
		Name = "Avanzado",
		Color = Color3.fromRGB(0, 255, 255),       -- Cyan brillante
		GlowColor = Color3.fromRGB(50, 255, 255),  -- Cyan eléctrico
		ParticleColor = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 255)), -- Cyan claro
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),  -- Cyan puro
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255)),   -- Azul cyan
		}),
		ParticleTexture = "rbxasset://textures/particles/fire_main.dds",
		MoneyColor = Color3.fromRGB(100, 255, 255), -- Cyan brillante
	},
}

-------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------

local GeneratorVFXManager = {}

-- Object pool para billboards
local billboardPool: {BillboardGui} = {}
local MAX_POOLED_BILLBOARDS = 20

-------------------------------------------------------------------------
-- BILLBOARD SYSTEM
-------------------------------------------------------------------------

--[[
	Crea o reutiliza un billboard del pool.

	@return BillboardGui
]]
local function getBillboardFromPool(): BillboardGui
	-- Intentar reutilizar del pool
	if #billboardPool > 0 then
		local billboard = table.remove(billboardPool)
		if billboard and billboard.Parent == nil then
			return billboard
		end
	end

	-- Crear nuevo billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 100

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.Name = "MoneyLabel"
	textLabel.Parent = billboard

	return billboard
end

--[[
	Devuelve un billboard al pool.

	@param billboard - Billboard a devolver
]]
local function returnBillboardToPool(billboard: BillboardGui)
	if #billboardPool < MAX_POOLED_BILLBOARDS then
		billboard.Parent = nil
		billboard.Enabled = true
		local label = billboard:FindFirstChild("MoneyLabel") :: TextLabel?
		if label then
			label.TextTransparency = 0
		end
		table.insert(billboardPool, billboard)
	else
		billboard:Destroy()
	end
end

--[[
	Muestra un billboard flotante con el dinero producido.

	@param model - Modelo del generador
	@param amount - Cantidad de dinero producida
	@param tier - Tier del generador (1, 2, 3)
]]
function GeneratorVFXManager:ShowMoneyProduction(model: Model, amount: number, tier: number)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[GeneratorVFXManager] MainPart not found in generator model")
		return
	end

	local tierConfig = TIER_CONFIGS[tier] or TIER_CONFIGS[1]

	-- Obtener billboard del pool
	local billboard = getBillboardFromPool()
	billboard.Adornee = mainPart

	-- Parent debe ser workspace o un folder, NO el mainPart
	local effectsFolder = workspace:FindFirstChild("Effects")
	if not effectsFolder then
		effectsFolder = Instance.new("Folder")
		effectsFolder.Name = "Effects"
		effectsFolder.Parent = workspace
	end
	billboard.Parent = effectsFolder

	-- Configurar texto
	local label = billboard:FindFirstChild("MoneyLabel") :: TextLabel
	if label then
		label.Text = string.format("+$%d", amount)
		label.TextColor3 = tierConfig.MoneyColor
	end

	-- Animación de flotación
	local startOffset = Vector3.new(0, 3, 0)
	local endOffset = Vector3.new(0, 3 + BILLBOARD_FLOAT_HEIGHT, 0)

	-- Tween de posición
	local positionTween = TweenService:Create(
		billboard,
		TweenInfo.new(
			BILLBOARD_FLOAT_DURATION,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{ StudsOffset = endOffset }
	)

	-- Tween de fade out
	if label then
		local fadeTween = TweenService:Create(
			label,
			TweenInfo.new(
				BILLBOARD_FLOAT_DURATION * 0.6, -- Empieza a desaparecer a 60% del tiempo
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out,
				0,
				false,
				BILLBOARD_FLOAT_DURATION * 0.4 -- Delay: empieza después del 40%
			),
			{ TextTransparency = 1 }
		)

		fadeTween:Play()
	end

	positionTween:Play()

	-- Limpiar después de la animación
	task.delay(BILLBOARD_FLOAT_DURATION, function()
		billboard.StudsOffset = startOffset -- Reset para próximo uso
		returnBillboardToPool(billboard)
	end)

	if DEBUG_MODE then
		print(string.format("[GeneratorVFXManager] Showed +$%d on Tier %d generator", amount, tier))
	end
end

-------------------------------------------------------------------------
-- GLOW PULSE SYSTEM
-------------------------------------------------------------------------

--[[
	Aplica un efecto de glow pulsante al MainPart del generador.

	@param model - Modelo del generador
	@param tier - Tier del generador (1, 2, 3)
]]
function GeneratorVFXManager:ApplyGlowPulse(model: Model, tier: number)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[GeneratorVFXManager] MainPart not found in generator model")
		return
	end

	local tierConfig = TIER_CONFIGS[tier] or TIER_CONFIGS[1]

	-- Aplicar material Neon
	mainPart.Material = Enum.Material.Neon
	mainPart.Color = tierConfig.Color

	-- Crear PointLight para el glow
	local existingLight = mainPart:FindFirstChild("GeneratorGlow") :: PointLight?
	if not existingLight then
		local pointLight = Instance.new("PointLight")
		pointLight.Name = "GeneratorGlow"
		pointLight.Color = tierConfig.GlowColor
		pointLight.Brightness = 2
		pointLight.Range = 15
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

	if DEBUG_MODE then
		print(string.format("[GeneratorVFXManager] Applied glow pulse to Tier %d generator", tier))
	end
end

-------------------------------------------------------------------------
-- PARTICLE SYSTEM
-------------------------------------------------------------------------

--[[
	Crea un sistema de partículas temático para el generador.

	@param model - Modelo del generador
	@param tier - Tier del generador (1, 2, 3)
	@return ParticleEmitter - El emitter creado
]]
function GeneratorVFXManager:CreateParticles(model: Model, tier: number): ParticleEmitter?
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[GeneratorVFXManager] MainPart not found in generator model")
		return nil
	end

	local tierConfig = TIER_CONFIGS[tier] or TIER_CONFIGS[1]

	-- Verificar si ya existe
	local existingEmitter = mainPart:FindFirstChild("GeneratorParticles") :: ParticleEmitter?
	if existingEmitter then
		return existingEmitter
	end

	-- Crear nuevo emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "GeneratorParticles"
	emitter.Texture = tierConfig.ParticleTexture
	emitter.Color = tierConfig.ParticleColor
	emitter.Rate = PARTICLE_RATE
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-50, 50)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.VelocityInheritance = 0
	emitter.Acceleration = Vector3.new(0, 3, 0) -- Flotan hacia arriba
	emitter.Parent = mainPart

	if DEBUG_MODE then
		print(string.format("[GeneratorVFXManager] Created particles for Tier %d generator", tier))
	end

	return emitter
end

-------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------------------------------

--[[
	Remueve todos los efectos visuales de un generador.

	IMPORTANTE: NO remueve el StatsBillboard ni los ProximityPrompts,
	solo los efectos visuales temporales (luz, partículas, billboards de dinero).

	@param model - Modelo del generador
]]
function GeneratorVFXManager:RemoveEffects(model: Model)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return
	end

	-- Remover luz
	local light = mainPart:FindFirstChild("GeneratorGlow")
	if light then
		light:Destroy()
	end

	-- Remover partículas
	local particles = mainPart:FindFirstChild("GeneratorParticles")
	if particles then
		particles:Destroy()
	end

	-- CRÍTICO: Solo remover billboards de efectos visuales, NO el StatsBillboard
	for _, child in mainPart:GetChildren() do
		if child:IsA("BillboardGui") and child.Name ~= "StatsBillboard" then
			child:Destroy()
		end
	end

	if DEBUG_MODE then
		print("[GeneratorVFXManager] Removed visual effects (preserved StatsBillboard)")
	end
end

--[[
	Obtiene la configuración de un tier específico.

	@param tier - Número de tier (1, 2, 3)
	@return TierConfig - Configuración del tier
]]
function GeneratorVFXManager:GetTierConfig(tier: number): TierConfig
	return TIER_CONFIGS[tier] or TIER_CONFIGS[1]
end

-------------------------------------------------------------------------
-- FASE 2: SOUND SYSTEM
-------------------------------------------------------------------------

--[[
	Crea un sonido de cash register cuando el generador produce dinero.

	@param model - Modelo del generador
]]
function GeneratorVFXManager:PlayCashRegisterSound(model: Model)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = CASH_REGISTER_SOUND_ID
	sound.Volume = CASH_REGISTER_VOLUME
	sound.Parent = mainPart
	sound:Play()

	-- Limpiar después de reproducir
	Debris:AddItem(sound, 2)
end

--[[
	Crea y activa el sonido ambient loop del generador.

	@param model - Modelo del generador
]]
function GeneratorVFXManager:CreateAmbientSound(model: Model)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return
	end

	-- Verificar si ya existe
	local existingSound = mainPart:FindFirstChild("GeneratorAmbient")
	if existingSound then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "GeneratorAmbient"
	sound.SoundId = AMBIENT_SOUND_ID
	sound.Volume = AMBIENT_VOLUME
	sound.Looped = true
	sound.RollOffMaxDistance = 50
	sound.RollOffMinDistance = 10
	sound.Parent = mainPart
	sound:Play()
end

--[[
	Reproduce el sonido de placement cuando se coloca el generador.

	@param model - Modelo del generador
]]
function GeneratorVFXManager:PlayPlacementSound(model: Model)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = PLACEMENT_SOUND_ID
	sound.Volume = PLACEMENT_VOLUME
	sound.Parent = mainPart
	sound:Play()

	Debris:AddItem(sound, 3)
end

-------------------------------------------------------------------------
-- FASE 2: CONSTRUCTION ANIMATION
-------------------------------------------------------------------------

--[[
	Anima la construcción del generador (aparece desde abajo).

	@param model - Modelo del generador
	@param finalPosition - Posición final donde debe quedar
	@param tier - Tier del generador
]]
function GeneratorVFXManager:PlayConstructionAnimation(model: Model, finalPosition: Vector3, tier: number)
	-- Obtener PrimaryPart o MainPart
	local primaryPart = model.PrimaryPart or model:FindFirstChild("MainPart")
	if not primaryPart then
		warn("[GeneratorVFXManager] No PrimaryPart or MainPart found for construction animation")
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
	self:PlayPlacementSound(model)

	-- Crear partículas temporales de construcción
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

		-- Activar efectos normales
		self:ApplyGlowPulse(model, tier)
		self:CreateParticles(model, tier)
		self:CreateAmbientSound(model)
	end)

	if DEBUG_MODE then
		print("[GeneratorVFXManager] Construction animation started")
	end
end

-------------------------------------------------------------------------
-- PHASE 4: UPGRADE EFFECTS SYSTEM
-------------------------------------------------------------------------

--[[
	Muestra efectos visuales espectaculares al upgradear un generator.

	EFECTOS:
	- Partículas doradas explosivas
	- Sonido de upgrade
	- Flash de luz
	- Tween suave de transformación

	@param model - Modelo del generator
	@param fromTier - Tier anterior
	@param toTier - Tier nuevo
]]
function GeneratorVFXManager:ShowUpgradeEffect(model: Model, fromTier: number, toTier: number)
	print(string.format("[GeneratorVFXManager] 🎨 ShowUpgradeEffect CALLED: T%d → T%d", fromTier, toTier))

	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[GeneratorVFXManager] ❌ ShowUpgradeEffect: MainPart not found!")
		return
	end

	print("[GeneratorVFXManager] ✅ MainPart found, creating upgrade effects...")

	-- Reproducir sonido de upgrade
	local upgradeSound = Instance.new("Sound")
	upgradeSound.SoundId = UPGRADE_SOUND_ID
	upgradeSound.Volume = 0.8
	upgradeSound.Parent = mainPart
	upgradeSound:Play()
	Debris:AddItem(upgradeSound, 3)

	-- Crear flash de luz
	local flashLight = Instance.new("PointLight")
	flashLight.Brightness = 10
	flashLight.Range = 30
	flashLight.Color = Color3.fromRGB(255, 215, 0) -- Dorado
	flashLight.Parent = mainPart

	-- Fade out del flash
	local flashTween = TweenService:Create(
		flashLight,
		TweenInfo.new(UPGRADE_ANIMATION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }
	)
	flashTween:Play()
	Debris:AddItem(flashLight, UPGRADE_ANIMATION_DURATION + 1)

	-- Crear partículas doradas explosivas
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

	-- Burst de partículas
	upgradeParticles:Emit(UPGRADE_PARTICLE_COUNT)

	-- Limpiar partículas después
	Debris:AddItem(upgradeParticles, 2)

	-- Crear anillos de energía expandiéndose
	for i = 1, 3 do
		task.delay(i * 0.2, function()
			local ring = Instance.new("Part")
			ring.Name = "UpgradeRing"
			ring.Size = Vector3.new(0.5, 0.5, 0.5)
			ring.Shape = Enum.PartType.Ball
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(255, 215, 0)
			ring.Transparency = 0.3
			ring.Anchored = true
			ring.CanCollide = false
			ring.Position = mainPart.Position
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

	-- Mensaje flotante de upgrade (FIX: usar Adornee + parent correcto)
	local upgradeBillboard = Instance.new("BillboardGui")
	upgradeBillboard.Size = UDim2.new(8, 0, 2, 0) -- Más grande para mejor visibilidad
	upgradeBillboard.StudsOffset = Vector3.new(0, 6, 0)
	upgradeBillboard.AlwaysOnTop = true
	upgradeBillboard.MaxDistance = 100
	upgradeBillboard.Adornee = mainPart -- 🔧 FIX: Configurar Adornee

	-- Parent debe ser workspace o Effects folder, NO mainPart
	local effectsFolder = workspace:FindFirstChild("Effects")
	if not effectsFolder then
		effectsFolder = Instance.new("Folder")
		effectsFolder.Name = "Effects"
		effectsFolder.Parent = workspace
	end
	upgradeBillboard.Parent = effectsFolder -- 🔧 FIX: Parent correcto

	local upgradeLabel = Instance.new("TextLabel")
	upgradeLabel.Size = UDim2.new(1, 0, 1, 0)
	upgradeLabel.BackgroundTransparency = 1
	upgradeLabel.Text = string.format("TIER %d", toTier) -- Texto simplificado
	upgradeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	upgradeLabel.TextStrokeTransparency = 0
	upgradeLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	upgradeLabel.Font = Enum.Font.FredokaOne -- Estilo grafiti
	upgradeLabel.TextScaled = true
	upgradeLabel.Parent = upgradeBillboard

	-- Animar el texto flotando y desvaneciéndose
	local textTween = TweenService:Create(
		upgradeBillboard,
		TweenInfo.new(2.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), -- Más tiempo + bounce
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

	Debris:AddItem(upgradeBillboard, 3) -- Más tiempo para verlo

	print(string.format("[GeneratorVFXManager] ✨ Billboard created! Text: '%s', Position: %s, Parent: %s",
		upgradeLabel.Text,
		tostring(upgradeBillboard.StudsOffset),
		upgradeBillboard.Parent.Name
	))

	if DEBUG_MODE then
		print(string.format("[GeneratorVFXManager] Upgrade effect played: T%d → T%d", fromTier, toTier))
	end
end

-------------------------------------------------------------------------
-- FASE 2: PROXIMITY PROMPT WITH STATS
-------------------------------------------------------------------------

--[[
	Crea un ProximityPrompt con estadísticas del generador.

	@param model - Modelo del generador
	@param userId - ID del dueño
	@param tier - Tier del generador
	@param objectId - ID único del objeto (PHASE 4)
	@return ProximityPrompt - El prompt creado
]]
function GeneratorVFXManager:CreateStatsPrompt(model: Model, userId: number, tier: number, objectId: string?): ProximityPrompt?
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return nil
	end

	-- PHASE 4: Guardar objectId en el modelo para uso en upgrades
	if objectId then
		local objectIdValue = Instance.new("StringValue")
		objectIdValue.Name = "ObjectId"
		objectIdValue.Value = objectId
		objectIdValue.Parent = mainPart
		print("[GeneratorVFXManager] 💾 ObjectId saved in model:", objectId)
	end

	-- Verificar si ya existe
	local existingPrompt = mainPart:FindFirstChild("StatsPrompt")
	if existingPrompt then
		return existingPrompt :: ProximityPrompt
	end

	-- Crear ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StatsPrompt"
	prompt.ActionText = "View Stats"
	prompt.ObjectText = "Generator"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = mainPart

	-- Crear BillboardGui para mostrar stats (invisible por defecto)
	local statsBillboard = Instance.new("BillboardGui")
	statsBillboard.Name = "StatsBillboard"
	statsBillboard.Size = UDim2.new(8, 0, 5, 0)
	statsBillboard.StudsOffset = Vector3.new(0, 4, 0)
	statsBillboard.AlwaysOnTop = true
	statsBillboard.Enabled = false -- Oculto por defecto
	statsBillboard.Parent = mainPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 2
	frame.BorderColor3 = TIER_CONFIGS[tier].Color
	frame.Parent = statsBillboard

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "StatsText"
	textLabel.Size = UDim2.new(1, -20, 0.75, -10)  -- Reducido para dejar espacio al botón
	textLabel.Position = UDim2.new(0, 10, 0, 10)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextScaled = false
	textLabel.TextSize = 18
	textLabel.Font = Enum.Font.Code
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Text = "Loading stats..."
	textLabel.Parent = frame

	-- PHASE 4: ProximityPrompt para UPGRADE (tecla R)
	local upgradePrompt = Instance.new("ProximityPrompt")
	upgradePrompt.Name = "UpgradePrompt"
	upgradePrompt.ActionText = "Upgrade Generator"
	upgradePrompt.ObjectText = ""
	upgradePrompt.KeyboardKeyCode = Enum.KeyCode.R
	upgradePrompt.MaxActivationDistance = 10
	upgradePrompt.HoldDuration = 0
	upgradePrompt.RequiresLineOfSight = false
	upgradePrompt.Enabled = false  -- Se activa cuando puede upgradear
	upgradePrompt.Parent = mainPart

	-- FASE 3: Función para actualizar stats dinámicamente
	local function updateStatsText()
		-- Leer valores del modelo
		local totalProducedValue = mainPart:FindFirstChild("TotalProduced")
		local spawnTimeValue = mainPart:FindFirstChild("SpawnTime")
		local moneyPerSecValue = mainPart:FindFirstChild("MoneyPerSec")
		local tierValue = mainPart:FindFirstChild("Tier")

		local totalProduced = totalProducedValue and totalProducedValue.Value or 0
		local spawnTime = spawnTimeValue and spawnTimeValue.Value or os.time()
		local moneyPerSec = moneyPerSecValue and moneyPerSecValue.Value or 0
		local currentTier = tierValue and tierValue.Value or tier

		-- Calcular uptime
		local uptime = os.time() - spawnTime
		local uptimeMinutes = math.floor(uptime / 60)
		local uptimeSeconds = uptime % 60

		-- Obtener configuración del tier
		local tierConfig = TIER_CONFIGS[currentTier] or TIER_CONFIGS[1]
		local Players = game:GetService("Players")
		local owner = Players:GetPlayerByUserId(userId)
		local ownerName = owner and owner.Name or "Unknown"

		-- PHASE 4: Verificar si puede upgradear y obtener costo
		local UpgradeDefinitions = require(game.ServerScriptService.Services.UpgradeDefinitions)
		local tierName = "Generator"
		if currentTier == 2 then
			tierName = "GeneratorT2"
		elseif currentTier == 3 then
			tierName = "GeneratorT3"
		end

		local canUpgrade = UpgradeDefinitions.CanUpgrade(tierName)
		local upgradeCost = UpgradeDefinitions.GetUpgradeCost(tierName)

		-- PHASE 4: Actualizar ProximityPrompt de upgrade
		if canUpgrade and upgradeCost then
			local nextTier = currentTier + 1
			upgradePrompt.ActionText = string.format("Upgrade to Tier %d ($%d)", nextTier, upgradeCost)
			upgradePrompt.Enabled = true
		else
			upgradePrompt.Enabled = false
		end

		-- Texto de stats (incluye info de upgrade)
		local upgradeText = ""
		if canUpgrade and upgradeCost then
			local nextTier = currentTier + 1
			upgradeText = string.format("\n✨ Press R to UPGRADE → Tier %d ($%d)", nextTier, upgradeCost)
		elseif currentTier >= 3 then
			upgradeText = "\n🏆 MAX TIER REACHED"
		end

		textLabel.Text = string.format([[
⚙️ %s
━━━━━━━━━━━━━━━━━
💰 Rate: $%d/sec
💵 Total: $%.0f
⏱️ Uptime: %dm %ds
👤 Owner: %s
━━━━━━━━━━━━━━━━━
Press E to close%s]], tierConfig.Name, moneyPerSec, totalProduced, uptimeMinutes, uptimeSeconds, ownerName, upgradeText)
	end

	-- Loop de actualización dinámica (cada segundo)
	local updateLoop = nil
	local statsVisible = false

	-- Evento para mostrar/ocultar stats
	prompt.Triggered:Connect(function(player)
		statsVisible = not statsVisible
		statsBillboard.Enabled = statsVisible

		if statsVisible then
			-- Actualizar inmediatamente al abrir
			updateStatsText()

			-- Iniciar loop de actualización
			updateLoop = task.spawn(function()
				while statsVisible and mainPart.Parent do
					task.wait(1)
					if statsVisible then
						updateStatsText()
					end
				end
			end)
		else
			-- Detener loop al cerrar
			if updateLoop then
				task.cancel(updateLoop)
				updateLoop = nil
			end
		end
	end)

	-- PHASE 4: Evento de upgrade (tecla R)
	upgradePrompt.Triggered:Connect(function(player)
		print("[GeneratorVFXManager] 🎯 Upgrade prompt triggered by:", player.Name)

		-- Obtener objectId
		local objectIdValue = mainPart:FindFirstChild("ObjectId")
		if not objectIdValue then
			warn("[GeneratorVFXManager] ❌ ObjectId not found!")
			return
		end

		local objectId = objectIdValue.Value

		-- Obtener UpgradeService
		local Knit = require(game.ReplicatedStorage.Knit)
		local UpgradeService = Knit.GetService("UpgradeService")

		-- Intentar upgradear
		local success = UpgradeService:UpgradeGenerator(objectId, player.UserId)

		if success then
			print("[GeneratorVFXManager] ✅ Upgrade successful!")
			-- Actualizar stats inmediatamente
			updateStatsText()
		else
			warn("[GeneratorVFXManager] ❌ Upgrade failed")
		end
	end)

	if DEBUG_MODE then
		print("[GeneratorVFXManager] Stats prompt created")
	end

	return prompt
end

-------------------------------------------------------------------------
-- PHASE 4: UPGRADE HELPERS
-------------------------------------------------------------------------

--[[
	Actualiza los ProximityPrompts después de un upgrade para reflejar el nuevo tier.

	CRÍTICO: Este método se llama después de que RemoveEffects() haya preservado
	el StatsBillboard, para asegurar que los prompts están correctamente actualizados.

	@param model - Modelo del generador
	@param newTier - Nuevo tier después del upgrade
]]
function GeneratorVFXManager:RefreshPromptsAfterUpgrade(model: Model, newTier: number)
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		warn("[GeneratorVFXManager] RefreshPromptsAfterUpgrade: MainPart not found")
		return
	end

	-- Verificar que el StatsPrompt existe (debería existir siempre)
	local statsPrompt = mainPart:FindFirstChild("StatsPrompt")
	if not statsPrompt then
		warn("[GeneratorVFXManager] ⚠️  WARNING: StatsPrompt not found after upgrade! This shouldn't happen.")
	end

	-- Verificar que el UpgradePrompt existe
	local upgradePrompt = mainPart:FindFirstChild("UpgradePrompt")
	if not upgradePrompt then
		warn("[GeneratorVFXManager] ⚠️  WARNING: UpgradePrompt not found after upgrade!")
	end

	-- Verificar que el StatsBillboard existe
	local statsBillboard = mainPart:FindFirstChild("StatsBillboard")
	if not statsBillboard then
		warn("[GeneratorVFXManager] ⚠️  WARNING: StatsBillboard destroyed during upgrade! This is the bug we're trying to fix.")
	else
		if DEBUG_MODE then
			print("[GeneratorVFXManager] ✅ StatsBillboard preserved after upgrade to Tier", newTier)
		end
	end

	-- Actualizar el UpgradePrompt según el nuevo tier
	if upgradePrompt then
		local UpgradeDefinitions = require(game.ServerScriptService.Services.UpgradeDefinitions)
		local tierName = "Generator"
		if newTier == 2 then
			tierName = "GeneratorT2"
		elseif newTier == 3 then
			tierName = "GeneratorT3"
		end

		local canUpgrade = UpgradeDefinitions.CanUpgrade(tierName)
		local upgradeCost = UpgradeDefinitions.GetUpgradeCost(tierName)

		if canUpgrade and upgradeCost then
			local nextTier = newTier + 1
			upgradePrompt.ActionText = string.format("Upgrade to Tier %d ($%d)", nextTier, upgradeCost)
			upgradePrompt.Enabled = true
			if DEBUG_MODE then
				print(string.format("[GeneratorVFXManager] UpgradePrompt updated: T%d → T%d ($%d)", newTier, nextTier, upgradeCost))
			end
		else
			-- Tier máximo alcanzado
			upgradePrompt.Enabled = false
			if DEBUG_MODE then
				print("[GeneratorVFXManager] UpgradePrompt disabled (max tier reached)")
			end
		end
	end

	if DEBUG_MODE then
		print(string.format("[GeneratorVFXManager] Prompts refreshed after upgrade to Tier %d", newTier))
	end
end

-------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------

if DEBUG_MODE then
	print("[GeneratorVFXManager] ✓ Module loaded with", #TIER_CONFIGS, "tiers")
end

return GeneratorVFXManager
