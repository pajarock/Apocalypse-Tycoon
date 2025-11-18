--!strict
--[[
	CONFIG.LUA - Apocalypse Tycoon
	Configuración central del juego
	
	VERSIÓN: 1.1
	ÚLTIMA ACTUALIZACIÓN: Sistema de balance mejorado
	
	NOTAS:
	- Todos los valores están balanceados para sesiones de 30-60 minutos
	- Modifica con cuidado: pequeños cambios afectan toda la economía
--]]

local Config = {}

--═══════════════════════════════════════════════════════════════════════
-- 💰 ECONOMÍA
--═══════════════════════════════════════════════════════════════════════
Config.START_CASH = 50  -- 🆕 Dar un pequeño boost inicial (era 0)
Config.CASH_PER_SEC_BASE = 1  -- Ingreso base sin upgrades
Config.TICK_SECS = 1  -- Frecuencia de actualización de income

-- 🆕 Límites de economía (prevenir exploits)
Config.MAX_CASH = 999999999  -- Límite superior de dinero
Config.MIN_CASH = 0  -- No permitir cash negativo

-- 🆕 Multiplicadores de progresión
Config.PRICE_MULTIPLIER = 1.15  -- Cada upgrade cuesta 15% más que el anterior
Config.INCOME_DIMINISHING_RETURNS = 0.95  -- Cada upgrade da 5% menos income relativo

-- 🆕 Offline Earnings
Config.OFFLINE_MAX_MINUTES = 30  -- Máximo 30 minutos de ganancias offline
Config.OFFLINE_RATE_MULTIPLIER = 0.3  -- Solo ganas 50% del income normal offline

--═══════════════════════════════════════════════════════════════════════
-- 🏗️ BASES Y CONSTRUCCIÓN
--═══════════════════════════════════════════════════════════════════════
Config.BASE_SIZE = Vector3.new(120, 1, 120)  -- Tamaño de la plataforma base
Config.SPAWN_RING_RADIUS = 250  -- Radio del círculo donde aparecen bases
Config.BASE_SPAWN_HEIGHT = 5  -- Altura sobre el terreno

-- 🆕 Límites de construcción
Config.MAX_MODELS_PER_BASE = 100  -- Límite para prevenir lag
Config.BUILD_GRID_COLUMNS = 4  -- Columnas en la grilla de construcción
Config.BUILD_CELL_SIZE = 8  -- Espacio entre modelos en studs

-- 🆕 Cosméticos de base
Config.BASE_COLORS = {
	Default = Color3.fromRGB(60, 60, 60),
	Damaged = Color3.fromRGB(120, 40, 40),  -- Rojo cuando HP < 30%
	Shielded = Color3.fromRGB(80, 120, 180),  -- Azul cuando tiene escudo
}

--═══════════════════════════════════════════════════════════════════════
-- 🛡️ SISTEMA DE DAÑO Y DEFENSA
--═══════════════════════════════════════════════════════════════════════
Config.BASE_MAX_HP = 100
Config.BASE_REGEN_RATE = 0.5  -- HP por segundo (0 = sin regen pasiva)
Config.REPAIR_COST_PER_HP = 100  -- $50 por punto de HP reparado

-- Escudos (✅ BALANCEADO: +20% efectividad)
Config.SHIELD_REDUCTION_PER_LEVEL = 0.18  -- 18% reducción por nivel (antes 15%)
Config.SHIELD_MAX_REDUCTION = 0.54  -- Máximo 54% de reducción (3 niveles)
Config.SHIELD_MAX_LEVEL = 3  -- 🆕 Nivel máximo de escudo

-- 🆕 Sistema de invencibilidad temporal
Config.RESPAWN_INVULNERABILITY_SECS = 5  -- 5 segundos de invencibilidad al respawnear

