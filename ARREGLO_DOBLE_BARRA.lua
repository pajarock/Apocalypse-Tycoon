--[[
═══════════════════════════════════════════════════════════════════════
🎯 ARREGLO: DOBLE BARRA DE VIDA (5 MINUTOS)
═══════════════════════════════════════════════════════════════════════

PROBLEMA:
Aparecen 2 health bars / bases en el juego porque hay código duplicado
en Main.Server.lua función assignBase.

CAUSA:
- Líneas 412-426: BaseVisualsManager crea base ✅ (correcto)
- Líneas 428-455: Código viejo crea OTRA base ❌ (duplicado)

═══════════════════════════════════════════════════════════════════════
📋 SOLUCIÓN
═══════════════════════════════════════════════════════════════════════

Archivo: ServerScriptService.Main.Server
Función: assignBase (cerca de línea 403)

PASO 1: BUSCAR la función assignBase
────────────────────────────────────────────────────────────────────────
Busca estas líneas (cerca de línea 412):

```lua
-- 🆕 USAR BaseVisualsManager en lugar de crear base manualmente
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
```

PASO 2: BORRAR TODO EL CÓDIGO DUPLICADO DESPUÉS
────────────────────────────────────────────────────────────────────────
INMEDIATAMENTE DESPUÉS de ese bloque, hay código duplicado que empieza:

```lua
local plate = Instance.new("Part")
plate.Name = plr.Name .. "_Base"
```

BORRA TODO desde ahí hasta (y incluyendo):

```lua
if DEBUG then
	print(("[BASE] Asignada base slot %d a %s"):format(slot, plr.Name))
end
```

Es decir, BORRAR líneas 428-455 completas.

PASO 3: RESULTADO FINAL
────────────────────────────────────────────────────────────────────────
La función assignBase debe quedar así:
--]]

local function assignBase(plr: Player, slot: number)
	local totalSlots = math.max(NextSlot - 1, 1)
	local angle = ((slot - 1) / totalSlots) * 2 * math.pi
	local center = Vector3.new(
		math.cos(angle) * Config.SPAWN_RING_RADIUS,
		Config.BASE_SPAWN_HEIGHT,
		math.sin(angle) * Config.SPAWN_RING_RADIUS
	)

	-- 🆕 USAR BaseVisualsManager en lugar de crear base manualmente
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
end

--[[
═══════════════════════════════════════════════════════════════════════
✅ ¡ESO ES TODO!

RESULTADO ESPERADO:
- ✅ Solo UNA base por jugador
- ✅ Solo UNA health bar (la de BaseVisualsManager)
- ✅ Base con efectos visuales correctos
- ✅ Billboard actualizado en tiempo real

═══════════════════════════════════════════════════════════════════════
🧪 TESTING

1. Aplica el cambio
2. Guarda (Ctrl+S)
3. Reinicia el servidor
4. Únete al juego
5. Verifica:
   - Solo 1 base visible
   - Solo 1 health bar
   - Health bar se actualiza cuando recibes daño

═══════════════════════════════════════════════════════════════════════
]]
