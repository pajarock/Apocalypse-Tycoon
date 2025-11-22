--!strict
--[[
	-----------------------------------------------------------------------
	DEBUG MANAGER - Sistema completo de debug para testing
	-----------------------------------------------------------------------

	CONTROLES:
	- N: Skip al siguiente wave
	- Shift+N: Saltar +5 waves
	- B: Spawn Boss instantÃ¡neo
	- V: Spawn Mini-Boss instantÃ¡neo
	- C: AÃ±adir $10,000
	- Shift+C: AÃ±adir $100,000
	- Y: Reset a Wave 1
	- G: Toggle Invencibilidad (God Mode)
	- 1-9: Saltar a wave especÃ­fico (10, 20, 30, etc.)

	-----------------------------------------------------------------------
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Solo funciona en Studio
if not RunService:IsStudio() then
	return
end

print("[DEBUG MANAGER] ??? Iniciando sistema de debug...")

-- Esperar a que Main.Server.lua cree los componentes necesarios
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CurrentWaveValue = ReplicatedStorage:WaitForChild("CurrentWave", 10)

-- MÃ³dulos
local Config = require(ServerStorage.Config.Config)
local Events = require(ServerScriptService.EventManager)

-- Esperar a que Economy y DataStore estÃ©n cargados
task.wait(2)
local Economy = require(ServerScriptService.EconomyModule)
local DataStore = require(ServerScriptService.DataStoreModule)
local Base = require(ServerScriptService.BaseModule)

-- Remotes de debug
local DebugSkipWave = Remotes:WaitForChild("DebugSkipWave")
local DebugJumpToWave = Remotes:WaitForChild("DebugJumpToWave")
local DebugSpawnBoss = Remotes:WaitForChild("DebugSpawnBoss")
local DebugSpawnMiniBoss = Remotes:WaitForChild("DebugSpawnMiniBoss")
local DebugAddCash = Remotes:WaitForChild("DebugAddCash")
local DebugResetWave = Remotes:WaitForChild("DebugResetWave")
local DebugToggleInvincibility = Remotes:WaitForChild("DebugToggleInvincibility")
local DebugInvincibilityChanged = Remotes:WaitForChild("DebugInvincibilityChanged")

-- Remotes existentes para notificaciones
local ShowNotification = Remotes:FindFirstChild("ShowNotification")

-- Cooldowns para evitar spam
local Cooldowns = {}
local COOLDOWN_TIME = 0.5 -- 0.5 segundos entre comandos

-------------------------------------------------------------------------
-- HELPERS
-------------------------------------------------------------------------

local function checkCooldown(userId: number): boolean
	local now = tick()
	local lastTime = Cooldowns[userId] or 0

	if now - lastTime < COOLDOWN_TIME then
		return false
	end

	Cooldowns[userId] = now
	return true
end

local function notify(player: Player, message: string)
	
	-- Solo logging - el cliente maneja el feedback visual
	print(string.format("[DEBUG] %s: %s", player.Name, message))
end

-------------------------------------------------------------------------
-- DEBUG COMMANDS
-------------------------------------------------------------------------

-- Helper: Auto-spawnea boss/mini-boss si la wave lo requiere
local function checkAndSpawnBoss(waveNum: number)
	local isBossWave = waveNum % 10 == 0
	local isMiniBossWave = (waveNum % 5 == 0) and not isBossWave

	if isBossWave then
		-- Spawn Boss completo
		task.delay(1, function()
			Events:BossMeteor(waveNum, true)
		end)
		return "BOSS"
	elseif isMiniBossWave then
		-- Spawn Mini-Boss
		task.delay(1, function()
			Events:BossMeteor(waveNum, false)
		end)
		return "MINI-BOSS"
	end

	return nil
end

-- SKIP WAVE: Salta al siguiente wave
DebugSkipWave.OnServerEvent:Connect(function(player: Player, skipAmount: number?)
	if not checkCooldown(player.UserId) then return end

	local skip = skipAmount or 1
	local newWave = CurrentWaveValue.Value + skip

	CurrentWaveValue.Value = newWave

	-- Auto-detectar y spawnear boss/mini-boss
	local bossType = checkAndSpawnBoss(newWave)
	if bossType then
		notify(player, string.format("? Wave %d - %s INCOMING!", newWave, bossType))
	else
		notify(player, string.format("? Saltando a Wave %d", newWave))
	end

	print(string.format("[DEBUG] %s saltÃ³ al wave %d%s", player.Name, newWave, bossType and (" (" .. bossType .. ")") or ""))
end)

-- JUMP TO WAVE: Salta a un wave especÃ­fico
DebugJumpToWave.OnServerEvent:Connect(function(player: Player, targetWave: number)
	if not checkCooldown(player.UserId) then return end

	if not targetWave or targetWave < 1 then
		notify(player, "? Wave invÃ¡lido")
		return
	end

	CurrentWaveValue.Value = targetWave

	-- Auto-detectar y spawnear boss/mini-boss
	local bossType = checkAndSpawnBoss(targetWave)
	if bossType then
		notify(player, string.format("?? Wave %d - %s INCOMING!", targetWave, bossType))
	else
		notify(player, string.format("?? Saltando a Wave %d", targetWave))
	end

	print(string.format("[DEBUG] %s saltÃ³ al wave %d%s", player.Name, targetWave, bossType and (" (" .. bossType .. ")") or ""))
end)

-- SPAWN BOSS: Spawnea un boss completo (4 fases)
DebugSpawnBoss.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	notify(player, "?? SPAWNING BOSS...")

	-- Usar el wave actual o un mÃºltiplo de 10
	local waveNum = CurrentWaveValue.Value
	if waveNum % 10 ~= 0 then
		waveNum = math.ceil(waveNum / 10) * 10
	end

	-- Llamar al BossMeteor con isFullBoss = true
	task.spawn(function()
		Events:BossMeteor(waveNum, true)
	end)

	print(string.format("[DEBUG] %s spawneÃ³ un BOSS (wave %d)", player.Name, waveNum))
end)

-- SPAWN MINI-BOSS: Spawnea un mini-boss (1 fase aleatoria)
DebugSpawnMiniBoss.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	notify(player, "?? SPAWNING MINI-BOSS...")

	-- Usar el wave actual o un mÃºltiplo de 5
	local waveNum = CurrentWaveValue.Value
	if waveNum % 5 ~= 0 then
		waveNum = math.ceil(waveNum / 5) * 5
	end

	-- Llamar al BossMeteor con isFullBoss = false
	task.spawn(function()
		Events:BossMeteor(waveNum, false)
	end)

	print(string.format("[DEBUG] %s spawneÃ³ un MINI-BOSS (wave %d)", player.Name, waveNum))
end)

