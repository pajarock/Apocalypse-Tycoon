--!strict
--[[
	TurretDefinitions.luau - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Definiciones completas de todas las torretas defensivas del juego.

	TORRETAS DISPONIBLES:
	1. Machine Gun (T1-T5) - Ráfaga rápida, DPS constante
	2. Laser Turret (T1-T5) - Rayo continuo, especializado en Large meteors
	3. Missile Launcher (T1-T5) - AOE explosivo, cooldown alto
	4. Tesla Coil (T1-T5) - Cadena eléctrica, multi-target
	5. Shield Dome - Defensa especial, protección temporal

	═══════════════════════════════════════════════════════════════════════
]]

--[[────────────────────────────────────────────────────────────────────────
	TYPE DEFINITIONS
────────────────────────────────────────────────────────────────────────]]

export type TargetPriority = "Closest" | "Furthest" | "Strongest" | "Weakest"

export type TurretStats = {
	-- Daño y combate
	Damage: number?,           -- Daño por disparo (Machine Gun, Missile)
	DPS: number?,              -- Daño por segundo (Laser)
	AOERadius: number?,        -- Radio de explosión (Missile)
	MaxChains: number?,        -- Cadenas máximas (Tesla)
	ChainRange: number?,       -- Rango entre cadenas (Tesla)

	-- Timing
	FireRate: number?,         -- Segundos entre disparos
	Cooldown: number?,         -- Cooldown entre ataques
	BeamDuration: string?,     -- Duración del beam (Laser)

	-- Alcance y targeting
	Range: number,             -- Alcance máximo en studs
	TargetPriority: TargetPriority,

	-- Shield Dome específico
	DomeHP: number?,           -- HP del escudo
	DomeDuration: number?,     -- Duración en segundos
	DomeRadius: number?,       -- Radio del domo
	AutoTriggerHP: number?,    -- % de HP para auto-activar
}

export type TurretDefinition = {
	-- Identificación
	Name: string,
	DisplayName: string,
	Description: string,
	Tier: number,              -- 1-5 para torretas, 0 para Shield Dome

	-- Visual
	Size: Vector3,
	Color: Color3,
	Material: Enum.Material,

	-- Económico
	Cost: number,              -- Costo de colocación (T1) o upgrade

	-- Stats de combate
	Stats: TurretStats,

	-- Comportamiento
	Category: "Defense",
	TurretType: "MachineGun" | "Laser" | "Missile" | "Tesla" | "ShieldDome",
	IsPlaceable: boolean,
	CanUpgrade: boolean,
}

--[[────────────────────────────────────────────────────────────────────────
	MACHINE GUN TURRET (T1-T5)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	Especialidad: Ráfaga rápida, DPS constante
	Estrategia: Mata meteoritos pequeños rápidamente. Barato en early-game.
────────────────────────────────────────────────────────────────────────]]

local TurretDefinitions = {}

