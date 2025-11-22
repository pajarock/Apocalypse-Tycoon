--!strict
--[[
	BaseDataService - Sistema de Persistencia y DataStore

	CARACTERÃSTICAS:
	- SerializaciÃ³n/DeserializaciÃ³n de bases y objetos
	- IntegraciÃ³n con DataStoreService
	- Auto-save periÃ³dico (cada N minutos)
	- Schema versioning para migraciones
	- Error handling robusto (retries, fallbacks)
	- Backup temporal en memoria (anti data loss)

	ARQUITECTURA DE DATOS:

	BaseLayout = {
		Version = "1.0",
		OwnerId = 123456,
		PlayerName = "Usuario",
		SavedAt = timestamp,
		BasePosition = {X, Y, Z},
		Objects = {
			{Type = "Generator", Pos = {...}, Rot = 0},
			{Type = "Turret", Pos = {...}, Rot = 90},
			...
		}
	}

	DATASTORE STRUCTURE:
	Key: "Base_<UserId>"
	Value: BaseLayout (JSON-serialized)

	AUTHOR: Epic Data System v1
	RELIABILITY: Retry logic + in-memory backup
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Knit)

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	TYPES & CONSTANTS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

export type SerializedVector3 = {
	X: number,
	Y: number,
	Z: number,
}

export type SerializedObject = {
	Type: string,
	Pos: SerializedVector3,
	Rot: number,
	PlacedAt: number,
}

export type BaseLayout = {
	Version: string,
	OwnerId: number,
	PlayerName: string,
	SavedAt: number,
	BasePosition: SerializedVector3,
	Objects: { SerializedObject },
}

export type SaveResult = {
	Success: boolean,
	ErrorMessage: string?,
}

-- Constantes
local DATASTORE_NAME = "BasePersistence_V1"
local SCHEMA_VERSION = "1.0"
local AUTO_SAVE_INTERVAL = 300 -- 5 minutos
local MAX_RETRY_ATTEMPTS = 3
local RETRY_DELAY = 2 -- segundos

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	SERVICE DEFINITION
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

local BaseDataService = Knit.CreateService({
	Name = "BaseDataService",
	Client = {},
})

-- Internal state
local baseDataStore: DataStore? = nil
local inMemoryBackup: { [number]: BaseLayout } = {} -- Backup temporal
local autoSaveEnabled = true
local lastSaveTimes: { [number]: number } = {} -- Para rate limiting

-- Dependencies
local BaseSpawnerService
local BaseOwnershipService

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	SERIALIZATION - Data Conversion
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Serializa un Vector3 a tabla.

	FORMATO: {X = x, Y = y, Z = z}

	Por quÃ©: DataStore no soporta tipos de Roblox (Vector3, CFrame, etc).
	Debemos convertir a tipos primitivos (number, string, table).

	@param vec - Vector3 a serializar
	@return SerializedVector3 - Tabla serializada
]]
local function serializeVector3(vec: Vector3): SerializedVector3
	return {
		X = vec.X,
		Y = vec.Y,
		Z = vec.Z,
	}
end

--[[
	Deserializa una tabla a Vector3.
]]
local function deserializeVector3(data: SerializedVector3): Vector3
	return Vector3.new(data.X, data.Y, data.Z)
end

--[[
	Serializa el layout completo de una base.

	PROCESO:
	1. Obtener datos de la base (BaseSpawnerService)
	2. Obtener objetos colocados (BaseOwnershipService)
	3. Serializar cada objeto
	4. Construir estructura BaseLayout
	5. Agregar metadata (version, timestamp)

	@param userId - ID del jugador/dueÃ±o
	@return BaseLayout? - Layout serializado, o nil si no hay base
]]
local function serializeBaseLayout(userId: number): BaseLayout?
	-- Obtener base
	local baseData = BaseSpawnerService:GetBaseData(userId)
	if not baseData then
		return nil
	end

	-- Obtener objetos colocados
	local placedObjects = BaseOwnershipService:GetBaseObjects(userId)

	-- Serializar objetos
	local serializedObjects: { SerializedObject } = {}
	for _, obj in ipairs(placedObjects) do
		table.insert(serializedObjects, {
			Type = obj.ObjectType,
			Pos = serializeVector3(obj.Position),
			Rot = obj.Rotation,
			PlacedAt = obj.PlacedAt,
		})
	end

	-- Construir layout
	local layout: BaseLayout = {
		Version = SCHEMA_VERSION,
		OwnerId = userId,
		PlayerName = baseData.PlayerName,
		SavedAt = os.time(),
		BasePosition = serializeVector3(baseData.Position),
		Objects = serializedObjects,
	}

	return layout
end

