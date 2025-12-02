--!strict
--[[
	BaseOwnershipService - Sistema Robusto de Permisos y Zonas

	CARACTER�STICAS:
	- Sistema de permisos multi-nivel (Owner, Team, Public)
	- Zone validation con geometr�a 2D (point-in-circle)
	- Anti-exploit: validaci�n server-side de todos los placement
	- Event-driven: notifica cambios de ownership
	- Audit trail: registro de qui�n coloc� qu�

	ARQUITECTURA DE PERMISOS:
	+-----------------------------------------+
	� OWNER      ? Full control              �
	� TEAM       ? Shared building (futuro)  �
	� PUBLIC     ? Read-only visualization   �
	+-----------------------------------------+

	VALIDACI�N ANTI-EXPLOIT:
	1. �El jugador existe?
	2. �Tiene una base spawneada?
	3. �La posici�n est� dentro de su BuildZone?
	4. �No colisiona con objetos existentes?

	AUTHOR: Epic Ownership System v1
	COMPLEXITY: O(1) ownership check, O(n) zone validation
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Knit)

--[[------------------------------------------------------------------------
	TYPES & ENUMS
------------------------------------------------------------------------]]

export type PermissionLevel = "Owner" | "Team" | "Public" | "None"

export type ZoneType = "Build" | "Spawn" | "Restricted"

export type PlacedObject = {
	ObjectId: string,           -- GUID �nico del objeto
	OwnerId: number,            -- UserId del due�o de la base
	PlacedBy: number,           -- UserId de quien lo coloc�
	ObjectType: string,         -- Tipo de upgrade (ej: "Generator", "Turret")
	Position: Vector3,
	Rotation: number,
	PlacedAt: number,           -- Timestamp
	Instance: Instance?,        -- Referencia al objeto f�sico
}

export type ValidationResult = {
	IsValid: boolean,
	ErrorMessage: string?,
	ErrorCode: string?,
}

--[[------------------------------------------------------------------------
	SERVICE DEFINITION
------------------------------------------------------------------------]]

local BaseOwnershipService = Knit.CreateService({
	Name = "BaseOwnershipService",
	Client = {},
})

-- Internal state
local placedObjects: { [string]: PlacedObject } = {} -- Indexado por ObjectId
local baseObjects: { [number]: { PlacedObject } } = {} -- Indexado por OwnerId (userId)
local objectCounter = 0 -- Para generar IDs �nicos

-- Dependencies (se obtendr�n en KnitInit)
local BaseSpawnerService

--[[------------------------------------------------------------------------
	UTILITY - GUID Generation
------------------------------------------------------------------------]]

--[[
	Genera un ID �nico para objetos colocados.

	FORMATO: OBJ_{timestamp}_{counter}_{random}
	EJEMPLO: OBJ_1699999999_42_A3F7

	@return string - ID �nico garantizado
]]
local function generateObjectId(): string
	objectCounter += 1
	local timestamp = os.time()
	local random = string.format("%04X", math.random(0, 65535))
	return string.format("OBJ_%d_%d_%s", timestamp, objectCounter, random)
end

--[[------------------------------------------------------------------------
	GEOMETRY - Zone Validation
------------------------------------------------------------------------]]

--[[
	Verifica si un punto est� dentro de una zona circular (2D).

	MATEM�TICAS:
	- Ignora eje Y (solo plano XZ)
	- Distancia euclidiana 2D: sqrt((x2-x1)� + (z2-z1)�)
	- Punto est� dentro si: distancia <= radio

	OPTIMIZACI�N: Usa magnitud al cuadrado para evitar sqrt cuando sea posible

	@param point - Punto a verificar (Vector3)
	@param center - Centro de la zona (Vector3)
	@param radius - Radio de la zona
	@return boolean - true si est� dentro
]]
local function isPointInZone(point: Vector3, center: Vector3, radius: number): boolean
	-- Proyectar a plano XZ (ignorar altura Y)
	local dx = point.X - center.X
	local dz = point.Z - center.Z

	local distanceSquared = dx * dx + dz * dz
	local radiusSquared = radius * radius

	return distanceSquared <= radiusSquared
end

--[[
	Obtiene el tipo de zona en una posici�n para una base espec�fica.

	JERARQU�A DE ZONAS (del m�s restrictivo al menos):
	1. SpawnZone (radio peque�o) - Solo teleport
	2. BuildZone (radio medio) - Construcci�n permitida
	3. Fuera de zonas - Prohibido

	@param userId - Due�o de la base
	@param position - Posici�n a verificar
	@return ZoneType? - Tipo de zona, o nil si est� fuera
]]
local function getZoneTypeAtPosition(userId: number, position: Vector3): ZoneType?
	local baseData = BaseSpawnerService:GetBaseData(userId)
	if not baseData then
		return nil
	end

	local baseCenter = baseData.Position

	-- Obtener configuraci�n de zonas (hardcodeado por ahora, podr�a venir de config)
	local spawnRadius = 15  -- Radio del SpawnZone
	local buildRadius = 60  -- Radio del BuildZone

	-- Verificar SpawnZone primero (es m�s restrictivo)
	if isPointInZone(position, baseCenter, spawnRadius) then
		return "Spawn"
	end

	-- Verificar BuildZone
	if isPointInZone(position, baseCenter, buildRadius) then
		return "Build"
	end

	-- Fuera de todas las zonas
	return nil
end

--[[------------------------------------------------------------------------
	PERMISSION SYSTEM - Access Control
------------------------------------------------------------------------]]

--[[
	Determina el nivel de permisos de un jugador en una base.

	NIVELES:
	- "Owner"  ? Due�o de la base (full control)
	- "Team"   ? Miembro del equipo (futuro: compartir bases)
	- "Public" ? Visitante (solo visualizaci�n)
	- "None"   ? Sin acceso (fuera de la base)

	@param userId - ID del jugador
	@param baseOwnerId - ID del due�o de la base
	@return PermissionLevel - Nivel de permiso
]]
local function getPermissionLevel(userId: number, baseOwnerId: number): PermissionLevel
	-- Si es el due�o, tiene control total
	if userId == baseOwnerId then
		return "Owner"
	end

	-- FUTURO: Implementar sistema de teams
	-- local player = Players:GetPlayerByUserId(userId)
	-- local owner = Players:GetPlayerByUserId(baseOwnerId)
	-- if player and owner and player.Team == owner.Team then
	--     return "Team"
	-- end

	-- Por defecto, visitante p�blico
	return "Public"
end

--[[
	Verifica si un jugador puede construir en una posici�n.

	VALIDACIONES:
	1. Jugador debe tener base spawneada
	2. Posici�n debe estar en BuildZone de su base
	3. No debe estar en SpawnZone (reservado)
	4. Debe ser Owner o Team (Public no puede construir)

	@param userId - ID del jugador
	@param position - Posici�n donde quiere construir
	@return ValidationResult - Resultado con error si falla
]]
local function canBuildAtPosition(userId: number, position: Vector3): ValidationResult
	-- Validar que el jugador tenga base
	local baseData = BaseSpawnerService:GetBaseData(userId)
	if not baseData then
		return {
			IsValid = false,
			ErrorMessage = "No tienes una base spawneada",
			ErrorCode = "NO_BASE",
		}
	end

	-- Determinar zona
	local zoneType = getZoneTypeAtPosition(userId, position)

	if not zoneType then
		return {
			IsValid = false,
			ErrorMessage = "Posici�n fuera de tu zona de construcci�n",
			ErrorCode = "OUT_OF_BOUNDS",
		}
	end

	if zoneType == "Spawn" then
		return {
			IsValid = false,
			ErrorMessage = "No puedes construir en la zona de spawn",
			ErrorCode = "SPAWN_ZONE_BLOCKED",
		}
	end

	if zoneType == "Build" then
		-- Verificar permisos (solo Owner o Team pueden construir)
		local permission = getPermissionLevel(userId, userId)
		if permission ~= "Owner" and permission ~= "Team" then
			return {
				IsValid = false,
				ErrorMessage = "No tienes permisos para construir aqu�",
				ErrorCode = "INSUFFICIENT_PERMISSIONS",
			}
		end

		return {
			IsValid = true,
		}
	end

	-- Zona restringida (futuro)
	return {
		IsValid = false,
		ErrorMessage = "Zona restringida",
		ErrorCode = "RESTRICTED_ZONE",
	}
end

--[[------------------------------------------------------------------------
	OBJECT MANAGEMENT - Placement Tracking
------------------------------------------------------------------------]]

--[[
	Registra un objeto colocado en una base.

	PROCESO:
	1. Generar ID �nico
	2. Crear registro en placedObjects
	3. Agregar a �ndice de base (baseObjects)
	4. Retornar PlacedObject data

	IMPORTANTE: Este m�todo NO valida permisos, solo registra.
	Llama a canBuildAtPosition() ANTES de llamar esto.

	@param ownerId - Due�o de la base
	@param placedBy - Quien coloc� el objeto
	@param objectType - Tipo de upgrade
	@param position - Posici�n del objeto
	@param rotation - Rotaci�n (grados)
	@param instance - Referencia f�sica opcional
	@return PlacedObject - Datos del objeto registrado
]]
local function registerPlacedObject(
	ownerId: number,
	placedBy: number,
	objectType: string,
	position: Vector3,
	rotation: number,
	instance: Instance?
): PlacedObject
	local objectId = generateObjectId()

	local placedObject: PlacedObject = {
		ObjectId = objectId,
		OwnerId = ownerId,
		PlacedBy = placedBy,
		ObjectType = objectType,
		Position = position,
		Rotation = rotation,
		PlacedAt = os.time(),
		Instance = instance,
	}

	-- Registrar en �ndice global
	placedObjects[objectId] = placedObject

	-- Registrar en �ndice por base
	if not baseObjects[ownerId] then
		baseObjects[ownerId] = {}
	end
	table.insert(baseObjects[ownerId], placedObject)

	print(string.format(
		"[BaseOwnershipService] ?? Object registered: %s (Type: %s, Owner: %d, PlacedBy: %d)",
		objectId,
		objectType,
		ownerId,
		placedBy
		))

	return placedObject
end

--[[
	Elimina un objeto colocado.

	@param objectId - ID del objeto a eliminar
	@return boolean - true si se elimin� exitosamente
]]
local function unregisterPlacedObject(objectId: string): boolean
	local placedObject = placedObjects[objectId]
	if not placedObject then
		return false
	end

	-- Desregistrar de UpgradeService antes de destruir
	local UpgradeService = require(script.Parent.UpgradeService)
	UpgradeService:UnregisterUpgrade(objectId, placedObject.ObjectType)

	-- Destruir instancia f�sica si existe
	if placedObject.Instance then
		placedObject.Instance:Destroy()
	end

	-- Eliminar de �ndice global
	placedObjects[objectId] = nil

	-- Eliminar de �ndice de base
	local baseObjectsList = baseObjects[placedObject.OwnerId]
	if baseObjectsList then
		for i, obj in ipairs(baseObjectsList) do
			if obj.ObjectId == objectId then
				table.remove(baseObjectsList, i)
				break
			end
		end
	end

	print(string.format(
		"[BaseOwnershipService] ??? Object unregistered: %s",
		objectId
		))

	return true
end

--[[------------------------------------------------------------------------
	PUBLIC API - Service Methods
------------------------------------------------------------------------]]

--[[
	Valida si un jugador puede construir en una posici�n.
	(Wrapper p�blico del m�todo interno)
]]
function BaseOwnershipService:ValidatePlacement(userId: number, position: Vector3): ValidationResult
	return canBuildAtPosition(userId, position)
end

--[[
	Registra un objeto colocado tras validaci�n exitosa.
]]
function BaseOwnershipService:RegisterObject(
	ownerId: number,
	placedBy: number,
	objectType: string,
	position: Vector3,
	rotation: number,
	instance: Instance?
): PlacedObject?
	-- Validar permisos primero
	local validation = canBuildAtPosition(placedBy, position)
	if not validation.IsValid then
		warn("[BaseOwnershipService] Cannot register object:", validation.ErrorMessage)
		return nil
	end

	return registerPlacedObject(ownerId, placedBy, objectType, position, rotation, instance)
end

--[[
	Elimina un objeto si el jugador tiene permisos.
]]
function BaseOwnershipService:RemoveObject(userId: number, objectId: string): boolean
	local placedObject = placedObjects[objectId]
	if not placedObject then
		warn("[BaseOwnershipService] Object not found:", objectId)
		return false
	end

	-- Verificar permisos (solo owner puede eliminar)
	local permission = getPermissionLevel(userId, placedObject.OwnerId)
	if permission ~= "Owner" then
		warn("[BaseOwnershipService] Insufficient permissions to remove object")
		return false
	end

	return unregisterPlacedObject(objectId)
end

--[[
	Obtiene todos los objetos colocados en una base.
]]
function BaseOwnershipService:GetBaseObjects(ownerId: number): { PlacedObject }
	return baseObjects[ownerId] or {}
end

--[[
	Obtiene los datos de un objeto espec�fico.
]]
function BaseOwnershipService:GetObjectData(objectId: string): PlacedObject?
	return placedObjects[objectId]
end

--[[
	Limpia todos los objetos de una base (cuando se destruye).
]]
function BaseOwnershipService:ClearBaseObjects(ownerId: number): number
	local objects = baseObjects[ownerId]
	if not objects then
		return 0
	end

	local count = #objects

	-- Crear copia del array para evitar modificar mientras iteramos
	local objectsCopy = {}
	for _, obj in ipairs(objects) do
		table.insert(objectsCopy, obj.ObjectId)
	end

	-- Eliminar todos los objetos
	for _, objectId in ipairs(objectsCopy) do
		unregisterPlacedObject(objectId)
	end

	-- Limpiar array (ya deber�a estar vac�o, pero por seguridad)
	baseObjects[ownerId] = nil

	print(string.format(
		"[BaseOwnershipService] ?? Cleared %d objects from base (Owner: %d)",
		count,
		ownerId
		))

	return count
end

--[[
	Verifica si un jugador es due�o de una base.
]]
function BaseOwnershipService:IsOwner(userId: number, baseOwnerId: number): boolean
	return getPermissionLevel(userId, baseOwnerId) == "Owner"
end

--[[
	Obtiene el nivel de permisos de un jugador en una base.
]]
function BaseOwnershipService:GetPermissionLevel(userId: number, baseOwnerId: number): PermissionLevel
	return getPermissionLevel(userId, baseOwnerId)
end

--[[------------------------------------------------------------------------
	CLIENT API - M�todos Expuestos al Cliente
------------------------------------------------------------------------]]

--[[
	Valida desde el cliente si puede construir en una posici�n.

	SEGURIDAD: Esta es solo preview - la validaci�n REAL ocurre server-side
	en RegisterObject(). Esto permite mostrar feedback visual al cliente.
]]
function BaseOwnershipService.Client:CanBuild(player: Player, position: Vector3)
	return self.Server:ValidatePlacement(player.UserId, position)
end

--[[
	Obtiene los objetos de la base del jugador.
]]
function BaseOwnershipService.Client:GetMyObjects(player: Player)
	return self.Server:GetBaseObjects(player.UserId)
end

--[[
	Coloca un objeto desde el cliente (con validaci�n server-side).

	INTEGRACI�N CON UPGRADES:
	- Usa UpgradeDefinitions para crear modelos visuales
	- Registra en UpgradeService para funcionalidad (generators, turrets, etc.)
	- Valida placement server-side antes de crear
]]
function BaseOwnershipService.Client:PlaceObject(player: Player, objectType: string, position: Vector3, rotation: number, size: Vector3)
	-- Obtener definici�n del upgrade
	local UpgradeDefinitions = require(script.Parent.UpgradeDefinitions)
	local definition = UpgradeDefinitions.GetDefinition(objectType)

	if not definition then
		return {
			Success = false,
			ErrorMessage = "Invalid upgrade type: " .. objectType,
		}
	end

	-- Usar tama�o de la definici�n (no el pasado por par�metro)
	local actualSize = definition.Size

	-- Validar placement en servidor
	local BasePlacementService = require(script.Parent.BasePlacementService)
	local result = BasePlacementService:CalculatePlacement(player.UserId, position, rotation, actualSize)

	if not result.IsValid then
		return {
			Success = false,
			ErrorMessage = result.ErrorMessage,
			ErrorCode = result.ErrorCode,
		}
	end

	-- TODO: Verificar que el jugador tenga suficiente dinero (definition.Cost)
	-- Por ahora, permitir colocar gratis para testing

	-- Detectar si es una torreta y usar el CreateModel correcto
	local TurretDefinitions = require(script.Parent.TurretDefinitions)
	local model
	local isTurret = string.match(objectType, "^MachineGun")
		or string.match(objectType, "^Laser")
		or string.match(objectType, "^Missile")
		or string.match(objectType, "^Tesla")
		or objectType == "ShieldDome"

	if isTurret then
		-- Usar TurretDefinitions para torretas (incluye ProximityPrompts de upgrade)
		model = TurretDefinitions.CreateModel(objectType)
	else
		-- Usar UpgradeDefinitions para generators, storage, etc.
		model = UpgradeDefinitions.CreateModel(objectType)
	end

	if not model then
		return {
			Success = false,
			ErrorMessage = "Failed to create model for: " .. objectType,
		}
	end

	-- Posicionar modelo
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(CFrame.new(result.Position) * CFrame.Angles(0, math.rad(result.Rotation), 0))
	end
	model.Parent = workspace

	-- Registrar en el ownership system
	local placedObject = self.Server:RegisterObject(
		player.UserId,
		player.UserId,
		objectType,
		result.Position,
		result.Rotation,
		model
	)

	if placedObject then
		-- Agregar ObjectId como Attribute al modelo para identificación client-side
		if model.PrimaryPart then
			model.PrimaryPart:SetAttribute("ObjectId", placedObject.ObjectId)
			model.PrimaryPart:SetAttribute("OwnerId", player.UserId)
			model.PrimaryPart:SetAttribute("ObjectType", objectType)
		end

		-- Registrar en UpgradeService para funcionalidad
		local UpgradeService = require(script.Parent.UpgradeService)
		UpgradeService:RegisterUpgrade(placedObject.ObjectId, player.UserId, objectType, model)

		return {
			Success = true,
			ObjectId = placedObject.ObjectId,
			Position = result.Position,
			Rotation = result.Rotation,
		}
	else
		-- Si falla el registro, destruir el objeto
		model:Destroy()
		return {
			Success = false,
			ErrorMessage = "Failed to register object",
		}
	end
end

--[[------------------------------------------------------------------------
	LIFECYCLE HOOKS
------------------------------------------------------------------------]]

function BaseOwnershipService:KnitInit()
	print("[BaseOwnershipService] ?? Initialized")
end

function BaseOwnershipService:KnitStart()
	-- Obtener dependencia de BaseSpawnerService
	BaseSpawnerService = Knit.GetService("BaseSpawnerService")

	print("[BaseOwnershipService] ? Started - Permission system ready")
	print("[BaseOwnershipService] Anti-exploit validation: ENABLED")
end

return BaseOwnershipService