--!strict
--[[
	-----------------------------------------------------------------------
	POWERUP CONTROLLER CLIENT - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Controlador cliente para manejar eventos de powerups:
	? Recepción de notificaciones de activación/expiración
	? Sincronización con UI
	? Efectos de sonido
	? Logging y debugging

	-----------------------------------------------------------------------
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpActivated = Remotes:WaitForChild("PowerUpActivated") :: RemoteEvent
local PowerUpExpired = Remotes:WaitForChild("PowerUpExpired") :: RemoteEvent
local PowerUpCollected = Remotes:WaitForChild("PowerUpCollected") :: RemoteEvent

-- Estado local
local ActivePowerUps: {[string]: {StartTime: number, Duration: number}} = {}

-- -----------------------------------------------------------------------
-- EVENTOS DE POWERUPS
-- -----------------------------------------------------------------------

-- Activar powerup
PowerUpActivated.OnClientEvent:Connect(function(powerUpId: string, duration: number?)
	-- ? FIX: Validar que duration no sea nil
	local safeDuration = duration or 0

	if ActivePowerUps[powerUpId] then
		print(("[PowerUpController] ?? Reemplazando powerup existente: %s"):format(powerUpId))
	end

	ActivePowerUps[powerUpId] = {
		StartTime = tick(),
		Duration = safeDuration,
	}

	-- ? FIX: Usar safeDuration en el print para evitar nil
	print(("[PowerUpController] ? Powerup activado: %s (duración: %.1fs)"):format(powerUpId, safeDuration))
end)

-- Expirar powerup
PowerUpExpired.OnClientEvent:Connect(function(powerUpId: string)
	if ActivePowerUps[powerUpId] then
		ActivePowerUps[powerUpId] = nil
		print(("[PowerUpController] Expiró: %s"):format(powerUpId))
	else
		warn(("[PowerUpController] Intentó expirar powerup inexistente: %s"):format(powerUpId))
	end
end)

-- Powerup recogido
PowerUpCollected.OnClientEvent:Connect(function(powerUpId: string)
	print(("[PowerUpController] ?? Recogido: %s"):format(powerUpId))

	-- Aquí puedes agregar efectos de sonido:
	-- local sound = Instance.new("Sound")
	-- sound.SoundId = "rbxassetid://XXXXXX"
	-- sound.Parent = workspace
	-- sound:Play()
end)

-- -----------------------------------------------------------------------
-- UTILIDADES
-- -----------------------------------------------------------------------

-- Obtener powerups activos
function GetActivePowerUps(): {string}
	local active = {}
	for powerUpId, _ in pairs(ActivePowerUps) do
		table.insert(active, powerUpId)
	end
	return active
end

-- Verificar si un powerup está activo
function IsPowerUpActive(powerUpId: string): boolean
	return ActivePowerUps[powerUpId] ~= nil
end

-- Obtener tiempo restante de un powerup
function GetPowerUpTimeRemaining(powerUpId: string): number
	local data = ActivePowerUps[powerUpId]
	if not data then return 0 end

	local elapsed = tick() - data.StartTime
	local remaining = math.max(0, data.Duration - elapsed)
	return remaining
end

print("[PowerUpController] ? PowerUp Controller Client inicializado")