--═══════════════════════════════════════════════════════════════════════
-- ☄️ METEORITOS
--═══════════════════════════════════════════════════════════════════════
Config.METEOR_DAMAGE = 25  -- Daño base por impacto
Config.METEOR_DAMAGE_RADIUS = 20  -- Radio de daño en studs
Config.METEOR_MIN_Y = 120  -- Altura de spawn
Config.METEOR_VELOCITY = 140  -- Velocidad de caída
Config.METEOR_LIFETIME = 15  -- Segundos antes de auto-destruirse

-- 🆕 Variantes de meteoritos (para futuras implementaciones)
Config.METEOR_TYPES = {
	Small = {
		Damage = 10,
		Size = Vector3.new(4, 4, 4),
		Color = Color3.fromRGB(200, 100, 0),
		Speed = 180,
	},
	Normal = {
		Damage = 25,
		Size = Vector3.new(8, 8, 8),
		Color = Color3.fromRGB(255, 130, 0),
		Speed = 140,
	},
	Large = {
		Damage = 50,
		Size = Vector3.new(12, 12, 12),
		Color = Color3.fromRGB(255, 50, 0),
		Speed = 100,
	},
}

-- Debug
Config.METEOR_DEBUG_COOLDOWN = 5  -- Cooldown para debug spawn (anti-spam)

--═══════════════════════════════════════════════════════════════════════
-- 🎯 EVENTOS Y RAIDS
--═══════════════════════════════════════════════════════════════════════
Config.EVENT_INTERVAL = 300  -- Segundos entre eventos automáticos
Config.METEOR_COUNT = 30  -- Meteoritos por evento MeteorStorm
Config.RAIDER_HIT_DAMAGE = 5  -- Daño por golpe de raider

-- 🆕 Configuración de eventos específicos
Config.EVENTS = {
	MeteorStorm = {
		Duration = 30,  -- Duración del evento en segundos
		SpawnRate = 1,  -- Meteoritos por segundo
		WarnTime = 10,  -- Avisar 5 segundos antes
	},
	Raiders = {
		Count = 5,  -- Número de raiders por oleada
		HP = 100,  -- HP por raider
		Speed = 16,  -- Velocidad de movimiento
		AttackCooldown = 2,  -- Segundos entre ataques
	},
	-- 🆕 Preparado para eventos futuros
	BloodMoon = {
		Enabled = false,  -- Deshabilitado por ahora
		Multiplier = 2,  -- x2 dificultad
	},
}

--═══════════════════════════════════════════════════════════════════════
-- 🔧 SISTEMA DE REPARACIONES
--═══════════════════════════════════════════════════════════════════════
Config.REPAIR_BASE_COST = 50              -- Costo base de una reparación mínima
Config.REPAIR_MULTIPLIER = 1.35           -- Cada reparación siguiente cuesta +35%
Config.REPAIR_DECAY_SECS = 60             -- Cada 60s sin reparar, baja el streak (opcional)
Config.REPAIR_DAMAGE_FACTOR = 1.5         -- Factor extra si el daño fue alto


--═══════════════════════════════════════════════════════════════════════
-- 💾 DATASTORE Y GUARDADO
--═══════════════════════════════════════════════════════════════════════
Config.DATASTORE_NAME = "ApocalypseTycoon_v1"
Config.AUTOSAVE_SECS = 60  -- Auto-guardar cada minuto
Config.SAVE_ON_PURCHASE = false  -- 🆕 Guardar después de cada compra (puede ser laggy)
Config.MAX_SAVE_RETRIES = 3  -- 🆕 Reintentos si falla el guardado

-- 🆕 Estructura de datos versionada (para migraciones futuras)
Config.DATA_VERSION = 1

--═══════════════════════════════════════════════════════════════════════
-- 🔒 SEGURIDAD Y RATE LIMITING
--═══════════════════════════════════════════════════════════════════════
Config.MAX_PURCHASE_PER_SEC = 6  -- Límite de compras por segundo
Config.MAX_REPAIR_PER_REQUEST = 1000  -- Límite de HP reparables por click
Config.MAX_REMOTE_CALLS_PER_MIN = 120  -- 🆕 Límite global de llamadas remotas

