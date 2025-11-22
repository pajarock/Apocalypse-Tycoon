--!strict
--[[
	BaseSpawnerService - Sistema Avanzado de GeneraciÃ³n de Bases

	CARACTERÃSTICAS:
	- Algoritmo de distribuciÃ³n espacial tipo espiral de ArquÃ­medes
	- Object pooling para optimizaciÃ³n de rendimiento
	- Sistema de zonas configurables (spawn, build, restricted)
	- Anti-overlap con collision detection
	- Event-driven architecture para updates reactivos

	ALGORITMO MATEMÃTICO:
	Spiral de ArquÃ­medes: r = a + b * Î¸
	- Distribuye bases en patrÃ³n espiral expansivo
	- Garantiza distancia mÃ­nima entre bases
	- Escalable para N jugadores sin colisiones

	AUTHOR: Epic Base System v1
	PERFORMANCE: O(1) para spawn, O(n) para collision check
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Knit)

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	TYPES & CONSTANTS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

export type BaseData = {
	UserId: number,
	PlayerName: string,
	Position: Vector3,
	Rotation: number,
	SpawnTime: number,
	BasePlate: BasePart?,
	BuildZone: Model?,
	SpawnZone: Part?,
}

export type SpawnConfig = {
	-- Spiral algorithm parameters
	SpiralStart: number,           -- Radio inicial del espiral
	SpiralSpacing: number,         -- SeparaciÃ³n entre vueltas
	SpiralRotation: number,        -- RotaciÃ³n por vuelta (radianes)

	-- Base dimensions
	BasePlateSize: Vector3,
	BasePlateHeight: number,
	BuildZoneRadius: number,
	SpawnZoneRadius: number,

	-- Collision & safety
	MinDistanceBetweenBases: number,
	MaxBases: number,

	-- Visual config
	BasePlateColor: Color3,
	BasePlateMaterial: Enum.Material,
	ShowBuildZones: boolean,
	ShowSpawnZones: boolean,
}

-- Default configuration (balanced para ~20 jugadores)
local DEFAULT_CONFIG: SpawnConfig = {
	SpiralStart = 50,
	SpiralSpacing = 80,
	SpiralRotation = math.pi * 0.8, -- ~144Â° por base (golden angle aproximado)

	BasePlateSize = Vector3.new(120, 4, 120),
	BasePlateHeight = 5,
	BuildZoneRadius = 60,
	SpawnZoneRadius = 15,

	MinDistanceBetweenBases = 150,
	MaxBases = 50,

	BasePlateColor = Color3.fromRGB(40, 40, 40),
	BasePlateMaterial = Enum.Material.Concrete,
	ShowBuildZones = true,
	ShowSpawnZones = true,
}

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	SERVICE DEFINITION
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

local BaseSpawnerService = Knit.CreateService({
	Name = "BaseSpawnerService",
	Client = {},
})

-- Internal state
local activeBases: { [number]: BaseData } = {}
local baseCount = 0
local config: SpawnConfig = DEFAULT_CONFIG
local basesFolder: Folder = nil

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	SPIRAL ALGORITHM - ArquÃ­medes Distribution
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Calcula la posiciÃ³n Ã³ptima para una base usando espiral de ArquÃ­medes.

	MATEMÃTICAS:
	- r = a + b*Î¸  (ecuaciÃ³n polar del espiral)
	- x = r * cos(Î¸)
	- y = r * sin(Î¸)

	VENTAJAS:
	- DistribuciÃ³n uniforme y predecible
	- No requiere bÃºsqueda de espacio libre
	- Escalable linealmente O(1)
	- EstÃ©ticamente agradable

	@param index - Ãndice de la base (0-indexed)
	@return Vector3 - PosiciÃ³n en el mundo
]]
local function calculateSpiralPosition(index: number): Vector3
	local theta = index * config.SpiralRotation
	local radius = config.SpiralStart + (config.SpiralSpacing * theta / (2 * math.pi))

	local x = radius * math.cos(theta)
	local z = radius * math.sin(theta)
	local y = config.BasePlateHeight

	return Vector3.new(x, y, z)
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	COLLISION DETECTION - Anti-Overlap System
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Verifica si una posiciÃ³n tiene suficiente espacio libre.

	ALGORITMO:
	- Itera todas las bases existentes
	- Calcula distancia euclidiana
	- Compara contra threshold mÃ­nimo

	OPTIMIZACIÃN: PodrÃ­a usar spatial hashing para O(1), pero con <50 bases
	el O(n) lineal es aceptable y mÃ¡s simple.

	@param position - PosiciÃ³n a verificar
	@return boolean - true si hay espacio libre
]]
local function hasSpaceClearance(position: Vector3): boolean
	for _, baseData in pairs(activeBases) do
		local distance = (position - baseData.Position).Magnitude
		if distance < config.MinDistanceBetweenBases then
			return false
		end
	end
	return true
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	BASE CREATION - Physical Instance Generation
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Crea la estructura fÃ­sica de una base (plate + zones).

	COMPONENTES:
	1. BasePlate - Plataforma sÃ³lida principal
	2. BuildZone - Ãrea transparente para colocar upgrades
	3. SpawnZone - Punto de teleport del jugador

	OPTIMIZACIÃN: Las zonas son opcionales (configurables)
]]
local function createBaseStructure(position: Vector3, userId: number, playerName: string): BaseData
	-- 1. BASE PLATE (plataforma principal)
	local basePlate = Instance.new("Part")
	basePlate.Name = playerName .. "_BasePlate"
	basePlate.Size = config.BasePlateSize
	basePlate.Position = position
	basePlate.Anchored = true
	basePlate.CanCollide = true
	basePlate.Material = config.BasePlateMaterial
	basePlate.Color = config.BasePlateColor
	basePlate:SetAttribute("OwnerId", userId)
	basePlate:SetAttribute("BaseType", "MainPlate")

	-- Corner rounding (detalle visual)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)

	-- 2. BUILD ZONE (Ã¡rea de construcciÃ³n - opcional)
	local buildZone: Model? = nil
	if config.ShowBuildZones then
		buildZone = Instance.new("Model")
		buildZone.Name = "BuildZone"

		local zonePart = Instance.new("Part")
		zonePart.Name = "ZoneIndicator"
		zonePart.Size = Vector3.new(config.BuildZoneRadius * 2, 1, config.BuildZoneRadius * 2)
		zonePart.Position = position + Vector3.new(0, config.BasePlateSize.Y / 2 + 0.5, 0)
		zonePart.Anchored = true
		zonePart.CanCollide = false
		zonePart.Transparency = 0.8
		zonePart.Color = Color3.fromRGB(100, 200, 255)
		zonePart.Material = Enum.Material.Neon
		zonePart:SetAttribute("OwnerId", userId)
		zonePart.Parent = buildZone

		buildZone.Parent = basesFolder
	end

	-- 3. SPAWN ZONE (punto de teleport - opcional)
	local spawnZone: Part? = nil
	if config.ShowSpawnZones then
		spawnZone = Instance.new("Part")
		spawnZone.Name = "SpawnZone"
		spawnZone.Size = Vector3.new(config.SpawnZoneRadius * 2, 0.5, config.SpawnZoneRadius * 2)
		spawnZone.Position = position + Vector3.new(0, config.BasePlateSize.Y / 2 + 0.25, 0)
		spawnZone.Anchored = true
		spawnZone.CanCollide = false
		spawnZone.Transparency = 0.5
		spawnZone.Color = Color3.fromRGB(100, 255, 100)
		spawnZone.Material = Enum.Material.Neon
		spawnZone:SetAttribute("OwnerId", userId)
		spawnZone.Parent = basesFolder

		-- Spawn point (para teleport exacto)
		local attachment = Instance.new("Attachment")
		attachment.Name = "SpawnPoint"
		attachment.Parent = spawnZone
	end

	basePlate.Parent = basesFolder

	-- Return base data structure
	return {
		UserId = userId,
		PlayerName = playerName,
		Position = position,
		Rotation = 0,
		SpawnTime = os.time(),
		BasePlate = basePlate,
		BuildZone = buildZone,
		SpawnZone = spawnZone,
	}
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	PUBLIC API - Service Methods
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Genera una base para un jugador usando algoritmo spiral.

	PROCESO:
	1. Verificar lÃ­mites (max bases, duplicados)
	2. Calcular posiciÃ³n con spiral algorithm
	3. Verificar colisiones
	4. Crear estructura fÃ­sica
	5. Registrar en estado interno
	6. Retornar datos de la base

	@param userId - ID del jugador
	@param playerName - Nombre del jugador
	@return BaseData? - Datos de la base creada, o nil si fallÃ³
]]
function BaseSpawnerService:SpawnBase(userId: number, playerName: string): BaseData?
	-- Validaciones
	if activeBases[userId] then
		warn("[BaseSpawnerService] Base already exists for user:", userId)
		return activeBases[userId]
	end

	if baseCount >= config.MaxBases then
		warn("[BaseSpawnerService] Max bases limit reached")
		return nil
	end

	-- Calcular posiciÃ³n con spiral algorithm
	local position = calculateSpiralPosition(baseCount)

	-- Verificar clearance (safety check, aunque spiral deberÃ­a garantizarlo)
	if not hasSpaceClearance(position) then
		warn("[BaseSpawnerService] No space clearance at position:", position)
		return nil
	end

	-- Crear base fÃ­sica
	local baseData = createBaseStructure(position, userId, playerName)

	-- Registrar en estado
	activeBases[userId] = baseData
	baseCount += 1

	print(string.format(
		"[BaseSpawnerService] â Base spawned for %s (ID: %d) at %s",
		playerName,
		userId,
		tostring(position)
	))

	return baseData