-- MACHINE GUN T1
TurretDefinitions.MachineGunT1 = {
	Name = "MachineGunT1",
	DisplayName = "🔫 Machine Gun T1",
	Description = "Rapid-fire turret. Best value for early defense.",
	Tier = 1,

	Size = Vector3.new(6, 8, 6),
	Color = Color3.fromRGB(100, 100, 120),  -- Gris metálico
	Material = Enum.Material.Metal,

	Cost = 5000,

	Stats = {
		Damage = 8,
		FireRate = 0.25,  -- 4 disparos/segundo
		Range = 50,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "MachineGun",
	IsPlaceable = true,
	CanUpgrade = true,
} :: TurretDefinition

-- MACHINE GUN T2
TurretDefinitions.MachineGunT2 = {
	Name = "MachineGunT2",
	DisplayName = "🔫 Machine Gun T2",
	Description = "Improved fire rate and damage. Reliable mid-game defense.",
	Tier = 2,

	Size = Vector3.new(7, 9, 7),
	Color = Color3.fromRGB(120, 120, 140),
	Material = Enum.Material.Metal,

	Cost = 20000,

	Stats = {
		Damage = 12,
		FireRate = 0.20,  -- 5 disparos/segundo
		Range = 60,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "MachineGun",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- MACHINE GUN T3
TurretDefinitions.MachineGunT3 = {
	Name = "MachineGunT3",
	DisplayName = "🔫 Machine Gun T3",
	Description = "High-velocity rounds. Shreds normal meteors.",
	Tier = 3,

	Size = Vector3.new(8, 10, 8),
	Color = Color3.fromRGB(140, 140, 160),
	Material = Enum.Material.Metal,

	Cost = 80000,

	Stats = {
		Damage = 18,
		FireRate = 0.15,  -- 6.67 disparos/segundo
		Range = 70,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "MachineGun",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- MACHINE GUN T4
TurretDefinitions.MachineGunT4 = {
	Name = "MachineGunT4",
	DisplayName = "🔫 Machine Gun T4",
	Description = "Armor-piercing rounds. Devastating DPS.",
	Tier = 4,

	Size = Vector3.new(9, 11, 9),
	Color = Color3.fromRGB(160, 160, 180),
	Material = Enum.Material.Metal,

	Cost = 350000,

	Stats = {
		Damage = 28,
		FireRate = 0.12,  -- 8.33 disparos/segundo
		Range = 80,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "MachineGun",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- MACHINE GUN T5
TurretDefinitions.MachineGunT5 = {
	Name = "MachineGunT5",
	DisplayName = "🔫 Machine Gun T5 MAX",
	Description = "Ultimate rapid-fire cannon. MAXIMUM TIER.",
	Tier = 5,

	Size = Vector3.new(10, 12, 10),
	Color = Color3.fromRGB(180, 180, 200),
	Material = Enum.Material.Metal,

	Cost = 1500000,

	Stats = {
		Damage = 45,
		FireRate = 0.10,  -- 10 disparos/segundo
		Range = 100,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "MachineGun",
	IsPlaceable = false,
	CanUpgrade = false,  -- MAX TIER
} :: TurretDefinition

--[[────────────────────────────────────────────────────────────────────────
	LASER TURRET (T1-T5)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	Especialidad: Rayo continuo, mejor contra Large meteors
	Estrategia: Especializado en meteoritos grandes. DPS alto pero caro.
────────────────────────────────────────────────────────────────────────]]

-- LASER T1
TurretDefinitions.LaserT1 = {
	Name = "LaserT1",
	DisplayName = "⚡ Laser Turret T1",
	Description = "Continuous beam weapon. Effective vs Large meteors.",
	Tier = 1,

	Size = Vector3.new(6, 10, 6),
	Color = Color3.fromRGB(255, 50, 50),  -- Rojo láser
	Material = Enum.Material.Neon,

	Cost = 15000,

	Stats = {
		DPS = 25,
		Range = 70,
		BeamDuration = "Continuous",
		TargetPriority = "Strongest",
	},

	Category = "Defense",
	TurretType = "Laser",
	IsPlaceable = true,
	CanUpgrade = true,
} :: TurretDefinition

-- LASER T2
TurretDefinitions.LaserT2 = {
	Name = "LaserT2",
	DisplayName = "⚡ Laser Turret T2",
	Description = "Enhanced beam focus. Melts armor quickly.",
	Tier = 2,

	Size = Vector3.new(7, 11, 7),
	Color = Color3.fromRGB(255, 80, 80),
	Material = Enum.Material.Neon,

	Cost = 60000,

	Stats = {
		DPS = 50,
		Range = 80,
		BeamDuration = "Continuous",
		TargetPriority = "Strongest",
	},

	Category = "Defense",
	TurretType = "Laser",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- LASER T3
TurretDefinitions.LaserT3 = {
	Name = "LaserT3",
	DisplayName = "⚡ Laser Turret T3",
	Description = "Superheated beam. Vaporizes large threats.",
	Tier = 3,

	Size = Vector3.new(8, 12, 8),
	Color = Color3.fromRGB(255, 100, 100),
	Material = Enum.Material.Neon,

	Cost = 250000,

	Stats = {
		DPS = 100,
		Range = 90,
		BeamDuration = "Continuous",
		TargetPriority = "Strongest",
	},

	Category = "Defense",
	TurretType = "Laser",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- LASER T4
TurretDefinitions.LaserT4 = {
	Name = "LaserT4",
	DisplayName = "⚡ Laser Turret T4",
	Description = "Plasma-enhanced beam. Unstoppable damage.",
	Tier = 4,

	Size = Vector3.new(9, 13, 9),
	Color = Color3.fromRGB(255, 120, 120),
	Material = Enum.Material.Neon,

	Cost = 1000000,

	Stats = {
		DPS = 200,
		Range = 110,
		BeamDuration = "Continuous",
		TargetPriority = "Strongest",
	},

	Category = "Defense",
	TurretType = "Laser",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- LASER T5
TurretDefinitions.LaserT5 = {
	Name = "LaserT5",
	DisplayName = "⚡ Laser Turret T5 MAX",
	Description = "Ultimate beam cannon. Nothing survives. MAXIMUM TIER.",
	Tier = 5,

	Size = Vector3.new(10, 14, 10),
	Color = Color3.fromRGB(255, 150, 150),
	Material = Enum.Material.Neon,

	Cost = 4500000,

	Stats = {
		DPS = 400,
		Range = 130,
		BeamDuration = "Continuous",
		TargetPriority = "Strongest",
	},

	Category = "Defense",
	TurretType = "Laser",
	IsPlaceable = false,
	CanUpgrade = false,  -- MAX TIER
} :: TurretDefinition

--[[────────────────────────────────────────────────────────────────────────
	MISSILE LAUNCHER (T1-T5)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	Especialidad: AOE explosivo, cooldown alto
	Estrategia: Intercepta grupos de meteoritos. Mejor para oleadas densas.
────────────────────────────────────────────────────────────────────────]]

-- MISSILE T1
TurretDefinitions.MissileT1 = {
	Name = "MissileT1",
	DisplayName = "🚀 Missile Launcher T1",
	Description = "AOE explosive missiles. Intercepts meteor clusters.",
	Tier = 1,

	Size = Vector3.new(8, 10, 8),
	Color = Color3.fromRGB(100, 200, 255),  -- Azul misil
	Material = Enum.Material.Metal,

	Cost = 40000,

	Stats = {
		Damage = 80,
		AOERadius = 12,
		Cooldown = 3.0,
		Range = 80,
		TargetPriority = "Furthest",
	},

	Category = "Defense",
	TurretType = "Missile",
	IsPlaceable = true,
	CanUpgrade = true,
} :: TurretDefinition

-- MISSILE T2
TurretDefinitions.MissileT2 = {
	Name = "MissileT2",
	DisplayName = "🚀 Missile Launcher T2",
	Description = "Faster reload. Wider blast radius.",
	Tier = 2,

	Size = Vector3.new(9, 11, 9),
	Color = Color3.fromRGB(120, 210, 255),
	Material = Enum.Material.Metal,

	Cost = 150000,

	Stats = {
		Damage = 150,
		AOERadius = 15,
		Cooldown = 2.5,
		Range = 90,
		TargetPriority = "Furthest",
	},

	Category = "Defense",
	TurretType = "Missile",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- MISSILE T3
TurretDefinitions.MissileT3 = {
	Name = "MissileT3",
	DisplayName = "🚀 Missile Launcher T3",
	Description = "Cluster warheads. Devastates meteor swarms.",
	Tier = 3,

	Size = Vector3.new(10, 12, 10),
	Color = Color3.fromRGB(140, 220, 255),
	Material = Enum.Material.Metal,

	Cost = 600000,

	Stats = {
		Damage = 280,
		AOERadius = 18,
		Cooldown = 2.0,
		Range = 100,
		TargetPriority = "Furthest",
	},

	Category = "Defense",
	TurretType = "Missile",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- MISSILE T4
TurretDefinitions.MissileT4 = {
	Name = "MissileT4",
	DisplayName = "🚀 Missile Launcher T4",
	Description = "Tactical nuke missiles. Massive area denial.",
	Tier = 4,

	Size = Vector3.new(11, 13, 11),
	Color = Color3.fromRGB(160, 230, 255),
	Material = Enum.Material.Metal,

	Cost = 2500000,

	Stats = {
		Damage = 500,
		AOERadius = 22,
		Cooldown = 1.5,
		Range = 120,
		TargetPriority = "Furthest",
	},

	Category = "Defense",
	TurretType = "Missile",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- MISSILE T5
TurretDefinitions.MissileT5 = {
	Name = "MissileT5",
	DisplayName = "🚀 Missile Launcher T5 MAX",
	Description = "ICBM-class explosives. Total annihilation. MAXIMUM TIER.",
	Tier = 5,

	Size = Vector3.new(12, 14, 12),
	Color = Color3.fromRGB(180, 240, 255),
	Material = Enum.Material.Metal,

	Cost = 10000000,

	Stats = {
		Damage = 900,
		AOERadius = 25,
		Cooldown = 1.2,
		Range = 140,
		TargetPriority = "Furthest",
	},

	Category = "Defense",
	TurretType = "Missile",
	IsPlaceable = false,
	CanUpgrade = false,  -- MAX TIER
} :: TurretDefinition

--[[────────────────────────────────────────────────────────────────────────
	TESLA COIL (T1-T5)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	Especialidad: Cadena eléctrica, multi-target
	Estrategia: Late-game powerhouse. Daña múltiples meteoritos simultáneamente.
────────────────────────────────────────────────────────────────────────]]

-- TESLA T1
TurretDefinitions.TeslaT1 = {
	Name = "TeslaT1",
	DisplayName = "⚡ Tesla Coil T1",
	Description = "Chain lightning. Hits 2 targets simultaneously.",
	Tier = 1,

	Size = Vector3.new(7, 12, 7),
	Color = Color3.fromRGB(100, 100, 255),  -- Azul eléctrico
	Material = Enum.Material.Neon,

	Cost = 100000,

	Stats = {
		Damage = 35,
		MaxChains = 2,
		ChainRange = 20,
		Cooldown = 1.5,
		Range = 60,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "Tesla",
	IsPlaceable = true,
	CanUpgrade = true,
} :: TurretDefinition

-- TESLA T2
TurretDefinitions.TeslaT2 = {
	Name = "TeslaT2",
	DisplayName = "⚡ Tesla Coil T2",
	Description = "Amplified voltage. Chains to 3 targets.",
	Tier = 2,

	Size = Vector3.new(8, 13, 8),
	Color = Color3.fromRGB(120, 120, 255),
	Material = Enum.Material.Neon,

	Cost = 400000,

	Stats = {
		Damage = 70,
		MaxChains = 3,
		ChainRange = 25,
		Cooldown = 1.3,
		Range = 70,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "Tesla",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- TESLA T3
TurretDefinitions.TeslaT3 = {
	Name = "TeslaT3",
	DisplayName = "⚡ Tesla Coil T3",
	Description = "Overcharged arcs. 4-target chain reaction.",
	Tier = 3,

	Size = Vector3.new(9, 14, 9),
	Color = Color3.fromRGB(140, 140, 255),
	Material = Enum.Material.Neon,

	Cost = 1800000,

	Stats = {
		Damage = 140,
		MaxChains = 4,
		ChainRange = 30,
		Cooldown = 1.0,
		Range = 80,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "Tesla",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- TESLA T4
TurretDefinitions.TeslaT4 = {
	Name = "TeslaT4",
	DisplayName = "⚡ Tesla Coil T4",
	Description = "Plasma arcs. 5-target devastation.",
	Tier = 4,

	Size = Vector3.new(10, 15, 10),
	Color = Color3.fromRGB(160, 160, 255),
	Material = Enum.Material.Neon,

	Cost = 8000000,

	Stats = {
		Damage = 280,
		MaxChains = 5,
		ChainRange = 35,
		Cooldown = 0.8,
		Range = 90,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "Tesla",
	IsPlaceable = false,
	CanUpgrade = true,
} :: TurretDefinition

-- TESLA T5
TurretDefinitions.TeslaT5 = {
	Name = "TeslaT5",
	DisplayName = "⚡ Tesla Coil T5 MAX",
	Description = "Infinite energy coil. 6-target lightning storm. MAXIMUM TIER.",
	Tier = 5,

	Size = Vector3.new(11, 16, 11),
	Color = Color3.fromRGB(180, 180, 255),
	Material = Enum.Material.Neon,

	Cost = 35000000,

	Stats = {
		Damage = 550,
		MaxChains = 6,
		ChainRange = 40,
		Cooldown = 0.6,
		Range = 100,
		TargetPriority = "Closest",
	},

	Category = "Defense",
	TurretType = "Tesla",
	IsPlaceable = false,
	CanUpgrade = false,  -- MAX TIER
} :: TurretDefinition

--[[────────────────────────────────────────────────────────────────────────
	SHIELD DOME (Estructura especial)
	━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	Especialidad: Defensa temporal de emergencia
	Estrategia: Última defensa contra boss waves. Protege toda la base.
────────────────────────────────────────────────────────────────────────]]

TurretDefinitions.ShieldDome = {
	Name = "ShieldDome",
	DisplayName = "🛡️ Shield Dome",
	Description = "Emergency protection. Auto-activates when base HP < 30%.",
	Tier = 0,  -- Estructura especial, no tiene tiers

	Size = Vector3.new(12, 8, 12),
	Color = Color3.fromRGB(100, 200, 255),  -- Azul escudo
	Material = Enum.Material.ForceField,

	Cost = 2500000,

	Stats = {
		DomeHP = 1000,
		DomeDuration = 15,  -- 15 segundos
		DomeRadius = 50,    -- 50 studs
		Cooldown = 40,      -- 40 segundos de cooldown
		Range = 50,         -- No aplica, pero necesario para el type
		TargetPriority = "Closest",  -- No aplica
		AutoTriggerHP = 30,  -- Auto-activa cuando base HP < 30%
	},

	Category = "Defense",
	TurretType = "ShieldDome",
	IsPlaceable = true,
	CanUpgrade = false,  -- No tiene upgrades
} :: TurretDefinition

--[[────────────────────────────────────────────────────────────────────────
	HELPER FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Obtiene la definición de una torreta por nombre.

	@param turretName - Nombre de la torreta (ej: "MachineGunT1")
	@return TurretDefinition? - Definición de la torreta, o nil si no existe
]]
function TurretDefinitions.GetDefinition(turretName: string): TurretDefinition?
	return TurretDefinitions[turretName]
end

--[[
	Obtiene todas las torretas colocables (T1 de cada tipo + Shield Dome).

	@return {TurretDefinition} - Array de definiciones
]]
function TurretDefinitions.GetAllPlaceable(): {TurretDefinition}
	local placeableTurrets = {}

	for _, definition in TurretDefinitions do
		if type(definition) == "table" and definition.IsPlaceable then
			table.insert(placeableTurrets, definition)
		end
	end

	return placeableTurrets
end

--[[
	Obtiene el nombre del siguiente tier para una torreta.

	Cadenas:
	- MachineGun: MachineGunT1 → T2 → T3 → T4 → T5
	- Laser: LaserT1 → T2 → T3 → T4 → T5
	- Missile: MissileT1 → T2 → T3 → T4 → T5
	- Tesla: TeslaT1 → T2 → T3 → T4 → T5
	- ShieldDome: No tiene upgrades

	@param currentTierName - Nombre del tier actual
	@return string? - Nombre del siguiente tier, o nil si ya está en tier máximo
]]
function TurretDefinitions.GetNextTier(currentTierName: string): string?
	-- Machine Gun
	if currentTierName == "MachineGunT1" then return "MachineGunT2"
	elseif currentTierName == "MachineGunT2" then return "MachineGunT3"
	elseif currentTierName == "MachineGunT3" then return "MachineGunT4"
	elseif currentTierName == "MachineGunT4" then return "MachineGunT5"
	elseif currentTierName == "MachineGunT5" then return nil  -- MAX TIER

	-- Laser
	elseif currentTierName == "LaserT1" then return "LaserT2"
	elseif currentTierName == "LaserT2" then return "LaserT3"
	elseif currentTierName == "LaserT3" then return "LaserT4"
	elseif currentTierName == "LaserT4" then return "LaserT5"
	elseif currentTierName == "LaserT5" then return nil  -- MAX TIER

	-- Missile
	elseif currentTierName == "MissileT1" then return "MissileT2"
	elseif currentTierName == "MissileT2" then return "MissileT3"
	elseif currentTierName == "MissileT3" then return "MissileT4"
	elseif currentTierName == "MissileT4" then return "MissileT5"
	elseif currentTierName == "MissileT5" then return nil  -- MAX TIER

	-- Tesla
	elseif currentTierName == "TeslaT1" then return "TeslaT2"
	elseif currentTierName == "TeslaT2" then return "TeslaT3"
	elseif currentTierName == "TeslaT3" then return "TeslaT4"
	elseif currentTierName == "TeslaT4" then return "TeslaT5"
	elseif currentTierName == "TeslaT5" then return nil  -- MAX TIER

	-- Shield Dome (no tiene upgrades)
	elseif currentTierName == "ShieldDome" then return nil
	end

	return nil
end

--[[
	Calcula el costo de upgrade para una torreta.

	El costo es la diferencia entre el costo del siguiente tier y el tier actual.

	@param currentTierName - Nombre del tier actual
	@return number? - Costo de upgrade, o nil si no puede upgradear
]]
function TurretDefinitions.GetUpgradeCost(currentTierName: string): number?
	local nextTierName = TurretDefinitions.GetNextTier(currentTierName)
	if not nextTierName then
		return nil  -- No puede upgradear
	end

	local currentDef = TurretDefinitions.GetDefinition(currentTierName)
	local nextDef = TurretDefinitions.GetDefinition(nextTierName)

	if not currentDef or not nextDef then
		return nil
	end

	-- Costo de upgrade = diferencia entre costos
	return nextDef.Cost - currentDef.Cost
end

--[[
	Verifica si una torreta puede ser upgradeada.

	@param tierName - Nombre del tier a verificar
	@return boolean - true si puede ser upgradeada, false si ya está en tier máximo
]]
function TurretDefinitions.CanUpgrade(tierName: string): boolean
	local definition = TurretDefinitions.GetDefinition(tierName)
	if not definition then
		return false
	end
	return definition.CanUpgrade
end

--[[
	Crea un modelo físico 3D basado en la definición de torreta.

	NOTA: Por ahora usa geometría simple. En el futuro esto podría cargar
	meshes o modelos de ServerStorage.

	@param turretName - Nombre de la torreta
	@return Model? - Modelo creado, o nil si no existe la definición
]]
function TurretDefinitions.CreateModel(turretName: string): Model?
	local definition = TurretDefinitions.GetDefinition(turretName)
	if not definition then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = definition.Name

	-- Crear parte principal
	local mainPart = Instance.new("Part")
	mainPart.Name = "MainPart"
	mainPart.Size = definition.Size
	mainPart.Color = definition.Color
	mainPart.Material = definition.Material
	mainPart.Anchored = true
	mainPart.CanCollide = true
	mainPart.Parent = model

	-- Agregar highlight para mejor visibilidad
	local highlight = Instance.new("Highlight")
	highlight.FillColor = definition.Color
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.8
	highlight.Parent = mainPart

	-- Agregar BillboardGui con nombre
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, definition.Size.Y / 2 + 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = mainPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = definition.DisplayName
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	-- Agregar ProximityPrompt para upgrade (solo si puede upgradear)
	if definition.CanUpgrade then
		local upgradePrompt = Instance.new("ProximityPrompt")
		upgradePrompt.Name = "UpgradePrompt"
		upgradePrompt.ActionText = "Upgrade to Next Tier"
		upgradePrompt.ObjectText = definition.DisplayName
		upgradePrompt.RequiresLineOfSight = false
		upgradePrompt.MaxActivationDistance = 10
		upgradePrompt.HoldDuration = 0.5  -- Requiere hold para prevenir clicks accidentales
		upgradePrompt.Parent = mainPart
	end

	-- Agregar ProximityPrompt para stats (siempre)
	local statsPrompt = Instance.new("ProximityPrompt")
	statsPrompt.Name = "StatsPrompt"
	statsPrompt.ActionText = "View Stats"
	statsPrompt.ObjectText = definition.DisplayName
	statsPrompt.RequiresLineOfSight = false
	statsPrompt.MaxActivationDistance = 10
	statsPrompt.KeyboardKeyCode = Enum.KeyCode.E  -- Tecla E para ver stats
	statsPrompt.Parent = mainPart

	-- PrimaryPart
	model.PrimaryPart = mainPart

	return model
end

--[[
	Obtiene el tipo base de una torreta (sin el tier).

	@param turretName - Nombre completo (ej: "MachineGunT3")
	@return string? - Tipo base (ej: "MachineGun"), o nil si no se reconoce
]]
function TurretDefinitions.GetBaseType(turretName: string): string?
	if string.match(turretName, "^MachineGun") then
		return "MachineGun"
	elseif string.match(turretName, "^Laser") then
		return "Laser"
	elseif string.match(turretName, "^Missile") then
		return "Missile"
	elseif string.match(turretName, "^Tesla") then
		return "Tesla"
	elseif turretName == "ShieldDome" then
		return "ShieldDome"
	end
	return nil
end

return TurretDefinitions
