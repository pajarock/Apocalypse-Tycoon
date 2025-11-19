--!strict
--[[
	PROCEDURAL MODELS - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Genera modelos 3D procedurales para upgrades con estilo apocal�ptico.

	FEATURES:
	? 10+ modelos pre-definidos
	? Low-poly futurista/industrial
	? Animaciones simples (rotar, flotar, pulsar)
	? Efectos de part�culas integrados
	? Colores met�licos con acentos ne�n
	? < 100 triangles por modelo

	USAGE:
		local ProceduralModels = require(game.ServerStorage.Managers.ProceduralModels)

		-- Crear modelo
		local model = ProceduralModels:CreateModel("SolarPanel")
		model.Parent = workspace

	AVAILABLE MODELS:
		- SolarPanel (Income)
		- WindTurbine (Income)
		- MinerDrill (Income)
		- NuclearReactor (Income)
		- ShieldGenerator (Defense)
		- WallSection (Defense)
		- Turret (Defense)
		- StorageContainer (Utility)
		- AutoRepairDrone (Utility)
		- WaterPump (Utility)
]]

local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------

local DEBUG_MODE = false

-- Colores por categor�a
local CATEGORY_COLORS = {
	Income = {
		Primary = Color3.fromRGB(180, 180, 180), -- Gris met�lico
		Accent = Color3.fromRGB(255, 215, 0),    -- Dorado
		Glow = Color3.fromRGB(255, 255, 100),
	},
	Defense = {
		Primary = Color3.fromRGB(100, 120, 140), -- Gris azulado
		Accent = Color3.fromRGB(100, 150, 255),  -- Azul ne�n
		Glow = Color3.fromRGB(150, 200, 255),
	},
	Utility = {
		Primary = Color3.fromRGB(140, 100, 140), -- Gris morado
		Accent = Color3.fromRGB(200, 100, 255),  -- Morado ne�n
		Glow = Color3.fromRGB(220, 150, 255),
	},
}

-------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------

local ProceduralModels = {}
ProceduralModels.__index = ProceduralModels

-------------------------------------------------------------------------
-- UTILITIES
-------------------------------------------------------------------------

local function addRotationAnimation(part: BasePart, speed: number)
	task.spawn(function()
		while part and part.Parent do
			part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(speed), 0)
			task.wait(1/30) -- 30 FPS para animaci�n
		end
	end)
end

local function addFloatAnimation(part: BasePart, height: number, duration: number)
	local originalPos = part.Position

	task.spawn(function()
		while part and part.Parent do
			-- Float up
			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = originalPos + Vector3.new(0, height, 0)}
			):Play()

			task.wait(duration)

			-- Float down
			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Position = originalPos}
			):Play()

			task.wait(duration)
		end
	end)
end

local function addPulseAnimation(part: BasePart, intensity: number, duration: number)
	local originalSize = part.Size

	task.spawn(function()
		while part and part.Parent do
			-- Pulse up
			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = originalSize * (1 + intensity)}
			):Play()

			task.wait(duration)

			-- Pulse down
			TweenService:Create(
				part,
				TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Size = originalSize}
			):Play()

			task.wait(duration)
		end
	end)
end

local function addGlowEffect(part: BasePart, color: Color3): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 2
	light.Range = 15
	light.Parent = part

	return light
end

local function addEnergyParticles(part: BasePart, color: Color3): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 5
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.LightEmission = 1
	emitter.Acceleration = Vector3.new(0, 5, 0)
	emitter.Parent = part

	return emitter
end

-------------------------------------------------------------------------
-- MODEL GENERATORS - INCOME
-------------------------------------------------------------------------

