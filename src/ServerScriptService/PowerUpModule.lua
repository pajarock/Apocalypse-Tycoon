--!strict
--[[
	═══════════════════════════════════════════════════════════════════════
	POWERUP MODULE - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema completo de power-ups con:
	✓ Gestión de powerups activos por jugador
	✓ Spawning de powerups en el mundo
	✓ Sistema de pickup visual
	✓ Efectos VFX para cada powerup
	✓ Integración con BaseModule y EconomyModule
	✓ Sistema de stacking y cooldowns

	═══════════════════════════════════════════════════════════════════════
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Módulos
local PowerUpConfig = require(ServerStorage.Config.PowerUpConfig)
local Config = require(ServerStorage.Config.Config)

-- Referencias a otros módulos (se inyectarán después)
local BaseModule = nil
local EconomyModule = nil

local DEBUG = Config.DEBUG_MODE or false

-- ═══════════════════════════════════════════════════════════════════════
-- TIPOS
-- ═══════════════════════════════════════════════════════════════════════

export type ActivePowerUp = {
	PowerUpId: string,
	StartTime: number,
	Duration: number,
	Data: any?, -- Data específica del powerup
}

-- ═══════════════════════════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════════════════════════

local PowerUpModule = {}

-- [userId] = {ActivePowerUps: {ActivePowerUp}, Cooldowns: {[powerUpId]: endTime}}
local PlayerPowerUps: {[number]: any} = {}

-- Tracking de efectos especiales
local DashCooldownOverride: {[number]: boolean} = {} -- Para SuperDash
local IncomeBoostMultipliers: {[number]: number} = {} -- Para IncomeBoost
local BaseShieldActive: {[number]: boolean} = {} -- Para BaseShield
local CriticalParryActive: {[number]: boolean} = {} -- Para CriticalParry
local MeteorJammerActive: {[number]: number} = {} -- userId = endTime

-- Tracking de drones
local ActiveDrones: {[number]: {Model}} = {}

-- ═══════════════════════════════════════════════════════════════════════
-- REMOTES
-- ═══════════════════════════════════════════════════════════════════════

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Crear remotes si no existen
local function getOrCreateRemote(name: string, remoteType: string): RemoteEvent | RemoteFunction
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		if remoteType == "Event" then
			remote = Instance.new("RemoteEvent")
		else
			remote = Instance.new("RemoteFunction")
		end
		remote.Name = name
		remote.Parent = Remotes
		if DEBUG then
			print(("[PowerUpModule] Creado remote: %s"):format(name))
		end
	end
	return remote
end

local PowerUpActivated = getOrCreateRemote("PowerUpActivated", "Event") :: RemoteEvent
local PowerUpExpired = getOrCreateRemote("PowerUpExpired", "Event") :: RemoteEvent
local PowerUpSpawned = getOrCreateRemote("PowerUpSpawned", "Event") :: RemoteEvent
local PowerUpCollected = getOrCreateRemote("PowerUpCollected", "Event") :: RemoteEvent

-- ═══════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════

local function ensurePlayerState(userId: number)
	if not PlayerPowerUps[userId] then
		PlayerPowerUps[userId] = {
			ActivePowerUps = {},
			Cooldowns = {},
		}
	end
end

local function getPlayer(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE SPAWNING DE POWERUPS
-- ═══════════════════════════════════════════════════════════════════════

-- Crear powerup físico en el mundo
function PowerUpModule.SpawnPowerUpInWorld(powerUpId: string, position: Vector3): Model?
	local def = PowerUpConfig.PowerUps[powerUpId]
	if not def then
		warn(("[PowerUpModule] PowerUp inválido: %s"):format(powerUpId))
		return nil
	end

	-- Crear modelo de powerup
	local powerUpModel = Instance.new("Model")
	powerUpModel.Name = "PowerUp_" .. powerUpId
	powerUpModel:SetAttribute("PowerUpId", powerUpId)

	-- Base del powerup (parte física)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 4, 4)
	base.Position = position
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Neon
	base.Color = def.Color
	base.Transparency = 0.3
	base.Parent = powerUpModel

	-- Agregar forma especial
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = base

	-- Icono del powerup (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 200)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = base

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.fromScale(1, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Text = def.Icon
	iconLabel.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.3)
	nameLabel.Position = UDim2.fromScale(0, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = def.Color
	nameLabel.Text = def.Name
	nameLabel.Parent = billboard

	-- Partículas
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(def.Color)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 20
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.LightEmission = 1
	particles.Parent = base

	-- Luz
	local light = Instance.new("PointLight")
	light.Color = def.Color
	light.Brightness = 2
	light.Range = 20
	light.Parent = base

	-- Animación de flotación y rotación
	task.spawn(function()
		local startY = position.Y
		local t = 0
		while base and base.Parent do
			t += 0.016 -- ~60 FPS
			local offset = math.sin(t * 2) * 1 -- Oscilación de 1 stud
			base.CFrame = CFrame.new(position.X, startY + offset, position.Z)
				* CFrame.Angles(0, t, 0) -- Rotación continua
			task.wait(0.016)
		end
	end)

	powerUpModel.PrimaryPart = base
	powerUpModel.Parent = workspace

	-- Detectar colisión con jugador
	base.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Recoger powerup
		PowerUpModule.CollectPowerUp(player.UserId, powerUpId)
		powerUpModel:Destroy()
	end)

	-- Auto-destruir después de 30 segundos
	Debris:AddItem(powerUpModel, 30)

	if DEBUG then
		print(("[PowerUpModule] PowerUp spawneado: %s en %s"):format(powerUpId, tostring(position)))
	end

	-- Notificar a clientes
	PowerUpSpawned:FireAllClients(powerUpId, position)

	return powerUpModel
end

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE COLECCIÓN Y ACTIVACIÓN
-- ═══════════════════════════════════════════════════════════════════════

function PowerUpModule.CollectPowerUp(userId: number, powerUpId: string)
	ensurePlayerState(userId)

	local def = PowerUpConfig.PowerUps[powerUpId]
	if not def then
		warn(("[PowerUpModule] PowerUp inválido: %s"):format(powerUpId))
		return
	end

	local player = getPlayer(userId)
	if not player then return end

	-- Verificar cooldown
	local state = PlayerPowerUps[userId]
	if state.Cooldowns[powerUpId] and tick() < state.Cooldowns[powerUpId] then
		if DEBUG then
			print(("[PowerUpModule] PowerUp en cooldown: %s para userId %d"):format(powerUpId, userId))
		end
		return
	end

	-- Activar powerup
	PowerUpModule.ActivatePowerUp(userId, powerUpId)

	-- Notificar cliente
	PowerUpCollected:FireClient(player, powerUpId)

	if DEBUG then
		print(("[PowerUpModule] PowerUp recogido: %s por userId %d"):format(powerUpId, userId))
	end
end

function PowerUpModule.ActivatePowerUp(userId: number, powerUpId: string)
	ensurePlayerState(userId)

	local def = PowerUpConfig.PowerUps[powerUpId]
	if not def then return end

	local duration = PowerUpConfig.GetRandomDuration(powerUpId)

	-- Crear entrada de powerup activo
	local activePowerUp: ActivePowerUp = {
		PowerUpId = powerUpId,
		StartTime = tick(),
		Duration = duration,
		Data = {},
	}

	table.insert(PlayerPowerUps[userId].ActivePowerUps, activePowerUp)

	-- Llamar función de activación específica
	if def.OnActivate then
		local activateFunc = PowerUpModule[def.OnActivate]
		if activateFunc then
			activateFunc(userId, activePowerUp)
		end
	end

	-- Notificar cliente
	local player = getPlayer(userId)
	if player then
		PowerUpActivated:FireClient(player, powerUpId, duration)
	end

	-- Programar expiración
	if duration > 0 then
		task.delay(duration, function()
			PowerUpModule.ExpirePowerUp(userId, powerUpId)
		end)
	end

	if DEBUG then
		print(("[PowerUpModule] PowerUp activado: %s para userId %d (duración: %.1fs)"):format(
			powerUpId, userId, duration
		))
	end
end

function PowerUpModule.ExpirePowerUp(userId: number, powerUpId: string)
	if not PlayerPowerUps[userId] then return end

	local state = PlayerPowerUps[userId]

	-- Buscar y remover powerup activo
	for i, powerUp in ipairs(state.ActivePowerUps) do
		if powerUp.PowerUpId == powerUpId then
			table.remove(state.ActivePowerUps, i)
			break
		end
	end

	-- Llamar función de limpieza específica
	local def = PowerUpConfig.PowerUps[powerUpId]
	if def and def.OnDeactivate then
		local deactivateFunc = PowerUpModule[def.OnDeactivate]
		if deactivateFunc then
			deactivateFunc(userId)
		end
	end

	-- Cleanup específico por powerup
	if powerUpId == "SuperDash" then
		DashCooldownOverride[userId] = nil
	elseif powerUpId == "IncomeBoost" then
		IncomeBoostMultipliers[userId] = nil
	elseif powerUpId == "MeteorJammer" then
		MeteorJammerActive[userId] = nil
	end

	-- Notificar cliente
	local player = getPlayer(userId)
	if player then
		PowerUpExpired:FireClient(player, powerUpId)
	end

	if DEBUG then
		print(("[PowerUpModule] PowerUp expirado: %s para userId %d"):format(powerUpId, userId))
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- IMPLEMENTACIÓN DE POWERUPS ESPECÍFICOS
-- ═══════════════════════════════════════════════════════════════════════

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1. GOD SHIELD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateGodShield(userId: number, powerUp: ActivePowerUp)
	if not BaseModule then return end

	BaseModule.SetInvulnerable(userId, true, powerUp.Duration)

	if DEBUG then
		print(("[PowerUpModule] God Shield activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2. DOUBLE DAMAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateDoubleDamage(userId: number, powerUp: ActivePowerUp)
	-- Este se maneja en el cliente/sistema de armas
	-- Aquí solo guardamos que está activo
	powerUp.Data.DamageMultiplier = 2.0

	if DEBUG then
		print(("[PowerUpModule] Double Damage activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3. SUPER DASH
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateSuperDash(userId: number, powerUp: ActivePowerUp)
	DashCooldownOverride[userId] = true

	if DEBUG then
		print(("[PowerUpModule] Super Dash activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4. FULL HEAL
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateFullHeal(userId: number, powerUp: ActivePowerUp)
	if not BaseModule then return end

	local maxHP = BaseModule.GetMaxHP(userId)
	BaseModule.SetHP(userId, maxHP)

	if DEBUG then
		print(("[PowerUpModule] Full Heal activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5. MINI DRONE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateMiniDrone(userId: number, powerUp: ActivePowerUp)
	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local character = player.Character
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Crear dron
	local drone = Instance.new("Part")
	drone.Name = "MiniDrone"
	drone.Size = Vector3.new(2, 2, 2)
	drone.Material = Enum.Material.Neon
	drone.Color = Color3.fromRGB(150, 150, 255)
	drone.CanCollide = false
	drone.Anchored = false
	drone.CFrame = humanoidRootPart.CFrame + Vector3.new(0, 5, 0)

	-- Hacer que flote
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPosition.P = 10000
	bodyPosition.Parent = drone

	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
	bodyGyro.P = 10000
	bodyGyro.Parent = drone

	-- Efectos visuales
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 150, 255)
	light.Brightness = 2
	light.Range = 15
	light.Parent = drone

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(150, 150, 255))
	particles.Size = NumberSequence.new(0.5)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 20
	particles.Speed = NumberRange.new(2, 4)
	particles.LightEmission = 1
	particles.Parent = drone

	drone.Parent = workspace

	-- Guardar referencia
	if not ActiveDrones[userId] then
		ActiveDrones[userId] = {}
	end
	table.insert(ActiveDrones[userId], drone)

	powerUp.Data.Drone = drone
	powerUp.Data.InterceptsRemaining = math.random(1, 2)

	-- Animar dron para orbitar alrededor del jugador
	task.spawn(function()
		local angle = 0
		local radius = 10
		while drone and drone.Parent and humanoidRootPart and humanoidRootPart.Parent do
			angle += 0.05
			local offsetX = math.cos(angle) * radius
			local offsetZ = math.sin(angle) * radius
			local targetPos = humanoidRootPart.Position + Vector3.new(offsetX, 5, offsetZ)

			bodyPosition.Position = targetPos
			bodyGyro.CFrame = CFrame.new(drone.Position, humanoidRootPart.Position)

			task.wait(0.016)
		end
	end)

	-- Auto-destruir después de la duración
	task.delay(powerUp.Duration, function()
		if drone and drone.Parent then
			drone:Destroy()
		end
	end)

	if DEBUG then
		print(("[PowerUpModule] Mini Drone activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6. SPEED BOOST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateSpeedBoost(userId: number, powerUp: ActivePowerUp)
	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then return end

	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = originalSpeed * 2

	powerUp.Data.OriginalSpeed = originalSpeed

	-- Restaurar después de la duración
	task.delay(powerUp.Duration, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalSpeed
		end
	end)

	if DEBUG then
		print(("[PowerUpModule] Speed Boost activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 7. BASE SHIELD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateBaseShield(userId: number, powerUp: ActivePowerUp)
	BaseShieldActive[userId] = true

	if DEBUG then
		print(("[PowerUpModule] Base Shield activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 8. METEOR JAMMER
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateMeteorJammer(userId: number, powerUp: ActivePowerUp)
	MeteorJammerActive[userId] = tick() + powerUp.Duration

	if DEBUG then
		print(("[PowerUpModule] Meteor Jammer activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 9. DEFENSIVE BURST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateDefensiveBurst(userId: number, powerUp: ActivePowerUp)
	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local position = humanoidRootPart.Position

	-- Crear explosión visual
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 100
	explosion.BlastPressure = 0 -- No empujar jugadores
	explosion.Parent = workspace

	-- Buscar y destruir meteoritos cercanos
	local meteorsDestroyed = 0
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name:match("Meteor") then
			local distance = (obj.Position - position).Magnitude
			if distance <= 100 then
				obj:Destroy()
				meteorsDestroyed += 1
			end
		end
	end

	if DEBUG then
		print(("[PowerUpModule] Defensive Burst activado para userId %d - %d meteoritos destruidos"):format(
			userId, meteorsDestroyed
		))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 10. CRITICAL PARRY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateCriticalParry(userId: number, powerUp: ActivePowerUp)
	CriticalParryActive[userId] = true

	if DEBUG then
		print(("[PowerUpModule] Critical Parry activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 11. ULTRA CHARGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateUltraCharge(userId: number, powerUp: ActivePowerUp)
	-- Resetear todos los cooldowns
	if PlayerPowerUps[userId] then
		PlayerPowerUps[userId].Cooldowns = {}
	end

	-- 50% chance de dar un powerup adicional
	if math.random() <= 0.5 then
		local rarityRoll = PowerUpConfig.GetRandomRarity("Normal")
		local bonusPowerUp = PowerUpConfig.GetRandomPowerUpByRarity(rarityRoll)
		if bonusPowerUp then
			task.delay(0.5, function()
				PowerUpModule.ActivatePowerUp(userId, bonusPowerUp)
			end)
		end
	end

	if DEBUG then
		print(("[PowerUpModule] Ultra Charge activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 12. EGG CATALYST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateEggCatalyst(userId: number, powerUp: ActivePowerUp)
	-- Este se maneja en el sistema de rewards de waves
	powerUp.Data.EggChanceBonus = 0.25

	if DEBUG then
		print(("[PowerUpModule] Egg Catalyst activado para userId %d"):format(userId))
	end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 13. INCOME BOOST
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
function PowerUpModule.ActivateIncomeBoost(userId: number, powerUp: ActivePowerUp)
	IncomeBoostMultipliers[userId] = 1.3 -- +30%

	if DEBUG then
		print(("[PowerUpModule] Income Boost activado para userId %d"):format(userId))
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- GETTERS PARA OTROS MÓDULOS
-- ═══════════════════════════════════════════════════════════════════════

-- Verificar si SuperDash está activo (para sistema de dash)
function PowerUpModule.IsSuperDashActive(userId: number): boolean
	return DashCooldownOverride[userId] == true
end

-- Obtener multiplier de income boost (para EconomyModule)
function PowerUpModule.GetIncomeMultiplier(userId: number): number
	return IncomeBoostMultipliers[userId] or 1.0
end

-- Verificar si BaseShield puede bloquear daño
function PowerUpModule.TryUseBaseShield(userId: number): boolean
	if BaseShieldActive[userId] then
		BaseShieldActive[userId] = nil -- Consumir shield
		PowerUpModule.ExpirePowerUp(userId, "BaseShield")
		return true
	end
	return false
end

-- Verificar si Critical Parry puede activarse
function PowerUpModule.TryUseCriticalParry(userId: number, meteorPosition: Vector3): boolean
	if CriticalParryActive[userId] then
		CriticalParryActive[userId] = nil
		PowerUpModule.ExpirePowerUp(userId, "CriticalParry")

		-- Crear explosión en la posición del meteorito
		local explosion = Instance.new("Explosion")
		explosion.Position = meteorPosition
		explosion.BlastRadius = 80
		explosion.BlastPressure = 0
		explosion.Parent = workspace

		-- Destruir meteoritos cercanos
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name:match("Meteor") then
				local distance = (obj.Position - meteorPosition).Magnitude
				if distance <= 80 then
					obj:Destroy()
				end
			end
		end

		return true
	end
	return false
end

-- Verificar si Meteor Jammer está activo
function PowerUpModule.IsMeteorJammerActive(userId: number): boolean
	local endTime = MeteorJammerActive[userId]
	if endTime and tick() < endTime then
		return true
	end
	return false
end

-- Verificar si Mini Drone puede interceptar
function PowerUpModule.TryDroneIntercept(userId: number): boolean
	if not PlayerPowerUps[userId] then return false end

	for _, powerUp in ipairs(PlayerPowerUps[userId].ActivePowerUps) do
		if powerUp.PowerUpId == "MiniDrone" and powerUp.Data.InterceptsRemaining and powerUp.Data.InterceptsRemaining > 0 then
			powerUp.Data.InterceptsRemaining -= 1

			if DEBUG then
				print(("[PowerUpModule] Dron interceptó meteorito para userId %d (quedan %d)"):format(
					userId, powerUp.Data.InterceptsRemaining
				))
			end

			-- Si no quedan intercepciones, destruir dron
			if powerUp.Data.InterceptsRemaining <= 0 then
				if powerUp.Data.Drone and powerUp.Data.Drone.Parent then
					powerUp.Data.Drone:Destroy()
				end
				PowerUpModule.ExpirePowerUp(userId, "MiniDrone")
			end

			return true
		end
	end

	return false
end

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE SPAWN AUTOMÁTICO
-- ═══════════════════════════════════════════════════════════════════════

-- Spawnear powerup para un jugador que completó una wave
function PowerUpModule.SpawnPowerUpForPlayer(userId: any, waveType: string)
	-- ✅ VALIDACIÓN: Verificar que userId sea un número
	if type(userId) ~= "number" then
		warn(("[PowerUpModule] ❌ SpawnPowerUpForPlayer recibió userId inválido: %s (tipo: %s)"):format(
			tostring(userId), type(userId)
		))
		warn("[PowerUpModule] Stack trace - Esto se llamó desde EventManager probablemente")
		warn("[PowerUpModule] 💡 SOLUCIÓN: En EventManager.lua línea ~349, cambia a:")
		warn("    PowerUpManager:SpawnRandomPowerUp(userId, 'Normal')")
		warn("    NO pases meteorPosition o player, solo player.UserId")
		return
	end

	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- Determinar rarity según wave type
	local rarity = PowerUpConfig.GetRandomRarity(waveType)
	local powerUpId = PowerUpConfig.GetRandomPowerUpByRarity(rarity)

	if not powerUpId then
		warn(("[PowerUpModule] No se pudo obtener powerup para rarity: %s"):format(rarity))
		return
	end

	-- Spawn cerca del jugador
	local offsetAngle = math.random() * math.pi * 2
	local offsetDistance = 15
	local spawnPosition = humanoidRootPart.Position + Vector3.new(
		math.cos(offsetAngle) * offsetDistance,
		2,
		math.sin(offsetAngle) * offsetDistance
	)

	PowerUpModule.SpawnPowerUpInWorld(powerUpId, spawnPosition)

	if DEBUG then
		print(("[PowerUpModule] PowerUp spawneado para userId %d: %s (%s)"):format(
			userId, powerUpId, rarity
		))
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE INICIALIZACIÓN Y CLEANUP
-- ═══════════════════════════════════════════════════════════════════════

function PowerUpModule.InitPlayer(userId: number)
	ensurePlayerState(userId)

	if DEBUG then
		print(("[PowerUpModule] Jugador inicializado: %d"):format(userId))
	end
end

function PowerUpModule.CleanupPlayer(userId: number)
	-- Limpiar powerups activos
	if PlayerPowerUps[userId] then
		for _, powerUp in ipairs(PlayerPowerUps[userId].ActivePowerUps) do
			if powerUp.Data.Drone and powerUp.Data.Drone.Parent then
				powerUp.Data.Drone:Destroy()
			end
		end
	end

	PlayerPowerUps[userId] = nil
	DashCooldownOverride[userId] = nil
	IncomeBoostMultipliers[userId] = nil
	BaseShieldActive[userId] = nil
	CriticalParryActive[userId] = nil
	MeteorJammerActive[userId] = nil
	ActiveDrones[userId] = nil

	if DEBUG then
		print(("[PowerUpModule] Jugador limpiado: %d"):format(userId))
	end
end

-- Inyectar dependencias
function PowerUpModule.SetDependencies(base: any, economy: any)
	BaseModule = base
	EconomyModule = economy

	if DEBUG then
		print("[PowerUpModule] Dependencias inyectadas")
	end
end

-- ═══════════════════════════════════════════════════════════════════════
-- LIFECYCLE
-- ═══════════════════════════════════════════════════════════════════════

Players.PlayerAdded:Connect(function(player)
	PowerUpModule.InitPlayer(player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	PowerUpModule.CleanupPlayer(player.UserId)
end)

if DEBUG then
	print("[PowerUpModule] ✅ Sistema de PowerUps inicializado")
end

return PowerUpModule
