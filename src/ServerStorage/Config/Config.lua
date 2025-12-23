--!strict
--[[
	CONFIG.LUA - Apocalypse Tycoon
	? BALANCE V2.0 - HIGH DIFFICULTY BUT FAIR
	
	DISE�O DE DIFICULTAD:
	- Primeros 5 minutos: Tutorial natural (waves suaves)
	- Minutos 5-15: Rampa de dificultad (decisiones importantes)
	- Minutos 15+: Endgame (multitasking, gesti�n de recursos)
	
	FILOSOF�A:
	? Cada compra debe sentirse significativa
	? Los meteoritos son amenaza real pero predecible
	? Muerte = setback, no game over
	? Skill > grinding
--]]

local Config = {}

-------------------------------------------------------------------------
-- ?? ECONOM�A - Tight pero justa
-------------------------------------------------------------------------
Config.START_CASH = 750  -- Suficiente para: 1 income upgrade + 1 defensa b�sica
Config.CASH_PER_SEC_BASE = 8  -- 8/sec = 480/min base (sin upgrades)
Config.TICK_SECS = 1

-- L�mites
Config.MAX_CASH = 999999999
Config.MIN_CASH = 0

-- Progresi�n (curva exponencial moderada)
Config.PRICE_MULTIPLIER = 1.14  -- 14% m�s caro cada nivel
Config.INCOME_DIMINISHING_RETURNS = 0.90  -- Cada upgrade da 10% menos (fuerza diversificaci�n)

-- Offline (penalizar heavy AFK)
Config.OFFLINE_MAX_MINUTES = 15  -- Solo 15 minutos
Config.OFFLINE_RATE_MULTIPLIER = 0.2  -- 20% del income (no recompensa AFK)

-------------------------------------------------------------------------
-- ??? BASES Y CONSTRUCCI�N
-------------------------------------------------------------------------
Config.BASE_SIZE = Vector3.new(120, 1, 120)
Config.SPAWN_RING_RADIUS = 250
Config.BASE_SPAWN_HEIGHT = 5

Config.MAX_MODELS_PER_BASE = 100
Config.BUILD_GRID_COLUMNS = 4
Config.BUILD_CELL_SIZE = 8

Config.BASE_COLORS = {
	Default = Color3.fromRGB(60, 60, 60),
	Damaged = Color3.fromRGB(120, 40, 40),
	Shielded = Color3.fromRGB(80, 120, 180),
}

-------------------------------------------------------------------------
-- ??? SISTEMA DE DA�O Y DEFENSA - Balanceado para skill
-------------------------------------------------------------------------
Config.BASE_MAX_HP = 150  -- HP aumentado (antes 100) para m�s margen de error
Config.BASE_REGEN_RATE = 0.3  -- Regen lenta pero presente (45 HP/min)
Config.REPAIR_COST_PER_HP = 8  -- 8$/HP = 1200$ para full repair (significativo)
Config.BASE_REGEN_DELAY = 0.2
-- Escudos (crucial para late game)
Config.SHIELD_REDUCTION_PER_LEVEL = 0.18  -- 18% por nivel
Config.SHIELD_MAX_REDUCTION = 0.54  -- M�ximo 54% (3 niveles)
Config.SHIELD_MAX_LEVEL = 3

-- Invencibilidad post-respawn
Config.RESPAWN_INVULNERABILITY_SECS = 8  -- 8 segundos para reorganizarse

-------------------------------------------------------------------------
-- ?? METEORITOS - Amenaza escalable
-------------------------------------------------------------------------
Config.METEOR_DAMAGE = 28  -- ~5 hits = muerte sin defensas
Config.METEOR_DAMAGE_RADIUS = 22  -- Radio ligeramente mayor
Config.METEOR_MIN_Y = 130  -- M�s altura = m�s tiempo de reacci�n
Config.METEOR_VELOCITY = 135  -- Velocidad moderada (antes 140)
Config.METEOR_LIFETIME = 15

