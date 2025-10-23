--!strict
--[[
	TUTORIAL MANAGER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema de tutorial interactivo que enseña la mecánica de salto para evadir meteoritos.

	FLUJO DEL TUTORIAL:
	1. Pantalla negra → "Welcome to the Apocalypse"
	2. Spawn en tutorial area aislada
	3. Primer meteorito (warning) → IMPACTO (toma daño)
	4. "Jump to dodge!" (enseña mecánica)
	5. Segundo meteorito → Debe esquivarlo
	6. Si falla: retry (máx 3 intentos)
	7. Si éxito: +10 tiros gratis → Teleport a base real

	FEATURES:
	✅ Zona aislada del mapa principal
	✅ Meteoritos de práctica (daño reducido)
	✅ Retry system
	✅ Recompensas al completar
	✅ Tracking de progreso
	✅ Highlights del botón de summon al terminar

	USAGE:
		local TutorialManager = require(game.ServerStorage.TutorialManager)

		-- Inicializar al arrancar el servidor
		TutorialManager:Initialize()

		-- Iniciar tutorial para un jugador
		TutorialManager:StartTutorial(player)
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--═══════════════════════════════════════════════════════════════════════
-- MÓDULOS
--═══════════════════════════════════════════════════════════════════════

local Config = require(ServerStorage.Config.Config)
local MeteorDamageSystem = require(ServerStorage.MeteorDamageSystem)
local VFXManager = require(ServerStorage.Managers.VFXManager)

-- Economy module (para dar recompensas)
local Economy = nil
pcall(function()
	Economy = require(game.ServerScriptService.EconomyModule)
end)

--═══════════════════════════════════════════════════════════════════════
-- REMOTES
--═══════════════════════════════════════════════════════════════════════

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Crear remotes si no existen
local function getOrCreateRemote(name: string, className: string)
	local remote = Remotes:FindFirstChild(name)
	if not remote then
		if className == "RemoteEvent" then
			remote = Instance.new("RemoteEvent")
		else
			remote = Instance.new("RemoteFunction")
		end
		remote.Name = name
		remote.Parent = Remotes
		warn(("[TutorialManager] Creado %s '%s'"):format(className, name))
	end
	return remote
end

local ShowTutorialScreen = getOrCreateRemote("ShowTutorialScreen", "RemoteEvent") :: RemoteEvent
local HideTutorialScreen = getOrCreateRemote("HideTutorialScreen", "RemoteEvent") :: RemoteEvent
local ShowNotification = getOrCreateRemote("ShowNotification", "RemoteEvent") :: RemoteEvent
local ShowJumpIndicator = getOrCreateRemote("ShowJumpIndicator", "RemoteEvent") :: RemoteEvent
local HideJumpIndicator = getOrCreateRemote("HideJumpIndicator", "RemoteEvent") :: RemoteEvent
local CameraShake = getOrCreateRemote("CameraShake", "RemoteEvent") :: RemoteEvent

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTES
--═══════════════════════════════════════════════════════════════════════

local DEBUG = Config.DEBUG_MODE

local TUTORIAL_POSITION = Config.TUTORIAL.TutorialZonePosition or Vector3.new(0, 1000, 0)
local METEOR_WARNING_TIME = Config.TUTORIAL.MeteorWarningTime or 2
local MAX_RETRIES = Config.TUTORIAL.MaxRetries or 3
local FREE_SUMMONS_REWARD = Config.TUTORIAL.RewardFreeSummons or 10

--═══════════════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════════════

local TutorialState = {} -- [userId] = {step, completed, retries, dodgedMeteor}
local TutorialArea = nil :: Folder?

--═══════════════════════════════════════════════════════════════════════
-- MÓDULO
--═══════════════════════════════════════════════════════════════════════

local TutorialManager = {}

--═══════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
--═══════════════════════════════════════════════════════════════════════

function TutorialManager:Initialize()
	-- Crear zona de tutorial
	TutorialArea = workspace:FindFirstChild("TutorialZone") :: Folder?
	if not TutorialArea then
		TutorialArea = Instance.new("Folder")
		TutorialArea.Name = "TutorialZone"
		TutorialArea.Parent = workspace
	end

	-- Limpiar zona existente
	TutorialArea:ClearAllChildren()

	-- Crear plataforma
	local platform = Instance.new("Part")
	platform.Name = "TutorialPlatform"
	platform.Size = Vector3.new(80, 2, 80)
	platform.Position = TUTORIAL_POSITION
	platform.Anchored = true
	platform.Material = Enum.Material.Concrete
	platform.Color = Color3.fromRGB(60, 60, 60)
	platform.Parent = TutorialArea

	-- Decoración: grid lines
	local gridSize = 8
	for i = 1, 9 do
		local line = Instance.new("Part")
		line.Size = Vector3.new(80, 0.1, 0.5)
		line.Position = platform.Position + Vector3.new(0, 1.1, -40 + (i * gridSize))
		line.Anchored = true
		line.Material = Enum.Material.Neon
		line.Color = Color3.fromRGB(100, 100, 100)
		line.CanCollide = false
		line.Parent = TutorialArea

		local line2 = Instance.new("Part")
		line2.Size = Vector3.new(0.5, 0.1, 80)
		line2.Position = platform.Position + Vector3.new(-40 + (i * gridSize), 1.1, 0)
		line2.Anchored = true
		line2.Material = Enum.Material.Neon
		line2.Color = Color3.fromRGB(100, 100, 100)
		line2.CanCollide = false
		line2.Parent = TutorialArea
	end

	-- Paredes invisibles
	local wallHeight = 20
	local wallPositions = {
		{pos = Vector3.new(0, wallHeight/2, 40), size = Vector3.new(80, wallHeight, 1)}, -- Norte
		{pos = Vector3.new(0, wallHeight/2, -40), size = Vector3.new(80, wallHeight, 1)}, -- Sur
		{pos = Vector3.new(40, wallHeight/2, 0), size = Vector3.new(1, wallHeight, 80)}, -- Este
		{pos = Vector3.new(-40, wallHeight/2, 0), size = Vector3.new(1, wallHeight, 80)}, -- Oeste
	}

	for _, data in ipairs(wallPositions) do
		local wall = Instance.new("Part")
		wall.Size = data.size
		wall.Position = TUTORIAL_POSITION + data.pos
		wall.Anchored = true
		wall.Transparency = 1
		wall.CanCollide = true
		wall.Parent = TutorialArea
	end

	-- Luz ambiental
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Range = 100
	light.Color = Color3.fromRGB(255, 200, 150)
	light.Parent = platform

	if DEBUG then
		print("[TutorialManager] ✓ Tutorial zone created at", TUTORIAL_POSITION)
	end
end

--═══════════════════════════════════════════════════════════════════════
-- TUTORIAL FLOW
--═══════════════════════════════════════════════════════════════════════

function TutorialManager:StartTutorial(player: Player)
	local userId = player.UserId

	-- Verificar si ya completó el tutorial
	if TutorialState[userId] and TutorialState[userId].completed then
		if DEBUG then
			print(("[TutorialManager] Player %d already completed tutorial"):format(userId))
		end
		return false
	end

	-- Inicializar estado
	TutorialState[userId] = {
		step = 1,
		completed = false,
		retries = 0,
		dodgedMeteor = false,
		startTime = tick()
	}

	-- Teleport a tutorial zone
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?

	if root then
		root.CFrame = CFrame.new(TUTORIAL_POSITION + Vector3.new(0, 5, 0))
	end

	-- Iniciar secuencia
	task.spawn(function()
		tutorialSequence(player)
	end)

	if DEBUG then
		print(("[TutorialManager] Tutorial started for %s"):format(player.Name))
	end

	return true
end

-- Secuencia principal del tutorial
local function tutorialSequence(player: Player)
	local userId = player.UserId
	local state = TutorialState[userId]

	if not state then return end

	-- STEP 1: Bienvenida
	ShowTutorialScreen:FireClient(player, "WELCOME TO THE APOCALYPSE", 3, Color3.fromRGB(200, 50, 50))
	task.wait(3.5)

	-- STEP 2: Explicar el contexto
	ShowTutorialScreen:FireClient(player, "Meteors will rain from the sky...", 2.5, Color3.fromRGB(255, 150, 100))
	task.wait(3)

	-- STEP 3: Primer meteorito (sin poder esquivar)
	ShowNotification:FireClient(player, "⚠️ INCOMING METEOR!", 2, Color3.fromRGB(255, 0, 0))
	task.wait(METEOR_WARNING_TIME)

	spawnTutorialMeteor(player, false) -- No cuenta como dodge
	task.wait(3)

	-- STEP 4: Enseñar mecánica
	ShowTutorialScreen:FireClient(player, "JUMP TO DODGE METEORS!", 4, Color3.fromRGB(0, 255, 0))
	ShowJumpIndicator:FireClient(player)
	task.wait(4)

	-- STEP 5: Segundo meteorito (puede esquivar)
	state.step = 2
	attemptDodgeMeteor(player)
end

-- Intentar esquivar meteorito
local function attemptDodgeMeteor(player: Player)
	local userId = player.UserId
	local state = TutorialState[userId]

	if not state then return end

	-- Notificación
	ShowNotification:FireClient(player, "⚠️ DODGE THIS ONE!", 2, Color3.fromRGB(255, 200, 0))
	task.wait(METEOR_WARNING_TIME)

	-- Preparar hook para detectar dodge
	state.dodgedMeteor = false

	local connection
	connection = MeteorDamageSystem.OnDodge:Connect(function(dodgedUserId)
		if dodgedUserId == userId then
			state.dodgedMeteor = true
			connection:Disconnect()
		end
	end)

	-- Spawn meteorito
	local success = spawnTutorialMeteor(player, true)
	task.wait(2)

	connection:Disconnect()

	-- Verificar resultado
	if state.dodgedMeteor or success then
		-- ✅ SUCCESS
		onDodgeSuccess(player)
	else
		-- ❌ FAILED
		onDodgeFailed(player)
	end
end

local function onDodgeSuccess(player: Player)
	local userId = player.UserId
	local state = TutorialState[userId]

	if not state then return end

	-- Feedback positivo
	ShowTutorialScreen:FireClient(player, "PERFECT!", 2, Color3.fromRGB(0, 255, 0))
	VFXManager:PlayEffect("PurchaseSuccess", player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
	CameraShake:FireClient(player, "Light", 0.3)
	task.wait(2.5)

	-- Dar recompensa
	ShowTutorialScreen:FireClient(player, string.format("+%d FREE SUMMONS!", FREE_SUMMONS_REWARD), 3, Color3.fromRGB(255, 215, 0))
	task.wait(3)

	-- Aplicar recompensa
	if Economy then
		local econ = Economy.GetState(userId)
		if econ then
			econ.FreeSummons = (econ.FreeSummons or 0) + FREE_SUMMONS_REWARD
		end
	end

	-- Completar tutorial
	TutorialManager:CompleteTutorial(player)
end

local function onDodgeFailed(player: Player)
	local userId = player.UserId
	local state = TutorialState[userId]

	if not state then return end

	state.retries += 1

	if state.retries >= MAX_RETRIES then
		-- Demasiados intentos, dar success de todos modos
		ShowNotification:FireClient(player, "That's okay, let's continue!", 3, Color3.fromRGB(100, 150, 255))
		task.wait(2)
		onDodgeSuccess(player)
		return
	end

	-- Retry
	ShowNotification:FireClient(player, "Try again! Jump when you see the warning!", 3, Color3.fromRGB(255, 200, 0))
	task.wait(2)

	attemptDodgeMeteor(player)
end

function TutorialManager:CompleteTutorial(player: Player)
	local userId = player.UserId
	local state = TutorialState[userId]

	if not state then return end

	-- Marcar como completado
	state.completed = true
	state.step = 99

	-- Mensaje final
	ShowTutorialScreen:FireClient(player, "TUTORIAL COMPLETE", 2, Color3.fromRGB(255, 215, 0))
	task.wait(2)

	-- Ocultar UI del tutorial
	HideTutorialScreen:FireClient(player)
	HideJumpIndicator:FireClient(player)

	-- Teleport a su base real
	task.wait(1)

	local basesFolder = workspace:FindFirstChild("Bases")
	if basesFolder then
		for _, basePart in ipairs(basesFolder:GetChildren()) do
			if basePart:IsA("BasePart") and basePart:GetAttribute("OwnerUserId") == userId then
				local character = player.Character
				if character then
					local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if root then
						root.CFrame = basePart.CFrame + Vector3.new(0, 10, 0)
					end
				end
				break
			end
		end
	end

	-- Highlight del botón de summon
	task.delay(2, function()
		TutorialManager:HighlightSummonButton(player)
	end)

	if DEBUG then
		local duration = tick() - state.startTime
		print(("[TutorialManager] %s completed tutorial in %.1fs (retries: %d)"):format(
			player.Name, duration, state.retries
		))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- METEORITOS DE PRÁCTICA
--═══════════════════════════════════════════════════════════════════════

function spawnTutorialMeteor(player: Player, canDodge: boolean): boolean
	local character = player.Character
	if not character then return false end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return false end

	-- Crear meteorito de práctica
	local meteor = Instance.new("Part")
	meteor.Name = "TutorialMeteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(6, 6, 6)
	meteor.Material = Enum.Material.Neon
	meteor.Color = Color3.fromRGB(255, 100, 50)
	meteor.Anchored = false
	meteor.CanCollide = true
	meteor.Position = root.Position + Vector3.new(0, 30, 0)
	meteor.Parent = TutorialArea

	-- Efecto de fuego
	local fire = Instance.new("Fire", meteor)
	fire.Size = 8
	fire.Heat = 12
	fire.Color = Color3.fromRGB(255, 100, 0)

	-- Trail
	VFXManager:PlayEffect("MeteorTrail", meteor.Position)

	-- BodyVelocity para caída
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	bv.Velocity = Vector3.new(0, -45, 0) -- Velocidad moderada
	bv.Parent = meteor

	-- Detección de impacto
	local impacted = false

	meteor.Touched:Connect(function(hit)
		if impacted then return end
		if hit:IsDescendantOf(character) then return end

		impacted = true

		-- Explosión
		VFXManager:PlayEffect("MeteorExplosion", meteor.Position)
		CameraShake:FireClient(player, "Medium", 0.5)

		-- Aplicar daño si está habilitado
		if canDodge then
			-- Crear una base falsa para el sistema de daño
			local fakBase = Instance.new("Part")
			fakBase:SetAttribute("OwnerUserId", player.UserId)
			fakBase.Position = root.Position
			fakBase.Parent = nil

			MeteorDamageSystem:OnMeteorImpact(meteor.Position, fakBase, "Normal")

			fakBase:Destroy()
		else
			-- Solo daño visual sin mecánica de dodge
			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
			if humanoid then
				humanoid:TakeDamage(10) -- Daño reducido
			end

			ShowNotification:FireClient(player, "-10 HP", 2, Color3.fromRGB(255, 0, 0))
		end

		-- Destruir meteorito
		meteor:Destroy()
	end)

	-- Timeout
	Debris:AddItem(meteor, 5)

	return true
end

--═══════════════════════════════════════════════════════════════════════
-- UTILIDADES
--═══════════════════════════════════════════════════════════════════════

function TutorialManager:HighlightSummonButton(player: Player)
	-- Esta función se conectará con el botón de summon en el main server
	ShowNotification:FireClient(player, "Click the SUMMON button to get your first dinosaur!", 5, Color3.fromRGB(255, 215, 0))

	-- TODO: Agregar highlight visual del botón
end

function TutorialManager:HasCompletedTutorial(userId: number): boolean
	return TutorialState[userId] and TutorialState[userId].completed or false
end

function TutorialManager:GetProgress(userId: number)
	return TutorialState[userId]
end

--═══════════════════════════════════════════════════════════════════════
-- CLEANUP
--═══════════════════════════════════════════════════════════════════════

Players.PlayerRemoving:Connect(function(plr)
	TutorialState[plr.UserId] = nil
end)

--═══════════════════════════════════════════════════════════════════════

-- No auto-inicializar, debe llamarse explícitamente desde el main server
if DEBUG then
	print("[TutorialManager] ✓ Módulo cargado (usar :Initialize() para setup)")
end

return TutorialManager
