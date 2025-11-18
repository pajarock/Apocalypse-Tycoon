--!strict
-- EconomyModule.lua  (robusto y defensivo)

local ServerStorage = game:GetService("ServerStorage")

local Config  = require(ServerStorage.Config.Config)
local UpgDefs = require(ServerStorage.Config.Upgrades)

local EconomyModule = {}

-- =========================
-- Config defensivo
-- =========================
local START_CASH        = tonumber(Config.START_CASH) or 0
local PRICE_MULTIPLIER  = math.max(tonumber(Config.PRICE_MULTIPLIER) or 1.15, 1.0)
local TICK_SECS         = tonumber(Config.TICK_SECS) or 1
local MIN_CASH          = tonumber(Config.MIN_CASH) or 0
local MAX_CASH          = tonumber(Config.MAX_CASH) or 9e15
local DEBUG             = not not Config.DEBUG_MODE
-- Costos de reparación (defensivo)
local REPAIR_BASE_COST     = tonumber(Config.REPAIR_BASE_COST)     or 50   -- costo base
local REPAIR_MULTIPLIER    = math.max(tonumber(Config.REPAIR_MULTIPLIER) or 1.35, 1.0) -- sube por reparación
local REPAIR_DECAY_SECS    = tonumber(Config.REPAIR_DECAY_SECS)    or 60   -- si pasan Xs sin reparar, baja el streak
local REPAIR_DAMAGE_FACTOR = tonumber(Config.REPAIR_DAMAGE_FACTOR) or 1.5  -- pondera por % de vida perdida (opcional)

export type State = {
	Cash: number,
	IncomePerSec: number,
	OwnedUpgrades: {[string]: number},
	TotalEarned: number,
	TotalSpent: number,
	PrestigeLevel: number,
	-- NUEVO: streak de reparaciones
	RepairStreak: number,
	LastRepairT: number,
}

-- memoria (por sesión)
local _stateByUser : {[number]: State} = {}

-- =========================
-- Utilidades internas
-- =========================
local function clampCash(x:number): number
	return math.clamp(x, MIN_CASH, MAX_CASH)
end

local function getState(uid:number): State?
	return _stateByUser[uid]
end

local function ownedCount(uid:number, id:string): number
	local s = getState(uid)
	if not s then return 0 end
	local c = s.OwnedUpgrades[id]
	return (type(c) == "number" and c > 0) and c or 0
end

local function getDef(id:string): any?
	local def = UpgDefs[id]
	if type(def) ~= "table" then return nil end
	return def
end

-- Precio robusto: usa BasePrice o Price; nunca deja 0/NaN.
-- Permite countOverride para previsualizar sin tocar el estado.
local function getUpgradePrice(uid:number, id:string, countOverride:number?): number
	local def = getDef(id)
	if not def then
		if DEBUG then warn(("[ECONOMY] Upgrade '%s' no existe en UpgDefs"):format(tostring(id))) end
		return 9e15
	end

	-- Acepta def.BasePrice o def.Price (ambos soportados)
	local base = tonumber(def.BasePrice or def.Price) or 0
	if base <= 0 then
		if DEBUG then warn(("[ECONOMY] BasePrice inválido para '%s' (%s)"):format(tostring(id), tostring(def.BasePrice or def.Price))) end
		base = 1
	end

	local have = (type(countOverride) == "number" and countOverride >= 0) and countOverride or ownedCount(uid, id)
	local mult = PRICE_MULTIPLIER
	local price = base * (mult ^ have)

	-- Precio mínimo 1 y redondeado
	price = math.max(1, price)
	return math.floor(price + 0.5)
end

-- Recalcula IncomePerSec en base a UpgDefs * cantidad
local function recomputeIncome(uid:number)
	local s = getState(uid)
	if not s then return end

	local totalIPS = 0
	for upgId, count in pairs(s.OwnedUpgrades) do
		if type(count) == "number" and count > 0 then
			local def = getDef(upgId)
			if def then
				local baseInc = tonumber(def.IncomePerSec) or 0
				if baseInc > 0 then
					totalIPS += baseInc * count
					-- multiplicador opcional por-upgrade
					if def.MultIncomePercent then
						totalIPS *= (1 + (tonumber(def.MultIncomePercent) or 0))
					end
				end
			end
		end
	end

	s.IncomePerSec = math.max(0, totalIPS)
