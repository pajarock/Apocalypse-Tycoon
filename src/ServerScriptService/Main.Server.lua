--!strict
--[[
	═══════════════════════════════════════════════════════════════════════
	APOCALYPSE TYCOON - MAIN SERVER
	═══════════════════════════════════════════════════════════════════════
	VERSIÓN: 5.0 PRODUCTION READY
	AUTOR: Tu Equipo
	ÚLTIMA ACTUALIZACIÓN: 2025
	
	CARACTERÍSTICAS:
	✓ Sistema completo de economía con anti-exploit
	✓ Sistema de waves dinámicas con boss fights
	✓ Sistema de achievements y badges
	✓ Sistema de prestige y progresión
	✓ Sistema VIP y gamepasses
	✓ Sistema de daily rewards
	✓ Sistema de leaderboards global
	✓ Sistema de commands (admin y debug)
	✓ Sistema de analytics y telemetría
	✓ Sistema de backup automático
	✓ Sistema de rate limiting
	✓ Sistema de tutorial para nuevos jugadores
	✓ Sistema de quests/missions
	✓ Sistema de sonidos y efectos
	✓ Sistema de server events especiales
	✓ Optimizaciones de rendimiento
	✓ Manejo robusto de errores
	
	NOTAS DE PRODUCCIÓN:
	- Testear en servidor privado antes de público
	- Configurar gamepasses IDs en Config
	- Configurar badge IDs en AchievementModule
	- Activar analytics si es necesario
	- Revisar limits de rate limiting
	═══════════════════════════════════════════════════════════════════════
--]]

--═══════════════════════════════════════════════════════════════════════
-- SERVICIOS
--═══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")

--Bloque hasta que 1_CreateRemotes termine
local RS = game:GetService("ReplicatedStorage")
RS:WaitForChild("Remotes"):WaitForChild("CameraShake")  

-- 🎨 VISUAL OVERHAUL (Pack 2)
local EnvironmentManager = require(ServerStorage.Managers.EnvironmentManager)
local BaseVisualsManager = require(ServerStorage.Managers.BaseVisualsManager)
local ProceduralModels = require(ServerStorage.Managers.ProceduralModels)
local BuildEffectsManager = require(ServerStorage.Managers.BuildEffectsManager)

--═══════════════════════════════════════════════════════════════════════
-- MÓDULOS
--═══════════════════════════════════════════════════════════════════════
local Config = require(ServerStorage.Config.Config)
local UpgDefs = require(ServerStorage.Config.Upgrades)
local DataStore = require(ServerScriptService.DataStoreModule)
local Economy = require(ServerScriptService.EconomyModule)
local Events = require(ServerScriptService.EventManager)
local Base = require(ServerScriptService.BaseModule)

-- ✅ POWERUP SYSTEM
local PowerUpModule = require(ServerScriptService.PowerUpModule)

-- ✅ NUEVO: Inyectar BaseModule en EventManager (arregla dependencia circular)
Events:SetBaseModule(Base)

-- ✅ Inyectar dependencias en PowerUpModule
PowerUpModule.SetDependencies(Base, Economy)

-- Módulo de achievements (crear si no existe)
local Achievements = ServerScriptService:FindFirstChild("AchievementModule")
if Achievements then
	Achievements = require(Achievements)
end

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTES Y CONFIGURACIÓN
--═══════════════════════════════════════════════════════════════════════
local IS_STUDIO = RunService:IsStudio()
local DEBUG = Config.DEBUG_MODE and IS_STUDIO

-- IDs de gamepasses (CONFIGURAR EN PRODUCCIÓN)
local GAMEPASS_DOUBLE_INCOME = Config.GAMEPASSES.DoubleIncome.ID
local GAMEPASS_INSTANT_REPAIR = Config.GAMEPASSES.InstantRepair.ID
local GAMEPASS_PREMIUM_SLOTS = Config.GAMEPASSES.PremiumSlots.ID

-- Admin list (userId)
local ADMINS = {
	-- Agregar tus IDs aquí
}

-- Limits de rate limiting
local RATE_LIMITS = {
	Purchase = {max = 10, window = 1}, -- 10 compras por segundo
	Repair = {max = 5, window = 1},
	Command = {max = 20, window = 5},
}

--═══════════════════════════════════════════════════════════════════════
-- ESTADO GLOBAL DEL SERVIDOR
--═══════════════════════════════════════════════════════════════════════
local ServerState = {
	StartTime = os.time(),
	CurrentWave = 1,
	PlayersJoined = 0,
	TotalPurchases = 0,
	TotalDamage = 0,
	ServerEvents = {},
	Leaderboard = {},
}
-- ✅ NUEVO: Crear IntValue para sincronizar wave counter con clientes
local CurrentWaveValue = Instance.new("IntValue")
CurrentWaveValue.Name = "CurrentWave"
CurrentWaveValue.Value = ServerState.CurrentWave
CurrentWaveValue.Parent = ReplicatedStorage

if Config.DEBUG_MODE then
	print("[MAIN] ✅ IntValue 'CurrentWave' creado en ReplicatedStorage")
end

local NextSlot = 1
local SlotByUserId = {}
local BasePartByUser = {}
local BuildIndexByCategory = {}
local LastActionTime = {} -- Rate limiting

-- Gamepasses cache
local GamepassCache = {}

-- Tutorial tracking
local TutorialCompleted = {}

-- Daily rewards tracking
local DailyRewards = {}
local LastDailyReward = {}

--═══════════════════════════════════════════════════════════════════════
-- REMOTES
--═══════════════════════════════════════════════════════════════════════
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
assert(Remotes, "[MAIN] Falta carpeta Remotes")

local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction
local RequestBaseState = Remotes:WaitForChild("RequestBaseState") :: RemoteFunction
local RequestRepair = Remotes:WaitForChild("RequestRepair") :: RemoteEvent
local BaseStateChanged = Remotes:WaitForChild("BaseStateChanged") :: RemoteEvent
local CashTick = Remotes:WaitForChild("CashTick") :: RemoteEvent

-- 🎰 Remote para comprar powerups desde la máquina
local PurchasePowerUp = Remotes:FindFirstChild("PurchasePowerUp") :: RemoteEvent?
if not PurchasePowerUp then
	PurchasePowerUp = Instance.new("RemoteEvent")
	PurchasePowerUp.Name = "PurchasePowerUp"
	PurchasePowerUp.Parent = Remotes
	print("[POWERUP] RemoteEvent 'PurchasePowerUp' creado automáticamente")
end
local BaseDamaged = Remotes:WaitForChild("BaseDamaged") :: RemoteEvent

-- Remotes adicionales (crear si no existen)
local function getOrCreateRemote(name: string, remoteType: string): RemoteEvent | RemoteFunction
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		if remoteType == "Event" then
			remote = Instance.new("RemoteEvent")
		else
			remote = Instance.new("RemoteFunction")
		end
		remote.Name = name
		remote.Parent = Remotes

		if DEBUG then
			print(("[REMOTES] Creado: %s (%s)"):format(name, remoteType))
		end
	end
	return remote
end

local RequestSell = getOrCreateRemote("RequestSell", "Event") :: RemoteEvent
local RequestPrestige = getOrCreateRemote("RequestPrestige", "Event") :: RemoteEvent
local RequestDailyReward = getOrCreateRemote("RequestDailyReward", "Event") :: RemoteEvent
local AdminCommand = getOrCreateRemote("AdminCommand", "Event") :: RemoteEvent
local RequestLeaderboard = getOrCreateRemote("RequestLeaderboard", "Function") :: RemoteFunction
local ShowNotification = getOrCreateRemote("ShowNotification", "Event") :: RemoteEvent
local CompleteTutorial = getOrCreateRemote("CompleteTutorial", "Event") :: RemoteEvent
local WaveResult = getOrCreateRemote("WaveResult", "Event") :: RemoteEvent -- ✅ Para mensajes épicos

--═══════════════════════════════════════════════════════════════════════
-- UTILIDADES
--═══════════════════════════════════════════════════════════════════════

-- Verificar si es admin
local function isAdmin(userId: number): boolean
	return table.find(ADMINS, userId) ~= nil
end

-- Verificar gamepass
local function hasGamepass(userId: number, gamepassId: number): boolean
	if gamepassId == 0 then return false end

	-- Cache
	local cacheKey = ("%d_%d"):format(userId, gamepassId)
	if GamepassCache[cacheKey] ~= nil then
		return GamepassCache[cacheKey]
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(userId, gamepassId)
	end)

	local result = success and owns or false
	GamepassCache[cacheKey] = result
	return result
end

-- Rate limiting
local function checkRateLimit(userId: number, action: string): boolean
	local limit = RATE_LIMITS[action]
	if not limit then return true end

	local key = ("%d_%s"):format(userId, action)
	local now = tick()

	if not LastActionTime[key] then
		LastActionTime[key] = {times = {}, count = 0}
	end

	local data = LastActionTime[key]

	-- Limpiar tiempos antiguos
	local cutoff = now - limit.window
	local newTimes = {}
	for _, t in ipairs(data.times) do
		if t > cutoff then
			table.insert(newTimes, t)
		end
	end
	data.times = newTimes
	data.count = #newTimes

	-- Verificar límite
	if data.count >= limit.max then
		if DEBUG then
			warn(("[RATE_LIMIT] Usuario %d excedió límite de %s"):format(userId, action))
		end
		return false
	end

	-- Registrar acción
	table.insert(data.times, now)
	data.count += 1
	return true
end

