--!strict
--[[
	UpgradeService - Maneja la funcionalidad de upgrades

	RESPONSABILIDADES:
	- Gestionar upgrades activos (generators, turrets, storage)
	- Update loop para generators (producci�n de dinero)
	- Update loop para turrets (targeting y disparo)
	- C�lculo de capacidad total de storage
	- Repair station interaction

	ARQUITECTURA:
	- Knit Service (servidor-side)
	- Integra con BaseOwnershipService para tracking de objetos
	- Integra con PlayerDataService para dar dinero
	- Update loops separados para cada categor�a de upgrade

	OPTIMIZACI�N:
	- Generators: Update cada segundo (batch processing)
	- Turrets: Update cada frame solo para turrets activos
	- Storage: C�lculo on-demand (no loop)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Knit)
local UpgradeDefinitions = require(script.Parent.UpgradeDefinitions)
local GeneratorVFXManager = require(ServerStorage.Managers.GeneratorVFXManager)

--[[------------------------------------------------------------------------
	SERVICE DEFINITION
------------------------------------------------------------------------]]

local UpgradeService = Knit.CreateService({
	Name = "UpgradeService",
})

-- Internal state
local activeGenerators = {}  -- {[objectId] = {UserId, LastProduction, Definition}}
local activeTurrets = {}     -- {[objectId] = {UserId, Model, Definition, LastShot}}
local repairStations = {}    -- {[objectId] = {UserId, Model}}

-- Services (obtenidos en KnitStart)
local BaseOwnershipService
local PlayerDataService
local TurretService  -- NEW: Sistema de torretas defensivas

--[[────────────────────────────────────────────────────────────────────────
	HELPER FUNCTIONS
────────────────────────────────────────────────────────────────────────]]

--[[
	Convierte tier number a tier name

	@param tier - Número del tier (1-5)
	@return string - Nombre del tier (Generator, GeneratorT2, etc.)
]]
local function getTierName(tier: number): string
	if tier == 1 then
		return "Generator"
	elseif tier == 2 then
		return "GeneratorT2"
	elseif tier == 3 then
		return "GeneratorT3"
	elseif tier == 4 then
		return "GeneratorT4"
	elseif tier == 5 then
		return "GeneratorT5"
	else
		return "Generator"
	end
end

--[[────────────────────────────────────────────────────────────────────────
	GENERATOR SYSTEM - Passive Money Production
------------------------------------------------------------------------]]

--[[
	Registra un generator para producci�n autom�tica.

	@param objectId - ID del objeto
	@param userId - Due�o del generator
	@param model - Modelo 3D del generator
	@param objectType - Tipo de generator (Generator, GeneratorT2, GeneratorT3)
]]
function UpgradeService:RegisterGenerator(objectId: string, userId: number, model: Model, objectType: string?)
	-- Default a "Generator" si no se especifica
	local generatorType = objectType or "Generator"

	local definition = UpgradeDefinitions.GetDefinition(generatorType)
	if not definition then
		warn(string.format("[UpgradeService] Definition not found for: %s", generatorType))
		return
	end

	-- FASE 3: Detectar tier autom�ticamente basado en el tipo
	local tier = 1
	if generatorType == "GeneratorT2" then
		tier = 2
	elseif generatorType == "GeneratorT3" then
		tier = 3
	elseif generatorType == "GeneratorT4" then
		tier = 4
	elseif generatorType == "GeneratorT5" then
		tier = 5
	end

	activeGenerators[objectId] = {
		UserId = userId,
		LastProduction = os.time(),
		Definition = definition,
		Model = model,
		Tier = tier, -- Guardar tier para uso posterior
		TotalProduced = 0, -- FASE 2: Tracking de dinero total producido
		SpawnTime = os.time(), -- FASE 2: Tiempo de spawn para calcular uptime

		-- OVERCLOCK SYSTEM
		OverclockActive = false,
		OverclockEndTime = 0,
		OverclockCooldownEndTime = 0,
		Stability = 100, -- 0-100, reduces with overclock use
	}

	-- FASE 3: Almacenar stats en el modelo para acceso din�mico desde ProximityPrompt
	local mainPart = model:FindFirstChild("MainPart")
	if mainPart then
		-- Crear valores para tracking din�mico
		local totalProducedValue = Instance.new("NumberValue")
		totalProducedValue.Name = "TotalProduced"
		totalProducedValue.Value = 0
		totalProducedValue.Parent = mainPart

		local spawnTimeValue = Instance.new("NumberValue")
		spawnTimeValue.Name = "SpawnTime"
		spawnTimeValue.Value = os.time()
		spawnTimeValue.Parent = mainPart

		local moneyPerSecValue = Instance.new("NumberValue")
		moneyPerSecValue.Name = "MoneyPerSec"
		moneyPerSecValue.Value = definition.Stats.MoneyPerSecond or 0
		moneyPerSecValue.Parent = mainPart

		local tierValue = Instance.new("IntValue")
		tierValue.Name = "Tier"
		tierValue.Value = tier
		tierValue.Parent = mainPart
	end

	-- FASE 2: Animaci�n de construcci�n (incluye efectos visuales)
	local mainPart = model:FindFirstChild("MainPart") or model:FindFirstChild("HumanoidRootPart")
	if mainPart then
		local finalPosition = mainPart.Position
		GeneratorVFXManager:PlayConstructionAnimation(model, finalPosition, tier)
	else
		-- Fallback: aplicar efectos inmediatamente si no hay MainPart
		GeneratorVFXManager:ApplyGlowPulse(model, tier)
		GeneratorVFXManager:CreateParticles(model, tier)
		GeneratorVFXManager:CreateAmbientSound(model)
	end

	-- FASE 2: Crear ProximityPrompt con stats
	-- PHASE 4: Pasar objectId para que se pueda usar en upgrades
	GeneratorVFXManager:CreateStatsPrompt(model, userId, tier, objectId)

	-- Sincronizar estado inicial de Overclock a attributes
	syncOverclockAttributes(objectId)

	print(string.format(
		"[UpgradeService] ?? Generator registered: %s (Owner: %d, Rate: $%d/s, Tier: %d)",
		objectId,
		userId,
		definition.Stats.MoneyPerSecond or 0,
		tier
		))
end

--[[
	Quita un generator del sistema.

	@param objectId - ID del objeto
]]
function UpgradeService:UnregisterGenerator(objectId: string)
	if activeGenerators[objectId] then
		local data = activeGenerators[objectId]

		-- Limpiar efectos visuales
		if data.Model then
			GeneratorVFXManager:RemoveEffects(data.Model)

			-- FASE 2: Limpiar sonidos y ProximityPrompt
			local mainPart = data.Model:FindFirstChild("MainPart")
			if mainPart then
				-- Eliminar sonido ambiental
				local ambient = mainPart:FindFirstChild("GeneratorAmbient")
				if ambient then
					ambient:Destroy()
				end

				-- Eliminar ProximityPrompt
				local prompt = mainPart:FindFirstChild("StatsPrompt")
				if prompt then
					prompt:Destroy()
				end

				-- Eliminar billboard de estad�sticas (si est� visible)
				local statsBillboard = mainPart:FindFirstChild("StatsBillboard")
				if statsBillboard then
					statsBillboard:Destroy()
				end
			end
		end

		activeGenerators[objectId] = nil
		print(string.format("[UpgradeService] Generator unregistered: %s", objectId))
	end
end

--[[
	PHASE 4: Upgradea un generator al siguiente tier (T1→T2→T3).

	PROCESO:
	1. Validar que el jugador es el dueño
	2. Validar que puede upgradear (no está en tier máximo)
	3. Calcular costo y validar dinero suficiente
	4. Deducir dinero del jugador
	5. Actualizar el modelo en workspace (tamaño, color, efectos)
	6. Actualizar stats en activeGenerators
	7. Mostrar efectos visuales de upgrade

	@param objectId - ID del generator
	@param userId - ID del jugador que intenta upgradear
	@return boolean - true si el upgrade fue exitoso, false si falló
]]
function UpgradeService:UpgradeGenerator(objectId: string, userId: number): boolean
	print(string.format("[UpgradeService] 🔧 UpgradeGenerator called - objectId: %s, userId: %d", objectId, userId))

	local data = activeGenerators[objectId]
	if not data then
		warn(string.format("[UpgradeService] ❌ Generator not found: %s", objectId))
		print("[UpgradeService] 📊 Active generators count:", (function()
			local count = 0
			for _ in pairs(activeGenerators) do count += 1 end
			return count
		end)())
		return false
	end

	print(string.format("[UpgradeService] ✅ Generator found - Owner: %d, Tier: %s",
		data.UserId, data.Definition.Name))

	-- Validar ownership
	if data.UserId ~= userId then
		warn(string.format("[UpgradeService] ❌ Ownership mismatch - Generator owner: %d, Requester: %d",
			data.UserId, userId))
		return false
	end

	-- Obtener tier actual
	local currentTierName = data.Definition.Name

	-- Validar que puede upgradear
	if not UpgradeDefinitions.CanUpgrade(currentTierName) then
		warn(string.format("[UpgradeService] ❌ Already at max tier: %s", currentTierName))
		return false
	end

	-- Obtener siguiente tier y costo
	local nextTierName = UpgradeDefinitions.GetNextTier(currentTierName)
	local upgradeCost = UpgradeDefinitions.GetUpgradeCost(currentTierName)

	if not nextTierName or not upgradeCost then
		warn(string.format("[UpgradeService] ❌ Failed to get next tier info for %s", currentTierName))
		return false
	end

	print(string.format("[UpgradeService] 📊 Upgrade info - Current: %s, Next: %s, Cost: $%d",
		currentTierName, nextTierName, upgradeCost))

	-- Validar dinero suficiente y deducir
	if not PlayerDataService then
		warn("[UpgradeService] ❌ PlayerDataService not available")
		return false
	end

	print(string.format("[UpgradeService] 💰 Checking money for user %d (need $%d)", userId, upgradeCost))

	-- Intentar deducir dinero (DeductMoney verifica automáticamente si tiene suficiente)
	local success = PlayerDataService:DeductMoney(userId, upgradeCost)
	if not success then
		warn(string.format("[UpgradeService] ❌ User %d doesn't have enough money ($%d needed)", userId, upgradeCost))
		return false
	end

	print(string.format("[UpgradeService] ✅ Money deducted: $%d from user %d", upgradeCost, userId))

	-- Obtener nueva definición
	local nextDefinition = UpgradeDefinitions.GetDefinition(nextTierName)
	if not nextDefinition then
		warn(string.format("[UpgradeService] UpgradeGenerator: Definition not found for %s", nextTierName))
		return false
	end

	-- Calcular nuevo tier number
	local newTier = 1
	if nextTierName == "GeneratorT2" then
		newTier = 2
	elseif nextTierName == "GeneratorT3" then
		newTier = 3
	elseif nextTierName == "GeneratorT4" then
		newTier = 4
	elseif nextTierName == "GeneratorT5" then
		newTier = 5
	end

	local oldTier = data.Tier or 1

	-- Actualizar datos internos PRIMERO
	data.Definition = nextDefinition
	data.Tier = newTier

	-- Actualizar modelo en workspace
	if data.Model then
		local mainPart = data.Model:FindFirstChild("MainPart")
		if mainPart then
			-- Actualizar propiedades físicas
			mainPart.Size = nextDefinition.Size
			mainPart.Color = nextDefinition.Color
			mainPart.Material = nextDefinition.Material

			-- Actualizar highlight
			local highlight = mainPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = nextDefinition.Color
			end

			-- Actualizar valores en MainPart para stats dinámicos
			local moneyPerSecValue = mainPart:FindFirstChild("MoneyPerSec") :: NumberValue?
			if moneyPerSecValue then
				moneyPerSecValue.Value = nextDefinition.Stats.MoneyPerSecond or 0
			end

			local tierValue = mainPart:FindFirstChild("Tier") :: IntValue?
			if tierValue then
				tierValue.Value = newTier
			end

			-- Actualizar nombre del modelo
			data.Model.Name = nextTierName

			-- Actualizar billboard name tag (texto Y posición)
			local billboard = mainPart:FindFirstChild("NameTag")
			if billboard and billboard:IsA("BillboardGui") then
				-- Actualizar texto
				local label = billboard:FindFirstChild("TextLabel")
				if label then
					label.Text = nextDefinition.DisplayName
				end

				-- Actualizar posición basada en el nuevo tamaño del generador
				-- Fórmula: definition.Size.Y / 2 + 2 (misma que en UpgradeDefinitions.luau:414)
				billboard.StudsOffset = Vector3.new(0, nextDefinition.Size.Y / 2 + 2, 0)
			end

			-- FASE 4: Mostrar efectos visuales de upgrade
			GeneratorVFXManager:ShowUpgradeEffect(data.Model, oldTier, newTier)

			-- Recrear partículas y sonido ambiental para el nuevo tier
			GeneratorVFXManager:RemoveEffects(data.Model)  -- Ahora preserva StatsBillboard ✅
			GeneratorVFXManager:ApplyGlowPulse(data.Model, newTier)
			GeneratorVFXManager:CreateParticles(data.Model, newTier)
			GeneratorVFXManager:CreateAmbientSound(data.Model)

			-- CRÍTICO: Refrescar prompts después del upgrade para asegurar que todo funciona
			GeneratorVFXManager:RefreshPromptsAfterUpgrade(data.Model, newTier)
		end
	end

	print(string.format(
		"[UpgradeService] ✨ Generator upgraded: %s (T%d → T%d, Cost: $%d, New Rate: $%d/s)",
		objectId,
		oldTier,
		newTier,
		upgradeCost,
		nextDefinition.Stats.MoneyPerSecond or 0
	))

	return true
end

--[[────────────────────────────────────────────────────────────────────────
	TURRET UPGRADE SYSTEM (NEW)
────────────────────────────────────────────────────────────────────────]]

--[[
	Upgradea una torreta al siguiente tier (T1→T2→T3→T4→T5).

	Similar al sistema de generators, pero usando TurretService y TurretDefinitions.

	PROCESO:
	1. Validar que el jugador es el dueño
	2. Validar que puede upgradear (no está en tier máximo)
	3. Calcular costo y validar dinero suficiente
	4. Deducir dinero del jugador
	5. Actualizar el modelo en TurretService
	6. Mostrar efectos visuales de upgrade

	@param objectId - ID de la torreta
	@param userId - ID del jugador que intenta upgradear
	@return boolean - true si el upgrade fue exitoso, false si falló
]]
function UpgradeService:UpgradeTurret(objectId: string, userId: number): boolean
	-- Verificar que TurretService exista
	if not TurretService then
		warn("[UpgradeService] UpgradeTurret: TurretService not available")
		return false
	end

	-- Obtener data de la torreta desde TurretService
	local turretData = TurretService:GetTurretData(objectId)
	if not turretData then
		warn(string.format("[UpgradeService] UpgradeTurret: Turret not found: %s", objectId))
		return false
	end

	-- Validar ownership
	if turretData.UserId ~= userId then
		warn(string.format("[UpgradeService] UpgradeTurret: User %d is not owner of turret %s", userId, objectId))
		return false
	end

	-- Obtener tier actual usando TurretDefinitions
	local TurretDefinitions = require(script.Parent.TurretDefinitions)
	local currentTierName = turretData.Definition.Name

	-- Validar que puede upgradear
	if not TurretDefinitions.CanUpgrade(currentTierName) then
		warn(string.format("[UpgradeService] UpgradeTurret: Turret %s is already at max tier", objectId))
		return false
	end

	-- Obtener siguiente tier y costo
	local nextTierName = TurretDefinitions.GetNextTier(currentTierName)
	local upgradeCost = TurretDefinitions.GetUpgradeCost(currentTierName)

	if not nextTierName or not upgradeCost then
		warn(string.format("[UpgradeService] UpgradeTurret: Failed to get next tier or cost for %s", currentTierName))
		return false
	end

	-- Validar dinero suficiente y deducir
	if not PlayerDataService then
		warn("[UpgradeService] ❌ PlayerDataService not available")
		return false
	end

	print(string.format("[UpgradeService] 💰 Checking money for turret upgrade (user %d needs $%d)", userId, upgradeCost))

	-- Intentar deducir dinero
	local success = PlayerDataService:DeductMoney(userId, upgradeCost)
	if not success then
		warn(string.format("[UpgradeService] ❌ User %d doesn't have enough money ($%d needed)", userId, upgradeCost))
		return false
	end

	print(string.format("[UpgradeService] ✅ Money deducted: $%d from user %d", upgradeCost, userId))

	-- Upgradear la torreta en TurretService
	local upgradeSuccess = TurretService:UpgradeTurret(objectId)
	if not upgradeSuccess then
		-- Si falla, devolver el dinero
		PlayerDataService:AddMoney(userId, upgradeCost)
		warn(string.format("[UpgradeService] ❌ Failed to upgrade turret, money refunded"))
		return false
	end

	print(string.format(
		"[UpgradeService] ⬆️ Turret upgraded: %s → %s (Cost: $%d)",
		currentTierName,
		nextTierName,
		upgradeCost
	))

	-- TODO: VFX de upgrade (próxima fase)
	-- GeneratorVFXManager:PlayUpgradeEffect(turretData.Model, oldTier, newTier)

	return true
end

--[[
	Obtiene información de upgrade para una torreta.

	Devuelve información sobre el costo de upgrade, tier actual, siguiente tier, etc.
	Útil para mostrar en UI (ProximityPrompts, paneles, etc.)

	@param objectId - ID de la torreta
	@return table? - Información de upgrade, o nil si no existe/no puede upgradear
]]
function UpgradeService:GetTurretUpgradeInfo(objectId: string): table?
	if not TurretService then
		return nil
	end

	local turretData = TurretService:GetTurretData(objectId)
	if not turretData then
		return nil
	end

	local TurretDefinitions = require(script.Parent.TurretDefinitions)
	local currentTierName = turretData.Definition.Name

	if not TurretDefinitions.CanUpgrade(currentTierName) then
		return {
			CanUpgrade = false,
			CurrentTier = turretData.Definition.Tier,
			CurrentTierName = currentTierName,
			Reason = "Already at max tier",
		}
	end

	local nextTierName = TurretDefinitions.GetNextTier(currentTierName)
	local upgradeCost = TurretDefinitions.GetUpgradeCost(currentTierName)
	local nextDefinition = TurretDefinitions.GetDefinition(nextTierName)

	return {
		CanUpgrade = true,
		UpgradeCost = upgradeCost,
		CurrentTier = turretData.Definition.Tier,
		NextTier = nextDefinition and nextDefinition.Tier or 0,
		CurrentTierName = currentTierName,
		NextTierName = nextTierName,
		CurrentDPS = turretData.Definition.Stats.DPS or turretData.Definition.Stats.Damage or 0,
		NextDPS = nextDefinition and (nextDefinition.Stats.DPS or nextDefinition.Stats.Damage) or 0,
	}
end

--[[
	Update loop para generators - ejecuta cada segundo.

	PROCESO:
	1. Iterar sobre todos los generators activos
	2. Calcular dinero producido desde �ltima actualizaci�n
	3. Dar dinero al jugador (via PlayerDataService)
	4. Actualizar timestamp
]]
local function updateGenerators()
	local currentTime = os.time()

	for objectId, data in pairs(activeGenerators) do
		local timePassed = currentTime - data.LastProduction
		if timePassed >= 1 then
			-- Producir dinero
			local moneyToGive = (data.Definition.Stats.MoneyPerSecond or 0) * timePassed

			-- OVERCLOCK BOOST: +200% (3x multiplier)
			if data.OverclockActive then
				moneyToGive = moneyToGive * 3
			end

			-- Dar dinero al jugador (si PlayerDataService existe)
			if PlayerDataService then
				local success = pcall(function()
					PlayerDataService:AddMoney(data.UserId, moneyToGive)
				end)

				if success then
					-- FASE 2: Actualizar estad�sticas de producci�n
					data.TotalProduced = data.TotalProduced + moneyToGive

					-- FASE 3: Actualizar valor en el modelo para stats din�micos
					if data.Model then
						local mainPart = data.Model:FindFirstChild("MainPart")
						if mainPart then
							local totalProducedValue = mainPart:FindFirstChild("TotalProduced") :: NumberValue?
							if totalProducedValue then
								totalProducedValue.Value = data.TotalProduced
							end

							-- Mostrar efectos visuales
							local tier = data.Tier or 1
							GeneratorVFXManager:ShowMoneyProduction(data.Model, moneyToGive, tier)
							-- FASE 2: Reproducir sonido de "cash register"
							GeneratorVFXManager:PlayCashRegisterSound(data.Model)
						end
					end
				end
			end

			-- Actualizar timestamp
			data.LastProduction = currentTime
		end
	end
end

--[[------------------------------------------------------------------------
	TURRET SYSTEM - Auto-targeting Defense
------------------------------------------------------------------------]]

--[[
	Registra una turret para targeting autom�tico.

	@param objectId - ID del objeto
	@param userId - Due�o de la turret
	@param model - Modelo 3D de la turret
]]
function UpgradeService:RegisterTurret(objectId: string, userId: number, model: Model)
	local definition = UpgradeDefinitions.GetDefinition("Turret")
	if not definition then
		return
	end

	activeTurrets[objectId] = {
		UserId = userId,
		Model = model,
		Definition = definition,
		LastShot = 0,
	}

	print(string.format(
		"[UpgradeService] ?? Turret registered: %s (Owner: %d, Range: %.1f)",
		objectId,
		userId,
		definition.Stats.Range or 0
		))
end

--[[
	Quita una turret del sistema.

	@param objectId - ID del objeto
]]
function UpgradeService:UnregisterTurret(objectId: string)
	if activeTurrets[objectId] then
		activeTurrets[objectId] = nil
		print(string.format("[UpgradeService] Turret unregistered: %s", objectId))
	end
end

--[[
	Encuentra el meteoro/enemigo m�s cercano a la turret.

	@param turretPosition - Posici�n de la turret
	@param range - Rango de detecci�n
	@return Model? - Meteoro/enemigo m�s cercano, o nil
]]
local function findNearestTarget(turretPosition: Vector3, range: number): Model?
	-- TODO: Integrar con sistema de meteoros cuando exista
	-- Por ahora, buscar cualquier Part llamada "Meteor" o "Enemy" en Workspace

	local nearestTarget = nil
	local nearestDistance = range

	for _, object in workspace:GetChildren() do
		if object:IsA("Model") and (object.Name == "Meteor" or object.Name == "Enemy") then
			local primaryPart = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				local distance = (primaryPart.Position - turretPosition).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestTarget = object
				end
			end
		end
	end

	return nearestTarget
end

--[[
	Dispara un proyectil desde la turret hacia el objetivo.

	@param turretModel - Modelo de la turret
	@param target - Objetivo a disparar
	@param damage - Da�o del proyectil
]]
local function shootProjectile(turretModel: Model, target: Model, damage: number)
	local mainPart = turretModel:FindFirstChild("MainPart") :: BasePart?
	if not mainPart then
		return
	end

	local targetPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	if not targetPart then
		return
	end

	-- Crear proyectil
	local projectile = Instance.new("Part")
	projectile.Name = "TurretProjectile"
	projectile.Size = Vector3.new(1, 1, 1)
	projectile.Shape = Enum.PartType.Ball
	projectile.Color = Color3.fromRGB(255, 255, 0)
	projectile.Material = Enum.Material.Neon
	projectile.CanCollide = false
	projectile.Anchored = false
	projectile.CFrame = CFrame.new(mainPart.Position + Vector3.new(0, 2, 0))
	projectile.Parent = workspace

	-- Agregar BodyVelocity para mover el proyectil
	local direction = (targetPart.Position - projectile.Position).Unit
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = direction * 100  -- Velocidad del proyectil
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Parent = projectile

	-- Detectar colisi�n (destruir proyectil y da�ar objetivo)
	projectile.Touched:Connect(function(hit)
		if hit:IsDescendantOf(target) then
			-- TODO: Aplicar da�o al objetivo
			print(string.format("[UpgradeService] ?? Hit target: %s (Damage: %d)", target.Name, damage))

			-- Destruir objetivo (temporal - deber�a tener HP system)
			target:Destroy()

			-- Destruir proyectil
			projectile:Destroy()
		end
	end)

	-- Destruir proyectil despu�s de 5 segundos (si no impacta)
	task.delay(5, function()
		if projectile.Parent then
			projectile:Destroy()
		end
	end)
end

--[[
	Update loop para turrets - ejecuta cada frame.

	PROCESO:
	1. Iterar sobre todas las turrets activas
	2. Buscar objetivo m�s cercano en rango
	3. Si hay objetivo y fireRate permite, disparar
	4. Actualizar orientaci�n de la turret hacia el objetivo
]]
local function updateTurrets(deltaTime: number)
	local currentTime = tick()

	for objectId, data in pairs(activeTurrets) do
		local mainPart = data.Model:FindFirstChild("MainPart") :: BasePart?
		if not mainPart then
			continue
		end

		local fireRate = data.Definition.Stats.FireRate or 1
		local range = data.Definition.Stats.Range or 50
		local damage = data.Definition.Stats.Damage or 10

		-- Buscar objetivo
		local target = findNearestTarget(mainPart.Position, range)

		if target then
			local targetPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			if targetPart then
				-- Rotar turret hacia objetivo
				local lookDirection = (targetPart.Position - mainPart.Position).Unit
				mainPart.CFrame = CFrame.new(mainPart.Position, mainPart.Position + lookDirection)

				-- Disparar si cooldown permite
				local timeSinceLastShot = currentTime - data.LastShot
				if timeSinceLastShot >= (1 / fireRate) then
					shootProjectile(data.Model, target, damage)
					data.LastShot = currentTime
				end
			end
		end
	end
end

--[[------------------------------------------------------------------------
	STORAGE SYSTEM - Money Capacity
------------------------------------------------------------------------]]

--[[
	Calcula la capacidad total de storage para un jugador.

	@param userId - ID del jugador
	@return number - Capacidad total
]]
function UpgradeService:GetTotalStorageCapacity(userId: number): number
	local baseCapacity = 1000  -- Capacidad base sin upgrades

	-- Obtener todos los objetos del jugador
	local objects = BaseOwnershipService:GetBaseObjects(userId)

	-- Sumar capacidad de cada Storage
	local totalCapacity = baseCapacity
	for _, object in objects do
		if object.ObjectType == "Storage" then
			local definition = UpgradeDefinitions.GetDefinition("Storage")
			if definition and definition.Stats.Capacity then
				totalCapacity = totalCapacity + definition.Stats.Capacity
			end
		end
	end

	return totalCapacity
end

--[[------------------------------------------------------------------------
	REPAIR STATION SYSTEM - Mobile-Friendly Base Repair
------------------------------------------------------------------------]]

--[[
	Registra una repair station y conecta su ProximityPrompt.

	@param objectId - ID del objeto
	@param userId - Due�o de la repair station
	@param model - Modelo 3D de la repair station
]]
function UpgradeService:RegisterRepairStation(objectId: string, userId: number, model: Model)
	local definition = UpgradeDefinitions.GetDefinition("RepairStation")
	if not definition then
		return
	end

	repairStations[objectId] = {
		UserId = userId,
		Model = model,
	}

	-- Conectar ProximityPrompt
	local mainPart = model:FindFirstChild("MainPart")
	if mainPart then
		local prompt = mainPart:FindFirstChild("RepairPrompt") :: ProximityPrompt?
		if prompt then
			prompt.Triggered:Connect(function(player)
				-- Verificar que el jugador sea el due�o
				if player.UserId ~= userId then
					print(string.format("[UpgradeService] ? %s tried to use another player's repair station", player.Name))
					return
				end

				-- Intentar reparar
				local repairCost = definition.Stats.RepairCost or 25
				local repairAmount = definition.Stats.RepairAmount or 100

				-- TODO: Integrar con sistema de base HP
				-- Por ahora, solo deducir dinero
				if PlayerDataService then
					local currentMoney = PlayerDataService:GetMoney(userId)
					if currentMoney >= repairCost then
						PlayerDataService:RemoveMoney(userId, repairCost)
						print(string.format(
							"[UpgradeService] ?? %s repaired base: -%d money, +%d HP",
							player.Name,
							repairCost,
							repairAmount
							))

						-- TODO: Actualizar HP de la base
					else
						print(string.format("[UpgradeService] ? %s doesn't have enough money to repair", player.Name))
					end
				end
			end)
		end
	end

	print(string.format(
		"[UpgradeService] ?? Repair Station registered: %s (Owner: %d)",
		objectId,
		userId
		))
end

--[[
	Quita una repair station del sistema.

	@param objectId - ID del objeto
]]
function UpgradeService:UnregisterRepairStation(objectId: string)
	if repairStations[objectId] then
		repairStations[objectId] = nil
		print(string.format("[UpgradeService] Repair Station unregistered: %s", objectId))
	end
end

--[[------------------------------------------------------------------------
	PUBLIC API - Registration
------------------------------------------------------------------------]]

--[[
	Registra un upgrade en el sistema correspondiente.

	@param objectId - ID del objeto
	@param userId - Due�o del objeto
	@param objectType - Tipo de upgrade
	@param model - Modelo 3D
]]
function UpgradeService:RegisterUpgrade(objectId: string, userId: number, objectType: string, model: Model)
	-- FASE 3: Detectar todos los tipos de generadores
	if objectType == "Generator" or objectType == "GeneratorT2" or objectType == "GeneratorT3" or objectType == "GeneratorT4" or objectType == "GeneratorT5" then
		self:RegisterGenerator(objectId, userId, model, objectType)
	elseif objectType == "Turret" then
		-- Legacy turret
		self:RegisterTurret(objectId, userId, model)
	elseif objectType == "RepairStation" then
		self:RegisterRepairStation(objectId, userId, model)
	-- NEW: Detectar nuevas torretas del sistema de defensa
	elseif string.match(objectType, "^MachineGun") or string.match(objectType, "^Laser") or string.match(objectType, "^Missile") or string.match(objectType, "^Tesla") or objectType == "ShieldDome" then
		-- Registrar en el nuevo TurretService
		if TurretService then
			TurretService:RegisterTurret(objectId, userId, model, objectType)
			print(("[UpgradeService] ✅ Registered new turret: %s"):format(objectType))
		else
			warn("[UpgradeService] ⚠️ TurretService not available, turret won't function")
		end
	end
end

--[[
	Desregistra un upgrade del sistema.

	@param objectId - ID del objeto
	@param objectType - Tipo de upgrade
]]
function UpgradeService:UnregisterUpgrade(objectId: string, objectType: string)
	-- FASE 3: Detectar todos los tipos de generadores
	if objectType == "Generator" or objectType == "GeneratorT2" or objectType == "GeneratorT3" or objectType == "GeneratorT4" or objectType == "GeneratorT5" then
		self:UnregisterGenerator(objectId)
	elseif objectType == "Turret" then
		-- Legacy turret
		self:UnregisterTurret(objectId)
	elseif objectType == "RepairStation" then
		self:UnregisterRepairStation(objectId)
	-- NEW: Desregistrar nuevas torretas
	elseif string.match(objectType, "^MachineGun") or string.match(objectType, "^Laser") or string.match(objectType, "^Missile") or string.match(objectType, "^Tesla") or objectType == "ShieldDome" then
		if TurretService then
			TurretService:UnregisterTurret(objectId)
			print(("[UpgradeService] ❌ Unregistered turret: %s"):format(objectId))
		end
	end
end

--[[------------------------------------------------------------------------
	DEBUG / MONITORING API
------------------------------------------------------------------------]]

--[[
	Obtiene informaci�n de debugging sobre todos los upgrades activos.

	IMPORTANTE: Este m�todo es para debugging/monitoring.
	Retorna copias de datos, no referencias directas.

	@return DebugInfo - Tabla con informaci�n de todos los upgrades
]]
export type DebugInfo = {
	GeneratorCount: number,
	TurretCount: number,
	RepairStationCount: number,
	Generators: {{
		ObjectId: string,
		UserId: number,
		LastProduction: number,
		MoneyPerSecond: number,
		SecondsSinceProduction: number,
		TotalProduced: number, -- FASE 3: Dinero total producido
		SpawnTime: number, -- FASE 3: Timestamp de spawn
		Uptime: number, -- FASE 3: Segundos activo
		Tier: number, -- FASE 3: Tier del generador
	}},
	Turrets: {{
		ObjectId: string,
		UserId: number,
		Range: number,
		Damage: number,
		FireRate: number,
	}},
	RepairStations: {{
		ObjectId: string,
		UserId: number,
	}},
}

function UpgradeService:GetDebugInfo(): DebugInfo
	local currentTime = os.time()

	-- Copiar datos de generators
	local generatorList = {}
	for objectId, data in pairs(activeGenerators) do
		table.insert(generatorList, {
			ObjectId = objectId,
			UserId = data.UserId,
			LastProduction = data.LastProduction,
			MoneyPerSecond = data.Definition.Stats.MoneyPerSecond or 0,
			SecondsSinceProduction = currentTime - data.LastProduction,
			TotalProduced = data.TotalProduced or 0, -- FASE 3
			SpawnTime = data.SpawnTime or currentTime, -- FASE 3
			Uptime = currentTime - (data.SpawnTime or currentTime), -- FASE 3
			Tier = data.Tier or 1, -- FASE 3
		})
	end

	-- Copiar datos de turrets
	local turretList = {}
	for objectId, data in pairs(activeTurrets) do
		table.insert(turretList, {
			ObjectId = objectId,
			UserId = data.UserId,
			Range = data.Definition.Stats.Range or 0,
			Damage = data.Definition.Stats.Damage or 0,
			FireRate = data.Definition.Stats.FireRate or 0,
		})
	end

	-- Copiar datos de repair stations
	local repairStationList = {}
	for objectId, data in pairs(repairStations) do
		table.insert(repairStationList, {
			ObjectId = objectId,
			UserId = data.UserId,
		})
	end

	return {
		GeneratorCount = #generatorList,
		TurretCount = #turretList,
		RepairStationCount = #repairStationList,
		Generators = generatorList,
		Turrets = turretList,
		RepairStations = repairStationList,
	}
end

--[[
	Obtiene conteo r�pido de upgrades activos (lightweight).

	@return counts - Tabla con conteos {Generators, Turrets, RepairStations}
]]
function UpgradeService:GetActiveUpgradeCounts(): {Generators: number, Turrets: number, RepairStations: number}
	local generatorCount = 0
	local turretCount = 0
	local repairStationCount = 0

	for _ in pairs(activeGenerators) do
		generatorCount += 1
	end

	for _ in pairs(activeTurrets) do
		turretCount += 1
	end

	for _ in pairs(repairStations) do
		repairStationCount += 1
	end

	return {
		Generators = generatorCount,
		Turrets = turretCount,
		RepairStations = repairStationCount,
	}
end

--[[────────────────────────────────────────────────────────────────────────
	CLIENT-FACING METHODS (Exposed via Knit RemoteFunctions)
────────────────────────────────────────────────────────────────────────]]

--[[
	Client-facing methods que pueden ser llamados desde el cliente.
	Knit automáticamente crea RemoteFunctions para estos métodos.
]]
UpgradeService.Client = {}

--[[
	Solicita upgrade de un generador desde el cliente.

	@param player - Jugador que solicita el upgrade (inyectado automáticamente por Knit)
	@param objectId - ID del generator a upgradear
	@return boolean - true si el upgrade fue exitoso
]]
function UpgradeService.Client:UpgradeGenerator(player: Player, objectId: string): boolean
	-- Knit pasa automáticamente el player como primer argumento
	-- Llamar al método del servidor (usar UpgradeService directamente, no self.Server)
	return UpgradeService:UpgradeGenerator(objectId, player.UserId)
end

--[[
	Obtiene información sobre el próximo upgrade de un generador.

	@param player - Jugador que solicita la info (inyectado automáticamente por Knit)
	@param objectId - ID del generator
	@return table - Información del upgrade: {
		CanUpgrade: boolean,
		UpgradeCost: number,
		CurrentIncome: number,
		NextIncome: number,
		CurrentTier: number,
		NextTier: number,
		NextTierName: string,
		CurrentTierName: string
	} o nil si el generator no existe
]]
function UpgradeService.Client:GetUpgradeInfo(player: Player, objectId: string)
	print("[DEBUG SERVER] GetUpgradeInfo called for player:", player.Name, "objectId:", objectId)
	local data = activeGenerators[objectId]
	if not data then
		print("[DEBUG SERVER] No data found for objectId:", objectId)
		return nil
	end

	-- Verificar ownership
	if data.UserId ~= player.UserId then
		print("[DEBUG SERVER] Ownership mismatch. data.UserId:", data.UserId, "player.UserId:", player.UserId)
		return nil
	end

	-- IMPORTANTE: Usar getTierName() basándose en data.Tier, NO en data.Type
	-- data.Type no existe/no se actualiza en activeGenerators
	local currentTier = data.Tier or 1
	local currentTierName = getTierName(currentTier)
	local currentIncome = data.Definition.Stats.MoneyPerSecond or 0

	print("[DEBUG SERVER] currentTier:", currentTier, "currentTierName:", currentTierName, "currentIncome:", currentIncome)

	-- Verificar si hay siguiente tier
	local nextTierName = UpgradeDefinitions.GetNextTier(currentTierName)
	if not nextTierName then
		-- Ya está en max tier
		return {
			CanUpgrade = false,
			UpgradeCost = 0,
			CurrentIncome = currentIncome,
			NextIncome = currentIncome,
			CurrentTier = currentTier,
			NextTier = currentTier,
			NextTierName = currentTierName,
			CurrentTierName = currentTierName,
		}
	end

	local nextDefinition = UpgradeDefinitions.GetDefinition(nextTierName)
	if not nextDefinition then
		return {
			CanUpgrade = false,
			UpgradeCost = 0,
			CurrentIncome = currentIncome,
			NextIncome = currentIncome,
			CurrentTier = currentTier,
			NextTier = currentTier,
			NextTierName = currentTierName,
			CurrentTierName = currentTierName,
		}
	end

	-- Calcular costo de upgrade (diferencia entre el costo total del siguiente tier y el actual)
	local currentCost = data.Definition.Cost or 0
	local nextCost = nextDefinition.Cost or 0
	local upgradeCost = nextCost - currentCost

	local nextIncome = nextDefinition.Stats.MoneyPerSecond or 0
	local nextTier = currentTier + 1

	local result = {
		CanUpgrade = true,
		UpgradeCost = upgradeCost,
		CurrentIncome = currentIncome,
		NextIncome = nextIncome,
		CurrentTier = currentTier,
		NextTier = nextTier,
		NextTierName = nextTierName,
		CurrentTierName = currentTierName,
	}

	print("[DEBUG SERVER] Returning upgrade info:", result)
	print("[DEBUG SERVER] UpgradeCost:", upgradeCost, "CurrentIncome:", currentIncome, "NextIncome:", nextIncome)

	return result
end

--[[────────────────────────────────────────────────────────────────────────
	LIFECYCLE HOOKS
------------------------------------------------------------------------]]

function UpgradeService:KnitInit()
	-- Crear RemoteEvents si no existen
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not Remotes then
		Remotes = Instance.new("Folder")
		Remotes.Name = "Remotes"
		Remotes.Parent = ReplicatedStorage
	end

	-- RemoteEvent para vender generadores
	if not Remotes:FindFirstChild("SellGenerator") then
		local sellRemote = Instance.new("RemoteEvent")
		sellRemote.Name = "SellGenerator"
		sellRemote.Parent = Remotes
		print("[UpgradeService] ✅ RemoteEvent 'SellGenerator' created")
	end

	-- RemoteEvent para activar Overclock
	if not Remotes:FindFirstChild("ActivateOverclock") then
		local overclockRemote = Instance.new("RemoteEvent")
		overclockRemote.Name = "ActivateOverclock"
		overclockRemote.Parent = Remotes
		print("[UpgradeService] ✅ RemoteEvent 'ActivateOverclock' created")
	end

	print("[UpgradeService] ?? Initialized")
end

function UpgradeService:KnitStart()
	-- Obtener servicios
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	-- PlayerDataService es opcional (puede no existir a�n)
	local success, result = pcall(function()
		return Knit.GetService("PlayerDataService")
	end)
	if success then
		PlayerDataService = result
	else
		warn("[UpgradeService] PlayerDataService no encontrado - generators no dar�n dinero")
	end

	-- TurretService para el nuevo sistema de torretas
	local turretSuccess, turretResult = pcall(function()
		return Knit.GetService("TurretService")
	end)
	if turretSuccess then
		TurretService = turretResult
		print("[UpgradeService] ✅ TurretService integrado")
	else
		warn("[UpgradeService] ⚠️ TurretService no encontrado - torretas no funcionarán")
	end

	-- Conectar RemoteEvents
	local Remotes = ReplicatedStorage.Remotes
	if Remotes:FindFirstChild("SellGenerator") then
		Remotes.SellGenerator.OnServerEvent:Connect(function(player, objectId)
			self:HandleSellGenerator(player, objectId)
		end)
		print("[UpgradeService] ✅ RemoteEvent 'SellGenerator' connected")
	end

	if Remotes:FindFirstChild("ActivateOverclock") then
		Remotes.ActivateOverclock.OnServerEvent:Connect(function(player, objectId)
			self:HandleActivateOverclock(player, objectId)
		end)
		print("[UpgradeService] ✅ RemoteEvent 'ActivateOverclock' connected")
	end

	-- Iniciar update loops
	-- Generators: Update cada segundo
	task.spawn(function()
		while true do
			updateGenerators()
			task.wait(1)
		end
	end)

	-- Turrets: Update cada frame (RenderStepped en servidor = Heartbeat)
	RunService.Heartbeat:Connect(function(deltaTime)
		updateTurrets(deltaTime)
	end)

	print("[UpgradeService] ? Started - Update loops running")
	print(string.format("[UpgradeService] Generators: %d | Turrets: %d | Repair Stations: %d",
		0, 0, 0  -- Start empty
		))
end

--[[────────────────────────────────────────────────────────────────────────
	SELL SYSTEM - HandleSellGenerator
────────────────────────────────────────────────────────────────────────]]

--[[
	Maneja venta de generador.

	REFUND: 50% del costo total (suma de T1 + upgrades)

	@param player - Jugador que solicita la venta
	@param objectId - ID del generador
]]
function UpgradeService:HandleSellGenerator(player: Player, objectId: string)
	local generatorData = activeGenerators[objectId]
	if not generatorData then
		warn("[UpgradeService] ❌ Generator not found:", objectId)
		return
	end

	-- Validar ownership
	if generatorData.UserId ~= player.UserId then
		warn("[UpgradeService] ❌ Player", player.UserId, "is not owner of generator", objectId)
		return
	end

	-- Calcular refund (50% del costo original)
	local refundAmount = math.floor(generatorData.Definition.Cost * 0.5)

	-- Dar dinero (refund)
	local EconomyModule = require(ServerScriptService:WaitForChild("EconomyModule"))
	EconomyModule.AdminGiveCash(player.UserId, refundAmount)

	-- 🛡️ Actualizar Guardian después de refund
	local BaseModule = require(ServerScriptService:WaitForChild("BaseModule"))
	local refundState = EconomyModule.GetState(player.UserId)
	if refundState then
		BaseModule.UpdateGuardianTarget(player.UserId, refundState.Cash)
	end

	-- Remover del BaseOwnershipService
	if BaseOwnershipService then
		BaseOwnershipService:RemoveObject(player.UserId, objectId)
	end

	-- Destruir modelo
	if generatorData.Model and generatorData.Model.Parent then
		generatorData.Model:Destroy()
	end

	-- Desregistrar del sistema de generadores
	activeGenerators[objectId] = nil

	print(string.format(
		"[UpgradeService] ✅ Generator sold: %s (Refund: $%d, Owner: %d)",
		objectId,
		refundAmount,
		player.UserId
	))
end

--[[────────────────────────────────────────────────────────────────────────
	OVERCLOCK SYSTEM - Helper Functions
────────────────────────────────────────────────────────────────────────]]

--[[
	Sincroniza el estado de Overclock del generador a los attributes del MainPart
	para que el cliente pueda leerlos.

	@param objectId - ID del generador
]]
local function syncOverclockAttributes(objectId: string)
	local generatorData = activeGenerators[objectId]
	if not generatorData or not generatorData.Model then
		return
	end

	local mainPart = generatorData.Model:FindFirstChild("MainPart")
	if not mainPart then
		return
	end

	-- Sincronizar attributes
	mainPart:SetAttribute("OverclockActive", generatorData.OverclockActive)
	mainPart:SetAttribute("OverclockEndTime", generatorData.OverclockEndTime)
	mainPart:SetAttribute("OverclockCooldownEndTime", generatorData.OverclockCooldownEndTime)
	mainPart:SetAttribute("Stability", generatorData.Stability)
end

--[[────────────────────────────────────────────────────────────────────────
	OVERCLOCK SYSTEM - HandleActivateOverclock
────────────────────────────────────────────────────────────────────────]]

--[[
	Activa Overclock en un generador.

	BOOST: +200% income por 10 segundos
	COST: $50
	COOLDOWN: 30 segundos
	RISK: 10% chance de overheat (apaga el generador por 5s)

	@param player - Jugador que solicita la activación
	@param objectId - ID del generador
]]
function UpgradeService:HandleActivateOverclock(player: Player, objectId: string)
	local generatorData = activeGenerators[objectId]
	if not generatorData then
		warn("[UpgradeService] ❌ Generator not found:", objectId)
		return
	end

	-- Validar ownership
	if generatorData.UserId ~= player.UserId then
		warn("[UpgradeService] ❌ Player", player.UserId, "is not owner of generator", objectId)
		return
	end

	local currentTime = tick()

	-- Verificar si ya está activo
	if generatorData.OverclockActive then
		warn("[UpgradeService] ⚠️ Overclock already active for:", objectId)
		return
	end

	-- Verificar cooldown
	if currentTime < generatorData.OverclockCooldownEndTime then
		local remaining = math.ceil(generatorData.OverclockCooldownEndTime - currentTime)
		warn(string.format("[UpgradeService] ⚠️ Overclock on cooldown: %ds remaining", remaining))
		return
	end

	-- Costo de activación
	local activationCost = 50
	local EconomyModule = require(ServerScriptService:WaitForChild("EconomyModule"))
	local playerState = EconomyModule.GetState(player.UserId)

	if not playerState or playerState.Cash < activationCost then
		warn("[UpgradeService] ❌ Not enough money for Overclock:", player.UserId)
		return
	end

	-- Cobrar dinero
	EconomyModule.AdminRemoveCash(player.UserId, activationCost)

	-- Activar Overclock
	generatorData.OverclockActive = true
	generatorData.OverclockEndTime = currentTime + 10  -- 10 segundos de duración

	-- Reducir estabilidad
	generatorData.Stability = math.max(0, generatorData.Stability - 15)

	-- Sincronizar estado a cliente
	syncOverclockAttributes(objectId)

	-- Calcular riesgo de overheat (10% base + más si la estabilidad es baja)
	local overheatChance = 0.10 + (1 - generatorData.Stability / 100) * 0.20  -- 10% + hasta 20% extra
	local willOverheat = math.random() < overheatChance

	print(string.format(
		"[UpgradeService] ⚡ Overclock activated: %s (Owner: %d, Duration: 10s, Stability: %d%%, Overheat: %s)",
		objectId,
		player.UserId,
		generatorData.Stability,
		willOverheat and "YES" or "NO"
	))

	-- Si overheat, programar apagado
	if willOverheat then
		task.delay(5, function()  -- Overheat a mitad del boost
			if activeGenerators[objectId] then
				generatorData.OverclockActive = false
				generatorData.OverclockEndTime = 0
				generatorData.OverclockCooldownEndTime = tick() + 45  -- Cooldown más largo si overheat

				-- Sincronizar estado a cliente
				syncOverclockAttributes(objectId)

				warn(string.format("[UpgradeService] 🔥 Generator OVERHEATED: %s", objectId))
			end
		end)
	else
		-- Cooldown normal después del boost
		task.delay(10, function()
			if activeGenerators[objectId] then
				generatorData.OverclockActive = false
				generatorData.OverclockCooldownEndTime = currentTime + 30  -- 30s cooldown

				-- Sincronizar estado a cliente
				syncOverclockAttributes(objectId)
			end
		end)
	end
end

return UpgradeService