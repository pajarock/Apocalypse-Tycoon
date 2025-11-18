--!strict
--[[
	BASE MODULE - Apocalypse Tycoon (ARREGLADO)
	-----------------------------------------------------------------------

	? ARREGLOS EN ESTA VERSIÓN:
	1. Eliminada dependencia circular con EventManager (línea 28 removida)
	2. Eliminado código de shake duplicado (líneas 272-276 removidas)
	3. El shake ahora se maneja completamente en EventManager

	CAMBIOS RESPECTO A LA VERSIÓN ANTERIOR:
	- Línea 28: ELIMINADA - No require EventManager
	- Líneas 271-276: ELIMINADAS - No llama a EventManager.ShakePlayer
	- Todo lo demás funciona igual

	Gestiona la salud y estado de las bases de los jugadores.

	FEATURES:
	? Sistema de HP por jugador
	? Daño con reducción por shields
	? Invulnerabilidad temporal
	? Regeneración automática
	? Eventos de estado (damaged, destroyed, healed)
	? Sistema de meteoros sobrevividos

	USAGE:
		local Base = require(game.ServerScriptService.BaseModule)

		Base.InitPlayer(userId)
		Base.ApplyDamage(userId, 50)
		local hp = Base.GetHP(userId)
--]]
local DAMAGE_COOLDOWN = 0.35 --Nueva integracion para evitar doble damage.

local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

-- ? ARREGLADO: Eliminado require de EventManager (dependencia circular)
-- local EventManager = require(game.ServerScriptService:WaitForChild("EventManager"))

-------------------------------------------------------------------------
-- CONFIGURACIÓN
-------------------------------------------------------------------------

-- Intentar cargar Config, si no existe usar defaults
local Config = nil
local success = pcall(function()
	Config = require(game.ServerStorage.Config.Config)
end)

if not success or not Config then
	warn("[BaseModule] Config.lua no encontrado, usando valores por defecto")
	Config = {
		BASE_MAX_HP = 100,
		BASE_REGEN_RATE = 1,
		BASE_REGEN_DELAY = 5,
		SHIELD_DAMAGE_REDUCTION = 0.15,
		DEBUG_MODE = false
	}
end

local DEBUG = Config.DEBUG_MODE or false
--local DEBUG = true --forzado para testing

local Economy = nil
local economySuccess = pcall(function()
	Economy = require(game.ServerScriptService.EconomyModule)
end)

if not economySuccess or not Economy then
	warn("[BaseModule] EconomyModule no encontrado - penalizaciones desactivadas")
end
-------------------------------------------------------------------------
-- ESTADO
-------------------------------------------------------------------------

local BaseState = {} -- [userId] = {HP, MaxHP, LastDamageTime, IsInvulnerable, ShieldLevel, MeteorsSurvived, DiedDuringWave}
local PendingMoneyReductions = {} -- [userId] = {targetAmount, timestamp}
local ActiveGuardianTasks = {} -- [userId] = task thread

-------------------------------------------------------------------------
-- MÓDULO
-------------------------------------------------------------------------

local BaseModule = {}

-------------------------------------------------------------------------
-- INICIALIZACIÓN
-------------------------------------------------------------------------

function BaseModule.InitPlayer(userId: number)
	if BaseState[userId] then
		if DEBUG then
			warn(("[BaseModule] Usuario %d ya inicializado"):format(userId))
		end
		return
	end

	-- ? Flag para detectar muerte durante wave actual
	BaseState[userId] = {
		HP = Config.BASE_MAX_HP,
		MaxHP = Config.BASE_MAX_HP,
		LastDamageTime = 0,
		IsInvulnerable = false,
		ShieldLevel = 0,
		MeteorsSurvived = 0,
		RegenEnabled = true,
		DiedDuringWave = false
	}

	if DEBUG then
		print(("[BaseModule] Inicializado userId %d - HP: %d"):format(userId, Config.BASE_MAX_HP))
	end
end

function BaseModule.RemovePlayer(userId: number)
	BaseState[userId] = nil

	if DEBUG then
		print(("[BaseModule] Removido userId %d"):format(userId))
	end
