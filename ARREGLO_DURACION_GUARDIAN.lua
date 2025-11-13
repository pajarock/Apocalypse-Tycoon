--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO FINAL - Guardian de 120 Segundos
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	- Guardian rápido termina en 15s
	- Pero autosave pasa 32s después
	- El dinero vuelve a subir porque el guardian ya no está activo

	SOLUCIÓN:
	Cambiar la duración del guardian rápido de 15s → 120s

	═══════════════════════════════════════════════════════════════════════
	CAMBIO MUY SIMPLE (1 LÍNEA)
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: ServerScriptService.BaseModule
	FUNCIÓN: OnBaseDead
	SECCIÓN: 2. RESTAR DINERO

	Busca esta línea (aproximadamente línea 365):
--]]

local forceDuration = 15 -- Forzar por 15 segundos

--[[
	CÁMBIALA A:
--]]

local forceDuration = 120 -- Forzar por 120 segundos (2 minutos)

--[[
	═══════════════════════════════════════════════════════════════════════
	ESO ES TODO.
	═══════════════════════════════════════════════════════════════════════

	Cambia solo el número 15 → 120
	Guarda (Ctrl+S)
	Prueba de nuevo

	RESULTADO:
	- Guardian rápido durará 2 minutos completos
	- Cubrirá todos los autosaves que pasen
	- Después de 2 minutos, el guardian normal seguirá activo
	- El dinero permanecerá en $750,000 (o lo que corresponda)

	OUTPUT ESPERADO:
	[BaseModule] 🛡️ Guardian rápido terminado (120s)  ← Ahora dice 120s
	[DATASTORE] saved uid=3620016515 cash=750000  ← CORRECTO
	[AUTOSAVE] Guardado: averockMx ($750000)  ← CORRECTO

	═══════════════════════════════════════════════════════════════════════
--]]
