--!strict
--[[
	BASE VISUALS MANAGER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Maneja efectos visuales dinámicos de las bases según su HP.

	FEATURES:
	✅ Efectos progresivos según HP (100% → 0%)
	✅ Humo cuando HP < 50%
	✅ Fuego cuando HP < 25%
	✅ Grietas y daño visual
	✅ Pulsating glow cuando invulnerable
	✅ Decoraciones (muros, torres, billboards)
	✅ Performance-optimized

	USAGE:
		local BaseVisualsManager = require(game.ServerStorage.Managers.BaseVisualsManager)

		-- Crear base con visuals
		local base = BaseVisualsManager:CreateBase(userId, position, playerName)

		-- Actualizar efectos según HP
		BaseVisualsManager:UpdateBaseVisuals(userId, currentHP, maxHP)

	API:
		:CreateBase(userId, position, playerName) → BasePart
		:UpdateBaseVisuals(userId, currentHP, maxHP)
		:SetInvulnerable(userId, enabled)
		:CleanupBase(userId)
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTS
--═══════════════════════════════════════════════════════════════════════

local DEBUG_MODE = false

-- Umbrales de HP para efectos
local HP_THRESHOLDS = {
	PRISTINE = 0.70, -- 70-100%: Sin daño visible
	DAMAGED = 0.40,  -- 40-69%: Grietas y decals
	CRITICAL = 0.20, -- 20-39%: Humo saliendo
	BURNING = 0.01,  -- 1-19%: Fuego activo
}

-- Colores según estado
local BASE_COLORS = {
	Pristine = Color3.fromRGB(60, 60, 60),   -- Gris normal
	Damaged = Color3.fromRGB(80, 60, 50),    -- Gris con tinte marrón
	Critical = Color3.fromRGB(100, 70, 60),  -- Más marrón
	Burning = Color3.fromRGB(120, 80, 70),   -- Casi rojo
	Invulnerable = Color3.fromRGB(100, 150, 255), -- Azul brillante
}

-- Configuración de decoraciones
local DECORATION_CONFIG = {
	-- Muros perimetrales
	Walls = {
		Enabled = true,
		Height = 6,
		Thickness = 1,
		Color = Color3.fromRGB(80, 80, 80),
		Material = Enum.Material.Concrete,
	},

	-- Torres en esquinas
	Towers = {
		Enabled = true,
		Height = 12,
		Size = Vector3.new(4, 12, 4),
		Color = Color3.fromRGB(100, 100, 100),
		Material = Enum.Material.Metal,
	},
}

--═══════════════════════════════════════════════════════════════════════
-- MODULE
--═══════════════════════════════════════════════════════════════════════

local BaseVisualsManager = {}
BaseVisualsManager.__index = BaseVisualsManager

-- Estado: {[userId] = {base: BasePart, effects: {...}, decorations: {...}}}
local BaseData = {}

--═══════════════════════════════════════════════════════════════════════
-- UTILITIES
--═══════════════════════════════════════════════════════════════════════

local function getHPState(hpPercent: number): string
	if hpPercent >= HP_THRESHOLDS.PRISTINE then
		return "Pristine"
	elseif hpPercent >= HP_THRESHOLDS.DAMAGED then
		return "Damaged"
	elseif hpPercent >= HP_THRESHOLDS.CRITICAL then
		return "Critical"
	else
		return "Burning"
	end
end

--═══════════════════════════════════════════════════════════════════════
-- DECORATIONS
--═══════════════════════════════════════════════════════════════════════

local function createWalls(basePart: BasePart): {Part}
	if not DECORATION_CONFIG.Walls.Enabled then
		return {}
	end

	local walls = {}
	local baseSize = basePart.Size
	local wallConfig = DECORATION_CONFIG.Walls

	local halfWidth = baseSize.X / 2
	local halfDepth = baseSize.Z / 2

	-- 4 muros (Norte, Sur, Este, Oeste)
	local wallPositions = {
		{pos = Vector3.new(0, wallConfig.Height/2, halfDepth + wallConfig.Thickness/2), size = Vector3.new(baseSize.X, wallConfig.Height, wallConfig.Thickness)},
		{pos = Vector3.new(0, wallConfig.Height/2, -(halfDepth + wallConfig.Thickness/2)), size = Vector3.new(baseSize.X, wallConfig.Height, wallConfig.Thickness)},
		{pos = Vector3.new(halfWidth + wallConfig.Thickness/2, wallConfig.Height/2, 0), size = Vector3.new(wallConfig.Thickness, wallConfig.Height, baseSize.Z)},
		{pos = Vector3.new(-(halfWidth + wallConfig.Thickness/2), wallConfig.Height/2, 0), size = Vector3.new(wallConfig.Thickness, wallConfig.Height, baseSize.Z)},
	}

	for i, data in ipairs(wallPositions) do
		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = data.size
		wall.Anchored = true
		wall.Material = wallConfig.Material
		wall.Color = wallConfig.Color
		wall.CFrame = basePart.CFrame * CFrame.new(data.pos)
		wall.Parent = basePart

		table.insert(walls, wall)
	end

	return walls
end

local function createTowers(basePart: BasePart): {Part}
	if not DECORATION_CONFIG.Towers.Enabled then
		return {}
	end

	local towers = {}
	local baseSize = basePart.Size
	local towerConfig = DECORATION_CONFIG.Towers

	local halfWidth = baseSize.X / 2
	local halfDepth = baseSize.Z / 2
	local offset = 2 -- Offset hacia afuera

	-- 4 torres en esquinas
	local towerPositions = {
		Vector3.new(halfWidth + offset, towerConfig.Height/2, halfDepth + offset),
		Vector3.new(halfWidth + offset, towerConfig.Height/2, -(halfDepth + offset)),
		Vector3.new(-(halfWidth + offset), towerConfig.Height/2, halfDepth + offset),
		Vector3.new(-(halfWidth + offset), towerConfig.Height/2, -(halfDepth + offset)),
	}

	for i, pos in ipairs(towerPositions) do
		local tower = Instance.new("Part")
		tower.Name = "Tower_" .. i
		tower.Size = towerConfig.Size
		tower.Anchored = true
		tower.Material = towerConfig.Material
		tower.Color = towerConfig.Color
		tower.CFrame = basePart.CFrame * CFrame.new(pos)
		tower.Parent = basePart

		-- Detalle en top (antenna)
		local antenna = Instance.new("Part")
		antenna.Name = "Antenna"
		antenna.Size = Vector3.new(0.5, 3, 0.5)
		antenna.Anchored = true
		antenna.Material = Enum.Material.Metal
		antenna.Color = Color3.fromRGB(200, 200, 200)
		antenna.CFrame = tower.CFrame * CFrame.new(0, towerConfig.Height/2 + 1.5, 0)
		antenna.Parent = tower

		-- Light en top
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 100, 0)
		light.Brightness = 2
		light.Range = 20
		light.Parent = antenna

		table.insert(towers, tower)
	end

	return towers
end

local function createBillboard(basePart: BasePart, playerName: string, userId: number): BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Name = "BaseBillboard"
	bb.Size = UDim2.fromOffset(300, 100)
	bb.StudsOffset = Vector3.new(0, 10, 0)
	bb.AlwaysOnTop = true
	bb.Parent = basePart

	-- Frame contenedor
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 0.2
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	-- Borde brillante
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Nombre del jugador
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.Position = UDim2.fromScale(0, 0.05)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	nameLabel.Text = playerName .. "'s Base"
	nameLabel.Parent = frame

	-- HP Bar
	local hpBarBg = Instance.new("Frame")
	hpBarBg.Name = "HPBarBg"
	hpBarBg.Size = UDim2.fromScale(0.9, 0.15)
	hpBarBg.Position = UDim2.fromScale(0.05, 0.5)
	hpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	hpBarBg.BorderSizePixel = 0
	hpBarBg.Parent = frame

	local hpBarCorner = Instance.new("UICorner")
	hpBarCorner.CornerRadius = UDim.new(0.5, 0)
	hpBarCorner.Parent = hpBarBg

	local hpBar = Instance.new("Frame")
	hpBar.Name = "HPBar"
	hpBar.Size = UDim2.fromScale(1, 1)
	hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	hpBar.BorderSizePixel = 0
	hpBar.Parent = hpBarBg

	local hpBarFillCorner = Instance.new("UICorner")
	hpBarFillCorner.CornerRadius = UDim.new(0.5, 0)
	hpBarFillCorner.Parent = hpBar

	-- HP Text
	local hpLabel = Instance.new("TextLabel")
	hpLabel.Name = "HPLabel"
	hpLabel.Size = UDim2.fromScale(1, 0.3)
	hpLabel.Position = UDim2.fromScale(0, 0.7)
	hpLabel.BackgroundTransparency = 1
	hpLabel.TextScaled = true
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextColor3 = Color3.new(1, 1, 1)
	hpLabel.Text = "HP: 100/100"
	hpLabel.Parent = frame

	return bb
end

--═══════════════════════════════════════════════════════════════════════
-- EFFECTS
--═══════════════════════════════════════════════════════════════════════

local function createSmokeEffect(basePart: BasePart): Part
	local smokePart = Instance.new("Part")
	smokePart.Name = "SmokeEffect"
	smokePart.Size = Vector3.new(1, 1, 1)
	smokePart.Transparency = 1
	smokePart.CanCollide = false
	smokePart.CanQuery = false
	smokePart.CanTouch = false
	smokePart.Anchored = true
	smokePart.CFrame = basePart.CFrame * CFrame.new(0, 3, 0)
	smokePart.Parent = basePart

	local smoke = Instance.new("ParticleEmitter")
	smoke.Name = "Smoke"
	smoke.Rate = 15
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Speed = NumberRange.new(5, 10)
	smoke.SpreadAngle = Vector2.new(20, 20)
	smoke.Color = ColorSequence.new(Color3.fromRGB(60, 60, 60))
	smoke.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 3)
	})
	smoke.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	smoke.Acceleration = Vector3.new(0, 10, 0)
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = smokePart

	return smokePart