local function createSolarPanel(): Model
	local model = Instance.new("Model")
	model.Name = "SolarPanel"

	local colors = CATEGORY_COLORS.Income

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(6, 1, 6)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Panel (inclinado)
	local panel = Instance.new("Part")
	panel.Name = "Panel"
	panel.Size = Vector3.new(5, 0.2, 4)
	panel.Anchored = true
	panel.Material = Enum.Material.Glass
	panel.Color = Color3.fromRGB(50, 50, 80)
	panel.Transparency = 0.3
	panel.CFrame = base.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(30), 0, 0)
	panel.Parent = model

	-- Support pole
	local pole = Instance.new("Part")
	pole.Name = "Pole"
	pole.Size = Vector3.new(0.5, 3, 0.5)
	pole.Anchored = true
	pole.Material = Enum.Material.Metal
	pole.Color = colors.Primary
	pole.CFrame = base.CFrame * CFrame.new(0, 1.5, 0)
	pole.Parent = model

	-- Glow cells on panel
	local cell = Instance.new("Part")
	cell.Name = "Cell"
	cell.Size = Vector3.new(0.8, 0.3, 0.8)
	cell.Anchored = true
	cell.Material = Enum.Material.Neon
	cell.Color = colors.Accent
	cell.CFrame = panel.CFrame
	cell.Parent = model

	addGlowEffect(cell, colors.Glow)
	addEnergyParticles(panel, colors.Glow)

	model.PrimaryPart = base
	return model
end

local function createWindTurbine(): Model
	local model = Instance.new("Model")
	model.Name = "WindTurbine"

	local colors = CATEGORY_COLORS.Income

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 1, 4)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Tower
	local tower = Instance.new("Part")
	tower.Name = "Tower"
	tower.Size = Vector3.new(1, 10, 1)
	tower.Anchored = true
	tower.Material = Enum.Material.Metal
	tower.Color = colors.Primary
	tower.CFrame = base.CFrame * CFrame.new(0, 5.5, 0)
	tower.Parent = model

	-- Hub
	local hub = Instance.new("Part")
	hub.Name = "Hub"
	hub.Size = Vector3.new(1.5, 1.5, 1.5)
	hub.Shape = Enum.PartType.Cylinder
	hub.Anchored = false -- Para rotar
	hub.Material = Enum.Material.Metal
	hub.Color = colors.Accent
	hub.CFrame = tower.CFrame * CFrame.new(0, 5.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	hub.Parent = model

	-- Blades (3)
	for i = 1, 3 do
		local blade = Instance.new("Part")
		blade.Name = "Blade_" .. i
		blade.Size = Vector3.new(0.3, 4, 1)
		blade.Anchored = false
		blade.Material = Enum.Material.Metal
		blade.Color = Color3.fromRGB(220, 220, 220)
		blade.CFrame = hub.CFrame * CFrame.Angles(0, 0, math.rad((i-1) * 120)) * CFrame.new(0, 2, 0)
		blade.Parent = model

		-- Weld blade to hub
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hub
		weld.Part1 = blade
		weld.Parent = hub
	end

	-- Weld hub to tower
	local hubWeld = Instance.new("WeldConstraint")
	hubWeld.Part0 = tower
	hubWeld.Part1 = hub
	hubWeld.Parent = tower

	-- Rotation animation
	addRotationAnimation(hub, 2) -- 2 degrees per frame

	model.PrimaryPart = base
	return model
end

local function createMinerDrill(): Model
	local model = Instance.new("Model")
	model.Name = "MinerDrill"

	local colors = CATEGORY_COLORS.Income

	-- Base platform
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(6, 1, 6)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Support frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(3, 5, 3)
	frame.Anchored = true
	frame.Material = Enum.Material.Metal
	frame.Color = colors.Primary
	frame.CFrame = base.CFrame * CFrame.new(0, 3, 0)
	frame.Parent = model

	-- Drill bit (rotates)
	local drill = Instance.new("Part")
	drill.Name = "Drill"
	drill.Size = Vector3.new(1, 4, 1)
	drill.Shape = Enum.PartType.Cylinder
	drill.Anchored = false
	drill.Material = Enum.Material.DiamondPlate
	drill.Color = colors.Accent
	drill.CFrame = frame.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)
	drill.Parent = model

	-- Weld
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = frame
	weld.Part1 = drill
	weld.Parent = frame

	-- Tip (pointed)
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.8, 1, 0.8)
	tip.Shape = Enum.PartType.Ball
	tip.Anchored = false
	tip.Material = Enum.Material.Metal
	tip.Color = Color3.fromRGB(50, 50, 50)
	tip.CFrame = drill.CFrame * CFrame.new(0, 0, -2.5)
	tip.Parent = model

	local tipWeld = Instance.new("WeldConstraint")
	tipWeld.Part0 = drill
	tipWeld.Part1 = tip
	tipWeld.Parent = drill

	-- Smoke/particles
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate = 10
	smoke.Lifetime = NumberRange.new(0.5, 1)
	smoke.Speed = NumberRange.new(2, 5)
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80))
	smoke.Size = NumberSequence.new(0.5)
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Parent = tip

	addRotationAnimation(drill, 10) -- Fast rotation

	model.PrimaryPart = base
	return model
