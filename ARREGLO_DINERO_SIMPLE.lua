--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO SIMPLE - Dinero sin DataStoreModule
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	- DataStoreModule no tiene función SavePlayerData
	- El dinero se reduce pero se revierte al hacer autosave
	- El autosave guarda el valor ANTES de la reducción

	SOLUCIÓN:
	En lugar de forzar guardado, simplemente esperar a que el autosave
	lo guarde naturalmente. Pero cambiar el ORDEN del código para que
	el dinero se reduzca y quede reducido hasta el próximo autosave.

	═══════════════════════════════════════════════════════════════════════
	ARREGLO #1: LÍNEA 528 ERROR
	═══════════════════════════════════════════════════════════════════════

	ERROR:
	"attempt to compare nil <= number" en línea 528

	CAUSA:
	Probablemente en el loop de regeneración, está comparando state.HP
	pero state podría ser nil o state.HP podría ser nil.

	UBICACIÓN: ServerScriptService.BaseModule (loop de regeneración, línea ~328-345)

	BUSCA ESTE CÓDIGO:
--]]

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			if state.RegenEnabled and state.HP < state.MaxHP then
				-- Solo regenerar si no ha recibido daño recientemente
				local timeSinceDamage = tick() - state.LastDamageTime

				if timeSinceDamage >= Config.BASE_REGEN_DELAY then
					state.HP = math.min(state.HP + Config.BASE_REGEN_RATE, state.MaxHP)
					-- ...
				end
			end
		end
	end
end)

--[[
	REEMPLAZA CON (agregando validaciones):
--]]

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			-- ✅ ARREGLADO: Validar que state y state.HP existan
			if state and state.HP and state.MaxHP and state.RegenEnabled then
				if state.HP < state.MaxHP then
					-- Solo regenerar si no ha recibido daño recientemente
					local timeSinceDamage = tick() - (state.LastDamageTime or 0)

					if timeSinceDamage >= Config.BASE_REGEN_DELAY then
						state.HP = math.min(state.HP + Config.BASE_REGEN_RATE, state.MaxHP)

						if DEBUG and state.HP % 10 == 0 then
							print(("[BaseModule] Regen - userId %d: %d/%d"):format(
								userId, state.HP, state.MaxHP
							))
						end
					end
				end
			end
		end
	end
end)

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #2: DINERO NO SE REDUCE (SOLUCIÓN SIN DATASTOREMODULE)
	═══════════════════════════════════════════════════════════════════════

	NUEVO ENFOQUE:
	Como tu DataStoreModule no tiene SavePlayerData, vamos a usar una
	solución más simple: reducir el dinero Y marcarlo como "dirty" para
	que el autosave lo guarde en el próximo ciclo.

	UBICACIÓN: ServerScriptService.BaseModule (función OnBaseDead)

	BUSCA LA SECCIÓN DE RESTAR DINERO (líneas donde reduces cashValue.Value):
--]]

-- 2. Restar dinero (CON GUARDADO FORZADO)
if moneyLost > 0 and cashValue then
	local oldMoney = currentMoney

	-- Reducir dinero
	cashValue.Value = math.max(0, currentMoney - moneyLost)

	-- ✅ ARREGLADO: Forzar guardado inmediato con DataStore
	local DataStoreModule = game.ServerScriptService:FindFirstChild("DataStoreModule")
	if DataStoreModule then
		-- ... código del guardado ...
	end
end

--[[
	REEMPLAZA CON ESTA VERSIÓN SIMPLIFICADA:
--]]

-- 2. Restar dinero (SOLUCIÓN SIN DATASTOREMODULE)
if moneyLost > 0 and cashValue then
	local oldMoney = currentMoney

	-- ✅ ARREGLADO: Reducir dinero directamente
	cashValue.Value = math.max(0, currentMoney - moneyLost)

	-- Forzar que se detecte el cambio (trigger para sistemas de guardado)
	if leaderstats then
		leaderstats.Cash.Value = cashValue.Value
	end

	-- Esperar un frame para que se propague el cambio
	task.wait(0.1)

	if DEBUG then
		print(("[BaseModule] 💰 Dinero reducido: $%d → $%d (pérdida: $%d)"):format(
			oldMoney, cashValue.Value, moneyLost
		))
		print(("[BaseModule] ⏱️ Dinero actualizado, autosave lo guardará en próximo ciclo"))
	end
end

--[[
	═══════════════════════════════════════════════════════════════════════
	TESTING:
	═══════════════════════════════════════════════════════════════════════

	Después de aplicar ambos arreglos:

	1. Presiona Play
	2. Dale $1000 a tu jugador
	3. Deja que la base muera
	4. Verifica en el Output:

	[BaseModule] 💀 BASE DESTRUIDA - userId 3620016515
	[BaseModule] 💰 Dinero reducido: $1000 → $750 (pérdida: $250)
	[BaseModule] ⏱️ Dinero actualizado, autosave lo guardará en próximo ciclo

	5. Espera 10 segundos (countdown)
	6. Espera al autosave (puede tardar hasta 60s)
	7. Verifica que dice:

	[DATASTORE] saved uid=3620016515 cash=750  ← ✅ CORRECTO
	[AUTOSAVE] Guardado: averockMx ($750)

	═══════════════════════════════════════════════════════════════════════
	SI SIGUE SIN FUNCIONAR:
	═══════════════════════════════════════════════════════════════════════

	Si después del autosave sigue mostrando $999999:

	OPCIÓN ALTERNATIVA: Desactivar autosave durante OnBaseDead

	Agrega ANTES de reducir el dinero:
--]]

-- Marcar que estamos en proceso de penalización (evitar autosave)
player:SetAttribute("InDeathPenalty", true)

-- Reducir dinero
cashValue.Value = math.max(0, currentMoney - moneyLost)

-- Esperar frame
task.wait(0.1)

-- Des-marcar
player:SetAttribute("InDeathPenalty", false)

--[[
	Y luego en tu sistema de autosave (Main.Server.lua), modificar para:
--]]

-- En el loop de autosave, agregar check:
if player:GetAttribute("InDeathPenalty") then
	-- Skip este jugador, está en penalización
	continue
end

--[[
	═══════════════════════════════════════════════════════════════════════
	RESUMEN:
	═══════════════════════════════════════════════════════════════════════

	✅ ARREGLO #1: Validar state.HP en loop de regeneración
	✅ ARREGLO #2: Simplificar reducción de dinero sin DataStoreModule

	Implementa ambos arreglos y prueba. Si el dinero SIGUE sin reducirse,
	usa la OPCIÓN ALTERNATIVA con SetAttribute.

	═══════════════════════════════════════════════════════════════════════
--]]