end

local function createFireEffect(basePart: BasePart): Part
	local firePart = Instance.new("Part")
	firePart.Name = "FireEffect"
	firePart.Size = Vector3.new(1, 1, 1)
	firePart.Transparency = 1
	firePart.CanCollide = false
	firePart.CanQuery = false
	firePart.CanTouch = false
	firePart.Anchored = true
	firePart.CFrame = basePart.CFrame * CFrame.new(0, 2, 0)
	firePart.Parent = basePart

	-- Fire particles
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "Fire"
	fire.Rate = 30
	fire.Lifetime = NumberRange.new(0.5, 1)
	fire.Speed = NumberRange.new(2, 5)
	fire.SpreadAngle = Vector2.new(30, 30)
	fire.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 30, 0))
	})
	fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	fire.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	fire.LightEmission = 1
	fire.Acceleration = Vector3.new(0, 5, 0)
	fire.EmissionDirection = Enum.NormalId.Top
	fire.Parent = firePart

	-- Light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 0)
	light.Brightness = 5
	light.Range = 30
	light.Parent = firePart

	return firePart
end

local function createCrackDecals(basePart: BasePart): {Decal}
	local decals = {}

	-- Crear 2-3 decals de grietas en caras aleatorias
	local faces = {Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Right}

	for i = 1, 2 do
		local decal = Instance.new("Decal")
		decal.Name = "CrackDecal_" .. i
		decal.Texture = "rbxasset://textures/SpawnLocation.png" -- Placeholder (usar texture de grietas si tienes)
		decal.Face = faces[math.random(1, #faces)]
		decal.Transparency = 0.3
		decal.Parent = basePart

		table.insert(decals, decal)
	end

	return decals
end

--═══════════════════════════════════════════════════════════════════════
-- INVULNERABILITY EFFECT
--═══════════════════════════════════════════════════════════════════════

local function startInvulnerabilityEffect(basePart: BasePart)
	-- Pulsating glow
	local originalColor = basePart.Color
	local glowColor = BASE_COLORS.Invulnerable

	task.spawn(function()
		while basePart:GetAttribute("Invulnerable") do
			-- Fade to glow
			TweenService:Create(
				basePart,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Color = glowColor}
			):Play()

			task.wait(0.5)

			-- Fade back
			TweenService:Create(
				basePart,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Color = originalColor}
			):Play()

			task.wait(0.5)
		end

		-- Reset color
		basePart.Color = originalColor
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- PUBLIC API
--═══════════════════════════════════════════════════════════════════════

--[[
	Crea una base con todas las decoraciones visuales.

	@param userId number - ID del jugador
	@param position Vector3 - Posición donde spawnear
	@param playerName string - Nombre del jugador
	@param baseSize Vector3? - Tamaño de la base (opcional)
	@return BasePart - La base creada
]]
function BaseVisualsManager:CreateBase(userId: number, position: Vector3, playerName: string, baseSize: Vector3?): BasePart
	baseSize = baseSize or Vector3.new(120, 1, 120)

	-- Crear base principal
	local basePart = Instance.new("Part")
	basePart.Name = playerName .. "_Base"
	basePart.Size = baseSize
	basePart.Anchored = true
	basePart.Position = position
	basePart.Material = Enum.Material.Concrete
	basePart.Color = BASE_COLORS.Pristine
	basePart:SetAttribute("OwnerUserId", userId)

	-- Crear decoraciones
	-- DESHABILITADO: Muros por default (ahora se crean con Upgrade_7: Wall Section)
	-- local walls = createWalls(basePart)
	local walls = {} -- Sin muros por default
	local towers = createTowers(basePart)


	-- Guardar referencias
	BaseData[userId] = {
		base = basePart,
		effects = {},
		decorations = {
			walls = walls,
			towers = towers,
			billboard = billboard,
		},
	}

	if DEBUG_MODE then
		print(("[BASE_VISUALS] Created base for %s (userId: %d)"):format(playerName, userId))
	end

	return basePart
end

--[[
	Actualiza los efectos visuales según el HP actual.

	@param userId number - ID del jugador
	@param currentHP number - HP actual
	@param maxHP number - HP máximo
]]
function BaseVisualsManager:UpdateBaseVisuals(userId: number, currentHP: number, maxHP: number)
	local data = BaseData[userId]
	if not data or not data.base or not data.base.Parent then
		return
	end

	local basePart = data.base
	local hpPercent = currentHP / maxHP
	local state = getHPState(hpPercent)

	-- Actualizar color de base
	if not basePart:GetAttribute("Invulnerable") then
		TweenService:Create(
			basePart,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Color = BASE_COLORS[state]}
		):Play()
	end

	-- Actualizar HP bar en billboard
	local billboard = data.base:FindFirstChild("BaseBillboard")
	if billboard and billboard:IsA("BillboardGui") then
		local frame = billboard:FindFirstChild("Frame")
		if not frame then return end

		-- HP Bar
		local hpBarBg = frame:FindFirstChild("HPBarBg")
		local hpBar = hpBarBg and hpBarBg:FindFirstChild("HPBar")
		local hpLabel = frame:FindFirstChild("HPLabel")

		if hpBar then
			-- ✅ Animar barra con porcentaje correcto
			TweenService:Create(
				hpBar,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.fromScale(hpPercent, 1)}
			):Play()

			-- Color según HP
			if hpPercent > 0.7 then
				hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			elseif hpPercent > 0.3 then
				hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			else
				hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
		end

		if hpLabel then
			-- ✅ IMPORTANTE: Mostrar HP actual vs MaxHP real
			hpLabel.Text = string.format("HP: %d/%d", currentHP, maxHP)
		end
	end

	-- Efectos según estado
	-- Limpiar efectos previos
	for effectName, effect in pairs(data.effects) do
		if effect and effect.Parent then
			effect:Destroy()
		end
		data.effects[effectName] = nil
	end

	-- Agregar efectos según HP
	if hpPercent < HP_THRESHOLDS.CRITICAL and not data.effects.Smoke then
		data.effects.Smoke = createSmokeEffect(basePart)

		if DEBUG_MODE then
			print(("[BASE_VISUALS] Added smoke effect to base (userId: %d)"):format(userId))
		end
	end

	if hpPercent < HP_THRESHOLDS.BURNING and not data.effects.Fire then
		data.effects.Fire = createFireEffect(basePart)

		if DEBUG_MODE then
			print(("[BASE_VISUALS] Added fire effect to base (userId: %d)"):format(userId))
		end
	end

	if hpPercent < HP_THRESHOLDS.DAMAGED and not data.effects.Cracks then
		data.effects.Cracks = createCrackDecals(basePart)
	end
