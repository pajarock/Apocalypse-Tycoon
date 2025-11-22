--!strict
--[[
	AMBIENT EFFECTS - Apocalypse Tycoon (VERSIÓN CORREGIDA)
	Efectos visuales optimizados sin errores de audio
]]

local AmbientEffects = {}

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------
-- PARTÍCULAS GLOBALES
-------------------------------------------------------------------------

local function createGlobalAsh()
	local ashPart = Instance.new("Part")
	ashPart.Name = "AshEmitter"
	ashPart.Size = Vector3.new(1, 1, 1)
	ashPart.Position = Vector3.new(0, 100, 0)
	ashPart.Anchored = true
	ashPart.CanCollide = false
	ashPart.Transparency = 1
	ashPart.Parent = workspace

	local ash = Instance.new("ParticleEmitter")
	ash.Name = "GlobalAsh"
	ash.Color = ColorSequence.new(Color3.fromRGB(80, 70, 60))
	ash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	ash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	ash.Lifetime = NumberRange.new(8, 12)
	ash.Rate = 5
	ash.Speed = NumberRange.new(2, 5)
	ash.SpreadAngle = Vector2.new(180, 180)
	ash.Rotation = NumberRange.new(0, 360)
	ash.RotSpeed = NumberRange.new(-40, 40)
	ash.VelocityInheritance = 0
	ash.Drag = 1
	ash.EmissionDirection = Enum.NormalId.Top
	ash.Parent = ashPart

	print("[EFFECTS] Ceniza global activada")
end

local function createGroundFog()
	local fogFolder = Instance.new("Folder")
	fogFolder.Name = "GroundFog"
	fogFolder.Parent = workspace

	for i = 1, 15 do
		local angle = (i / 15) * math.pi * 2
		local distance = math.random(200, 400)

		local fogPart = Instance.new("Part")
		fogPart.Name = "Fog_" .. i
		fogPart.Size = Vector3.new(60, 15, 60)
		fogPart.Position = Vector3.new(
			math.cos(angle) * distance,
			5,
			math.sin(angle) * distance
		)
		fogPart.Anchored = true
		fogPart.CanCollide = false
		fogPart.Transparency = 1
		fogPart.Parent = fogFolder

		local fog = Instance.new("ParticleEmitter")
		fog.Color = ColorSequence.new(Color3.fromRGB(100, 80, 60))
		fog.Size = NumberSequence.new(30, 50)
		fog.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 0.9),
		})
		fog.Lifetime = NumberRange.new(6, 10)
		fog.Rate = 10
		fog.Speed = NumberRange.new(1, 3)
		fog.SpreadAngle = Vector2.new(30, 30)
		fog.RotSpeed = NumberRange.new(-10, 10)
		fog.ZOffset = -1
		fog.Parent = fogPart
	end

	print("[EFFECTS] Niebla tóxica creada")
end

-------------------------------------------------------------------------
-- EFECTOS DE CALOR
-------------------------------------------------------------------------

local function createHeatWaves()
	local heatFolder = Instance.new("Folder")
	heatFolder.Name = "HeatWaves"
	heatFolder.Parent = workspace

	for i = 1, 20 do
		local angle = (i / 20) * math.pi * 2
		local distance = math.random(250, 450)

		local heatZone = Instance.new("Part")
		heatZone.Name = "Heat_" .. i
		heatZone.Size = Vector3.new(40, 30, 40)
		heatZone.Position = Vector3.new(
			math.cos(angle) * distance,
			15,
			math.sin(angle) * distance
		)
		heatZone.Anchored = true
		heatZone.CanCollide = false
		heatZone.Transparency = 1
		heatZone.Parent = heatFolder

		local heat = Instance.new("ParticleEmitter")
		heat.Texture = "rbxasset://textures/particles/smoke_main.dds"
		heat.Color = ColorSequence.new(Color3.fromRGB(255, 200, 150))
		heat.Size = NumberSequence.new(15, 20)
		heat.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.5, 0.95),
			NumberSequenceKeypoint.new(1, 1),
		})
		heat.Lifetime = NumberRange.new(3, 5)
		heat.Rate = 15
		heat.Speed = NumberRange.new(5, 10)
		heat.SpreadAngle = Vector2.new(20, 20)
		heat.EmissionDirection = Enum.NormalId.Top
		heat.Parent = heatZone
	end

	print("[EFFECTS] Ondas de calor activadas")
end

-------------------------------------------------------------------------
-- RELÁMPAGOS APOCALÍPTICOS
-------------------------------------------------------------------------

local function createLightning()
	task.spawn(function()
		while true do
			task.wait(math.random(15, 30))

			local pos = Vector3.new(
				math.random(-500, 500),
				200,
				math.random(-500, 500)
			)

			local flash = Instance.new("Part")
			flash.Name = "Lightning"
			flash.Size = Vector3.new(3, 200, 3)
			flash.Position = pos
			flash.Anchored = true
			flash.CanCollide = false
			flash.Material = Enum.Material.Neon
			flash.Color = Color3.fromRGB(255, 50, 50)
			flash.Transparency = 0
			flash.Parent = workspace

			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 100, 100)
			light.Brightness = 10
			light.Range = 300
			light.Parent = flash

			local tween = TweenService:Create(
				flash,
				TweenInfo.new(0.3, Enum.EasingStyle.Linear),
				{Transparency = 1}
			)
			tween:Play()

			Debris:AddItem(flash, 1)
		end
	end)

	print("[EFFECTS] Sistema de relámpagos iniciado")
end

-------------------------------------------------------------------------
-- CRISTALES MÍSTICOS
-------------------------------------------------------------------------

