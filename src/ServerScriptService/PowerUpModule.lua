--!strict
--[[
	-----------------------------------------------------------------------
	POWERUP MODULE - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Sistema completo de power-ups con:
	? GestiÃ³n de powerups activos por jugador
	? Spawning de powerups en el mundo
	? Sistema de pickup visual
	? Efectos VFX para cada powerup
	? IntegraciÃ³n con BaseModule y EconomyModule
	? Sistema de stacking y cooldowns

	-----------------------------------------------------------------------
--]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- MÃ³dulos
local PowerUpConfig = require(ServerStorage.Config.PowerUpConfig)
local Config = require(ServerStorage.Config.Config)

-- Referencias a otros mÃ³dulos (se inyectarÃ¡n despuÃ©s)
local BaseModule = nil
local EconomyModule = nil

local DEBUG = Config.DEBUG_MODE or false

-- -----------------------------------------------------------------------
-- TIPOS
-- -----------------------------------------------------------------------

export type ActivePowerUp = {
	PowerUpId: string,
	StartTime: number,
	Duration: number,
	Data: any?, -- Data especÃ­fica del powerup
}

-- -----------------------------------------------------------------------
-- ESTADO
-- -----------------------------------------------------------------------

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

-- -----------------------------------------------------------------------
-- REMOTES
-- -----------------------------------------------------------------------

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

-- -----------------------------------------------------------------------
-- UTILIDADES
-- -----------------------------------------------------------------------

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

-- -----------------------------------------------------------------------
-- SISTEMA DE SPAWNING DE POWERUPS
-- -----------------------------------------------------------------------

-- Crear powerup fÃ­sico en el mundo
function PowerUpModule.SpawnPowerUpInWorld(powerUpId: string, position: Vector3): Model?
	local def = PowerUpConfig.PowerUps[powerUpId]
	if not def then
		warn(("[PowerUpModule] PowerUp invÃ¡lido: %s"):format(powerUpId))
		return nil
	end

	-- Crear modelo de powerup
	local powerUpModel = Instance.new("Model")
	powerUpModel.Name = "PowerUp_" .. powerUpId
	powerUpModel:SetAttribute("PowerUpId", powerUpId)

	-- Base del powerup (parte fÃ­sica)
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

	-- PartÃ­culas
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

	-- AnimaciÃ³n de flotaciÃ³n y rotaciÃ³n
	task.spawn(function()
		local startY = position.Y
		local t = 0
		while base and base.Parent do
			t += 0.016 -- ~60 FPS
			local offset = math.sin(t * 2) * 1 -- OscilaciÃ³n de 1 stud
			base.CFrame = CFrame.new(position.X, startY + offset, position.Z)
				* CFrame.Angles(0, t, 0) -- RotaciÃ³n continua
			task.wait(0.016)
		end
	end)

	powerUpModel.PrimaryPart = base
	powerUpModel.Parent = workspace

	-- Detectar colisiÃ³n con jugador
	base.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Recoger powerup
		PowerUpModule.CollectPowerUp(player.UserId, powerUpId)
		powerUpModel:Destroy()
	end)

	-- Auto-destruir despuÃ©s de 30 segundos
	Debris:AddItem(powerUpModel, 30)

	if DEBUG then
		print(("[PowerUpModule] PowerUp spawneado: %s en %s"):format(powerUpId, tostring(position)))
	end

	-- Notificar a clientes
	PowerUpSpawned:FireAllClients(powerUpId, position)

	return powerUpModel
end

-- -----------------------------------------------------------------------
-- SISTEMA DE COLECCIÃN Y ACTIVACIÃN
-- -----------------------------------------------------------------------

