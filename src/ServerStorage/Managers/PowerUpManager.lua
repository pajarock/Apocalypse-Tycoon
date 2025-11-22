--!strict
--[[
	-----------------------------------------------------------------------
	POWERUP MANAGER ADAPTER - Apocalypse Tycoon
	-----------------------------------------------------------------------

	?? ESTE ES UN ADAPTER/WRAPPER PARA COMPATIBILIDAD CON CÃÂDIGO VIEJO

	El sistema real de powerups estÃÂ¡ en:
	- ServerScriptService.PowerUpModule (sistema principal)
	- ServerStorage.Config.PowerUpConfig (configuraciÃÂ³n)

	Este archivo solo existe para mantener compatibilidad con cÃÂ³digo que
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
-- ADAPTER API (Para compatibilidad con cÃÂ³digo viejo)
-- -----------------------------------------------------------------------

local PowerUpManager = {}

-- ? MÃÂTODO QUE EL CÃÂDIGO VIEJO ESPERA
function PowerUpManager:GetRandomPowerUp(waveType: string?): string?
	local config = getPowerUpConfig()
	if not config then
		warn("[PowerUpManager] No se pudo cargar PowerUpConfig")
		return nil
	end

	-- Determinar rarity segÃÂºn wave type
	local waveTypeStr = waveType or "Normal"
	local rarity = config.GetRandomRarity(waveTypeStr)

	-- Obtener powerup aleatorio de esa rarity
	local powerUpId = config.GetRandomPowerUpByRarity(rarity)

	return powerUpId
end

-- Spawnear powerup aleatorio cerca de un jugador
function PowerUpManager:SpawnRandomPowerUp(userId: number, waveType: string?)
	-- ? VALIDACIÃÂN: Verificar que userId sea un nÃÂºmero
	if type(userId) ~= "number" then
		warn(("[PowerUpManager] ? SpawnRandomPowerUp recibiÃÂ³ userId invÃÂ¡lido: %s (tipo: %s)"):format(
			tostring(userId), type(userId)
			))
		warn("[PowerUpManager] ?? Tip: AsegÃÂºrate de pasar player.UserId, no player o position")
		return
	end

	local module = getPowerUpModule()
	if not module then
		warn("[PowerUpManager] No se pudo cargar PowerUpModule")
		return
	end

	-- Delegar al mÃÂ³dulo real
	module.SpawnPowerUpForPlayer(userId, waveType or "Normal")
end

-- Spawnear powerup especÃÂ­fico
function PowerUpManager:SpawnPowerUp(userId: number, powerUpId: string, position: Vector3?)
	local module = getPowerUpModule()
	if not module then
		warn("[PowerUpManager] No se pudo cargar PowerUpModule")
		return
	end

	if position then
		-- Spawn en posiciÃÂ³n especÃÂ­fica
		module.SpawnPowerUpInWorld(powerUpId, position)
	else
		-- Activar directamente (sin spawn fÃÂ­sico)
		module.ActivatePowerUp(userId, powerUpId)
	end
end

-- Verificar si jugador tiene powerup activo
function PowerUpManager:HasActivePowerUp(userId: number, powerUpId: string): boolean
	local module = getPowerUpModule()
	if not module then return false end

	-- Esto requiere acceso al estado interno, por ahora retornar false
	-- El mÃÂ³dulo real maneja esto internamente
	return false
end

-- Obtener todos los powerups activos de un jugador
function PowerUpManager:GetActivePowerUps(userId: number): {string}
	-- El mÃÂ³dulo real maneja esto internamente
	return {}
end

-- -----------------------------------------------------------------------
-- MÃÂTODOS ADICIONALES PARA EL NUEVO SISTEMA
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

-- Obtener definiciÃÂ³n de powerup
function PowerUpManager:GetPowerUpDefinition(powerUpId: string): any?
	local config = getPowerUpConfig()
	if not config then return nil end

	return config.PowerUps[powerUpId]
end

print("[PowerUpManager] ? Sistema de power-ups cargado (ADAPTER MODE)")

return PowerUpManager