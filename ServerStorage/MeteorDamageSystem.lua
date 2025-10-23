--!strict
--[[
	METEOR DAMAGE SYSTEM - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema de daño de meteoritos a jugadores con mecánica de evasión por salto.

	FEATURES:
	✅ Daño de área (AoE) al impactar
	✅ Detección de salto para evadir daño
	✅ Escalado de daño por distancia
	✅ Feedback visual (VFX, notificaciones, camera shake)
	✅ Sistema de immunidad temporal
	✅ Tracking de dodges/hits para achievements

	USAGE:
		local MeteorDamageSystem = require(game.ServerStorage.MeteorDamageSystem)

		-- Llamar cuando un meteorito impacte
		MeteorDamageSystem:OnMeteorImpact(impactPosition, basePart, meteorType)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--═══════════════════════════════════════════════════════════════════════
-- MÓDULOS
--═══════════════════════════════════════════════════════════════════════

local Config = require(ServerStorage.Config.Config)
local VFXManager = require(ServerStorage.Managers.VFXManager)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CameraShake = Remotes:WaitForChild("CameraShake") :: RemoteEvent
local ShowNotification = Remotes:FindFirstChild("ShowNotification") :: RemoteEvent?

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTES
--═══════════════════════════════════════════════════════════════════════

local DEBUG = Config.DEBUG_MODE

local DAMAGE_RADIUS = Config.METEOR_DAMAGE_RADIUS or 20
local BASE_DAMAGE = Config.METEOR_PLAYER_DAMAGE or 25
local JUMP_IMMUNITY_HEIGHT = Config.JUMP_IMMUNITY_HEIGHT or 5
local IMMUNITY_DURATION = 0.5 -- segundos de immunity después de dodge

--═══════════════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════════════

local PlayerStats = {} -- [userId] = {dodges, hits, lastDodgeTime}

-- Jugadores inmunes temporalmente
local ImmunePlayersCache = {} -- [userId] = expirationTime

--═══════════════════════════════════════════════════════════════════════
-- EVENTOS (Para tutorial y achievements)
--═══════════════════════════════════════════════════════════════════════

local OnDodge = Instance.new("BindableEvent")
local OnHit = Instance.new("BindableEvent")
local OnDeath = Instance.new("BindableEvent")

--═══════════════════════════════════════════════════════════════════════
-- MÓDULO
--═══════════════════════════════════════════════════════════════════════

local MeteorDamageSystem = {
	OnDodge = OnDodge.Event,
	OnHit = OnHit.Event,
	OnDeath = OnDeath.Event
}

--═══════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
--═══════════════════════════════════════════════════════════════════════

function MeteorDamageSystem:Initialize()
	-- Cleanup de immunity cache cada 5 segundos
	task.spawn(function()
		while true do
			task.wait(5)
			local now = tick()
			for userId, expTime in pairs(ImmunePlayersCache) do
				if now >= expTime then
					ImmunePlayersCache[userId] = nil
				end
			end
		end
	end)

	if DEBUG then
		print("[MeteorDamageSystem] ✓ Inicializado")
	end
end

--═══════════════════════════════════════════════════════════════════════
-- UTILIDADES
--═══════════════════════════════════════════════════════════════════════

local function initPlayerStats(userId: number)
	if not PlayerStats[userId] then
		PlayerStats[userId] = {
			dodges = 0,
			hits = 0,
			lastDodgeTime = 0
		}
	end
end

local function isPlayerImmune(userId: number): boolean
	local expTime = ImmunePlayersCache[userId]
	if not expTime then return false end

	if tick() >= expTime then
		ImmunePlayersCache[userId] = nil
		return false
	end

	return true
end

local function setPlayerImmunity(userId: number, duration: number)
	ImmunePlayersCache[userId] = tick() + duration
end

local function isPlayerJumping(character: Model): boolean
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not (humanoid and rootPart) then
		return false
	end

	-- Método 1: Verificar estado de Humanoid
	if humanoid:GetState() == Enum.HumanoidStateType.Jumping or
	   humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		return true
	end

	-- Método 2: Raycast hacia abajo
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -JUMP_IMMUNITY_HEIGHT, 0),
		rayParams
	)

	-- Si no hay raycast hit, está en el aire
	return rayResult == nil
end

local function showNotification(player: Player, message: string, color: Color3?)
	if not ShowNotification then return end

	ShowNotification:FireClient(player, message, 2, color)