-- Variantes de meteoritos (aumentan con waves)
Config.METEOR_TYPES = {
	Small = {
		Damage = 15,
		Size = Vector3.new(4, 4, 4),
		Color = Color3.fromRGB(200, 100, 0),
		Speed = 170,
	},
	Normal = {
		Damage = 28,
		Size = Vector3.new(8, 8, 8),
		Color = Color3.fromRGB(255, 130, 0),
		Speed = 135,
	},
	Large = {
		Damage = 50,
		Size = Vector3.new(12, 12, 12),
		Color = Color3.fromRGB(255, 50, 0),
		Speed = 100,  -- M�s lentos pero mortales
	},
}

Config.METEOR_DEBUG_COOLDOWN = 5

-------------------------------------------------------------------------
-- ?? SISTEMA DE WAVES - Progresi�n dram�tica pero fair
-------------------------------------------------------------------------
Config.CURRENT_WAVE = 1
Config.METEORS_PER_WAVE_BASE = 5  -- Empezar m�s suave

-- CURVA DE DIFICULTAD DISE�ADA:
-- Wave 1-3: Tutorial (5-9 meteors, 75s interval) - Aprender mec�nicas
-- Wave 4-7: Ramp up (11-17 meteors, 60s interval) - Construir defensas
-- Wave 8-12: Mid game (19-27 meteors, 50s interval) - Optimizar estrategia
-- Wave 13+: Endgame (29+ meteors, 45s interval) - Survival mode

function Config.GetWaveDifficulty(waveNum: number)
	local meteorsCount, damage, interval

	-- Early Game (Waves 1-3): Aprendizaje
	if waveNum <= 3 then
		meteorsCount = 5 + (waveNum * 2)  -- 7, 9, 11
		damage = 20 + (waveNum * 3)  -- 23, 26, 29
		interval = 75  -- Tiempo generoso entre waves

		-- Ramp Up (Waves 4-7): Presi�n moderada
	elseif waveNum <= 7 then
		meteorsCount = 11 + ((waveNum - 3) * 2)  -- 13, 15, 17, 19
		damage = 28 + (waveNum * 2)  -- 36, 38, 40, 42
		interval = 65 - (waveNum - 3)  -- 62s ? 59s

		-- Mid Game (Waves 8-12): Intensidad alta
	elseif waveNum <= 12 then
		meteorsCount = 19 + ((waveNum - 7) * 2)  -- 21, 23, 25, 27, 29
		damage = 42 + (waveNum * 2)  -- 58, 60, 62, 64, 66
		interval = math.max(50, 60 - (waveNum - 7))  -- 55s ? 50s

		-- End Game (Wave 13+): Chaos controlado
	else
		meteorsCount = 29 + ((waveNum - 12) * 1)  -- +1 por wave
		damage = 66 + ((waveNum - 12) * 3)  -- Da�o sigue escalando
		interval = 45  -- Intervalo m�nimo constante
	end

	return {
		Meteors = meteorsCount,
		Damage = damage,
		Interval = interval
	}
end

-------------------------------------------------------------------------
-- ?? EVENTOS Y RAIDS
-------------------------------------------------------------------------
Config.EVENT_INTERVAL = 180  -- Evento especial cada 3 minutos
Config.METEOR_COUNT = 25
Config.RAIDER_HIT_DAMAGE = 8

Config.EVENTS = {
	MeteorStorm = {
		Duration = 25,
		SpawnRate = 1.5,  -- 1.5 meteoros/segundo
		WarnTime = 8,
	},
	Raiders = {
		Count = 4,
		HP = 120,
		Speed = 18,
		AttackCooldown = 2.5,
	},
	BloodMoon = {
		Enabled = false,
		Multiplier = 2,
	},
}

-------------------------------------------------------------------------
-- ?? SISTEMA DE REPARACIONES - Costoso pero necesario
-------------------------------------------------------------------------
Config.REPAIR_BASE_COST = 75
Config.REPAIR_MULTIPLIER = 1.28  -- Cada reparaci�n +28% m�s cara (era 35%)
Config.REPAIR_DECAY_SECS = 90  -- Decay del costo m�s lento
Config.REPAIR_DAMAGE_FACTOR = 1.3

-------------------------------------------------------------------------
-- ?? DATASTORE Y GUARDADO
-------------------------------------------------------------------------
Config.DATASTORE_NAME = "ApocalypseTycoon_v2_BALANCED"
Config.AUTOSAVE_SECS = 45  -- Guardar m�s frecuente
Config.SAVE_ON_PURCHASE = false
Config.MAX_SAVE_RETRIES = 3
Config.DATA_VERSION = 2  -- Nueva versi�n por balance changes