end

function BaseModule.IncreaseMaxHP(userId: number, amount: number)
	if not BaseState[userId] then return end

	BaseState[userId].MaxHP += amount
	BaseState[userId].HP = math.min(
		BaseState[userId].HP + amount,
		BaseState[userId].MaxHP
	)

	if DEBUG then
		print(("[BaseModule] Max HP aumentado - userId %d: %d"):format(
			userId, BaseState[userId].MaxHP
			))
	end

	-- Actualizar visuales
	local BaseVisualsManager = require(game.ServerStorage.Managers.BaseVisualsManager)
	BaseVisualsManager.UpdateBaseVisuals(
		userId,
		BaseState[userId].HP,
		BaseState[userId].MaxHP
	)
end

-- Getter para MaxHP
function BaseModule.GetMaxHP(userId: number): number
	if not BaseState[userId] then
		return Config.BASE_MAX_HP
	end

	return BaseState[userId].MaxHP
end

--[[
Luego en Main.Server, cuando compren Upgrade_7:
]]

if upgradeId == "Upgrade_7" then
	-- ? Aumentar MaxHP individual del jugador
	Base.IncreaseMaxHP(plr.UserId, 5)

	if DEBUG then
		print(("[PURCHASE] Max HP de %s aumentado a %d"):format(
			plr.Name, Base.GetMaxHP(plr.UserId)
			))
	end
end
-------------------------------------------------------------------------
-- HP MANAGEMENT
-------------------------------------------------------------------------
local function createBaseBillboard(plate: BasePart, playerName: string, userId: number)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(300, 80)
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = plate

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = playerName .. "'s Base"
	nameLabel.Parent = frame

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HPLabel"
	hpLabel.Size = UDim2.fromScale(1, 0.5)
	hpLabel.Position = UDim2.fromScale(0, 0.5)
	hpLabel.BackgroundTransparency = 1
	hpLabel.TextScaled = true
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	hpLabel.Text = string.format("HP: %d/%d", BaseModule.GetHP(userId), Config.BASE_MAX_HP)
	hpLabel.Parent = frame

	-- Actualizar HP label periódicamente
	task.spawn(function()
		while plate and plate.Parent and Players:GetPlayerByUserId(userId) do
			local hp = BaseModule.GetHP(userId)
			local maxHP = Config.BASE_MAX_HP
			local pct = hp / maxHP

			hpLabel.Text = string.format("HP: %d/%d", hp, maxHP)

			if pct > 0.7 then
				hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
			elseif pct > 0.3 then
				hpLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
			else
				hpLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			end

			task.wait(2)
		end
	end)
end

function BaseModule.GetHP(userId: number): number
	if not BaseState[userId] then
		warn(("[BaseModule] GetHP: Usuario %d no inicializado"):format(userId))
		return 0
	end

	return BaseState[userId].HP
end

function BaseModule.GetMaxHP(userId: number): number
	if not BaseState[userId] then
		return Config.BASE_MAX_HP
	end

	return BaseState[userId].MaxHP
end

function BaseModule.SetHP(userId: number, newHP: number)
	if not BaseState[userId] then
		warn(("[BaseModule] SetHP: Usuario %d no inicializado"):format(userId))
		return
	end

	local old = BaseState[userId].HP
	BaseState[userId].HP = math.clamp(newHP, 0, BaseState[userId].MaxHP)

	if DEBUG and old ~= BaseState[userId].HP then
		print(("[BaseModule] SetHP userId %d: %d ? %d"):format(userId, old, BaseState[userId].HP))
	end
end

function BaseModule.AddHP(userId: number, amount: number)
	if not BaseState[userId] then return end

	local old = BaseState[userId].HP
	BaseState[userId].HP = math.min(BaseState[userId].HP + amount, BaseState[userId].MaxHP)

	if DEBUG and amount > 0 then
		print(("[BaseModule] AddHP userId %d: +%d HP (%d ? %d)"):format(
			userId, amount, old, BaseState[userId].HP
			))
	end
end

