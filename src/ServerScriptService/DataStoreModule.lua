--!strict
-- DataStoreModule.lua  (robusto y defensivo)

local DataStoreService = game:GetService("DataStoreService")
local Config = require(game.ServerStorage.Config.Config)

local DataStoreModule = {}

-- Config defensivo
local DS_NAME           = tostring(Config.DATASTORE_NAME or "apocalypsetycoon_v1")
local MAX_RETRIES       = tonumber(Config.MAX_SAVE_RETRIES) or 3
local RETRY_DELAY_BASE  = 1
local RETRY_BACKOFF     = 2
local MIN_CASH          = tonumber(Config.MIN_CASH) or 0
local MAX_CASH          = tonumber(Config.MAX_CASH) or 9e15
local DATA_VERSION      = tonumber(Config.DATA_VERSION) or 1
local DEBUG             = not not Config.DEBUG_MODE

local ds = DataStoreService:GetDataStore(DS_NAME)

export type SaveBlob = {
	DataVersion: number,
	Cash: number,
	OwnedUpgrades: {[string]: number},
	TotalEarned: number,
	TotalSpent: number,
	PrestigeLevel: number,
	LastSave: number,
	LastLogout: number?,
	__isNew: boolean?  -- bandera interna para Economy
}

-- ========== helpers ==========

local function validateBlob(data:any): boolean
	if typeof(data) ~= "table" then return false end
	if typeof(data.Cash) ~= "number" then return false end
	if typeof(data.OwnedUpgrades) ~= "table" then return false end
	for id, count in pairs(data.OwnedUpgrades) do
		if typeof(id) ~= "string" or typeof(count) ~= "number" then
			return false
		end
	end
	return true
end

local function migrateData(data:any): SaveBlob
	local b = table.clone(data) :: any
	local version = tonumber(b.DataVersion) or 0

	-- v0 -> v1: booleans a números, rellenar campos
	if version == 0 then
		if b.OwnedUpgrades then
			for id, val in pairs(b.OwnedUpgrades) do
				if typeof(val) == "boolean" then
					b.OwnedUpgrades[id] = val and 1 or 0
				end
			end
		end
		b.TotalEarned   = tonumber(b.TotalEarned)   or 0
		b.TotalSpent    = tonumber(b.TotalSpent)    or 0
		b.PrestigeLevel = tonumber(b.PrestigeLevel) or 0
		b.DataVersion   = 1
	end

	return b :: SaveBlob
end

local function sanitizeBlob(blob: SaveBlob): SaveBlob
	blob.DataVersion   = tonumber(blob.DataVersion) or DATA_VERSION
	blob.Cash          = math.clamp(tonumber(blob.Cash) or 0, MIN_CASH, MAX_CASH)
	blob.TotalEarned   = tonumber(blob.TotalEarned)   or 0
	blob.TotalSpent    = tonumber(blob.TotalSpent)    or 0
	blob.PrestigeLevel = tonumber(blob.PrestigeLevel) or 0
	blob.LastSave      = tonumber(blob.LastSave) or os.time()
	if blob.LastLogout ~= nil then
		blob.LastLogout = tonumber(blob.LastLogout) or 0
	end
	if typeof(blob.OwnedUpgrades) ~= "table" then
		blob.OwnedUpgrades = {}
	end
	for id, count in pairs(blob.OwnedUpgrades) do
		if typeof(count) ~= "number" or count < 0 then
			blob.OwnedUpgrades[id] = 0
		end
	end
	return blob
end

-- ========== API ==========
function DataStoreModule:DefaultBlob()
	return {
		DataVersion   = DATA_VERSION,
		Cash          = tonumber(Config.START_CASH) or 0,
		OwnedUpgrades = {},
		TotalEarned   = 0,
		TotalSpent    = 0,
		PrestigeLevel = 0,
		LastSave      = os.time(),
		LastLogout    = nil,
	}
end


function DataStoreModule:LoadAsync(userId:number): SaveBlob
		-- 🔴 TEMPORAL: Forzar datos fresh para testing
		if Config.DEBUG_MODE then
			print(("[DATASTORE] 🆕 FORZANDO datos fresh para testing"))
			local freshBlob = self:DefaultBlob()
			freshBlob.__fresh = true
			return freshBlob
		end
		-- El resto del código normal continúa...
	local key = "u_" .. tostring(userId)
	

	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(function()
			return ds:GetAsync(key)
		end)

		if ok then
			-- Jugador nuevo
			if result == nil then
				if DEBUG then
					print(("[DATASTORE] nuevo %s → defaults"):format(tostring(userId)))
				end
				local b = self:DefaultBlob()
				b.__fresh = true               -- << bandera para Economy
				return b
			end

			-- valida y migra
			if not validateBlob(result) then
				warn(("[DATASTORE] datos corruptos %s → defaults"):format(tostring(userId)))
				local b = self:DefaultBlob()
				b.__fresh = true
				return b
			end

			local migrated  = migrateData(result)
			local sanitized = sanitizeBlob(migrated)

			if DEBUG then
				print(("[DATASTORE] cargado %s  cash=$%s  prestige=%s")
					:format(
						tostring(userId),
						tostring(sanitized.Cash),
						tostring(sanitized.PrestigeLevel)
					))
			end

			return sanitized

		else
			warn(("[DATASTORE] error load uid=%d (%d/%d): %s")
				:format(userId, attempt, MAX_RETRIES, tostring(result)))
			if attempt < MAX_RETRIES then
				task.wait(RETRY_DELAY_BASE * (RETRY_BACKOFF ^ (attempt-1)))
			end
		end
	end

	warn(("[DATASTORE] FALLO CRÍTICO load uid=%d -> defaults"):format(userId))
	return sanitizeBlob(self:DefaultBlob())