end

local function createNuclearReactor(): Model
	local model = Instance.new("Model")
	model.Name = "NuclearReactor"

	local colors = CATEGORY_COLORS.Income

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(8, 1, 8)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Core (cylinder)
	local core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(5, 8, 5)
	core.Shape = Enum.PartType.Cylinder
	core.Anchored = true
	core.Material = Enum.Material.Metal
	core.Color = colors.Primary
	core.CFrame = base.CFrame * CFrame.new(0, 5, 0) * CFrame.Angles(0, 0, math.rad(90))
	core.Parent = model

	-- Reactor glow
	local glow = Instance.new("Part")
	glow.Name = "Glow"
	glow.Size = Vector3.new(3, 3, 3)
	glow.Shape = Enum.PartType.Ball
	glow.Anchored = true
	glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(100, 255, 100) -- Green glow
	glow.Transparency = 0.3
	glow.CFrame = core.CFrame
	glow.Parent = model

	-- Cooling pipes (4)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		local pipe = Instance.new("Part")
		pipe.Name = "Pipe_" .. i
		pipe.Size = Vector3.new(0.5, 6, 0.5)
		pipe.Shape = Enum.PartType.Cylinder
		pipe.Anchored = true
		pipe.Material = Enum.Material.Metal
		pipe.Color = Color3.fromRGB(100, 100, 100)
		pipe.CFrame = core.CFrame * CFrame.new(math.cos(angle) * 3, 0, math.sin(angle) * 3) * CFrame.Angles(0, 0, math.rad(90))
		pipe.Parent = model
	end

	addGlowEffect(glow, Color3.fromRGB(100, 255, 100))
	addPulseAnimation(glow, 0.1, 1)
	addEnergyParticles(glow, Color3.fromRGB(150, 255, 150))

	model.PrimaryPart = base
	return model
end

-------------------------------------------------------------------------
-- MODEL GENERATORS - DEFENSE
-------------------------------------------------------------------------

local function createShieldGenerator(): Model
	local model = Instance.new("Model")
	model.Name = "ShieldGenerator"

	local colors = CATEGORY_COLORS.Defense

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(6, 1, 6)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Core sphere
	local sphere = Instance.new("Part")
	sphere.Name = "Sphere"
	sphere.Size = Vector3.new(4, 4, 4)
	sphere.Shape = Enum.PartType.Ball
	sphere.Anchored = true
	sphere.Material = Enum.Material.ForceField
	sphere.Color = colors.Accent
	sphere.Transparency = 0.5
	sphere.CFrame = base.CFrame * CFrame.new(0, 4, 0)
	sphere.Parent = model

	-- Rotating ring
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Size = Vector3.new(6, 0.5, 6)
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = false
	ring.Material = Enum.Material.Neon
	ring.Color = colors.Accent
	ring.Transparency = 0.3
	ring.CFrame = sphere.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = model

	-- Weld ring to sphere
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = sphere
	weld.Part1 = ring
	weld.Parent = sphere

	addRotationAnimation(ring, 3)
	addGlowEffect(sphere, colors.Glow)
	addFloatAnimation(sphere, 0.5, 2)

	model.PrimaryPart = base
	return model
end