function BaseModule.SetMaxHP(userId: number, newMaxHP: number)
	if not BaseState[userId] then
		warn(("[BaseModule] SetMaxHP: Usuario %d no inicializado"):format(userId))
		return
	end

	local oldMaxHP = BaseState[userId].MaxHP
	BaseState[userId].MaxHP = newMaxHP

	-- Si el HP actual era el mÃ¡ximo, aumentarlo tambiÃ©n
	if BaseState[userId].HP == oldMaxHP then
		BaseState[userId].HP = newMaxHP
	end

	if DEBUG then
		print(("[BaseModule] SetMaxHP userId %d: %d â†’ %d"):format(userId, oldMaxHP, newMaxHP))
	end
end

-------------------------------------------------------------------------
-- DAMAGE SYSTEM
-------------------------------------------------------------------------

local DEFAULTS = {
	MaxHP = 100,
	HP = 100,
	ShieldLevel = 0,
	IsInvulnerable = false,
	LastDamageTime = -1e9,
	MeteorsSurvived = 0,
	DiedDuringWave = false
}

local function ensureState(userId: number)
	local s = BaseState[userId]
	if not s then
		s = {}
		BaseState[userId] = s
	end
	if type(s.MaxHP) ~= "number" then s.MaxHP = DEFAULTS.MaxHP end
	if type(s.HP) ~= "number" then s.HP = s.MaxHP end
	if type(s.ShieldLevel) ~= "number" then s.ShieldLevel = DEFAULTS.ShieldLevel end
	if type(s.IsInvulnerable) ~= "boolean" then s.IsInvulnerable = DEFAULTS.IsInvulnerable end
	if type(s.LastDamageTime) ~= "number" then s.LastDamageTime = DEFAULTS.LastDamageTime end
	if type(s.MeteorsSurvived) ~= "number" then s.MeteorsSurvived = DEFAULTS.MeteorsSurvived end
	if type(s.DiedDuringWave) ~= "boolean" then s.DiedDuringWave = DEFAULTS.DiedDuringWave end
	return s
end

function BaseModule.ApplyDamage(userId: number, rawDamage: number): number
	local state = ensureState(userId)

	-- Cooldown
	local now = tick()
	if (state.LastDamageTime or -1e9) + DAMAGE_COOLDOWN > now then
		return 0
	end

	-- Invulnerable
	if state.IsInvulnerable then
		state.LastDamageTime = now
		return 0
	end

	-- Reducción por escudo
	local shield = tonumber(state.ShieldLevel) or 0
	local reduction = 1.0
	if shield > 0 then
		reduction = 1.0 - (Config.SHIELD_DAMAGE_REDUCTION * shield)
		reduction = math.max(0.1, reduction)
	end

	-- Aplicar daño
	local dmg = tonumber(rawDamage) or 0
	local finalDamage = math.floor(dmg * reduction + 0.5)
	local oldHP = tonumber(state.HP) or 0
	state.HP = math.max(0, oldHP - finalDamage)
	state.LastDamageTime = now

	-- Muerte
	if state.HP <= 0 and oldHP > 0 and BaseModule.OnBaseDead then
		BaseModule.OnBaseDead(userId)
	end

	-- ? ARREGLADO: Eliminado código de shake - ahora se maneja en EventManager
	-- El shake se activa directamente en EventManager cuando impacta un meteorito
	-- No es necesario duplicar la lógica aquí

	if DEBUG then
		print(("[BaseModule] ApplyDamage userId %d: -%d HP (%d ? %d)"):format(
			userId, finalDamage, oldHP, state.HP
			))
	end

	return finalDamage
end

-------------------------------------------------------------------------
-- SISTEMA DE PENALIZACIONES POR MUERTE DE BASE
-------------------------------------------------------------------------

-- ? ARREGLADO: Removidas declaraciones duplicadas - usar las de línea 79-80

