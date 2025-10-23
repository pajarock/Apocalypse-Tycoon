--!strict
--[[
	CONFIG - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Configuración centralizada del juego.
	Todos los valores ajustables deben estar aquí.

	USAGE:
		local Config = require(game.ServerStorage.Config.Config)
		print(Config.BASE_MAX_HP)
--]]

local RunService = game:GetService("RunService")

--═══════════════════════════════════════════════════════════════════════
-- CONFIG TABLE
--═══════════════════════════════════════════════════════════════════════

local Config = {}

--═══════════════════════════════════════════════════════════════════════
-- GENERAL
--═══════════════════════════════════════════════════════════════════════

Config.GAME_VERSION = "5.0.0"
Config.DEBUG_MODE = RunService:IsStudio() -- Auto-detectar Studio
Config.TICK_SECS = 1 -- Tick de economía cada 1 segundo
Config.AUTOSAVE_SECS = 120 -- Autosave cada 2 minutos

--═══════════════════════════════════════════════════════════════════════
-- DATASTORE
--═══════════════════════════════════════════════════════════════════════

Config.DATASTORE_NAME = "ApocalypseTycoon_V5"
Config.DATA_VERSION = 5

--═══════════════════════════════════════════════════════════════════════
-- ECONOMÍA
--═══════════════════════════════════════════════════════════════════════

Config.START_CASH = 100
Config.MIN_CASH = 0
Config.MAX_CASH = 1e15 -- 1 quadrillón
Config.INCOME_TICK_INTERVAL = 1 -- segundos

-- Offline Earnings
Config.OFFLINE_MAX_MINUTES = 120 -- 2 horas máximo
Config.OFFLINE_RATE_MULTIPLIER = 0.5 -- 50% del rate normal

--═══════════════════════════════════════════════════════════════════════
-- BASE
--═══════════════════════════════════════════════════════════════════════

Config.BASE_MAX_HP = 100
Config.BASE_REGEN_RATE = 1 -- HP por segundo
Config.BASE_REGEN_DELAY = 5 -- segundos sin daño antes de regenerar
Config.BASE_SIZE = Vector3.new(60, 1, 60)
Config.BASE_SPAWN_HEIGHT = 5
Config.SPAWN_RING_RADIUS = 150 -- Radio del círculo de bases

-- Shield System
Config.SHIELD_DAMAGE_REDUCTION = 0.15 -- 15% por nivel de shield

-- Repair System
Config.REPAIR_COST_PER_HP = 10
Config.MAX_REPAIR_PER_REQUEST = 100

-- Base Colors
Config.BASE_COLORS = {
	Default = Color3.fromRGB(80, 80, 80),
	Damaged = Color3.fromRGB(120, 100, 80),
	Critical = Color3.fromRGB(150, 80, 60),
	Burning = Color3.fromRGB(180, 60, 40)
}

--═══════════════════════════════════════════════════════════════════════
-- METEORITOS
--═══════════════════════════════════════════════════════════════════════

Config.METEOR_TYPES = {
	Small = {
		Speed = 60,
		Size = Vector3.new(3, 3, 3),
		Color = Color3.fromRGB(255, 150, 100),
		Damage = 10,
		HP = 50 -- HP del meteorito (para que dinosaurios puedan destruirlo)
	},

	Normal = {
		Speed = 45,
		Size = Vector3.new(6, 6, 6),
		Color = Color3.fromRGB(255, 100, 50),
		Damage = 25,
		HP = 100
	},

	Large = {
		Speed = 30,
		Size = Vector3.new(10, 10, 10),
		Color = Color3.fromRGB(200, 50, 20),
		Damage = 50,
		HP = 200
	},

	Boss = {
		Speed = 20,
		Size = Vector3.new(15, 15, 15),
		Color = Color3.fromRGB(150, 20, 20),
		Damage = 100,
		HP = 500
	}
}

Config.METEOR_MIN_Y = 200 -- Altura mínima de spawn
Config.METEOR_MAX_Y = 300 -- Altura máxima de spawn
Config.METEOR_LIFETIME = 30 -- segundos antes de despawn automático
Config.METEOR_COUNT = 5 -- meteoritos por storm
Config.METEOR_SPREAD = 40 -- studs de spread aleatorio
Config.METEOR_DEBUG_COOLDOWN = 5 -- segundos entre debug spawns (tecla M)

-- Meteor Damage to Players
Config.METEOR_PLAYER_DAMAGE = 25 -- Daño base a jugadores
Config.METEOR_DAMAGE_RADIUS = 20 -- studs desde el impacto
Config.JUMP_IMMUNITY_HEIGHT = 5 -- studs sobre el suelo para evadir

--═══════════════════════════════════════════════════════════════════════
-- WAVES
--═══════════════════════════════════════════════════════════════════════