local function createTurret(): Model
	local model = Instance.new("Model")
	model.Name = "Turret"

	local colors = CATEGORY_COLORS.Defense

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(5, 2, 5)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Tower
	local tower = Instance.new("Part")
	tower.Name = "Tower"
	tower.Size = Vector3.new(3, 4, 3)
	tower.Anchored = true
	tower.Material = Enum.Material.Metal
	tower.Color = colors.Primary
	tower.CFrame = base.CFrame * CFrame.new(0, 3, 0)
	tower.Parent = model

	-- Barrel
	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Size = Vector3.new(0.8, 4, 0.8)
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Anchored = true
	barrel.Material = Enum.Material.Metal
	barrel.Color = Color3.fromRGB(50, 50, 50)
	barrel.CFrame = tower.CFrame * CFrame.new(0, 2, 2) * CFrame.Angles(math.rad(90), 0, 0)
	barrel.Parent = model

	-- Tip glow
	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.6, 0.6, 0.6)
	tip.Shape = Enum.PartType.Ball
	tip.Anchored = true
	tip.Material = Enum.Material.Neon
	tip.Color = colors.Accent
	tip.CFrame = barrel.CFrame * CFrame.new(0, 0, -2.5)
	tip.Parent = model

	addGlowEffect(tip, colors.Glow)

	model.PrimaryPart = base
	return model
end

local function createWallSection(): Model
	local model = Instance.new("Model")
	model.Name = "WallSection"

	local colors = CATEGORY_COLORS.Defense

	-- Main wall
	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Size = Vector3.new(8, 6, 1)
	wall.Anchored = true
	wall.Material = Enum.Material.Concrete
	wall.Color = colors.Primary
	wall.Parent = model

	-- Reinforcement bars (3)
	for i = 1, 3 do
		local bar = Instance.new("Part")
		bar.Name = "Bar_" .. i
		bar.Size = Vector3.new(0.3, 6, 0.3)
		bar.Anchored = true
		bar.Material = Enum.Material.Metal
		bar.Color = Color3.fromRGB(150, 150, 150)
		bar.CFrame = wall.CFrame * CFrame.new((i-2) * 3, 0, 0.7)
		bar.Parent = model
	end

	model.PrimaryPart = wall
	return model
end

-------------------------------------------------------------------------
-- MODEL GENERATORS - UTILITY
-------------------------------------------------------------------------

local function createStorageContainer(): Model
	local model = Instance.new("Model")
	model.Name = "StorageContainer"

	local colors = CATEGORY_COLORS.Utility

	-- Container body
	local container = Instance.new("Part")
	container.Name = "Container"
	container.Size = Vector3.new(6, 5, 6)
	container.Anchored = true
	container.Material = Enum.Material.Metal
	container.Color = colors.Primary
	container.Parent = model

	-- Door
	local door = Instance.new("Part")
	door.Name = "Door"
	door.Size = Vector3.new(3, 4, 0.2)
	door.Anchored = true
	door.Material = Enum.Material.Metal
	door.Color = colors.Accent
	door.CFrame = container.CFrame * CFrame.new(0, 0, 3.1)
	door.Parent = model

	-- Light on top
	local light = Instance.new("Part")
	light.Name = "Light"
	light.Size = Vector3.new(1, 0.5, 1)
	light.Anchored = true
	light.Material = Enum.Material.Neon
	light.Color = colors.Accent
	light.CFrame = container.CFrame * CFrame.new(0, 2.75, 0)
	light.Parent = model

	addGlowEffect(light, colors.Glow)
	addPulseAnimation(light, 0.1, 1.5)

	model.PrimaryPart = container
	return model
end

local function createAutoRepairDrone(): Model
	local model = Instance.new("Model")
	model.Name = "AutoRepairDrone"

	local colors = CATEGORY_COLORS.Utility

	-- Base station
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 1, 4)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Drone body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 1, 2)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = colors.Accent
	body.CFrame = base.CFrame * CFrame.new(0, 3, 0)
	body.Parent = model

	-- Propellers (4)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		local prop = Instance.new("Part")
		prop.Name = "Propeller_" .. i
		prop.Size = Vector3.new(0.2, 1.5, 0.2)
		prop.Anchored = false
		prop.Material = Enum.Material.Neon
		prop.Color = colors.Glow
		prop.CFrame = body.CFrame * CFrame.new(math.cos(angle) * 1.2, 0, math.sin(angle) * 1.2)
		prop.Parent = model

		-- Weld
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = prop
		weld.Parent = body

		addRotationAnimation(prop, 20) -- Fast spin
	end

	addFloatAnimation(body, 1, 2)
	addGlowEffect(body, colors.Glow)

	model.PrimaryPart = base
	return model
