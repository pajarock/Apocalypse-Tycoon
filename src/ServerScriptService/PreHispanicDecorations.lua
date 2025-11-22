--!strict
--[[
	DECORACIONES PREHISPÃÂNICAS - Apocalypse Tycoon
	Estatuas, glifos, altares y elementos culturales
	
	INSPIRACIÃÂN:
	- Cultura Maya: PirÃÂ¡mides, estelas, calendarios
	- Cultura Azteca: Templos, guerreros, serpientes emplumadas
	- Cultura Inca: Muros de piedra, terrazas
]]

local PreHispanicDecorations = {}

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------
-- CONFIGURACIÃÂN
-------------------------------------------------------------------------

local DECO_CONFIG = {
	Colors = {
		Stone = Color3.fromRGB(60, 50, 45),
		OldStone = Color3.fromRGB(80, 70, 60),
		GoldAccent = Color3.fromRGB(255, 200, 50),
		Jade = Color3.fromRGB(50, 150, 100),
		Obsidian = Color3.fromRGB(20, 15, 15),
		Turquoise = Color3.fromRGB(80, 200, 200),
	},

	-- IDs de texturas (reemplazar con assets propios)
	Textures = {
		Glyph1 = "rbxassetid://7229442422",
		Glyph2 = "rbxassetid://7229442422",
		Hieroglyph = "rbxassetid://7229442422",
		Pattern = "rbxassetid://7229442422",
	}
}

-------------------------------------------------------------------------
-- ESTATUAS DE GUERREROS
-------------------------------------------------------------------------

local function createWarriorStatue(position: Vector3): Model
	local statue = Instance.new("Model")
	statue.Name = "WarriorStatue"

	-- Base/pedestal
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(8, 4, 8)
	base.Position = position
	base.Anchored = true
	base.Material = Enum.Material.Slate
	base.Color = DECO_CONFIG.Colors.OldStone
	base.Parent = statue

	-- Placa con glifos
	local plaque = Instance.new("Part")
	plaque.Name = "Plaque"
	plaque.Size = Vector3.new(7, 3, 0.5)
	plaque.Position = base.Position + Vector3.new(0, -0.5, 4)
	plaque.Anchored = true
	plaque.Material = Enum.Material.Marble
	plaque.Color = DECO_CONFIG.Colors.Stone
	plaque.Parent = statue

	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = plaque

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = "?? GUERRERO JAGUAR\n? ÃÂ¦ ? ?"  -- SÃÂ­mbolos pseudo-maya
	text.TextColor3 = DECO_CONFIG.Colors.GoldAccent
	text.TextScaled = true
	text.Font = Enum.Font.Bodoni
	text.Parent = surface

	-- Cuerpo de la estatua
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(4, 8, 3)
	torso.Position = base.Position + Vector3.new(0, 6, 0)
	torso.Anchored = true
	torso.Material = Enum.Material.Concrete
	torso.Color = DECO_CONFIG.Colors.Stone
	torso.Parent = statue

	-- Cabeza
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(3.5, 4, 3.5)
	head.Position = torso.Position + Vector3.new(0, 6, 0)
	head.Anchored = true
	head.Material = Enum.Material.Concrete
	head.Color = DECO_CONFIG.Colors.Stone
	head.Parent = statue

	-- Casco/mÃÂ¡scara (esfera dorada)
	local helmet = Instance.new("Part")
	helmet.Name = "Helmet"
	helmet.Size = Vector3.new(4, 3, 4)
	helmet.Position = head.Position + Vector3.new(0, 2, 0)
	helmet.Shape = Enum.PartType.Ball
	helmet.Anchored = true
	helmet.Material = Enum.Material.Neon
	helmet.Color = DECO_CONFIG.Colors.GoldAccent
	helmet.Parent = statue

	-- Luz dramÃÂ¡tica
	local light = Instance.new("SpotLight")
	light.Brightness = 5
	light.Range = 40
	light.Color = DECO_CONFIG.Colors.GoldAccent
	light.Face = Enum.NormalId.Top
	light.Angle = 60
	light.Parent = helmet

	statue.PrimaryPart = base
	return statue
end

-------------------------------------------------------------------------
-- SERPIENTE EMPLUMADA (QUETZALCÃÂATL)
-------------------------------------------------------------------------

