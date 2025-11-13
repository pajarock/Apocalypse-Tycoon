--[[
	═══════════════════════════════════════════════════════════════════════
	DIAGNÓSTICO Y ARREGLOS FINALES
	═══════════════════════════════════════════════════════════════════════

	PROBLEMAS ACTUALES:
	1. Spam de guardian (x40 por segundo) - algo cambia el dinero constantemente
	2. Error línea 611 - comparación con nil
	3. Autosave guarda $999,999 - valor viejo

	═══════════════════════════════════════════════════════════════════════
	ARREGLO #1: ERROR LÍNEA 611
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: ServerScriptService.BaseModule
	Loop de regeneración (línea ~611)

	Este es el mismo error que intentamos arreglar antes.
	Busca el loop de regeneración:
--]]

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			if state.RegenEnabled and state.HP < state.MaxHP then  -- ❌ ESTA LÍNEA
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
			-- ✅ ARREGLADO: Validar todo antes de comparar
			if state and type(state) == "table" then
				local hp = state.HP
				local maxHP = state.MaxHP
				local regenEnabled = state.RegenEnabled
				local lastDamageTime = state.LastDamageTime or 0

				if hp and maxHP and regenEnabled and type(hp) == "number" and type(maxHP) == "number" then
					if hp < maxHP then
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
	end
end)

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #2: MEJORAR DEBUG DEL GUARDIAN
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: Función OnBaseDead, dentro del guardian rápido

	Busca esta sección (~línea 380-392):
--]]

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

--[[
	REEMPLAZA con esto (guarda valor ANTES de cambiar):
--]]

if cash then
	-- Si el valor es diferente al target, forzarlo de vuelta
	if cash.Value ~= newAmount then
		local oldValue = cash.Value  -- ✅ Guardar ANTES
		cash.Value = newAmount

		if DEBUG then
			print(("[BaseModule] 🛡️ Guardian FORZÓ dinero: $%d → $%d (target: $%d)"):format(
				oldValue, cash.Value, newAmount
			))
		end
	end
else
	-- Sin Cash, terminar
	break
end

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #3: AGREGAR DETECTIVE AL GUARDIAN
	═══════════════════════════════════════════════════════════════════════

	Vamos a averiguar QUÉ está cambiando el dinero.

	En el mismo guardian rápido, DESPUÉS del if cash.Value ~= newAmount,
	agrega esto:
--]]

if cash then
	if cash.Value ~= newAmount then
		local oldValue = cash.Value

		-- ✅ DETECTIVE: ¿Quién cambió el dinero?
		if DEBUG then
			print(("[BaseModule] 🔍 DETECTIVE: Dinero cambió de $%d a $%d (debería ser $%d)"):format(
				newAmount, oldValue, newAmount
			))

			-- Ver si hay algún script modificando
			local changed = cash:GetPropertyChangedSignal("Value")
			if changed then
				print(("[BaseModule] 🔍 Cash.Value tiene listeners activos"):format())
			end
		end

		cash.Value = newAmount

		if DEBUG then
			print(("[BaseModule] 🛡️ Guardian FORZÓ dinero: $%d → $%d (target: $%d)"):format(
				oldValue, cash.Value, newAmount
			))
		end
	end
else
	break
end

--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO #4: DESACTIVAR TEMPORALMENTE EL GUARDIAN NORMAL
	═══════════════════════════════════════════════════════════════════════

	El guardian normal (el que verifica cada 1 segundo) puede estar
	compitiendo con el guardian rápido.

	UBICACIÓN: Al final de BaseModule, antes de return

	Busca este código:
--]]

task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, data in pairs(PendingMoneyReductions) do
			-- ... código del guardian normal
		end
	end
end)

--[[
	COMENTA TODO ESE BLOQUE temporalmente:
--]]

--[[ ✅ DESACTIVADO TEMPORALMENTE PARA TESTING
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, data in pairs(PendingMoneyReductions) do
			-- ... código del guardian normal
		end
	end
end)
--]]

--[[
	═══════════════════════════════════════════════════════════════════════
	TESTING:
	═══════════════════════════════════════════════════════════════════════

	Después de aplicar los 4 arreglos:

	1. Presiona Play
	2. Deja que la base muera UNA vez
	3. PEGA TODO EL OUTPUT

	Busca específicamente:
	- 🔍 DETECTIVE: ¿Qué dice?
	- 🛡️ Guardian FORZÓ: ¿Cuántas veces aparece?
	- ¿Qué valores muestra? ($X → $Y)

	Esto nos dirá EXACTAMENTE qué está cambiando el dinero.

	═══════════════════════════════════════════════════════════════════════
--]]
