--!strict
--[[
	EVENT MANAGER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	VERSIÓN REFACTORIZADA con VFX épicos integrados.

	CAMBIOS EN ESTA VERSIÓN:
	✅ Integración con VFXManager para efectos visuales
	✅ Camera shake en impactos usando RemoteEvent
	✅ Trail mejorado con VFX data-driven
	✅ Explosiones espectaculares con partículas
	✅ Mantiene TODA la lógica original de daño/meteoritos

	INSTRUCCIONES DE INSTALACIÓN:
	1. Copia VFXManager.lua a ServerStorage.Managers.VFXManager
	2. Copia VFXConfig.lua a ServerStorage.Config.VFXConfig
	3. Reemplaza el EventManager antiguo con este archivo
	4. Copia el RemoteEvent "CameraShake" a ReplicatedStorage.Remotes

	COMPATIBILIDAD:
	- NO cambia API pública
	- NO rompe código existente
	- Solo agrega efectos visuales
]]

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Debris             = game:GetService("Debris")

local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
assert(RemotesFolder, "[EventManager] Falta folder ReplicatedStorage/Remotes")

local DebugSpawnMeteor  = RemotesFolder:WaitForChild("DebugSpawnMeteor") :: RemoteEvent
local BaseDamaged       = RemotesFolder:FindFirstChild("BaseDamaged") :: RemoteEvent?

-- 🔥 NUEVO: Remote para camera shake
local CameraShake = RemotesFolder:FindFirstChild("CameraShake") :: RemoteEvent?
if not CameraShake then
	CameraShake = Instance.new("RemoteEvent")
	CameraShake.Name = "CameraShake"
	CameraShake.Parent = RemotesFolder
	warn("[EventManager] RemoteEvent 'CameraShake' creado automáticamente")
end

local Config     = require(game.ServerStorage.Config.Config)
local BaseModule = require(script.Parent.BaseModule)

-- 🔥 NUEVO: Import VFXManager
local VFXManager = require(script.Parent.Managers.VFXManager)

local EventManager = {}

local DebugCooldowns: {[number]: number} = {}

--═══════════════════════════════════════════════════════════════════════
-- UTILIDADES (Sin cambios)
--═══════════════════════════════════════════════════════════════════════

local function getPlayerBasePart(plr: Player): BasePart?
	local bases = workspace:FindFirstChild("Bases")
	if not bases then
		warn("[Meteor] No existe workspace.Bases")
		return nil
	end

	local plate = bases:FindFirstChild(plr.Name.."_Base")
	if plate and plate:IsA("BasePart") then
		return plate
	end

	for _, child in ipairs(bases:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("OwnerUserId") == plr.UserId then
			return child
		end
	end

	return nil
end

local function ownerIdFromHierarchy(inst: Instance?): number?
	local cur = inst
	while cur and cur ~= workspace do
		local v = cur:GetAttribute("OwnerUserId")
		if typeof(v) == "number" then
			return v
		end
		cur = cur.Parent
	end
	return nil
end

local function nearestBaseOwnerIdAt(pos: Vector3, radius: number): number?
	local basesFolder = workspace:FindFirstChild("Bases")
	if not basesFolder then return nil end

	local bestUserId: number? = nil
	local bestDist = math.huge

	for _, basePart in ipairs(basesFolder:GetChildren()) do
		if basePart:IsA("BasePart") then
			local uid = basePart:GetAttribute("OwnerUserId")
			if typeof(uid) == "number" then
				local d = (basePart.Position - pos).Magnitude
				if d < bestDist then
					bestDist = d
					bestUserId = uid
				end
			end
		end
	end

	if bestUserId and bestDist <= radius then
		return bestUserId
	end
	return nil
end

local function resolveOwnerForHit(meteor: BasePart, hit: BasePart, fallbackPos: Vector3): number?
	local uid = ownerIdFromHierarchy(hit)
	if uid then return uid end

	local mUid = meteor:GetAttribute("TargetUserId")
	if typeof(mUid) == "number" then return mUid end

	return nearestBaseOwnerIdAt(fallbackPos, 50)
end

local function notifyPlayer(plr: Player, message: string, color: Color3?)
	if Config.DEBUG_MODE then
		print(("[NOTIFY] %s: %s"):format(plr.Name, message))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- METEORITOS - 🔥 REFACTORIZADO CON VFX
--═══════════════════════════════════════════════════════════════════════

local function createMeteor(meteorType: string): Part
	local typeConfig = Config.METEOR_TYPES[meteorType] or Config.METEOR_TYPES.Normal

	local meteor = Instance.new("Part")
	meteor.Name = "Meteor_" .. meteorType
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = typeConfig.Size
	meteor.Material = Enum.Material.Slate
	meteor.Color = typeConfig.Color
	meteor.Anchored = false
	meteor.CanCollide = true
	meteor.CanQuery = true
	meteor.CanTouch = true
	meteor.CustomPhysicalProperties = PhysicalProperties.new(3, 0.4, 0.3)
	meteor.CollisionGroup = "Default"

	-- 🔥 NUEVO: Usar VFX trail en lugar de Fire básico
	-- El trail se spawneará con VFXManager (ver abajo)

	-- Mantener efectos básicos para compatibilidad
	local fire = Instance.new("Fire", meteor)
	fire.Size = 10
	fire.Heat = 15
	fire.Color = Color3.fromRGB(255, 100, 0)

	local trail = Instance.new("Trail", meteor)
	trail.Lifetime = 0.8
	local att0 = Instance.new("Attachment", meteor)
	local att1 = Instance.new("Attachment", meteor)
	att1.Position = Vector3.new(0, 3, 0)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 150, 0))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})

	return meteor