end

local function decayRepairStreak(s: State)
	if (s.LastRepairT or 0) <= 0 then return end
	local since = os.clock() - (s.LastRepairT or 0)
	if since >= REPAIR_DECAY_SECS then
		s.RepairStreak = 0
	end
end

-- Costo actual de reparar.
-- damageRatio: 0.0..1.0 (ej. 0.4 si el edificio tiene 40% de vida perdida). Opcional.
local function computeRepairCost(s: State, damageRatio: number?): number
	decayRepairStreak(s)

	local streak = math.max(0, tonumber(s.RepairStreak) or 0)
	local cost = REPAIR_BASE_COST * (REPAIR_MULTIPLIER ^ streak)

	if damageRatio and damageRatio > 0 then
		cost = cost * (1 + REPAIR_DAMAGE_FACTOR * math.clamp(damageRatio, 0, 1))
	end
	cost = math.max(1, cost)
	return math.floor(cost + 0.5)
end

-- =========================
-- API
-- =========================

-- Para pintar botón de "Reparar" (no gasta dinero)
function EconomyModule.GetRepairPreview(uid: number, damageRatio: number?): {price: number, canAfford: boolean, streak: number}
	local s = _stateByUser[uid]
	if not s then return {price = 9e15, canAfford = false, streak = 0} end
	local price = computeRepairCost(s, damageRatio)
	return {
		price = price,
		canAfford = (s.Cash >= price),
		streak = s.RepairStreak or 0,
	}
end

-- Cobra la reparación y aumenta el streak. No modifica vida/daño; eso se hace en tu módulo del evento.
-- Devuelve (ok, pricePagado, reason?)
function EconomyModule.TryRepair(uid: number, damageRatio: number?): (boolean, number, string?)
	local s = _stateByUser[uid]
	if not s then return false, 0, "NO_STATE" end

	local price = computeRepairCost(s, damageRatio)

	if s.Cash < price then
		return false, price, "NOT_ENOUGH_CASH"
	end

	-- cobra
	s.Cash -= price
	s.TotalSpent += price
	s.Cash = math.clamp(s.Cash, MIN_CASH, MAX_CASH)

	-- sube el streak y registra tiempo
	s.RepairStreak = (s.RepairStreak or 0) + 1
	s.LastRepairT  = os.clock()

	if DEBUG then
		print(("[ECONOMY] REPAIR uid=%d price=%d streak=%d cash=%d"):format(uid, price, s.RepairStreak, s.Cash))
	end

	return true, price, nil
end

-- Llama esto al terminar la lluvia de meteoritos o al quedar 100% reparado.
function EconomyModule.ResetRepairStreak(uid: number)
	local s = _stateByUser[uid]
	if not s then return end
	s.RepairStreak = 0
	s.LastRepairT  = 0
end

function EconomyModule.InitPlayer(uid:number, blob:any?)
	local s : State = {
		Cash          = START_CASH,
		IncomePerSec  = 0,
		OwnedUpgrades = {},
		TotalEarned   = 0,
		TotalSpent    = 0,
		PrestigeLevel = 0,
		RepairStreak = 0,
		LastRepairT  = 0,
	}

	if type(blob) == "table" then
		if blob.__fresh then
			s.Cash = START_CASH
		else
			s.Cash          = tonumber(blob.Cash) or s.Cash
			s.TotalEarned   = tonumber(blob.TotalEarned) or 0
			s.TotalSpent    = tonumber(blob.TotalSpent) or 0
			s.PrestigeLevel = tonumber(blob.PrestigeLevel) or 0

			if type(blob.OwnedUpgrades) == "table" then
				for k, v in pairs(blob.OwnedUpgrades) do
					if type(k) == "string" and type(v) == "number" and v > 0 then
						s.OwnedUpgrades[k] = v
					end
				end
			end

			-- si todo luce "vacío", trátalo como nuevo
			if (s.Cash or 0) == 0 and next(s.OwnedUpgrades) == nil and (s.TotalEarned or 0) == 0 then
				s.Cash = START_CASH
			end
		end
	end

	s.Cash = clampCash(s.Cash)
	_stateByUser[uid] = s
	recomputeIncome(uid)

	if DEBUG then
		print(("[ECONOMY] Init uid=%s cash=%s ips=%s prestige=%s")
			:format(tostring(uid), tostring(s.Cash), tostring(s.IncomePerSec), tostring(s.PrestigeLevel)))
	end
