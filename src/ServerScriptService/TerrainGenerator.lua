--!strict
--[[
	TERRAIN GENERATOR - Apocalypse Tycoon (VERSIÃN CORREGIDA)
	Genera un mapa apocalÃ­ptico prehispÃ¡nico con lava y montaÃ±as
]]

local TerrainGenerator = {}

local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

-------------------------------------------------------------------------
-- CONFIGURACIÃN DEL MAPA
-------------------------------------------------------------------------

local MAP_CONFIG = {
	MapSize = 2000,
	CenterRadius = 300,

	MountainCount = 20,  -- Reducido para mejor rendimiento
	MountainHeightMin = 60,
	MountainHeightMax = 150,
	MountainRadiusMin = 30,
	MountainRadiusMax = 80,

	LavaLevel = -5,
	LavaDamage = 50,
	LavaColor = Color3.fromRGB(255, 80, 0),

	PlatformHeight = 15,
	PlatformRadius = 70,

	RuinsCount = 10,  -- Reducido
	PillarCount = 20, -- Reducido

	Colors = {
		Stone = Color3.fromRGB(60, 50, 45),
		DarkStone = Color3.fromRGB(30, 25, 20),
		Obsidian = Color3.fromRGB(20, 15, 15),
		Sand = Color3.fromRGB(120, 100, 80),
		Moss = Color3.fromRGB(80, 100, 60),
	}
}

-------------------------------------------------------------------------
-- UTILIDADES
-------------------------------------------------------------------------