local function createFeatheredSerpent(position: Vector3): Model
	local serpent = Instance.new("Model")
	serpent.Name = "FeatheredSerpent"

	-- Cuerpo ondulante (varios segmentos)
	local segments = 8
	for i = 1, segments do
		local segment = Instance.new("Part")
		segment.Name = "Segment_" .. i
		segment.Size = Vector3.new(3, 3, 5)
		segment.Shape = Enum.PartType.Cylinder

		-- PosiciÃÂ³n ondulante
		local angle = (i / segments) * math.pi
		local height = math.sin(angle) * 10
		segment.Position = position + Vector3.new(
			i * 5,
			5 + height,
			0
		)

		segment.Orientation = Vector3.new(0, 0, 90 + (height * 3))
		segment.Anchored = true
		segment.Material = Enum.Material.Slate
		segment.Color = DECO_CONFIG.Colors.Jade
		segment.Parent = serpent

		-- Plumas (partÃÂ­culas)
		if i % 2 == 0 then
			local feathers = Instance.new("ParticleEmitter")
			feathers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			feathers.Color = ColorSequence.new(DECO_CONFIG.Colors.Turquoise)
			feathers.Size = NumberSequence.new(2, 0)
			feathers.Transparency = NumberSequence.new(0.3, 1)
			feathers.Lifetime = NumberRange.new(1, 2)
			feathers.Rate = 5
			feathers.Speed = NumberRange.new(2, 5)
			feathers.SpreadAngle = Vector2.new(30, 30)
			feathers.Parent = segment
		end
	end

	-- Cabeza de serpiente
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(5, 5, 7)
	head.Position = position + Vector3.new(segments * 5 + 5, 8, 0)
	head.Anchored = true
	head.Material = Enum.Material.Marble
	head.Color = DECO_CONFIG.Colors.GoldAccent
	head.Parent = serpent

	-- Ojos brillantes
	for _, xOffset in ipairs({-1.5, 1.5}) do
		local eye = Instance.new("Part")
		eye.Size = Vector3.new(0.8, 0.8, 0.8)
		eye.Position = head.Position + Vector3.new(xOffset, 0.5, 3)
		eye.Shape = Enum.PartType.Ball
		eye.Anchored = true
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255, 50, 50)
		eye.Parent = serpent

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 50, 50)
		light.Brightness = 5
		light.Range = 20
		light.Parent = eye
	end

	-- AnimaciÃÂ³n de flotaciÃÂ³n
	task.spawn(function()
		local startCF = serpent:GetPivot()
		while serpent.Parent do
			local newY = startCF.Position.Y + math.sin(tick() * 0.5) * 2
			serpent:PivotTo(CFrame.new(startCF.Position.X, newY, startCF.Position.Z) * startCF.Rotation)
			task.wait(0.03)
		end
	end)

	return serpent
end

-------------------------------------------------------------------------
-- ALTAR DE SACRIFICIOS
-------------------------------------------------------------------------