end

--═══════════════════════════════════════════════════════════════════════
-- DAÑO PRINCIPAL
--═══════════════════════════════════════════════════════════════════════

function MeteorDamageSystem:OnMeteorImpact(position: Vector3, basePart: BasePart, meteorType: string?)
	if not basePart then return end

	-- Obtener owner de la base
	local userId = basePart:GetAttribute("OwnerUserId")
	if not userId then
		if DEBUG then
			warn("[MeteorDamageSystem] BasePart sin OwnerUserId")
		end
		return
	end

	local player = Players:GetPlayerByUserId(userId)
	if not (player and player.Character) then return end

	local character = player.Character
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not (humanoid and rootPart and humanoid.Health > 0) then return end

	-- Inicializar stats
	initPlayerStats(userId)

	-- Calcular distancia desde el impacto
	local distance = (rootPart.Position - position).Magnitude

	if distance > DAMAGE_RADIUS then
		-- Fuera de rango, no hacer nada
		return
	end

	-- Verificar immunity
	if isPlayerImmune(userId) then
		if DEBUG then
			print(("[MeteorDamageSystem] Player %d is immune"):format(userId))
		end
		return
	end

	-- Verificar si está saltando
	local isJumping = isPlayerJumping(character)

	if isJumping then
		-- ✅ EVADIÓ EL DAÑO
		PlayerStats[userId].dodges += 1
		PlayerStats[userId].lastDodgeTime = tick()

		-- Feedback positivo
		showNotification(player, "✓ DODGED!", Color3.fromRGB(0, 255, 0))

		-- VFX de dodge
		VFXManager:PlayEffect("PurchaseSuccess", rootPart.Position + Vector3.new(0, 2, 0))

		-- Camera shake leve
		CameraShake:FireClient(player, "Light", 0.2)

		-- Immunity temporal
		setPlayerImmunity(userId, IMMUNITY_DURATION)

		-- 🔥 Disparar evento para tutorial/achievements
		OnDodge:Fire(userId, meteorType)

		if DEBUG then
			print(("[MeteorDamageSystem] Player %d DODGED meteor (%.1f studs)"):format(userId, distance))
		end

		return
	end

	-- ❌ NO EVADIÓ - APLICAR DAÑO

	-- Escalar daño por distancia (más cerca = más daño)
	local damageScale = 1 - (distance / DAMAGE_RADIUS)
	damageScale = math.max(0.3, damageScale) -- Mínimo 30% de daño

	-- Multiplicador por tipo de meteorito
	local typeMultiplier = 1.0
	if meteorType then
		local meteorConfig = Config.METEOR_TYPES[meteorType]
		if meteorConfig then
			-- Usar el damage del meteorito como multiplier
			typeMultiplier = (meteorConfig.Damage or BASE_DAMAGE) / BASE_DAMAGE
		end
	end

	local finalDamage = math.floor(BASE_DAMAGE * damageScale * typeMultiplier)

	-- Aplicar daño
	humanoid:TakeDamage(finalDamage)

	-- Stats
	PlayerStats[userId].hits += 1

	-- Feedback negativo
	showNotification(player, string.format("-%d HP", finalDamage), Color3.fromRGB(255, 0, 0))

	-- VFX en jugador
	VFXManager:PlayEffect("DamageHit", rootPart.Position + Vector3.new(0, 1, 0))

	-- Camera shake fuerte
	CameraShake:FireClient(player, "Heavy", 0.4)

	-- Immunity temporal corta (para no recibir multi-hit del mismo meteorito)
	setPlayerImmunity(userId, 0.3)

	-- 🔥 Disparar evento para tutorial/achievements
	OnHit:Fire(userId, finalDamage, meteorType)

	if DEBUG then
		print(("[MeteorDamageSystem] Player %d HIT by meteor | Distance: %.1f | Damage: %d (scale: %.1f%%, type: %.1fx)"):format(
			userId, distance, finalDamage, damageScale * 100, typeMultiplier
		))
	end

	-- Check si murió
	if humanoid.Health <= 0 then
		MeteorDamageSystem:OnPlayerDeath(player)
	end
end

--═══════════════════════════════════════════════════════════════════════
-- DAÑO AoE (OPCIONAL - Para explosiones grandes)
--═══════════════════════════════════════════════════════════════════════

