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

-- Esperar a que Knit esté disponible y listo
task.wait(5) -- Dar tiempo a KnitServer.lua para inicializar todos los servicios

local Knit = require(ReplicatedStorage.Knit)

-- Obtener servicios necesarios
local BaseSpawnerService
local success, err = pcall(function()
	BaseSpawnerService = Knit.GetService("BaseSpawnerService")
end)

if not success or not BaseSpawnerService then
	warn("[BaseAutoSpawner] ❌ Error: No se pudo obtener BaseSpawnerService")
	warn("[BaseAutoSpawner] Error:", err)
	return
end

print("[BaseAutoSpawner] ✅ BaseSpawnerService cargado correctamente")

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
	if Config.DEBUG_MODE then
		print(("[BaseAutoSpawner] 🎯 Spawneando base para %s..."):format(player.Name))
	end

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

	if Config.DEBUG_MODE then
		print(("[BaseAutoSpawner] ✅ Base spawneada exitosamente para %s"):format(player.Name))
		print(("[BaseAutoSpawner] 📊 Posición: %s"):format(tostring(baseData.Position)))
		print(("[BaseAutoSpawner] 📊 BuildZone Radio: 60 studs"):format())
		print(("[BaseAutoSpawner] 📊 SpawnZone Radio: 15 studs"):format())
	end

	return baseData
end

-------------------------------------------------------------------------
-- EVENTO PRINCIPAL: PlayerAdded
-------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
	-- Esperar a que el character se cargue
	player.CharacterAdded:Wait()

	-- Pequeño delay para asegurar que todos los sistemas estén listos
	task.wait(0.5)

	-- Spawnear base
	local baseData = spawnBaseForPlayer(player)

	if not baseData then
		warn(("[BaseAutoSpawner] ⚠️ No se pudo crear base para %s"):format(player.Name))
		return
	end

	-- Teleportar jugador a su base
	task.wait(0.5) -- Pequeño delay antes de teleportar
	teleportPlayerToBase(player, baseData.Position)
end)

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