end

local function spawnMeteorTowards(plr: Player, startPos: Vector3, targetPos: Vector3, meteorType: string?)
	meteorType = meteorType or "Normal"
	local typeConfig = Config.METEOR_TYPES[meteorType] or Config.METEOR_TYPES.Normal

	local meteor = createMeteor(meteorType)
	meteor.Position = startPos
	meteor.Parent = workspace

	meteor:SetAttribute("TargetUserId", plr.UserId)
	meteor:SetAttribute("MeteorType", meteorType)

	-- 🔥 NUEVO: Spawnear VFX trail que sigue al meteorito
	task.spawn(function()
		while meteor and meteor.Parent do
			VFXManager:PlayEffect("MeteorTrail", meteor.Position, meteor)
			task.wait(0.15) -- Trail cada 0.15s
		end
	end)

	local dir = (targetPos - startPos).Unit
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = dir * typeConfig.Speed + Vector3.new(0, -10, 0)
	bv.Parent = meteor
	Debris:AddItem(bv, 0.6)

	if Config.DEBUG_MODE then
		print(("[Meteor] %s lanzado hacia %s"):format(meteorType, plr.Name))
	end

	local ShowNotif = RemotesFolder:FindFirstChild("ShowNotification")
	if ShowNotif then
		ShowNotif:FireClient(plr, "☄️ INCOMING!", 2)
	end

	local applied = false
	local conn: RBXScriptConnection? = nil

	local function cleanup()
		if conn then conn:Disconnect() end
		meteor.Anchored = true
		Debris:AddItem(meteor, 0.1)
	end

	task.delay(Config.METEOR_LIFETIME, function()
		if meteor and meteor.Parent and not applied then
			if Config.DEBUG_MODE then
				print("[Meteor] Timeout sin impacto válido")
			end
			cleanup()
		end
	end)

	conn = meteor.Touched:Connect(function(hit: BasePart)
		if not meteor or not meteor.Parent then return end
		if applied then return end
		if not hit or not hit:IsA("BasePart") then return end

		if hit.Name:match("^Meteor_") then return end

		local hitPos = meteor.Position
		local userId = resolveOwnerForHit(meteor, hit, hitPos)

		if not userId then return end

		-- 🔥 NUEVO: Explosión visual épica
		VFXManager:PlayEffect("MeteorExplosion", hitPos)

		-- 🔥 NUEVO: Camera shake para el jugador afectado
		local ownerPlr = Players:GetPlayerByUserId(userId)
		if ownerPlr and CameraShake then
			-- Shake intensity basada en tipo de meteorito
			local shakeIntensity = "Medium"
			if meteorType == "Large" then
				shakeIntensity = "Heavy"
			elseif meteorType == "Small" then
				shakeIntensity = "Light"
			end

			CameraShake:FireClient(ownerPlr, shakeIntensity, 0.5)
		end

		-- Lógica de daño (sin cambios)
		local rawDamage = typeConfig.Damage
		local appliedAmount = BaseModule.ApplyDamage(userId, rawDamage)
		applied = appliedAmount > 0

		if Config.DEBUG_MODE then
			print(("[Meteor] Impacto en base de userId=%d | raw=%d, applied=%d, HP restante=%d")
				:format(userId, rawDamage, appliedAmount, BaseModule.GetHP(userId)))
		end

		if BaseModule.GetHP(userId) > 0 then
			print(("[METEOR] Jugador %d sobrevivió!"):format(userId))
		end

		if ownerPlr and appliedAmount > 0 then
			if BaseDamaged then
				BaseDamaged:FireClient(ownerPlr, appliedAmount)
			end

			-- 🔥 NUEVO: VFX de daño en la base
			local basePart = getPlayerBasePart(ownerPlr)
			if basePart then
				VFXManager:PlayEffect("DamageHit", basePart.Position + Vector3.new(0, 5, 0))
			end

			if BaseModule.IsLowHP(userId) then
				notifyPlayer(ownerPlr, "⚠️ HP CRÍTICO!", Config.UI_COLORS.Warning)
			end
		end

		cleanup()
	end)

	Debris:AddItem(meteor, Config.METEOR_LIFETIME)
