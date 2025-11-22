--!strict
--[[
	BasePlacementService - Sistema Avanzado de Grid Snapping y Placement

	CARACTERÃÂSTICAS:
	- Grid snapping configurable (1, 2, 5, 10 studs)
	- AABB collision detection (Axis-Aligned Bounding Boxes)
	- Rotation snapping (90ÃÂ° increments)
	- Surface detection (auto-height adjustment)
	- Preview position calculation para ghost objects

	ALGORITMOS MATEMÃÂTICOS:

	1. GRID SNAPPING:
	   snapped = round(value / gridSize) * gridSize

	2. AABB COLLISION (3D):
	   Dos cajas colisionan si:
	   (min1.X <= max2.X && max1.X >= min2.X) &&
	   (min1.Y <= max2.Y && max1.Y >= min2.Y) &&
	   (min1.Z <= max2.Z && max1.Z >= min2.Z)

	3. ROTATION SNAPPING:
	   snappedAngle = round(angle / increment) * increment

	AUTHOR: Epic Placement System v1
	PERFORMANCE: O(n) collision check con early exit
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Knit = require(ReplicatedStorage.Knit)

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	TYPES & CONSTANTS
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

export type BoundingBox = {
	Min: Vector3,
	Max: Vector3,
	Center: Vector3,
	Size: Vector3,
}

export type PlacementConfig = {
	GridSize: number,              -- TamaÃÂ±o de la cuadrÃÂ­cula (studs)
	RotationIncrement: number,     -- Incremento de rotaciÃÂ³n (grados)
	EnableSnapping: boolean,       -- Habilitar snapping
	EnableCollision: boolean,      -- Habilitar collision detection
	CollisionPadding: number,      -- Padding extra para colisiones (studs)
	MaxPlacementHeight: number,    -- Altura mÃÂ¡xima sobre la base
	MinPlacementHeight: number,    -- Altura mÃÂ­nima (sobre baseplate)
}

export type PlacementResult = {
	IsValid: boolean,
	Position: Vector3?,            -- PosiciÃÂ³n final (snapped)
	Rotation: number?,             -- RotaciÃÂ³n final (snapped)
	ErrorMessage: string?,
	ErrorCode: string?,
}

-- ConfiguraciÃÂ³n por defecto
local DEFAULT_CONFIG: PlacementConfig = {
	GridSize = 5,                  -- Grid de 5x5 studs
	RotationIncrement = 90,        -- RotaciÃÂ³n en incrementos de 90ÃÂ°
	EnableSnapping = true,
	EnableCollision = true,
	CollisionPadding = 0.5,        -- Medio stud de padding
	MaxPlacementHeight = 50,       -- 50 studs sobre la base
	MinPlacementHeight = 2,        -- 2 studs sobre el baseplate
}

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	SERVICE DEFINITION
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

local BasePlacementService = Knit.CreateService({
	Name = "BasePlacementService",
	Client = {},
})

-- Internal state
local config: PlacementConfig = DEFAULT_CONFIG

-- Dependencies
local BaseSpawnerService
local BaseOwnershipService

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	GRID MATHEMATICS - Snapping Algorithms
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

--[[
	Snap un valor a la cuadrÃÂ­cula mÃÂ¡s cercana.

	MATEMÃÂTICAS:
	- Dividir por gridSize
	- Redondear al entero mÃÂ¡s cercano
	- Multiplicar por gridSize

	EJEMPLO (gridSize = 5):
	  Input: 7.3  Ã¢ÂÂ 7.3/5 = 1.46 Ã¢ÂÂ round(1.46) = 1 Ã¢ÂÂ 1*5 = 5
	  Input: 12.8 Ã¢ÂÂ 12.8/5 = 2.56 Ã¢ÂÂ round(2.56) = 3 Ã¢ÂÂ 3*5 = 15

	@param value - Valor a snapear
	@param gridSize - TamaÃÂ±o de la cuadrÃÂ­cula
	@return number - Valor snapped
]]
local function snapToGrid(value: number, gridSize: number): number
	return math.round(value / gridSize) * gridSize
end

--[[
	Snap una posiciÃÂ³n 3D al grid (eje X y Z, Y se calcula por altura).

	PROCESO:
	1. Snap X y Z al grid
	2. Mantener Y original (o ajustar segÃÂºn superficie)
	3. Retornar Vector3 snapped

	@param position - PosiciÃÂ³n original
	@param gridSize - TamaÃÂ±o de la cuadrÃÂ­cula
	@return Vector3 - PosiciÃÂ³n snapped
]]
local function snapPositionToGrid(position: Vector3, gridSize: number): Vector3
	return Vector3.new(
		snapToGrid(position.X, gridSize),
		position.Y, -- Mantener altura original
		snapToGrid(position.Z, gridSize)
	)
end

--[[
	Snap un ÃÂ¡ngulo a incrementos especÃÂ­ficos.

	MATEMÃÂTICAS:
	- Normalizar ÃÂ¡ngulo a rango [0, 360)
	- Snap al incremento mÃÂ¡s cercano
	- Re-normalizar si es necesario

	EJEMPLO (increment = 90):
	  Input: 47ÃÂ°  Ã¢ÂÂ round(47/90) = 1 Ã¢ÂÂ 1*90 = 90ÃÂ°
	  Input: 135ÃÂ° Ã¢ÂÂ round(135/90) = 2 Ã¢ÂÂ 2*90 = 180ÃÂ°

	@param angle - ÃÂngulo en grados
	@param increment - Incremento de rotaciÃÂ³n
	@return number - ÃÂngulo snapped
]]
local function snapRotation(angle: number, increment: number): number
	-- Normalizar a [0, 360)
	local normalized = angle % 360
	if normalized < 0 then
		normalized += 360
	end

	-- Snap al incremento
	local snapped = math.round(normalized / increment) * increment

	-- Re-normalizar
	return snapped % 360
end

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	COLLISION DETECTION - AABB Algorithm
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

--[[
	Calcula el bounding box (AABB) de un objeto en una posiciÃÂ³n.

	PROCESO:
	1. Obtener tamaÃÂ±o del objeto
	2. Calcular mitad del tamaÃÂ±o (extents)
	3. Min = Center - Extents
	4. Max = Center + Extents

	NOTA: Asume que el objeto estÃÂ¡ aligned con los ejes (no rotado).
	Para objetos rotados, se necesitarÃÂ­a OBB (Oriented Bounding Box).

	@param center - Centro del objeto
	@param size - TamaÃÂ±o del objeto (Vector3)
	@return BoundingBox - AABB del objeto
]]
local function calculateBoundingBox(center: Vector3, size: Vector3): BoundingBox
	local halfSize = size / 2

	return {
		Min = center - halfSize,
		Max = center + halfSize,
		Center = center,
		Size = size,
	}
end

--[[
	Verifica si dos bounding boxes colisionan (AABB vs AABB).

	ALGORITMO (Separating Axis Theorem simplificado):
	Dos AABB NO colisionan si existe al menos un eje donde estÃÂ¡n separadas.
	Colisionan si se solapan en TODOS los ejes (X, Y, Z).

	CONDICIÃÂN DE COLISIÃÂN (por eje):
	  min1 <= max2 && max1 >= min2

	OPTIMIZACIÃÂN: Early exit en cuanto un eje no colisiona.

	@param box1 - Primer bounding box
	@param box2 - Segundo bounding box
	@param padding - Padding extra (infla las cajas)
	@return boolean - true si colisionan
]]
local function aabbCollision(box1: BoundingBox, box2: BoundingBox, padding: number): boolean
	-- Inflar cajas con padding
	local min1 = box1.Min - Vector3.new(padding, padding, padding)
	local max1 = box1.Max + Vector3.new(padding, padding, padding)
	local min2 = box2.Min - Vector3.new(padding, padding, padding)
	local max2 = box2.Max + Vector3.new(padding, padding, padding)

	-- Verificar solapamiento en X
	if min1.X > max2.X or max1.X < min2.X then
		return false -- Separadas en X
	end

	-- Verificar solapamiento en Y
	if min1.Y > max2.Y or max1.Y < min2.Y then
		return false -- Separadas en Y
	end

	-- Verificar solapamiento en Z
	if min1.Z > max2.Z or max1.Z < min2.Z then
		return false -- Separadas en Z
	end

	-- Se solapan en todos los ejes Ã¢ÂÂ COLISIÃÂN
	return true
end

--[[
	Obtiene el tamaÃÂ±o de un objeto (BasePart, Model, etc).

	PROCESO:
	- Si es BasePart: usar Size directamente
	- Si es Model: calcular GetExtentsSize()
	- Si es otro: retornar tamaÃÂ±o default

	@param object - Instancia del objeto
	@return Vector3 - TamaÃÂ±o del objeto
]]
local function getObjectSize(object: Instance): Vector3
	if object:IsA("BasePart") then
		return object.Size
	elseif object:IsA("Model") then
		-- GetExtentsSize() retorna el tamaÃÂ±o del bounding box del modelo
		local _, size = object:GetBoundingBox()
		return size
	else
		-- Default para objetos desconocidos
		return Vector3.new(5, 5, 5)
	end
end

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	PLACEMENT VALIDATION - Unified Checks
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

--[[
	Valida la altura de colocaciÃÂ³n relativa a la base.

	VALIDACIONES:
	- No demasiado bajo (por debajo del baseplate)
	- No demasiado alto (lÃÂ­mite de construcciÃÂ³n)

	@param basePosition - PosiciÃÂ³n de la base (Vector3)
	@param objectPosition - PosiciÃÂ³n del objeto (Vector3)
	@return boolean, string? - true si es vÃÂ¡lida, error message si no
]]
local function validatePlacementHeight(basePosition: Vector3, objectPosition: Vector3): (boolean, string?)
	local relativeHeight = objectPosition.Y - basePosition.Y

	if relativeHeight < config.MinPlacementHeight then
		return false, string.format(
			"Muy bajo (%.1f studs). MÃÂ­nimo: %.1f studs sobre la base",
			relativeHeight,
			config.MinPlacementHeight
		)
	end

	if relativeHeight > config.MaxPlacementHeight then
		return false, string.format(
			"Muy alto (%.1f studs). MÃÂ¡ximo: %.1f studs sobre la base",
			relativeHeight,
			config.MaxPlacementHeight
		)
	end

	return true
end

--[[
	Valida colisiÃÂ³n con objetos ya colocados en la base.

	ALGORITMO:
	1. Obtener todos los objetos de la base
	2. Calcular bounding box del nuevo objeto
	3. Iterar objetos existentes
	4. Verificar AABB collision con cada uno
	5. Si hay colisiÃÂ³n Ã¢ÂÂ INVÃÂLIDO

	OPTIMIZACIÃÂN: Early exit en la primera colisiÃÂ³n detectada.

	@param ownerId - DueÃÂ±o de la base
	@param position - PosiciÃÂ³n del nuevo objeto
	@param size - TamaÃÂ±o del nuevo objeto
	@return boolean, string? - true si no colisiona
]]
local function validateNoCollision(ownerId: number, position: Vector3, size: Vector3): (boolean, string?)
	if not config.EnableCollision then
		return true -- Collision disabled
	end

	-- Obtener objetos existentes en la base
	local existingObjects = BaseOwnershipService:GetBaseObjects(ownerId)

	-- Calcular bounding box del nuevo objeto
	local newBox = calculateBoundingBox(position, size)

	-- Verificar colisiÃÂ³n con cada objeto existente
	for _, placedObject in ipairs(existingObjects) do
		if placedObject.Instance then
			local existingSize = getObjectSize(placedObject.Instance)
			local existingBox = calculateBoundingBox(placedObject.Position, existingSize)

			if aabbCollision(newBox, existingBox, config.CollisionPadding) then
				return false, string.format(
					"Colisiona con objeto existente: %s (Type: %s)",
					placedObject.ObjectId,
					placedObject.ObjectType
				)
			end
		end
	end

	return true -- No hay colisiones
end

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	PUBLIC API - Service Methods
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

--[[
	Calcula una posiciÃÂ³n vÃÂ¡lida para colocar un objeto (con snapping y validaciÃÂ³n).

	PROCESO COMPLETO:
	1. Snap posiciÃÂ³n al grid (si estÃÂ¡ habilitado)
	2. Snap rotaciÃÂ³n (si estÃÂ¡ habilitado)
	3. Validar permisos (via BaseOwnershipService)
	4. Validar altura
	5. Validar colisiÃÂ³n

	@param userId - ID del jugador
	@param rawPosition - PosiciÃÂ³n raw (sin snap)
	@param rawRotation - RotaciÃÂ³n raw (grados)
	@param objectSize - TamaÃÂ±o del objeto a colocar
	@return PlacementResult - Resultado con posiciÃÂ³n final o error
]]
function BasePlacementService:CalculatePlacement(
	userId: number,
	rawPosition: Vector3,
	rawRotation: number,
	objectSize: Vector3
): PlacementResult
	-- 1. SNAP AL GRID
	local position = rawPosition
	if config.EnableSnapping then
		position = snapPositionToGrid(rawPosition, config.GridSize)
	end

	-- 2. SNAP ROTACIÃÂN
	local rotation = rawRotation
	if config.EnableSnapping then
		rotation = snapRotation(rawRotation, config.RotationIncrement)
	end

	-- 3. VALIDAR PERMISOS (zona y ownership)
	local permissionValidation = BaseOwnershipService:ValidatePlacement(userId, position)
	if not permissionValidation.IsValid then
		return {
			IsValid = false,
			ErrorMessage = permissionValidation.ErrorMessage,
			ErrorCode = permissionValidation.ErrorCode,
		}
	end

	-- 4. VALIDAR ALTURA
	local baseData = BaseSpawnerService:GetBaseData(userId)
	if not baseData then
		return {
			IsValid = false,
			ErrorMessage = "No se encontrÃÂ³ la base del jugador",
			ErrorCode = "BASE_NOT_FOUND",
		}
	end

	local heightValid, heightError = validatePlacementHeight(baseData.Position, position)
	if not heightValid then
		return {
			IsValid = false,
			ErrorMessage = heightError,
			ErrorCode = "INVALID_HEIGHT",
		}
	end

	-- 5. VALIDAR COLISIÃÂN
	local collisionValid, collisionError = validateNoCollision(userId, position, objectSize)
	if not collisionValid then
		return {
			IsValid = false,
			ErrorMessage = collisionError,
			ErrorCode = "COLLISION_DETECTED",
		}
	end

	-- Ã¢ÂÂ TODO VÃÂLIDO
	return {
		IsValid = true,
		Position = position,
		Rotation = rotation,
	}
end

--[[
	Snap una posiciÃÂ³n al grid (utilidad pÃÂºblica).
]]
function BasePlacementService:SnapPosition(position: Vector3): Vector3
	if config.EnableSnapping then
		return snapPositionToGrid(position, config.GridSize)
	end
	return position
end

--[[
	Snap una rotaciÃÂ³n (utilidad pÃÂºblica).
]]
function BasePlacementService:SnapRotation(rotation: number): number
	if config.EnableSnapping then
		return snapRotation(rotation, config.RotationIncrement)
	end
	return rotation
end

--[[
	Actualiza la configuraciÃÂ³n del placement system.
]]
function BasePlacementService:UpdateConfig(newConfig: PlacementConfig?)
	if newConfig then
		for key, value in pairs(newConfig :: any) do
			(config :: any)[key] = value
		end
		print("[BasePlacementService] Configuration updated")
	end
end

--[[
	Obtiene la configuraciÃÂ³n actual.
]]
function BasePlacementService:GetConfig(): PlacementConfig
	return config
end

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	CLIENT API - MÃÂ©todos Expuestos al Cliente
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

--[[
	Calcula placement desde el cliente (para ghost preview).

	IMPORTANTE: Esto es solo para UI preview. El placement REAL se valida
	server-side cuando se registra el objeto.
]]
function BasePlacementService.Client:GetPlacementPreview(
	player: Player,
	position: Vector3,
	rotation: number,
	objectSize: Vector3
)
	return self.Server:CalculatePlacement(player.UserId, position, rotation, objectSize)
end

--[[
	Obtiene el grid size actual (para mostrar en UI).
]]
function BasePlacementService.Client:GetGridSize(player: Player)
	return config.GridSize
end

--[[Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ
	LIFECYCLE HOOKS
Ã¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂÃ¢ÂÂ]]

function BasePlacementService:KnitInit()
	print("[BasePlacementService] Ã¢ÂÂÃ¯Â¸Â Initialized")
end

function BasePlacementService:KnitStart()
	-- Obtener dependencias
	BaseSpawnerService = Knit.GetService("BaseSpawnerService")
	BaseOwnershipService = Knit.GetService("BaseOwnershipService")

	print("[BasePlacementService] Ã¢ÂÂ Started - Grid snapping system ready")
	print(string.format(
		"[BasePlacementService] Config: GridSize=%.1f, Rotation=%dÃÂ°, Collision=%s",
		config.GridSize,
		config.RotationIncrement,
		config.EnableCollision and "ENABLED" or "DISABLED"
	))
end

return BasePlacementService