-- 🆕 Anti-exploit
Config.VALIDATE_PRICES = true  -- Validar precios en servidor antes de comprar
Config.LOG_SUSPICIOUS_ACTIVITY = true  -- Loggear actividad sospechosa

--═══════════════════════════════════════════════════════════════════════
-- 🎨 UI Y EXPERIENCIA DE USUARIO
--═══════════════════════════════════════════════════════════════════════
-- 🆕 Configuración de interfaz
Config.UI = {
	ShowDamageNumbers = true,  -- Mostrar números flotantes al recibir daño
	ShowIncomePopups = true,  -- Mostrar "+$X" al generar income
	ShakeOnDamage = true,  -- Shake de cámara al recibir daño fuerte
	LowHealthWarning = 30,  -- % de HP para mostrar advertencia
	NotificationDuration = 3,  -- Segundos que duran las notificaciones
}

-- 🆕 Colores de la UI
Config.UI_COLORS = {
	Income = Color3.fromRGB(100, 255, 100),  -- Verde para income
	Damage = Color3.fromRGB(255, 80, 80),  -- Rojo para daño
	Repair = Color3.fromRGB(100, 200, 255),  -- Azul para reparación
	Warning = Color3.fromRGB(255, 200, 0),  -- Amarillo para advertencias
}

--═══════════════════════════════════════════════════════════════════════
-- 🔊 SONIDOS (preparado para implementación)
--═══════════════════════════════════════════════════════════════════════
-- 🆕 IDs de sonidos de Roblox (reemplazar con tus propios assets)
Config.SOUNDS = {
	Purchase = "rbxassetid://0",  -- Sonido al comprar
	MeteorImpact = "rbxassetid://9118617342",  -- Sonido de impacto
	BaseDamaged = "rbxassetid://0",  -- Sonido al recibir daño
	IncomeEarned = "rbxassetid://0",  -- Sonido de income
	LevelUp = "rbxassetid://0",  -- Sonido al subir de nivel/prestige
	Warning = "rbxassetid://0",  -- Sonido de alerta
}

Config.SOUND_VOLUME = 0.5  -- Volumen general (0-1)
Config.MUSIC_ENABLED = false  -- Música de fondo (implementar después)

--═══════════════════════════════════════════════════════════════════════
-- 👑 VIP Y GAMEPASSES (preparado para monetización)
--═══════════════════════════════════════════════════════════════════════
-- 🆕 IDs de productos de Roblox (configurar cuando crees los gamepasses)
Config.GAMEPASSES = {
	DoubleIncome = {
		ID = 0,  -- Reemplazar con ID real
		Multiplier = 2,
		Enabled = false,
	},
	InstantRepair = {
		ID = 0,
		Cost = 100,  -- Robux
		Enabled = false,
	},
	PremiumSlots = {
		ID = 0,
		ExtraSlots = 50,  -- 50 slots adicionales de construcción
		Enabled = false,
	},
}

--═══════════════════════════════════════════════════════════════════════
-- 📊 ANALYTICS Y DEBUG
--═══════════════════════════════════════════════════════════════════════
-- 🆕 Sistema de telemetría (para balancear el juego)
Config.ANALYTICS = {
	Enabled = true,  -- Guardar estadísticas de juego
	TrackPurchases = true,
	TrackDeaths = true,
	TrackSessionTime = true,
	TrackIncome = true,
}

-- Debug
Config.DEBUG_MODE = true-- 🆕 Activar logs detallados (desactivar en producción)
Config.SHOW_DEBUG_UI = false  -- 🆕 Mostrar UI de debug a todos los jugadores

--═══════════════════════════════════════════════════════════════════════
-- 🎮 BALANCE Y PROGRESIÓN
--═══════════════════════════════════════════════════════════════════════
-- 🆕 Curvas de progresión
Config.PROGRESSION = {
	EarlyGame = {
		MaxMinutes = 10,
		IncomeBoost = 1.5,  -- 50% más income en primeros 10 minutos
	},
	MidGame = {
		MaxMinutes = 30,
		IncomeBoost = 1.0,  -- Income normal
	},
	LateGame = {
		MaxMinutes = 999,
		IncomeBoost = 0.8,  -- Reducir grinding excesivo
	},
}