end

local function spawnMeteorOverBase(plr: Player, height: number?, spread: number?, meteorType: string?)
	local base = getPlayerBasePart(plr)

	if not base then
		warn(("[Meteor] No encontré base del jugador: %s"):format(plr.Name))
		return
	end

	local h  = height or Config.METEOR_MIN_Y
	local sp = spread or 12
	local offset = Vector3.new(math.random(-sp, sp), 0, math.random(-sp, sp))
	local startPos = base.Position + Vector3.new(0, h, 0) + offset
	local target   = base.Position + offset * 0.25

	spawnMeteorTowards(plr, startPos, target, meteorType)
end

-- Debug: Meteorito con tecla M (sin cambios)
DebugSpawnMeteor.OnServerEvent:Connect(function(plr: Player)
	local now = tick()
	local lastSpawn = DebugCooldowns[plr.UserId] or 0

	if now - lastSpawn < Config.METEOR_DEBUG_COOLDOWN then
		if Config.DEBUG_MODE then
			warn(("[DEBUG] %s en cooldown de meteorito"):format(plr.Name))
		end
		return
	end

	DebugCooldowns[plr.UserId] = now

	if Config.DEBUG_MODE then
		print("[DEBUG] DebugSpawnMeteor de", plr.Name)
	end

	local types = {"Small", "Normal", "Large"}
	local randomType = types[math.random(1, #types)]

	spawnMeteorOverBase(plr, Config.METEOR_MIN_Y, 12, randomType)
end)

-- Evento: MeteorStorm (sin cambios de lógica, solo VFX)
function EventManager:MeteorStorm()
	local config = Config.EVENTS.MeteorStorm

	if config.WarnTime > 0 then
		for _, plr in ipairs(Players:GetPlayers()) do
			notifyPlayer(plr, "⚠️ TORMENTA DE METEORITOS EN " .. config.WarnTime .. "s", Config.UI_COLORS.Warning)
		end
		task.wait(config.WarnTime)
	end

	local ShowNotif = RemotesFolder:FindFirstChild("ShowNotification")
	if ShowNotif then
		for _, plr in ipairs(Players:GetPlayers()) do
			ShowNotif:FireClient(plr, "⚠️ METEOR STORM", 3)
		end
	end

	print("[EVENT] MeteorStorm iniciada")

	for _, plr in ipairs(Players:GetPlayers()) do
		local meteorCount = Config.METEOR_COUNT

		for i = 1, meteorCount do
			task.delay(i * (1 / config.SpawnRate), function()
				local rand = math.random()
				local meteorType
				if rand < 0.5 then
					meteorType = "Small"
				elseif rand < 0.9 then
					meteorType = "Normal"
				else
					meteorType = "Large"
				end

				spawnMeteorOverBase(plr, Config.METEOR_MIN_Y + 20, 14, meteorType)
			end)
		end
	end

	task.delay(config.Duration, function()
		print("[EVENT] MeteorStorm finalizada")
		for _, plr in ipairs(Players:GetPlayers()) do
			notifyPlayer(plr, "✓ Tormenta terminada", Config.UI_COLORS.Income)
		end
	end)
end

-- Limpieza
Players.PlayerRemoving:Connect(function(plr)
	DebugCooldowns[plr.UserId] = nil
end)

if Config.DEBUG_MODE then
	print("[EVENTMANAGER REFACTORED] ✓ Módulo cargado con VFX épicos")
end

return EventManager
