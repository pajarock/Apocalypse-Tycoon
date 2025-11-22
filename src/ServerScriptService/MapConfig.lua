--!strict
--[[
	-----------------------------------------------------------------------
	CONFIGURACIÓN RÁPIDA DEL MAPA
	-----------------------------------------------------------------------
	
	Modifica estos valores para personalizar tu mapa sin tocar el código principal.
	Todos los valores tienen explicaciones y valores recomendados.
	
	?? IMPORTANTE: Después de modificar, guarda y reinicia el servidor.
]]

local MapConfig = {}

-------------------------------------------------------------------------
-- ?? TERRENO Y DIMENSIONES
-------------------------------------------------------------------------

MapConfig.Terrain = {
	-- Tamaño total del mapa (en studs)
	-- Valor recomendado: 1500-2500
	-- ?? Más grande = más lag pero más espacio
	MapSize = 2000,

	-- Radio del área segura central (donde aparecen las bases)
	-- Valor recomendado: 250-350
	SafeZoneRadius = 300,

	-- Número de montañas volcánicas
	-- Valor recomendado: 15-30
	-- ?? Más montañas = más lag
	MountainCount = 25,

	-- Altura de las montañas (mínima y máxima en studs)
	MountainHeightMin = 80,
	MountainHeightMax = 200,

	-- Tamaño de las montañas (radio base)
	MountainRadiusMin = 40,
	MountainRadiusMax = 100,
}

-------------------------------------------------------------------------
-- ?? LAVA Y PELIGROS
-------------------------------------------------------------------------

MapConfig.Lava = {
	-- Nivel del océano de lava (altura Y)
	-- Valor recomendado: -10 a 0
	Level = -5,

	-- Daño que causa la lava al tocarla
	-- Valor recomendado: 30-100
	-- ?? 100 = muerte instantánea
	Damage = 50,

	-- Color de la lava (RGB)
	-- ?? Puedes cambiar el color aquí
	Color = Color3.fromRGB(255, 80, 0),  -- Naranja brillante

	-- Transparencia de la lava (0 = opaco, 1 = invisible)
	Transparency = 0.3,

	-- ¿Crear burbujas de lava que explotan?
	EnableBubbles = true,

	-- Frecuencia de burbujas (segundos entre cada una)
	BubbleFrequency = 3,
}

-------------------------------------------------------------------------
-- ??? PLATAFORMAS DE BASES
-------------------------------------------------------------------------

MapConfig.Platforms = {
	-- Altura de las plataformas sobre el suelo
	Height = 15,

	-- Radio de cada plataforma (tamaño)
	Radius = 70,

	-- Número de lados (más lados = más circular)
	-- Valor recomendado: 8-16
	Sides = 12,

	-- ¿Añadir pilares con antorchas en las esquinas?
	IncludePillars = true,

	-- ¿Añadir rampa de acceso?
	IncludeRamp = true,
}

-------------------------------------------------------------------------
-- ?? COLORES Y ESTÉTICA
-------------------------------------------------------------------------

MapConfig.Colors = {
	-- Colores de las piedras y construcciones
	Stone = Color3.fromRGB(60, 50, 45),
	DarkStone = Color3.fromRGB(30, 25, 20),
	Obsidian = Color3.fromRGB(20, 15, 15),
	Sand = Color3.fromRGB(120, 100, 80),

	-- Colores de decoraciones
	Gold = Color3.fromRGB(255, 200, 50),
	Jade = Color3.fromRGB(50, 150, 100),
	Turquoise = Color3.fromRGB(80, 200, 200),

	-- Color del cielo (afecta la atmósfera)
	SkyAmbient = Color3.fromRGB(100, 50, 30),
	SkyColor = Color3.fromRGB(255, 120, 80),
}

-------------------------------------------------------------------------
-- ??? DECORACIONES PREHISPÁNICAS
-------------------------------------------------------------------------

MapConfig.Decorations = {
	-- ¿Habilitar decoraciones prehispánicas?
	Enabled = true,

	-- Cantidad de cada tipo de decoración
	WarriorStatues = 8,      -- Estatuas de guerreros
	Serpents = 2,            -- Serpientes emplumadas
	Altars = 4,              -- Altares de sacrificio
	Steles = 12,             -- Estelas con glifos
	SolarCalendars = 1,      -- Calendarios solares

	-- ¿Añadir ruinas piramidales?
	IncludeRuins = true,
	RuinCount = 15,

	-- ¿Añadir pilares antiguos?
	IncludePillars = true,
	PillarCount = 30,
}