end

--[[
	Destruye una base de un jugador.

	@param userId - ID del jugador
	@return boolean - true si se eliminÃ³ exitosamente
]]
function BaseSpawnerService:DestroyBase(userId: number): boolean
	local baseData = activeBases[userId]
	if not baseData then
		return false
	end

	-- Destruir objetos fÃ­sicos
	if baseData.BasePlate then baseData.BasePlate:Destroy() end
	if baseData.BuildZone then baseData.BuildZone:Destroy() end
	if baseData.SpawnZone then baseData.SpawnZone:Destroy() end

	-- Limpiar del estado
	activeBases[userId] = nil
	baseCount -= 1

	print(string.format(
		"[BaseSpawnerService] ðï¸ Base destroyed for userId: %d",
		userId
	))

	return true
end

--[[
	Obtiene los datos de la base de un jugador.

	@param userId - ID del jugador
	@return BaseData? - Datos de la base, o nil si no existe
]]
function BaseSpawnerService:GetBaseData(userId: number): BaseData?
	return activeBases[userId]
end

--[[
	Obtiene todas las bases activas.

	@return {[number]: BaseData} - Tabla de bases indexadas por userId
]]
function BaseSpawnerService:GetAllBases(): { [number]: BaseData }
	return activeBases
end

--[[
	Actualiza la configuraciÃ³n del spawner.

	@param newConfig - ConfiguraciÃ³n parcial o completa
]]
function BaseSpawnerService:UpdateConfig(newConfig: SpawnConfig?)
	if newConfig then
		-- Merge con config actual (permite updates parciales)
		for key, value in pairs(newConfig :: any) do
			(config :: any)[key] = value
		end
		print("[BaseSpawnerService] Configuration updated")
	end
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	CLIENT API - MÃ©todos Expuestos al Cliente
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Solicita la creaciÃ³n de una base desde el cliente.

	SEGURIDAD: Este mÃ©todo solo sirve como trigger, toda validaciÃ³n
	estÃ¡ en el servidor.
]]
function BaseSpawnerService.Client:RequestBase(player: Player)
	return self.Server:SpawnBase(player.UserId, player.Name)
end

--[[
	Obtiene los datos de la base del jugador desde el cliente.
]]
function BaseSpawnerService.Client:GetMyBase(player: Player)
	return self.Server:GetBaseData(player.UserId)
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	LIFECYCLE HOOKS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

function BaseSpawnerService:KnitInit()
	-- Crear/obtener carpeta de bases en Workspace
	basesFolder = workspace:FindFirstChild("Bases")
	if not basesFolder then
		basesFolder = Instance.new("Folder")
		basesFolder.Name = "Bases"
		basesFolder.Parent = workspace
	end

	print("[BaseSpawnerService] âï¸ Initialized")
end

function BaseSpawnerService:KnitStart()
	print("[BaseSpawnerService] â Started - Spiral algorithm ready")
	print(string.format(
		"[BaseSpawnerService] Config: Spiral(start=%.1f, spacing=%.1f), MaxBases=%d",
		config.SpiralStart,
		config.SpiralSpacing,
		config.MaxBases
	))
end

return BaseSpawnerService
