--!strict
--[[
	UPGRADES.LUA - Apocalypse Tycoon
	Define todos los upgrades disponibles para comprar
	
	VERSIÓN: 2.0
	MEJORAS:
	- Campo IncomePerSec corregido (era IncomeDelta)
	- Más upgrades (10 total)
	- Descripciones para UI
	- Balance mejorado
	- Categorías por tipo
--]]

export type UpgradeDef = {
	Title: string,           -- Nombre mostrado en UI
	Description: string,     -- Descripción para tooltip
	BasePrice: number,       -- Precio inicial
	PriceGrowth: number,     -- Multiplicador de precio (era PriceMul)
	IncomePerSec: number,    -- 🔧 CORREGIDO: era IncomeDelta
	ModelName: string?,      -- Nombre del modelo en ServerStorage.Models
	Repeatable: boolean,     -- Si se puede comprar múltiples veces
	MaxCount: number?,       -- Límite de compras (nil = infinito)
	Category: string?,       -- Para organizar UI (Income, Defense, Utility)
}

local Upgrades: {[string]: UpgradeDef} = {

	--═══════════════════════════════════════════════════════════════════════
	-- 💰 GENERADORES DE INCOME (Early Game)
	--═══════════════════════════════════════════════════════════════════════
	Upgrade_1 = {
		Title = "Solar Panel",
		Description = "Genera energía del sol. +1$/s",
		BasePrice = 50,
		PriceGrowth = 5,
		IncomePerSec = 1,
		ModelName = "GeneratorMk1",
		Repeatable = true,
		MaxCount = nil,
		Category = "Income",
	},

	Upgrade_2 = {
		Title = "Wind Turbine",
		Description = "Aprovecha el viento apocalíptico. +3$/s",
		BasePrice = 150,
		PriceGrowth = 5,
		IncomePerSec = 3,
		ModelName = "GeneratorMk1",  -- Usa mismo modelo por ahora
		Repeatable = true,
		MaxCount = nil,
		Category = "Income",
	},

	Upgrade_3 = {
		Title = "Miner Drill",
		Description = "Extrae minerales del subsuelo. +8$/s",
		BasePrice = 3000,
		PriceGrowth = 2,
		IncomePerSec = 8,
		ModelName = "MinerDrill",
		Repeatable = true,
		MaxCount = nil,
		Category = "Income",
	},

	Upgrade_4 = {
		Title = "Water Purifier",
		Description = "Agua limpia es oro en el apocalipsis. +20$/s",
		BasePrice = 50000,
		PriceGrowth = 3,
		IncomePerSec = 20,
		ModelName = "WaterPump",
		Repeatable = true,
		MaxCount = nil,
		Category = "Income",
	},

	Upgrade_5 = {
		Title = "Scrap Recycler",
		Description = "Convierte basura en recursos. +50$/s",
		BasePrice = 8000,
		PriceGrowth = 1.28,
		IncomePerSec = 50,
		ModelName = "MinerDrill",  -- Placeholder
		Repeatable = true,
		MaxCount = nil,
		Category = "Income",
	},

	--═══════════════════════════════════════════════════════════════════════
	-- 🛡️ DEFENSA
	--═══════════════════════════════════════════════════════════════════════
	Upgrade_6 = {
		Title = "Shield Generator Mk1",
		Description = "Reduce daño recibido en 20%",
		BasePrice = 500000,
		PriceGrowth = 5.0,  -- Muy caro escalar
		IncomePerSec = 0,
		ModelName = "ShieldEmitter",
		Repeatable = true,
		MaxCount = 3,  -- Máximo 3 niveles = 60% reducción
		Category = "Defense",
	},
	Upgrade_7 = {
		Title = "Wall Section",  -- Ya no "Reinforced Walls"
		Description = "Construye un segmento de muro (+5 HP max)",
		BasePrice = 2000,
		PriceGrowth = 1.50,  -- Crece poco para comprar muchas
		IncomePerSec = 0,
		ModelName = "WallSection",  -- Nuevo modelo
		Repeatable = true,
		MaxCount = 20,  -- Hasta 20 secciones
		Category = "Defense",
	},
	Upgrade_8 = {
		Title = "Reinforced Walls",
		Description = "Aumenta HP máximo de la base en +20",
		BasePrice = 1000000,
		PriceGrowth = 3,
		IncomePerSec = 0,
		ModelName = "ReinforcedWalls", 
		Repeatable = true,
		MaxCount = 5,  -- +100 HP máximo
		Category = "Defense",
	},

	--═══════════════════════════════════════════════════════════════════════
	-- ⚙️ UTILIDADES (Mid-Late Game)
	--═══════════════════════════════════════════════════════════════════════
	Upgrade_11 = { -- ✅ FIX: Cambiado de Upgrade_8 duplicado a Upgrade_11
		Title = "Auto-Repair System",
		Description = "Repara base automáticamente. +2 HP/s",
		BasePrice = 2000000,
		PriceGrowth = 1.5,
		IncomePerSec = 0,
		ModelName = nil,
		Repeatable = true,
		MaxCount = 3,
		Category = "Utility",
	},

	Upgrade_9 = {
		Title = "Nuclear Reactor",
		Description = "Poder masivo pero peligroso. +150$/s",
		BasePrice = 2000000,
		PriceGrowth = 1.4,
		IncomePerSec = 150,
		ModelName = "GeneratorMk1",  -- Placeholder
		Repeatable = true,
		MaxCount = nil,
		Category = "Income",
	},

	Upgrade_10 = {
		Title = "Meteor Detector",
		Description = "Alerta 15s antes de impacto",
		BasePrice = 300000,
		PriceGrowth = 1.0,  -- No crece (solo 1 compra)
		IncomePerSec = 0,
		ModelName = nil,
		Repeatable = false,
		MaxCount = 1,
		Category = "Utility",
	},

	--═══════════════════════════════════════════════════════════════════════
	-- 🥚 PETS / COMPAÑEROS (Preparado para futuro)
	--═══════════════════════════════════════════════════════════════════════
	Upgrade_12 = {
		Title = "Pet Egg (Basic)",
		Description = "Huevo de mascota básica - ¡PRÓXIMAMENTE!",
		BasePrice = 100000,
		PriceGrowth = 1.25,
		IncomePerSec = 0,
		ModelName = nil,
		Repeatable = true,
		MaxCount = 5,
		Category = "Pets",
	},
}

return Upgrades