-------------------------------------------------------------------------
-- ? EFECTOS VISUALES
-------------------------------------------------------------------------

MapConfig.Effects = {
	-- ? Efectos habilitados (true/false)
	EnableAsh = true,              -- Ceniza flotando
	EnableFog = true,              -- Niebla tóxica
	EnableHeatWaves = true,        -- Ondas de calor
	EnableLightning = true,        -- Relámpagos rojos
	EnableCrystals = true,         -- Cristales flotantes

	-- ??? Intensidad de efectos (0-1)
	-- 0 = sin efectos, 1 = máxima intensidad
	AshIntensity = 1.0,
	FogIntensity = 0.8,
	LightningFrequency = 0.5,      -- 0.5 = cada 15-30 segundos

	-- ?? Modo Performance
	-- Si tienes lag, activa esto (true)
	PerformanceMode = false,

	-- Si PerformanceMode = true, reduce efectos:
	-- - Ceniza: 70% menos partículas
	-- - Niebla: desactivada
	-- - Cristales: desactivados
	-- - Relámpagos: 50% menos frecuentes
}

-------------------------------------------------------------------------
-- ?? SONIDOS Y MÚSICA
-------------------------------------------------------------------------

MapConfig.Audio = {
	-- ¿Habilitar sonidos?
	Enabled = true,

	-- Volumen general (0-1)
	MasterVolume = 0.5,

	-- Volúmenes específicos
	BackgroundMusicVolume = 0.2,
	WindVolume = 0.15,
	LavaVolume = 0.25,

	-- IDs de audio (puedes reemplazar con tus propios assets)
	BackgroundMusicID = "rbxassetid://1845458027",
	WindSoundID = "rbxassetid://2518311499",
	LavaBubbleID = "rbxassetid://1847058585",
	ThunderID = "rbxassetid://1842091308",
}

-------------------------------------------------------------------------
-- ?? ILUMINACIÓN
-------------------------------------------------------------------------

MapConfig.Lighting = {
	-- Hora del día (0-24)
	-- 17 = atardecer apocalíptico
	TimeOfDay = 17,

	-- Brillo general (1-3)
	Brightness = 1.5,

	-- Color del ambiente
	AmbientColor = Color3.fromRGB(100, 50, 30),
	OutdoorAmbientColor = Color3.fromRGB(120, 60, 40),

	-- Atmósfera
	AtmosphereDensity = 0.4,
	AtmosphereHaze = 2,

	-- Post-Processing
	BloomIntensity = 0.5,
	ColorSaturation = 0.1,  -- Más bajo = más desaturado
	Contrast = 0.1,
}

-------------------------------------------------------------------------
-- ?? GAMEPLAY
-------------------------------------------------------------------------

MapConfig.Gameplay = {
	-- ¿Permitir teleport entre plataformas?
	EnableTeleporters = false,

	-- ¿Añadir zonas de recursos especiales?
	EnableResourceZones = false,

	-- ¿Eventos aleatorios en ruinas?
	EnableRandomEvents = false,

	-- ¿NPCs enemigos en montañas?
	EnableEnemySpawns = false,
}

-------------------------------------------------------------------------
-- ?? MODO DEBUG
-------------------------------------------------------------------------

MapConfig.Debug = {
	-- Mostrar mensajes de debug en consola
	Enabled = true,

	-- Mostrar estadísticas en tiempo real
	ShowStats = false,

	-- Mostrar hitboxes de colisión
	ShowHitboxes = false,

	-- Permitir comandos de admin
	AllowAdminCommands = true,
}

-------------------------------------------------------------------------
-- ?? PRESETS RÁPIDOS
-------------------------------------------------------------------------

