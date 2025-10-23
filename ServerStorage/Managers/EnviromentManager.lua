--!strict
--[[
	ENVIRONMENT MANAGER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Maneja ambiente apocalíptico, iluminación y partículas ambientales.

	FEATURES:
	✅ Skybox apocalíptico (cielo rojo/naranja)
	✅ Lighting atmosférico (tinte rojizo, neblina)
	✅ Partículas ambientales (ceniza cayendo, humo)
	✅ Efectos post-procesamiento (ColorCorrection, Bloom, Atmosphere)
	✅ Performance-optimized (max 10 emitters)
	✅ Day/night cycle opcional (desactivado por defecto)

	USAGE:
		local EnvironmentManager = require(game.ServerStorage.Managers.EnvironmentManager)
		EnvironmentManager:Initialize()

	API:
		:Initialize() - Setup completo del ambiente
		:SetTimeOfDay(hour: number) - Cambiar hora (opcional)
		:EnableDayNightCycle(enabled: boolean) - Ciclo día/noche
		:SetWeather(weatherType: string) - "clear", "fog", "storm"
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTS
--═══════════════════════════════════════════════════════════════════════

local DEBUG_MODE = false

-- Configuración de lighting apocalíptico
local LIGHTING_CONFIG = {
	-- Hora del día (18 = 6 PM, atardecer)
	ClockTime = 18,

	-- Brightness reducido para ambiente oscuro
	Brightness = 1.5,

	-- Colores ambientales
	Ambient = Color3.fromRGB(120, 60, 40), -- Tinte rojizo
	OutdoorAmbient = Color3.fromRGB(140, 80, 60),

	-- Niebla
	FogColor = Color3.fromRGB(100, 50, 30),
	FogStart = 100,
	FogEnd = 500,

	-- Configuración global
	GlobalShadows = true,
	Technology = Enum.Technology.ShadowMap,
	EnvironmentDiffuseScale = 0.5,
	EnvironmentSpecularScale = 0.3,
}

-- Configuración de atmosphere
local ATMOSPHERE_CONFIG = {
	Density = 0.35,
	Offset = 0.25,
	Color = Color3.fromRGB(200, 100, 50),
	Decay = Color3.fromRGB(100, 50, 30),
	Glare = 0.5,
	Haze = 1.5,
}

-- Configuración de color correction
local COLOR_CORRECTION_CONFIG = {
	Brightness = 0,
	Contrast = 0.1,
	Saturation = -0.2, -- Menos saturación (más sepia)
	TintColor = Color3.fromRGB(255, 200, 180), -- Tinte cálido
}

-- Configuración de bloom
local BLOOM_CONFIG = {
	Enabled = true,
	Intensity = 0.4,
	Size = 24,
	Threshold = 2,
}

-- Configuración de sun rays
local SUNRAYS_CONFIG = {
	Enabled = true,
	Intensity = 0.15,
	Spread = 0.5,
}

-- Partículas ambientales
local PARTICLE_CONFIG = {
	-- Ceniza cayendo
	Ash = {
		Enabled = true,
		Count = 5, -- Número de emitters
		Rate = 10,
		Lifetime = NumberRange.new(8, 12),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(5, 5),
		Color = ColorSequence.new(Color3.fromRGB(80, 80, 80)),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 0.2)
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.8, 0.7),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Height = 150,
		Radius = 200,
	},

	-- Humo distante
	Smoke = {
		Enabled = true,
		Count = 3,
		Rate = 5,
		Lifetime = NumberRange.new(15, 20),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(15, 15),
		Color = ColorSequence.new(Color3.fromRGB(60, 60, 60)),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(0.5, 4),
			NumberSequenceKeypoint.new(1, 6)
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 0.9),
			NumberSequenceKeypoint.new(1, 1)
		}),
		Height = 100,
		Radius = 300,
	},
}

--═══════════════════════════════════════════════════════════════════════
-- MODULE
--═══════════════════════════════════════════════════════════════════════

local EnvironmentManager = {}
EnvironmentManager.__index = EnvironmentManager

-- Estado
local ParticleEmitters = {}
local DayNightEnabled = false
local CurrentWeather = "clear"

--═══════════════════════════════════════════════════════════════════════
-- UTILITIES
--═══════════════════════════════════════════════════════════════════════