function MeteorDamageSystem:ApplyAoEDamage(position: Vector3, radius: number, damage: number, excludeUserId: number?)
	-- Encontrar todos los jugadores en el radio
	local playersHit = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId == excludeUserId then continue end

		local character = player.Character
		if not character then continue end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then continue end

		local distance = (rootPart.Position - position).Magnitude
		if distance <= radius then
			table.insert(playersHit, {
				player = player,
				distance = distance
			})
		end
	end

	-- Aplicar daño escalado
	for _, data in ipairs(playersHit) do
		local player = data.player
		local distance = data.distance
		local character = player.Character

		if not character then continue end

		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
		if not (humanoid and humanoid.Health > 0) then continue end

		-- No aplicar si está saltando
		if isPlayerJumping(character) then
			showNotification(player, "✓ DODGED AoE!", Color3.fromRGB(0, 255, 150))
			continue
		end

		-- Escalar daño
		local scale = 1 - (distance / radius)
		local finalDamage = math.floor(damage * scale)

		humanoid:TakeDamage(finalDamage)

		-- Feedback
		showNotification(player, string.format("-%d HP (AoE)", finalDamage), Color3.fromRGB(255, 100, 0))
		VFXManager:PlayEffect("DamageHit", character.HumanoidRootPart.Position)

		if DEBUG then
			print(("[MeteorDamageSystem] AoE hit Player %d | Distance: %.1f | Damage: %d"):format(
				player.UserId, distance, finalDamage
			))
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- EVENTOS
--═══════════════════════════════════════════════════════════════════════

function MeteorDamageSystem:OnPlayerDeath(player: Player)
	local userId = player.UserId

	-- 🔥 Disparar evento
	OnDeath:Fire(userId)

	if DEBUG then
		print(("[MeteorDamageSystem] 💀 Player %d died from meteor"):format(userId))
	end

	-- Aquí puedes agregar lógica de penalización
	-- Por ejemplo: perder dinero, stats, etc.

	-- Mensaje dramático
	task.delay(2, function()
		if player and player.Parent then
			showNotification(player, "☠️ You were crushed by a meteor!", Color3.fromRGB(200, 0, 0))
		end
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- STATS Y ACHIEVEMENTS
--═══════════════════════════════════════════════════════════════════════

function MeteorDamageSystem:GetPlayerStats(userId: number)
	initPlayerStats(userId)
	return PlayerStats[userId]
end

function MeteorDamageSystem:GetDodgeCount(userId: number): number
	initPlayerStats(userId)
	return PlayerStats[userId].dodges
end

function MeteorDamageSystem:GetHitCount(userId: number): number
	initPlayerStats(userId)
	return PlayerStats[userId].hits
end

function MeteorDamageSystem:GetDodgeRate(userId: number): number
	initPlayerStats(userId)
	local stats = PlayerStats[userId]
	local total = stats.dodges + stats.hits

	if total == 0 then return 0 end

	return stats.dodges / total
end

--═══════════════════════════════════════════════════════════════════════
-- DEBUG
--═══════════════════════════════════════════════════════════════════════

function MeteorDamageSystem:DebugPrintStats(userId: number)
	local stats = MeteorDamageSystem:GetPlayerStats(userId)
	local rate = MeteorDamageSystem:GetDodgeRate(userId)

	print(("═════════════════════════════════════════"))
	print(("  METEOR DAMAGE STATS - User %d"):format(userId))
	print(("═════════════════════════════════════════"))
	print(("  Dodges: %d"):format(stats.dodges))
	print(("  Hits: %d"):format(stats.hits))
	print(("  Dodge Rate: %.1f%%"):format(rate * 100))
	print(("  Last Dodge: %.1fs ago"):format(tick() - stats.lastDodgeTime))
	print(("  Is Immune: %s"):format(isPlayerImmune(userId) and "YES" or "NO"))
	print(("═════════════════════════════════════════"))
end

--═══════════════════════════════════════════════════════════════════════
-- CLEANUP
--═══════════════════════════════════════════════════════════════════════

Players.PlayerRemoving:Connect(function(plr)
	PlayerStats[plr.UserId] = nil
	ImmunePlayersCache[plr.UserId] = nil
end)

--═══════════════════════════════════════════════════════════════════════

-- Auto-inicializar
MeteorDamageSystem:Initialize()

if DEBUG then
	print("[MeteorDamageSystem] ✓ Módulo cargado")
end

return MeteorDamageSystem
