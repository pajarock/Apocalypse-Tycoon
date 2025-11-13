--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO - ERROR LÍNEA 528 (attempt to compare nil <= number)
	═══════════════════════════════════════════════════════════════════════

	ERROR:
	ServerScriptService.BaseModule:528: attempt to compare nil <= number

	CAUSA:
	En el loop de regeneración, está comparando state.HP < state.MaxHP
	pero state.HP o state.MaxHP puede ser nil en el primer ciclo.

	UBICACIÓN: ServerScriptService.BaseModule
	BUSCA: "Loop de regeneración" o "task.spawn(function()"
	(Aproximadamente líneas 325-346)

	═══════════════════════════════════════════════════════════════════════
	CÓDIGO ACTUAL (CON ERROR):
	═══════════════════════════════════════════════════════════════════════
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

					if DEBUG and state.HP % 10 == 0 then
						print(("[BaseModule] Regen - userId %d: %d/%d"):format(
							userId, state.HP, state.MaxHP
						))
					end
				end
			end
		end
	end
end)

--[[
	═══════════════════════════════════════════════════════════════════════
	CÓDIGO ARREGLADO (CON VALIDACIONES):
	═══════════════════════════════════════════════════════════════════════

	Reemplaza el código de arriba con esto:
--]]

-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1) -- Check cada segundo

		for userId, state in pairs(BaseState) do
			-- ✅ ARREGLADO: Validar que todas las propiedades existan
			if state then
				-- Validar que HP, MaxHP y LastDamageTime existan
				local hp = state.HP
				local maxHP = state.MaxHP
				local regenEnabled = state.RegenEnabled
				local lastDamageTime = state.LastDamageTime or 0

				-- Solo regenerar si todo está definido
				if hp and maxHP and regenEnabled and hp < maxHP then
					-- Solo regenerar si no ha recibido daño recientemente
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
	QUÉ CAMBIÓ:
	═══════════════════════════════════════════════════════════════════════

	1. Agregado check: if state then
	2. Guardado propiedades en variables locales
	3. Validar que hp, maxHP existan antes de comparar
	4. Default de lastDamageTime a 0 si es nil
	5. Usar las variables locales en lugar de state.HP directamente

	RESULTADO:
	✅ No más errores "attempt to compare nil <= number"
	✅ El sistema de regeneración funciona correctamente
	✅ No crashea si un jugador tiene BaseState incompleto

	═══════════════════════════════════════════════════════════════════════
	TESTING:
	═══════════════════════════════════════════════════════════════════════

	Después de aplicar:
	1. Presiona Play en Studio
	2. Spawna un meteorito (o espera a la wave)
	3. Verifica que NO aparece el error de línea 528
	4. La regeneración debería funcionar normalmente

	En el Output deberías ver (si DEBUG está activo):
	[BaseModule] Regen - userId 3620016515: 10/100
	[BaseModule] Regen - userId 3620016515: 20/100
	...

	═══════════════════════════════════════════════════════════════════════
--]]