Config.WAVE_SYSTEM = {
	Enabled = true,
	StartDelay = 30, -- segundos antes del primer wave
	BaseInterval = 60, -- segundos entre waves
}

-- Dificultad por wave
Config.WAVE_DIFFICULTY = {
	{wave = 1, meteors = 3, damage = 10, interval = 60},
	{wave = 5, meteors = 5, damage = 15, interval = 50}, -- Boss
	{wave = 10, meteors = 7, damage = 20, interval = 45}, -- Boss
	{wave = 15, meteors = 10, damage = 25, interval = 40}, -- Boss
	{wave = 20, meteors = 15, damage = 30, interval = 35}, -- Boss
}

function Config.GetWaveDifficulty(wave: number)
	-- Buscar configuración exacta
	for i = #Config.WAVE_DIFFICULTY, 1, -1 do
		local cfg = Config.WAVE_DIFFICULTY[i]
		if wave >= cfg.wave then
			return cfg
		end
	end

	-- Default para wave 1
	return Config.WAVE_DIFFICULTY[1]
end

function Config.GetDynamicDifficulty(playerCount: number): number
	-- Escalar dificultad con número de jugadores
	if playerCount <= 1 then
		return 1.0
	elseif playerCount <= 3 then
		return 0.9
	elseif playerCount <= 5 then
		return 0.8
	elseif playerCount <= 10 then
		return 0.7
	else
		return 0.6
	end
end

--═══════════════════════════════════════════════════════════════════════
-- PRESTIGE
--═══════════════════════════════════════════════════════════════════════

Config.PRESTIGE = {
	Enabled = true,
	RequiredCash = 1000000, -- 1 millón
	BonusPerPrestige = 0.10, -- 10% bonus income por nivel
	MaxPrestige = 50
}

--═══════════════════════════════════════════════════════════════════════
-- GAMEPASSES
--═══════════════════════════════════════════════════════════════════════

Config.GAMEPASSES = {
	DoubleIncome = {
		ID = 0, -- CAMBIAR EN PRODUCCIÓN
		Name = "Double Income",
		Multiplier = 2.0
	},

	InstantRepair = {
		ID = 0, -- CAMBIAR EN PRODUCCIÓN
		Name = "Instant Repair",
		CostReduction = 0.5 -- 50% más barato
	},

	PremiumSlots = {
		ID = 0, -- CAMBIAR EN PRODUCCIÓN
		Name = "Premium Slots",
		BonusSlots = 10
	}
}

--═══════════════════════════════════════════════════════════════════════
-- TUTORIAL
--═══════════════════════════════════════════════════════════════════════

Config.TUTORIAL = {
	Enabled = true,
	RewardFreeSummons = 10, -- Summons gratis al completar
	TutorialZonePosition = Vector3.new(0, 1000, 0), -- Lejos del mapa principal
	MeteorWarningTime = 2, -- segundos de warning antes del impacto
	MaxRetries = 3 -- reintentos para dodge
}

--═══════════════════════════════════════════════════════════════════════
-- SUMMON SYSTEM (GACHA)
--═══════════════════════════════════════════════════════════════════════

Config.SUMMON = {
	Enabled = true,
	CostPerSummon = 1000, -- Cash por summon (si no es gratis)
	CostIncrease = 1.1, -- 10% más caro cada vez (opcional)

	-- Drop rates (deben sumar 1.0)
	DropRates = {
		Common = 0.70, -- 70%
		Rare = 0.20, -- 20%
		Epic = 0.08, -- 8%
		Legendary = 0.02 -- 2%
	},

	-- Max dinosaurios activos simultáneamente
	MaxActiveDinosaurs = 20,

	-- Animation
	EggBreakDuration = 2, -- segundos de animación
	RevealDuration = 3 -- segundos mostrando el resultado
}

--═══════════════════════════════════════════════════════════════════════
-- DINOSAURS
--═══════════════════════════════════════════════════════════════════════

Config.DINOSAURS = {
	Velociraptor = {
		Rarity = "Common",
		HP = 100,
		Damage = 15,
		AttackSpeed = 1.5, -- ataques/segundo
		Range = 20,
		MoveSpeed = 16,
		Description = "Fast attacker with quick strikes"
	},

	Triceratops = {
		Rarity = "Rare",
		HP = 300,
		Damage = 30,
		AttackSpeed = 0.5,
		Range = 15,
		MoveSpeed = 8,
		Description = "Tanky defender with high HP"
	},

	Pteranodon = {
		Rarity = "Epic",
		HP = 150,
		Damage = 25,
		AttackSpeed = 2.0,
		Range = 40,
		MoveSpeed = 24,
		CanFly = true,
		Description = "Flying unit that intercepts meteors"
	},

	TRex = {
		Rarity = "Legendary",
		HP = 500,
		Damage = 100,
		AttackSpeed = 0.8,
		Range = 25,
		MoveSpeed = 12,
		AOE = 10, -- Area damage
		Description = "Massive damage with area attacks"
	}
}

