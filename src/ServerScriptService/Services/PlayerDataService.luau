--!strict
--[[
	PlayerDataService - Wrapper para integrar EconomyModule con Knit

	PROPÃSITO:
	- Actuar como puente entre el sistema Knit (nuevo) y EconomyModule (legacy)
	- Exponer API limpia de economÃ­a para otros servicios Knit
	- Permitir migraciÃ³n gradual sin romper funcionalidad existente

	ARQUITECTURA:
	- Knit Service (servidor-side)
	- Wrapper del EconomyModule legacy
	- Preserva toda la funcionalidad del sistema de economÃ­a original

	MÃTODOS PRINCIPALES:
	- AddMoney(userId, amount) - Usado por generadores
	- GetMoney(userId) - Consultar dinero actual
	- GetState(userId) - Estado completo del jugador
	- Purchase(userId, upgradeId) - Comprar upgrade (legacy)

	INTEGRACIÃN:
	- UpgradeService lo usa para dar dinero de generators
	- Futuras features pueden usar esta API limpia
	- Mantiene compatibilidad con sistema legacy existente
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Knit)

-- Importar EconomyModule legacy
local EconomyModule = require(ServerScriptService.EconomyModule)

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	SERVICE DEFINITION
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

local PlayerDataService = Knit.CreateService({
	Name = "PlayerDataService",
})

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	MONEY OPERATIONS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Agrega dinero a un jugador (usado por generators, rewards, etc.)

	@param userId - ID del jugador
	@param amount - Cantidad de dinero a agregar (puede ser decimal)
	@return success - Si la operaciÃ³n fue exitosa
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
		-- Debug opcional (comentar en producciÃ³n para reducir spam)
		-- print(string.format("[PlayerDataService] ð° Added $%.2f to userId=%d", amount, userId))
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
	Obtiene el estado completo de economÃ­a de un jugador.

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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	PURCHASE OPERATIONS (Wrapper para legacy upgrades)
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Compra un upgrade usando el sistema legacy.

	NOTA: Este mÃ©todo estÃ¡ aquÃ­ para compatibilidad con upgrades legacy.
	Los nuevos upgrades de Knit (BaseOwnershipService) NO usan esto.

	@param userId - ID del jugador
	@param upgradeId - ID del upgrade a comprar
	@return success - Si la compra fue exitosa
	@return error - CÃ³digo de error si fallÃ³
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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	PLAYER INITIALIZATION (Wrapper)
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Inicializa la economÃ­a de un jugador.

	NOTA: Esto normalmente lo hace el Main.Server.lua legacy.
	Solo usar si sabes lo que estÃ¡s haciendo.

	@param userId - ID del jugador
	@param blob - Datos guardados (opcional)
]]
function PlayerDataService:InitPlayer(userId: number, blob: any?)
	EconomyModule.InitPlayer(userId, blob)
	print(string.format("[PlayerDataService] ð® Player initialized: userId=%d", userId))
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	UTILITY FUNCTIONS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

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

	ADVERTENCIA: Esto modifica el cash directamente. Ãsalo con cuidado.
	Para compras, usa PurchaseLegacyUpgrade() que maneja validaciÃ³n.

	@param userId - ID del jugador
	@param amount - Cantidad a deducir
	@return success - Si la operaciÃ³n fue exitosa
]]
function PlayerDataService:DeductMoney(userId: number, amount: number): boolean
	if not self:HasEnoughMoney(userId, amount) then
		return false
	end

	-- Deducir usando AddMoney con valor negativo
	return self:AddMoney(userId, -amount)
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	LIFECYCLE HOOKS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

function PlayerDataService:KnitInit()
	print("[PlayerDataService] âï¸ Initialized (EconomyModule wrapper)")
end

function PlayerDataService:KnitStart()
	print("[PlayerDataService] â Started - Ready to process money operations")
	print("[PlayerDataService] ð Connected to EconomyModule (legacy)")

	-- Verificar que EconomyModule estÃ© cargado
	if not EconomyModule then
		error("[PlayerDataService] â CRITICAL: EconomyModule not found!")
	end

	-- Mostrar info sobre el mÃ³dulo de economÃ­a
	local metrics = EconomyModule.GetMetrics()
	if metrics then
		print(string.format(
			"[PlayerDataService] ð EconomyModule stats: Purchases=%d, Ticks=%d",
			metrics.totalPurchases or 0,
			metrics.totalTicks or 0
		))
	end
end

return PlayerDataService