local function createSacrificeAltar(position: Vector3): Model
	local altar = Instance.new("Model")
	altar.Name = "SacrificeAltar"

	-- Plataforma principal
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(12, 3, 12)
	platform.Position = position
	platform.Anchored = true
	platform.Material = Enum.Material.Slate
	platform.Color = DECO_CONFIG.Colors.Obsidian
	platform.Parent = altar

	-- Escalones
	for i = 1, 4 do
		local step = Instance.new("Part")
		step.Name = "Step_" .. i
		step.Size = Vector3.new(14 + (i * 2), 1.5, 3)
		step.Position = platform.Position + Vector3.new(0, -1.5 - (i * 1.5), 7 + (i * 1.5))
		step.Anchored = true
		step.Material = Enum.Material.Cobblestone
		step.Color = DECO_CONFIG.Colors.Stone
		step.Parent = altar
	end

	-- Mesa de altar
	local table = Instance.new("Part")
	table.Name = "AltarTable"
	table.Size = Vector3.new(6, 2, 4)
	table.Position = platform.Position + Vector3.new(0, 2.5, 0)
	table.Anchored = true
	table.Material = Enum.Material.Marble
	table.Color = DECO_CONFIG.Colors.Stone
	table.Parent = altar

	-- Antorchas en las esquinas
	local torchPositions = {
		Vector3.new(5, 0, 5),
		Vector3.new(-5, 0, 5),
		Vector3.new(5, 0, -5),
		Vector3.new(-5, 0, -5),
	}

	for _, offset in ipairs(torchPositions) do
		local torch = Instance.new("Part")
		torch.Name = "Torch"
		torch.Size = Vector3.new(1, 5, 1)
		torch.Position = platform.Position + offset + Vector3.new(0, 2.5, 0)
		torch.Anchored = true
		torch.Material = Enum.Material.Wood
		torch.Color = Color3.fromRGB(80, 50, 30)
		torch.Parent = altar

		-- Fuego
		local fire = Instance.new("Fire")
		fire.Size = 10
		fire.Heat = 15
		fire.Color = Color3.fromRGB(255, 150, 0)
		fire.SecondaryColor = Color3.fromRGB(255, 50, 0)
		fire.Parent = torch

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 150, 50)
		light.Brightness = 5
		light.Range = 40
		light.Parent = torch
	end

	-- CrÃÂ¡neo decorativo (sÃÂ­mbolo de muerte)
	local skull = Instance.new("Part")
	skull.Name = "Skull"
	skull.Size = Vector3.new(2, 2, 2)
	skull.Position = table.Position + Vector3.new(0, 1.5, 0)
	skull.Shape = Enum.PartType.Ball
	skull.Anchored = true
	skull.Material = Enum.Material.Marble
	skull.Color = Color3.fromRGB(200, 200, 200)
	skull.Parent = altar

	-- PartÃÂ­culas mÃÂ­sticas
	local mystic = Instance.new("ParticleEmitter")
	mystic.Color = ColorSequence.new(Color3.fromRGB(150, 50, 200))
	mystic.Size = NumberSequence.new(1, 0)
	mystic.Transparency = NumberSequence.new(0, 1)
	mystic.Lifetime = NumberRange.new(2, 4)
	mystic.Rate = 10
	mystic.Speed = NumberRange.new(2, 5)
	mystic.SpreadAngle = Vector2.new(30, 30)
	mystic.EmissionDirection = Enum.NormalId.Top
	mystic.Parent = table

	altar.PrimaryPart = platform
	return altar
end

-------------------------------------------------------------------------
-- ESTELAS CON GLIFOS
-------------------------------------------------------------------------

local function createGlyphStele(position: Vector3): Model
	local stele = Instance.new("Model")
	stele.Name = "GlyphStele"

	-- Pilar principal
	local pillar = Instance.new("Part")
	pillar.Name = "Pillar"
	pillar.Size = Vector3.new(3, 15, 1)
	pillar.Position = position + Vector3.new(0, 7.5, 0)
	pillar.Anchored = true
	pillar.Material = Enum.Material.Slate
	pillar.Color = DECO_CONFIG.Colors.OldStone
	pillar.Parent = stele

	-- Panel frontal con glifos
	local panel = Instance.new("Part")
	panel.Name = "GlyphPanel"
	panel.Size = Vector3.new(2.8, 14, 0.2)
	panel.Position = pillar.Position + Vector3.new(0, 0, 0.6)
	panel.Anchored = true
	panel.Material = Enum.Material.Marble
	panel.Color = DECO_CONFIG.Colors.Stone
	panel.Parent = stele

	-- AÃÂ±adir glifos usando SurfaceGui
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.Parent = panel

	-- Crear cuadrÃÂ­cula de sÃÂ­mbolos
	local glyphText = [[
		? ÃÂ¤ ?
		ÃÂ¦ ? ÃÂ¦
		? ? ?
		
		ÃÂ¤ CALENDARIO ÃÂ¤
		
		?ÃÂ¦???
		
		? ? ?
	]]

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = glyphText
	label.TextColor3 = DECO_CONFIG.Colors.GoldAccent
	label.TextScaled = true
	label.Font = Enum.Font.Bodoni
	label.Parent = surface

	-- Base de la estela
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 2, 4)
	base.Position = position
	base.Anchored = true
	base.Material = Enum.Material.Granite
	base.Color = DECO_CONFIG.Colors.Obsidian
	base.Parent = stele

	-- Luz mÃÂ­stica
	local light = Instance.new("PointLight")
	light.Color = DECO_CONFIG.Colors.GoldAccent
	light.Brightness = 3
	light.Range = 30
	light.Parent = panel

	stele.PrimaryPart = pillar
	return stele
end

-------------------------------------------------------------------------
-- CALENDARIO SOLAR
-------------------------------------------------------------------------