-------------------------------------------------------------------------
-- ?? SEGURIDAD Y RATE LIMITING
-------------------------------------------------------------------------
Config.MAX_PURCHASE_PER_SEC = 4  -- Prevenir spam (era 6)
Config.MAX_REPAIR_PER_REQUEST = 150  -- Limitar repairs masivas
Config.MAX_REMOTE_CALLS_PER_MIN = 100

Config.VALIDATE_PRICES = true
Config.LOG_SUSPICIOUS_ACTIVITY = true

-------------------------------------------------------------------------
-- ?? UI Y EXPERIENCIA DE USUARIO
-------------------------------------------------------------------------
Config.UI = {
	ShowDamageNumbers = true,
	ShowIncomePopups = true,
	ShakeOnDamage = true,
	LowHealthWarning = 35,  -- Advertir antes (35% HP)
	NotificationDuration = 4,
}

Config.UI_COLORS = {
	Income = Color3.fromRGB(100, 255, 100),
	Damage = Color3.fromRGB(255, 80, 80),
	Repair = Color3.fromRGB(100, 200, 255),
	Warning = Color3.fromRGB(255, 200, 0),
}

-------------------------------------------------------------------------
-- ?? SONIDOS
-------------------------------------------------------------------------
Config.SOUNDS = {
	Purchase = "rbxassetid://4612383453",
	MeteorImpact = "rbxassetid://9118617342",
	BaseDamaged = "rbxassetid://0",
	IncomeEarned = "rbxassetid://0",
	LevelUp = "rbxassetid://0",
	Warning = "rbxassetid://0",
}

Config.SOUND_VOLUME = 0.6
Config.MUSIC_ENABLED = false

-------------------------------------------------------------------------
-- ?? VIP Y GAMEPASSES
-------------------------------------------------------------------------
Config.GAMEPASSES = {
	DoubleIncome = {
		ID = 0,
		Multiplier = 1.75,  -- x1.75 en vez de x2 (no romper balance)
		Enabled = false,
	},
	InstantRepair = {
		ID = 0,
		Cost = 100,
		Enabled = false,
	},
	PremiumSlots = {
		ID = 0,
		ExtraSlots = 50,
		Enabled = false,
	},
}

-------------------------------------------------------------------------
-- ?? ANALYTICS Y DEBUG
-------------------------------------------------------------------------
Config.ANALYTICS = {
	Enabled = true,
	TrackPurchases = true,
	TrackDeaths = true,
	TrackSessionTime = true,
	TrackIncome = true,
}

Config.DEBUG_MODE = true
Config.SHOW_DEBUG_UI = false

-------------------------------------------------------------------------
-- 🏗️ KNIT MIGRATION FLAGS
-------------------------------------------------------------------------
-- Flag para usar el nuevo sistema de bases Knit en lugar del legacy
-- IMPORTANTE: Cambiar a true cuando el sistema Knit esté listo para producción
Config.USE_KNIT_BASES = false  -- false = usa sistema legacy | true = usa sistema Knit

-------------------------------------------------------------------------
-- ?? BALANCE Y PROGRESI�N
-------------------------------------------------------------------------
Config.PROGRESSION = {
	-- Early: Boost inicial para evitar frustraci�n
	EarlyGame = {
		MaxMinutes = 8,
		IncomeBoost = 1.4,  -- +40% income (aprender sin estr�s)
	},
	-- Mid: Income normal, dificultad aumenta
	MidGame = {
		MaxMinutes = 25,
		IncomeBoost = 1.0,
	},
	-- Late: Reducir grind, mantener desaf�o
	LateGame = {
		MaxMinutes = 999,
		IncomeBoost = 0.85,  -- -15% para evitar snowball excesivo
	},
}

Config.PRESTIGE = {
	Enabled = false,
	RequiredCash = 500000,
	BonusPerPrestige = 0.12,  -- +12% income por prestige
	MaxPrestige = 15,
}

