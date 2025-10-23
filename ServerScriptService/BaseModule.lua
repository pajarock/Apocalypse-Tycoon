--!strict
--[[
	BASE MODULE - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Gestiona la salud y estado de las bases de los jugadores.

	FEATURES:
	✅ Sistema de HP por jugador
	✅ Daño con reducción por shields
	✅ Invulnerabilidad temporal
	✅ Regeneración automática
	✅ Eventos de estado (damaged, destroyed, healed)
	✅ Sistema de meteoros sobrevividos

	USAGE:
		local Base = require(game.ServerScriptService.BaseModule)

		Base.InitPlayer(userId)
		Base.ApplyDamage(userId, 50)
		local hp = Base.GetHP(userId)
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--═══════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════════════

local BaseState = {} -- [userId] = {HP, MaxHP, LastDamageTime, IsInvulnerable, ShieldLevel, MeteorsSurvived}

--═══════════════════════════════════════════════════════════════════════
-- MÓDULO
--═══════════════════════════════════════════════════════════════════════

local BaseModule = {}

--═══════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
--═══════════════════════════════════════════════════════════════════════

function BaseModule.InitPlayer(userId: number)
	if BaseState[userId] then
		if DEBUG then
			warn(("[BaseModule] Usuario %d ya inicializado"):format(userId))
		end
		return
	end

	BaseState[userId] = {
		HP = Config.BASE_MAX_HP,
		MaxHP = Config.BASE_MAX_HP,
		LastDamageTime = 0,
		IsInvulnerable = false,
		ShieldLevel = 0,
		MeteorsSurvived = 0,
		RegenEnabled = true
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

--═══════════════════════════════════════════════════════════════════════
-- HP MANAGEMENT
--═══════════════════════════════════════════════════════════════════════

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
		print(("[BaseModule] SetHP userId %d: %d → %d"):format(userId, old, BaseState[userId].HP))
	end
end

function BaseModule.AddHP(userId: number, amount: number)
	if not BaseState[userId] then return end

	local old = BaseState[userId].HP
	BaseState[userId].HP = math.min(BaseState[userId].HP + amount, BaseState[userId].MaxHP)

	if DEBUG and amount > 0 then
		print(("[BaseModule] AddHP userId %d: +%d HP (%d → %d)"):format(
			userId, amount, old, BaseState[userId].HP
		))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- DAMAGE SYSTEM
--═══════════════════════════════════════════════════════════════════════

function BaseModule.ApplyDamage(userId: number, rawDamage: number): number
	if not BaseState[userId] then
		warn(("[BaseModule] ApplyDamage: Usuario %d no inicializado"):format(userId))
		return 0
	end

	local state = BaseState[userId]

	-- Invulnerabilidad
	if state.IsInvulnerable then
		if DEBUG then
			print(("[BaseModule] Daño bloqueado (invulnerable) - userId %d"):format(userId))
		end
		return 0
	end

	-- Reducción por shields
	local reduction = 1.0
	if state.ShieldLevel > 0 then
		reduction = 1.0 - (Config.SHIELD_DAMAGE_REDUCTION * state.ShieldLevel)
		reduction = math.max(0.1, reduction) -- Mínimo 10% de daño siempre pasa
	end

	local finalDamage = math.floor(rawDamage * reduction)
	local oldHP = state.HP

	state.HP = math.max(0, state.HP - finalDamage)
	state.LastDamageTime = tick()

	-- Detectar muerte
	if state.HP <= 0 and oldHP > 0 then
		BaseModule.OnBaseDead(userId)
	end

	if DEBUG then
		print(("[BaseModule] Daño aplicado - userId %d | raw=%d, shields=%.0f%%, final=%d | HP: %d → %d"):format(
			userId, rawDamage, (1-reduction)*100, finalDamage, oldHP, state.HP
		))
	end

	return finalDamage
end

function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print(("[BaseModule] 💀 BASE DESTRUIDA - userId %d"):format(userId))
	end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		-- Aquí puedes agregar lógica de penalización
		-- Por ejemplo: perder % de dinero, reset parcial, etc.

		-- Por ahora solo reseteamos HP
		task.wait(5) -- Esperar 5 segundos
		BaseModule.SetHP(userId, Config.BASE_MAX_HP)

		if DEBUG then
			print(("[BaseModule] Base respawneada - userId %d"):format(userId))
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- SHIELD SYSTEM
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════
-- INVULNERABILITY
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════
-- METEOR SURVIVAL TRACKING
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════
-- REGENERATION SYSTEM
--═══════════════════════════════════════════════════════════════════════

function BaseModule.SetRegenEnabled(userId: number, enabled: boolean)
	if not BaseState[userId] then return end
	BaseState[userId].RegenEnabled = enabled
end

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			if state.RegenEnabled and state.HP < state.MaxHP then
				-- Solo regenerar si no ha recibido daño recientemente
				local timeSinceDamage = tick() - state.LastDamageTime

				if timeSinceDamage >= Config.BASE_REGEN_DELAY then
					state.HP = math.min(state.HP + Config.BASE_REGEN_RATE, state.MaxHP)

					if DEBUG and state.HP % 10 == 0 then
						print(("[BaseModule] Regen - userId %d: %d/%d"):format(
							userId, state.HP, state.MaxHP
						))
					end
				end
			end
		end
	end
end)

--═══════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
--═══════════════════════════════════════════════════════════════════════

function BaseModule.DebugPrintState(userId: number)
	if not BaseState[userId] then
		print(("[BaseModule] Usuario %d no encontrado"):format(userId))
		return
	end

	local state = BaseState[userId]
	print(("═════════════════════════════════════════"))
	print(("  BASE STATE - User %d"):format(userId))
	print(("═════════════════════════════════════════"))
	print(("  HP: %d / %d (%.0f%%)"):format(state.HP, state.MaxHP, (state.HP/state.MaxHP)*100))
	print(("  Shield Level: %d (%.0f%% reduction)"):format(
		state.ShieldLevel, Config.SHIELD_DAMAGE_REDUCTION * state.ShieldLevel * 100
	))
	print(("  Invulnerable: %s"):format(state.IsInvulnerable and "YES" or "NO"))
	print(("  Meteors Survived: %d"):format(state.MeteorsSurvived))
	print(("  Last Damage: %.1fs ago"):format(tick() - state.LastDamageTime))
	print(("  Regen Enabled: %s"):format(state.RegenEnabled and "YES" or "NO"))
	print(("═════════════════════════════════════════"))
end

--═══════════════════════════════════════════════════════════════════════
-- CLEANUP
--═══════════════════════════════════════════════════════════════════════

-- Limpiar cuando jugadores se van
Players.PlayerRemoving:Connect(function(plr)
	BaseModule.RemovePlayer(plr.UserId)
end)

--═══════════════════════════════════════════════════════════════════════

if DEBUG then
	print("[BaseModule] ✓ Módulo cargado")
end

return BaseModule
