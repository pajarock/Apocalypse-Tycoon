--!strict
--[[
	UpgradeService - Maneja la funcionalidad de upgrades

	RESPONSABILIDADES:
	- Gestionar upgrades activos (generators, turrets, storage)
	- Update loop para generators (producciÃ³n de dinero)
	- Update loop para turrets (targeting y disparo)
	- CÃ¡lculo de capacidad total de storage
	- Repair station interaction

	ARQUITECTURA:
	- Knit Service (servidor-side)
	- Integra con BaseOwnershipService para tracking de objetos
	- Integra con PlayerDataService para dar dinero
	- Update loops separados para cada categorÃ­a de upgrade

	OPTIMIZACIÃN:
	- Generators: Update cada segundo (batch processing)
	- Turrets: Update cada frame solo para turrets activos
	- Storage: CÃ¡lculo on-demand (no loop)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Knit)
local UpgradeDefinitions = require(script.Parent.UpgradeDefinitions)
local GeneratorVFXManager = require(ServerStorage.Managers.GeneratorVFXManager)

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	SERVICE DEFINITION
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	GENERATOR SYSTEM - Passive Money Production
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Registra un generator para producciÃ³n automÃ¡tica.

	@param objectId - ID del objeto
	@param userId - DueÃ±o del generator
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

	-- FASE 3: Detectar tier automÃ¡ticamente basado en el tipo
	local tier = 1
	if generatorType == "GeneratorT2" then
		tier = 2
	elseif generatorType == "GeneratorT3" then
		tier = 3
	end

	activeGenerators[objectId] = {
		UserId = userId,
		LastProduction = os.time(),
		Definition = definition,
		Model = model,
		Tier = tier, -- Guardar tier para uso posterior
		TotalProduced = 0, -- FASE 2: Tracking de dinero total producido
		SpawnTime = os.time(), -- FASE 2: Tiempo de spawn para calcular uptime
	}

	-- FASE 3: Almacenar stats en el modelo para acceso dinÃ¡mico desde ProximityPrompt
	local mainPart = model:FindFirstChild("MainPart")
	if mainPart then
		-- Crear valores para tracking dinÃ¡mico
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

	-- FASE 2: AnimaciÃ³n de construcciÃ³n (incluye efectos visuales)
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

	print(string.format(
		"[UpgradeService] ð° Generator registered: %s (Owner: %d, Rate: $%d/s, Tier: %d)",
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

				-- Eliminar billboard de estadÃ­sticas (si estÃ¡ visible)
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
	PHASE 4: Upgradea un generator al siguiente tier (T1âT2âT3).

	PROCESO:
	1. Validar que el jugador es el dueÃ±o
	2. Validar que puede upgradear (no estÃ¡ en tier mÃ¡ximo)
	3. Calcular costo y validar dinero suficiente
	4. Deducir dinero del jugador
	5. Actualizar el modelo en workspace (tamaÃ±o, color, efectos)
	6. Actualizar stats en activeGenerators
	7. Mostrar efectos visuales de upgrade

	@param objectId - ID del generator
	@param userId - ID del jugador que intenta upgradear
	@return boolean - true si el upgrade fue exitoso, false si fallÃ³
]]
function UpgradeService:UpgradeGenerator(objectId: string, userId: number): boolean
	local data = activeGenerators[objectId]
	if not data then
		warn(string.format("[UpgradeService] UpgradeGenerator: Generator not found: %s", objectId))
		return false
	end

	-- Validar ownership
	if data.UserId ~= userId then
		warn(string.format("[UpgradeService] UpgradeGenerator: User %d is not owner of generator %s", userId, objectId))
		return false
	end

	-- Obtener tier actual
	local currentTierName = data.Definition.Name

	-- Validar que puede upgradear
	if not UpgradeDefinitions.CanUpgrade(currentTierName) then
		warn(string.format("[UpgradeService] UpgradeGenerator: Generator %s is already at max tier", objectId))
		return false
	end

	-- Obtener siguiente tier y costo
	local nextTierName = UpgradeDefinitions.GetNextTier(currentTierName)
	local upgradeCost = UpgradeDefinitions.GetUpgradeCost(currentTierName)

	if not nextTierName or not upgradeCost then
		warn(string.format("[UpgradeService] UpgradeGenerator: Failed to get next tier or cost for %s", currentTierName))
		return false
	end

	-- Validar dinero suficiente y deducir
	if not PlayerDataService then
		warn("[UpgradeService] â PlayerDataService not available")
		return false
	end

	print(string.format("[UpgradeService] ð° Checking money for user %d (need $%d)", userId, upgradeCost))

	-- Intentar deducir dinero (DeductMoney verifica automÃ¡ticamente si tiene suficiente)
	local success = PlayerDataService:DeductMoney(userId, upgradeCost)
	if not success then
		warn(string.format("[UpgradeService] â User %d doesn't have enough money ($%d needed)", userId, upgradeCost))
		return false
	end

	print(string.format("[UpgradeService] â Money deducted: $%d from user %d", upgradeCost, userId))

	-- Obtener nueva definiciÃ³n
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
	end

	local oldTier = data.Tier or 1

	-- Actualizar datos internos PRIMERO
	data.Definition = nextDefinition
	data.Tier = newTier

	-- Actualizar modelo en workspace
	if data.Model then
		local mainPart = data.Model:FindFirstChild("MainPart")
		if mainPart then
			-- Actualizar propiedades fÃ­sicas
			mainPart.Size = nextDefinition.Size
			mainPart.Color = nextDefinition.Color
			mainPart.Material = nextDefinition.Material

			-- Actualizar highlight
			local highlight = mainPart:FindFirstChild("Highlight")
			if highlight then
				highlight.FillColor = nextDefinition.Color
			end

			-- Actualizar valores en MainPart para stats dinÃ¡micos
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

			-- Actualizar billboard name tag
			local billboard = mainPart:FindFirstChild("NameTag")
			if billboard then
				local label = billboard:FindFirstChild("TextLabel")
				if label then
					label.Text = nextDefinition.DisplayName
				end
			end

			-- FASE 4: Mostrar efectos visuales de upgrade
			GeneratorVFXManager:ShowUpgradeEffect(data.Model, oldTier, newTier)

			-- Recrear partÃ­culas y sonido ambiental para el nuevo tier
			GeneratorVFXManager:RemoveEffects(data.Model)  -- Ahora preserva StatsBillboard â
			GeneratorVFXManager:ApplyGlowPulse(data.Model, newTier)
			GeneratorVFXManager:CreateParticles(data.Model, newTier)
			GeneratorVFXManager:CreateAmbientSound(data.Model)

			-- CRÃTICO: Refrescar prompts despuÃ©s del upgrade para asegurar que todo funciona
			GeneratorVFXManager:RefreshPromptsAfterUpgrade(data.Model, newTier)
		end
	end

	print(string.format(
		"[UpgradeService] â¨ Generator upgraded: %s (T%d â T%d, Cost: $%d, New Rate: $%d/s)",
		objectId,
		oldTier,
		newTier,
		upgradeCost,
		nextDefinition.Stats.MoneyPerSecond or 0
	))

	return true
end

--[[
	Update loop para generators - ejecuta cada segundo.

	PROCESO:
	1. Iterar sobre todos los generators activos
	2. Calcular dinero producido desde Ãºltima actualizaciÃ³n
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

			-- Dar dinero al jugador (si PlayerDataService existe)
			if PlayerDataService then
				local success = pcall(function()
					PlayerDataService:AddMoney(data.UserId, moneyToGive)
				end)

				if success then
					-- FASE 2: Actualizar estadÃ­sticas de producciÃ³n
					data.TotalProduced = data.TotalProduced + moneyToGive

					-- FASE 3: Actualizar valor en el modelo para stats dinÃ¡micos
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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	TURRET SYSTEM - Auto-targeting Defense
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Registra una turret para targeting automÃ¡tico.

	@param objectId - ID del objeto
	@param userId - DueÃ±o de la turret
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
		"[UpgradeService] ð« Turret registered: %s (Owner: %d, Range: %.1f)",
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
	Encuentra el meteoro/enemigo mÃ¡s cercano a la turret.

	@param turretPosition - PosiciÃ³n de la turret
	@param range - Rango de detecciÃ³n
	@return Model? - Meteoro/enemigo mÃ¡s cercano, o nil
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
	@param damage - DaÃ±o del proyectil
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

	-- Detectar colisiÃ³n (destruir proyectil y daÃ±ar objetivo)
	projectile.Touched:Connect(function(hit)
		if hit:IsDescendantOf(target) then
			-- TODO: Aplicar daÃ±o al objetivo
			print(string.format("[UpgradeService] ð¥ Hit target: %s (Damage: %d)", target.Name, damage))

			-- Destruir objetivo (temporal - deberÃ­a tener HP system)
			target:Destroy()

			-- Destruir proyectil
			projectile:Destroy()
		end
	end)

	-- Destruir proyectil despuÃ©s de 5 segundos (si no impacta)
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
	2. Buscar objetivo mÃ¡s cercano en rango
	3. Si hay objetivo y fireRate permite, disparar
	4. Actualizar orientaciÃ³n de la turret hacia el objetivo
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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	STORAGE SYSTEM - Money Capacity
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	REPAIR STATION SYSTEM - Mobile-Friendly Base Repair
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Registra una repair station y conecta su ProximityPrompt.

	@param objectId - ID del objeto
	@param userId - DueÃ±o de la repair station
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
				-- Verificar que el jugador sea el dueÃ±o
				if player.UserId ~= userId then
					print(string.format("[UpgradeService] â %s tried to use another player's repair station", player.Name))
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
							"[UpgradeService] ð§ %s repaired base: -%d money, +%d HP",
							player.Name,
							repairCost,
							repairAmount
						))

						-- TODO: Actualizar HP de la base
					else
						print(string.format("[UpgradeService] â %s doesn't have enough money to repair", player.Name))
					end
				end
			end)
		end
	end

	print(string.format(
		"[UpgradeService] ð§ Repair Station registered: %s (Owner: %d)",
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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	PUBLIC API - Registration
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Registra un upgrade en el sistema correspondiente.

	@param objectId - ID del objeto
	@param userId - DueÃ±o del objeto
	@param objectType - Tipo de upgrade
	@param model - Modelo 3D
]]
function UpgradeService:RegisterUpgrade(objectId: string, userId: number, objectType: string, model: Model)
	-- FASE 3: Detectar todos los tipos de generadores
	if objectType == "Generator" or objectType == "GeneratorT2" or objectType == "GeneratorT3" then
		self:RegisterGenerator(objectId, userId, model, objectType)
	elseif objectType == "Turret" then
		self:RegisterTurret(objectId, userId, model)
	elseif objectType == "RepairStation" then
		self:RegisterRepairStation(objectId, userId, model)
	end
