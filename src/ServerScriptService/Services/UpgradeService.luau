--!strict
--[[
	UpgradeService - Maneja la funcionalidad de upgrades

	RESPONSABILIDADES:
	- Gestionar upgrades activos (generators, turrets, storage)
	- Update loop para generators (producción de dinero)
	- Update loop para turrets (targeting y disparo)
	- Cálculo de capacidad total de storage
	- Repair station interaction

	ARQUITECTURA:
	- Knit Service (servidor-side)
	- Integra con BaseOwnershipService para tracking de objetos
	- Integra con PlayerDataService para dar dinero
	- Update loops separados para cada categoría de upgrade

	OPTIMIZACIÓN:
	- Generators: Update cada segundo (batch processing)
	- Turrets: Update cada frame solo para turrets activos
	- Storage: Cálculo on-demand (no loop)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Knit)
local UpgradeDefinitions = require(script.Parent.UpgradeDefinitions)
local GeneratorVFXManager = require(ServerStorage.Managers.GeneratorVFXManager)

--[[────────────────────────────────────────────────────────────────────────
	SERVICE DEFINITION
────────────────────────────────────────────────────────────────────────]]

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

--[[────────────────────────────────────────────────────────────────────────
	GENERATOR SYSTEM - Passive Money Production
────────────────────────────────────────────────────────────────────────]]

--[[
	Registra un generator para producción automática.

	@param objectId - ID del objeto
	@param userId - Dueño del generator
	@param model - Modelo 3D del generator
]]
function UpgradeService:RegisterGenerator(objectId: string, userId: number, model: Model)
	local definition = UpgradeDefinitions.GetDefinition("Generator")
	if not definition then
		return
	end

	-- Determinar tier del generador (por ahora defaultea a Tier 1)
	-- TODO: Expandir para soportar GeneratorT1, GeneratorT2, GeneratorT3
	local tier = 1

	activeGenerators[objectId] = {
		UserId = userId,
		LastProduction = os.time(),
		Definition = definition,
		Model = model,
		Tier = tier, -- Guardar tier para uso posterior
	}

	-- Aplicar efectos visuales
	GeneratorVFXManager:ApplyGlowPulse(model, tier)
	GeneratorVFXManager:CreateParticles(model, tier)

	print(string.format(
		"[UpgradeService] 💰 Generator registered: %s (Owner: %d, Rate: $%d/s, Tier: %d)",
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
		end

		activeGenerators[objectId] = nil
		print(string.format("[UpgradeService] Generator unregistered: %s", objectId))
	end
end

--[[
	Update loop para generators - ejecuta cada segundo.

	PROCESO:
	1. Iterar sobre todos los generators activos
	2. Calcular dinero producido desde última actualización
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
					-- Mostrar efecto visual de producción
					if data.Model and data.Model:FindFirstChild("MainPart") then
						local tier = data.Tier or 1
						GeneratorVFXManager:ShowMoneyProduction(data.Model, moneyToGive, tier)
					end
				end
			end

			-- Actualizar timestamp
			data.LastProduction = currentTime
		end
	end
end

--[[────────────────────────────────────────────────────────────────────────
	TURRET SYSTEM - Auto-targeting Defense
────────────────────────────────────────────────────────────────────────]]

--[[
	Registra una turret para targeting automático.

	@param objectId - ID del objeto
	@param userId - Dueño de la turret
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
		"[UpgradeService] 🔫 Turret registered: %s (Owner: %d, Range: %.1f)",
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
	Encuentra el meteoro/enemigo más cercano a la turret.

	@param turretPosition - Posición de la turret
	@param range - Rango de detección
	@return Model? - Meteoro/enemigo más cercano, o nil
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
	@param damage - Daño del proyectil
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

	-- Detectar colisión (destruir proyectil y dañar objetivo)
	projectile.Touched:Connect(function(hit)
		if hit:IsDescendantOf(target) then
			-- TODO: Aplicar daño al objetivo
			print(string.format("[UpgradeService] 💥 Hit target: %s (Damage: %d)", target.Name, damage))

			-- Destruir objetivo (temporal - debería tener HP system)
			target:Destroy()

			-- Destruir proyectil
			projectile:Destroy()
		end
	end)

	-- Destruir proyectil después de 5 segundos (si no impacta)
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
	2. Buscar objetivo más cercano en rango
	3. Si hay objetivo y fireRate permite, disparar
	4. Actualizar orientación de la turret hacia el objetivo
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

--[[────────────────────────────────────────────────────────────────────────
	STORAGE SYSTEM - Money Capacity
────────────────────────────────────────────────────────────────────────]]

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

--[[────────────────────────────────────────────────────────────────────────
	REPAIR STATION SYSTEM - Mobile-Friendly Base Repair
────────────────────────────────────────────────────────────────────────]]

--[[
	Registra una repair station y conecta su ProximityPrompt.

	@param objectId - ID del objeto
	@param userId - Dueño de la repair station
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
				-- Verificar que el jugador sea el dueño
				if player.UserId ~= userId then
					print(string.format("[UpgradeService] ❌ %s tried to use another player's repair station", player.Name))
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
							"[UpgradeService] 🔧 %s repaired base: -%d money, +%d HP",
							player.Name,
							repairCost,
							repairAmount
						))

						-- TODO: Actualizar HP de la base
					else
						print(string.format("[UpgradeService] ❌ %s doesn't have enough money to repair", player.Name))
					end
				end
			end)
		end
	end

	print(string.format(
		"[UpgradeService] 🔧 Repair Station registered: %s (Owner: %d)",
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

--[[────────────────────────────────────────────────────────────────────────
	PUBLIC API - Registration
────────────────────────────────────────────────────────────────────────]]

--[[
	Registra un upgrade en el sistema correspondiente.

	@param objectId - ID del objeto
	@param userId - Dueño del objeto
	@param objectType - Tipo de upgrade
	@param model - Modelo 3D
]]
function UpgradeService:RegisterUpgrade(objectId: string, userId: number, objectType: string, model: Model)
	if objectType == "Generator" then
		self:RegisterGenerator(objectId, userId, model)
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
	if objectType == "Generator" then
		self:UnregisterGenerator(objectId)
	elseif objectType == "Turret" then
		self:UnregisterTurret(objectId)
	elseif objectType == "RepairStation" then
		self:UnregisterRepairStation(objectId)
	end
end

--[[────────────────────────────────────────────────────────────────────────
	DEBUG / MONITORING API
────────────────────────────────────────────────────────────────────────]]

--[[
	Obtiene información de debugging sobre todos los upgrades activos.

	IMPORTANTE: Este método es para debugging/monitoring.
	Retorna copias de datos, no referencias directas.

	@return DebugInfo - Tabla con información de todos los upgrades
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
	Obtiene conteo rápido de upgrades activos (lightweight).

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
	LIFECYCLE HOOKS
────────────────────────────────────────────────────────────────────────]]

function UpgradeService:KnitInit()
	print("[UpgradeService] ⚙️ Initialized")
end

function UpgradeService:KnitStart()
	-- Obtener servicios
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	-- PlayerDataService es opcional (puede no existir aún)
	local success, result = pcall(function()
		return Knit.GetService("PlayerDataService")
	end)
	if success then
		PlayerDataService = result
	else
		warn("[UpgradeService] PlayerDataService no encontrado - generators no darán dinero")
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

	print("[UpgradeService] ✅ Started - Update loops running")
	print(string.format("[UpgradeService] Generators: %d | Turrets: %d | Repair Stations: %d",
		0, 0, 0  -- Start empty
	))
end

return UpgradeService