--═══════════════════════════════════════════════════════════════════════
-- UI
--═══════════════════════════════════════════════════════════════════════

Config.UI = {
	ShowIncomePopups = true,
	PopupDuration = 2, -- segundos
	NotificationDuration = 3, -- segundos

	Colors = {
		Success = Color3.fromRGB(0, 255, 0),
		Error = Color3.fromRGB(255, 0, 0),
		Warning = Color3.fromRGB(255, 200, 0),
		Info = Color3.fromRGB(100, 150, 255)
	}
}

Config.UI_COLORS = Config.UI.Colors -- Alias para compatibilidad

--═══════════════════════════════════════════════════════════════════════
-- ANALYTICS
--═══════════════════════════════════════════════════════════════════════

Config.ANALYTICS = {
	Enabled = false, -- Activar cuando tengas servicio de analytics
	ServiceURL = "", -- URL de tu servicio (ej: Google Analytics)
	Events = {
		"PlayerJoined",
		"PlayerLeft",
		"Purchase",
		"Prestige",
		"WaveCompleted",
		"BaseDead",
		"DinosaurSummoned",
		"TutorialCompleted"
	}
}

--═══════════════════════════════════════════════════════════════════════
-- PERFORMANCE
--═══════════════════════════════════════════════════════════════════════

Config.PERFORMANCE = {
	MaxModelsPerBase = 100,
	VFXPoolSize = 50, -- Max efectos en pool
	MaxParticlesActive = 200,
	CleanupInterval = 30, -- segundos
}

Config.MAX_MODELS_PER_BASE = Config.PERFORMANCE.MaxModelsPerBase -- Alias

--═══════════════════════════════════════════════════════════════════════
-- EVENTS
--═══════════════════════════════════════════════════════════════════════

Config.EVENTS = {
	MeteorStorm = {
		Enabled = true,
		Interval = 60, -- segundos
		Duration = 10, -- segundos
		MeteorCount = 5
	},

	BossMeteor = {
		Enabled = true,
		EveryNWaves = 5, -- Cada 5 waves
		Damage = 100,
		Size = Vector3.new(15, 15, 15)
	}
}

--═══════════════════════════════════════════════════════════════════════
-- VALIDATION
--═══════════════════════════════════════════════════════════════════════

function Config.Validate(): (boolean, string?)
	-- Validar configuración crítica

	if Config.BASE_MAX_HP <= 0 then
		return false, "BASE_MAX_HP debe ser > 0"
	end

	if Config.START_CASH < 0 then
		return false, "START_CASH debe ser >= 0"
	end

	if Config.TICK_SECS <= 0 then
		return false, "TICK_SECS debe ser > 0"
	end

	-- Validar drop rates
	local totalRate = 0
	for _, rate in pairs(Config.SUMMON.DropRates) do
		totalRate += rate
	end

	if math.abs(totalRate - 1.0) > 0.01 then
		return false, string.format("Drop rates deben sumar 1.0 (actual: %.2f)", totalRate)
	end

	return true
end

--═══════════════════════════════════════════════════════════════════════
-- DEBUG
--═══════════════════════════════════════════════════════════════════════

if Config.DEBUG_MODE then
	print("═══════════════════════════════════════════════════════════════")
	print("  CONFIG - Apocalypse Tycoon")
	print("═══════════════════════════════════════════════════════════════")
	print(("  Version: %s"):format(Config.GAME_VERSION))
	print(("  Debug Mode: ENABLED"))
	print(("  DataStore: %s (v%d)"):format(Config.DATASTORE_NAME, Config.DATA_VERSION))
	print(("  Base HP: %d"):format(Config.BASE_MAX_HP))
	print(("  Start Cash: $%d"):format(Config.START_CASH))
	print(("  Meteor Types: %d"):format(#Config.METEOR_TYPES))
	print(("  Dinosaur Types: %d"):format(4)) -- Hardcoded por ahora
	print(("  Tutorial: %s"):format(Config.TUTORIAL.Enabled and "ON" or "OFF"))
	print(("  Summon System: %s"):format(Config.SUMMON.Enabled and "ON" or "OFF"))
	print("═══════════════════════════════════════════════════════════════")

	-- Validar
	local valid, err = Config.Validate()
	if valid then
		print("  ✅ Configuration is valid")
	else
		warn(("  ❌ Configuration ERROR: %s"):format(err or "unknown"))
	end

	print("═══════════════════════════════════════════════════════════════\n")
end

--═══════════════════════════════════════════════════════════════════════

return Config