function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print(("[BaseModule] ?? BASE DESTRUIDA - userId %d"):format(userId))
	end

	-- ? MARCAR QUE MURIÓ DURANTE ESTA WAVE
	if BaseState[userId] then
		BaseState[userId].DiedDuringWave = true
		if DEBUG then
			print(("[BaseModule] ?? Flag DiedDuringWave activado para userId %d"):format(userId))
		end
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- 1?? OBTENER DINERO ACTUAL DESDE ECONOMY MODULE
	local currentMoney = 0
	local economyState = nil

	if Economy then
		economyState = Economy.GetState(userId)
		if economyState then
			currentMoney = economyState.Cash or 0
		end
	else
		-- Fallback: leer desde leaderstats si Economy no disponible
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local cashValue = ls:FindFirstChild("Cash")
			if cashValue then
				currentMoney = cashValue.Value
			end
		end
	end

	if DEBUG then
		print(("[BaseModule] ?? ANTES - Dinero: $%d"):format(currentMoney))
	end

	-- 2?? CALCULAR PENALIZACIÓN (25% del dinero actual)
	local moneyLost = math.floor(currentMoney * 0.25)
	local newAmount = math.max(0, currentMoney - moneyLost)

	if DEBUG then
		print(("[BaseModule] ?? Pérdida calculada: $%d (25%%)"):format(moneyLost))
		print(("[BaseModule] ?? NUEVO valor: $%d"):format(newAmount))
	end

	-- 3?? ACTUALIZAR AMBOS LUGARES: ECONOMY Y LEADERSTATS

	-- A) Actualizar EconomyModule (la fuente de verdad)
	if economyState then
		economyState.Cash = newAmount
		if DEBUG then
			print(("[BaseModule] ? Economy.Cash actualizado a $%d"):format(newAmount))
		end
	end

	-- B) Actualizar leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashValue = ls:FindFirstChild("Cash")
		if cashValue then
			cashValue.Value = newAmount
			if DEBUG then
				print(("[BaseModule] ? leaderstats.Cash actualizado a $%d"):format(newAmount))
			end
		end
	end

	-- 4?? ACTIVAR GUARDIAN (protección por 120 segundos)
	PendingMoneyReductions[userId] = {
		TargetAmount = newAmount,
		StartTime = tick(),
		Duration = 120
	}

	-- Cancelar guardian previo si existe
	if ActiveGuardianTasks[userId] then
		task.cancel(ActiveGuardianTasks[userId])
		ActiveGuardianTasks[userId] = nil
		if DEBUG then
			print(("[BaseModule] ?? Guardian previo cancelado"))
		end
	end

	-- Iniciar nuevo guardian
	ActiveGuardianTasks[userId] = task.spawn(function()
		local startTime = tick()
		local forceDuration = 120 -- 2 minutos
		local checkInterval = 0.5 -- Revisar cada 0.5 segundos

		if DEBUG then
			print(("[BaseModule] ??? Guardian ACTIVADO - Protegiendo $%d por %ds"):format(
				newAmount, forceDuration
				))
		end

		while tick() - startTime < forceDuration do
			task.wait(checkInterval)

			-- ? Leer el target actual desde PendingMoneyReductions (puede cambiar con compras)
			local protection = PendingMoneyReductions[userId]
			if not protection then
				if DEBUG then
					print(("[BaseModule] ?? Guardian: Protección eliminada externamente"):format())
				end
				break
			end

			local targetAmount = protection.TargetAmount

			-- Verificar si el jugador sigue conectado
			local plr = Players:GetPlayerByUserId(userId)
			if not plr then
				if DEBUG then
					print(("[BaseModule] ?? Guardian: Jugador desconectado"):format())
				end
				break
			end

			local cash = plr:FindFirstChild("leaderstats") and plr:FindFirstChild("leaderstats"):FindFirstChild("Cash")
			if not cash then
				if DEBUG then
					warn(("[BaseModule] ?? Guardian: Cash no encontrado"):format())
				end
				break
			end

			-- ? ARREGLADO: Solo evitar que BAJE del mínimo, permitir que SUBA
			if cash.Value < targetAmount then
				local oldValue = cash.Value

				-- Forzar al mínimo solo si bajó
				cash.Value = targetAmount

				if Economy then
					local state = Economy.GetState(userId)
					if state then
						state.Cash = targetAmount
					end
				end

				if DEBUG then
					print(("[BaseModule] ??? Guardian PROTEGIÓ: Dinero bajó de $%d a $%d"):format(
						targetAmount, oldValue
						))
					print(("[BaseModule] ??? Guardian RESTAURÓ: $%d ? $%d"):format(
						oldValue, targetAmount
						))
				end
			elseif DEBUG and cash.Value > targetAmount then
				-- Income normal funcionando, no hacer nada
				print(("[BaseModule] ? Guardian: Income OK ($%d, mínimo protegido: $%d)"):format(
					cash.Value, targetAmount
					))
			end
		end

		ActiveGuardianTasks[userId] = nil
		if DEBUG then
			print(("[BaseModule] ? Guardian TERMINADO - Protección finalizada"):format())
		end
	end)

	-- 5?? MOSTRAR PANTALLA DE MUERTE
	local Remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
	if Remotes then
		local BaseDead = Remotes:FindFirstChild("BaseDead")
		if BaseDead and BaseDead:IsA("RemoteEvent") then
			BaseDead:FireClient(player, moneyLost, 10)
			if DEBUG then
				print(("[BaseModule] ?? Pantalla de muerte enviada"):format())
			end
		end
	end

	-- 6?? ESPERAR 10 SEGUNDOS Y RESPAWNEAR BASE
	task.wait(10)

	-- Respawnear con 50% HP
	local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
	BaseModule.SetHP(userId, respawnHP)

	if DEBUG then
		print(("[BaseModule] ??? Base respawneada - userId %d con %d HP"):format(
			userId, respawnHP
			))
	end

	-- Actualizar visuales de la base
	local BaseStateChanged = Remotes and Remotes:FindFirstChild("BaseStateChanged")
	if BaseStateChanged and BaseStateChanged:IsA("RemoteEvent") then
		BaseStateChanged:FireClient(player, {
			UserId = userId,
			BaseHP = respawnHP,
			MaxHP = Config.BASE_MAX_HP,
		})
	end

	-- Actualizar visuales (si BaseVisualsManager está disponible)
	local BaseVisualsManager = nil
	pcall(function()
		BaseVisualsManager = require(game.ServerStorage.Managers.BaseVisualsManager)
	end)

	if BaseVisualsManager and BaseVisualsManager.UpdateBaseVisuals then
		BaseVisualsManager.UpdateBaseVisuals(userId, respawnHP, Config.BASE_MAX_HP)
	end
