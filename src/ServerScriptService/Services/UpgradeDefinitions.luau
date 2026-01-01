--!strict
--[[
	UpgradeDefinitions - Stats y configuraci�n de todos los upgrades

	Define las propiedades de cada tipo de upgrade:
	- Visual (modelo, tama�o, color)
	- Stats (producci�n, da�o, capacidad)
	- Costos (dinero para colocar)
	- Comportamiento (funcionalidad espec�fica)

	UPGRADES DISPONIBLES:
	1. Generator (T1) - Produce $5/s pasivamente
	2. GeneratorT2 (T2) - Produce $15/s pasivamente (mete�rico)
	3. GeneratorT3 (T3) - Produce $50/s pasivamente (avanzado)
	4. Turret - Dispara a meteoros/enemigos
	5. Storage - Aumenta capacidad de dinero
	6. RepairStation - Estaci�n f�sica para reparar base (mobile-friendly)
]]

export type UpgradeDefinition = {
	-- Identificaci�n
	Name: string,
	DisplayName: string,
	Description: string,

	-- Visual
	Size: Vector3,
	Color: Color3,
	Material: Enum.Material,

	-- Econ�mico
	Cost: number,

	-- Stats (var�a por tipo)
	Stats: {
		-- Generator
		MoneyPerSecond: number?,

		-- Turret
		Damage: number?,
		Range: number?,
		FireRate: number?,

		-- Storage
		Capacity: number?,

		-- RepairStation
		RepairAmount: number?,
		RepairCost: number?,
	},

	-- Comportamiento
	Category: "Production" | "Defense" | "Utility",
	IsPlaceable: boolean,
}

--[[------------------------------------------------------------------------
	UPGRADE DEFINITIONS
------------------------------------------------------------------------]]

local UpgradeDefinitions = {}

-- GENERATOR - Produce dinero pasivamente
UpgradeDefinitions.Generator = {
	Name = "Generator",
	DisplayName = "?? Generator",
	Description = "Produces money passively over time",

	Size = Vector3.new(8, 6, 8),
	Color = Color3.fromRGB(255, 215, 0),  -- Gold
	Material = Enum.Material.Neon,

	Cost = 100,

	Stats = {
		MoneyPerSecond = 5,  -- Produce $5 por segundo
	},

	Category = "Production",
	IsPlaceable = true,
} :: UpgradeDefinition

-- GENERATOR TIER 2 - Mete�rico (Producci�n media)
UpgradeDefinitions.GeneratorT2 = {
	Name = "GeneratorT2",
	DisplayName = "? Generator Mete�rico",
	Description = "Advanced generator with crystal-powered production",

	Size = Vector3.new(10, 8, 10),  -- M�s grande que T1
	Color = Color3.fromRGB(150, 50, 200),  -- P�rpura
	Material = Enum.Material.Neon,

	Cost = 200,  -- T1 ($100) + upgrade cost ($100)

	Stats = {
		MoneyPerSecond = 15,  -- 3x producci�n de T1
	},

	Category = "Production",
	IsPlaceable = false,  -- Solo accesible via upgrade desde T1
} :: UpgradeDefinition

-- GENERATOR TIER 3 - Avanzado (Producci�n alta)
UpgradeDefinitions.GeneratorT3 = {
	Name = "GeneratorT3",
	DisplayName = "?? Generator Avanzado",
	Description = "Elite energy generator with maximum efficiency",

	Size = Vector3.new(12, 10, 12),  -- M�s grande que T2
	Color = Color3.fromRGB(0, 255, 255),  -- Cyan brillante
	Material = Enum.Material.Neon,

	Cost = 500,  -- T2 ($200) + upgrade cost ($300)

	Stats = {
		MoneyPerSecond = 50,  -- 10x producci�n de T1
	},

	Category = "Production",
	IsPlaceable = false,  -- Solo accesible via upgrade desde T2
} :: UpgradeDefinition

-- GENERATOR TIER 4 - Nuclear (Producción muy alta)
UpgradeDefinitions.GeneratorT4 = {
	Name = "GeneratorT4",
	DisplayName = "☢️ Generator Nuclear",
	Description = "Radioactive reactor with extreme power output",

	Size = Vector3.new(14, 12, 14),  -- Más grande que T3
	Color = Color3.fromRGB(0, 255, 65),  -- Verde neón radiactivo
	Material = Enum.Material.Neon,

	Cost = 1500,  -- T3 ($500) + upgrade cost ($1,000)

	Stats = {
		MoneyPerSecond = 150,  -- 30x producción de T1, 3x de T3
	},

	Category = "Production",
	IsPlaceable = false,  -- Solo accesible via upgrade
} :: UpgradeDefinition

