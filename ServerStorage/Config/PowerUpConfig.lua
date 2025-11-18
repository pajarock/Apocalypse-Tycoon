--!strict
--[[
	POWER-UP CONFIG - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Configuración de todos los power-ups del juego.
	Data-driven para facilitar balanceo sin tocar código.

	USAGE:
		local PowerUpConfig = require(game.ServerStorage.Config.PowerUpConfig)
		local shieldData = PowerUpConfig.PowerUps.ShieldBubble
		print(shieldData.Duration) -- 10
]]

local PowerUpConfig = {}

--═══════════════════════════════════════════════════════════════════════
-- POWER-UP DEFINITIONS
--═══════════════════════════════════════════════════════════════════════

PowerUpConfig.PowerUps = {
	ShieldBubble = {
		Name = "Shield Bubble",
		DisplayName = "🛡️ Shield Bubble",
		Description = "Invulnerabilidad total por 10 segundos",
		Duration = 10, -- segundos
		Cooldown = 0, -- sin cooldown entre pickups
		Stackable = true, -- extender duración si recoges otro
		StackBonus = 5, -- +5 segundos extra al stackear

		-- Visual
		Color = Color3.fromRGB(0, 170, 255), -- Azul brillante
		Icon = "🛡️",
		PartSize = Vector3.new(2, 2, 2),
		PartShape = "Ball",

		-- Efectos
		Effects = {
			Shield = true, -- Activa escudo
			DamageReduction = 1.0, -- 100% reducción (invulnerable)
		},

		-- Drop rates
		DropChance = {
			MeteorSmall = 0.06,
			MeteorNormal = 0.08,
			MeteorLarge = 0.12,
			MiniBoss = 0.50,
			Boss = 1.0,
		},
	},

	SlowMotion = {
		Name = "Slow Motion",
		DisplayName = "⏱️ Slow Motion",
		Description = "Ralentiza meteoritos 50% por 8 segundos",
		Duration = 8,
		Cooldown = 0,
		Stackable = true,
		StackBonus = 4,

		-- Visual
		Color = Color3.fromRGB(150, 50, 200), -- Morado
		Icon = "⏱️",
		PartSize = Vector3.new(2, 2, 2),
		PartShape = "Ball",

		-- Efectos
		Effects = {
			SlowMotion = true,
			MeteorSpeedMultiplier = 0.5, -- 50% velocidad
		},

		-- Drop rates (más raro, es muy OP)
		DropChance = {
			MeteorSmall = 0.03,
			MeteorNormal = 0.05,
			MeteorLarge = 0.08,
			MiniBoss = 0.40,
			Boss = 0.80,
		},
	},

	CoinRain = {
		Name = "Coin Rain",
		DisplayName = "💰 Coin Rain x2",
		Description = "Dobla todas las ganancias por 30 segundos",
		Duration = 30,
		Cooldown = 0,
		Stackable = true,
		StackBonus = 15, -- +15s extra

		-- Visual
		Color = Color3.fromRGB(255, 215, 0), -- Dorado
		Icon = "💰",
		PartSize = Vector3.new(2, 2, 2),
		PartShape = "Ball",

		-- Efectos
		Effects = {
			CoinMultiplier = 2, -- 2x coins
		},

		-- Drop rates (común)
		DropChance = {
			MeteorSmall = 0.08,
			MeteorNormal = 0.10,
			MeteorLarge = 0.12,
			MiniBoss = 0.60,
			Boss = 1.0,
		},
	},

	AutoRepair = {
		Name = "Auto Repair",
		DisplayName = "🔧 Auto-Repair",
		Description = "Repara +5 HP/segundo por 20 segundos",
		Duration = 20,
		Cooldown = 0,
		Stackable = true,
		StackBonus = 10,

		-- Visual
		Color = Color3.fromRGB(0, 255, 100), -- Verde brillante
		Icon = "🔧",
		PartSize = Vector3.new(2, 2, 2),
		PartShape = "Ball",

		-- Efectos
		Effects = {
			HealPerSecond = 5, -- +5 HP cada segundo
		},

		-- Drop rates
		DropChance = {
			MeteorSmall = 0.07,
			MeteorNormal = 0.09,
			MeteorLarge = 0.11,
			MiniBoss = 0.55,
			Boss = 1.0,
		},
	},

	DamageBoost = {
		Name = "Damage Boost",
		DisplayName = "💥 Damage Boost x3",
		Description = "Triplica tu daño por 15 segundos",
		Duration = 15,
		Cooldown = 0,
		Stackable = true,
		StackBonus = 7,

		-- Visual
		Color = Color3.fromRGB(255, 50, 50), -- Rojo intenso
		Icon = "💥",
		PartSize = Vector3.new(2, 2, 2),
		PartShape = "Ball",

		-- Efectos
		Effects = {
			DamageMultiplier = 3, -- 3x daño
		},

		-- Drop rates
		DropChance = {
			MeteorSmall = 0.06,
			MeteorNormal = 0.08,
			MeteorLarge = 0.10,
			MiniBoss = 0.50,
			Boss = 1.0,
		},
	},
}

--═══════════════════════════════════════════════════════════════════════
-- GENERAL SETTINGS
--═══════════════════════════════════════════════════════════════════════

PowerUpConfig.Settings = {
	-- Despawn time si no se recoge
	DespawnTime = 15, -- segundos

	-- Pickup radius (auto-pickup si estás cerca)
	PickupRadius = 8, -- studs

	-- Visual effects
	RotationSpeed = 45, -- grados por segundo
	HoverHeight = 2, -- studs arriba/abajo
	HoverSpeed = 1, -- velocidad del hover

	-- Particles
	ParticleRate = 10, -- partículas por segundo
	ParticleLifetime = 1, -- segundos

	-- Multiple power-ups activos
	MaxActivePowerUps = 5, -- máximo 5 power-ups activos al mismo tiempo

	-- Debug
	ShowDebugMessages = true,
}

--═══════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
--═══════════════════════════════════════════════════════════════════════

-- Obtener power-up aleatorio basado en source (meteor, boss, etc)
function PowerUpConfig:GetRandomPowerUp(source: string): string?
	local validPowerUps = {}

	for powerUpName, data in pairs(self.PowerUps) do
		local chance = data.DropChance[source] or 0
		if chance > 0 and math.random() <= chance then
			table.insert(validPowerUps, powerUpName)
		end
	end

	if #validPowerUps == 0 then
		return nil
	end

	return validPowerUps[math.random(1, #validPowerUps)]
end

-- Obtener todos los nombres de power-ups
function PowerUpConfig:GetAllPowerUpNames(): {string}
	local names = {}
	for name, _ in pairs(self.PowerUps) do
		table.insert(names, name)
	end
	return names
end

-- Validar que un power-up existe
function PowerUpConfig:IsValidPowerUp(name: string): boolean
	return self.PowerUps[name] ~= nil
end

--═══════════════════════════════════════════════════════════════════════

if PowerUpConfig.Settings.ShowDebugMessages then
	print("[PowerUpConfig] ✓ Cargado con", #PowerUpConfig:GetAllPowerUpNames(), "power-ups")
end

return PowerUpConfig