-- 🆕 Prestige (implementar en futuro)
Config.PRESTIGE = {
	Enabled = false,
	RequiredCash = 1000000,  -- $1M para hacer prestige
	BonusPerPrestige = 0.1,  -- +10% income permanente por prestige
	MaxPrestige = 10,
}

--═══════════════════════════════════════════════════════════════════════
-- 🛠️ UTILIDADES DE VALIDACIÓN
--═══════════════════════════════════════════════════════════════════════
-- 🆕 Función para validar que el config sea correcto
function Config.Validate(): (boolean, string?)
	-- Validar que valores críticos estén en rangos válidos
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

	-- Validar que no haya duplicados en tipos de meteoritos
	local meteorNames = {}
	for name, _ in pairs(Config.METEOR_TYPES) do
		if meteorNames[name] then
			return false, ("Tipo de meteorito duplicado: %s"):format(name)
		end
		meteorNames[name] = true
	end

	return true, nil
end

-- 🆕 Función para obtener un valor con fallback
function Config.Get(key: string, default: any): any
	local value = Config[key]
	if value ~= nil then
		return value
	end

	warn(("[CONFIG] Clave no encontrada: %s, usando default: %s"):format(key, tostring(default)))
	return default
end

-- 🆕 Función para ajustar dificultad según jugadores activos
function Config.GetDynamicDifficulty(playerCount: number): number
	-- Más jugadores = eventos más frecuentes pero repartidos
	if playerCount <= 1 then
		return 1.0  -- Dificultad normal
	elseif playerCount <= 5 then
		return 0.8  -- 20% más fácil (menos eventos)
	else
		return 0.6  -- 40% más fácil en servers llenos
	end
end

--═══════════════════════════════════════════════════════════════════════
-- 🏁 INICIALIZACIÓN
--═══════════════════════════════════════════════════════════════════════
-- Validar config al cargar el módulo
local isValid, errorMsg = Config.Validate()
if not isValid then
	error(("[CONFIG] Error de validación: %s"):format(errorMsg or "desconocido"))
end

-- Log de confirmación
if Config.DEBUG_MODE then
	print("[CONFIG] ✓ Configuración cargada y validada correctamente")
	print(("[CONFIG] Versión de datos: v%d"):format(Config.DATA_VERSION))
	print(("[CONFIG] DataStore: %s"):format(Config.DATASTORE_NAME))
end

--═══════════════════════════════════════════════════════════════════════
-- 🌊 SISTEMA DE WAVES (✅ BALANCEADO - Opción B: Moderado)
--═══════════════════════════════════════════════════════════════════════
Config.CURRENT_WAVE = 1
Config.METEORS_PER_WAVE_BASE = 7  -- ✅ REDUCIDO: 8 → 7 (-12% meteoritos)

function Config.GetWaveDifficulty(waveNum: number)
	return {
		Meteors = Config.METEORS_PER_WAVE_BASE + (waveNum * 2),  -- Wave 1: 7, Wave 2: 9, Wave 3: 11
		Damage = 14 + (waveNum * 4),  -- ✅ REDUCIDO: base 20→14, crecimiento +5→+4 (Wave 1: 18, Wave 2: 22, Wave 3: 26)
		Interval = math.max(45, 90 - (waveNum * 3))  -- Tiempo entre waves (mantener)
	}
end

-- Validar config al cargar el módulo
local isValid, errorMsg = Config.Validate()
if not isValid then
	error(("[CONFIG] Error de validación: %s"):format(errorMsg or "desconocido"))
end

-- Log de confirmación
if Config.DEBUG_MODE then
	print("[CONFIG] ✓ Configuración cargada y validada correctamente")
	print(("[CONFIG] Versión de datos: v%d"):format(Config.DATA_VERSION))
	print(("[CONFIG] DataStore: %s"):format(Config.DATASTORE_NAME))
end

return Config