-- GENERATOR TIER 5 - Quantum (Producción máxima - TIER FINAL)
UpgradeDefinitions.GeneratorT5 = {
	Name = "GeneratorT5",
	DisplayName = "⭐ Generator Quantum",
	Description = "Ultimate cosmic energy generator - MAX TIER",

	Size = Vector3.new(16, 14, 16),  -- Más grande que T4
	Color = Color3.fromRGB(255, 255, 255),  -- Blanco brillante
	Material = Enum.Material.Neon,

	Cost = 6500,  -- T4 ($1,500) + upgrade cost ($5,000)

	Stats = {
		MoneyPerSecond = 500,  -- 100x producción de T1, 10x de T3
	},

	Category = "Production",
	IsPlaceable = false,  -- Solo accesible via upgrade
} :: UpgradeDefinition

-- TURRET - Dispara a meteoros/enemigos
UpgradeDefinitions.Turret = {
	Name = "Turret",
	DisplayName = "?? Turret",
	Description = "Shoots meteors and enemies automatically",

	Size = Vector3.new(6, 8, 6),
	Color = Color3.fromRGB(255, 50, 50),  -- Red
	Material = Enum.Material.Metal,

	Cost = 150,

	Stats = {
		Damage = 10,
		Range = 50,  -- 50 studs de alcance
		FireRate = 1,  -- 1 disparo por segundo
	},

	Category = "Defense",
	IsPlaceable = true,
} :: UpgradeDefinition

-- STORAGE - Aumenta capacidad de dinero
UpgradeDefinitions.Storage = {
	Name = "Storage",
	DisplayName = "?? Storage",
	Description = "Increases your money storage capacity",

	Size = Vector3.new(10, 8, 10),
	Color = Color3.fromRGB(100, 150, 255),  -- Blue
	Material = Enum.Material.SmoothPlastic,

	Cost = 75,

	Stats = {
		Capacity = 1000,  -- +$1000 de capacidad
	},

	Category = "Utility",
	IsPlaceable = true,
} :: UpgradeDefinition

-- REPAIR STATION - Estaci�n f�sica para reparar (mobile-friendly)
UpgradeDefinitions.RepairStation = {
	Name = "RepairStation",
	DisplayName = "?? Repair Station",
	Description = "Interact to repair your base (mobile-friendly)",

	Size = Vector3.new(8, 6, 8),
	Color = Color3.fromRGB(100, 255, 100),  -- Green
	Material = Enum.Material.Neon,

	Cost = 50,

	Stats = {
		RepairAmount = 100,  -- Repara 100 HP
		RepairCost = 25,  -- Cuesta $25 reparar
	},

	Category = "Utility",
	IsPlaceable = true,
} :: UpgradeDefinition

--[[────────────────────────────────────────────────────────────────────────
	DEFENSE TOWERS (NEW SYSTEM - TIER 1 PLACEABLE)
────────────────────────────────────────────────────────────────────────]]

-- MACHINE GUN T1 - Entry-level rapid-fire turret
UpgradeDefinitions.MachineGunT1 = {
	Name = "MachineGunT1",
	DisplayName = "Machine Gun T1",
	Description = "Rapid-fire turret. Best value for early defense.",

	Size = Vector3.new(6, 8, 6),
	Color = Color3.fromRGB(100, 100, 120),
	Material = Enum.Material.Metal,

	Cost = 5000,

	Stats = {
		Damage = 8,
		Range = 50,
		FireRate = 0.25,
	},

	Category = "Defense",
	IsPlaceable = true,
} :: UpgradeDefinition

-- LASER TURRET T1 - Continuous beam weapon
UpgradeDefinitions.LaserT1 = {
	Name = "LaserT1",
	DisplayName = "Laser Turret T1",
	Description = "Continuous beam weapon. Effective vs Large meteors.",

	Size = Vector3.new(6, 10, 6),
	Color = Color3.fromRGB(255, 50, 50),
	Material = Enum.Material.Neon,

	Cost = 15000,

	Stats = {
		DPS = 25,
		Range = 70,
		FireRate = 0.1,  -- Beam continuo, pero para compatibilidad
	},

	Category = "Defense",
	IsPlaceable = true,
} :: UpgradeDefinition

-- MISSILE LAUNCHER T1 - AOE explosive missiles
UpgradeDefinitions.MissileT1 = {
	Name = "MissileT1",
	DisplayName = "Missile Launcher T1",
	Description = "AOE explosive missiles. Intercepts meteor clusters.",

	Size = Vector3.new(8, 10, 8),
	Color = Color3.fromRGB(100, 200, 255),
	Material = Enum.Material.Metal,

	Cost = 40000,

	Stats = {
		Damage = 80,
		Range = 80,
		FireRate = 3.0,
		AOERadius = 12,
	},

	Category = "Defense",
	IsPlaceable = true,
} :: UpgradeDefinition

-- TESLA COIL T1 - Chain lightning
UpgradeDefinitions.TeslaT1 = {
	Name = "TeslaT1",
	DisplayName = "Tesla Coil T1",
	Description = "Chain lightning. Hits 2 targets simultaneously.",

	Size = Vector3.new(7, 12, 7),
	Color = Color3.fromRGB(100, 100, 255),
	Material = Enum.Material.Neon,

	Cost = 100000,

	Stats = {
		Damage = 35,
		Range = 60,
		FireRate = 1.5,
		MaxChains = 2,
		ChainRange = 20,
	},

	Category = "Defense",
	IsPlaceable = true,
} :: UpgradeDefinition