end

function DataStoreModule:SaveAsync(userId:number, blob:SaveBlob): boolean
	local key = "u_" .. tostring(userId)
	blob.LastSave    = os.time()
	blob.DataVersion = DATA_VERSION
	blob.__isNew     = nil  -- no persistimos bandera interna
	blob = sanitizeBlob(blob)

	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			ds:SetAsync(key, blob)
		end)
		if ok then
			if DEBUG then
				print(("[DATASTORE] saved uid=%d cash=%d"):format(userId, blob.Cash))
			end
			return true
		else
			warn(("[DATASTORE] error save uid=%d (%d/%d): %s")
				:format(userId, attempt, MAX_RETRIES, tostring(err)))
			if attempt < MAX_RETRIES then
				task.wait(RETRY_DELAY_BASE * (RETRY_BACKOFF ^ (attempt-1)))
			end
		end
	end

	warn(("[DATASTORE] FALLO CRÍTICO save uid=%d"):format(userId))
	return false
end

function DataStoreModule:SaveAsyncSafe(userId:number, blob:SaveBlob): boolean
	local key = "u_" .. tostring(userId)
	blob.LastSave    = os.time()
	blob.DataVersion = DATA_VERSION
	blob.__isNew     = nil
	blob = sanitizeBlob(blob)

	for attempt = 1, MAX_RETRIES do
		local ok, err = pcall(function()
			ds:UpdateAsync(key, function(old:any?)
				if old and typeof(old) == "table" and typeof(old.Cash) == "number" then
					if old.Cash > blob.Cash then
						if DEBUG then
							warn(("[DATASTORE] desync cash uid=%d local=%d remote=%d")
								:format(userId, blob.Cash, old.Cash))
						end
						blob.Cash = old.Cash
					end
				end
				return blob
			end)
		end)
		if ok then
			if DEBUG then print(("[DATASTORE] saved(SAFE) uid=%d"):format(userId)) end
			return true
		else
			warn(("[DATASTORE] error save(SAFE) uid=%d (%d/%d): %s")
				:format(userId, attempt, MAX_RETRIES, tostring(err)))
			if attempt < MAX_RETRIES then
				task.wait(RETRY_DELAY_BASE * (RETRY_BACKOFF ^ (attempt-1)))
			end
		end
	end

	warn(("[DATASTORE] FALLO CRÍTICO save(SAFE) uid=%d"):format(userId))
	return false
end

function DataStoreModule:DeleteAsync(userId:number): boolean
	local key = "u_" .. tostring(userId)
	local ok, err = pcall(function() ds:RemoveAsync(key) end)
	if ok then
		warn(("[DATASTORE] borrado uid=%d"):format(userId)); return true
	else
		warn(("[DATASTORE] error borrar uid=%d: %s"):format(userId, tostring(err))); return false
	end
end

-- No disponible en DataStore estándar
function DataStoreModule:ListKeysAsync(_prefix:string?, _limit:number?): {string}
	warn("[DATASTORE] ListKeysAsync no disponible en DataStore estándar.")
	return {}
end

function DataStoreModule:CreateBackup(userId:number): boolean
	local key = "u_" .. tostring(userId)
	local backupKey = "backup_" .. key .. "_" .. os.time()
	local ok, err = pcall(function()
		local data = ds:GetAsync(key)
		if data ~= nil then
			ds:SetAsync(backupKey, data)
		end
	end)
	if ok then
		print(("[DATASTORE] backup creado: %s"):format(backupKey)); return true
	else
		warn(("[DATASTORE] error backup uid=%d: %s"):format(userId, tostring(err))); return false
	end
end

function DataStoreModule:GetStats(): {[string]: any}
	return {
		DataStoreName = DS_NAME,
		DataVersion   = DATA_VERSION,
		MaxRetries    = MAX_RETRIES,
		RetryBackoff  = RETRY_BACKOFF,
	}
end

if DEBUG then
	print("[DATASTORE] módulo cargado")
	print(("[DATASTORE] store=%s  version=%d"):format(DS_NAME, DATA_VERSION))
end

-- =========================
-- Wipe Player Data (resetear progreso)
-- =========================
function DataStoreModule.WipePlayerData(userId: number)
	local success, err = pcall(function()
		local dataStore = DataStoreService:GetDataStore(DS_NAME)
		dataStore:RemoveAsync("player_" .. tostring(userId))
	end)

	if success then
		print("✅ Data borrada para jugador:", userId)
	else
		warn("❌ Error al borrar data para", userId, "->", err)
	end
end

function DataStoreModule:WipePlayer(userId: number)
	self:DeleteAsync(userId)
	local plr = Players:GetPlayerByUserId(userId)
	if plr then plr:Kick("Reset complete") end
end

return DataStoreModule
