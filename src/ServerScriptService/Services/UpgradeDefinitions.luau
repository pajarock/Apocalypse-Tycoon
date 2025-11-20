--!strict
--[[
	UpgradeDefinitions - Stats y configuración de todos los upgrades

	Define las propiedades de cada tipo de upgrade:
	- Visual (modelo, tamaño, color)
	- Stats (producción, daño, capacidad)
	- Costos (dinero para colocar)
	- Comportamiento (funcionalidad específica)

	UPGRADES DISPONIBLES:
	1. Generator (T1) - Produce $5/s pasivamente
	2. GeneratorT2 (T2) - Produce $15/s pasivamente (meteórico)
	3. GeneratorT3 (T3) - Produce $50/s pasivamente (avanzado)
	4. Turret - Dispara a meteoros/enemigos
	5. Storage - Aumenta capacidad de dinero
	6. RepairStation - Estación física para reparar base (mobile-friendly)
]]

export type UpgradeDefinition = {
	-- Identificación
	Name: string,
	DisplayName: string,
	Description: string,

	-- Visual
	Size: Vector3,
	Color: Color3,
	Material: Enum.Material,

	-- Económico
	Cost: number,

	-- Stats (varía por tipo)
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

--[[────────────────────────────────────────────────────────────────────────
	UPGRADE DEFINITIONS
────────────────────────────────────────────────────────────────────────]]

local UpgradeDefinitions = {}

-- GENERATOR - Produce dinero pasivamente
UpgradeDefinitions.Generator = {
	Name = "Generator",
	DisplayName = "💰 Generator",
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

-- GENERATOR TIER 2 - Meteórico (Producción media)
UpgradeDefinitions.GeneratorT2 = {
	Name = "GeneratorT2",
	DisplayName = "⚡ Generator Meteórico",
	Description = "Advanced generator with crystal-powered production",

	Size = Vector3.new(10, 8, 10),  -- Más grande que T1
	Color = Color3.fromRGB(150, 50, 200),  -- Púrpura
	Material = Enum.Material.Neon,

	Cost = 500,  -- 5x más caro que T1

	Stats = {
		MoneyPerSecond = 15,  -- 3x producción de T1
	},

	Category = "Production",
	IsPlaceable = true,
} :: UpgradeDefinition

-- GENERATOR TIER 3 - Avanzado (Producción alta)
UpgradeDefinitions.GeneratorT3 = {
	Name = "GeneratorT3",
	DisplayName = "🔮 Generator Avanzado",
	Description = "Elite energy generator with maximum efficiency",

	Size = Vector3.new(12, 10, 12),  -- Más grande que T2
	Color = Color3.fromRGB(0, 255, 255),  -- Cyan brillante
	Material = Enum.Material.Neon,

	Cost = 2000,  -- 20x más caro que T1

	Stats = {
		MoneyPerSecond = 50,  -- 10x producción de T1
	},

	Category = "Production",
	IsPlaceable = true,
} :: UpgradeDefinition

-- TURRET - Dispara a meteoros/enemigos
UpgradeDefinitions.Turret = {
	Name = "Turret",
	DisplayName = "🔫 Turret",
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
	DisplayName = "📦 Storage",
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

-- REPAIR STATION - Estación física para reparar (mobile-friendly)
UpgradeDefinitions.RepairStation = {
	Name = "RepairStation",
	DisplayName = "🔧 Repair Station",
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
	HELPER FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Obtiene la definición de un upgrade por nombre.

	@param upgradeName - Nombre del upgrade (ej: "Generator")
	@return UpgradeDefinition? - Definición del upgrade, o nil si no existe
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
	Crea un modelo físico 3D basado en la definición.

	NOTA: Por ahora usa geometría simple (cubos). En el futuro
	esto podría cargar meshes o modelos de ServerStorage.

	@param upgradeName - Nombre del upgrade
	@return Model? - Modelo creado, o nil si no existe la definición
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

return UpgradeDefinitions