local function createPart(name: string, size: Vector3, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function randomPosition(radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius
	return Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)
end

local function perlinNoise(x: number, z: number, scale: number): number
	local noise = math.noise(x * scale, z * scale, 0)
	return (noise + 1) * 0.5
end

-------------------------------------------------------------------------
-- GENERACIÃN DE MONTAÃAS
-------------------------------------------------------------------------

local function createMountain(position: Vector3, height: number, radius: number, mapFolder: Folder)
	local mountainFolder = Instance.new("Folder")
	mountainFolder.Name = "Mountain_" .. tostring(math.random(1000, 9999))
	mountainFolder.Parent = mapFolder

	local layers = math.floor(height / 10)

	for i = 1, layers do
		local layerHeight = height * (1 - i/layers)
		local layerRadius = radius * (1 - i/(layers * 1.5))

		local layer = createPart(
			"Layer_" .. i,
			Vector3.new(layerRadius * 2, 10, layerRadius * 2),
			MAP_CONFIG.Colors.DarkStone,
			Enum.Material.Rock
		)

		local noiseValue = perlinNoise(position.X, position.Z, 0.05)
		if noiseValue > 0.6 then
			layer.Color = MAP_CONFIG.Colors.Obsidian
		elseif noiseValue > 0.3 then
			layer.Color = MAP_CONFIG.Colors.Stone
		end

		layer.Position = position + Vector3.new(0, layerHeight, 0)
		layer.Parent = mountainFolder

		if i % 3 == 0 then
			local rock = createPart(
				"Rock",
				Vector3.new(math.random(10, 20), math.random(10, 20), math.random(10, 20)),
				MAP_CONFIG.Colors.Obsidian,
				Enum.Material.Slate
			)
			rock.Position = layer.Position + Vector3.new(
				math.random(-layerRadius, layerRadius),
				10,
				math.random(-layerRadius, layerRadius)
			)
			rock.Rotation = Vector3.new(
				math.random(-30, 30),
				math.random(0, 360),
				math.random(-30, 30)
			)
			rock.Parent = mountainFolder
		end
	end

	local peak = createPart(
		"Peak",
		Vector3.new(radius * 0.3, height * 0.2, radius * 0.3),
		MAP_CONFIG.Colors.Obsidian,
		Enum.Material.Basalt
	)
	peak.Position = position + Vector3.new(0, height + 10, 0)
	peak.Shape = Enum.PartType.Cylinder
	peak.Orientation = Vector3.new(0, 0, 90)
	peak.Parent = mountainFolder

	if math.random() > 0.5 then
		local lavaGlow = Instance.new("PointLight")
		lavaGlow.Color = MAP_CONFIG.LavaColor
		lavaGlow.Brightness = 3
		lavaGlow.Range = 80
		lavaGlow.Parent = peak

		local crater = createPart(
			"Crater",
			Vector3.new(radius * 0.4, 5, radius * 0.4),
			MAP_CONFIG.LavaColor,
			Enum.Material.Neon
		)
		crater.Position = peak.Position + Vector3.new(0, -5, 0)
		crater.Parent = mountainFolder
	end

	return mountainFolder
end

-------------------------------------------------------------------------
-- LAVA Y PELIGROS
-------------------------------------------------------------------------

local function createLavaOcean(mapFolder: Folder)
	local lavaFolder = Instance.new("Folder")
	lavaFolder.Name = "LavaOcean"
	lavaFolder.Parent = mapFolder

	local sections = 20
	local sectionSize = MAP_CONFIG.MapSize / sections

	for x = 1, sections do
		for z = 1, sections do
			local posX = (x - sections/2) * sectionSize
			local posZ = (z - sections/2) * sectionSize

			local lava = createPart(
				"Lava",
				Vector3.new(sectionSize, 10, sectionSize),
				MAP_CONFIG.LavaColor,
				Enum.Material.Neon
			)
			lava.Position = Vector3.new(posX, MAP_CONFIG.LavaLevel, posZ)
			lava.CanCollide = false
			lava.Transparency = 0.3
			lava.Parent = lavaFolder

			lava.Touched:Connect(function(hit)
				if not hit.Parent then return end
				local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid:TakeDamage(MAP_CONFIG.LavaDamage)

					local fire = Instance.new("Fire")
					fire.Size = 10
					fire.Heat = 15
					fire.Parent = hit
					Debris:AddItem(fire, 3)
				end
			end)

			local light = Instance.new("PointLight")
			light.Color = MAP_CONFIG.LavaColor
			light.Brightness = 2
			light.Range = 60
			light.Parent = lava
		end
	end

	print("[TERRAIN] OcÃ©ano de lava creado")
end

-------------------------------------------------------------------------
-- PLATAFORMAS PARA BASES
-------------------------------------------------------------------------

local function createBasePlatform(position: Vector3, playerName: string, mapFolder: Folder): BasePart
	local platformFolder = Instance.new("Folder")
	platformFolder.Name = "Platform_" .. playerName
	platformFolder.Parent = mapFolder

	local platform = createPart(
		"BasePlate",
		Vector3.new(MAP_CONFIG.PlatformRadius * 2, 2, MAP_CONFIG.PlatformRadius * 2),
		MAP_CONFIG.Colors.Stone,
		Enum.Material.Slate
	)
	platform.Position = position + Vector3.new(0, MAP_CONFIG.PlatformHeight, 0)
	platform.Parent = platformFolder

	local borderSize = 3
	local sides = 12

	for i = 1, sides do
		local angle = (i / sides) * math.pi * 2
		local nextAngle = ((i + 1) / sides) * math.pi * 2

		local x1 = math.cos(angle) * MAP_CONFIG.PlatformRadius
		local z1 = math.sin(angle) * MAP_CONFIG.PlatformRadius
		local x2 = math.cos(nextAngle) * MAP_CONFIG.PlatformRadius
		local z2 = math.sin(nextAngle) * MAP_CONFIG.PlatformRadius

		local midX = (x1 + x2) / 2
		local midZ = (z1 + z2) / 2
		local length = math.sqrt((x2-x1)^2 + (z2-z1)^2)

		local border = createPart(
			"Border_" .. i,
			Vector3.new(length, 8, borderSize),
			MAP_CONFIG.Colors.Obsidian,
			Enum.Material.Granite
		)
		border.Position = platform.Position + Vector3.new(midX, 3, midZ)
		border.Orientation = Vector3.new(0, math.deg(angle) + 90, 0)
		border.Parent = platformFolder
	end

	local pillarPositions = {
		Vector3.new(MAP_CONFIG.PlatformRadius - 10, 0, MAP_CONFIG.PlatformRadius - 10),
		Vector3.new(-(MAP_CONFIG.PlatformRadius - 10), 0, MAP_CONFIG.PlatformRadius - 10),
		Vector3.new(MAP_CONFIG.PlatformRadius - 10, 0, -(MAP_CONFIG.PlatformRadius - 10)),
		Vector3.new(-(MAP_CONFIG.PlatformRadius - 10), 0, -(MAP_CONFIG.PlatformRadius - 10)),
	}

	for _, offset in ipairs(pillarPositions) do
		local pillar = createPart(
			"Pillar",
			Vector3.new(4, 20, 4),
			MAP_CONFIG.Colors.Obsidian,
			Enum.Material.Marble
		)
		pillar.Position = platform.Position + offset + Vector3.new(0, 10, 0)
		pillar.Parent = platformFolder

		local torch = createPart(
			"Torch",
			Vector3.new(2, 3, 2),
			Color3.fromRGB(139, 69, 19),
			Enum.Material.Wood
		)
		torch.Position = pillar.Position + Vector3.new(0, 12, 0)
		torch.Parent = platformFolder

		local flame = Instance.new("Fire")
		flame.Size = 8
		flame.Heat = 10
		flame.Parent = torch

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 50)
		light.Brightness = 3
		light.Range = 40
		light.Parent = torch
	end

	local ramp = createPart(
		"Ramp",
		Vector3.new(20, 2, 30),
		MAP_CONFIG.Colors.Stone,
		Enum.Material.Cobblestone
	)
	ramp.Position = platform.Position + Vector3.new(0, -7, MAP_CONFIG.PlatformRadius + 15)
	ramp.Orientation = Vector3.new(-15, 0, 0)
	ramp.Parent = platformFolder

	return platform
