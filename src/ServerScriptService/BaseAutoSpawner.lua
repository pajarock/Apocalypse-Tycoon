--!strict
--[[
	BASE AUTO SPAWNER - Sistema Knit

	Este script maneja el spawn automático de bases usando el sistema Knit.
	Se activa cuando Config.USE_KNIT_BASES = true

	FUNCIONALIDAD:
	- Spawnea bases automáticamente cuando un jugador se une
	- Teleporta jugadores a su base
	- Manejo robusto de errores

	IMPORTANTE:
	- Este script REEMPLAZA la función assignBase() del sistema legacy
	- Solo se ejecuta si Config.USE_KNIT_BASES = true

	AUTOR: Apocalypse Tycoon Team
	VERSIÓN: 1.0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Configuración
local Config = require(ServerStorage.Config.Config)

-- Verificar si debemos ejecutar (flag de migración)
if not Config.USE_KNIT_BASES then
	print("[BaseAutoSpawner] ⏸️ Sistema Knit desactivado (USE_KNIT_BASES = false)")
	return -- No ejecutar nada si el flag está en false
end

print("[BaseAutoSpawner] 🔄 Esperando a que Knit esté listo...")

local Knit = require(ReplicatedStorage.Knit)

-- Obtener servicios necesarios con reintentos
local BaseSpawnerService
local maxAttempts = 10
local attempt = 0

while not BaseSpawnerService and attempt < maxAttempts do
	attempt += 1
	local success, result = pcall(function()
		return Knit.GetService("BaseSpawnerService")
	end)

	if success and result then
		BaseSpawnerService = result
		break
	else
		if Config.DEBUG_MODE then
			print(("[BaseAutoSpawner] ⏳ Intento %d/%d - Esperando a BaseSpawnerService..."):format(attempt, maxAttempts))
		end
		task.wait(0.2) -- Esperar 200ms antes de reintentar
	end
end

if not BaseSpawnerService then
	warn("[BaseAutoSpawner] ❌ Error: No se pudo obtener BaseSpawnerService después de múltiples intentos")
	return
end

print("[BaseAutoSpawner] ✅ BaseSpawnerService cargado correctamente (intento " .. attempt .. ")")

-------------------------------------------------------------------------
-- FUNCIONES AUXILIARES
-------------------------------------------------------------------------

-- Teleportar jugador a su base
local function teleportPlayerToBase(player: Player, basePosition: Vector3)
	-- Esperar a que el personaje cargue
	local character = player.Character or player.CharacterAdded:Wait()

	-- Esperar a HumanoidRootPart
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

	if humanoidRootPart then
		-- Teleportar 5 studs arriba de la base para evitar colisiones
		humanoidRootPart.CFrame = CFrame.new(basePosition + Vector3.new(0, 5, 0))

		if Config.DEBUG_MODE then
			print(("[BaseAutoSpawner] 📍 %s teleportado a posición: %s"):format(
				player.Name,
				tostring(basePosition)
			))
		end
	else
		warn(("[BaseAutoSpawner] ⚠️ No se encontró HumanoidRootPart para %s"):format(player.Name))
	end
end

-- Spawn de base para un jugador
local function spawnBaseForPlayer(player: Player)
	print(("[BaseAutoSpawner] 🎯 Spawneando base para %s (userId: %d)..."):format(player.Name, player.UserId))

	-- Spawnear base usando el servicio Knit
	local success, baseData = pcall(function()
		return BaseSpawnerService:SpawnBase(player.UserId, player.Name)
	end)

	if not success then
		warn(("[BaseAutoSpawner] ❌ Error al spawnear base para %s"):format(player.Name))
		warn(("[BaseAutoSpawner] Error: %s"):format(tostring(baseData)))
		return nil
	end

	if not baseData then
		warn(("[BaseAutoSpawner] ❌ BaseSpawnerService retornó nil para %s"):format(player.Name))
		return nil
	end

	print(("[BaseAutoSpawner] ✅ Base spawneada exitosamente para %s"):format(player.Name))
	print(("[BaseAutoSpawner] 📊 Posición: %s"):format(tostring(baseData.Position)))
	print(("[BaseAutoSpawner] 📊 UserId: %d"):format(player.UserId))

	return baseData
end

-------------------------------------------------------------------------
-- EVENTO PRINCIPAL: PlayerAdded
-------------------------------------------------------------------------

local function handlePlayerJoin(player: Player)
	if Config.DEBUG_MODE then
		print(("[BaseAutoSpawner] 🎮 Procesando jugador: %s"):format(player.Name))
	end

	-- Esperar a que el character se cargue (instantáneo si ya está cargado)
	local character = player.Character or player.CharacterAdded:Wait()

	-- Spawnear base (sin delays innecesarios)
	local baseData = spawnBaseForPlayer(player)

	if not baseData then
		warn(("[BaseAutoSpawner] ⚠️ No se pudo crear base para %s"):format(player.Name))
		return
	end

	-- Teleportar jugador a su base inmediatamente
	teleportPlayerToBase(player, baseData.Position)
end

-- Conectar evento para nuevos jugadores
Players.PlayerAdded:Connect(handlePlayerJoin)

-- Procesar jugadores que ya están en el juego (importante para Studio)
for _, player in Players:GetPlayers() do
	if Config.DEBUG_MODE then
		print(("[BaseAutoSpawner] 🔄 Procesando jugador existente: %s"):format(player.Name))
	end
	task.spawn(function()
		handlePlayerJoin(player)
	end)
end

-------------------------------------------------------------------------
-- INICIALIZACIÓN
-------------------------------------------------------------------------

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🏗️  BASE AUTO SPAWNER - SISTEMA KNIT ACTIVO")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[BaseAutoSpawner] ✅ Sistema de spawn automático iniciado")
print("[BaseAutoSpawner] 📌 Modo: Knit (Config.USE_KNIT_BASES = true)")
print("[BaseAutoSpawner] 📌 Service: BaseSpawnerService")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