-- Notificar jugador
local function notifyPlayer(plr: Player, message: string, duration: number?)
	if ShowNotification then
		ShowNotification:FireClient(plr, message, duration or 3)
	end
end

-- Broadcast a todos
local function broadcastNotification(message: string, duration: number?)
	if ShowNotification then
		for _, plr in ipairs(Players:GetPlayers()) do
			ShowNotification:FireClient(plr, message, duration or 3)
		end
	end
end

-- Log de analytics
local function logAnalytic(eventName: string, data: any?)
	if not Config.ANALYTICS.Enabled then return end

	-- Aquí puedes integrar con servicios externos como Google Analytics
	-- o simplemente guardar en DataStore para análisis posterior

	if DEBUG then
		print(("[ANALYTICS] %s: %s"):format(eventName, HttpService:JSONEncode(data or {})))
	end
end

-- Obtener carpeta de bases
local function getBasesFolder(): Folder
	local f = workspace:FindFirstChild("Bases")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Bases"
		f.Parent = workspace
	end
	return f
end

-- Taggear modelo con owner
local function tagOwned(inst: Instance, userId: number)
	inst:SetAttribute("OwnerUserId", userId)
	if inst:IsA("Model") then
		for _, child in ipairs(inst:GetDescendants()) do
			if child:IsA("BasePart") then
				child:SetAttribute("OwnerUserId", userId)
			end
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE LEADERSTATS
--═══════════════════════════════════════════════════════════════════════
local function createLeaderstats(plr: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = plr

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = ls

	local ips = Instance.new("IntValue")
	ips.Name = "IncomePerSec"
	ips.Value = 0
	ips.Parent = ls

	-- Stats adicionales (ocultas para UI pero útiles)
	local stats = Instance.new("Folder")
	stats.Name = "Stats"
	stats.Parent = plr

	local totalEarned = Instance.new("IntValue")
	totalEarned.Name = "TotalEarned"
	totalEarned.Value = 0
	totalEarned.Parent = stats

	local totalSpent = Instance.new("IntValue")
	totalSpent.Name = "TotalSpent"
	totalSpent.Value = 0
	totalSpent.Parent = stats

	local meteorsSurvived = Instance.new("IntValue")
	meteorsSurvived.Name = "MeteorsSurvived"
	meteorsSurvived.Value = 0
	meteorsSurvived.Parent = stats

	local prestigeLevel = Instance.new("IntValue")
	prestigeLevel.Name = "PrestigeLevel"
	prestigeLevel.Value = 0
	prestigeLevel.Parent = stats

	local playTime = Instance.new("IntValue")
	playTime.Name = "PlayTime"
	playTime.Value = 0
	playTime.Parent = stats

	return ls, cash, ips
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE BASES Y SPAWN
--═══════════════════════════════════════════════════════════════════════
local function createBaseBillboard(plate: BasePart, playerName: string, userId: number)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(300, 80)
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.AlwaysOnTop = true
	bb.Parent = plate

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = playerName .. "'s Base"
	nameLabel.Parent = frame

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HPLabel"
	hpLabel.Size = UDim2.fromScale(1, 0.5)
	hpLabel.Position = UDim2.fromScale(0, 0.5)
	hpLabel.BackgroundTransparency = 1
	hpLabel.TextScaled = true
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	hpLabel.Text = string.format("HP: %d/%d", Base.GetHP(userId), Config.BASE_MAX_HP)
	hpLabel.Parent = frame

	-- Actualizar HP label periódicamente
	task.spawn(function()
		while plate and plate.Parent and Players:GetPlayerByUserId(userId) do
			local hp = Base.GetHP(userId)
			local maxHP = Config.BASE_MAX_HP
			local pct = hp / maxHP

			hpLabel.Text = string.format("HP: %d/%d", hp, maxHP)

			if pct > 0.7 then
				hpLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
			elseif pct > 0.3 then
				hpLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
			else
				hpLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			end

			task.wait(2)
		end
	end)
end

local function assignBase(plr: Player, slot: number)
	local totalSlots = math.max(NextSlot - 1, 1)
	local angle = ((slot - 1) / totalSlots) * 2 * math.pi
	local center = Vector3.new(
		math.cos(angle) * Config.SPAWN_RING_RADIUS,
		Config.BASE_SPAWN_HEIGHT,
		math.sin(angle) * Config.SPAWN_RING_RADIUS
	)

	local plate = BaseVisualsManager:CreateBase(
		plr.UserId,
		center,
		plr.Name,
		Config.BASE_SIZE
	)

	plate.Parent = getBasesFolder()
	BasePartByUser[plr.UserId] = plate
	plr:SetAttribute("BaseSlot", slot)

	-- 🎰 Spawnear máquina expendedora de powerups
	local vendingMachine = ProceduralModels:CreateModel("PowerUpVendingMachine")
	if vendingMachine then
		-- Posicionar cerca del spawn (10 studs al frente)
		local machinePos = center + Vector3.new(0, 4, -10)
		vendingMachine:SetPrimaryPartCFrame(CFrame.new(machinePos))
		vendingMachine:SetAttribute("OwnerUserId", plr.UserId)
		vendingMachine.Name = "VendingMachine_" .. plr.Name
		vendingMachine.Parent = getBasesFolder()

		if DEBUG then
			print(("[POWERUP] 🎰 Máquina expendedora spawneada para %s"):format(plr.Name))
		end
	end

	if DEBUG then
		print(("[BASE] Asignada base slot %d a %s"):format(slot, plr.Name))
	end
end 


local function teleportToBase(plr: Player, char: Model)
	task.defer(function()
		local root = char:WaitForChild("HumanoidRootPart", 5)
		local plate = BasePartByUser[plr.UserId]

		if root and plate then
			root.CFrame = plate.CFrame + Vector3.new(0, 5, 0)
		end

		Base.HealOnRespawn(plr.UserId)
		BaseStateChanged:FireClient(plr, {
			UserId = plr.UserId,
			BaseHP = Base.GetHP(plr.UserId),
			MaxHP = Config.BASE_MAX_HP,
		})
	end)--
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE CATEGORÍAS Y PLACEMENT
--═══════════════════════════════════════════════════════════════════════
local CategoryColors = {
	Income = {
		Button = Color3.fromRGB(100, 255, 100),
		Label = Color3.fromRGB(40, 80, 40),
	},
	Defense = {
		Button = Color3.fromRGB(100, 150, 255),
		Label = Color3.fromRGB(40, 60, 80),
	},
	Utility = {
		Button = Color3.fromRGB(200, 100, 255),
		Label = Color3.fromRGB(80, 40, 80),
	},
}

local function getOrInitCategoryIndex(userId: number, category: string): number
	if not BuildIndexByCategory[userId] then
		BuildIndexByCategory[userId] = {
			Income = 1,
			Defense = 1,
			Utility = 1,
		}
	end
	if not BuildIndexByCategory[userId][category] then
		BuildIndexByCategory[userId][category] = 1
	end
	return BuildIndexByCategory[userId][category]
end

local function incrementCategoryIndex(userId: number, category: string)
	if not BuildIndexByCategory[userId] then
		BuildIndexByCategory[userId] = {}
	end
	local current = getOrInitCategoryIndex(userId, category)
	BuildIndexByCategory[userId][category] = current + 1
end

local function getWallPlacementCFrame(basePart: BasePart, wallIndex: number): CFrame
	local baseSize = Config.BASE_SIZE
	local halfWidth = baseSize.X / 2
	local halfDepth = baseSize.Z / 2
	local wallWidth = 8
	local wallsPerSide = 4
	local totalWalls = wallsPerSide * 4

	local normalizedIndex = ((wallIndex - 1) % totalWalls) + 1
	local side = math.floor((normalizedIndex - 1) / wallsPerSide)
	local positionInSide = ((normalizedIndex - 1) % wallsPerSide)

	local offset = Vector3.zero
	local rotation = 0

	if side == 0 then
		offset = Vector3.new((positionInSide - 1.5) * wallWidth, 3, halfDepth + 0.5)
		rotation = 0
	elseif side == 1 then
		offset = Vector3.new(halfWidth + 0.5, 3, (positionInSide - 1.5) * wallWidth)
		rotation = 90
	elseif side == 2 then
		offset = Vector3.new((1.5 - positionInSide) * wallWidth, 3, -(halfDepth + 0.5))
		rotation = 180
	else
		offset = Vector3.new(-(halfWidth + 0.5), 3, (1.5 - positionInSide) * wallWidth)
		rotation = 270
	end

	return basePart.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(rotation), 0)
end

local function getNextBuildCFrame(basePart: BasePart, index: number, category: string?): CFrame?
	local cat = category or "Income"
	local MAX_PER_CATEGORY = 12

	if index > MAX_PER_CATEGORY then
		warn(("[PLACEMENT] Límite alcanzado para categoría %s"):format(cat))
		return nil
	end

	local categoryOffsets = {
		Income = Vector3.new(-30, 0, 10),
		Defense = Vector3.new(30, 0, 10),
		Utility = Vector3.new(0, 0, 35),
	}

	local baseOffset = categoryOffsets[cat] or Vector3.new(0, 0, 0)
	local cols = 4
	local cellSize = 12
	local i = index - 1
	local row = math.floor(i / cols)
	local col = i % cols

	local gridOffset = Vector3.new(
		(col - (cols-1)/2) * cellSize,
		3,
		row * cellSize
	)

	return basePart.CFrame * CFrame.new(baseOffset + gridOffset)
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE MODELOS
--═══════════════════════════════════════════════════════════════════════
local ModelsFolder = ServerStorage:FindFirstChild("Models")
if not ModelsFolder then
	ModelsFolder = Instance.new("Folder")
	ModelsFolder.Name = "Models"
	ModelsFolder.Parent = ServerStorage
