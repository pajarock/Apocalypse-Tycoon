--!strict
--[[
	EVENT MANAGER - Apocalypse Tycoon (ARREGLADO)
	-----------------------------------------------------------------------

	✅ ARREGLOS EN ESTA VERSIÓN:
	1. BaseModule ahora se inyecta desde Main.Server.lua (no require directo)
	2. Validación de BaseModule antes de usar sus funciones
	3. Flash en pantalla agregado en impactos
	4. Mejores mensajes de error para debugging

	CAMBIOS RESPECTO A LA VERSIÓN ANTERIOR:
	- Línea 56: BaseModule = nil (se inyectará)
	- Línea 67-72: Nueva función SetBaseModule()
	- Línea 293-310: Validación de BaseModule añadida
	- Línea 280-283: Flash rojo agregado en impactos
--]]

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

-- 🔥 NUEVO: Remote para notificaciones (dodge, daño, etc.)
local ShowNotification = RemotesFolder:FindFirstChild("ShowNotification") :: RemoteEvent?
if not ShowNotification then
	ShowNotification = Instance.new("RemoteEvent")
	ShowNotification.Name = "ShowNotification"
	ShowNotification.Parent = RemotesFolder
	warn("[EventManager] RemoteEvent 'ShowNotification' creado automáticamente")
end

-- 🔥 NUEVO: Remote para screen flash
local ScreenFlash = RemotesFolder:FindFirstChild("ScreenFlash") :: RemoteEvent?
if not ScreenFlash then
	ScreenFlash = Instance.new("RemoteEvent")
	ScreenFlash.Name = "ScreenFlash"
	ScreenFlash.Parent = RemotesFolder
	warn("[EventManager] RemoteEvent 'ScreenFlash' creado automáticamente")
end

-- 💀 NUEVO: Remote para notificar muerte de base
local BaseDead = RemotesFolder:FindFirstChild("BaseDead") :: RemoteEvent?
if not BaseDead then
	BaseDead = Instance.new("RemoteEvent")
	BaseDead.Name = "BaseDead"
	BaseDead.Parent = RemotesFolder
	warn("[EventManager] RemoteEvent 'BaseDead' creado automáticamente")
end


local Config     = require(game.ServerStorage.Config.Config)

-- ✅ ARREGLADO: BaseModule se inyectará desde Main.Server.lua
local BaseModule = nil

-- 🔥 NUEVO: Import VFXManager
local VFXManager = require(game.ServerStorage.Managers.VFXManager)

-- 🔥 NUEVO: Import MeteorDamageSystem (OPCIONAL - comentar si no existe)
local MeteorDamageSystem = nil
local hasMeteorDamage = pcall(function()
	MeteorDamageSystem = require(game.ServerStorage.MeteorDamageSystem)
end)

local EventManager = {}

local DebugCooldowns: {[number]: number} = {}

-------------------------------------------------------------------------
-- ✅ NUEVA FUNCIÓN: Inyectar BaseModule desde Main.Server.lua
-------------------------------------------------------------------------

function EventManager:SetBaseModule(base)
	BaseModule = base
	if Config.DEBUG_MODE then
		print("[EventManager] ✅ BaseModule inyectado exitosamente")
	end
end

-------------------------------------------------------------------------
-- UTILIDADES (Sin cambios)
-------------------------------------------------------------------------

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

-------------------------------------------------------------------------
-- METEORITOS - 🔥 REFACTORIZADO CON VFX
-------------------------------------------------------------------------

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

	-- 🔥 NUEVO: HP para que dinosaurios puedan atacar meteoritos
	local meteorHP = typeConfig.HP or 100
	meteor:SetAttribute("HP", meteorHP)
	meteor:SetAttribute("MaxHP", meteorHP)
	meteor:SetAttribute("MeteorType", meteorType)

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

			-- ✅ NUEVO: Flash rojo en pantalla al recibir impacto
			if ScreenFlash then
				ScreenFlash:FireClient(ownerPlr, "Red", 0.4, 0.3)
			end
		end

		-- 🔥 NUEVO: DAÑO A JUGADORES (mecánica de salto para evadir)
		if hasMeteorDamage and MeteorDamageSystem then
			local basePart = getPlayerBasePart(ownerPlr)
			if basePart then
				MeteorDamageSystem:OnMeteorImpact(hitPos, basePart, meteorType)
			end
		end

		-- ✅ ARREGLADO: Lógica de daño a la base con validación de BaseModule
		local appliedAmount = 0

		if BaseModule and BaseModule.ApplyDamage then
			local rawDamage = typeConfig.Damage
			appliedAmount = BaseModule.ApplyDamage(userId, rawDamage)
			applied = appliedAmount > 0

			if Config.DEBUG_MODE then
				local currentHP = BaseModule.GetHP and BaseModule.GetHP(userId) or "?"
				print(("[Meteor] Impacto en base de userId=%d | raw=%d, applied=%d, HP restante=%s")
					:format(userId, rawDamage, appliedAmount, tostring(currentHP)))
			end

			if BaseModule.GetHP and BaseModule.GetHP(userId) > 0 then
				print(("[METEOR] Jugador %d sobrevivió!"):format(userId))
			end
		else
			warn("[EventManager] ⚠️ BaseModule no está disponible - no se aplicó daño")
			warn("[EventManager] ⚠️ Asegúrate de llamar EventManager:SetBaseModule(Base) en Main.Server.lua")
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

			if BaseModule and BaseModule.IsLowHP and BaseModule.IsLowHP(userId) then
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
			ShowNotif:FireClient(plr, "☄️ METEOR STORM", 3)
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