-------------------------------------------------------------------------
-- ??? UTILIDADES DE VALIDACI�N
-------------------------------------------------------------------------
function Config.Validate(): (boolean, string?)
	if Config.BASE_MAX_HP <= 0 then
		return false, "BASE_MAX_HP debe ser mayor a 0"
	end

	if Config.TICK_SECS <= 0 then
		return false, "TICK_SECS debe ser mayor a 0"
	end

	if Config.SHIELD_MAX_REDUCTION < 0 or Config.SHIELD_MAX_REDUCTION > 1 then
		return false, "SHIELD_MAX_REDUCTION debe estar entre 0 y 1"
	end

	if Config.MAX_CASH <= Config.START_CASH then
		return false, "MAX_CASH debe ser mayor que START_CASH"
	end

	local meteorNames = {}
	for name, _ in pairs(Config.METEOR_TYPES) do
		if meteorNames[name] then
			return false, ("Tipo de meteorito duplicado: %s"):format(name)
		end
		meteorNames[name] = true
	end

	return true, nil
end

function Config.Get(key: string, default: any): any
	local value = Config[key]
	if value ~= nil then
		return value
	end

	warn(("[CONFIG] Clave no encontrada: %s, usando default: %s"):format(key, tostring(default)))
	return default
end

-- Dificultad din�mica seg�n jugadores (m�s jugadores = m�s f�cil individualmente)
function Config.GetDynamicDifficulty(playerCount: number): number
	if playerCount <= 1 then
		return 1.0  -- Solo, dificultad completa
	elseif playerCount <= 4 then
		return 0.85  -- 2-4 jugadores, -15% dificultad
	elseif playerCount <= 8 then
		return 0.7  -- 5-8 jugadores, -30% dificultad
	else
		return 0.6  -- 9+ jugadores, -40% dificultad
	end
end

-------------------------------------------------------------------------
-- ?? HELPER: Calculadora de econom�a
-------------------------------------------------------------------------
-- Funci�n �til para balancear precios de upgrades
function Config.CalculateUpgradePrice(basePrice: number, level: number): number
	return math.floor(basePrice * (Config.PRICE_MULTIPLIER ^ level))
end

-- Calcular income despu�s de X upgrades
function Config.CalculateIncome(upgradeCount: number): number
	local income = Config.CASH_PER_SEC_BASE
	for i = 1, upgradeCount do
		income = income + (Config.CASH_PER_SEC_BASE * (Config.INCOME_DIMINISHING_RETURNS ^ i))
	end
	return math.floor(income)
end

-- Preview de progresi�n (para testing)
function Config.PrintProgressionCurve()
	if not Config.DEBUG_MODE then return end

	print("\n+-----------------------------------------------------------+")
	print("�  APOCALYPSE TYCOON - PROGRESSION PREVIEW                �")
	print("+-----------------------------------------------------------+\n")

	for wave = 1, 15 do
		local diff = Config.GetWaveDifficulty(wave)
		print(string.format("Wave %2d: %2d meteors | %3d dmg | %ds interval", 
			wave, diff.Meteors, diff.Damage, diff.Interval))
	end

	print("\n-- Income Progression (con 10 upgrades) --")
	for i = 0, 10, 2 do
		print(string.format("  %d upgrades: %d$/sec", i, Config.CalculateIncome(i)))
	end
	print("")
end

-------------------------------------------------------------------------
-- ?? INICIALIZACI�N
-------------------------------------------------------------------------
local isValid, errorMsg = Config.Validate()
if not isValid then
	error(("[CONFIG] Error de validaci�n: %s"):format(errorMsg or "desconocido"))
end

if Config.DEBUG_MODE then
	print("+-----------------------------------------------------------+")
	print("�        ? APOCALYPSE TYCOON - BALANCED CONFIG ?        �")
	print("�-----------------------------------------------------------�")
	print(string.format("�  Version: v%d | Mode: HIGH DIFFICULTY               �", Config.DATA_VERSION))
	print(string.format("�  DataStore: %-42s�", Config.DATASTORE_NAME))
	print(string.format("�  Start Cash: $%-6d | Income: %d$/sec base        �", Config.START_CASH, Config.CASH_PER_SEC_BASE))
	print(string.format("�  Base HP: %-3d | Meteor Damage: %-3d                �", Config.BASE_MAX_HP, Config.METEOR_DAMAGE))
	print("+-----------------------------------------------------------+")

	-- Mostrar preview de progresi�n
	Config.PrintProgressionCurve()
end

return Config