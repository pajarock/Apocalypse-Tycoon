--[[
	═══════════════════════════════════════════════════════════════════════
	SOLUCIÓN FINAL - Guardian Inmediato + Protección Continua
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA ENCONTRADO:
	- El dinero SÍ se reduce a $750,000 ✅
	- Guardian se activa ✅
	- PERO autosave guarda $999,999 (valor viejo del DataStore) ❌

	CAUSA:
	- Tu autosave es rápido (cada ~10 segundos)
	- Guardian verifica cada 1 segundo
	- Autosave pasa ANTES de que guardian pueda forzar

	SOLUCIÓN:
	- Guardian debe actuar INMEDIATAMENTE después de reducir
	- Y luego seguir vigilando cada segundo

	═══════════════════════════════════════════════════════════════════════
	PASO ÚNICO: REEMPLAZAR SECCIÓN 2 DE OnBaseDead
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: ServerScriptService.BaseModule
	BUSCA: Tu función OnBaseDead (la que acabas de pegar)

	Busca esta sección (aproximadamente líneas 323-377):
--]]

	-- ═══════════════════════════════════════════════════════════════════
	-- 2. RESTAR DINERO (CON DEBUG EXTENSO)
	-- ═══════════════════════════════════════════════════════════════════

	if moneyLost > 0 and cashValue then
		local oldMoney = currentMoney

		-- Debug: Verificar ANTES de la resta
		if DEBUG then
			print(("[BaseModule] 💵 ANTES - Cash.Value: $%d"):format(cashValue.Value))
		end

		-- Calcular nuevo valor
		local newAmount = math.max(0, currentMoney - moneyLost)

		-- Debug: Mostrar cálculo
		if DEBUG then
			print(("[BaseModule] 🧮 Cálculo: $%d - $%d = $%d"):format(currentMoney, moneyLost, newAmount))
		end

		-- CRÍTICO: Reducir dinero
		cashValue.Value = newAmount

		-- Debug: Verificar DESPUÉS de la resta
		if DEBUG then
			print(("[BaseModule] 💵 DESPUÉS - Cash.Value: $%d"):format(cashValue.Value))
		end

		-- ✅ Activar guardian SOLO si la reducción funcionó
		if cashValue.Value == newAmount then
			PendingMoneyReductions[userId] = {
				targetAmount = newAmount,
				timestamp = tick()
			}

			if DEBUG then
				print(("[BaseModule] 🛡️ Guardian activado - Target: $%d"):format(newAmount))
			end
		else
			warn(("[BaseModule] ⚠️ ALERTA: Dinero NO se redujo! Esperado: $%d, Actual: $%d"):format(
				newAmount, cashValue.Value
			))
		end

		-- Debug final
		if DEBUG then
			print(("[BaseModule] 💰 Dinero reducido: $%d → $%d (pérdida: $%d)"):format(
				oldMoney, cashValue.Value, moneyLost
			))
		end
	else
		if DEBUG then
			print(("[BaseModule] ℹ️ Sin dinero para perder (tiene $%d)"):format(currentMoney))
		end
	end