end

-------------------------------------------------------------------------
-- SHIELD SYSTEM
-------------------------------------------------------------------------

function BaseModule.SetShieldLevel(userId: number, level: number)
	if not BaseState[userId] then return end

	BaseState[userId].ShieldLevel = math.max(0, level)

	if DEBUG then
		print(("[BaseModule] Shield level userId %d: %d (reducción: %.0f%%)"):format(
			userId, level, Config.SHIELD_DAMAGE_REDUCTION * level * 100
			))
	end
end

function BaseModule.GetShieldLevel(userId: number): number
	if not BaseState[userId] then return 0 end
	return BaseState[userId].ShieldLevel
end

-------------------------------------------------------------------------
-- INVULNERABILITY
-------------------------------------------------------------------------

function BaseModule.SetInvulnerable(userId: number, invul: boolean, duration: number?)
	if not BaseState[userId] then return end

	BaseState[userId].IsInvulnerable = invul

	if invul and duration then
		task.delay(duration, function()
			if BaseState[userId] then
				BaseState[userId].IsInvulnerable = false
				if DEBUG then
					print(("[BaseModule] Invulnerabilidad terminada - userId %d"):format(userId))
				end
			end
		end)
	end

	if DEBUG then
		print(("[BaseModule] Invulnerabilidad userId %d: %s"):format(
			userId, invul and "ACTIVA" or "INACTIVA"
			))
	end
end

function BaseModule.IsInvulnerable(userId: number): boolean
	if not BaseState[userId] then return false end
	return BaseState[userId].IsInvulnerable
end

-------------------------------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------------------------------

function BaseModule.IsLowHP(userId: number): boolean
	if not BaseState[userId] then return false end

	local pct = BaseState[userId].HP / BaseState[userId].MaxHP
	return pct < 0.25 -- Menos del 25%