end

-------------------------------------------------------------------------
-- DECORACIÃN PREHISPÃNICA
-------------------------------------------------------------------------

local function createRuins(mapFolder: Folder)
	local ruinsFolder = Instance.new("Folder")
	ruinsFolder.Name = "Ruins"
	ruinsFolder.Parent = mapFolder

	for i = 1, MAP_CONFIG.RuinsCount do
		local pos = randomPosition(MAP_CONFIG.MapSize * 0.4)
		pos = Vector3.new(pos.X, MAP_CONFIG.PlatformHeight + 20, pos.Z)

		local levels = math.random(3, 5)
		for level = 1, levels do
			local size = (levels - level + 1) * 12
			local ruin = createPart(
				"Ruin_" .. level,
				Vector3.new(size, 8, size),
				MAP_CONFIG.Colors.Stone,
				Enum.Material.Slate
			)
			ruin.Position = pos + Vector3.new(0, (level - 1) * 8, 0)
			ruin.Parent = ruinsFolder

			if math.random() > 0.5 then
				ruin.Color = MAP_CONFIG.Colors.Moss
			end
		end
	end

	print("[TERRAIN] Ruinas creadas")
end

local function createPillars(mapFolder: Folder)
	local pillarsFolder = Instance.new("Folder")
	pillarsFolder.Name = "AncientPillars"
	pillarsFolder.Parent = mapFolder

	for i = 1, MAP_CONFIG.PillarCount do
		local pos = randomPosition(MAP_CONFIG.MapSize * 0.45)
		pos = Vector3.new(pos.X, MAP_CONFIG.PlatformHeight, pos.Z)

		local height = math.random(25, 60)
		local pillar = createPart(
			"Pillar",
			Vector3.new(5, height, 5),
			MAP_CONFIG.Colors.Obsidian,
			Enum.Material.Granite
		)
		pillar.Position = pos + Vector3.new(0, height/2, 0)
		pillar.Rotation = Vector3.new(
			math.random(-5, 5),
			math.random(0, 360),
			math.random(-5, 5)
		)
		pillar.Parent = pillarsFolder

		if math.random() > 0.7 then
			local crystal = createPart(
				"Crystal",
				Vector3.new(3, 6, 3),
				Color3.fromRGB(150, 255, 255),
				Enum.Material.Neon
			)
			crystal.Position = pillar.Position + Vector3.new(0, height/2 + 5, 0)
			crystal.Shape = Enum.PartType.Ball
			crystal.Parent = pillarsFolder

			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(150, 255, 255)
			light.Brightness = 5
			light.Range = 50
			light.Parent = crystal
		end
	end

	print("[TERRAIN] Pilares antiguos creados")
