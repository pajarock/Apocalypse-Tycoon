--!strict
--[[
	BUILD EFFECTS MANAGER - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Maneja animaciones y efectos visuales durante la construcciÃÂ³n de upgrades.

	FEATURES:
	? Fade in + Scale from 0 ? 1
	? PartÃÂ­culas de construcciÃÂ³n (chispas, humo)
	? Sonidos de construcciÃÂ³n
	? Ghost preview (transparente)
	? Billboard temporal "CONSTRUIDO"
	? IntegraciÃÂ³n con VFXManager

	USAGE:
		local BuildEffectsManager = require(game.ServerStorage.Managers.BuildEffectsManager)

		-- Reproducir efecto completo
		BuildEffectsManager:PlayBuildEffect(model, 0.8)

		-- Preview antes de construir
		local ghost = BuildEffectsManager:CreateGhostPreview(model)

	API:
		:PlayBuildEffect(model, duration) - AnimaciÃÂ³n completa
		:CreateGhostPreview(model) - Preview transparente
		:ShowBuiltNotification(position, text) - Billboard temporal
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------

local DEBUG_MODE = false

-- ConfiguraciÃÂ³n de animaciÃÂ³n
local BUILD_ANIMATION_CONFIG = {
	FadeDuration = 0.5,
	ScaleDuration = 0.5,
	TotalDuration = 1.0,
	EasingStyle = Enum.EasingStyle.Quad,
	EasingDirection = Enum.EasingDirection.Out,
}

-- ConfiguraciÃÂ³n de partÃÂ­culas
local PARTICLE_CONFIG = {
	-- Chispas de construcciÃÂ³n
	Sparks = {
		Rate = 40,
		Lifetime = NumberRange.new(0.3, 0.6),
		Speed = NumberRange.new(10, 20),
		SpreadAngle = Vector2.new(180, 180),
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
		}),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0)
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		LightEmission = 1,
		Acceleration = Vector3.new(0, -20, 0),
	},

	-- Humo de construcciÃÂ³n
	Smoke = {
		Rate = 20,
		Lifetime = NumberRange.new(1, 1.5),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(30, 30),
		Color = ColorSequence.new(Color3.fromRGB(100, 100, 100)),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 1.5)
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Acceleration = Vector3.new(0, 5, 0),
	},

	-- Blueprint particles (azul)
	Blueprint = {
		Rate = 15,
		Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(3, 8),
		SpreadAngle = Vector2.new(60, 60),
		Color = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 0)
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		}),
		LightEmission = 0.8,
		Acceleration = Vector3.new(0, 8, 0),
	},
}

-- Sonidos (IDs gratuitos de Roblox Library)
local SOUND_IDS = {
	Construction = "rbxassetid://9120386436", -- Build sound
	Complete = "rbxassetid://9120386505",     -- Success sound
	Blueprint = "rbxassetid://9120386633",    -- Tech sound
}

-------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------

local BuildEffectsManager = {}
BuildEffectsManager.__index = BuildEffectsManager

-------------------------------------------------------------------------
-- UTILITIES
-------------------------------------------------------------------------