end

function BaseModule.GetHPPercentage(userId: number): number
	if not BaseState[userId] then return 0 end

	return BaseState[userId].HP / BaseState[userId].MaxHP
end

function BaseModule.HealOnRespawn(userId: number)
	if not BaseState[userId] then return end

	-- Curar 25% al respawnear
	local healAmount = math.floor(BaseState[userId].MaxHP * 0.25)
	BaseModule.AddHP(userId, healAmount)

	if DEBUG then
		print(("[BaseModule] Heal on respawn - userId %d: +%d HP"):format(userId, healAmount))
	end
end

-------------------------------------------------------------------------
-- METEOR SURVIVAL TRACKING
-------------------------------------------------------------------------

function BaseModule.IncrementMeteorsSurvived(userId: number)
	if not BaseState[userId] then return end

	BaseState[userId].MeteorsSurvived += 1

	if DEBUG and BaseState[userId].MeteorsSurvived % 10 == 0 then
		print(("[BaseModule] Usuario %d sobrevivió %d meteoritos!"):format(
			userId, BaseState[userId].MeteorsSurvived
			))
	end
end

function BaseModule.GetMeteorsSurvived(userId: number): number
	if not BaseState[userId] then return 0 end
	return BaseState[userId].MeteorsSurvived
end

-------------------------------------------------------------------------
-- WAVE DEATH TRACKING (para sistema de waves)
-------------------------------------------------------------------------

-- ? Resetear flag al inicio de cada wave
function BaseModule.ResetWaveDeathFlag(userId: number)
	if not BaseState[userId] then return end

	BaseState[userId].DiedDuringWave = false

	if DEBUG then
		print(("[BaseModule] ?? Flag DiedDuringWave reseteado para userId %d"):format(userId))
	end
end

-- ? Verificar si murió durante la wave actual
function BaseModule.DiedDuringCurrentWave(userId: number): boolean
	if not BaseState[userId] then return false end
	return BaseState[userId].DiedDuringWave or false
end

-- ? Resetear flags de TODOS los jugadores (llamar al inicio de cada wave)
function BaseModule.ResetAllWaveDeathFlags()
	for userId, state in pairs(BaseState) do
		if state and type(state) == "table" then
			state.DiedDuringWave = false
		end
	end

	if DEBUG then
		print("[BaseModule] ?? Flags DiedDuringWave reseteados para todos los jugadores")
	end
end

-------------------------------------------------------------------------
-- REGENERATION SYSTEM
-------------------------------------------------------------------------

function BaseModule.SetRegenEnabled(userId: number, enabled: boolean)
	if not BaseState[userId] then return end
	BaseState[userId].RegenEnabled = enabled
end

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1)

		for userId, state in pairs(BaseState) do
			-- ? ARREGLADO: Validar todo
			if state and type(state) == "table" then
				local hp = state.HP
				local maxHP = state.MaxHP
				local regenEnabled = state.RegenEnabled
				local lastDamageTime = state.LastDamageTime or 0

				if hp and maxHP and regenEnabled and type(hp) == "number" and type(maxHP) == "number" then
					if hp < maxHP then
						local timeSinceDamage = tick() - lastDamageTime

						if timeSinceDamage >= Config.BASE_REGEN_DELAY then
							state.HP = math.min(hp + Config.BASE_REGEN_RATE, maxHP)

							if DEBUG and state.HP % 10 == 0 then
								print(("[BaseModule] Regen - userId %d: %d/%d"):format(
									userId, state.HP, state.MaxHP
									))
							end
						end
					end
				end
			end
		end
	end
end)

-------------------------------------------------------------------------
-- DEBUG COMMANDS
-------------------------------------------------------------------------