end

local function createWaterPump(): Model
	local model = Instance.new("Model")
	model.Name = "WaterPump"

	local colors = CATEGORY_COLORS.Utility

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(5, 1, 5)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = colors.Primary
	base.Parent = model

	-- Tank
	local tank = Instance.new("Part")
	tank.Name = "Tank"
	tank.Size = Vector3.new(4, 6, 4)
	tank.Shape = Enum.PartType.Cylinder
	tank.Anchored = true
	tank.Material = Enum.Material.Metal
	tank.Color = colors.Primary
	tank.CFrame = base.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(90))
	tank.Parent = model

	-- Water indicator
	local water = Instance.new("Part")
	water.Name = "Water"
	water.Size = Vector3.new(3, 3, 3)
	water.Shape = Enum.PartType.Ball
	water.Anchored = true
	water.Material = Enum.Material.Glass
	water.Color = Color3.fromRGB(100, 150, 255)
	water.Transparency = 0.5
	water.CFrame = tank.CFrame
	water.Parent = model

	-- Pipe
	local pipe = Instance.new("Part")
	pipe.Name = "Pipe"
	pipe.Size = Vector3.new(0.5, 5, 0.5)
	pipe.Anchored = true
	pipe.Material = Enum.Material.Metal
	pipe.Color = Color3.fromRGB(100, 100, 100)
	pipe.CFrame = tank.CFrame * CFrame.new(0, 0, 3)
	pipe.Parent = model

	addGlowEffect(water, Color3.fromRGB(150, 200, 255))
	addPulseAnimation(water, 0.05, 1.5)

	model.PrimaryPart = base
	return model
end

