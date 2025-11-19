--!strict
--[[
	-----------------------------------------------------------------------
	POWERUP MANAGER ADAPTER - Apocalypse Tycoon
	-----------------------------------------------------------------------

	?? ESTE ES UN ADAPTER/WRAPPER PARA COMPATIBILIDAD CON CÓDIGO VIEJO

	El sistema real de powerups está en:
	- ServerScriptService.PowerUpModule (sistema principal)
	- ServerStorage.Config.PowerUpConfig (configuración)

	Este archivo solo existe para mantener compatibilidad con código que
	espera ServerStorage.Managers.PowerUpManager

	-----------------------------------------------------------------------
--]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- Lazy load del sistema real de powerups
local PowerUpModule = nil
local PowerUpConfig = nil

local function getPowerUpModule()
	if not PowerUpModule then
		local ok, mod = pcall(function()
			return require(ServerScriptService:WaitForChild("PowerUpModule"))
		end)
		if ok then
			PowerUpModule = mod
		end
	end
	return PowerUpModule
end

local function getPowerUpConfig()
	if not PowerUpConfig then
		local ok, mod = pcall(function()
			return require(ServerStorage.Config:WaitForChild("PowerUpConfig"))
		end)
		if ok then
			PowerUpConfig = mod
		end
	end
	return PowerUpConfig
end

-- -----------------------------------------------------------------------
-- ADAPTER API (Para compatibilidad con código viejo)
-- -----------------------------------------------------------------------

local PowerUpManager = {}

-- ? MÉTODO QUE EL CÓDIGO VIEJO ESPERA
function PowerUpManager:GetRandomPowerUp(waveType: string?): string?
	local config = getPowerUpConfig()
	if not config then
		warn("[PowerUpManager] No se pudo cargar PowerUpConfig")
		return nil
	end

	-- Determinar rarity según wave type
	local waveTypeStr = waveType or "Normal"
	local rarity = config.GetRandomRarity(waveTypeStr)

	-- Obtener powerup aleatorio de esa rarity
	local powerUpId = config.GetRandomPowerUpByRarity(rarity)

	return powerUpId
end

-- Spawnear powerup aleatorio cerca de un jugador
function PowerUpManager:SpawnRandomPowerUp(userId: number, waveType: string?)
	-- ? VALIDACIÓN: Verificar que userId sea un número
	if type(userId) ~= "number" then
		warn(("[PowerUpManager] ? SpawnRandomPowerUp recibió userId inválido: %s (tipo: %s)"):format(
			tostring(userId), type(userId)
			))
		warn("[PowerUpManager] ?? Tip: Asegúrate de pasar player.UserId, no player o position")
		return
	end

	local module = getPowerUpModule()
	if not module then
		warn("[PowerUpManager] No se pudo cargar PowerUpModule")
		return
	end

	-- Delegar al módulo real
	module.SpawnPowerUpForPlayer(userId, waveType or "Normal")
end

-- Spawnear powerup específico
function PowerUpManager:SpawnPowerUp(userId: number, powerUpId: string, position: Vector3?)
	local module = getPowerUpModule()
	if not module then
		warn("[PowerUpManager] No se pudo cargar PowerUpModule")
		return
	end

	if position then
		-- Spawn en posición específica
		module.SpawnPowerUpInWorld(powerUpId, position)
	else
		-- Activar directamente (sin spawn físico)
		module.ActivatePowerUp(userId, powerUpId)
	end
end

-- Verificar si jugador tiene powerup activo
function PowerUpManager:HasActivePowerUp(userId: number, powerUpId: string): boolean
	local module = getPowerUpModule()
	if not module then return false end

	-- Esto requiere acceso al estado interno, por ahora retornar false
	-- El módulo real maneja esto internamente
	return false
end

-- Obtener todos los powerups activos de un jugador
function PowerUpManager:GetActivePowerUps(userId: number): {string}
	-- El módulo real maneja esto internamente
	return {}
end

-- -----------------------------------------------------------------------
-- MÉTODOS ADICIONALES PARA EL NUEVO SISTEMA
-- -----------------------------------------------------------------------

-- Inicializar jugador
function PowerUpManager:InitPlayer(userId: number)
	local module = getPowerUpModule()
	if module and module.InitPlayer then
		module.InitPlayer(userId)
	end
end

-- Cleanup jugador
function PowerUpManager:CleanupPlayer(userId: number)
	local module = getPowerUpModule()
	if module and module.CleanupPlayer then
		module.CleanupPlayer(userId)
	end
end

-- -----------------------------------------------------------------------
-- HELPERS
-- -----------------------------------------------------------------------

-- Obtener lista de powerups disponibles
function PowerUpManager:GetAvailablePowerUps(): {string}
	local config = getPowerUpConfig()
	if not config then return {} end

	local list = {}
	for id, _ in pairs(config.PowerUps) do
		table.insert(list, id)
	end
	return list
end

-- Obtener definición de powerup
function PowerUpManager:GetPowerUpDefinition(powerUpId: string): any?
	local config = getPowerUpConfig()
	if not config then return nil end

	return config.PowerUps[powerUpId]
end

print("[PowerUpManager] ? Sistema de power-ups cargado (ADAPTER MODE)")

return PowerUpManager