end

-------------------------------------------------------------------------
-- ILUMINACIÃN Y ATMÃSFERA
-------------------------------------------------------------------------

local function setupLighting()
	Lighting.Ambient = Color3.fromRGB(100, 50, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 60, 40)
	Lighting.Brightness = 1.5
	Lighting.ColorShift_Bottom = Color3.fromRGB(255, 100, 50)
	Lighting.ColorShift_Top = Color3.fromRGB(200, 80, 60)

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.4
	atmosphere.Offset = 0.3
	atmosphere.Color = Color3.fromRGB(255, 120, 80)
	atmosphere.Decay = Color3.fromRGB(200, 100, 50)
	atmosphere.Glare = 0.5
	atmosphere.Haze = 2

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end

	Lighting.TimeOfDay = "17:00:00"
	Lighting.GeographicLatitude = 0

	print("[TERRAIN] IluminaciÃ³n configurada")
end

-------------------------------------------------------------------------
-- API PÃBLICA
-------------------------------------------------------------------------

function TerrainGenerator.GenerateMap(): Folder
	local mapFolder = workspace:FindFirstChild("ApocalypticMap")
	if mapFolder then
		mapFolder:Destroy()
	end

	mapFolder = Instance.new("Folder")
	mapFolder.Name = "ApocalypticMap"
	mapFolder.Parent = workspace

	print("[TERRAIN] Iniciando generaciÃ³n del mapa...")

	createLavaOcean(mapFolder)

	print("[TERRAIN] Generando montaÃ±as...")
	local mountainsFolder = Instance.new("Folder")
	mountainsFolder.Name = "Mountains"
	mountainsFolder.Parent = mapFolder

	for i = 1, MAP_CONFIG.MountainCount do
		local pos = randomPosition(MAP_CONFIG.MapSize * 0.4)
		if pos.Magnitude > MAP_CONFIG.CenterRadius then
			local height = math.random(MAP_CONFIG.MountainHeightMin, MAP_CONFIG.MountainHeightMax)
			local radius = math.random(MAP_CONFIG.MountainRadiusMin, MAP_CONFIG.MountainRadiusMax)
			createMountain(Vector3.new(pos.X, 0, pos.Z), height, radius, mountainsFolder)
		end
	end

	createRuins(mapFolder)
	createPillars(mapFolder)
	setupLighting()

	print("[TERRAIN] ? Mapa generado exitosamente")
	return mapFolder
end

function TerrainGenerator.CreatePlayerPlatform(position: Vector3, playerName: string): BasePart
	local mapFolder = workspace:FindFirstChild("ApocalypticMap")
	if not mapFolder then
		mapFolder = Instance.new("Folder")
		mapFolder.Name = "ApocalypticMap"
		mapFolder.Parent = workspace
	end

	return createBasePlatform(position, playerName, mapFolder)
end

function TerrainGenerator.ClearMap()
	local mapFolder = workspace:FindFirstChild("ApocalypticMap")
	if mapFolder then
		mapFolder:Destroy()
		print("[TERRAIN] Mapa limpiado")
	end
end

function TerrainGenerator.GetSafeHeight(position: Vector2): number
	return MAP_CONFIG.PlatformHeight + 2
end

return TerrainGenerator