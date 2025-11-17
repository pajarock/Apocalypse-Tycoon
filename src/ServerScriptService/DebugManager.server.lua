--!strict
--[[
	═══════════════════════════════════════════════════════════════════════
	DEBUG MANAGER - Sistema completo de debug para testing
	═══════════════════════════════════════════════════════════════════════

	CONTROLES:
	- N: Skip al siguiente wave
	- Shift+N: Saltar +5 waves
	- B: Spawn Boss instantáneo
	- V: Spawn Mini-Boss instantáneo
	- C: Añadir $10,000
	- Shift+C: Añadir $100,000
	- Y: Reset a Wave 1
	- G: Toggle Invencibilidad (God Mode)
	- 1-9: Saltar a wave específico (10, 20, 30, etc.)

	═══════════════════════════════════════════════════════════════════════
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

print("[DEBUG MANAGER] 🛠️ Iniciando sistema de debug...")

-- Esperar a que Main.Server.lua cree los componentes necesarios
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CurrentWaveValue = ReplicatedStorage:WaitForChild("CurrentWave", 10)

-- Módulos
local Config = require(ServerStorage.Config.Config)
local Events = require(ServerScriptService.EventManager)

-- Esperar a que Economy y DataStore estén cargados
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

--═══════════════════════════════════════════════════════════════════════
-- HELPERS
--═══════════════════════════════════════════════════════════════════════

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
	if ShowNotification then
		ShowNotification:FireClient(player, message, 3)
	end
	print(string.format("[DEBUG] %s: %s", player.Name, message))
end

--═══════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
--═══════════════════════════════════════════════════════════════════════

-- SKIP WAVE: Salta al siguiente wave
DebugSkipWave.OnServerEvent:Connect(function(player: Player, skipAmount: number?)
	if not checkCooldown(player.UserId) then return end

	local skip = skipAmount or 1
	local newWave = CurrentWaveValue.Value + skip

	CurrentWaveValue.Value = newWave
	notify(player, string.format("⏩ Saltando a Wave %d", newWave))

	print(string.format("[DEBUG] %s saltó al wave %d", player.Name, newWave))
end)

-- JUMP TO WAVE: Salta a un wave específico
DebugJumpToWave.OnServerEvent:Connect(function(player: Player, targetWave: number)
	if not checkCooldown(player.UserId) then return end

	if not targetWave or targetWave < 1 then
		notify(player, "❌ Wave inválido")
		return
	end

	CurrentWaveValue.Value = targetWave
	notify(player, string.format("🎯 Saltando a Wave %d", targetWave))

	print(string.format("[DEBUG] %s saltó al wave %d", player.Name, targetWave))
end)

-- SPAWN BOSS: Spawnea un boss completo (4 fases)
DebugSpawnBoss.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	notify(player, "💀 SPAWNING BOSS...")

	-- Usar el wave actual o un múltiplo de 10
	local waveNum = CurrentWaveValue.Value
	if waveNum % 10 ~= 0 then
		waveNum = math.ceil(waveNum / 10) * 10
	end

	-- Llamar al BossMeteor con isFullBoss = true
	task.spawn(function()
		Events:BossMeteor(waveNum, true)
	end)

	print(string.format("[DEBUG] %s spawneó un BOSS (wave %d)", player.Name, waveNum))
end)

-- SPAWN MINI-BOSS: Spawnea un mini-boss (1 fase aleatoria)
DebugSpawnMiniBoss.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	notify(player, "👹 SPAWNING MINI-BOSS...")

	-- Usar el wave actual o un múltiplo de 5
	local waveNum = CurrentWaveValue.Value
	if waveNum % 5 ~= 0 then
		waveNum = math.ceil(waveNum / 5) * 5
	end

	-- Llamar al BossMeteor con isFullBoss = false
	task.spawn(function()
		Events:BossMeteor(waveNum, false)
	end)

	print(string.format("[DEBUG] %s spawneó un MINI-BOSS (wave %d)", player.Name, waveNum))
end)

-- ADD CASH: Añade dinero al jugador
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
		-- Formatear el número para mostrar (simple)
		local formattedCash = tostring(cashToAdd)
		if cashToAdd >= 1000000 then
			formattedCash = string.format("%.1fM", cashToAdd / 1000000)
		elseif cashToAdd >= 1000 then
			formattedCash = string.format("%.1fK", cashToAdd / 1000)
		end

		notify(player, string.format("💰 +$%s", formattedCash))
		print(string.format("[DEBUG] %s añadió $%d", player.Name, cashToAdd))
	else
		notify(player, "❌ Error añadiendo dinero: " .. tostring(errorMsg))
		warn(string.format("[DEBUG] Error añadiendo cash a %s: %s", player.Name, tostring(errorMsg)))
	end
end)

-- RESET WAVE: Resetea a wave 1
DebugResetWave.OnServerEvent:Connect(function(player: Player)
	if not checkCooldown(player.UserId) then return end

	CurrentWaveValue.Value = 1
	notify(player, "🔄 Wave reseteado a 1")

	print(string.format("[DEBUG] %s reseteó el wave a 1", player.Name))
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
		notify(player, "🛡️ INVENCIBILIDAD ACTIVADA")
	else
		notify(player, "⚔️ INVENCIBILIDAD DESACTIVADA")
	end

	-- Notificar al cliente para el feedback visual
	DebugInvincibilityChanged:FireClient(player, newInvincible)

	print(string.format("[DEBUG] %s %s la invencibilidad",
		player.Name,
		newInvincible and "activó" or "desactivó"))
end)

print("[DEBUG MANAGER] ✅ Sistema de debug cargado")
print("[DEBUG MANAGER] 📝 Usa las teclas de debug en el cliente para controlar")
