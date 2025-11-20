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
local DEBUG_MODE = false

-- FASE 2 Constants
local CONSTRUCTION_DURATION = 1 -- Segundos de animación de construcción
local CONSTRUCTION_START_OFFSET = -10 -- Studs bajo tierra al inicio
local CASH_REGISTER_SOUND_ID = "rbxassetid://16628919037" -- Sonido de cash register
local AMBIENT_SOUND_ID = "rbxassetid://9113673075" -- Sonido ambient loop
local PLACEMENT_SOUND_ID = "rbxassetid://6895079853" -- Sonido al colocar
local AMBIENT_VOLUME = 0.3 -- Volumen del sonido ambient
local CASH_REGISTER_VOLUME = 0.5 -- Volumen del cash register
local PLACEMENT_VOLUME = 0.7 -- Volumen del placement

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

	-- Remover billboards
	for _, child in mainPart:GetChildren() do
		if child:IsA("BillboardGui") then
			child:Destroy()
		end
	end

	if DEBUG_MODE then
		print("[GeneratorVFXManager] Removed all effects from generator")
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
-- FASE 2: PROXIMITY PROMPT WITH STATS
-------------------------------------------------------------------------

--[[
	Crea un ProximityPrompt con estadísticas del generador.

	@param model - Modelo del generador
	@param userId - ID del dueño
	@param tier - Tier del generador
	@return ProximityPrompt - El prompt creado
]]
function GeneratorVFXManager:CreateStatsPrompt(model: Model, userId: number, tier: number): ProximityPrompt?
	local mainPart = model:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return nil
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
	textLabel.Size = UDim2.new(1, -20, 1, -20)
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

	-- Evento para mostrar/ocultar stats
	local statsVisible = false
	prompt.Triggered:Connect(function(player)
		statsVisible = not statsVisible
		statsBillboard.Enabled = statsVisible

		if statsVisible then
			-- TODO: Actualizar stats dinámicamente desde UpgradeService
			-- Por ahora, mostrar info básica
			local tierConfig = TIER_CONFIGS[tier]
			local Players = game:GetService("Players")
			local owner = Players:GetPlayerByUserId(userId)
			local ownerName = owner and owner.Name or "Unknown"

			textLabel.Text = string.format([[
━━━━━━━━━━━━━━━━━━━━━━
💰 %s GENERATOR
━━━━━━━━━━━━━━━━━━━━━━
Rate: $5/second
Tier: %d
Status: ✅ Active
Owner: %s
━━━━━━━━━━━━━━━━━━━━━━
Press E to close
]], tierConfig.Name:upper(), tier, ownerName)
		end
	end)

	if DEBUG_MODE then
		print("[GeneratorVFXManager] Stats prompt created")
	end

	return prompt
end

-------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------

if DEBUG_MODE then
	print("[GeneratorVFXManager] ✓ Module loaded with", #TIER_CONFIGS, "tiers")
end

return GeneratorVFXManager