end

local function ensureModel(name: string, color: Color3)
	if ModelsFolder:FindFirstChild(name) then return end

	local m = Instance.new("Model")
	m.Name = name

	local p = Instance.new("Part")
	p.Name = "Primary"
	p.Size = Vector3.new(6, 6, 6)
	p.Anchored = true
	p.Material = Enum.Material.Metal
	p.Color = color
	p.Parent = m

	m.PrimaryPart = p
	m.Parent = ModelsFolder

	if DEBUG then
		print(("[MODELS] Creado modelo placeholder: %s"):format(name))
	end
end

-- Crear modelos base
ensureModel("GeneratorMk1", Color3.fromRGB(180, 180, 180))
ensureModel("MinerDrill", Color3.fromRGB(120, 180, 255))
ensureModel("WaterPump", Color3.fromRGB(120, 255, 180))
ensureModel("ShieldEmitter", Color3.fromRGB(255, 140, 180))
ensureModel("WallSection", Color3.fromRGB(100, 100, 100))
ensureModel("ReinforcedWalls", Color3.fromRGB(80, 80, 80))

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE COMPRA/VENTA
--═══════════════════════════════════════════════════════════════════════
local function createUpgradeButton(upgId: string, def: any, userId: number, basePart: BasePart): Model?
	local category = def.Category or "Income"
	local colors = CategoryColors[category] or CategoryColors.Income

	local button = Instance.new("Model")
	button.Name = "Button_" .. upgId

	-- Base del botón
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(8, 1.5, 8)
	base.Anchored = true
	base.Material = Enum.Material.Neon
	base.Color = colors.Button
	base.Parent = button

	-- Borde
	local border = Instance.new("Part")
	border.Name = "Border"
	border.Size = Vector3.new(8.4, 0.2, 8.4)
	border.Anchored = true
	border.Material = Enum.Material.Metal
	border.Color = Color3.fromRGB(200, 200, 200)
	border.CFrame = base.CFrame * CFrame.new(0, -0.85, 0)
	border.Parent = button

	-- Label
	local label = Instance.new("Part")
	label.Name = "Label"
	label.Size = Vector3.new(8, 5, 0.5)
	label.Anchored = true
	label.Material = Enum.Material.SmoothPlastic
	label.Color = colors.Label
	label.CFrame = base.CFrame * CFrame.new(0, 3.25, -4.25)
	label.Parent = button

	-- SurfaceGui
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.Parent = label

	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.fromScale(1, 0.4)
	titleText.Position = UDim2.fromScale(0, 0.1)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Color3.new(1, 1, 1)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextScaled = true
	titleText.Text = def.Title or upgId
	titleText.Parent = surface

	local descText = Instance.new("TextLabel")
	descText.Size = UDim2.fromScale(1, 0.3)
	descText.Position = UDim2.fromScale(0, 0.5)
	descText.BackgroundTransparency = 1
	descText.TextColor3 = Color3.fromRGB(200, 200, 200)
	descText.Font = Enum.Font.Gotham
	descText.TextScaled = true
	descText.Text = def.Description or ""
	descText.Parent = surface

	local categoryTag = Instance.new("TextLabel")
	categoryTag.Size = UDim2.fromScale(0.5, 0.15)
	categoryTag.Position = UDim2.fromScale(0.25, 0.85)
	categoryTag.BackgroundTransparency = 0.5
	categoryTag.BackgroundColor3 = colors.Button
	categoryTag.TextColor3 = Color3.new(1, 1, 1)
	categoryTag.Font = Enum.Font.GothamBold
	categoryTag.TextScaled = true
	categoryTag.Text = category:upper()
	categoryTag.Parent = surface

	local tagCorner = Instance.new("UICorner")
	tagCorner.CornerRadius = UDim.new(0.5, 0)
	tagCorner.Parent = categoryTag

	button.PrimaryPart = base
	button:SetAttribute("UpgradeButton", true)
	button:SetAttribute("UpgradeId", upgId)
	button:SetAttribute("OwnerUserId", userId)
	button:SetAttribute("Category", category)

	-- Posicionar
	local catIndex = getOrInitCategoryIndex(userId, category)
	local cf = getNextBuildCFrame(basePart, catIndex, category)

	if not cf then
		button:Destroy()
		return nil
	end

	button:PivotTo(cf)
	button.Parent = getBasesFolder()
	incrementCategoryIndex(userId, category)

	return button
end

RequestPurchase.OnServerEvent:Connect(function(plr: Player, upgradeId: string)
	if typeof(upgradeId) ~= "string" then return end

	-- Rate limiting
	if not checkRateLimit(plr.UserId, "Purchase") then
		notifyPlayer(plr, "⚠️ Slow down!", 2)
		return
	end

	-- Validar upgrade existe
	local def = UpgDefs[upgradeId]
	if not def then
		warn(("[PURCHASE] Upgrade inválido: %s"):format(upgradeId))
		return
	end

	-- Intentar compra
	local ok, reason = Economy.Purchase(plr.UserId, upgradeId)
	if not ok then
		if reason == "NOT_ENOUGH_CASH" then
			notifyPlayer(plr, "❌ Not enough cash!", 2)
		elseif reason == "REACH_CAP" then
			notifyPlayer(plr, "⚠️ Max upgrades reached!", 2)
		end
		return
	end

	-- ✅ Actualizar Guardian para permitir compra legítima
	local s = Economy.GetState(plr.UserId)
	if s then
		-- Actualizar target del Guardian PRIMERO
		Base.UpdateGuardianTarget(plr.UserId, s.Cash)

		-- Actualizar leaderstats inmediatamente para evitar race condition
		local ls = plr:FindFirstChild("leaderstats")
		if ls then
			local cash = ls:FindFirstChild("Cash") :: IntValue?
			if cash then
				cash.Value = s.Cash
			end
		end

		if Config.DEBUG_MODE then
			print(("[PURCHASE] ✅ Guardian actualizado: nuevo target = $%d"):format(s.Cash))
		end
	end

	-- Log analytics
	logAnalytic("Purchase", {
		userId = plr.UserId,
		upgradeId = upgradeId,
		price = Economy.GetCurrentPrice(plr.UserId, upgradeId),
	})

	ServerState.TotalPurchases += 1

	local s = Economy.GetState(plr.UserId)
	if not s then return end

	local count = s.OwnedUpgrades[upgradeId] or 0
	local basePart = BasePartByUser[plr.UserId]
	if not basePart then return end

	local category = def.Category or "Income"

	-- Primera compra: crear botón
	if count == 1 and def.ModelName then
		local buttonName = "Button_" .. upgradeId
		local existing = getBasesFolder():FindFirstChild(buttonName)

		if not existing then
			createUpgradeButton(upgradeId, def, plr.UserId, basePart)
		end
	end

	-- Colocar modelo
	if count >= 1 and def.ModelName then
		local tpl = ModelsFolder:FindFirstChild(def.ModelName)
		if not (tpl and tpl:IsA("Model") and tpl.PrimaryPart) then
			-- Crear placeholder
			local m = Instance.new("Model")
			m.Name = def.ModelName .. "_Placeholder"
			local p = Instance.new("Part")
			p.Name = "Primary"
			p.Size = Vector3.new(6, 6, 6)
			p.Anchored = true
			p.Material = Enum.Material.Metal
			p.Color = Color3.fromRGB(255, 180, 0)
			p.Parent = m
			m.PrimaryPart = p
			tpl = m
		end

		local cf
		if upgradeId == "Upgrade_7" then
			cf = getWallPlacementCFrame(basePart, count)
		else
			local catIndex = getOrInitCategoryIndex(plr.UserId, category)
			cf = getNextBuildCFrame(basePart, catIndex, category)

			if cf then
				incrementCategoryIndex(plr.UserId, category)
			end
		end

		if cf then
			local clone = tpl:Clone()
			tagOwned(clone, plr.UserId)
			BuildEffectsManager:PlayBuildEffect(clone, 0.8)
			clone:PivotTo(cf)
			clone.Parent = getBasesFolder()
		end
	end

	-- Efectos especiales
	if upgradeId == "Upgrade_6" then
		plr:SetAttribute("ShieldLevel", (plr:GetAttribute("ShieldLevel") or 0) + 1)
	end

	if upgradeId == "Upgrade_7" then
		Config.BASE_MAX_HP += 5
		Base.SetMaxHP(plr.UserId, Config.BASE_MAX_HP)
		Base.AddHP(plr.UserId, 5)
		if DEBUG then
			print(("[PURCHASE] Max HP aumentado a " .. Config.BASE_MAX_HP))
		end
	
	
	--[[local baseVisuals = ServerStorage.Managers:FindFirstChild("BaseVisualsManager")
	if baseVisuals then
		local BaseVisualsManager = require(baseVisuals)
		BaseVisualsManager.UpdateBaseVisuals(
			plr.UserId,
			Base.GetHP(plr.UserId),
			Config.BASE_MAX_HP  -- ← MaxHP nuevo
		)
	end

	if DEBUG then
		print(("[PURCHASE] Max HP aumentado a %d"):format(Config.BASE_MAX_HP))
	end]]--
end

	-- Sync leaderstats
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		local cash = ls:FindFirstChild("Cash") :: IntValue?
		local ips = ls:FindFirstChild("IncomePerSec") :: IntValue?
		if cash then cash.Value = s.Cash end
		if ips then ips.Value = s.IncomePerSec end
	end

	-- Achievement: Primera compra
	if ServerState.TotalPurchases == 1 and Achievements then
		Achievements.Award(plr.UserId, "FirstPurchase")
	end

	notifyPlayer(plr, string.format("✓ Purchased %s!", def.Title or upgradeId), 2)
end)

