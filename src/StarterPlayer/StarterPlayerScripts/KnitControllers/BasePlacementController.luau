--!strict
--[[
	BasePlacementController - Sistema de Ghost Preview y Placement

	CARACTERÍSTICAS:
	- Ghost preview semi-transparente que sigue al mouse
	- Raycast 3D para posicionar objetos en el mundo
	- Feedback visual (verde = válido, rojo = inválido)
	- Rotación con tecla R (incrementos de 90°)
	- Click para confirmar placement
	- Validación en tiempo real con servidor

	ARQUITECTURA DE INPUT:
	- Mouse Move → Raycast → Calcular posición → Preview
	- Mouse Click → Validar → Colocar → Refresh
	- Key R → Rotar ghost → Update preview

	ALGORITMO DE RAYCAST:
	1. Obtener posición del mouse (2D screen)
	2. Convertir a ray 3D (Camera:ScreenPointToRay)
	3. Raycast contra Workspace
	4. Snap posición al grid
	5. Validar con servidor
	6. Actualizar ghost visual

	AUTHOR: Epic Placement Controller v1
	CLIENT-SIDE: No lógica de negocio, solo UI/preview
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Knit = require(ReplicatedStorage.Knit)

--[[────────────────────────────────────────────────────────────────────────
	TYPES & CONSTANTS
────────────────────────────────────────────────────────────────────────]]

export type PlacementMode = {
	IsActive: boolean,
	ObjectType: string,
	ObjectSize: Vector3,
	GhostModel: Model?,
	CurrentRotation: number,
	LastValidPosition: Vector3?,
}

-- Constantes de visualización
local GHOST_TRANSPARENCY = 0.5
local VALID_COLOR = Color3.fromRGB(100, 255, 100)    -- Verde
local INVALID_COLOR = Color3.fromRGB(255, 100, 100)  -- Rojo
local RAYCAST_DISTANCE = 500                         -- Distancia máxima del raycast

--[[────────────────────────────────────────────────────────────────────────
	CONTROLLER DEFINITION
────────────────────────────────────────────────────────────────────────]]

local BasePlacementController = Knit.CreateController({
	Name = "BasePlacementController",
})

-- Internal state
local placementMode: PlacementMode = {
	IsActive = false,
	ObjectType = "",
	ObjectSize = Vector3.new(5, 5, 5),
	GhostModel = nil,
	CurrentRotation = 0,
	LastValidPosition = nil,
}

local player = Players.LocalPlayer
local camera: Camera
local mouse: Mouse

-- Services & Controllers (se obtendrán en KnitStart)
local BasePlacementService
local BaseOwnershipService
local BaseUIController

--[[────────────────────────────────────────────────────────────────────────
	RAYCAST UTILITIES - 3D Position Detection
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea parámetros de raycast con filtros configurados.

	FILTROS:
	- Ignorar ghost model (no colisionar consigo mismo)
	- Ignorar otros players
	- Solo colisionar con Workspace y bases

	@return RaycastParams - Parámetros configurados
]]
local function createRaycastParams(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local ignoreList = {}

	-- Ignorar ghost model
	if placementMode.GhostModel then
		table.insert(ignoreList, placementMode.GhostModel)
	end

	-- Ignorar character del jugador
	if player.Character then
		table.insert(ignoreList, player.Character)
	end

	params.FilterDescendantsInstances = ignoreList

	return params
end

--[[
	Obtiene la posición 3D del mouse en el mundo usando raycast.

	ALGORITMO:
	1. Convertir posición 2D del mouse a Ray 3D
	2. Hacer raycast desde la cámara
	3. Retornar punto de intersección

	@return Vector3? - Posición en el mundo, o nil si no hit
]]
local function getMouseWorldPosition(): Vector3?
	if not camera or not mouse then
		return nil
	end

	-- Obtener posición 2D del mouse
	local mousePos = Vector2.new(mouse.X, mouse.Y)

	-- Convertir a Ray 3D
	local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y, 0)

	-- Configurar raycast
	local params = createRaycastParams()

	-- Hacer raycast
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAYCAST_DISTANCE, params)

	if result then
		return result.Position
	end

	return nil
end

--[[────────────────────────────────────────────────────────────────────────
	GHOST MODEL - Visual Preview
────────────────────────────────────────────────────────────────────────]]

--[[
	Crea un ghost model para preview.

	CARACTERÍSTICAS:
	- Semi-transparente (GHOST_TRANSPARENCY)
	- CanCollide = false
	- Anchored = true
	- Color cambia según validez (verde/rojo)

	NOTA: Por ahora usa un cube simple. Cuando tengamos assets de upgrades,
	esto cargará el modelo real del upgrade.

	@param objectType - Tipo de objeto (ej: "Generator", "Turret")
	@param size - Tamaño del objeto
	@return Model - Ghost model creado
]]
local function createGhostModel(objectType: string, size: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "GhostPreview_" .. objectType

	-- Por ahora, usar un cube simple
	local part = Instance.new("Part")
	part.Name = "GhostPart"
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = GHOST_TRANSPARENCY
	part.Material = Enum.Material.Neon
	part.Color = VALID_COLOR -- Default verde
	part.Parent = model

	-- Grid visual (opcional - ayuda a ver el grid snapping)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.8
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.Parent = surfaceGui

	-- Grid lines
	local uiGrid = Instance.new("UIGridLayout")
	uiGrid.CellSize = UDim2.new(0.2, 0, 0.2, 0)
	uiGrid.Parent = frame

	-- Establecer PrimaryPart para poder rotar todo el model
	model.PrimaryPart = part

	-- INDICADOR DE ROTACIÓN - Flecha para ver la dirección
	-- Posicionar en el frente del cubo (cara -Z)
	local arrow = Instance.new("Part")
	arrow.Name = "RotationArrow"
	arrow.Size = Vector3.new(size.X * 0.3, size.Y, size.Z * 0.15)  -- Barra delgada
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.Transparency = 0.2
	arrow.Material = Enum.Material.Neon
	arrow.Color = Color3.fromRGB(255, 255, 0)  -- Amarillo brillante

	-- Posicionar relativo al part usando CFrame
	-- -Z es el frente, mover la flecha hacia adelante
	local offset = CFrame.new(0, 0, -(size.Z/2 + arrow.Size.Z/2 + 0.5))
	arrow.CFrame = part.CFrame * offset
	arrow.Parent = model

	-- Soldar la flecha al part principal
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = arrow
	weld.Parent = arrow

	-- Texto "FRONT" arriba de la flecha
	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 80, 0, 30)
	billboardGui.StudsOffset = Vector3.new(0, size.Y/2 + 2, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Parent = arrow

	local frontLabel = Instance.new("TextLabel")
	frontLabel.Size = UDim2.new(1, 0, 1, 0)
	frontLabel.BackgroundTransparency = 1
	frontLabel.Text = "▲ FRONT ▲"
	frontLabel.TextColor3 = Color3.new(1, 1, 0)
	frontLabel.TextStrokeTransparency = 0
	frontLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	frontLabel.Font = Enum.Font.GothamBold
	frontLabel.TextScaled = true
	frontLabel.Parent = billboardGui

	model.Parent = Workspace
	return model
end

--[[
	Actualiza la posición y visual del ghost model.

	@param position - Nueva posición
	@param isValid - Si la posición es válida
]]
local function updateGhostModel(position: Vector3, isValid: boolean)
	if not placementMode.GhostModel then
		return
	end

	local ghostPart = placementMode.GhostModel:FindFirstChild("GhostPart") :: Part?
	if not ghostPart then
		return
	end

	-- Actualizar TODO EL MODEL (incluye GhostPart + RotationArrow)
	-- Esto asegura que el Weld funcione correctamente
	local rotationRadians = math.rad(placementMode.CurrentRotation)
	local newCFrame = CFrame.new(position) * CFrame.Angles(0, rotationRadians, 0)

	-- Usar SetPrimaryPartCFrame para mover TODO el modelo
	if placementMode.GhostModel.PrimaryPart then
		placementMode.GhostModel:SetPrimaryPartCFrame(newCFrame)
	else
		-- Fallback: actualizar solo el GhostPart
		ghostPart.CFrame = newCFrame
	end

	-- Mostrar ghost (por si estaba oculto)
	ghostPart.Transparency = GHOST_TRANSPARENCY

	-- Actualizar color según validez
	ghostPart.Color = isValid and VALID_COLOR or INVALID_COLOR
end

--[[
	Destruye el ghost model actual.
]]
local function destroyGhostModel()
	if placementMode.GhostModel then
		placementMode.GhostModel:Destroy()
		placementMode.GhostModel = nil
	end
end

--[[────────────────────────────────────────────────────────────────────────
	PLACEMENT MODE - State Management
────────────────────────────────────────────────────────────────────────]]

--[[
	Activa el modo de placement.

	@param objectType - Tipo de objeto a colocar
	@param objectSize - Tamaño del objeto (opcional)
]]
local function activatePlacementMode(objectType: string, objectSize: Vector3?)
	-- Destruir ghost anterior si existe
	destroyGhostModel()

	-- Configurar estado
	placementMode.IsActive = true
	placementMode.ObjectType = objectType
	placementMode.ObjectSize = objectSize or Vector3.new(5, 5, 5)
	placementMode.CurrentRotation = 0
	placementMode.LastValidPosition = nil

	-- Crear ghost model
	placementMode.GhostModel = createGhostModel(objectType, placementMode.ObjectSize)

	print(string.format(
		"[BasePlacementController] 🎯 Placement mode activated: %s",
		objectType
	))
end

--[[
	Desactiva el modo de placement.
]]
local function deactivatePlacementMode()
	destroyGhostModel()

	placementMode.IsActive = false
	placementMode.ObjectType = ""
	placementMode.LastValidPosition = nil

	-- Cerrar build menu si está abierto
	if BaseUIController then
		BaseUIController:CloseBuildMenu()
	end

	print("[BasePlacementController] ❌ Placement mode deactivated")
end

--[[────────────────────────────────────────────────────────────────────────
	INPUT HANDLING - User Interaction
────────────────────────────────────────────────────────────────────────]]

--[[
	Maneja la rotación del ghost con tecla E.
]]
local function handleRotationInput()
	placementMode.CurrentRotation = (placementMode.CurrentRotation + 90) % 360
	print(string.format(
		"[BasePlacementController] 🔄 Rotated to: %d°",
		placementMode.CurrentRotation
	))

	-- Actualizar ghost visualmente inmediatamente
	if placementMode.LastValidPosition then
		updateGhostModel(placementMode.LastValidPosition, true)
	end
end

--[[
	Intenta colocar el objeto en la posición actual.
]]
local function attemptPlacement()
	if not placementMode.LastValidPosition then
		warn("[BasePlacementController] No valid position to place")
		return
	end

	print(string.format(
		"[BasePlacementController] 📍 Attempting placement at: %s (Rotation: %d°)",
		tostring(placementMode.LastValidPosition),
		placementMode.CurrentRotation
	))

	-- Llamar al servidor para colocar el objeto
	local result = BaseOwnershipService:PlaceObject(
		placementMode.ObjectType,
		placementMode.LastValidPosition,
		placementMode.CurrentRotation,
		placementMode.ObjectSize
	)

	if result.Success then
		print(string.format(
			"[BasePlacementController] ✅ Object placed successfully: %s",
			result.ObjectId
		))

		-- Desactivar placement mode
		deactivatePlacementMode()
	else
		warn(string.format(
			"[BasePlacementController] ❌ Failed to place object: %s",
			result.ErrorMessage or "Unknown error"
		))
	end
end

--[[
	Maneja input del mouse (click, movimiento).
]]
local function setupInputHandlers()
	-- TECLA E y ESCAPE - Rotar y Cancelar
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- ESCAPE tiene prioridad - ignorar gameProcessed
		if input.KeyCode == Enum.KeyCode.Escape and placementMode.IsActive then
			print(string.format(
				"[BasePlacementController] 🚫 ESCAPE pressed - Force closing (gameProcessed: %s)",
				tostring(gameProcessed)
			))
			deactivatePlacementMode()
			return
		end

		-- Para otras teclas, respetar gameProcessed
		if gameProcessed then return end

		if placementMode.IsActive then
			if input.KeyCode == Enum.KeyCode.E then
				handleRotationInput()
			end
		end
	end)

	-- CLICK - Colocar objeto
	mouse.Button1Down:Connect(function()
		if placementMode.IsActive then
			attemptPlacement()
		end
	end)
end

--[[────────────────────────────────────────────────────────────────────────
	UPDATE LOOP - Preview Rendering
────────────────────────────────────────────────────────────────────────]]

--[[
	Loop de actualización del ghost preview (ejecuta cada frame).

	PROCESO:
	1. Obtener posición del mouse en el mundo (raycast)
	2. Pedir al servidor que valide la posición
	3. Actualizar visual del ghost (color verde/rojo)
	4. Guardar última posición válida
]]
local function startUpdateLoop()
	RunService.RenderStepped:Connect(function()
		if not placementMode.IsActive then
			return
		end

		-- Obtener posición del mouse en 3D
		local worldPos = getMouseWorldPosition()
		if not worldPos then
			-- No hay intersección - ocultar ghost
			if placementMode.GhostModel then
				local ghostPart = placementMode.GhostModel:FindFirstChild("GhostPart") :: Part?
				if ghostPart then
					ghostPart.Transparency = 1 -- Ocultar
				end
			end
			return
		end

		-- Validar posición con servidor (SÍNCRONO para evitar race conditions)
		local result = BasePlacementService:GetPlacementPreview(
			worldPos,
			placementMode.CurrentRotation,
			placementMode.ObjectSize
		)

		if result.IsValid and result.Position then
			-- Posición válida
			placementMode.LastValidPosition = result.Position
			updateGhostModel(result.Position, true)
		else
			-- Posición inválida
			placementMode.LastValidPosition = nil
			updateGhostModel(worldPos, false)
		end
	end)
end

--[[────────────────────────────────────────────────────────────────────────
	PUBLIC API - Controller Methods
────────────────────────────────────────────────────────────────────────]]

--[[
	Activa el placement mode (callable desde otros controllers).
]]
function BasePlacementController:StartPlacement(objectType: string, objectSize: Vector3?)
	activatePlacementMode(objectType, objectSize)
end

--[[
	Desactiva el placement mode.
]]
function BasePlacementController:CancelPlacement()
	deactivatePlacementMode()
end

--[[
	Verifica si está en modo placement.
]]
function BasePlacementController:IsPlacing(): boolean
	return placementMode.IsActive
end

--[[────────────────────────────────────────────────────────────────────────
	LIFECYCLE HOOKS
────────────────────────────────────────────────────────────────────────]]

function BasePlacementController:KnitInit()
	-- Obtener referencias
	camera = Workspace.CurrentCamera
	mouse = player:GetMouse()

	print("[BasePlacementController] ⚙️ Initialized")
end

function BasePlacementController:KnitStart()
	-- Obtener servicios & controllers
	BasePlacementService = Knit.GetService("BasePlacementService")
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")
	BaseUIController = Knit.GetController("BaseUIController")

	-- Setup input handlers
	setupInputHandlers()

	-- Iniciar update loop
	startUpdateLoop()

	print("[BasePlacementController] ✅ Started - Ghost preview system ready")
	print("[BasePlacementController] Controls: E = Rotate, Click = Place, ESC = Cancel")

	-- TEST: Activar placement mode automáticamente (REMOVER EN PRODUCCIÓN)
	-- task.delay(2, function()
	-- 	self:StartPlacement("TestObject", Vector3.new(10, 5, 10))
	-- end)
end

return BasePlacementController
