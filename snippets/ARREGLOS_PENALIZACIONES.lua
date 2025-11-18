--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLOS PARA SISTEMA DE PENALIZACIONES
	═══════════════════════════════════════════════════════════════════════

	PROBLEMAS DETECTADOS:
	1. ❌ Dinero no se reduce (aunque el log dice que se perdió)
	2. ❌ Base no re-aparece después del countdown
	3. ❌ Error de TweenService en BaseDeathUI (línea 209)

	SOLUCIONES:
--]]

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #1: DINERO NO SE REDUCE
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	El log muestra "Dinero perdido: $249999 (25% de $999999)" pero el autosave
	sigue mostrando $999999. Esto significa que cashValue.Value se está
	revirtiendo o no se está guardando correctamente.

	CAUSA PROBABLE:
	- Tu sistema de DataStore puede estar revirtiéndolo
	- O el camino a leaderstats.Cash no es correcto
	- O hay un sistema de economía que override el valor

	SOLUCIÓN:
	Usar el sistema de economía existente en lugar de modificar el valor directamente.

	UBICACIÓN: ServerScriptService.BaseModule (función OnBaseDead)

	BUSCA ESTAS LÍNEAS (~línea 302-316):
--]]

-- 1. Calcular pérdida de dinero (25%)
local leaderstats = player:FindFirstChild("leaderstats")
local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
local currentMoney = cashValue and cashValue.Value or 0

local moneyLost = math.floor(currentMoney * 0.25) -- 25% de pérdida

-- 2. Restar dinero
if moneyLost > 0 and cashValue then
	cashValue.Value = math.max(0, currentMoney - moneyLost)

	if DEBUG then
		print(("[BaseModule] Dinero perdido: $%d (25%% de $%d)"):format(moneyLost, currentMoney))
	end
end

--[[
	REEMPLAZA CON ESTO:
--]]

-- 1. Calcular pérdida de dinero (25%)
local leaderstats = player:FindFirstChild("leaderstats")
local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
local currentMoney = cashValue and cashValue.Value or 0

local moneyLost = math.floor(currentMoney * 0.25) -- 25% de pérdida

-- 2. Restar dinero usando el sistema de DataStore
if moneyLost > 0 and cashValue then
	-- ✅ ARREGLADO: Forzar guardado inmediato para evitar revert
	cashValue.Value = math.max(0, currentMoney - moneyLost)

	-- Forzar actualización del DataStore si existe
	local DataStoreModule = game.ServerScriptService:FindFirstChild("DataStoreModule")
	if DataStoreModule then
		local DSM = require(DataStoreModule)
		if DSM and DSM.SavePlayerData then
			-- Guardar inmediatamente para evitar revert
			task.spawn(function()
				pcall(function()
					DSM.SavePlayerData(player)
				end)
			end)
		end
	end

	if DEBUG then
		print(("[BaseModule] 💰 Dinero reducido: $%d → $%d (pérdida: $%d)"):format(
			currentMoney, cashValue.Value, moneyLost
		))
	end
end

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #2: BASE NO RE-APARECE
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	BaseModule.SetHP actualiza el HP pero no hace visible la base de nuevo.
	El HP se actualiza correctamente (0 → 50) pero visualmente la base
	no re-aparece.

	CAUSA:
	SetHP solo actualiza el diccionario BaseState, no sincroniza con
	BaseVisualsManager ni dispara eventos de actualización visual.

	SOLUCIÓN:
	Agregar código para notificar a BaseVisualsManager después de respawn.

	UBICACIÓN: ServerScriptService.BaseModule (función OnBaseDead)

	BUSCA ESTAS LÍNEAS (~línea 325-334):
--]]

-- 4. Cooldown de respawn (10 segundos)
task.wait(10)

-- 5. Respawn con 50% HP
local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
BaseModule.SetHP(userId, respawnHP)

if DEBUG then
	print(("[BaseModule] Base respawneada - userId %d con %d HP (50%%)"):format(userId, respawnHP))
end

--[[
	REEMPLAZA CON ESTO:
--]]