-- Sistema de venta
RequestSell.OnServerEvent:Connect(function(plr: Player, upgradeId: string)
	if typeof(upgradeId) ~= "string" then return end

	local s = Economy.GetState(plr.UserId)
	if not s or not s.OwnedUpgrades[upgradeId] or s.OwnedUpgrades[upgradeId] <= 0 then
		notifyPlayer(plr, "❌ Nothing to sell!", 2)
		return
	end

	local price = Economy.GetCurrentPrice(plr.UserId, upgradeId)
	local refund = math.floor(price * 0.5)

	s.OwnedUpgrades[upgradeId] -= 1
	s.Cash += refund

	-- Recalcular income
	s.IncomePerSec = 0
	for id, count in pairs(s.OwnedUpgrades) do
		local def = UpgDefs[id]
		if def and def.IncomePerSec then
			s.IncomePerSec += (def.IncomePerSec * count)
		end
	end

	-- Sync leaderstats
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		local cash = ls:FindFirstChild("Cash") :: IntValue?
		local ips = ls:FindFirstChild("IncomePerSec") :: IntValue?
		if cash then cash.Value = s.Cash end
		if ips then ips.Value = s.IncomePerSec end
	end

	notifyPlayer(plr, string.format("✓ Sold! +$%d", refund), 2)
end)