function PowerUpModule.CollectPowerUp(userId: number, powerUpId: string)
	ensurePlayerState(userId)

	local def = PowerUpConfig.PowerUps[powerUpId]
	if not def then
		warn(("[PowerUpModule] PowerUp invÃ¡lido: %s"):format(powerUpId))
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

	-- ? PREVENIR STACKING: Si ya tiene este powerup activo, expirar el viejo primero
	local state = PlayerPowerUps[userId]
	for i = #state.ActivePowerUps, 1, -1 do
		if state.ActivePowerUps[i].PowerUpId == powerUpId then
			if DEBUG then
				print(("[PowerUpModule] ?? Reemplazando powerup existente: %s para userId %d"):format(powerUpId, userId))
			end
			PowerUpModule.ExpirePowerUp(userId, powerUpId)
			break
		end
	end

	local duration = PowerUpConfig.GetRandomDuration(powerUpId)

	-- Crear entrada de powerup activo
	local activePowerUp: ActivePowerUp = {
		PowerUpId = powerUpId,
		StartTime = tick(),
		Duration = duration,
		Data = {},
	}

	table.insert(PlayerPowerUps[userId].ActivePowerUps, activePowerUp)

	-- Llamar funciÃ³n de activaciÃ³n especÃ­fica
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

	-- Programar expiraciÃ³n
	if duration > 0 then
		task.delay(duration, function()
			PowerUpModule.ExpirePowerUp(userId, powerUpId)
		end)
	else
		-- ? FIX: Powerups instantÃ¡neos (duration = 0) deben expirar inmediatamente
		-- Damos 0.5s para que se vea el efecto visual, luego expiramos
		task.delay(0.5, function()
			PowerUpModule.ExpirePowerUp(userId, powerUpId)
		end)
	end

	if DEBUG then
		print(("[PowerUpModule] PowerUp activado: %s para userId %d (duraciÃ³n: %.1fs)"):format(
			powerUpId, userId, duration
			))
	end
end

function PowerUpModule.ExpirePowerUp(userId: number, powerUpId: string)
	if not PlayerPowerUps[userId] then return end

	local state = PlayerPowerUps[userId]

	-- Buscar y remover powerup activo
	local found = false
	for i = #state.ActivePowerUps, 1, -1 do
		if state.ActivePowerUps[i].PowerUpId == powerUpId then
			-- Limpiar drones si es MiniDrone
			if powerUpId == "MiniDrone" then
				local droneData = state.ActivePowerUps[i].Data
				if droneData and droneData.Drone and droneData.Drone.Parent then
					droneData.Drone:Destroy()
				end
			end

			table.remove(state.ActivePowerUps, i)
			found = true
			break
		end
	end

	if not found and DEBUG then
		warn(("[PowerUpModule] ?? IntentÃ³ expirar powerup inexistente: %s para userId %d"):format(powerUpId, userId))
	end

	-- Llamar funciÃ³n de limpieza especÃ­fica
	local def = PowerUpConfig.PowerUps[powerUpId]
	if def and def.OnDeactivate then
		local deactivateFunc = PowerUpModule[def.OnDeactivate]
		if deactivateFunc then
			deactivateFunc(userId)
		end
	end

	-- Cleanup especÃ­fico por powerup (asegurar limpieza completa)
	if powerUpId == "SuperDash" then
		DashCooldownOverride[userId] = nil
	elseif powerUpId == "IncomeBoost" then
		IncomeBoostMultipliers[userId] = nil
	elseif powerUpId == "MeteorJammer" then
		MeteorJammerActive[userId] = nil
	elseif powerUpId == "BaseShield" then
		BaseShieldActive[userId] = nil
	elseif powerUpId == "CriticalParry" then
		CriticalParryActive[userId] = nil
	elseif powerUpId == "MiniDrone" then
		-- Limpiar todos los drones del jugador
		if ActiveDrones[userId] then
			for _, drone in ipairs(ActiveDrones[userId]) do
				if drone and drone.Parent then
					drone:Destroy()
				end
			end
			ActiveDrones[userId] = {}
		end
	elseif powerUpId == "SpeedBoost" then
		-- Restaurar velocidad original
		local player = getPlayer(userId)
		if player and player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid?
			if humanoid then
				humanoid.WalkSpeed = 16 -- Velocidad default de Roblox
			end
		end
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

-- -----------------------------------------------------------------------
-- IMPLEMENTACIÃN DE POWERUPS ESPECÃFICOS
-- -----------------------------------------------------------------------