--[[
	REEMPLAZA TODA ESA SECCIÓN con el código de abajo (líneas 94-177):
--]]

	-- ═══════════════════════════════════════════════════════════════════
	-- 2. RESTAR DINERO (CON GUARDIAN INMEDIATO)
	-- ═══════════════════════════════════════════════════════════════════

	if moneyLost > 0 and cashValue then
		local oldMoney = currentMoney

		-- Debug: Verificar ANTES de la resta
		if DEBUG then
			print(("[BaseModule] 💵 ANTES - Cash.Value: $%d"):format(cashValue.Value))
		end

		-- Calcular nuevo valor
		local newAmount = math.max(0, currentMoney - moneyLost)

		-- Debug: Mostrar cálculo
		if DEBUG then
			print(("[BaseModule] 🧮 Cálculo: $%d - $%d = $%d"):format(currentMoney, moneyLost, newAmount))
		end

		-- CRÍTICO: Reducir dinero
		cashValue.Value = newAmount

		-- Debug: Verificar DESPUÉS de la resta
		if DEBUG then
			print(("[BaseModule] 💵 DESPUÉS - Cash.Value: $%d"):format(cashValue.Value))
		end

		-- ✅ Activar guardian SOLO si la reducción funcionó
		if cashValue.Value == newAmount then
			PendingMoneyReductions[userId] = {
				targetAmount = newAmount,
				timestamp = tick()
			}

			if DEBUG then
				print(("[BaseModule] 🛡️ Guardian activado - Target: $%d"):format(newAmount))
			end

			-- ✅ NUEVO: Forzar el valor INMEDIATAMENTE en un loop rápido
			-- Esto evita que el autosave guarde el valor viejo
			task.spawn(function()
				local forceDuration = 15 -- Forzar por 15 segundos
				local startTime = tick()

				while tick() - startTime < forceDuration do
					-- Verificar cada 0.1 segundos (muy rápido)
					task.wait(0.1)

					-- Re-obtener referencias por si acaso
					local plr = Players:GetPlayerByUserId(userId)
					if not plr then break end

					local stats = plr:FindFirstChild("leaderstats")
					local cash = stats and stats:FindFirstChild("Cash")

					if cash then
						-- Si el valor es diferente al target, forzarlo de vuelta
						if cash.Value ~= newAmount then
							cash.Value = newAmount

							if DEBUG then
								print(("[BaseModule] 🛡️ Guardian FORZÓ dinero a $%d (era $%d)"):format(
									newAmount, cash.Value
								))
							end
						end
					else
						-- Sin Cash, terminar
						break
					end
				end

				if DEBUG then
					print(("[BaseModule] 🛡️ Guardian rápido terminado (15s)"):format())
				end
			end)

		else
			warn(("[BaseModule] ⚠️ ALERTA: Dinero NO se redujo! Esperado: $%d, Actual: $%d"):format(
				newAmount, cashValue.Value
			))
		end

		-- Debug final
		if DEBUG then
			print(("[BaseModule] 💰 Dinero reducido: $%d → $%d (pérdida: $%d)"):format(
				oldMoney, cashValue.Value, moneyLost
			))
		end
	else
		if DEBUG then
			print(("[BaseModule] ℹ️ Sin dinero para perder (tiene $%d)"):format(currentMoney))
		end
	end

--[[
	═══════════════════════════════════════════════════════════════════════
	QUÉ HACE ESTA VERSIÓN:
	═══════════════════════════════════════════════════════════════════════

	1. Reduce el dinero a $750,000 ✅
	2. Activa el guardian normal (cada 1 segundo por 120s)
	3. 🆕 NUEVO: Activa un guardian RÁPIDO que:
	   - Verifica cada 0.1 segundos (10 veces por segundo)
	   - Fuerza el valor de vuelta si cambió
	   - Dura 15 segundos (suficiente para 1-2 autosaves)
	   - Luego termina y deja al guardian normal

	RESULTADO:
	- El autosave puede intentar guardar $999,999
	- Pero el guardian rápido lo detecta en 0.1 segundos
	- Y lo fuerza de vuelta a $750,000
	- El siguiente autosave guardará $750,000 ✅

	═══════════════════════════════════════════════════════════════════════
	TESTING DESPUÉS DE APLICAR:
	═══════════════════════════════════════════════════════════════════════

	1. Presiona Play
	2. Dale $1,000,000
	3. Deja que la base muera
	4. Verifica el Output:

	[BaseModule] 💰 Dinero reducido: $999999 → $750000 (pérdida: $249999)
	[BaseModule] 🛡️ Guardian activado - Target: $750000

	... (espera al autosave ~10s) ...

	[BaseModule] 🛡️ Guardian FORZÓ dinero a $750000 (era $999999)
	[DATASTORE] saved uid=3620016515 cash=750000  ← ✅ CORRECTO

	... (15s después) ...

	[BaseModule] 🛡️ Guardian rápido terminado (15s)

	═══════════════════════════════════════════════════════════════════════
	SI SIGUE SIN FUNCIONAR:
	═══════════════════════════════════════════════════════════════════════

	Si ves en el Output:
	[DATASTORE] saved uid=3620016515 cash=999999

	Y NO ves:
	[BaseModule] 🛡️ Guardian FORZÓ dinero a $750000

	Entonces el problema es que tu DataStore guarda el valor VIEJO
	y NO lee de Cash.Value.

	En ese caso, necesitaremos modificar el DataStore directamente.
	PERO espera el resultado de esta prueba primero.

	═══════════════════════════════════════════════════════════════════════
--]]
