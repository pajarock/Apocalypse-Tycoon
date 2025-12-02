--!strict
--[[
	TurretService.luau - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Servicio principal para el sistema de torretas defensivas.

	RESPONSABILIDADES:
	- Registrar/desregistrar torretas activas
	- Sistema de targeting (detectar meteoritos)
	- Sistema de disparo (aplicar daño)
	- Cooldown management
	- Upgrade de torretas (T1→T2→T3→T4→T5)
	- Shield Dome management

	INTEGRACIÓN:
	- Consume meteoritos del EventManager (legacy)
	- Se integra con UpgradeService para placement
	- Usa TurretDefinitions para stats

	═══════════════════════════════════════════════════════════════════════
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Knit)
local TurretDefinitions = require(script.Parent.TurretDefinitions)
local TurretVFXManager = require(ServerStorage.Managers.TurretVFXManager)

--[[────────────────────────────────────────────────────────────────────────
	TYPE DEFINITIONS
────────────────────────────────────────────────────────────────────────]]

type TurretData = {
	ObjectId: string,
	UserId: number,
	Model: Model,
	Definition: any,  -- TurretDefinition
	LastFireTime: number,
	CurrentTarget: Model?,
	IsActive: boolean,

	-- Shield Dome específico
	DomeActive: boolean?,
	DomeHP: number?,
	DomeEndTime: number?,
	LastCooldownTime: number?,
}

--[[────────────────────────────────────────────────────────────────────────
	SERVICE DEFINITION
────────────────────────────────────────────────────────────────────────]]

local TurretService = Knit.CreateService({
	Name = "TurretService",
	Client = {},
})

-- Storage de torretas activas
local activeTurrets: {[string]: TurretData} = {}

-- Configuración
local UPDATE_RATE = 0.1  -- Actualizar targeting cada 0.1s
local METEOR_FOLDER_NAME = "Meteors"  -- Carpeta donde están los meteoritos

--[[────────────────────────────────────────────────────────────────────────
	INITIALIZATION
────────────────────────────────────────────────────────────────────────]]

function TurretService:KnitInit()
	print("[TurretService] Initializing...")
end

function TurretService:KnitStart()
	print("[TurretService] Starting turret systems...")

	-- Iniciar update loop para targeting y disparo
	RunService.Heartbeat:Connect(function()
		self:UpdateAllTurrets()
	end)

	print("[TurretService] ✅ Turret systems online")
end

--[[────────────────────────────────────────────────────────────────────────
	PUBLIC API - Registration
────────────────────────────────────────────────────────────────────────]]

--[[
	Registra una nueva torreta en el sistema.

	@param objectId - ID único del objeto
	@param userId - ID del dueño
	@param model - Modelo físico de la torreta
	@param turretName - Nombre de la torreta (ej: "MachineGunT1")
	@return boolean - true si se registró exitosamente
]]
function TurretService:RegisterTurret(objectId: string, userId: number, model: Model, turretName: string): boolean
	local definition = TurretDefinitions.GetDefinition(turretName)
	if not definition then
		warn(("[TurretService] Definición no encontrada: %s"):format(turretName))
		return false
	end

	-- Crear data de la torreta
	local turretData: TurretData = {
		ObjectId = objectId,
		UserId = userId,
		Model = model,
		Definition = definition,
		LastFireTime = 0,
		CurrentTarget = nil,
		IsActive = true,
	}

	-- Si es Shield Dome, inicializar estado especial
	if definition.TurretType == "ShieldDome" then
		turretData.DomeActive = false
		turretData.DomeHP = definition.Stats.DomeHP
		turretData.DomeEndTime = 0
		turretData.LastCooldownTime = 0
	end

	activeTurrets[objectId] = turretData

	print(("[TurretService] ✅ Registered %s (Owner: %d)"):format(definition.DisplayName, userId))
	return true
end

--[[
	Desregistra una torreta del sistema.

	@param objectId - ID del objeto a desregistrar
]]
function TurretService:UnregisterTurret(objectId: string)
	local turretData = activeTurrets[objectId]
	if turretData then
		print(("[TurretService] ❌ Unregistered %s"):format(turretData.Definition.DisplayName))
		activeTurrets[objectId] = nil
	end
end

--[[
	Obtiene información de una torreta específica.

	@param objectId - ID del objeto
	@return TurretData? - Data de la torreta, o nil si no existe
]]
function TurretService:GetTurretData(objectId: string): TurretData?
	return activeTurrets[objectId]
end

--[[────────────────────────────────────────────────────────────────────────
	UPGRADE SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Upgradea una torreta al siguiente tier.

	@param objectId - ID del objeto a upgradear
	@return boolean - true si se upgradeó exitosamente
]]
function TurretService:UpgradeTurret(objectId: string): boolean
	local turretData = activeTurrets[objectId]
	if not turretData then
		warn(("[TurretService] Torreta no encontrada: %s"):format(objectId))
		return false
	end

	local currentName = turretData.Definition.Name
	local nextTierName = TurretDefinitions.GetNextTier(currentName)

	if not nextTierName then
		warn(("[TurretService] Torreta ya está en tier máximo: %s"):format(currentName))
		return false
	end

	local nextDefinition = TurretDefinitions.GetDefinition(nextTierName)
	if not nextDefinition then
		warn(("[TurretService] Siguiente tier no encontrado: %s"):format(nextTierName))
		return false
	end

	-- Actualizar definición
	turretData.Definition = nextDefinition

	-- Actualizar visual del modelo
	self:UpdateTurretVisual(turretData)

	print(("[TurretService] ⬆️ Upgraded %s → %s"):format(currentName, nextTierName))
	return true
end

--[[
	Actualiza el visual de una torreta después de un upgrade.

	@param turretData - Data de la torreta
]]
function TurretService:UpdateTurretVisual(turretData: TurretData)
	local model = turretData.Model
	local definition = turretData.Definition

	-- Actualizar MainPart
	local mainPart = model:FindFirstChild("MainPart") :: Part?
	if mainPart then
		mainPart.Size = definition.Size
		mainPart.Color = definition.Color
		mainPart.Material = definition.Material

		-- Actualizar highlight
		local highlight = mainPart:FindFirstChild("Highlight") :: Highlight?
		if highlight then
			highlight.FillColor = definition.Color
		end
	end

	-- Actualizar nombre en billboard
	local billboard = mainPart and mainPart:FindFirstChild("NameTag") :: BillboardGui?
	if billboard then
		local label = billboard:FindFirstChild("TextLabel") :: TextLabel?
		if label then
			label.Text = definition.DisplayName
		end
	end
end

--[[────────────────────────────────────────────────────────────────────────
	TARGETING SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Update loop principal - ejecuta targeting y disparo para todas las torretas.
]]
function TurretService:UpdateAllTurrets()
	local currentTime = tick()

	for objectId, turretData in pairs(activeTurrets) do
		if not turretData.IsActive then
			continue
		end

		-- Verificar que el modelo siga existiendo
		if not turretData.Model or not turretData.Model.Parent then
			self:UnregisterTurret(objectId)
			continue
		end

		-- Shield Dome tiene lógica especial
		if turretData.Definition.TurretType == "ShieldDome" then
			self:UpdateShieldDome(turretData, currentTime)
			continue
		end

		-- Targeting normal
		local target = self:FindTarget(turretData)
		turretData.CurrentTarget = target

		-- Si hay target, intentar disparar
		if target then
			self:TryFire(turretData, target, currentTime)
		end
	end
end

--[[
	Encuentra el mejor target para una torreta según su prioridad.

	@param turretData - Data de la torreta
	@return Model? - Target encontrado, o nil
]]
function TurretService:FindTarget(turretData: TurretData): Model?
	local model = turretData.Model
	local definition = turretData.Definition
	local stats = definition.Stats

	-- Obtener posición de la torreta
	local turretPos = model:GetPivot().Position

	-- Buscar meteoritos en el workspace
	local meteorsFolder = workspace:FindFirstChild(METEOR_FOLDER_NAME)
	if not meteorsFolder then
		return nil
	end

	local potentialTargets = {}

	-- Filtrar meteoritos dentro del rango
	for _, meteor in ipairs(meteorsFolder:GetChildren()) do
		if not meteor:IsA("BasePart") and not meteor:IsA("Model") then
			continue
		end

		local meteorPos = if meteor:IsA("Model") then meteor:GetPivot().Position else meteor.Position
		local distance = (meteorPos - turretPos).Magnitude

		if distance <= stats.Range then
			table.insert(potentialTargets, {
				Model = meteor,
				Distance = distance,
				HP = self:GetMeteorHP(meteor),
			})
		end
	end

	-- Si no hay targets, retornar nil
	if #potentialTargets == 0 then
		return nil
	end

	-- Ordenar según prioridad
	local priority = stats.TargetPriority

	if priority == "Closest" then
		table.sort(potentialTargets, function(a, b)
			return a.Distance < b.Distance
		end)
	elseif priority == "Furthest" then
		table.sort(potentialTargets, function(a, b)
			return a.Distance > b.Distance
		end)
	elseif priority == "Strongest" then
		table.sort(potentialTargets, function(a, b)
			return a.HP > b.HP
		end)
	elseif priority == "Weakest" then
		table.sort(potentialTargets, function(a, b)
			return a.HP < b.HP
		end)
	end

	return potentialTargets[1].Model
end

--[[
	Obtiene el HP actual de un meteorito.

	@param meteor - Meteorito (Part o Model)
	@return number - HP del meteorito
]]
function TurretService:GetMeteorHP(meteor: Instance): number
	-- Buscar en Attributes
	local hp = meteor:GetAttribute("HP")
	if hp then
		return hp
	end

	-- Buscar en IntValue
	local hpValue = meteor:FindFirstChild("HP") :: IntValue?
	if hpValue then
		return hpValue.Value
	end

	-- Default (meteorito sin HP tracking)
	return 100
end

--[[────────────────────────────────────────────────────────────────────────
	FIRING SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Intenta disparar a un target si el cooldown lo permite.

	@param turretData - Data de la torreta
	@param target - Target a atacar
	@param currentTime - Tiempo actual
]]
function TurretService:TryFire(turretData: TurretData, target: Model, currentTime: number)
	local definition = turretData.Definition
	local stats = definition.Stats

	-- Obtener cooldown apropiado
	local cooldown = stats.FireRate or stats.Cooldown or 1.0

	-- Verificar si puede disparar
	if currentTime - turretData.LastFireTime < cooldown then
		return
	end

	-- Disparar según tipo
	local turretType = definition.TurretType

	if turretType == "MachineGun" then
		self:FireMachineGun(turretData, target)
	elseif turretType == "Laser" then
		self:FireLaser(turretData, target)
	elseif turretType == "Missile" then
		self:FireMissile(turretData, target)
	elseif turretType == "Tesla" then
		self:FireTesla(turretData, target)
	end

	-- Actualizar último disparo
	turretData.LastFireTime = currentTime
end

--[[
	Dispara una ráfaga de Machine Gun.

	@param turretData - Data de la torreta
	@param target - Target a atacar
]]
function TurretService:FireMachineGun(turretData: TurretData, target: Model)
	local stats = turretData.Definition.Stats
	local damage = stats.Damage or 10

	-- Aplicar daño directo
	self:ApplyDamage(target, damage)

	-- VFX
	local turretPos = turretData.Model:GetPivot().Position
	local targetPos = target:GetPivot().Position
	TurretVFXManager:CreateMachineGunTracer(turretPos, targetPos)
end

--[[
	Dispara un rayo láser continuo.

	@param turretData - Data de la torreta
	@param target - Target a atacar
]]
function TurretService:FireLaser(turretData: TurretData, target: Model)
	local stats = turretData.Definition.Stats
	local dps = stats.DPS or 25

	-- Laser aplica daño por frame (DPS / 60)
	local damagePerFrame = dps / 60
	self:ApplyDamage(target, damagePerFrame)

	-- VFX (beam continuo)
	local turretPos = turretData.Model:GetPivot().Position
	local targetPos = target:GetPivot().Position
	TurretVFXManager:CreateLaserBeam(turretPos, targetPos, 0.1)
end

--[[
	Dispara un misil explosivo con AOE.

	@param turretData - Data de la torreta
	@param target - Target a atacar
]]
function TurretService:FireMissile(turretData: TurretData, target: Model)
	local stats = turretData.Definition.Stats
	local damage = stats.Damage or 80
	local aoeRadius = stats.AOERadius or 12

	-- Obtener posición del target
	local targetPos = target:GetPivot().Position

	-- Aplicar daño AOE
	self:ApplyAOEDamage(targetPos, aoeRadius, damage)

	-- VFX (explosión)
	TurretVFXManager:CreateMissileExplosion(targetPos, aoeRadius)
end

--[[
	Dispara cadenas eléctricas de Tesla.

	@param turretData - Data de la torreta
	@param target - Target inicial
]]
function TurretService:FireTesla(turretData: TurretData, target: Model)
	local stats = turretData.Definition.Stats
	local damage = stats.Damage or 35
	local maxChains = stats.MaxChains or 2
	local chainRange = stats.ChainRange or 20

	-- Lista de targets ya afectados
	local affectedTargets = {}
	local affectedPositions = {}  -- Para VFX
	local currentTarget = target

	-- Aplicar cadenas
	for i = 1, maxChains do
		if not currentTarget then
			break
		end

		-- Aplicar daño
		self:ApplyDamage(currentTarget, damage)
		table.insert(affectedTargets, currentTarget)
		table.insert(affectedPositions, currentTarget:GetPivot().Position)

		-- Buscar siguiente target en cadena
		if i < maxChains then
			currentTarget = self:FindNextChainTarget(currentTarget, chainRange, affectedTargets)
		end
	end

	-- VFX (cadenas eléctricas)
	if #affectedPositions >= 2 then
		TurretVFXManager:CreateTeslaChain(affectedPositions)
	end
end

--[[
	Encuentra el siguiente target para una cadena de Tesla.

	@param currentTarget - Target actual
	@param chainRange - Rango de cadena
	@param affectedTargets - Targets ya afectados
	@return Model? - Siguiente target, o nil
]]
function TurretService:FindNextChainTarget(currentTarget: Model, chainRange: number, affectedTargets: {Model}): Model?
	local currentPos = currentTarget:GetPivot().Position
	local meteorsFolder = workspace:FindFirstChild(METEOR_FOLDER_NAME)

	if not meteorsFolder then
		return nil
	end

	local closestTarget = nil
	local closestDistance = math.huge

	for _, meteor in ipairs(meteorsFolder:GetChildren()) do
		-- Skip si ya fue afectado
		if table.find(affectedTargets, meteor) then
			continue
		end

		local meteorPos = if meteor:IsA("Model") then meteor:GetPivot().Position else meteor.Position
		local distance = (meteorPos - currentPos).Magnitude

		if distance <= chainRange and distance < closestDistance then
			closestTarget = meteor
			closestDistance = distance
		end
	end

	return closestTarget
end

--[[────────────────────────────────────────────────────────────────────────
	DAMAGE SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Aplica daño a un meteorito.

	@param meteor - Meteorito a dañar
	@param damage - Cantidad de daño
]]
function TurretService:ApplyDamage(meteor: Instance, damage: number)
	-- Intentar aplicar daño vía Attribute
	local currentHP = meteor:GetAttribute("HP")
	if currentHP then
		local newHP = math.max(0, currentHP - damage)
		meteor:SetAttribute("HP", newHP)

		-- Si HP llegó a 0, destruir meteorito
		if newHP <= 0 then
			meteor:Destroy()
		end
		return
	end

	-- Intentar aplicar daño vía IntValue
	local hpValue = meteor:FindFirstChild("HP") :: IntValue?
	if hpValue then
		local newHP = math.max(0, hpValue.Value - damage)
		hpValue.Value = newHP

		if newHP <= 0 then
			meteor:Destroy()
		end
		return
	end

	-- Si no tiene HP tracking, destruir directamente
	meteor:Destroy()
end

--[[
	Aplica daño AOE en un radio.

	@param center - Centro de la explosión
	@param radius - Radio de daño
	@param damage - Cantidad de daño
]]
function TurretService:ApplyAOEDamage(center: Vector3, radius: number, damage: number)
	local meteorsFolder = workspace:FindFirstChild(METEOR_FOLDER_NAME)
	if not meteorsFolder then
		return
	end

	for _, meteor in ipairs(meteorsFolder:GetChildren()) do
		local meteorPos = if meteor:IsA("Model") then meteor:GetPivot().Position else meteor.Position
		local distance = (meteorPos - center).Magnitude

		if distance <= radius then
			-- Daño disminuye con la distancia (falloff)
			local falloff = 1 - (distance / radius) * 0.5  -- 50% daño en borde
			local finalDamage = damage * falloff

			self:ApplyDamage(meteor, finalDamage)
		end
	end
end

--[[────────────────────────────────────────────────────────────────────────
	SHIELD DOME SYSTEM
────────────────────────────────────────────────────────────────────────]]

--[[
	Actualiza el estado de un Shield Dome.

	@param turretData - Data del Shield Dome
	@param currentTime - Tiempo actual
]]
function TurretService:UpdateShieldDome(turretData: TurretData, currentTime: number)
	local stats = turretData.Definition.Stats

	-- Si el domo está activo, verificar duración
	if turretData.DomeActive then
		if currentTime >= (turretData.DomeEndTime or 0) then
			-- Domo expiró
			self:DeactivateShieldDome(turretData)
			turretData.LastCooldownTime = currentTime
		end
		return
	end

	-- Si está en cooldown, verificar si terminó
	if turretData.LastCooldownTime and turretData.LastCooldownTime > 0 then
		local cooldownElapsed = currentTime - turretData.LastCooldownTime
		if cooldownElapsed < (stats.Cooldown or 40) then
			return  -- Todavía en cooldown
		end
	end

	-- TODO: Auto-activar cuando base HP < 30% (requiere integración con BaseModule)
	-- Por ahora, el jugador debe activarlo manualmente
end

--[[
	Activa el Shield Dome.

	@param objectId - ID del Shield Dome
	@return boolean - true si se activó exitosamente
]]
function TurretService:ActivateShieldDome(objectId: string): boolean
	local turretData = activeTurrets[objectId]
	if not turretData or turretData.Definition.TurretType ~= "ShieldDome" then
		return false
	end

	-- Verificar cooldown
	local currentTime = tick()
	if turretData.LastCooldownTime and turretData.LastCooldownTime > 0 then
		local cooldownElapsed = currentTime - turretData.LastCooldownTime
		local cooldownRequired = turretData.Definition.Stats.Cooldown or 40

		if cooldownElapsed < cooldownRequired then
			warn(("[TurretService] Shield Dome en cooldown: %.1fs restantes"):format(cooldownRequired - cooldownElapsed))
			return false
		end
	end

	-- Activar domo
	turretData.DomeActive = true
	turretData.DomeHP = turretData.Definition.Stats.DomeHP
	turretData.DomeEndTime = currentTime + (turretData.Definition.Stats.DomeDuration or 15)

	print(("[TurretService] 🛡️ Shield Dome ACTIVATED for %ds"):format(turretData.Definition.Stats.DomeDuration or 15))

	-- TODO: VFX (próxima fase)
	-- self:CreateShieldDomeVFX(turretData)

	return true
end

--[[
	Desactiva el Shield Dome.

	@param turretData - Data del Shield Dome
]]
function TurretService:DeactivateShieldDome(turretData: TurretData)
	turretData.DomeActive = false
	print("[TurretService] 🛡️ Shield Dome DEACTIVATED")

	-- TODO: VFX (próxima fase)
	-- self:DestroyShieldDomeVFX(turretData)
end

--[[────────────────────────────────────────────────────────────────────────
	STATS & DEBUG
────────────────────────────────────────────────────────────────────────]]

--[[
	Obtiene estadísticas de todas las torretas activas.

	@return {[string]: any} - Diccionario con stats
]]
function TurretService:GetStats(): {[string]: any}
	local stats = {
		TotalTurrets = 0,
		ByType = {
			MachineGun = 0,
			Laser = 0,
			Missile = 0,
			Tesla = 0,
			ShieldDome = 0,
		},
	}

	for _, turretData in pairs(activeTurrets) do
		stats.TotalTurrets += 1
		local turretType = turretData.Definition.TurretType
		stats.ByType[turretType] = (stats.ByType[turretType] or 0) + 1
	end

	return stats
end

return TurretService
