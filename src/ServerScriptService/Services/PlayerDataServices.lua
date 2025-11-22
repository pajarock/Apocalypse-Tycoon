--!strict
--[[
	PlayerDataService - Wrapper para integrar EconomyModule con Knit

	PROPÓSITO:
	- Actuar como puente entre el sistema Knit (nuevo) y EconomyModule (legacy)
	- Exponer API limpia de economía para otros servicios Knit
	- Permitir migración gradual sin romper funcionalidad existente

	ARQUITECTURA:
	- Knit Service (servidor-side)
	- Wrapper del EconomyModule legacy
	- Preserva toda la funcionalidad del sistema de economía original

	MÉTODOS PRINCIPALES:
	- AddMoney(userId, amount) - Usado por generadores
	- GetMoney(userId) - Consultar dinero actual
	- GetState(userId) - Estado completo del jugador
	- Purchase(userId, upgradeId) - Comprar upgrade (legacy)

	INTEGRACIÓN:
	- UpgradeService lo usa para dar dinero de generators
	- Futuras features pueden usar esta API limpia
	- Mantiene compatibilidad con sistema legacy existente
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Knit)

-- Importar EconomyModule legacy
local EconomyModule = require(ServerScriptService.EconomyModule)

--[[------------------------------------------------------------------------
	SERVICE DEFINITION
------------------------------------------------------------------------]]

local PlayerDataService = Knit.CreateService({
	Name = "PlayerDataService",
})

--[[------------------------------------------------------------------------
	MONEY OPERATIONS
------------------------------------------------------------------------]]

--[[
	Agrega dinero a un jugador (usado por generators, rewards, etc.)

	@param userId - ID del jugador
	@param amount - Cantidad de dinero a agregar (puede ser decimal)
	@return success - Si la operación fue exitosa
]]
function PlayerDataService:AddMoney(userId: number, amount: number): boolean
	if type(userId) ~= "number" or userId <= 0 then
		warn(string.format("[PlayerDataService] Invalid userId: %s", tostring(userId)))
		return false
	end

	if type(amount) ~= "number" or amount == 0 then
		warn(string.format("[PlayerDataService] Invalid amount: %s", tostring(amount)))
		return false
	end

	-- Usar AdminGiveCash del EconomyModule (acepta negativos para deducir)
	local success = EconomyModule.AdminGiveCash(userId, amount)

	if success then
		-- Debug opcional (comentar en producción para reducir spam)
		-- print(string.format("[PlayerDataService] ?? Added $%.2f to userId=%d", amount, userId))
		return true
	else
		warn(string.format("[PlayerDataService] Failed to add money to userId=%d (player not initialized?)", userId))
		return false
	end
end

--[[
	Obtiene el dinero actual de un jugador.

	@param userId - ID del jugador
	@return money - Cantidad de dinero (o 0 si no existe)
]]
function PlayerDataService:GetMoney(userId: number): number
	local state = EconomyModule.GetState(userId)
	if not state then
		return 0
	end

	return state.Cash or 0
end

--[[
	Obtiene el estado completo de economía de un jugador.

	@param userId - ID del jugador
	@return state - Estado completo (Cash, IncomePerSec, OwnedUpgrades, etc.)
]]
function PlayerDataService:GetState(userId: number)
	return EconomyModule.GetState(userId)
end

--[[
	Obtiene el ingreso por segundo actual de un jugador.

	@param userId - ID del jugador
	@return incomePerSec - Dinero generado por segundo
]]
function PlayerDataService:GetIncomePerSecond(userId: number): number
	local state = EconomyModule.GetState(userId)
	if not state then
		return 0
	end

	return state.IncomePerSec or 0
end

--[[------------------------------------------------------------------------
	PURCHASE OPERATIONS (Wrapper para legacy upgrades)
------------------------------------------------------------------------]]

--[[
	Compra un upgrade usando el sistema legacy.

	NOTA: Este método está aquí para compatibilidad con upgrades legacy.
	Los nuevos upgrades de Knit (BaseOwnershipService) NO usan esto.

	@param userId - ID del jugador
	@param upgradeId - ID del upgrade a comprar
	@return success - Si la compra fue exitosa
	@return error - Código de error si falló
]]
function PlayerDataService:PurchaseLegacyUpgrade(userId: number, upgradeId: string): (boolean, string?)
	return EconomyModule.Purchase(userId, upgradeId)
end

--[[
	Obtiene el precio actual de un upgrade legacy.

	@param userId - ID del jugador
	@param upgradeId - ID del upgrade
	@return price - Precio actual
]]
function PlayerDataService:GetLegacyUpgradePrice(userId: number, upgradeId: string): number
	return EconomyModule.GetCurrentPrice(userId, upgradeId)
end

--[[------------------------------------------------------------------------
	PLAYER INITIALIZATION (Wrapper)
------------------------------------------------------------------------]]

--[[
	Inicializa la economía de un jugador.

	NOTA: Esto normalmente lo hace el Main.Server.lua legacy.
	Solo usar si sabes lo que estás haciendo.

	@param userId - ID del jugador
	@param blob - Datos guardados (opcional)
]]
function PlayerDataService:InitPlayer(userId: number, blob: any?)
	EconomyModule.InitPlayer(userId, blob)
	print(string.format("[PlayerDataService] ?? Player initialized: userId=%d", userId))
end

--[[------------------------------------------------------------------------
	UTILITY FUNCTIONS
------------------------------------------------------------------------]]

--[[
	Verifica si un jugador tiene suficiente dinero.

	@param userId - ID del jugador
	@param amount - Cantidad requerida
	@return hasEnough - Si tiene suficiente dinero
]]
function PlayerDataService:HasEnoughMoney(userId: number, amount: number): boolean
	local currentMoney = self:GetMoney(userId)
	return currentMoney >= amount
end

--[[
	Intenta deducir dinero de un jugador.

	ADVERTENCIA: Esto modifica el cash directamente. Úsalo con cuidado.
	Para compras, usa PurchaseLegacyUpgrade() que maneja validación.

	@param userId - ID del jugador
	@param amount - Cantidad a deducir
	@return success - Si la operación fue exitosa
]]
function PlayerDataService:DeductMoney(userId: number, amount: number): boolean
	if not self:HasEnoughMoney(userId, amount) then
		return false
	end

	-- Deducir usando AddMoney con valor negativo
	return self:AddMoney(userId, -amount)
end

--[[------------------------------------------------------------------------
	LIFECYCLE HOOKS
------------------------------------------------------------------------]]

function PlayerDataService:KnitInit()
	print("[PlayerDataService] ?? Initialized (EconomyModule wrapper)")
end

function PlayerDataService:KnitStart()
	print("[PlayerDataService] ? Started - Ready to process money operations")
	print("[PlayerDataService] ?? Connected to EconomyModule (legacy)")

	-- Verificar que EconomyModule esté cargado
	if not EconomyModule then
		error("[PlayerDataService] ? CRITICAL: EconomyModule not found!")
	end

	-- Mostrar info sobre el módulo de economía
	local metrics = EconomyModule.GetMetrics()
	if metrics then
		print(string.format(
			"[PlayerDataService] ?? EconomyModule stats: Purchases=%d, Ticks=%d",
			metrics.totalPurchases or 0,
			metrics.totalTicks or 0
			))
	end
end

return PlayerDataService