--═══════════════════════════════════════════════════════════════════════
-- 🎰 SISTEMA DE COMPRA DE POWERUPS DESDE MÁQUINA
--═══════════════════════════════════════════════════════════════════════
if PurchasePowerUp then
	PurchasePowerUp.OnServerEvent:Connect(function(plr: Player)
		-- Rate limiting
		if not checkRateLimit(plr.UserId, "Purchase") then
			notifyPlayer(plr, "⚠️ Slow down!", 2)
			return
		end

		-- Intentar compra desde la máquina
		local success, errorMsg = PowerUpModule.PurchaseFromVendingMachine(plr.UserId)

		if success then
			notifyPlayer(plr, "🎰 PowerUp Activated!", 2)

			if Config.DEBUG_MODE then
				print(("[POWERUP] ✅ %s compró powerup desde máquina"):format(plr.Name))
			end
		else
			-- Mostrar mensaje de error
			notifyPlayer(plr, "❌ " .. (errorMsg or "Can't purchase"), 2)

			if Config.DEBUG_MODE then
				print(("[POWERUP] ❌ %s intentó comprar pero falló: %s"):format(plr.Name, errorMsg or "unknown"))
			end
		end
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE REPARACIÓN
--═══════════════════════════════════════════════════════════════════════
RequestRepair.OnServerEvent:Connect(function(plr: Player, amount: number)
	amount = tonumber(amount) or 10
	if amount <= 0 or amount > Config.MAX_REPAIR_PER_REQUEST then return end

	-- Rate limiting
	if not checkRateLimit(plr.UserId, "Repair") then
		notifyPlayer(plr, "⚠️ Repairing too fast!", 2)
		return
	end

	local cur = Base.GetHP(plr.UserId)
	local max = Config.BASE_MAX_HP
	local missing = math.max(0, max - cur)

	if missing <= 0 then
		notifyPlayer(plr, "✓ Already at full HP!", 2)
		return
	end

	local will = math.min(missing, amount)
	local s = Economy.GetState(plr.UserId)
	if not s then return end

	-- Calcular costo con escala
	local baseCost = Config.REPAIR_COST_PER_HP
	local incomeScale = 1 + ((s.IncomePerSec or 0) / 10)
	local hpScale = max / 100
	local cost = will * math.floor(baseCost * incomeScale * hpScale)

	-- Gamepass: Instant repair
	if hasGamepass(plr.UserId, GAMEPASS_INSTANT_REPAIR) then
		cost = math.floor(cost * 0.5) -- 50% de descuento
	end

	if s.Cash < cost then
		notifyPlayer(plr, string.format("❌ Need $%d to repair!", cost), 2)
		return
	end

	s.Cash -= cost
	Base.AddHP(plr.UserId, will)

	-- Sync
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		local c = ls:FindFirstChild("Cash") :: IntValue?
		if c then c.Value = s.Cash end
	end

	BaseStateChanged:FireClient(plr, {
		UserId = plr.UserId,
		BaseHP = Base.GetHP(plr.UserId),
		MaxHP = max,
	})

	-- ✅ Mostrar popup visual de gasto (-$XXX)
	if CashTick then
		CashTick:FireClient(plr, -cost)  -- Enviar valor negativo
	end

	notifyPlayer(plr, string.format("✓ Repaired +%d HP! -$%d", will, cost), 2)
end)

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE PRESTIGE
--═══════════════════════════════════════════════════════════════════════
RequestPrestige.OnServerEvent:Connect(function(plr: Player)
	if not Config.PRESTIGE.Enabled then
		notifyPlayer(plr, "⚠️ Prestige not available yet!", 3)
		return
	end

	local s = Economy.GetState(plr.UserId)
	if not s then return end

	-- Verificar requisitos
	if s.Cash < Config.PRESTIGE.RequiredCash then
		notifyPlayer(plr, string.format("❌ Need $%d to prestige!", Config.PRESTIGE.RequiredCash), 3)
		return
	end

	if s.PrestigeLevel >= Config.PRESTIGE.MaxPrestige then
		notifyPlayer(plr, "⚠️ Max prestige reached!", 3)
		return
	end

	-- Confirmar (esto debería hacerse con un diálogo en cliente)
	-- Por ahora lo hacemos directo

	-- Reset progreso
	s.Cash = Config.START_CASH
	s.OwnedUpgrades = {}
	s.PrestigeLevel += 1
	s.IncomePerSec = 0

	-- Limpiar modelos y botones
	local basesFolder = getBasesFolder()
	for _, obj in ipairs(basesFolder:GetChildren()) do
		if obj:GetAttribute("OwnerUserId") == plr.UserId and obj:GetAttribute("UpgradeButton") then
			obj:Destroy()
		end
	end

	-- Reset índices
	BuildIndexByCategory[plr.UserId] = {
		Income = 1,
		Defense = 1,
		Utility = 1,
	}

	-- Sync
	local ls = plr:FindFirstChild("leaderstats")
	if ls then
		local cash = ls:FindFirstChild("Cash") :: IntValue?
		local ips = ls:FindFirstChild("IncomePerSec") :: IntValue?
		if cash then cash.Value = s.Cash end
		if ips then ips.Value = s.IncomePerSec end
	end

	local stats = plr:FindFirstChild("Stats")
	if stats then
		local prestige = stats:FindFirstChild("PrestigeLevel") :: IntValue?
		if prestige then prestige.Value = s.PrestigeLevel end
	end

	Base.SetHP(plr.UserId, Config.BASE_MAX_HP)

	notifyPlayer(plr, string.format("✨ PRESTIGE %d! +%.0f%% bonus income!", s.PrestigeLevel, Config.PRESTIGE.BonusPerPrestige * 100), 5)

	logAnalytic("Prestige", {
		userId = plr.UserId,
		level = s.PrestigeLevel,
	})
end)

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE DAILY REWARDS
--═══════════════════════════════════════════════════════════════════════
local DAILY_REWARDS = {
	{cash = 500, title = "Day 1 Bonus"},
	{cash = 1000, title = "Day 2 Bonus"},
	{cash = 2000, title = "Day 3 Bonus"},
	{cash = 5000, title = "Day 4 Bonus"},
	{cash = 10000, title = "Day 5 Bonus"},
	{cash = 25000, title = "Day 6 Bonus"},
	{cash = 50000, title = "Day 7 Bonus - JACKPOT!"},
}

RequestDailyReward.OnServerEvent:Connect(function(plr: Player)
	local userId = plr.UserId
	local now = os.time()
	local last = LastDailyReward[userId] or 0
	local daysPassed = math.floor((now - last) / 86400)

	if daysPassed < 1 then
		local hoursLeft = math.ceil((86400 - (now - last)) / 3600)
		notifyPlayer(plr, string.format("⏰ Come back in %d hours!", hoursLeft), 3)
		return
	end

	-- Determinar día actual (reset si pasó más de 1 día)
	local currentDay = (DailyRewards[userId] or 0) + 1
	if daysPassed > 1 then
		currentDay = 1 -- Reset streak
	end

	if currentDay > #DAILY_REWARDS then
		currentDay = 1 -- Loop
	end

	local reward = DAILY_REWARDS[currentDay]
	local s = Economy.GetState(userId)
	if s then
		s.Cash += reward.cash

		local ls = plr:FindFirstChild("leaderstats")
		if ls then
			local cash = ls:FindFirstChild("Cash") :: IntValue?
			if cash then cash.Value = s.Cash end
		end
	end

	LastDailyReward[userId] = now
	DailyRewards[userId] = currentDay

	notifyPlayer(plr, string.format("🎁 %s: +$%d!", reward.title, reward.cash), 5)

	logAnalytic("DailyReward", {
		userId = userId,
		day = currentDay,
		reward = reward.cash,
	})
end)

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE ESTADO Y LEADERBOARDS
--═══════════════════════════════════════════════════════════════════════
RequestState.OnServerInvoke = function(plr: Player)
	local s = Economy.GetState(plr.UserId)
	if not s then return nil end

	local info = {}
	for id, def in pairs(UpgDefs) do
		info[id] = {
			Title = def.Title or id,
			Description = def.Description or "",
			Price = Economy.GetCurrentPrice(plr.UserId, id),
			Count = s.OwnedUpgrades[id] or 0,
			MaxCount = def.MaxCount,
			IncomePerSec = def.IncomePerSec or 0,
			Category = def.Category or "Income",
		}
	end

	return {
		Cash = s.Cash,
		IncomePerSec = s.IncomePerSec,
		UpgradesInfo = info,
		BaseHP = Base.GetHP(plr.UserId),
		BaseMaxHP = Config.BASE_MAX_HP,
		ShieldLevel = plr:GetAttribute("ShieldLevel") or 0,
		PrestigeLevel = s.PrestigeLevel or 0,
		TotalEarned = s.TotalEarned or 0,
		TotalSpent = s.TotalSpent or 0,
		MeteorsSurvived = Base.GetMeteorsSurvived(plr.UserId),
	}
end

RequestBaseState.OnServerInvoke = function(plr: Player)
	return {
		UserId = plr.UserId,
		BaseHP = Base.GetHP(plr.UserId),
		MaxHP = Config.BASE_MAX_HP,
		IsInvulnerable = Base.IsInvulnerable(plr.UserId),
	}
end

RequestLeaderboard.OnServerInvoke = function(plr: Player, leaderboardType: string?)
	-- Aquí puedes implementar diferentes tipos de leaderboards
	-- Por ahora retornamos top players por cash

	local leaders = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local s = Economy.GetState(p.UserId)
		if s then
			table.insert(leaders, {
				Name = p.Name,
				UserId = p.UserId,
				Cash = s.Cash,
				IncomePerSec = s.IncomePerSec,
				PrestigeLevel = s.PrestigeLevel or 0,
			})
		end
	end

	-- Ordenar por cash
	table.sort(leaders, function(a, b)
		return a.Cash > b.Cash
	end)

	-- Retornar top 10
	local top10 = {}
	for i = 1, math.min(10, #leaders) do
		table.insert(top10, leaders[i])
	end

	return top10
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE COMANDOS (ADMIN Y DEBUG)
--═══════════════════════════════════════════════════════════════════════
local Commands = {
	-- Admin commands
	givecash = function(plr: Player, args: {string})
		if not isAdmin(plr.UserId) then return end

		local targetName = args[1]
		local amount = tonumber(args[2]) or 1000

		local target = Players:FindFirstChild(targetName)
		if not target then
			notifyPlayer(plr, "❌ Player not found!", 2)
			return
		end

		local s = Economy.GetState(target.UserId)
		if s then
			s.Cash += amount

			local ls = target:FindFirstChild("leaderstats")
			if ls then
				local cash = ls:FindFirstChild("Cash") :: IntValue?
				if cash then cash.Value = s.Cash end
			end

			notifyPlayer(plr, string.format("✓ Gave $%d to %s", amount, target.Name), 3)
			notifyPlayer(target, string.format("💰 Admin gave you $%d!", amount), 3)
		end
	end,

	setwave = function(plr: Player, args: {string})
		if not isAdmin(plr.UserId) then return end

		local wave = tonumber(args[1]) or 1
		ServerState.CurrentWave = wave
		CurrentWaveValue.Value = wave

		notifyPlayer(plr, string.format("✓ Wave set to %d", wave), 2)
	end,

	heal = function(plr: Player, args: {string})
		if not isAdmin(plr.UserId) then return end

		local targetName = args[1] or plr.Name
		local target = Players:FindFirstChild(targetName)

		if not target then
			notifyPlayer(plr, "❌ Player not found!", 2)
			return
		end

		Base.SetHP(target.UserId, Config.BASE_MAX_HP)
		BaseStateChanged:FireClient(target, {
			UserId = target.UserId,
			BaseHP = Config.BASE_MAX_HP,
			MaxHP = Config.BASE_MAX_HP,
		})

		notifyPlayer(plr, string.format("✓ Healed %s", target.Name), 2)
	end,

	wipe = function(plr: Player, args: {string})
		if not isAdmin(plr.UserId) then return end

		local targetName = args[1]
		local target = Players:FindFirstChild(targetName)

		if not target then
			notifyPlayer(plr, "❌ Player not found!", 2)
			return
		end

		DataStore:WipePlayer(target.UserId)
		notifyPlayer(plr, string.format("✓ Wiped data for %s", target.Name), 3)
	end,

	-- Debug commands
	meteors = function(plr: Player, args: {string})
		if not DEBUG then return end

		local count = tonumber(args[1]) or 5
		Config.METEOR_COUNT = count

		Events:MeteorStorm()
		notifyPlayer(plr, string.format("☄️ Spawning %d meteors!", count), 3)
	end,

	stats = function(plr: Player, args: {string})
		local uptime = os.time() - ServerState.StartTime
		local hours = math.floor(uptime / 3600)
		local minutes = math.floor((uptime % 3600) / 60)

		notifyPlayer(plr, string.format(
			"📊 Server Stats:\nUptime: %dh %dm\nPlayers: %d\nWave: %d\nPurchases: %d",
			hours, minutes,
			#Players:GetPlayers(),
			ServerState.CurrentWave,
			ServerState.TotalPurchases
			), 5)
	end,
}

AdminCommand.OnServerEvent:Connect(function(plr: Player, commandString: string)
	if not checkRateLimit(plr.UserId, "Command") then
		notifyPlayer(plr, "⚠️ Too many commands!", 2)
		return
	end

	local parts = string.split(commandString, " ")
	local cmdName = parts[1]:lower()
	local args = {}

	for i = 2, #parts do
		table.insert(args, parts[i])
	end

	local cmd = Commands[cmdName]
	if cmd then
		local success, err = pcall(function()
			cmd(plr, args)
		end)

		if not success then
			warn(("[CMD] Error ejecutando comando %s: %s"):format(cmdName, tostring(err)))
			notifyPlayer(plr, "❌ Command error!", 2)
		end
	else
		notifyPlayer(plr, "❌ Unknown command!", 2)
	end
end)

--═══════════════════════════════════════════════════════════════════════
-- 🏃 DASH SYSTEM - Handle Dash Requests
--═══════════════════════════════════════════════════════════════════════

-- Crear RemoteEvent si no existe
local DashRequest = Remotes:FindFirstChild("DashRequest") :: RemoteEvent?
if not DashRequest then
	DashRequest = Instance.new("RemoteEvent")
	DashRequest.Name = "DashRequest"
	DashRequest.Parent = Remotes
	warn("[Main.Server] RemoteEvent 'DashRequest' creado automáticamente")
end

-- ✅ NUEVO: RemoteEvent para feedback de evasión
local DashEvaded = Remotes:FindFirstChild("DashEvaded") :: RemoteEvent?
if not DashEvaded then
	DashEvaded = Instance.new("RemoteEvent")
	DashEvaded.Name = "DashEvaded"
	DashEvaded.Parent = Remotes
	warn("[Main.Server] RemoteEvent 'DashEvaded' creado automáticamente")
end

-- Cooldowns por jugador (prevenir spam)
local DashCooldowns: {[number]: number} = {}
local DASH_COOLDOWN = 2.5 -- ✅ Reducido de 4s para acción más rápida
local DASH_DURATION = 0.3 -- duración de invulnerabilidad
local DASH_DISTANCE = 20 -- studs de teletransporte

DashRequest.OnServerEvent:Connect(function(plr: Player, direction: Vector3?)
	local userId = plr.UserId
	local now = tick()

	-- ✅ POWERUP: Verificar si SuperDash está activo (sin cooldown)
	local hasSuperDash = PowerUpModule.IsSuperDashActive and PowerUpModule.IsSuperDashActive(userId)

	-- Verificar cooldown (ignorar si tiene SuperDash)
	if not hasSuperDash and DashCooldowns[userId] and now - DashCooldowns[userId] < DASH_COOLDOWN then
		if Config.DEBUG_MODE then
			local remaining = math.ceil(DASH_COOLDOWN - (now - DashCooldowns[userId]))
			warn(("[DASH] %s en cooldown (%ds restantes)"):format(plr.Name, remaining))
		end
		return
	end

	-- Obtener character
	local character = plr.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?

	if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
		return
	end

	-- Validar dirección (anti-exploit)
	if not direction or typeof(direction) ~= "Vector3" then
		direction = humanoidRootPart.CFrame.LookVector
	end

	-- Normalizar y proyectar en plano horizontal
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	-- Actualizar cooldown
	DashCooldowns[userId] = now

	-- ✅ TELETRANSPORTE INSTANTÁNEO (20 studs)
	local originPos = humanoidRootPart.Position
	local targetPos = originPos + (direction * DASH_DISTANCE)

	-- Raycast para evitar teletransporte a través de paredes
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = workspace:Raycast(originPos, direction * DASH_DISTANCE, rayParams)

	if rayResult then
		-- Si hay obstáculo, teleportar hasta justo antes del obstáculo
		targetPos = rayResult.Position - (direction * 1) -- 1 stud antes del muro
	end

	-- Mantener Y original (no teleportar verticalmente)
	targetPos = Vector3.new(targetPos.X, originPos.Y, targetPos.Z)

	-- Resetear velocidad antes de teleportar (evita inercia)
	if humanoidRootPart:FindFirstChild("AssemblyLinearVelocity") then
		humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	end
	humanoidRootPart.Velocity = Vector3.zero

	-- Ejecutar teletransporte
	humanoidRootPart.CFrame = CFrame.new(targetPos, targetPos + direction)

	if Config.DEBUG_MODE then
		print(("[DASH] 🚀 %s teleportado de %s a %s (distancia: %.1f studs)"):format(
			plr.Name,
			tostring(Vector3.new(math.floor(originPos.X), math.floor(originPos.Y), math.floor(originPos.Z))),
			tostring(Vector3.new(math.floor(targetPos.X), math.floor(targetPos.Y), math.floor(targetPos.Z))),
			(targetPos - originPos).Magnitude
		))
	end

	-- ✅ Efectos de partículas en origen
	local originEffect = Instance.new("Part")
	originEffect.Size = Vector3.new(4, 0.5, 4)
	originEffect.Position = originPos
	originEffect.Anchored = true
	originEffect.CanCollide = false
	originEffect.Transparency = 1
	originEffect.Parent = workspace

	local originParticles = Instance.new("ParticleEmitter")
	originParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	originParticles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	originParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	originParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	originParticles.Lifetime = NumberRange.new(0.5, 0.8)
	originParticles.Rate = 100
	originParticles.Speed = NumberRange.new(5, 10)
	originParticles.SpreadAngle = Vector2.new(180, 180)
	originParticles.LightEmission = 1
	originParticles.Parent = originEffect
	originParticles.Enabled = true

	task.delay(0.1, function()
		originParticles.Enabled = false
	end)
	game.Debris:AddItem(originEffect, 2)

	-- ✅ Efectos de partículas en destino
	local destEffect = Instance.new("Part")
	destEffect.Size = Vector3.new(4, 0.5, 4)
	destEffect.Position = targetPos
	destEffect.Anchored = true
	destEffect.CanCollide = false
	destEffect.Transparency = 1
	destEffect.Parent = workspace

	local destParticles = Instance.new("ParticleEmitter")
	destParticles.Texture = "rbxasset://textures/particles/smoke_main.dds"
	destParticles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 200))
	destParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	destParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	destParticles.Lifetime = NumberRange.new(0.5, 0.8)
	destParticles.Rate = 100
	destParticles.Speed = NumberRange.new(5, 10)
	destParticles.SpreadAngle = Vector2.new(180, 180)
	destParticles.LightEmission = 1
	destParticles.Parent = destEffect
	destParticles.Enabled = true

	task.delay(0.1, function()
		destParticles.Enabled = false
	end)
	game.Debris:AddItem(destEffect, 2)

	-- Aplicar invulnerabilidad temporal
	if Base and Base.SetInvulnerable then
		Base.SetInvulnerable(userId, true, DASH_DURATION)

		if Config.DEBUG_MODE then
			print(("[DASH] ✅ %s teleported %.1f studs! Invulnerable por %.1fs"):format(plr.Name, DASH_DISTANCE, DASH_DURATION))
		end

		-- Notificación opcional
		if ShowNotif then
			ShowNotif:FireClient(plr, "💨 DASH!", 0.5)
		end
	else
		warn("[DASH] ⚠️ BaseModule no disponible - no se aplicó invulnerabilidad")
	end
end)