end

--[[
	Desregistra un upgrade del sistema.

	@param objectId - ID del objeto
	@param objectType - Tipo de upgrade
]]
function UpgradeService:UnregisterUpgrade(objectId: string, objectType: string)
	-- FASE 3: Detectar todos los tipos de generadores
	if objectType == "Generator" or objectType == "GeneratorT2" or objectType == "GeneratorT3" then
		self:UnregisterGenerator(objectId)
	elseif objectType == "Turret" then
		self:UnregisterTurret(objectId)
	elseif objectType == "RepairStation" then
		self:UnregisterRepairStation(objectId)
	end
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	DEBUG / MONITORING API
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Obtiene informaciÃ³n de debugging sobre todos los upgrades activos.

	IMPORTANTE: Este mÃ©todo es para debugging/monitoring.
	Retorna copias de datos, no referencias directas.

	@return DebugInfo - Tabla con informaciÃ³n de todos los upgrades
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
	Obtiene conteo rÃ¡pido de upgrades activos (lightweight).

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

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	LIFECYCLE HOOKS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

function UpgradeService:KnitInit()
	print("[UpgradeService] âï¸ Initialized")
end

function UpgradeService:KnitStart()
	-- Obtener servicios
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	-- PlayerDataService es opcional (puede no existir aÃºn)
	local success, result = pcall(function()
		return Knit.GetService("PlayerDataService")
	end)
	if success then
		PlayerDataService = result
	else
		warn("[UpgradeService] PlayerDataService no encontrado - generators no darÃ¡n dinero")
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

	print("[UpgradeService] â Started - Update loops running")
	print(string.format("[UpgradeService] Generators: %d | Turrets: %d | Repair Stations: %d",
		0, 0, 0  -- Start empty
	))
end

return UpgradeService