-- Función para aplicar presets predefinidos
function MapConfig.ApplyPreset(presetName: string)
	if presetName == "PERFORMANCE" then
		-- Máximo rendimiento, mínimos efectos
		MapConfig.Terrain.MountainCount = 15
		MapConfig.Effects.PerformanceMode = true
		MapConfig.Effects.EnableAsh = true
		MapConfig.Effects.EnableFog = false
		MapConfig.Effects.EnableCrystals = false
		MapConfig.Decorations.WarriorStatues = 4
		MapConfig.Decorations.Serpents = 1
		MapConfig.Decorations.PillarCount = 15

		print("[PRESET] ? Modo PERFORMANCE aplicado")

	elseif presetName == "EPIC" then
		-- Máxima calidad visual
		MapConfig.Terrain.MountainCount = 30
		MapConfig.Effects.PerformanceMode = false
		MapConfig.Effects.EnableAsh = true
		MapConfig.Effects.EnableFog = true
		MapConfig.Effects.EnableCrystals = true
		MapConfig.Effects.AshIntensity = 1.0
		MapConfig.Decorations.WarriorStatues = 12
		MapConfig.Decorations.Serpents = 3
		MapConfig.Decorations.PillarCount = 40

		print("[PRESET] ?? Modo EPIC aplicado")

	elseif presetName == "BALANCED" then
		-- Balance entre calidad y rendimiento (valores por defecto)
		print("[PRESET] ?? Modo BALANCED aplicado (por defecto)")

	else
		warn("[PRESET] ?? Preset desconocido:", presetName)
	end
end

-------------------------------------------------------------------------
-- ?? VALIDACIÓN DE CONFIGURACIÓN
-------------------------------------------------------------------------

function MapConfig.Validate()
	local warnings = {}

	-- Validar valores numéricos
	if MapConfig.Terrain.MapSize < 1000 then
		table.insert(warnings, "MapSize muy pequeño (< 1000), puede quedar apretado")
	elseif MapConfig.Terrain.MapSize > 5000 then
		table.insert(warnings, "MapSize muy grande (> 5000), puede causar lag")
	end

	if MapConfig.Lava.Damage > 100 then
		table.insert(warnings, "Daño de lava muy alto (> 100), será muerte instantánea")
	end

	if MapConfig.Terrain.MountainCount > 40 then
		table.insert(warnings, "Demasiadas montañas (> 40), considera reducir para mejor rendimiento")
	end

	-- Mostrar advertencias
	if #warnings > 0 then
		warn("?? ADVERTENCIAS DE CONFIGURACIÓN:")
		for _, warning in ipairs(warnings) do
			warn("   " .. warning)
		end
	else
		print("? Configuración validada correctamente")
	end

	return #warnings == 0
end

-------------------------------------------------------------------------
-- ?? GUARDAR/CARGAR CONFIGURACIÓN
-------------------------------------------------------------------------

-- Para futuras implementaciones con DataStore
function MapConfig.Save()
	-- TODO: Implementar guardado en DataStore
	warn("?? Función Save() no implementada aún")
end

function MapConfig.Load()
	-- TODO: Implementar carga desde DataStore
	warn("?? Función Load() no implementada aún")
end

-------------------------------------------------------------------------
-- ?? RESUMEN DE CONFIGURACIÓN
-------------------------------------------------------------------------

function MapConfig.PrintSummary()
	print("\n-----------------------------------------------------------")
	print("  RESUMEN DE CONFIGURACIÓN DEL MAPA")
	print("-----------------------------------------------------------")
	print(string.format("  Tamaño del mapa: %d studs", MapConfig.Terrain.MapSize))
	print(string.format("  Montañas: %d", MapConfig.Terrain.MountainCount))
	print(string.format("  Daño de lava: %d HP", MapConfig.Lava.Damage))
	print(string.format("  Decoraciones: %s", MapConfig.Decorations.Enabled and "Activadas" or "Desactivadas"))
	print(string.format("  Efectos: %s", MapConfig.Effects.PerformanceMode and "Modo Performance" or "Modo Normal"))
	print(string.format("  Audio: %s", MapConfig.Audio.Enabled and "Activado" or "Desactivado"))
	print("-----------------------------------------------------------\n")
end

-------------------------------------------------------------------------
-- ?? EXPORTAR
-------------------------------------------------------------------------

-- Validar configuración al cargar
MapConfig.Validate()

-- Mostrar resumen
if MapConfig.Debug.Enabled then
	MapConfig.PrintSummary()
end

return MapConfig