-- SHIELD DOME - Emergency protection structure
UpgradeDefinitions.ShieldDome = {
	Name = "ShieldDome",
	DisplayName = "Shield Dome",
	Description = "Emergency protection. Auto-activates when base HP < 30%.",

	Size = Vector3.new(12, 8, 12),
	Color = Color3.fromRGB(100, 200, 255),
	Material = Enum.Material.ForceField,

	Cost = 2500000,

	Stats = {
		DomeHP = 1000,
		Range = 50,  -- Radio del domo
		FireRate = 40,  -- Cooldown (reutilizamos FireRate para compatibilidad)
	},

	Category = "Defense",
	IsPlaceable = true,
} :: UpgradeDefinition

--[[------------------------------------------------------------------------
	HELPER FUNCTIONS
------------------------------------------------------------------------]]

--[[
	Obtiene la definici�n de un upgrade por nombre.

	@param upgradeName - Nombre del upgrade (ej: "Generator")
	@return UpgradeDefinition? - Definici�n del upgrade, o nil si no existe
]]
function UpgradeDefinitions.GetDefinition(upgradeName: string): UpgradeDefinition?
	return UpgradeDefinitions[upgradeName]
end

--[[
	Obtiene todas las definiciones de upgrades colocables.

	@return {UpgradeDefinition} - Array de definiciones
]]
function UpgradeDefinitions.GetAllPlaceable(): {UpgradeDefinition}
	local placeableUpgrades = {}

	for _, definition in UpgradeDefinitions do
		if type(definition) == "table" and definition.IsPlaceable then
			table.insert(placeableUpgrades, definition)
		end
	end

	return placeableUpgrades
end

--[[
	Crea un modelo f�sico 3D basado en la definici�n.

	NOTA: Por ahora usa geometr�a simple (cubos). En el futuro
	esto podr�a cargar meshes o modelos de ServerStorage.

	@param upgradeName - Nombre del upgrade
	@return Model? - Modelo creado, o nil si no existe la definici�n
]]
function UpgradeDefinitions.CreateModel(upgradeName: string): Model?
	local definition = UpgradeDefinitions.GetDefinition(upgradeName)
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
	billboard.Size = UDim2.new(0, 100, 0, 40)
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

	-- Para RepairStation, agregar ProximityPrompt
	if upgradeName == "RepairStation" then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "RepairPrompt"
		prompt.ActionText = "Repair Base"
		prompt.ObjectText = "Repair Station"
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 10
		prompt.Parent = mainPart
	end

	-- PrimaryPart
	model.PrimaryPart = mainPart

	return model
end

--[[────────────────────────────────────────────────────────────────────────
	PHASE 4: GENERATOR UPGRADE SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Obtiene el nombre del siguiente tier para un generador.

	Cadena: Generator → GeneratorT2 → GeneratorT3 → GeneratorT4 → GeneratorT5

	@param currentTierName - Nombre del tier actual
	@return string? - Nombre del siguiente tier, o nil si ya está en tier máximo
]]
function UpgradeDefinitions.GetNextTier(currentTierName: string): string?
	if currentTierName == "Generator" then
		return "GeneratorT2"
	elseif currentTierName == "GeneratorT2" then
		return "GeneratorT3"
	elseif currentTierName == "GeneratorT3" then
		return "GeneratorT4"
	elseif currentTierName == "GeneratorT4" then
		return "GeneratorT5"
	elseif currentTierName == "GeneratorT5" then
		return nil  -- Ya está en tier máximo (Quantum)
	end

	return nil
end

--[[
	Calcula el costo de upgrade para un generador.

	El costo es la diferencia entre el costo del siguiente tier y el tier actual.
	Por ejemplo: T1→T2 cuesta $400 ($500 - $100)

	@param currentTierName - Nombre del tier actual
	@return number? - Costo de upgrade, o nil si no puede upgradear
]]
function UpgradeDefinitions.GetUpgradeCost(currentTierName: string): number?
	local nextTierName = UpgradeDefinitions.GetNextTier(currentTierName)
	if not nextTierName then
		return nil  -- No puede upgradear
	end

	local currentDef = UpgradeDefinitions.GetDefinition(currentTierName)
	local nextDef = UpgradeDefinitions.GetDefinition(nextTierName)

	if not currentDef or not nextDef then
		return nil
	end

	-- Costo de upgrade = diferencia entre costos
	return nextDef.Cost - currentDef.Cost
end

--[[
	Verifica si un generador puede ser upgradeado.

	@param tierName - Nombre del tier a verificar
	@return boolean - true si puede ser upgradeado, false si ya está en tier máximo
]]
function UpgradeDefinitions.CanUpgrade(tierName: string): boolean
	return UpgradeDefinitions.GetNextTier(tierName) ~= nil
end

return UpgradeDefinitions