function BaseModule.DebugPrintState(userId: number)
	if not BaseState[userId] then
		print(("[BaseModule] Usuario %d no encontrado"):format(userId))
		return
	end

	local state = BaseState[userId]
	print(("-----------------------------------------"))
	print(("  BASE STATE - User %d"):format(userId))
	print(("-----------------------------------------"))
	print(("  HP: %d / %d (%.0f%%)"):format(state.HP, state.MaxHP, (state.HP/state.MaxHP)*100))
	print(("  Shield Level: %d (%.0f%% reduction)"):format(
		state.ShieldLevel, Config.SHIELD_DAMAGE_REDUCTION * state.ShieldLevel * 100
		))
	print(("  Invulnerable: %s"):format(state.IsInvulnerable and "YES" or "NO"))
	print(("  Meteors Survived: %d"):format(state.MeteorsSurvived))
	print(("  Last Damage: %.1fs ago"):format(tick() - state.LastDamageTime))
	print(("  Regen Enabled: %s"):format(state.RegenEnabled and "YES" or "NO"))
	print(("-----------------------------------------"))
end

-------------------------------------------------------------------------
-- CLEANUP
-------------------------------------------------------------------------

Players.PlayerRemoving:Connect(function(plr)
	local userId = plr.UserId

	BaseModule.RemovePlayer(userId)

	-- ? NUEVO: Cancelar guardian activo
	if ActiveGuardianTasks[userId] then
		task.cancel(ActiveGuardianTasks[userId])
		ActiveGuardianTasks[userId] = nil

		if DEBUG then
			print(("[BaseModule] Guardian cancelado para jugador que se fue: %d"):format(userId))
		end
	end

	-- ? NUEVO: Limpiar pending reductions
	if PendingMoneyReductions[userId] then
		PendingMoneyReductions[userId] = nil
	end
end)

-------------------------------------------------------------------------

if DEBUG then
	print("[BaseModule ARREGLADO] ? Módulo cargado (sin dependencia circular)")
end

--[[task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, data in pairs(PendingMoneyReductions) do
			-- Validar que data existe
			if data and type(data) == "table" then
				local player = Players:GetPlayerByUserId(userId)

				if player then
					local leaderstats = player:FindFirstChild("leaderstats")
					local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")

					if cashValue and data.targetAmount then
						-- Si el dinero está MAYOR al target, forzar reducción
						if cashValue.Value > data.targetAmount then
							cashValue.Value = data.targetAmount

							if DEBUG then
								print(("[BaseModule] ??? Guardian: Forzando dinero de userId %d a $%d"):format(
									userId, data.targetAmount
									))
							end
						end

						-- Después de 120 segundos (2 autosaves), dejar de forzar
						if data.timestamp and (tick() - data.timestamp > 120) then
							PendingMoneyReductions[userId] = nil

							if DEBUG then
								print(("[BaseModule] ? Guardian: Dinero de userId %d asegurado"):format(userId))
							end
						end
					end
				else
					-- Jugador se fue, limpiar
					PendingMoneyReductions[userId] = nil
				end
			else
				-- Data inválida, limpiar
				PendingMoneyReductions[userId] = nil
			end
		end
	end
end)
--]]

-------------------------------------------------------------------------
-- ? ACTUALIZAR GUARDIAN DESPUÉS DE COMPRAS LEGÍTIMAS
-------------------------------------------------------------------------

function BaseModule.UpdateGuardianTarget(userId: number, newTarget: number)
	local protection = PendingMoneyReductions[userId]

	-- ? Si no existe pero hay guardian task activo, crear la entrada
	if not protection then
		if ActiveGuardianTasks[userId] then
			-- Guardian activo pero sin PendingMoneyReductions - crearlo
			PendingMoneyReductions[userId] = {
				TargetAmount = newTarget,
				StartTime = tick(),
				Duration = 120
			}

			if DEBUG then
				print(("[BaseModule] ??? Guardian: Creada protección para compra legítima - Target: $%d"):format(newTarget))
			end
		else
			if DEBUG then
				print(("[BaseModule] ?? No hay Guardian activo para userId %d"):format(userId))
			end
		end
		return
	end

	-- Actualizar el target amount
	local oldTarget = protection.TargetAmount
	protection.TargetAmount = newTarget

	if DEBUG then
		print(("[BaseModule] ??? Guardian: Target actualizado $%d ? $%d para userId %d (compra legítima)"):format(
			oldTarget, newTarget, userId
			))
	end
end

return BaseModule