end

function EconomyModule.GetState(uid:number): State?
	return getState(uid)
end

function EconomyModule.GetCurrentPrice(uid:number, upgId:string): number
	return getUpgradePrice(uid, upgId, nil)
end

-- Helper de UI: devuelve { price, canAfford, have, capReached }
function EconomyModule.GetPurchasePreview(uid:number, upgId:string)
	local s = getState(uid)
	if not s then return nil end

	local def = getDef(upgId)
	if not def then return nil end

	local have = ownedCount(uid, upgId)
	local cap  = tonumber(def.MaxCount)
	local price = getUpgradePrice(uid, upgId, have)

	return {
		price      = price,
		canAfford  = (s.Cash >= price),
		have       = have,
		capReached = (cap ~= nil and have >= cap) or false,
	}
end

-- Compra 1 unidad
function EconomyModule.Purchase(uid:number, upgId:string): (boolean, string?)
	local s = getState(uid)
	if not s then return false, "NO_STATE" end

	local def = getDef(upgId)
	if not def then return false, "INVALID_UPGRADE" end

	local have = ownedCount(uid, upgId)
	local cap  = tonumber(def.MaxCount)
	if cap and have >= cap then
		return false, "REACH_CAP"
	end

	local price = getUpgradePrice(uid, upgId, have)
	if s.Cash < price then
		return false, "NOT_ENOUGH_CASH"
	end

	-- aplicar compra
	s.Cash -= price
	s.TotalSpent += price
	s.OwnedUpgrades[upgId] = have + 1
	s.Cash = clampCash(s.Cash)

	recomputeIncome(uid)

	if DEBUG then
		print(("[ECONOMY] BUY uid=%d %s -> have=%d  cash=%d  ips=%.0f")
			:format(uid, upgId, s.OwnedUpgrades[upgId], s.Cash, s.IncomePerSec))
	end

	return true, nil
end

-- Pago periódico
function EconomyModule.TickAll()
	local Players = game:GetService("Players")

	for uid, s in pairs(_stateByUser) do
		local incPerTick = (s.IncomePerSec or 0) * (TICK_SECS > 0 and TICK_SECS or 1)
		if incPerTick > 0 then
			-- 🔥 NUEVO: Aplicar multiplicador de Coin Rain power-up
			local multiplier = 1
			local player = Players:GetPlayerByUserId(uid)
			if player then
				multiplier = player:GetAttribute("CoinMultiplier") or 1
			end

			local finalIncome = incPerTick * multiplier

			s.Cash = clampCash(s.Cash + finalIncome)
			s.TotalEarned += finalIncome

			-- Debug solo si hay multiplicador activo
			if DEBUG and multiplier > 1 then
				print(("[ECONOMY] 💰 Coin Rain! uid=%d income=%.1f (x%.1f)"):format(
					uid, finalIncome, multiplier
				))
			end
		end
	end
end

-- Serialización
function EconomyModule.ToBlob(uid:number): any?
	local s = getState(uid)
	if not s then return nil end
	return {
		Cash          = math.floor(s.Cash + 0.5),
		OwnedUpgrades = s.OwnedUpgrades,
		TotalEarned   = math.floor(s.TotalEarned + 0.5),
		TotalSpent    = math.floor(s.TotalSpent + 0.5),
		PrestigeLevel = s.PrestigeLevel or 0,
	}
end

function EconomyModule.FromBlob(uid:number, blob:any)
	EconomyModule.InitPlayer(uid, blob)
end

return EconomyModule