local function playSound(soundId: string, position: Vector3, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = 1.0

	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position
	part.Parent = workspace

	sound.Parent = part
	sound:Play()

	Debris:AddItem(part, sound.TimeLength + 0.5)
end

local function createParticleEmitter(config: any, parent: BasePart): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")

	for prop, value in pairs(config) do
		if typeof(emitter[prop]) == typeof(value) then
			emitter[prop] = value
		end
	end

	emitter.Enabled = false -- Controlled manually
	emitter.Parent = parent

	return emitter
end

local function getModelCenter(model: Model): Vector3?
	if not model.PrimaryPart then
		return model:GetBoundingBox().Position
	end
	return model.PrimaryPart.Position
end

-------------------------------------------------------------------------
-- GHOST PREVIEW
-------------------------------------------------------------------------

--[[
	Crea un preview "fantasma" del modelo antes de construir.

	@param templateModel Model - Modelo template
	@return Model - Ghost preview (transparency = 0.7)
]]
function BuildEffectsManager:CreateGhostPreview(templateModel: Model): Model?
	if not templateModel then
		warn("[BuildEffects] No template model provided for ghost preview")
		return nil
	end

	local ghost = templateModel:Clone()
	ghost.Name = "GhostPreview_" .. templateModel.Name

	-- Make all parts transparent
	for _, desc in ipairs(ghost:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Transparency = 0.7
			desc.CanCollide = false
			desc.Material = Enum.Material.ForceField
		elseif desc:IsA("Decal") or desc:IsA("Texture") then
			desc.Transparency = 0.9
		elseif desc:IsA("ParticleEmitter") or desc:IsA("Beam") then
			desc.Enabled = false
		end
	end

	if DEBUG_MODE then
		print("[BuildEffects] Created ghost preview")
	end

	return ghost
end

-------------------------------------------------------------------------
-- BUILD NOTIFICATION
-------------------------------------------------------------------------

--[[
	Muestra un billboard temporal con mensaje.

	@param position Vector3 - PosiciÃÂ³n donde mostrar
	@param text string - Texto a mostrar
	@param duration number? - DuraciÃÂ³n en segundos (default: 2)
]]
function BuildEffectsManager:ShowBuiltNotification(position: Vector3, text: string, duration: number?)
	duration = duration or 2

	local part = Instance.new("Part")
	part.Name = "NotificationPart"
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Position = position + Vector3.new(0, 5, 0)
	part.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = frame

	-- Fade out animation
	task.delay(duration - 0.5, function()
		TweenService:Create(
			frame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		):Play()

		TweenService:Create(
			label,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		):Play()
	end)

	Debris:AddItem(part, duration)
end

-------------------------------------------------------------------------
-- BUILD ANIMATION
-------------------------------------------------------------------------

--[[
	Reproduce el efecto completo de construcciÃÂ³n.

	@param model Model - El modelo que se estÃÂ¡ construyendo
	@param duration number? - DuraciÃÂ³n total (default: 1.0)
]]
function BuildEffectsManager:PlayBuildEffect(model: Model, duration: number?)
	duration = duration or BUILD_ANIMATION_CONFIG.TotalDuration

	if not model or not model.PrimaryPart then
		warn("[BuildEffects] Model has no PrimaryPart")
		return
	end

	local center = getModelCenter(model)
	if not center then
		warn("[BuildEffects] Could not get model center")
		return
	end

	-- Step 1: Store original properties
	local originalScales = {}
	local originalTransparencies = {}

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			originalScales[part] = part.Size
			originalTransparencies[part] = part.Transparency

			-- Start invisible and small
			part.Size = Vector3.new(0, 0, 0)
			part.Transparency = 1
		end
	end

	-- Step 2: Create particle emitters
	local particlePart = Instance.new("Part")
	particlePart.Name = "BuildParticles"
	particlePart.Size = Vector3.new(1, 1, 1)
	particlePart.Transparency = 1
	particlePart.CanCollide = false
	particlePart.Anchored = true
	particlePart.Position = center
	particlePart.Parent = workspace

	local sparksEmitter = createParticleEmitter(PARTICLE_CONFIG.Sparks, particlePart)
	local smokeEmitter = createParticleEmitter(PARTICLE_CONFIG.Smoke, particlePart)
	local blueprintEmitter = createParticleEmitter(PARTICLE_CONFIG.Blueprint, particlePart)

	-- Step 3: Play sounds
	playSound(SOUND_IDS.Blueprint, center, 0.3)

	task.delay(duration * 0.3, function()
		playSound(SOUND_IDS.Construction, center, 0.4)
	end)

	task.delay(duration, function()
		playSound(SOUND_IDS.Complete, center, 0.5)
	end)

	-- Step 4: Emit particles
	task.spawn(function()
		sparksEmitter:Emit(30)
		blueprintEmitter:Emit(20)

		task.wait(duration * 0.3)
		smokeEmitter:Emit(15)

		task.wait(duration * 0.7)
		Debris:AddItem(particlePart, 2)
	end)

	-- Step 5: Animate build (fade in + scale)
	task.spawn(function()
		local fadeDuration = duration * 0.6
		local scaleDuration = duration * 0.8

		-- Phase 1: Blueprint appear (20% of time)
		task.wait(duration * 0.2)

		-- Phase 2: Fade in + scale up
		for part, originalSize in pairs(originalScales) do
			if part and part.Parent then
				-- Fade in
				TweenService:Create(
					part,
					TweenInfo.new(fadeDuration, BUILD_ANIMATION_CONFIG.EasingStyle, BUILD_ANIMATION_CONFIG.EasingDirection),
					{Transparency = originalTransparencies[part]}
				):Play()

				-- Scale up
				TweenService:Create(
					part,
					TweenInfo.new(scaleDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{Size = originalSize}
				):Play()
			end
		end

		-- Phase 3: Show notification
		task.wait(duration)
		BuildEffectsManager:ShowBuiltNotification(center, "? CONSTRUIDO!", 1.5)
	end)

	if DEBUG_MODE then
		print(("[BuildEffects] Playing build effect for %s (duration: %.1fs)"):format(model.Name, duration))
	end
end

--[[
	VersiÃÂ³n simplificada solo con fade (sin scale, para performance).

	@param model Model - El modelo
	@param duration number? - DuraciÃÂ³n (default: 0.5)
]]
function BuildEffectsManager:PlaySimpleBuildEffect(model: Model, duration: number?)
	duration = duration or 0.5

	if not model then return end

	local center = getModelCenter(model)
	if not center then return end

	-- Play sound
	playSound(SOUND_IDS.Construction, center, 0.3)

	-- Fade in all parts
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local originalTransparency = part.Transparency
			part.Transparency = 1

			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Transparency = originalTransparency}
			):Play()
		end
	end

	if DEBUG_MODE then
		print("[BuildEffects] Playing simple build effect")
	end
end

--[[
	Efecto de "deconstrucciÃÂ³n" (al vender).

	@param model Model - El modelo a deconstruir
	@param duration number? - DuraciÃÂ³n (default: 0.5)
]]
function BuildEffectsManager:PlayDeconstructEffect(model: Model, duration: number?)
	duration = duration or 0.5

	if not model then return end

	local center = getModelCenter(model)
	if not center then return end

	-- Play sound (reversed construction)
	playSound(SOUND_IDS.Blueprint, center, 0.4)

	-- Particles
	local particlePart = Instance.new("Part")
	particlePart.Size = Vector3.new(1, 1, 1)
	particlePart.Transparency = 1
	particlePart.CanCollide = false
	particlePart.Anchored = true
	particlePart.Position = center
	particlePart.Parent = workspace

	local blueprintEmitter = createParticleEmitter(PARTICLE_CONFIG.Blueprint, particlePart)
	blueprintEmitter:Emit(25)
	Debris:AddItem(particlePart, 2)

	-- Fade out + shrink
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- Fade out
			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Transparency = 1}
			):Play()

			-- Shrink
			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{Size = Vector3.new(0, 0, 0)}
			):Play()
		end
	end

	-- Destroy after animation
	task.delay(duration + 0.1, function()
		if model and model.Parent then
			model:Destroy()
		end
	end)

	if DEBUG_MODE then
		print("[BuildEffects] Playing deconstruct effect")
	end
end

-------------------------------------------------------------------------
-- INITIALIZATION MESSAGE
-------------------------------------------------------------------------

print("[BuildEffectsManager] ? Module loaded")

return BuildEffectsManager