-- ═══════════════════════════════════════════════════════════════════════
-- 🎰 POWERUP VENDING MACHINE (Máquina Expendedora de PowerUps)
-- ═══════════════════════════════════════════════════════════════════════
local function createPowerUpVendingMachine(): Model
	local model = Instance.new("Model")
	model.Name = "PowerUpVendingMachine"

	-- Colores vibrantes para powerups
	local machineColors = {
		Primary = Color3.fromRGB(220, 50, 50),     -- Rojo vibrante
		Accent = Color3.fromRGB(255, 215, 0),      -- Dorado
		Glow = Color3.fromRGB(255, 100, 255),      -- Magenta brillante
		Glass = Color3.fromRGB(150, 220, 255),     -- Azul cristal
	}

	-- Base de la máquina
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(5, 1, 4)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = machineColors.Primary
	base.Parent = model

	-- Cuerpo principal
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4.5, 6, 3.5)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = machineColors.Primary
	body.CFrame = base.CFrame * CFrame.new(0, 3.5, 0)
	body.Parent = model

	-- Esfera de cristal (gumball globe)
	local globe = Instance.new("Part")
	globe.Name = "Globe"
	globe.Shape = Enum.PartType.Ball
	globe.Size = Vector3.new(3.5, 3.5, 3.5)
	globe.Anchored = true
	globe.Material = Enum.Material.Glass
	globe.Transparency = 0.3
	globe.Color = machineColors.Glass
	globe.CFrame = body.CFrame * CFrame.new(0, 2, 0)
	globe.Parent = model

	-- PowerUp visual dentro de la esfera (pequeña esfera brillante)
	local powerUpSample = Instance.new("Part")
	powerUpSample.Name = "PowerUpSample"
	powerUpSample.Shape = Enum.PartType.Ball
	powerUpSample.Size = Vector3.new(1.2, 1.2, 1.2)
	powerUpSample.Anchored = true
	powerUpSample.Material = Enum.Material.Neon
	powerUpSample.Color = machineColors.Glow
	powerUpSample.CFrame = globe.CFrame
	powerUpSample.Parent = model

	-- Botón de compra (grande y obvio)
	local button = Instance.new("Part")
	button.Name = "Button"
	button.Shape = Enum.PartType.Cylinder
	button.Size = Vector3.new(0.8, 2, 2) -- Cilindro horizontal
	button.Anchored = true
	button.Material = Enum.Material.Neon
	button.Color = machineColors.Accent
	button.CFrame = body.CFrame * CFrame.new(0, -1, 2) * CFrame.Angles(0, 0, math.rad(90))
	button.Parent = model

	-- ProximityPrompt para interactuar
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PurchasePrompt"
	prompt.ActionText = "Buy PowerUp"
	prompt.ObjectText = "Vending Machine"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = button

	-- Ranura para powerup (donde sale)
	local slot = Instance.new("Part")
	slot.Name = "Slot"
	slot.Size = Vector3.new(2, 0.3, 1.5)
	slot.Anchored = true
	slot.Material = Enum.Material.SmoothPlastic
	slot.Color = Color3.fromRGB(50, 50, 50)
	slot.CFrame = body.CFrame * CFrame.new(0, -2.5, 1.8)
	slot.Parent = model

	-- Letrero "POWER-UPS" en la parte superior
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(4, 1, 0.2)
	sign.Anchored = true
	sign.Material = Enum.Material.Neon
	sign.Color = machineColors.Accent
	sign.CFrame = body.CFrame * CFrame.new(0, 3.5, -1.8)
	sign.Parent = model

	-- Efectos visuales
	addGlowEffect(globe, machineColors.Glow)
	addGlowEffect(button, machineColors.Accent)
	addGlowEffect(sign, machineColors.Accent)

	-- Animaciones
	addRotationAnimation(powerUpSample, 2) -- Rotar la muestra de powerup
	addPulseAnimation(button, 0.15, 1.2) -- Pulsar el botón para llamar atención
	addFloatAnimation(powerUpSample, 0.3, 2) -- Flotar dentro de la esfera

	model.PrimaryPart = base
	return model
end

-------------------------------------------------------------------------
-- PUBLIC API
-------------------------------------------------------------------------

local ModelGenerators = {
	-- Income
	SolarPanel = createSolarPanel,
	WindTurbine = createWindTurbine,
	MinerDrill = createMinerDrill,
	NuclearReactor = createNuclearReactor,

	-- Defense
	ShieldGenerator = createShieldGenerator,
	Turret = createTurret,
	WallSection = createWallSection,

	-- Utility
	StorageContainer = createStorageContainer,
	AutoRepairDrone = createAutoRepairDrone,
	WaterPump = createWaterPump,

	-- 🎰 PowerUps
	PowerUpVendingMachine = createPowerUpVendingMachine,
}

--[[
	Crea un modelo procedural.

	@param modelName string - Nombre del modelo (ver lista arriba)
	@return Model - El modelo creado
]]
function ProceduralModels:CreateModel(modelName: string): Model?
	local generator = ModelGenerators[modelName]
	if not generator then
		warn(("[ProceduralModels] Model '%s' not found"):format(modelName))
		return nil
	end

	local model = generator()

	if DEBUG_MODE then
		print(("[ProceduralModels] Created model: %s"):format(modelName))
	end

	return model
end

--[[
	Retorna lista de modelos disponibles.

	@return {string} - Array de nombres
]]
function ProceduralModels:GetAvailableModels(): {string}
	local models = {}
	for name in pairs(ModelGenerators) do
		table.insert(models, name)
	end
	return models
end

--[[
	Verifica si un modelo existe.

	@param modelName string - Nombre del modelo
	@return boolean - true si existe
]]
function ProceduralModels:ModelExists(modelName: string): boolean
	return ModelGenerators[modelName] ~= nil
end

-------------------------------------------------------------------------
-- INITIALIZATION MESSAGE
-------------------------------------------------------------------------

print("[ProceduralModels] ? Module loaded (" .. #ProceduralModels:GetAvailableModels() .. " models available)")

return ProceduralModels