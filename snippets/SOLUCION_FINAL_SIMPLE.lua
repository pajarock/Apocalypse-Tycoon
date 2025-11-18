--[[
	═══════════════════════════════════════════════════════════════════════
	SOLUCIÓN FINAL ULTRA-SIMPLE (SIN MODIFICAR MAIN.SERVER.LUA)
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA ACTUAL:
	1. Error línea 530: loop de regeneración compara nil
	2. Dinero se reduce pero autosave lo revierte inmediatamente

	SOLUCIÓN:
	1. Arreglar loop de regeneración (CRÍTICO)
	2. Reducir dinero DESPUÉS del respawn con protección continua

	═══════════════════════════════════════════════════════════════════════
	ARREGLO #1: ERROR LÍNEA 530 (MUY URGENTE)
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: ServerScriptService.BaseModule
	BUSCA: línea ~324-346 (Loop de regeneración)

	CÓDIGO ACTUAL (CON ERROR):
--]]

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			if state.RegenEnabled and state.HP < state.MaxHP then  -- ❌ ESTA LÍNEA DA ERROR
				-- ...
			end
		end
	end
end)

--[[
	REEMPLAZA TODO EL LOOP con esto:
--]]

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			-- ✅ ARREGLADO: Validar que state existe y tiene las propiedades
			if state and type(state) == "table" then
				local hp = state.HP
				local maxHP = state.MaxHP
				local regenEnabled = state.RegenEnabled
				local lastDamageTime = state.LastDamageTime or 0

				-- Solo regenerar si todas las propiedades existen
				if hp and maxHP and regenEnabled and hp < maxHP then
					local timeSinceDamage = tick() - lastDamageTime

					if timeSinceDamage >= Config.BASE_REGEN_DELAY then
						state.HP = math.min(hp + Config.BASE_REGEN_RATE, maxHP)

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
	ARREGLO #2: DINERO NO SE REDUCE (SOLUCIÓN INTELIGENTE)
	═══════════════════════════════════════════════════════════════════════

	EL PROBLEMA:
	- Tu autosave corre cada ~60 segundos
	- Reduces el dinero a $750,000
	- 3 segundos después, autosave guarda $999,999 (el valor viejo en el DataStore)
	- El valor se revierte

	LA SOLUCIÓN:
	Crear un "guardian" que mantenga el dinero reducido hasta el PRÓXIMO autosave.

	UBICACIÓN: ServerScriptService.BaseModule
	BUSCA: Tu función OnBaseDead actual (la que tiene "Dinero reducido")

	AGREGA ESTA NUEVA FUNCIÓN AL FINAL DEL MÓDULO (antes del return):
--]]

-- ✅ NUEVO: Sistema de "guardian" de dinero
local PendingMoneyReductions = {} -- [userId] = {targetAmount, timestamp}

task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, data in pairs(PendingMoneyReductions) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				local leaderstats = player:FindFirstChild("leaderstats")
				local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")

				if cashValue then
					-- Si el dinero está MAYOR al target, forzar reducción
					if cashValue.Value > data.targetAmount then
						cashValue.Value = data.targetAmount

						if DEBUG then
							print(("[BaseModule] 🛡️ Guardian: Forzando dinero de userId %d a $%d"):format(
								userId, data.targetAmount
							))
						end
					end

					-- Después de 120 segundos (2 autosaves), dejar de forzar
					if tick() - data.timestamp > 120 then
						PendingMoneyReductions[userId] = nil
						if DEBUG then
							print(("[BaseModule] ✓ Guardian: Dinero de userId %d asegurado"):format(userId))
						end
					end
				end
			else
				-- Jugador se fue, limpiar
				PendingMoneyReductions[userId] = nil
			end
		end
	end
end)

--[[
	AHORA, MODIFICA TU FUNCIÓN OnBaseDead:

	Busca la parte donde reduces el dinero (algo como):
--]]

-- 2. Restar dinero
if moneyLost > 0 and cashValue then
	local oldMoney = currentMoney

	-- Reducir dinero
	cashValue.Value = math.max(0, currentMoney - moneyLost)

	-- ... tu código actual ...
end

--[[
	REEMPLAZA con esto (agrega el guardian):
--]]

-- 2. Restar dinero (CON GUARDIAN)
if moneyLost > 0 and cashValue then
	local oldMoney = currentMoney
	local newAmount = math.max(0, currentMoney - moneyLost)

	-- Reducir dinero
	cashValue.Value = newAmount

	-- ✅ NUEVO: Activar guardian para mantener el dinero reducido
	PendingMoneyReductions[userId] = {
		targetAmount = newAmount,
		timestamp = tick()
	}

	if DEBUG then
		print(("[BaseModule] 💰 Dinero reducido: $%d → $%d (pérdida: $%d)"):format(
			oldMoney, newAmount, moneyLost
		))
		print(("[BaseModule] 🛡️ Guardian activado por 120 segundos"))
	end
end

--[[
	═══════════════════════════════════════════════════════════════════════
	CÓMO FUNCIONA EL GUARDIAN:
	═══════════════════════════════════════════════════════════════════════

	1. Reduces el dinero de $999,999 → $750,000
	2. Guardian se activa y guarda el valor target: $750,000
	3. Cada segundo, el guardian verifica:
	   - ¿El dinero es mayor a $750,000?
	   - Si SÍ → Lo fuerza de vuelta a $750,000
	4. Después de 120 segundos (2 autosaves), el guardian se desactiva
	5. Para ese entonces, el autosave ya guardó el valor correcto

	RESULTADO:
	✅ El dinero se mantiene reducido sin importar cuántas veces el autosave intente revertirlo
	✅ Después de 2 minutos, el valor está asegurado en el DataStore
	✅ NO necesitas modificar Main.Server.lua

	═══════════════════════════════════════════════════════════════════════
	TESTING:
	═══════════════════════════════════════════════════════════════════════

	Después de implementar:

	1. Presiona Play
	2. Dale $1,000,000 a tu jugador
	3. Deja que la base muera
	4. Verifica en el Output:

	[BaseModule] 💰 Dinero reducido: $999999 → $750000 (pérdida: $249999)
	[BaseModule] 🛡️ Guardian activado por 120 segundos

	5. Espera al autosave (~60s después)
	6. Deberías ver:

	[BaseModule] 🛡️ Guardian: Forzando dinero de userId 3620016515 a $750000
	[DATASTORE] saved uid=3620016515 cash=750000  ← ✅ CORRECTO

	7. Después de 2 minutos:

	[BaseModule] ✓ Guardian: Dinero de userId 3620016515 asegurado

	═══════════════════════════════════════════════════════════════════════
	RESUMEN DE CAMBIOS:
	═══════════════════════════════════════════════════════════════════════

	1️⃣ Arreglar loop de regeneración (líneas 324-346)
	   → Agregar validaciones de nil

	2️⃣ Agregar sistema de Guardian (al final del módulo, antes del return)
	   → 44 líneas de código nuevo

	3️⃣ Modificar OnBaseDead para activar guardian
	   → Agregar PendingMoneyReductions[userId] = {...}

	TIEMPO ESTIMADO: 10 minutos
	ARCHIVOS A MODIFICAR: Solo BaseModule.lua
	MAIN.SERVER.LUA: NO necesitas tocarlo ✅

	═══════════════════════════════════════════════════════════════════════
--]]