-- Limpieza al salir
Players.PlayerRemoving:Connect(function(plr)
	DashCooldowns[plr.UserId] = nil
end)

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE ECONOMÍA (LOOP PRINCIPAL)
--═══════════════════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(Config.TICK_SECS)

		Economy.TickAll()

		for _, plr in ipairs(Players:GetPlayers()) do
			local s = Economy.GetState(plr.UserId)
			if s then
				-- Aplicar bonus de prestige
				local prestigeBonus = 1 + (s.PrestigeLevel * Config.PRESTIGE.BonusPerPrestige)

				-- Aplicar bonus de gamepass
				if hasGamepass(plr.UserId, GAMEPASS_DOUBLE_INCOME) then
					prestigeBonus *= 2
				end

				local actualIncome = math.floor(s.IncomePerSec * prestigeBonus)

				-- Sync leaderstats
				local ls = plr:FindFirstChild("leaderstats")
				if ls then
					local ips = ls:FindFirstChild("IncomePerSec") :: IntValue?
					local cash = ls:FindFirstChild("Cash") :: IntValue?
					if ips then ips.Value = actualIncome end
					if cash then cash.Value = s.Cash end
				end

				-- Popup de income
				if actualIncome > 0 and Config.UI.ShowIncomePopups then
					CashTick:FireClient(plr, actualIncome)
				end
			end

			-- Update playtime
			local stats = plr:FindFirstChild("Stats")
			if stats then
				local playTime = stats:FindFirstChild("PlayTime") :: IntValue?
				if playTime then
					playTime.Value += Config.TICK_SECS
				end
			end
		end
	end