local function createSolarCalendar(position: Vector3): Model
	local calendar = Instance.new("Model")
	calendar.Name = "SolarCalendar"

	-- Disco principal
	local disc = Instance.new("Part")
	disc.Name = "CalendarDisc"
	disc.Size = Vector3.new(12, 2, 12)
	disc.Position = position + Vector3.new(0, 8, 0)
	disc.Shape = Enum.PartType.Cylinder
	disc.Orientation = Vector3.new(0, 0, 90)
	disc.Anchored = true
	disc.Material = Enum.Material.Slate
	disc.Color = DECO_CONFIG.Colors.Stone
	disc.Parent = calendar

	-- Centro del calendario (sol)
	local sun = Instance.new("Part")
	sun.Name = "Sun"
	sun.Size = Vector3.new(4, 4, 4)
	sun.Position = disc.Position
	sun.Shape = Enum.PartType.Ball
	sun.Anchored = true
	sun.Material = Enum.Material.Neon
	sun.Color = DECO_CONFIG.Colors.GoldAccent
	sun.Parent = calendar

	local sunLight = Instance.new("PointLight")
	sunLight.Color = DECO_CONFIG.Colors.GoldAccent
	sunLight.Brightness = 10
	sunLight.Range = 60
	sunLight.Parent = sun

	-- Rayos del sol (12 direcciones)
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local ray = Instance.new("Part")
		ray.Name = "Ray_" .. i
		ray.Size = Vector3.new(0.5, 3, 0.5)
		ray.Position = disc.Position + Vector3.new(
			math.cos(angle) * 5,
			0,
			math.sin(angle) * 5
		)
		ray.Anchored = true
		ray.Material = Enum.Material.Neon
		ray.Color = DECO_CONFIG.Colors.GoldAccent
		ray.Orientation = Vector3.new(0, math.deg(angle), 0)
		ray.Parent = calendar
	end

	-- AnimaciÃÂ³n de rotaciÃÂ³n
	task.spawn(function()
		while calendar.Parent do
			disc.Orientation = disc.Orientation + Vector3.new(0, 0, 0.2)
			task.wait(0.03)
		end
	end)

	-- Pedestal
	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Size = Vector3.new(6, 8, 6)
	pedestal.Position = position + Vector3.new(0, 4, 0)
	pedestal.Anchored = true
	pedestal.Material = Enum.Material.Granite
	pedestal.Color = DECO_CONFIG.Colors.Obsidian
	pedestal.Parent = calendar

	calendar.PrimaryPart = disc
	return calendar
end

-------------------------------------------------------------------------
-- API PÃÂBLICA
-------------------------------------------------------------------------

function PreHispanicDecorations.PlaceAll(mapFolder: Folder)
	local decoFolder = Instance.new("Folder")
	decoFolder.Name = "PreHispanicDecorations"
	decoFolder.Parent = mapFolder

	print("[DECO] Colocando decoraciones prehispÃÂ¡nicas...")

	-- Distribuir estatuas en cÃÂ­rculo
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local distance = 300
		local pos = Vector3.new(
			math.cos(angle) * distance,
			15,
			math.sin(angle) * distance
		)

		local statue = createWarriorStatue(pos)
		statue.Parent = decoFolder
	end

	-- Serpiente emplumada (2 grandes)
	for i = 1, 2 do
		local angle = (i / 2) * math.pi
		local serpent = createFeatheredSerpent(Vector3.new(
			math.cos(angle) * 400,
			30,
			math.sin(angle) * 400
			))
		serpent.Parent = decoFolder
	end

	-- Altares (4)
	for i = 1, 4 do
		local angle = ((i - 0.5) / 4) * math.pi * 2
		local altar = createSacrificeAltar(Vector3.new(
			math.cos(angle) * 350,
			15,
			math.sin(angle) * 350
			))
		altar.Parent = decoFolder
	end

	-- Estelas con glifos (12)
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local stele = createGlyphStele(Vector3.new(
			math.cos(angle) * 280,
			15,
			math.sin(angle) * 280
			))
		stele.Parent = decoFolder
	end

	-- Calendario solar (1 central)
	local calendar = createSolarCalendar(Vector3.new(0, 15, 0))
	calendar.Parent = decoFolder

	print("[DECO] ? Decoraciones prehispÃÂ¡nicas colocadas")
end

function PreHispanicDecorations.Clear(mapFolder: Folder)
	local deco = mapFolder:FindFirstChild("PreHispanicDecorations")
	if deco then
		deco:Destroy()
		print("[DECO] Decoraciones limpiadas")
	end
end

return PreHispanicDecorations