-------------------------------------------------------------------------
-- 💀 BOSS METEOR - Sistema de Fases
-------------------------------------------------------------------------

-- Fase 1: "Esquinas del Caos" - 4 meteoritos Small en esquinas NW→NE→SE→SW
local function BossPhase_Corners(plr: Player)
	local base = getPlayerBasePart(plr)
	if not base then return end

	local basePos = base.Position
	local offset = 25 -- studs desde el centro

	-- Esquinas en orden: NW, NE, SE, SW
	local corners = {
		Vector3.new(-offset, 0, -offset), -- NW
		Vector3.new(offset, 0, -offset),  -- NE
		Vector3.new(offset, 0, offset),   -- SE
		Vector3.new(-offset, 0, offset)   -- SW
	}

	for i, cornerOffset in ipairs(corners) do
		task.delay((i - 1) * 0.8, function() -- 0.8s entre cada meteorito
			local startPos = basePos + cornerOffset + Vector3.new(0, 120, 0)
			local targetPos = basePos + cornerOffset * 0.5
			spawnMeteorTowards(plr, startPos, targetPos, "Small")
		end)
	end

	if Config.DEBUG_MODE then
		print(("[BossMeteor] Fase 1 'Esquinas del Caos' ejecutada para %s"):format(plr.Name))
	end
end

-- Fase 2: "Círculo Infernal" - 6 meteoritos Normal en círculo rotando
local function BossPhase_Circle(plr: Player)
	local base = getPlayerBasePart(plr)
	if not base then return end

	local basePos = base.Position
	local radius = 35  -- ✅ Radio aumentado para patrón más visible
	local meteorCount = 6

	for i = 1, meteorCount do
		task.delay((i - 1) * 0.5, function() -- 0.5s entre cada meteorito
			local angle = (i / meteorCount) * math.pi * 2
			local offset = Vector3.new(
				math.cos(angle) * radius,
				0,
				math.sin(angle) * radius
			)

			-- ✅ Spawn desde arriba del punto del círculo
			local startPos = basePos + offset + Vector3.new(0, 100, 0)
			-- ✅ ARREGLADO: Caer directamente en el punto del círculo (offset completo)
			local targetPos = basePos + offset
			spawnMeteorTowards(plr, startPos, targetPos, "Normal")
		end)
	end

	if Config.DEBUG_MODE then
		print(("[BossMeteor] Fase 2 'Círculo Infernal' ejecutada para %s"):format(plr.Name))
	end
end

-- Fase 3: "El Coloso" - 1 meteorito GIGANTE lento (8s caída)
local function BossPhase_Colossus(plr: Player)
	local base = getPlayerBasePart(plr)
	if not base then return end

	local basePos = base.Position

	-- Spawn muy alto para caída lenta épica
	local startPos = basePos + Vector3.new(0, 250, 0)
	local targetPos = basePos

	-- Usar tipo Boss (más grande, más lento, más daño)
	local meteor = createMeteor("Boss")
	meteor.Position = startPos
	meteor.Parent = workspace

	meteor:SetAttribute("TargetUserId", plr.UserId)
	meteor:SetAttribute("MeteorType", "Boss")

	-- VFX trail épico
	task.spawn(function()
		while meteor and meteor.Parent do
			VFXManager:PlayEffect("MeteorTrail", meteor.Position, meteor)
			task.wait(0.1)
		end
	end)

	-- Velocidad MUY lenta para caída dramática
	local dir = (targetPos - startPos).Unit
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = dir * 15 + Vector3.new(0, -15, 0) -- Muy lento
	bv.Parent = meteor

	-- Notificación épica
	if ShowNotification then
		ShowNotification:FireClient(plr, "💀 THE COLOSSUS DESCENDS!", 4)
	end

	-- Sistema de impacto (igual que spawnMeteorTowards pero con más drama)
	local applied = false
	local conn: RBXScriptConnection? = nil

	local function cleanup()
		if conn then conn:Disconnect() end
		meteor.Anchored = true
		Debris:AddItem(meteor, 0.1)
	end

	task.delay(12, function() -- Más tiempo para caída lenta
		if meteor and meteor.Parent and not applied then
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

		-- ¡EXPLOSIÓN ÉPICA!
		VFXManager:PlayEffect("MeteorExplosion", hitPos)

		local ownerPlr = Players:GetPlayerByUserId(userId)
		if ownerPlr then
			-- Shake EXTRA HEAVY
			if CameraShake then
				CameraShake:FireClient(ownerPlr, "Heavy", 1.5)
			end

			-- Flash rojo intenso
			if ScreenFlash then
				ScreenFlash:FireClient(ownerPlr, "Red", 0.6, 0.5)
			end
		end

		-- Daño
		if BaseModule and BaseModule.ApplyDamage then
			local typeConfig = Config.METEOR_TYPES.Boss
			local rawDamage = typeConfig.Damage
			local appliedAmount = BaseModule.ApplyDamage(userId, rawDamage)
			applied = appliedAmount > 0

			if Config.DEBUG_MODE then
				print(("[BossMeteor] COLOSSUS impactó - daño=%d"):format(rawDamage))
			end

			if ownerPlr and appliedAmount > 0 then
				if BaseDamaged then
					BaseDamaged:FireClient(ownerPlr, appliedAmount)
				end
			end
		end

		cleanup()
	end)

	Debris:AddItem(meteor, 15)

	if Config.DEBUG_MODE then
		print(("[BossMeteor] Fase 3 'El Coloso' ejecutada para %s"):format(plr.Name))
	end
