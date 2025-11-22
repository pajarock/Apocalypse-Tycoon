--!strict
--[[
	ENVIRONMENT MANAGER - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Maneja ambiente apocalÃ­ptico, iluminaciÃ³n y partÃ­culas ambientales.

	FEATURES:
	? Skybox apocalÃ­ptico (cielo rojo/naranja)
	? Lighting atmosfÃ©rico (tinte rojizo, neblina)
	? PartÃ­culas ambientales (ceniza cayendo, humo)
	? Efectos post-procesamiento (ColorCorrection, Bloom, Atmosphere)
	? Performance-optimized (max 10 emitters)
	? Day/night cycle opcional (desactivado por defecto)

	USAGE:
		local EnvironmentManager = require(game.ServerStorage.Managers.EnvironmentManager)
		EnvironmentManager:Initialize()

	API:
		:Initialize() - Setup completo del ambiente
		:SetTimeOfDay(hour: number) - Cambiar hora (opcional)
		:EnableDayNightCycle(enabled: boolean) - Ciclo dÃ­a/noche
		:SetWeather(weatherType: string) - "clear", "fog", "storm"
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------

local DEBUG_MODE = false

-- ConfiguraciÃ³n de lighting apocalÃ­ptico
local LIGHTING_CONFIG = {
	-- Hora del dÃ­a (17 = atardecer cÃ¡lido)
	ClockTime = 17.5,

	-- Brillo general (2 = mÃ¡s claro sin perder sombras)
	Brightness = 2.0,

	-- Colores ambientales base (tono rojizo oscuro)
	Ambient = Color3.fromRGB(90, 50, 40), -- sombras
	OutdoorAmbient = Color3.fromRGB(120, 70, 55), -- luz exterior

	-- Niebla (tono naranja tenue, distancia media)
	FogColor = Color3.fromRGB(180, 90, 60),
	FogStart = 150,
	FogEnd = 800,

	-- Escala ambiental de reflejos y sombras
	EnvironmentDiffuseScale = 0.55,
	EnvironmentSpecularScale = 0.55,

	-- Activar sombras globales
	GlobalShadows = true,
}

-- ConfiguraciÃ³n de atmosphere (niebla volumÃ©trica)
local ATMOSPHERE_CONFIG = {
	-- Densidad de la niebla (0.25 = visible pero no bloquea todo)
	Density = 0.25,

	-- Altura donde empieza el efecto
	Offset = 0.15,

	-- Color base del aire (naranja volcÃ¡nico)
	Color = Color3.fromRGB(255, 150, 100),

	-- Degradado de color hacia el fondo (mÃ¡s claro)
	Decay = Color3.fromRGB(255, 210, 180),

	-- Brillo difuso de partÃ­culas
	Glare = 0.35,

	-- Cantidad de dispersiÃ³n (0.4 = bruma ligera)
	Haze = 0.4,
}

-- ConfiguraciÃ³n de correcciÃ³n de color
local COLOR_CORRECTION_CONFIG = {
	-- Brillo adicional global
	Brightness = 0.05,

	-- Contraste general (resalta luces/sombras)
	Contrast = 0.12,

	-- SaturaciÃ³n (-0.05 = tono ligeramente apagado)
	Saturation = -0.05,

	-- Tinte cÃ¡lido (naranja suave)
	TintColor = Color3.fromRGB(255, 220, 200),
}

-- ConfiguraciÃ³n de bloom (brillo en bordes de luz)
local BLOOM_CONFIG = {
	-- Activado
	Enabled = true,

	-- Intensidad del resplandor
	Intensity = 0.25,

	-- TamaÃ±o del halo de luz
	Size = 20,

	-- Umbral (quÃ© tan brillante debe ser algo para emitir halo)
	Threshold = 1.1,
}

-- ConfiguraciÃ³n de rayos solares
local SUNRAYS_CONFIG = {
	-- Activado
	Enabled = true,

	-- Intensidad de los rayos
	Intensity = 0.08,

	-- DispersiÃ³n de los rayos (0.65 = rayos amplios)
	Spread = 0.65,
}


-- PartÃ­culas ambientales
local PARTICLE_CONFIG = {
	-- Ceniza cayendo
	Ash = {
		Enabled = true,
		Count = 5, -- NÃºmero de emitters
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

-------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------

local EnvironmentManager = {}
EnvironmentManager.__index = EnvironmentManager

-- Estado
local ParticleEmitters = {}
local DayNightEnabled = false
local CurrentWeather = "clear"

-------------------------------------------------------------------------
-- UTILITIES
-------------------------------------------------------------------------

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

-------------------------------------------------------------------------
-- LIGHTING SETUP
-------------------------------------------------------------------------

local function setupLighting()
	-- Aplicar configuraciÃ³n bÃ¡sica
	for property, value in pairs(LIGHTING_CONFIG) do
		if typeof(Lighting[property]) == typeof(value) then
			Lighting[property] = value
		end
	end

	if DEBUG_MODE then
		print("[ENV] ? Lighting configurado (ClockTime: 18, Fog: 500)")
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
		print("[ENV] ? Atmosphere creada (Density: 0.35)")
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
		print("[ENV] ? ColorCorrection aplicado (Tinte cÃ¡lido)")
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
		print("[ENV] ? Bloom configurado (Intensity: 0.4)")
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
		print("[ENV] ? SunRays configurado")
	end
end

-------------------------------------------------------------------------
-- PARTICLE SYSTEM
-------------------------------------------------------------------------

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
	-- Limpiar partÃ­culas existentes
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
			print(("[ENV] ? Spawned %d ash emitters"):format(ashConfig.Count))
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
			print(("[ENV] ? Spawned %d smoke emitters"):format(smokeConfig.Count))
		end
	end
end

-------------------------------------------------------------------------
-- DAY/NIGHT CYCLE (OPCIONAL)
-------------------------------------------------------------------------

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
		print("[ENV] ? Day/night cycle started (10 min cycle)")
	end
end

local function stopDayNightCycle()
	DayNightEnabled = false
	Lighting.ClockTime = LIGHTING_CONFIG.ClockTime

	if DEBUG_MODE then
		print("[ENV] ? Day/night cycle stopped")
	end
end

-------------------------------------------------------------------------
-- WEATHER SYSTEM (OPCIONAL)
-------------------------------------------------------------------------

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
		-- Tormenta (mÃ¡s oscuro, mÃ¡s niebla)
		Lighting.FogEnd = 150
		Lighting.Brightness = 0.8
		Lighting.Ambient = Color3.fromRGB(80, 40, 30)

	else
		warn(("[ENV] Weather type '%s' not recognized"):format(weatherType))
		return
	end

	if DEBUG_MODE then
		print(("[ENV] ? Weather set to: %s"):format(weatherType))
	end
end

-------------------------------------------------------------------------
-- PUBLIC API
-------------------------------------------------------------------------

--[[
	Inicializa el ambiente apocalÃ­ptico completo.
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
		print("[ENV] ? Environment initialized successfully")
		print("[ENV] Active emitters:", #ParticleEmitters)
	end
end

--[[
	Cambia la hora del dÃ­a (0-24).

	@param hour number - Hora (0 = medianoche, 12 = mediodÃ­a, 18 = atardecer)
]]
function EnvironmentManager:SetTimeOfDay(hour: number)
	hour = math.clamp(hour, 0, 24)
	Lighting.ClockTime = hour

	if DEBUG_MODE then
		print(("[ENV] Time set to: %d:00"):format(math.floor(hour)))
	end
end

--[[
	Habilita/deshabilita ciclo dÃ­a/noche.

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
	Limpia todas las partÃ­culas ambientales.
]]
function EnvironmentManager:CleanupParticles()
	for _, part in ipairs(ParticleEmitters) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	ParticleEmitters = {}

	if DEBUG_MODE then
		print("[ENV] ? All particles cleaned up")
	end
end

--[[
	Recarga las partÃ­culas ambientales.
]]
function EnvironmentManager:ReloadParticles()
	self:CleanupParticles()
	spawnAmbientParticles()

	if DEBUG_MODE then
		print("[ENV] ? Particles reloaded")
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

-------------------------------------------------------------------------
-- CLEANUP ON SHUTDOWN
-------------------------------------------------------------------------

game:BindToClose(function()
	EnvironmentManager:CleanupParticles()
end)

-------------------------------------------------------------------------
-- INITIALIZATION MESSAGE
-------------------------------------------------------------------------

print("[EnvironmentManager] ? Module loaded")

return EnvironmentManager