-- ADD CASH: AÃ±ade dinero al jugador
DebugAddCash.OnServerEvent:Connect(function(player: Player, amount: number?)
	if not checkCooldown(player.UserId) then return end

	local cashToAdd = amount or 10000

	-- Obtener el state del jugador y modificar cash directamente
	local success, errorMsg = pcall(function()
		local state = Economy.GetState(player.UserId)
		if state then
			state.Cash = state.Cash + cashToAdd
			state.TotalEarned = state.TotalEarned + cashToAdd
		else
			error("Estado del jugador no encontrado")
		end
	end)

	if success then
		-- Formatear el nÃºmero para mostrar (simple)
		local formattedCash = tostring(cashToAdd)
		if cashToAdd >= 1000000 then
			formattedCash = string.format("%.1fM", cashToAdd / 1000000)
		elseif cashToAdd >= 1000 then
			formattedCash = string.format("%.1fK", cashToAdd / 1000)
		end

		notify(player, string.format("?? +$%s", formattedCash))
		print(string.format("[DEBUG] %s aÃ±adiÃ³ $%d", player.Name, cashToAdd))
	else
		notify(player, "? Error aÃ±adiendo dinero: " .. tostring(errorMsg))
		warn(string.format("[DEBUG] Error aÃ±adiendo cash a %s: %s", player.Name, tostring(errorMsg)))
	end
end)

-- RESET WAVE: Resetea a wave 1
DebugResetWave.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	CurrentWaveValue.Value = 1
	notify(player, "?? Wave reseteado a 1")

	print(string.format("[DEBUG] %s reseteÃ³ el wave a 1", player.Name))
end)

-- TOGGLE INVINCIBILITY: Activa/desactiva invencibilidad
DebugToggleInvincibility.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	-- Toggle invencibilidad
	local currentInvincible = Base.IsInvulnerable(player.UserId)
	local newInvincible = not currentInvincible

	Base.SetInvulnerable(player.UserId, newInvincible)

	-- Notificar al jugador
	if newInvincible then
		notify(player, "??? INVENCIBILIDAD ACTIVADA")
	else
		notify(player, "?? INVENCIBILIDAD DESACTIVADA")
	end

	-- Notificar al cliente para el feedback visual
	DebugInvincibilityChanged:FireClient(player, newInvincible)

	print(string.format("[DEBUG] %s %s la invencibilidad",
		player.Name,
		newInvincible and "activÃ³" or "desactivÃ³"))
end)

print("[DEBUG MANAGER] ? Sistema de debug cargado")
print("[DEBUG MANAGER] ?? Usa las teclas de debug en el cliente para controlar")