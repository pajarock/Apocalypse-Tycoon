--[[
═══════════════════════════════════════════════════════════════════════
🔍 DIAGNÓSTICO Y SOLUCIÓN: Doble Barra de Vida Persistente
═══════════════════════════════════════════════════════════════════════

PROBLEMA:
Después de borrar el código duplicado, SIGUEN apareciendo 2 barras de vida.

POSIBLES CAUSAS:
1. Bases viejas en Workspace de sesiones anteriores
2. Código no se aplicó correctamente
3. Hay otro lugar creando billboards
4. Cache de Studio

SOLUCIÓN PASO A PASO:
═══════════════════════════════════════════════════════════════════════
]]

--═══════════════════════════════════════════════════════════════════════
-- PASO 1: VERIFICAR QUE EL CÓDIGO ESTÁ BIEN
--═══════════════════════════════════════════════════════════════════════

--[[
Archivo: ServerScriptService.Main.Server
Función: assignBase (línea ~403)

DEBE VERSE ASÍ (SOLO UN BLOQUE):
]]

local function assignBase(plr: Player, slot: number)
	local totalSlots = math.max(NextSlot - 1, 1)
	local angle = ((slot - 1) / totalSlots) * 2 * math.pi
	local center = Vector3.new(
		math.cos(angle) * Config.SPAWN_RING_RADIUS,
		Config.BASE_SPAWN_HEIGHT,
		math.sin(angle) * Config.SPAWN_RING_RADIUS
	)

	-- ✅ SOLO ESTE BLOQUE DEBE EXISTIR
	local plate = BaseVisualsManager:CreateBase(
		plr.UserId,
		center,
		plr.Name,
		Config.BASE_SIZE
	)

	plate.Parent = getBasesFolder()
	BasePartByUser[plr.UserId] = plate
	plr:SetAttribute("BaseSlot", slot)

	if DEBUG then
		print(("[BASE] Asignada base slot %d a %s"):format(slot, plr.Name))
	end
end  -- ← La función TERMINA AQUÍ

--[[
❌ SI DESPUÉS DE "end" VES ALGO COMO ESTO, BÓRRALO:

	local plate = Instance.new("Part")
	plate.Name = plr.Name .. "_Base"
	...
	BasePartByUser[plr.UserId] = plate
	...
	if DEBUG then
		print(...)
	end

BORRA TODO ESO hasta el SEGUNDO "if DEBUG then ... end"
]]

--═══════════════════════════════════════════════════════════════════════
-- PASO 2: LIMPIAR BASES VIEJAS AL INICIAR SERVIDOR
--═══════════════════════════════════════════════════════════════════════

--[[
Archivo: ServerScriptService.Main.Server
Ubicación: DESPUÉS de la sección de "PLAYER LIFECYCLE" pero ANTES de PlayerAdded

Busca esta sección (cerca de línea 1555):
	-- PLAYER LIFECYCLE
	--═════════════════════════════════════════════════════════════════

ANTES de "Players.PlayerAdded:Connect", agrega este código:
]]

--═══════════════════════════════════════════════════════════════════════
-- 🧹 LIMPIEZA INICIAL: Borrar bases de sesiones anteriores
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════
-- PASO 3: FUNCIÓN DE DIAGNÓSTICO (TEMPORAL)
--═══════════════════════════════════════════════════════════════════════

--[[
Si SIGUEN apareciendo 2 barras, agrega esta función de diagnóstico
para identificar qué las está creando:

Ubicación: En Main.Server, DESPUÉS de assignBase pero ANTES de PlayerAdded
]]

-- 🔍 DIAGNÓSTICO: Detectar múltiples billboards
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

--[[
Luego, EN PlayerAdded, justo DESPUÉS de assignBase, agrega:

	assignBase(plr, slot)

	-- ✅ DIAGNÓSTICO TEMPORAL
	if Config.DEBUG_MODE then
		diagnosticBillboards(plr.UserId)
	end
]]

--═══════════════════════════════════════════════════════════════════════
-- PASO 4: SOLUCIÓN NUCLEAR - Destruir Billboards Duplicadas
--═══════════════════════════════════════════════════════════════════════

--[[
Si el diagnóstico confirma que hay 2+ billboards, agrega esta función
que las detecta y destruye las duplicadas:

Ubicación: Main.Server, después de assignBase
]]

local function cleanupDuplicateBillboards(userId: number)
	task.delay(1, function()
		local basesFolder = workspace:FindFirstChild("Bases")
		if not basesFolder then return end

		local billboards = {}

		-- Encontrar todos los billboards del usuario
		for _, obj in ipairs(basesFolder:GetDescendants()) do
			if obj:IsA("BillboardGui") then
				local parent = obj.Parent
				if parent and parent:GetAttribute("OwnerUserId") == userId then
					table.insert(billboards, obj)
				end
			end
		end

		-- Si hay más de 1, destruir los extras
		if #billboards > 1 then
			warn(("[CLEANUP] ⚠️ Encontradas %d billboards para userId %d, limpiando..."):format(
				#billboards, userId
			))

			-- Mantener solo el primero (asumiendo que es el correcto)
			for i = 2, #billboards do
				billboards[i]:Destroy()
				print(("[CLEANUP] ✅ Billboard duplicada destruida"):format())
			end
		end
	end)
end

--[[
Luego, EN PlayerAdded, justo DESPUÉS de assignBase:

	assignBase(plr, slot)

	-- ✅ LIMPIEZA AUTOMÁTICA
	cleanupDuplicateBillboards(plr.UserId)
]]

--═══════════════════════════════════════════════════════════════════════
-- RESUMEN DE PASOS
--═══════════════════════════════════════════════════════════════════════

--[[
1. ✅ Verificar que assignBase() solo tiene UN bloque de código
2. ✅ Agregar limpieza inicial al servidor (borra bases viejas)
3. 🔍 Agregar diagnóstico temporal para ver qué pasa
4. 🧹 Agregar cleanup automático de billboards duplicadas

TESTING:
1. Aplica los cambios
2. REINICIA el servidor completo (Stop + Play)
3. Únete al juego
4. Revisa el Output:
   [MAIN] 🧹 Limpiando bases de sesiones anteriores...
   [MAIN] ✅ Limpiadas X bases viejas
   [BASE] Asignada base slot 1 a TuNombre
   [DIAGNOSTIC] Base encontrada: TuNombre_Base
   [DIAGNOSTIC] Billboard #1: Parent = TuNombre_Base
   [DIAGNOSTIC] RESUMEN userId XXX: 1 bases, 1 billboards  ← DEBE SER 1

SI DICE "2 billboards":
   [CLEANUP] ⚠️ Encontradas 2 billboards para userId XXX, limpiando...
   [CLEANUP] ✅ Billboard duplicada destruida

RESULTADO ESPERADO:
- Solo 1 base visible
- Solo 1 health bar
- Output confirma: "1 bases, 1 billboards"
]]