local function createFloatingCrystals()
	local crystalsFolder = Instance.new("Folder")
	crystalsFolder.Name = "FloatingCrystals"
	crystalsFolder.Parent = workspace

	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local distance = math.random(300, 500)

		local crystal = Instance.new("Part")
		crystal.Name = "Crystal_" .. i
		crystal.Size = Vector3.new(4, 12, 4)
		crystal.Position = Vector3.new(
			math.cos(angle) * distance,
			50 + math.random(-10, 20),
			math.sin(angle) * distance
		)
		crystal.Anchored = true
		crystal.CanCollide = false
		crystal.Material = Enum.Material.Neon
		crystal.Color = Color3.fromRGB(150, 255, 255)
		crystal.Transparency = 0.3
		crystal.Shape = Enum.PartType.Cylinder
		crystal.Orientation = Vector3.new(
			math.random(-30, 30),
			math.random(0, 360),
			math.random(-30, 30)
		)
		crystal.Parent = crystalsFolder

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(150, 255, 255)
		light.Brightness = 5
		light.Range = 80
		light.Parent = crystal

		task.spawn(function()
			local startPos = crystal.Position
			while crystal.Parent do
				local newY = startPos.Y + math.sin(tick() + i) * 5
				crystal.Position = Vector3.new(startPos.X, newY, startPos.Z)
				crystal.Orientation = crystal.Orientation + Vector3.new(0, 0.5, 0)
				task.wait(0.03)
			end
		end)

		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(Color3.fromRGB(150, 255, 255))
		sparkles.Size = NumberSequence.new(0.3, 0)
		sparkles.Transparency = NumberSequence.new(0, 1)
		sparkles.Lifetime = NumberRange.new(1, 2)
		sparkles.Rate = 20
		sparkles.Speed = NumberRange.new(2, 5)
		sparkles.SpreadAngle = Vector2.new(360, 360)
		sparkles.Parent = crystal
	end

	print("[EFFECTS] Cristales místicos creados")
end

-------------------------------------------------------------------------
-- EFECTOS DE LAVA MEJORADOS
-------------------------------------------------------------------------

local function createLavaBubbles()
	task.spawn(function()
		while true do
			task.wait(math.random(3, 6))

			local pos = Vector3.new(
				math.random(-800, 800),
				-3,
				math.random(-800, 800)
			)

			local bubble = Instance.new("Part")
			bubble.Name = "LavaBubble"
			bubble.Size = Vector3.new(2, 2, 2)
			bubble.Position = pos
			bubble.Shape = Enum.PartType.Ball
			bubble.Material = Enum.Material.Neon
			bubble.Color = Color3.fromRGB(255, 100, 0)
			bubble.Anchored = true
			bubble.CanCollide = false
			bubble.Parent = workspace

			local growTween = TweenService:Create(
				bubble,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad),
				{Size = Vector3.new(6, 6, 6)}
			)
			growTween:Play()

			task.wait(0.5)

			local explosion = Instance.new("ParticleEmitter")
			explosion.Color = ColorSequence.new(Color3.fromRGB(255, 150, 0))
			explosion.Size = NumberSequence.new(2, 0)
			explosion.Transparency = NumberSequence.new(0, 1)
			explosion.Lifetime = NumberRange.new(0.5, 1)
			explosion.Rate = 100
			explosion.Speed = NumberRange.new(10, 20)
			explosion.SpreadAngle = Vector2.new(180, 180)
			explosion.Parent = bubble
			explosion.Enabled = true

			task.wait(0.1)
			explosion.Enabled = false

			Debris:AddItem(bubble, 2)
		end
	end)

	print("[EFFECTS] Burbujas de lava activadas")
end

-------------------------------------------------------------------------
-- POST-PROCESSING
-------------------------------------------------------------------------

local function setupPostProcessing()
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 0.8

	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
	end
	cc.Saturation = 0.1
	cc.TintColor = Color3.fromRGB(255, 200, 180)
	cc.Contrast = 0.1
	cc.Brightness = 0.05

	local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if not sunrays then
		sunrays = Instance.new("SunRaysEffect")
		sunrays.Parent = Lighting
	end
	sunrays.Intensity = 0.15
	sunrays.Spread = 0.4

	print("[EFFECTS] Post-processing configurado")
end

-------------------------------------------------------------------------
-- API PÚBLICA
-------------------------------------------------------------------------

function AmbientEffects.EnableAll()
	print("[EFFECTS] Activando todos los efectos ambientales...")

	createGlobalAsh()
	createGroundFog()
	createHeatWaves()
	createLightning()
	createFloatingCrystals()
	createLavaBubbles()
	setupPostProcessing()

	print("[EFFECTS] ? Todos los efectos activados")
end

function AmbientEffects.DisableAll()
	local effectsFolders = {
		"GroundFog",
		"HeatWaves",
		"FloatingCrystals",
	}

	for _, folderName in ipairs(effectsFolders) do
		local folder = workspace:FindFirstChild(folderName)
		if folder then
			folder:Destroy()
		end
	end

	local ashEmitter = workspace:FindFirstChild("AshEmitter")
	if ashEmitter then
		ashEmitter:Destroy()
	end

	Lighting.Ambient = Color3.fromRGB(138, 138, 138)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	Lighting.Brightness = 2
	Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
	Lighting.ColorShift_Top = Color3.new(0, 0, 0)

	print("[EFFECTS] Efectos desactivados")
end

function AmbientEffects.EnablePerformanceMode()
	print("[EFFECTS] Modo performance activado")

	createGlobalAsh()
	setupPostProcessing()

	for _, emitter in ipairs(workspace:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Rate = math.floor(emitter.Rate * 0.5)
		end
	end
end

return AmbientEffects