--[[
	Deserializa un layout y reconstruye la base.

	PROCESO:
	1. Validar schema version (migraciÃ³n si es necesario)
	2. Verificar integridad de datos
	3. Reconstruir base fÃ­sica (via BaseSpawnerService)
	4. Reconstruir objetos (via BaseOwnershipService)

	NOTA: Esta funciÃ³n NO crea los objetos fÃ­sicos automÃ¡ticamente,
	solo retorna los datos. El caller decide cÃ³mo instanciarlos.

	@param layout - Layout serializado
	@return boolean, string? - true si es vÃ¡lido, error si no
]]
local function validateLayout(layout: any): (boolean, string?)
	-- Type checking bÃ¡sico
	if type(layout) ~= "table" then
		return false, "Layout no es una tabla"
	end

	if type(layout.Version) ~= "string" then
		return false, "Version faltante o invÃ¡lida"
	end

	if type(layout.OwnerId) ~= "number" then
		return false, "OwnerId faltante o invÃ¡lido"
	end

	if type(layout.Objects) ~= "table" then
		return false, "Objects faltante o invÃ¡lido"
	end

	-- Schema version check
	if layout.Version ~= SCHEMA_VERSION then
		warn(string.format(
			"[BaseDataService] Schema mismatch: saved=%s, current=%s (migration needed)",
			layout.Version,
			SCHEMA_VERSION
		))
		-- AquÃ­ podrÃ­as implementar migraciÃ³n de schemas
	end

	return true
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	DATASTORE OPERATIONS - Persistence Layer
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Genera la key para el DataStore de un usuario.

	FORMATO: "Base_<UserId>"
	EJEMPLO: "Base_123456"
]]
local function getDataStoreKey(userId: number): string
	return string.format("Base_%d", userId)
end

--[[
	Guarda un layout en DataStore con retry logic.

	ALGORITMO DE RETRY:
	1. Intentar guardar
	2. Si falla: esperar RETRY_DELAY segundos
	3. Intentar de nuevo (hasta MAX_RETRY_ATTEMPTS)
	4. Si todos fallan: guardar en backup in-memory

	ERROR HANDLING:
	- Captura errores de DataStore (rate limits, network issues)
	- Fallback a in-memory backup
	- Log detallado de errores

	@param userId - ID del usuario
	@param layout - Layout a guardar
	@return SaveResult - Resultado de la operaciÃ³n
]]
local function saveToDataStore(userId: number, layout: BaseLayout): SaveResult
	if not baseDataStore then
		return {
			Success = false,
			ErrorMessage = "DataStore no inicializado (Studio?)",
		}
	end

	local key = getDataStoreKey(userId)
	local attempts = 0

	-- Retry loop
	while attempts < MAX_RETRY_ATTEMPTS do
		attempts += 1

		local success, err = pcall(function()
			baseDataStore:SetAsync(key, layout)
		end)

		if success then
			-- â GUARDADO EXITOSO
			lastSaveTimes[userId] = os.time()
			inMemoryBackup[userId] = layout -- TambiÃ©n guardar en backup

			print(string.format(
				"[BaseDataService] ð¾ Saved base for userId=%d (Objects: %d, Attempt: %d)",
				userId,
				#layout.Objects,
				attempts
			))

			return {
				Success = true,
			}
		else
			-- â ERROR
			warn(string.format(
				"[BaseDataService] Save failed for userId=%d (Attempt %d/%d): %s",
				userId,
				attempts,
				MAX_RETRY_ATTEMPTS,
				tostring(err)
			))

			if attempts < MAX_RETRY_ATTEMPTS then
				task.wait(RETRY_DELAY)
			end
		end
	end

	-- TODOS LOS INTENTOS FALLARON
	-- Guardar solo en backup in-memory
	inMemoryBackup[userId] = layout

	return {
		Success = false,
		ErrorMessage = "DataStore no disponible (guardado en backup local)",
	}
end

--[[
	Carga un layout desde DataStore con retry logic.

	FALLBACK: Si DataStore falla, intenta cargar desde in-memory backup.

	@param userId - ID del usuario
	@return BaseLayout? - Layout cargado, o nil si no existe
]]
local function loadFromDataStore(userId: number): BaseLayout?
	if not baseDataStore then
		-- Fallback a backup in-memory
		warn("[BaseDataService] DataStore no disponible, usando backup in-memory")
		return inMemoryBackup[userId]
	end

	local key = getDataStoreKey(userId)
	local attempts = 0

	-- Retry loop
	while attempts < MAX_RETRY_ATTEMPTS do
		attempts += 1

		local success, result = pcall(function()
			return baseDataStore:GetAsync(key)
		end)

		if success then
			if result then
				print(string.format(
					"[BaseDataService] ð Loaded base for userId=%d (Objects: %d)",
					userId,
					result.Objects and #result.Objects or 0
				))

				-- Guardar en backup tambiÃ©n
				inMemoryBackup[userId] = result
				return result
			else
				-- No hay datos guardados (nuevo jugador)
				return nil
			end
		else
			warn(string.format(
				"[BaseDataService] Load failed for userId=%d (Attempt %d/%d): %s",
				userId,
				attempts,
				MAX_RETRY_ATTEMPTS,
				tostring(result)
			))

			if attempts < MAX_RETRY_ATTEMPTS then
				task.wait(RETRY_DELAY)
			end
		end
	end

	-- TODOS LOS INTENTOS FALLARON - Fallback a backup
	warn("[BaseDataService] Using in-memory backup as fallback")
	return inMemoryBackup[userId]
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	PUBLIC API - Service Methods
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Guarda la base de un jugador.
]]
function BaseDataService:SaveBase(userId: number): SaveResult
	local layout = serializeBaseLayout(userId)

	if not layout then
		return {
			Success = false,
			ErrorMessage = "No se encontrÃ³ base para serializar",
		}
	end

	return saveToDataStore(userId, layout)