end

--[[
	Activa/desactiva el efecto de invulnerabilidad.

	@param userId number - ID del jugador
	@param enabled boolean - true para activar
]]
function BaseVisualsManager:SetInvulnerable(userId: number, enabled: boolean)
	local data = BaseData[userId]
	if not data or not data.base or not data.base.Parent then
		return
	end

	local basePart = data.base
	basePart:SetAttribute("Invulnerable", enabled)

	if enabled then
		startInvulnerabilityEffect(basePart)
	end

	if DEBUG_MODE then
		print(("[BASE_VISUALS] Invulnerability %s for userId: %d"):format(enabled and "enabled" or "disabled", userId))
	end
end

--[[
	Limpia todos los efectos y decoraciones de una base.

	@param userId number - ID del jugador
]]
function BaseVisualsManager:CleanupBase(userId: number)
	local data = BaseData[userId]
	if not data then
		return
	end

	-- Cleanup effects
	for _, effect in pairs(data.effects) do
		if effect and effect.Parent then
			effect:Destroy()
		end
	end

	-- Cleanup decorations
	if data.decorations.billboard and data.decorations.billboard.Parent then
		data.decorations.billboard:Destroy()
	end

	-- Base se limpia automáticamente al remover jugador
	BaseData[userId] = nil

	if DEBUG_MODE then
		print(("[BASE_VISUALS] Cleaned up base for userId: %d"):format(userId))
	end
end

--[[
	Retorna info de debug.

	@param userId number - ID del jugador
	@return {EffectCount: number, HasDecor: boolean}?
]]
function BaseVisualsManager:GetDebugInfo(userId: number): {EffectCount: number, HasDecor: boolean}?
	local data = BaseData[userId]
	if not data then
		return nil
	end

	local effectCount = 0
	for _ in pairs(data.effects) do
		effectCount += 1
	end

	return {
		EffectCount = effectCount,
		HasDecor = data.decorations.walls and #data.decorations.walls > 0,
	}
end

--═══════════════════════════════════════════════════════════════════════
-- INITIALIZATION MESSAGE
--═══════════════════════════════════════════════════════════════════════

print("[BaseVisualsManager] ✓ Module loaded")

return BaseVisualsManager