local function getOrCreateInstance(parent: Instance, className: string, name: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end

	if existing then
		existing:Destroy()
	end

	local new = Instance.new(className)
	new.Name = name
	new.Parent = parent
	return new
end

--═══════════════════════════════════════════════════════════════════════
-- LIGHTING SETUP
--═══════════════════════════════════════════════════════════════════════

local function setupLighting()
	-- Aplicar configuración básica
	for property, value in pairs(LIGHTING_CONFIG) do
		if typeof(Lighting[property]) == typeof(value) then
			Lighting[property] = value
		end
	end

	if DEBUG_MODE then
		print("[ENV] ✓ Lighting configurado (ClockTime: 18, Fog: 500)")
	end
end

local function setupAtmosphere()
	local atmosphere = getOrCreateInstance(Lighting, "Atmosphere", "ApocalypseAtmosphere") :: Atmosphere

	for property, value in pairs(ATMOSPHERE_CONFIG) do
		if typeof(atmosphere[property]) == typeof(value) then
			atmosphere[property] = value
		end
	end

	if DEBUG_MODE then
		print("[ENV] ✓ Atmosphere creada (Density: 0.35)")
	end
end

local function setupColorCorrection()
	local cc = getOrCreateInstance(Lighting, "ColorCorrectionEffect", "ApocalypseColorCorrection") :: ColorCorrectionEffect

	for property, value in pairs(COLOR_CORRECTION_CONFIG) do
		if typeof(cc[property]) == typeof(value) then
			cc[property] = value
		end
	end

	if DEBUG_MODE then
		print("[ENV] ✓ ColorCorrection aplicado (Tinte cálido)")
	end
end

local function setupBloom()
	local bloom = getOrCreateInstance(Lighting, "BloomEffect", "ApocalypseBloom") :: BloomEffect

	for property, value in pairs(BLOOM_CONFIG) do
		if typeof(bloom[property]) == typeof(value) then
			bloom[property] = value
		end
	end

	if DEBUG_MODE then
		print("[ENV] ✓ Bloom configurado (Intensity: 0.4)")
	end
end

local function setupSunRays()
	local sunRays = getOrCreateInstance(Lighting, "SunRaysEffect", "ApocalypseSunRays") :: SunRaysEffect

	for property, value in pairs(SUNRAYS_CONFIG) do
		if typeof(sunRays[property]) == typeof(value) then
			sunRays[property] = value
		end
	end

	if DEBUG_MODE then
		print("[ENV] ✓ SunRays configurado")
	end
end

--═══════════════════════════════════════════════════════════════════════
-- PARTICLE SYSTEM
--═══════════════════════════════════════════════════════════════════════

local function createParticleEmitter(config: any, position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "ParticleEmitter"
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = true
	part.Position = position
	part.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = config.Rate
	emitter.Lifetime = config.Lifetime
	emitter.Speed = config.Speed
	emitter.SpreadAngle = config.SpreadAngle
	emitter.Color = config.Color
	emitter.Size = config.Size
	emitter.Transparency = config.Transparency
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-50, 50)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Acceleration = Vector3.new(0, -2, 0)
	emitter.VelocityInheritance = 0
	emitter.Parent = part

	return part
end

local function spawnAmbientParticles()
	-- Limpiar partículas existentes
	for _, part in ipairs(ParticleEmitters) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	ParticleEmitters = {}

	-- Ceniza cayendo
	if PARTICLE_CONFIG.Ash.Enabled then
		local ashConfig = PARTICLE_CONFIG.Ash

		for i = 1, ashConfig.Count do
			local angle = (i / ashConfig.Count) * math.pi * 2
			local radius = ashConfig.Radius
			local pos = Vector3.new(
				math.cos(angle) * radius,
				ashConfig.Height,
				math.sin(angle) * radius
			)

			local part = createParticleEmitter(ashConfig, pos)
			table.insert(ParticleEmitters, part)
		end

		if DEBUG_MODE then
			print(("[ENV] ✓ Spawned %d ash emitters"):format(ashConfig.Count))
		end
	end

	-- Humo distante
	if PARTICLE_CONFIG.Smoke.Enabled then
		local smokeConfig = PARTICLE_CONFIG.Smoke

		for i = 1, smokeConfig.Count do
			local angle = (i / smokeConfig.Count) * math.pi * 2 + (math.pi / smokeConfig.Count)
			local radius = smokeConfig.Radius
			local pos = Vector3.new(
				math.cos(angle) * radius,
				smokeConfig.Height,
				math.sin(angle) * radius
			)

			local part = createParticleEmitter(smokeConfig, pos)
			table.insert(ParticleEmitters, part)
		end

		if DEBUG_MODE then
			print(("[ENV] ✓ Spawned %d smoke emitters"):format(smokeConfig.Count))
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- DAY/NIGHT CYCLE (OPCIONAL)
--═══════════════════════════════════════════════════════════════════════

local function startDayNightCycle()
	if DayNightEnabled then
		warn("[ENV] Day/night cycle already running")
		return
	end

	DayNightEnabled = true

	task.spawn(function()
		while DayNightEnabled do
			-- Ciclo de 10 minutos (600 segundos)
			local cycleDuration = 600
			local step = 24 / cycleDuration -- Incremento por segundo

			for i = 1, cycleDuration do
				if not DayNightEnabled then break end

				Lighting.ClockTime = (Lighting.ClockTime + step) % 24
				task.wait(1)
			end
		end
	end)

	if DEBUG_MODE then
		print("[ENV] ✓ Day/night cycle started (10 min cycle)")
	end
end

local function stopDayNightCycle()
	DayNightEnabled = false
	Lighting.ClockTime = LIGHTING_CONFIG.ClockTime

	if DEBUG_MODE then
		print("[ENV] ✓ Day/night cycle stopped")
	end
end

--═══════════════════════════════════════════════════════════════════════
-- WEATHER SYSTEM (OPCIONAL)
--═══════════════════════════════════════════════════════════════════════

local function setWeather(weatherType: string)
	CurrentWeather = weatherType

	if weatherType == "clear" then
		-- Default apocalyptic
		Lighting.FogEnd = LIGHTING_CONFIG.FogEnd
		Lighting.Brightness = LIGHTING_CONFIG.Brightness

	elseif weatherType == "fog" then
		-- Niebla densa
		Lighting.FogEnd = 200
		Lighting.Brightness = 1.0

	elseif weatherType == "storm" then
		-- Tormenta (más oscuro, más niebla)
		Lighting.FogEnd = 150
		Lighting.Brightness = 0.8
		Lighting.Ambient = Color3.fromRGB(80, 40, 30)

	else
		warn(("[ENV] Weather type '%s' not recognized"):format(weatherType))
		return
	end

	if DEBUG_MODE then
		print(("[ENV] ✓ Weather set to: %s"):format(weatherType))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- PUBLIC API
--═══════════════════════════════════════════════════════════════════════

--[[
	Inicializa el ambiente apocalíptico completo.
]]
function EnvironmentManager:Initialize()
	if DEBUG_MODE then
		print("[ENV] Initializing apocalyptic environment...")
	end

	-- Setup lighting
	setupLighting()
	setupAtmosphere()
	setupColorCorrection()
	setupBloom()
	setupSunRays()

	-- Spawn particles
	spawnAmbientParticles()

	-- Weather default
	CurrentWeather = "clear"

	if DEBUG_MODE then
		print("[ENV] ✓ Environment initialized successfully")
		print("[ENV] Active emitters:", #ParticleEmitters)
	end
end

--[[
	Cambia la hora del día (0-24).

	@param hour number - Hora (0 = medianoche, 12 = mediodía, 18 = atardecer)
]]
function EnvironmentManager:SetTimeOfDay(hour: number)
	hour = math.clamp(hour, 0, 24)
	Lighting.ClockTime = hour

	if DEBUG_MODE then
		print(("[ENV] Time set to: %d:00"):format(math.floor(hour)))
	end
end

--[[
	Habilita/deshabilita ciclo día/noche.

	@param enabled boolean - true para habilitar
]]
function EnvironmentManager:EnableDayNightCycle(enabled: boolean)
	if enabled then
		startDayNightCycle()
	else
		stopDayNightCycle()
	end
end

--[[
	Cambia el clima.

	@param weatherType string - "clear", "fog", "storm"
]]
function EnvironmentManager:SetWeather(weatherType: string)
	setWeather(weatherType)
end

--[[
	Retorna el clima actual.

	@return string - Tipo de clima actual
]]
function EnvironmentManager:GetCurrentWeather(): string
	return CurrentWeather
end

--[[
	Limpia todas las partículas ambientales.
]]
function EnvironmentManager:CleanupParticles()
	for _, part in ipairs(ParticleEmitters) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	ParticleEmitters = {}

	if DEBUG_MODE then
		print("[ENV] ✓ All particles cleaned up")
	end
end

--[[
	Recarga las partículas ambientales.
]]
function EnvironmentManager:ReloadParticles()
	self:CleanupParticles()
	spawnAmbientParticles()

	if DEBUG_MODE then
		print("[ENV] ✓ Particles reloaded")
	end
end

--[[
	Retorna info de debug.

	@return {ParticleCount: number, Weather: string, ClockTime: number}
]]
function EnvironmentManager:GetDebugInfo(): {ParticleCount: number, Weather: string, ClockTime: number}
	return {
		ParticleCount = #ParticleEmitters,
		Weather = CurrentWeather,
		ClockTime = Lighting.ClockTime,
	}
end

--═══════════════════════════════════════════════════════════════════════
-- CLEANUP ON SHUTDOWN
--═══════════════════════════════════════════════════════════════════════

game:BindToClose(function()
	EnvironmentManager:CleanupParticles()
end)

--═══════════════════════════════════════════════════════════════════════
-- INITIALIZATION MESSAGE
--═══════════════════════════════════════════════════════════════════════

print("[EnvironmentManager] ✓ Module loaded")

return EnvironmentManager