end

-- Fase 4: "Triángulo de Fuego" - 3 meteoritos Large en triángulo simultáneo
local function BossPhase_Triangle(plr: Player)
	local base = getPlayerBasePart(plr)
	if not base then return end

	local basePos = base.Position
	local radius = 20

	-- Triángulo equilátero: 3 puntos a 120° cada uno
	for i = 1, 3 do
		task.delay(0.2, function() -- Casi simultáneos (0.2s delay para drama)
			local angle = (i / 3) * math.pi * 2 + math.pi / 6 -- Offset para rotación
			local offset = Vector3.new(
				math.cos(angle) * radius,
				0,
				math.sin(angle) * radius
			)

			local startPos = basePos + offset + Vector3.new(0, 130, 0)
			local targetPos = basePos + offset * 0.4
			spawnMeteorTowards(plr, startPos, targetPos, "Large")
		end)
	end

	if Config.DEBUG_MODE then
		print(("[BossMeteor] Fase 4 'Triángulo de Fuego' ejecutada para %s"):format(plr.Name))
	end
end

-- 💀 FUNCIÓN PRINCIPAL: BossMeteor
function EventManager:BossMeteor(waveNum: number, isFullBoss: boolean)
	print(("[EVENT] 💀 BOSS METEOR iniciado - Wave %d | Full Boss: %s"):format(waveNum, tostring(isFullBoss)))

	local phaseNames = {
		"Esquinas del Caos",
		"Círculo Infernal",
		"El Coloso",
		"Triángulo de Fuego"
	}

	local phaseFunctions = {
		BossPhase_Corners,
		BossPhase_Circle,
		BossPhase_Colossus,
		BossPhase_Triangle
	}

	-- Elegir fases
	local phasesToExecute = {}
	if isFullBoss then
		-- Boss completo: las 4 fases en orden
		phasesToExecute = {1, 2, 3, 4}

		if ShowNotification then
			for _, plr in ipairs(Players:GetPlayers()) do
				ShowNotification:FireClient(plr, "💀 BOSS WAVE: The Crimson Colossus", 5)
			end
		end
	else
		-- Mini-boss: 1 fase aleatoria
		local randomPhase = math.random(1, 4)
		phasesToExecute = {randomPhase}

		if ShowNotification then
			for _, plr in ipairs(Players:GetPlayers()) do
				ShowNotification:FireClient(plr, string.format("💀 MINI-BOSS: %s", phaseNames[randomPhase]), 4)
			end
		end
	end

	-- Ejecutar fases
	local totalDuration = 0
	for idx, phaseNum in ipairs(phasesToExecute) do
		task.delay(totalDuration, function()
			print(("[BossMeteor] Ejecutando Fase %d: %s"):format(phaseNum, phaseNames[phaseNum]))

			-- Anunciar fase
			if ShowNotification and isFullBoss then
				for _, plr in ipairs(Players:GetPlayers()) do
					ShowNotification:FireClient(plr, string.format("🔥 PHASE %d: %s", phaseNum, phaseNames[phaseNum]), 3)
				end
			end

			-- Ejecutar fase para cada jugador
			for _, plr in ipairs(Players:GetPlayers()) do
				phaseFunctions[phaseNum](plr)
			end
		end)

		-- Timing entre fases
		if phaseNum == 3 then
			totalDuration += 10 -- Coloso tarda más
		else
			totalDuration += 6 -- Otras fases
		end
	end

	-- Esperar a que terminen todas las fases
	task.wait(totalDuration + 2)

	print("[BossMeteor] ✅ Boss Meteor completado")
end

-- Limpieza
Players.PlayerRemoving:Connect(function(plr)
	DebugCooldowns[plr.UserId] = nil
end)

if Config.DEBUG_MODE then
	print("[EVENTMANAGER ARREGLADO] ✅ Módulo cargado - esperando inyección de BaseModule")
end

return EventManager