end)

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE AUTOSAVE
--═══════════════════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_SECS)

		for _, plr in ipairs(Players:GetPlayers()) do
			local blob = Economy.ToBlob(plr.UserId)
			if blob then
				blob.LastLogout = os.time()

				-- Guardar stats adicionales
				local stats = plr:FindFirstChild("Stats")
				if stats then
					blob.MeteorsSurvived = Base.GetMeteorsSurvived(plr.UserId)

					local playTime = stats:FindFirstChild("PlayTime") :: IntValue?
					if playTime then
						blob.PlayTime = playTime.Value
					end
				end

				local success = DataStore:SaveAsync(plr.UserId, blob)
				if not success and DEBUG then
					warn(("[AUTOSAVE] Fallo al guardar %s"):format(plr.Name))
				elseif DEBUG then
					print(("[AUTOSAVE] Guardado: %s ($%d)"):format(plr.Name, blob.Cash))
				end
			end
		end

		if DEBUG then
			print(("[AUTOSAVE] Ciclo completado - %d jugadores"):format(#Players:GetPlayers()))
		end
	end
end)

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE WAVES Y EVENTOS
--═══════════════════════════════════════════════════════════════════════
local eventsEnabled = Events and typeof(Events.MeteorStorm) == "function"

if eventsEnabled then
	task.spawn(function()
		-- Esperar 30 segundos antes del primer evento
		task.wait(30)

		while true do
			local waveConfig = Config.GetWaveDifficulty(ServerState.CurrentWave)

			-- Ajustar por número de jugadores
			local playerCount = #Players:GetPlayers()
			local difficulty = Config.GetDynamicDifficulty(playerCount)
			local adjustedInterval = waveConfig.Interval * difficulty

			task.wait(adjustedInterval)

			-- ✅ SINCRONIZAR AL INICIO (muestra la wave que VAS A JUGAR)
			if CurrentWaveValue then
				CurrentWaveValue.Value = ServerState.CurrentWave
			end

			-- ✅ RESETEAR FLAGS DE MUERTE AL INICIO DE CADA WAVE
			Base.ResetAllWaveDeathFlags()

			print(("═══════════════════════════════════════════════════════════"):rep(1))
			print(("[WAVE] Iniciando Wave %d"):format(ServerState.CurrentWave))
			print(("[WAVE] Meteoritos: %d | Daño: %d | Jugadores: %d"):format(
				waveConfig.Meteors, waveConfig.Damage, playerCount
				))
			print(("═══════════════════════════════════════════════════════════"):rep(1))

			-- Anuncio
			broadcastNotification(string.format("⚔️ WAVE %d INCOMING!", ServerState.CurrentWave), 5)

		-- 💀 BOSS METEOR SYSTEM
		local isBossWave = ServerState.CurrentWave % 10 == 0
		local isMiniBossWave = (ServerState.CurrentWave % 5 == 0) and not isBossWave

		if isBossWave then
			-- 💀 BOSS COMPLETO (Wave 10, 20, 30...)
			task.wait(3)
			Events:BossMeteor(ServerState.CurrentWave, true)

			-- 🎁 RECOMPENSAS BOSS COMPLETO
			for _, plr in ipairs(Players:GetPlayers()) do
				if not Base.DiedDuringCurrentWave(plr.UserId) then
					local maxHP = Base.GetMaxHP(plr.UserId)
					Base.SetHP(plr.UserId, maxHP)

					local cashBonus = 500 * (ServerState.CurrentWave / 10)
					local s = Economy.GetState(plr.UserId)
					if s then
						s.Cash += cashBonus
						local ls = plr:FindFirstChild("leaderstats")
						if ls then
							local cash = ls:FindFirstChild("Cash") :: IntValue?
							if cash then cash.Value = s.Cash end
						end
					end

					broadcastNotification(string.format("🏆 %s DEFEATED THE BOSS! +$%d!", plr.Name, cashBonus), 5)

					if ServerState.CurrentWave == 10 and Achievements then
						Achievements.Award(plr.UserId, "ColossusSlayer")
					end
				end
			end

		elseif isMiniBossWave then
			-- 💀 MINI-BOSS (Wave 5, 15, 25...)
			task.wait(3)
			Events:BossMeteor(ServerState.CurrentWave, false)

			-- 🎁 RECOMPENSAS MINI-BOSS
			for _, plr in ipairs(Players:GetPlayers()) do
				if not Base.DiedDuringCurrentWave(plr.UserId) then
					local maxHP = Base.GetMaxHP(plr.UserId)
					Base.SetHP(plr.UserId, maxHP)

					local cashBonus = 100 * ServerState.CurrentWave
					local s = Economy.GetState(plr.UserId)
					if s then
						s.Cash += cashBonus
						local ls = plr:FindFirstChild("leaderstats")
						if ls then
							local cash = ls:FindFirstChild("Cash") :: IntValue?
							if cash then cash.Value = s.Cash end
						end
					end

					broadcastNotification(string.format("✓ %s survived Mini-Boss! +$%d", plr.Name, cashBonus), 4)
				end
			end

		else
			-- ⚔️ WAVE NORMAL
			Config.METEOR_COUNT = waveConfig.Meteors
			Config.METEOR_DAMAGE = waveConfig.Damage

			task.wait(5)
			Events:MeteorStorm()

			local stormDuration = (waveConfig.Meteors / Config.EVENTS.MeteorStorm.SpawnRate) + 10
			task.wait(stormDuration)

			-- 💰 BONUS POR WAVE NORMAL
			for _, plr in ipairs(Players:GetPlayers()) do
				if not Base.DiedDuringCurrentWave(plr.UserId) then
					local waveBonus = 50 * ServerState.CurrentWave
					local s = Economy.GetState(plr.UserId)
					if s then
						s.Cash += waveBonus
						local ls = plr:FindFirstChild("leaderstats")
						if ls then
							local cash = ls:FindFirstChild("Cash") :: IntValue?
							if cash then cash.Value = s.Cash end
						end

						if ShowNotif then
							ShowNotif:FireClient(plr, string.format("✓ Wave %d! +$%d", ServerState.CurrentWave, waveBonus), 3)
						end
					end
				end
			end
		end

			-- ✅ ARREGLADO: Wave completada (delay reducido para feedback inmediato)
			task.wait(0.3) -- Esperar solo 0.3s para feedback instantáneo

			if Config.DEBUG_MODE then
				print(("[WAVE] ✅ Wave %d completada"):format(ServerState.CurrentWave))
			end

			-- ✅ Incrementar contador Y enviar resultado ÉPICO personalizado
			for _, plr in ipairs(Players:GetPlayers()) do
				local diedDuringWave = Base.DiedDuringCurrentWave(plr.UserId)

				if not diedDuringWave then
					-- ✅ Jugador SOBREVIVIÓ
					Base.IncrementMeteorsSurvived(plr.UserId)

					local stats = plr:FindFirstChild("Stats")
					if stats then
						local meteors = stats:FindFirstChild("MeteorsSurvived") :: IntValue?
						if meteors then
							meteors.Value = Base.GetMeteorsSurvived(plr.UserId)
						end
					end

					-- ✅ ENVIAR RESULTADO ÉPICO DE VICTORIA
					if WaveResult then
						local waveData = {
							result = "victory",
							waveNumber = ServerState.CurrentWave,
							newSurvived = Base.GetMeteorsSurvived(plr.UserId)
						}
						print(("[WAVE] 🎉 Enviando VICTORIA a %s - Wave %d"):format(plr.Name, ServerState.CurrentWave))
						WaveResult:FireClient(plr, waveData)
					else
						warn("[WAVE] ⚠️ WaveResult remote no existe!")
					end

					-- Achievement: 100 meteoros
					if Base.GetMeteorsSurvived(plr.UserId) == 100 and Achievements then
						Achievements.Award(plr.UserId, "Survivor100")
					end

					--[[
					🎰 SISTEMA DE POWERUPS AUTOMÁTICOS DESACTIVADO
					════════════════════════════════════════════════
					Los powerups ahora se obtienen comprando en la máquina expendedora.
					El código antiguo está comentado abajo por si se necesita restaurar:

					-- ✅ POWERUP: Spawnear powerup al completar wave (solo cada 3 waves normales, o boss/miniboss)
					local shouldSpawnPowerUp = false
					local waveType = "Normal"

					if ServerState.CurrentWave % 10 == 0 then
						waveType = "Boss"
						shouldSpawnPowerUp = true
					elseif ServerState.CurrentWave % 5 == 0 then
						waveType = "MiniBoss"
						shouldSpawnPowerUp = true
					elseif ServerState.CurrentWave % 3 == 0 then
						-- Solo cada 3 waves normales (3, 6, 9, 12, etc)
						waveType = "Normal"
						shouldSpawnPowerUp = true
					end

					-- Spawnear powerup solo si cumple la condición
					if shouldSpawnPowerUp then
						-- ✅ Pasar el número de wave para el sistema híbrido
						PowerUpModule.SpawnPowerUpForPlayer(plr.UserId, waveType, ServerState.CurrentWave)

						if Config.DEBUG_MODE then
							print(("[POWERUP] ✅ Spawneando powerup para %s - Wave %d (%s)"):format(
								plr.Name, ServerState.CurrentWave, waveType
							))
						end
					end
					--]]

					if Config.DEBUG_MODE then
						print(("[WAVE] ✅ Jugador %s SOBREVIVIÓ wave %d"):format(plr.Name, ServerState.CurrentWave))
					end
				else
					-- ❌ Jugador MURIÓ
					-- ✅ ENVIAR RESULTADO ÉPICO DE DERROTA
					if WaveResult then
						local waveData = {
							result = "defeat",
							waveNumber = ServerState.CurrentWave,
							survivedCount = Base.GetMeteorsSurvived(plr.UserId)
						}
						print(("[WAVE] 💀 Enviando DERROTA a %s - Wave %d"):format(plr.Name, ServerState.CurrentWave))
						WaveResult:FireClient(plr, waveData)
					else
						warn("[WAVE] ⚠️ WaveResult remote no existe!")
					end

					if Config.DEBUG_MODE then
						print(("[WAVE] ❌ Jugador %s MURIÓ durante wave %d"):format(plr.Name, ServerState.CurrentWave))
					end
				end
			end

			-- ✅ INCREMENTAR WAVE DESPUÉS de enviar mensajes
			ServerState.CurrentWave += 1
			CurrentWaveValue.Value = ServerState.CurrentWave

			logAnalytic("WaveCompleted", {
				wave = ServerState.CurrentWave - 1,
				survivors = #Players:GetPlayers(),
			})
			-- Pausa de 5 segundos antes de anunciar el siguiente wave
			task.wait(5)
		end


	
	end)

	if DEBUG then
		print("[EVENTS] ✓ Sistema de waves iniciado")
	end
else
	warn("[EVENTS] EventManager no disponible - eventos desactivados")
end

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE REBUILD (Reconstruir progreso al unirse)
--═══════════════════════════════════════════════════════════════════════
local function rebuildPlayerProgress(plr: Player, basePart: BasePart)
	local s = Economy.GetState(plr.UserId)
	if not (s and s.OwnedUpgrades) then return end

	-- Reset índices
	BuildIndexByCategory[plr.UserId] = {
		Income = 1,
		Defense = 1,
		Utility = 1,
	}

	local totalRebuilt = 0
	local buttonsCreated = 0
	local basesFolder = getBasesFolder()

	-- Primero crear todos los botones
	for id, owned in pairs(s.OwnedUpgrades) do
		if (owned or 0) > 0 then
			local def = UpgDefs[id]
			if def and def.ModelName then
				local buttonName = "Button_" .. id
				local existing = basesFolder:FindFirstChild(buttonName)

				if not existing then
					local button = createUpgradeButton(id, def, plr.UserId, basePart)
					if button then
						buttonsCreated += 1
					end
				end
			end
		end
	end

	-- Luego colocar todos los modelos
	for id, owned in pairs(s.OwnedUpgrades) do
		if (owned or 0) > 0 then
			local def = UpgDefs[id]
			if def and def.ModelName then
				local category = def.Category or "Income"
				local tpl = ModelsFolder:FindFirstChild(def.ModelName)

				if not (tpl and tpl:IsA("Model") and tpl.PrimaryPart) then
					-- Crear placeholder
					local m = Instance.new("Model")
					m.Name = def.ModelName .. "_Placeholder"
					local p = Instance.new("Part")
					p.Name = "Primary"
					p.Size = Vector3.new(6, 6, 6)
					p.Anchored = true
					p.Material = Enum.Material.Metal
					p.Color = Color3.fromRGB(255, 180, 0)
					p.Parent = m
					m.PrimaryPart = p
					tpl = m
				end

				for i = 1, owned do
					if totalRebuilt >= Config.MAX_MODELS_PER_BASE then
						warn(("[REBUILD] Límite alcanzado para %s"):format(plr.Name))
						return
					end

					local cf
					if id == "Upgrade_7" then
						cf = getWallPlacementCFrame(basePart, i)
					else
						local catIndex = getOrInitCategoryIndex(plr.UserId, category)
						cf = getNextBuildCFrame(basePart, catIndex, category)

						if cf then
							incrementCategoryIndex(plr.UserId, category)
						end
					end

					if cf then
						local clone = tpl:Clone()
						tagOwned(clone, plr.UserId)
						clone:PivotTo(cf)
						clone.Parent = basesFolder
						totalRebuilt += 1
					end
				end
			end
		end
	end

	if DEBUG then
		print(("[REBUILD] %s: %d modelos, %d botones"):format(
			plr.Name, totalRebuilt, buttonsCreated
			))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- 🎨 INICIALIZAR AMBIENTE APOCALÍPTICO
--═══════════════════════════════════════════════════════════════════════
EnvironmentManager:Initialize()

if Config.DEBUG_MODE then
	print("[MAIN] ✓ Ambiente apocalíptico inicializado")
end

if Config.DEBUG_MODE then
	print("[MAIN] 🧹 Limpiando bases de sesiones anteriores...")

	local basesFolder = workspace:FindFirstChild("Bases")
	if basesFolder then
		local count = 0
		for _, obj in ipairs(basesFolder:GetChildren()) do
			if obj:IsA("BasePart") or obj:IsA("Model") then
				obj:Destroy()
				count += 1
			end
		end
		print(("[MAIN] ✅ Limpiadas %d bases viejas"):format(count))
	end
end

local function diagnosticBillboards(userId: number)
	task.delay(2, function() -- Esperar 2 segundos a que se creen las bases
		local basesFolder = workspace:FindFirstChild("Bases")
		if not basesFolder then return end

		local billboardCount = 0
		local baseCount = 0

		for _, obj in ipairs(basesFolder:GetDescendants()) do
			if obj:GetAttribute("OwnerUserId") == userId then
				if obj:IsA("BasePart") then
					baseCount += 1
					print(("[DIAGNOSTIC] Base encontrada: %s"):format(obj.Name))
				end
			end

			if obj:IsA("BillboardGui") then
				local parent = obj.Parent
				if parent and parent:GetAttribute("OwnerUserId") == userId then
					billboardCount += 1
					print(("[DIAGNOSTIC] Billboard #%d: Parent = %s"):format(
						billboardCount, parent.Name
						))
				end
			end
		end

		print(("[DIAGNOSTIC] RESUMEN userId %d: %d bases, %d billboards"):format(
			userId, baseCount, billboardCount
			))

		if billboardCount > 1 then
			warn(("[DIAGNOSTIC] ⚠️ PROBLEMA: Hay %d billboards (debería ser 1)"):format(billboardCount))
		end
	end)
end
--═══════════════════════════════════════════════════════════════════════
-- PLAYER LIFECYCLE
--═══════════════════════════════════════════════════════════════════════
Players.PlayerAdded:Connect(function(plr: Player)
	ServerState.PlayersJoined += 1

	-- Crear leaderstats
	local ls, cashVal, ipsVal = createLeaderstats(plr)

	-- Inicializar módulos
	Base.InitPlayer(plr.UserId)

	-- Cargar datos
	local blob = DataStore:LoadAsync(plr.UserId)
	Economy.InitPlayer(plr.UserId, blob)

	-- Calcular offline earnings
	local now = os.time()
	local lastOut = tonumber(blob.LastLogout or 0) or 0
	local maxOfflineSecs = Config.OFFLINE_MAX_MINUTES * 60
	local elapsed = math.max(0, math.min(now - lastOut, maxOfflineSecs))

	if elapsed > 0 and lastOut > 0 then
		local s = Economy.GetState(plr.UserId)
		if s and s.IncomePerSec > 0 then
			local offlineRate = Config.OFFLINE_RATE_MULTIPLIER
			local earned = math.floor(s.IncomePerSec * elapsed * offlineRate)
			s.Cash = math.clamp(s.Cash + earned, Config.MIN_CASH, Config.MAX_CASH)

			if earned > 0 then
				task.delay(2, function()
					notifyPlayer(plr, string.format("💰 Offline earnings: +$%d!", earned), 5)
				end)
			end

			if DEBUG then
				print(("[OFFLINE] %s ganó $%d en %ds"):format(plr.Name, earned, elapsed))
			end
		end
	end

	-- Sync inicial
	local s = Economy.GetState(plr.UserId)
	if s then
		plr:SetAttribute("ShieldLevel", s.OwnedUpgrades["Upgrade_6"] or 0)
		cashVal.Value = s.Cash
		ipsVal.Value = s.IncomePerSec

		local stats = plr:FindFirstChild("Stats")
		if stats then
			local prestigeVal = stats:FindFirstChild("PrestigeLevel") :: IntValue?
			if prestigeVal then prestigeVal.Value = s.PrestigeLevel or 0 end

			local totalEarnedVal = stats:FindFirstChild("TotalEarned") :: IntValue?
			if totalEarnedVal then totalEarnedVal.Value = s.TotalEarned or 0 end

			local meteorsVal = stats:FindFirstChild("MeteorsSurvived") :: IntValue?
			if meteorsVal then meteorsVal.Value = Base.GetMeteorsSurvived(plr.UserId) end
		end
	end

	-- Asignar slot y base
	local slot = SlotByUserId[plr.UserId]
	if not slot then
		slot = NextSlot
		SlotByUserId[plr.UserId] = slot
		NextSlot += 1
	end

	assignBase(plr, slot)
	-- ✅ DIAGNÓSTICO TEMPORAL
	if Config.DEBUG_MODE then
		diagnosticBillboards(plr.UserId)
	end

	-- Rebuild progreso
	local basePart = BasePartByUser[plr.UserId]
	if basePart then
		rebuildPlayerProgress(plr, basePart)
	end

	-- Character lifecycle
	local function onCharacterAdded(char: Model)
		teleportToBase(plr, char)

		-- Mostrar tutorial si es nuevo
		if not TutorialCompleted[plr.UserId] then
			task.delay(3, function()
				notifyPlayer(plr, "👋 Welcome! Press G to open shop", 5)
			end)
		end
	end

	plr.CharacterAdded:Connect(onCharacterAdded)
	if plr.Character then
		onCharacterAdded(plr.Character)
	end

	-- Welcome message
	task.delay(1, function()
		if s and s.PrestigeLevel > 0 then
			notifyPlayer(plr, string.format("✨ Welcome back, Prestige %d!", s.PrestigeLevel), 3)
		else
			notifyPlayer(plr, "🎮 Welcome to Apocalypse Tycoon!", 3)
		end
	end)

	logAnalytic("PlayerJoined", {
		userId = plr.UserId,
		name = plr.Name,
		prestige = s and s.PrestigeLevel or 0,
	})

	if DEBUG then
		print(("═══════════════════════════════════════════════════════════"):rep(1))
		print(("[JOIN] %s (#%d) - Cash: $%d | Prestige: %d"):format(
			plr.Name, plr.UserId,
			s and s.Cash or 0,
			s and s.PrestigeLevel or 0
			))
		print(("═══════════════════════════════════════════════════════════"):rep(1))
	end
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	-- Guardar datos
	local blob = Economy.ToBlob(plr.UserId)
	if blob then
		blob.LastLogout = os.time()

		-- Stats adicionales
		blob.MeteorsSurvived = Base.GetMeteorsSurvived(plr.UserId)

		local stats = plr:FindFirstChild("Stats")
		if stats then
			local playTime = stats:FindFirstChild("PlayTime") :: IntValue?
			if playTime then
				blob.PlayTime = playTime.Value
			end
		end

		local success = DataStore:SaveAsync(plr.UserId, blob)
		if not success then
			warn(("[SAVE] ❌ Error guardando datos de %s"):format(plr.Name))
		elseif DEBUG then
			print(("[SAVE] ✓ Guardado: %s ($%d)"):format(plr.Name, blob.Cash))
		end
	end

	-- Cleanup
	BasePartByUser[plr.UserId] = nil
	BuildIndexByCategory[plr.UserId] = nil
	LastActionTime[plr.UserId] = nil
	TutorialCompleted[plr.UserId] = nil

	logAnalytic("PlayerLeft", {
		userId = plr.UserId,
		name = plr.Name,
	})

	if DEBUG then
		print(("[LEAVE] %s desconectado"):format(plr.Name))
	end
end)

--═══════════════════════════════════════════════════════════════════════
-- SHUTDOWN HANDLER (Guardar todo antes de cerrar)
--═══════════════════════════════════════════════════════════════════════
game:BindToClose(function()
	if RunService:IsStudio() then return end

	print("[SHUTDOWN] Guardando todos los datos...")

	for _, plr in ipairs(Players:GetPlayers()) do
		local blob = Economy.ToBlob(plr.UserId)
		if blob then
			blob.LastLogout = os.time()
			DataStore:SaveAsync(plr.UserId, blob)
		end
	end

	print("[SHUTDOWN] ✓ Datos guardados")
	task.wait(2)
end)

--═══════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN FINAL
--═══════════════════════════════════════════════════════════════════════
print("═══════════════════════════════════════════════════════════════════════")
print("  🎮 APOCALYPSE TYCOON - SERVER INICIADO")
print("═══════════════════════════════════════════════════════════════════════")
print(("[CONFIG] Versión: 5.0 PRODUCTION"):format())
print(("[CONFIG] DataStore: %s (v%d)"):format(Config.DATASTORE_NAME, Config.DATA_VERSION))
print(("[CONFIG] Start Cash: $%d | Max Cash: $%d"):format(Config.START_CASH, Config.MAX_CASH))
print(("[CONFIG] Base HP: %d | Regen: %d/s"):format(Config.BASE_MAX_HP, Config.BASE_REGEN_RATE))
print(("[CONFIG] Waves: Activo | Prestige: %s"):format(Config.PRESTIGE.Enabled and "Si" or "No"))
print(("[CONFIG] Analytics: %s | Debug: %s"):format(
	Config.ANALYTICS.Enabled and "Si" or "No",
	DEBUG and "Si" or "No"
	))
print(("[CONFIG] Offline Earnings: %d min (%.0f%% rate)"):format(
	Config.OFFLINE_MAX_MINUTES,
	Config.OFFLINE_RATE_MULTIPLIER * 100
	))
print("═══════════════════════════════════════════════════════════════════════")

if DEBUG then
	print("\n[DEBUG] Modo debug activo - Comandos disponibles:")
	print("  - /givecash [player] [amount]")
	print("  - /setwave [number]")
	print("  - /heal [player]")
	print("  - /meteors [count]")
	print("  - /stats")
	print("═══════════════════════════════════════════════════════════════════════\n")
end

-- Validar configuración crítica
local isValid, errorMsg = Config.Validate()
if not isValid then
	error(("[CONFIG] ❌ Configuración inválida: %s"):format(errorMsg or "unknown"))
end

print("✅ Servidor listo para jugadores\n")