-- ???????????????????????????????????????????????????????????????
-- 1. GOD SHIELD
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateGodShield(userId: number, powerUp: ActivePowerUp)
	if not BaseModule then return end

	BaseModule.SetInvulnerable(userId, true, powerUp.Duration)

	if DEBUG then
		print(("[PowerUpModule] God Shield activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 2. DOUBLE DAMAGE
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateDoubleDamage(userId: number, powerUp: ActivePowerUp)
	-- Este se maneja en el cliente/sistema de armas
	-- AquÃ­ solo guardamos que estÃ¡ activo
	powerUp.Data.DamageMultiplier = 2.0

	if DEBUG then
		print(("[PowerUpModule] Double Damage activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 3. SUPER DASH
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateSuperDash(userId: number, powerUp: ActivePowerUp)
	DashCooldownOverride[userId] = true

	if DEBUG then
		print(("[PowerUpModule] Super Dash activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 4. FULL HEAL
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateFullHeal(userId: number, powerUp: ActivePowerUp)
	if not BaseModule then return end

	local maxHP = BaseModule.GetMaxHP(userId)
	BaseModule.SetHP(userId, maxHP)

	if DEBUG then
		print(("[PowerUpModule] Full Heal activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 5. MINI DRONE
-- ???????????????????????????????????????????????????????????????
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

	-- Auto-destruir despuÃ©s de la duraciÃ³n
	task.delay(powerUp.Duration, function()
		if drone and drone.Parent then
			drone:Destroy()
		end
	end)

	if DEBUG then
		print(("[PowerUpModule] Mini Drone activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 6. SPEED BOOST
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateSpeedBoost(userId: number, powerUp: ActivePowerUp)
	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid") :: Humanoid?
	if not humanoid then return end

	local originalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = originalSpeed * 2

	powerUp.Data.OriginalSpeed = originalSpeed

	-- Restaurar despuÃ©s de la duraciÃ³n
	task.delay(powerUp.Duration, function()
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalSpeed
		end
	end)

	if DEBUG then
		print(("[PowerUpModule] Speed Boost activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 7. BASE SHIELD
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateBaseShield(userId: number, powerUp: ActivePowerUp)
	BaseShieldActive[userId] = true

	if DEBUG then
		print(("[PowerUpModule] Base Shield activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 8. METEOR JAMMER
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateMeteorJammer(userId: number, powerUp: ActivePowerUp)
	MeteorJammerActive[userId] = tick() + powerUp.Duration

	if DEBUG then
		print(("[PowerUpModule] Meteor Jammer activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 9. DEFENSIVE BURST
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateDefensiveBurst(userId: number, powerUp: ActivePowerUp)
	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local position = humanoidRootPart.Position

	-- Crear explosiÃ³n visual
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

-- ???????????????????????????????????????????????????????????????
-- 10. CRITICAL PARRY
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateCriticalParry(userId: number, powerUp: ActivePowerUp)
	CriticalParryActive[userId] = true

	if DEBUG then
		print(("[PowerUpModule] Critical Parry activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 11. ULTRA CHARGE
-- ???????????????????????????????????????????????????????????????
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

-- ???????????????????????????????????????????????????????????????
-- 12. EGG CATALYST
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateEggCatalyst(userId: number, powerUp: ActivePowerUp)
	-- Este se maneja en el sistema de rewards de waves
	powerUp.Data.EggChanceBonus = 0.25

	if DEBUG then
		print(("[PowerUpModule] Egg Catalyst activado para userId %d"):format(userId))
	end
end

-- ???????????????????????????????????????????????????????????????
-- 13. INCOME BOOST
-- ???????????????????????????????????????????????????????????????
function PowerUpModule.ActivateIncomeBoost(userId: number, powerUp: ActivePowerUp)
	-- ?? Leer multiplier del config (2.0 = verdadero 2X)
	local config = PowerUpConfig.PowerUps.IncomeBoost
	IncomeBoostMultipliers[userId] = config and config.IncomeMultiplier or 2.0

	if DEBUG then
		print(("[PowerUpModule] Income Boost activado para userId %d"):format(userId))
	end
end

-- -----------------------------------------------------------------------
-- GETTERS PARA OTROS MÃDULOS
-- -----------------------------------------------------------------------

-- Verificar si SuperDash estÃ¡ activo (para sistema de dash)
function PowerUpModule.IsSuperDashActive(userId: number): boolean
	return DashCooldownOverride[userId] == true
end

-- Obtener multiplier de income boost (para EconomyModule)
function PowerUpModule.GetIncomeMultiplier(userId: number): number
	return IncomeBoostMultipliers[userId] or 1.0
end

-- Verificar si BaseShield puede bloquear daÃ±o
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

		-- Crear explosiÃ³n en la posiciÃ³n del meteorito
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

-- Verificar si Meteor Jammer estÃ¡ activo
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
				print(("[PowerUpModule] Dron interceptÃ³ meteorito para userId %d (quedan %d)"):format(
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

-- -----------------------------------------------------------------------
-- SISTEMA DE SPAWN AUTOMÃTICO
-- -----------------------------------------------------------------------

-- Spawnear powerup para un jugador que completÃ³ una wave
function PowerUpModule.SpawnPowerUpForPlayer(userId: any, waveType: string, waveNumber: number?)
	-- ? VALIDACIÃN: Verificar que userId sea un nÃºmero
	if type(userId) ~= "number" then
		warn(("[PowerUpModule] ? SpawnPowerUpForPlayer recibiÃ³ userId invÃ¡lido: %s (tipo: %s)"):format(
			tostring(userId), type(userId)
			))
		warn("[PowerUpModule] Stack trace - Esto se llamÃ³ desde EventManager probablemente")
		warn("[PowerUpModule] ?? SOLUCIÃN: En EventManager.lua lÃ­nea ~349, cambia a:")
		warn("    PowerUpManager:SpawnRandomPowerUp(userId, 'Normal')")
		warn("    NO pases meteorPosition o player, solo player.UserId")
		return
	end

	local player = getPlayer(userId)
	if not player or not player.Character then return end

	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	-- ? SISTEMA HÃBRIDO: DeterminÃ­stico + ProbabilÃ­stico
	local powerUpId: string? = nil
	local wave = waveNumber or 0

	-- WAVE 3: Siempre FullHeal (introducciÃ³n amigable)
	if wave == 3 then
		powerUpId = "FullHeal"
		if DEBUG then
			print(("[PowerUpModule] ?? Wave 3 - Spawneando FullHeal garantizado"):format())
		end

		-- WAVE 10, 20, 30... (Boss): Siempre GodShield o UltraCharge
	elseif waveType == "Boss" then
		local epicPowerups = {"GodShield", "UltraCharge"}
		powerUpId = epicPowerups[math.random(1, #epicPowerups)]
		if DEBUG then
			print(("[PowerUpModule] ?? Boss Wave %d - Spawneando %s Ã©pico"):format(wave, powerUpId))
		end

		-- WAVE 5, 15, 25... (MiniBoss): Random Uncommon
	elseif waveType == "MiniBoss" then
		powerUpId = PowerUpConfig.GetRandomPowerUpByRarity("Uncommon")
		if DEBUG then
			print(("[PowerUpModule] ?? MiniBoss Wave %d - Spawneando Uncommon: %s"):format(wave, powerUpId or "nil"))
		end

		-- OTRAS WAVES: Random segÃºn probabilidad de waveType
	else
		local rarity = PowerUpConfig.GetRandomRarity(waveType)
		powerUpId = PowerUpConfig.GetRandomPowerUpByRarity(rarity)
		if DEBUG then
			print(("[PowerUpModule] ?? Wave %d - Spawneando random %s: %s"):format(wave, rarity, powerUpId or "nil"))
		end
	end

	if not powerUpId then
		warn(("[PowerUpModule] No se pudo obtener powerup para wave %d (%s)"):format(wave, waveType))
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
		print(("[PowerUpModule] ? PowerUp spawneado para userId %d: %s (Wave %d, %s)"):format(
			userId, powerUpId, wave, waveType
			))
	end
end

-- -----------------------------------------------------------------------
-- ?? SISTEMA DE INVENTARIO DE POWERUPS
-- -----------------------------------------------------------------------

local MAX_INVENTORY_SLOTS = 5

-- Inventario por jugador: {userId: {powerUpId, powerUpId, ...}}
local PlayerInventories: {[number]: {string}} = {}

-- Remote para actualizar inventario en cliente
local UpdateInventoryRemote = Remotes:FindFirstChild("UpdateInventory") :: RemoteEvent?
if not UpdateInventoryRemote then
	UpdateInventoryRemote = Instance.new("RemoteEvent")
	UpdateInventoryRemote.Name = "UpdateInventory"
	UpdateInventoryRemote.Parent = Remotes
	if DEBUG then
		print("[PowerUpModule] Creado remote: UpdateInventory")
	end
end

--[[
	Agregar powerup al inventario del jugador.

	@param userId number
	@param powerUpId string
	@return boolean - true si se agregÃ³ exitosamente
	@return string? - mensaje de error
]]
function PowerUpModule.AddToInventory(userId: number, powerUpId: string): (boolean, string?)
	if not PlayerInventories[userId] then
		PlayerInventories[userId] = {}
	end

	local inventory = PlayerInventories[userId]

	-- Verificar si hay espacio
	if #inventory >= MAX_INVENTORY_SLOTS then
		return false, "Inventario lleno! (mÃ¡x 5)"
	end

	-- Agregar powerup
	table.insert(inventory, powerUpId)

	-- Sincronizar con cliente
	local player = getPlayer(userId)
	if player and UpdateInventoryRemote then
		UpdateInventoryRemote:FireClient(player, inventory)
	end

	if DEBUG then
		print(("[PowerUpModule] ? PowerUp agregado al inventario - userId %d, powerUp %s, total: %d/%d"):format(
			userId, powerUpId, #inventory, MAX_INVENTORY_SLOTS
			))
	end

	return true, nil
end

--[[
	Usar powerup desde un slot del inventario.

	@param userId number
	@param slotIndex number - Ã­ndice del slot (1-based)
	@return boolean - true si se usÃ³ exitosamente
]]
function PowerUpModule.UseFromInventory(userId: number, slotIndex: number): boolean
	if not PlayerInventories[userId] then
		return false
	end

	local inventory = PlayerInventories[userId]
	local powerUpId = inventory[slotIndex]

	if not powerUpId then
		return false
	end

	-- Remover del inventario
	table.remove(inventory, slotIndex)

	-- Activar el powerup
	PowerUpModule.ActivatePowerUp(userId, powerUpId)

	-- Sincronizar con cliente
	local player = getPlayer(userId)
	if player and UpdateInventoryRemote then
		UpdateInventoryRemote:FireClient(player, inventory)
	end

	if DEBUG then
		print(("[PowerUpModule] ? PowerUp usado desde inventario - userId %d, slot %d, powerUp %s"):format(
			userId, slotIndex, powerUpId
			))
	end

	return true
end

--[[
	Obtener inventario del jugador.

	@param userId number
	@return {string} - array de powerUpIds
]]
function PowerUpModule.GetInventory(userId: number): {string}
	return PlayerInventories[userId] or {}
end

-- -----------------------------------------------------------------------
-- ?? SISTEMA DE MÃQUINA EXPENDEDORA
-- -----------------------------------------------------------------------

-- Tracking de cooldown y primer uso por jugador
local VendingMachineCooldowns: {[number]: number} = {}
local VendingMachineFirstUse: {[number]: boolean} = {}

--[[
	Comprar powerup desde la mÃ¡quina expendedora.

	@param userId number - ID del jugador
	@return boolean - true si la compra fue exitosa
	@return string? - Mensaje de error si fallÃ³
]]
function PowerUpModule.PurchaseFromVendingMachine(userId: number): (boolean, string?)
	local player = getPlayer(userId)
	if not player or not player.Character then
		return false, "Jugador no encontrado"
	end

	-- ? Verificar cooldown
	local now = tick()
	local lastPurchase = VendingMachineCooldowns[userId] or 0
	local cooldownRemaining = PowerUpConfig.VendingMachine.Cooldown - (now - lastPurchase)

	if cooldownRemaining > 0 then
		return false, string.format("Cooldown: %.0fs restantes", cooldownRemaining)
	end

	-- ? PRIMER USO: Siempre IncomeBoost
	local powerUpId: string
	local price: number

	if not VendingMachineFirstUse[userId] then
		powerUpId = "IncomeBoost"
		price = 0 -- Gratis 
		VendingMachineFirstUse[userId] = true

		if DEBUG then
			print(("[PowerUpModule] ?? Primer uso de mÃ¡quina - IncomeBoost gratis garantizado para userId %d"):format(userId))
		end
	else
		-- ? Usos siguientes: Random por rareza
		local rarity = PowerUpModule.GetRandomVendingMachineRarity()
		powerUpId = PowerUpConfig.GetRandomPowerUpByRarity(rarity)
		price = PowerUpConfig.VendingMachine.Prices[rarity] or 300

		if DEBUG then
			print(("[PowerUpModule] ?? MÃ¡quina expendedora - Rareza: %s, PowerUp: %s, Precio: $%d"):format(
				rarity, powerUpId, price
				))
		end
	end

	-- ? Verificar si tiene suficiente cash
	local currentCash = 0
	if EconomyModule then
		local state = EconomyModule.GetState(userId)
		if state then
			currentCash = state.Cash
		end
	end

	if currentCash < price then
		return false, string.format("Necesitas $%d (te faltan $%d)", price, price - currentCash)
	end

	-- ? Cobrar (restar cash directamente del state)
	if EconomyModule then
		local state = EconomyModule.GetState(userId)
		if state then
			state.Cash -= price

			-- Actualizar leaderstats
			local player = getPlayer(userId)
			if player then
				local ls = player:FindFirstChild("leaderstats")
				if ls then
					local cashValue = ls:FindFirstChild("Cash") :: IntValue?
					if cashValue then
						cashValue.Value = state.Cash
					end
				end
			end
		end	
	end

	-- ? Agregar al inventario en vez de activar inmediatamente
	local success, errorMsg = PowerUpModule.AddToInventory(userId, powerUpId)
	if not success then
		-- Revertir el cobro si el inventario estÃ¡ lleno
		if EconomyModule then
			local state = EconomyModule.GetState(userId)
			if state then
				state.Cash += price
				local player = getPlayer(userId)
				if player then
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						local cashValue = ls:FindFirstChild("Cash") :: IntValue?
						if cashValue then
							cashValue.Value = state.Cash
						end
					end
				end
			end
		end
		return false, errorMsg
	end

	-- ? Registrar cooldown
	VendingMachineCooldowns[userId] = now

	if DEBUG then
		print(("[PowerUpModule] ? Compra exitosa - userId %d recibiÃ³ %s por $%d (agregado a inventario)"):format(
			userId, powerUpId, price
			))
	end

	-- Devolver powerUpId para spawnearlo en el mundo
	return true, powerUpId
end

-- Obtener rareza random para mÃ¡quina expendedora
function PowerUpModule.GetRandomVendingMachineRarity(): string
	local roll = math.random(1, 100)
	local rates = PowerUpConfig.VendingMachine.DropRates

	local cumulative = 0
	for _, rarity in ipairs({"Epic", "Rare", "Uncommon", "Common"}) do
		cumulative += rates[rarity]
		if roll <= cumulative then
			return rarity
		end
	end

	return "Common" -- Fallback
end

--[[
	Spawnear chicle/pelota fÃ­sica de powerup que puede ser recogido.

	@param powerUpId string - ID del powerup
	@param position Vector3 - PosiciÃ³n donde spawnearlo
	@param userId number - ID del dueÃ±o (para que solo Ã©l lo pueda recoger)
	@return Part - El chicle spawneado
]]
function PowerUpModule.SpawnGumball(powerUpId: string, position: Vector3, userId: number): Part?
	local def = PowerUpConfig.PowerUps[powerUpId]
	if not def then return nil end

	-- Crear chicle/pelota brillante
	local gumball = Instance.new("Part")
	gumball.Name = "PowerUpGumball"
	gumball.Shape = Enum.PartType.Ball
	gumball.Size = Vector3.new(1.5, 1.5, 1.5)
	gumball.Material = Enum.Material.Neon
	gumball.Color = def.VFX and def.VFX.ParticleColor and def.VFX.ParticleColor.Keypoints[1].Value or Color3.fromRGB(255, 100, 255)
	gumball.Anchored = false
	gumball.CanCollide = true
	gumball.Position = position
	gumball:SetAttribute("PowerUpId", powerUpId)
	gumball:SetAttribute("OwnerUserId", userId)

	-- PointLight para hacerlo brillante
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 10
	light.Color = gumball.Color
	light.Parent = gumball

	-- Sparkles para efecto mÃ¡gico
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = gumball.Color
	sparkles.Parent = gumball

	-- Touched event para recogerlo
	gumball.Touched:Connect(function(hit)
		if not hit or not hit.Parent then return end

		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
		if not player or player.UserId ~= userId then return end -- Solo el dueÃ±o puede recogerlo

		-- Ya estÃ¡ en el inventario (se agregÃ³ al comprar)
		-- Solo destruir el visual
		gumball:Destroy()

		if DEBUG then
			print(("[PowerUpModule] ?? Jugador %d recogiÃ³ chicle de %s"):format(userId, powerUpId))
		end
	end)

	-- Auto-destruir despuÃ©s de 60 segundos si no se recoge
	game:GetService("Debris"):AddItem(gumball, 60)

	return gumball
end

-- -----------------------------------------------------------------------
-- SISTEMA DE INICIALIZACIÃN Y CLEANUP
-- -----------------------------------------------------------------------

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
	
	-- ?? Limpiar inventario
	PlayerInventories[userId] = nil


	-- ?? Limpiar datos de vending machine
	VendingMachineCooldowns[userId] = nil
	VendingMachineFirstUse[userId] = nil

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

-- -----------------------------------------------------------------------
-- LIFECYCLE
-- -----------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player)
	PowerUpModule.InitPlayer(player.UserId)
end)

Players.PlayerRemoving:Connect(function(player)
	PowerUpModule.CleanupPlayer(player.UserId)
end)

if DEBUG then
	print("[PowerUpModule] ? Sistema de PowerUps inicializado")
end

return PowerUpModule