-- 4. Cooldown de respawn (10 segundos)
task.wait(10)

-- 5. Respawn con 50% HP
local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
BaseModule.SetHP(userId, respawnHP)

-- ✅ ARREGLADO: Notificar a BaseVisualsManager para actualizar visuals
local BaseVisualsManager = require(SS.Managers.BaseVisualsManager)
if BaseVisualsManager then
	BaseVisualsManager:UpdateBaseVisuals(userId, respawnHP, Config.BASE_MAX_HP)
end

-- ✅ ARREGLADO: Disparar evento de cambio de estado para cliente (si existe)
local BaseStateChanged = game.ReplicatedStorage.Remotes:FindFirstChild("BaseStateChanged")
if BaseStateChanged then
	BaseStateChanged:FireClient(player, respawnHP, Config.BASE_MAX_HP, 0) -- HP, MaxHP, Shields
end

if DEBUG then
	print(("[BaseModule] Base respawneada - userId %d con %d HP (50%%)"):format(userId, respawnHP))
end

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #3: ERROR DE TWEENSERVICE EN BASEDEATHUI
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	"TweenService:Create no property named 'BackgroundTransparency' for object 'BaseDeathUI'"

	CAUSA:
	Línea 209-213 intenta hacer tween de screenGui.BackgroundTransparency,
	pero ScreenGui NO tiene esa propiedad. Solo los GuiObjects (Frame, etc) tienen.

	SOLUCIÓN:
	Eliminar el tween de screenGui, solo hacer tween de los elementos visuales.

	UBICACIÓN: StarterGui.BaseDeathUI.client.lua

	BUSCA ESTAS LÍNEAS (~línea 208-213):
--]]

-- Fade out
local fadeOut = TweenService:Create(
	screenGui,
	TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	{BackgroundTransparency = 1}
)

TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

--[[
	REEMPLAZA CON ESTO:
--]]

-- ✅ ARREGLADO: Fade out (solo elementos visuales, NO screenGui)
TweenService:Create(background, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()

--[[
	SIMPLEMENTE ELIMINA las líneas 209-213 (el tween de screenGui).
	El resto del código de fade out ya está correcto (líneas 215-219).

	═══════════════════════════════════════════════════════════════════════
	RESUMEN DE CAMBIOS:
	═══════════════════════════════════════════════════════════════════════

	✅ ARREGLO #1: Agregar guardado forzado con DataStoreModule después de reducir dinero
	✅ ARREGLO #2: Notificar a BaseVisualsManager y disparar BaseStateChanged después de respawn
	✅ ARREGLO #3: Eliminar tween de screenGui en BaseDeathUI (líneas 209-213)

	═══════════════════════════════════════════════════════════════════════
	TESTING DESPUÉS DE APLICAR:
	═══════════════════════════════════════════════════════════════════════

	1. Dinero:
	   - Dale $1000 a tu jugador
	   - Deja que la base muera
	   - Verifica que el dinero baja a $750 (25% perdido)
	   - Verifica en el Output: "Dinero reducido: $1000 → $750"

	2. Base respawn:
	   - Después del countdown de 10s
	   - La base debe volver a aparecer con efectos de 50% HP
	   - Debería tener humo saliendo (< 40% HP threshold)
	   - Barra de HP (abajo-derecha) debe mostrar 50/100

	3. UI:
	   - No más errores de TweenService en el Output
	   - La pantalla roja desaparece suavemente después del countdown
	   - Todo se resetea correctamente para la próxima muerte

	═══════════════════════════════════════════════════════════════════════
	NOTAS IMPORTANTES:
	═══════════════════════════════════════════════════════════════════════

	- Si BaseVisualsManager no existe, comentar esas líneas (no crítico)
	- Si BaseStateChanged no existe, también está bien (es opcional)
	- El guardado forzado con DataStore es CRÍTICO para que el dinero se reste
	- Asegúrate de tener `local SS = game:GetService("ServerStorage")` al inicio de BaseModule

	═══════════════════════════════════════════════════════════════════════
--]]