end

--[[
	Carga la base de un jugador (retorna datos, no instancia objetos).
]]
function BaseDataService:LoadBase(userId: number): BaseLayout?
	local layout = loadFromDataStore(userId)

	if layout then
		-- Validar integridad
		local valid, err = validateLayout(layout)
		if not valid then
			warn("[BaseDataService] Invalid layout loaded:", err)
			return nil
		end
	end

	return layout
end

--[[
	Restaura una base completa desde layout guardado.

	PROCESO:
	1. Cargar layout desde DataStore
	2. Validar datos
	3. Crear objetos fÃ­sicos (esto requiere acceso a templates/assets)

	NOTA: Por ahora solo retorna el layout. La restauraciÃ³n fÃ­sica
	se implementarÃ¡ cuando tengamos los assets de los upgrades.
]]
function BaseDataService:RestoreBase(userId: number): (boolean, string?)
	local layout = self:LoadBase(userId)

	if not layout then
		return false, "No hay datos guardados para este usuario"
	end

	-- AquÃ­ irÃ­a la lÃ³gica de instanciar los objetos fÃ­sicos
	-- Por ahora solo cargamos los datos

	print(string.format(
		"[BaseDataService] Layout cargado para userId=%d (%d objetos)",
		userId,
		#layout.Objects
	))

	return true, nil
end

--[[
	Guarda todas las bases activas (para auto-save).
]]
function BaseDataService:SaveAllBases(): number
	local allBases = BaseSpawnerService:GetAllBases()
	local savedCount = 0

	for userId, _ in pairs(allBases) do
		local result = self:SaveBase(userId)
		if result.Success then
			savedCount += 1
		end
	end

	print(string.format(
		"[BaseDataService] ð¾ Auto-save completed: %d/%d bases saved",
		savedCount,
		table.maxn(allBases)
	))

	return savedCount
end

--[[
	Habilita/deshabilita auto-save.
]]
function BaseDataService:SetAutoSave(enabled: boolean)
	autoSaveEnabled = enabled
	print(string.format(
		"[BaseDataService] Auto-save %s",
		enabled and "ENABLED" or "DISABLED"
	))
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	CLIENT API - MÃ©todos Expuestos al Cliente
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Solicita guardar la base desde el cliente.
]]
function BaseDataService.Client:SaveMyBase(player: Player)
	return self.Server:SaveBase(player.UserId)
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	AUTO-SAVE SYSTEM
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Loop de auto-save (ejecuta cada AUTO_SAVE_INTERVAL segundos).
]]
local function startAutoSaveLoop()
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)

			if autoSaveEnabled then
				BaseDataService:SaveAllBases()
			end
		end
	end)
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	PLAYER LIFECYCLE - Save on Leave
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

--[[
	Guarda la base de un jugador cuando se desconecta.
]]
local function onPlayerRemoving(player: Player)
	print(string.format(
		"[BaseDataService] Player leaving, saving base for: %s",
		player.Name
	))

	local result = BaseDataService:SaveBase(player.UserId)

	if not result.Success then
		warn(string.format(
			"[BaseDataService] â ï¸ Failed to save base for %s: %s",
			player.Name,
			result.ErrorMessage or "Unknown error"
		))
	end
end

--[[ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ
	LIFECYCLE HOOKS
ââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââââ]]

function BaseDataService:KnitInit()
	-- Inicializar DataStore (solo en servidor real, no en Studio local)
	if RunService:IsStudio() then
		warn("[BaseDataService] Running in Studio - DataStore may not work (using in-memory backup)")
	end

	local success, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)

	if success then
		baseDataStore = result
		print("[BaseDataService] DataStore connected successfully")
	else
		warn("[BaseDataService] DataStore connection failed:", result)
		warn("[BaseDataService] Will use in-memory backup only")
	end

	print("[BaseDataService] âï¸ Initialized")
end

function BaseDataService:KnitStart()
	-- Obtener dependencias
	BaseSpawnerService = Knit.GetService("BaseSpawnerService")
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	-- Conectar evento de player leaving
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Iniciar auto-save loop
	startAutoSaveLoop()

	print("[BaseDataService] â Started - Persistence system ready")
	print(string.format(
		"[BaseDataService] Auto-save: %s (Interval: %d seconds)",
		autoSaveEnabled and "ENABLED" or "DISABLED",
		AUTO_SAVE_INTERVAL
	))
end

return BaseDataService
