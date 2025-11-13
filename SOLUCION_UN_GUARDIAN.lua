--[[
	═══════════════════════════════════════════════════════════════════════
	SOLUCIÓN FINAL - Un Solo Guardian Por Jugador
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA IDENTIFICADO:
	- Múltiples guardians corriendo al mismo tiempo
	- Cada muerte crea un nuevo guardian
	- Los guardians viejos NO se desactivan
	- Resultado: guardians peleando entre sí

	SOLUCIÓN:
	- Guardar referencia al task del guardian
	- Cancelar guardian previo antes de crear uno nuevo
	- Solo un guardian activo por jugador

	═══════════════════════════════════════════════════════════════════════
	PASO 1: AGREGAR VARIABLE GLOBAL
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: ServerScriptService.BaseModule
	Al inicio del módulo, después de:
		local PendingMoneyReductions = {}

	AGREGA esta línea:
--]]

local ActiveGuardianTasks = {} -- [userId] = task thread

--[[
	Debería quedar así:
		local BaseState = {}
		local PendingMoneyReductions = {}
		local ActiveGuardianTasks = {}  ← NUEVA LÍNEA

	═══════════════════════════════════════════════════════════════════════
	PASO 2: REEMPLAZAR SECCIÓN DEL GUARDIAN RÁPIDO EN OnBaseDead
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: Función OnBaseDead, dentro de la sección "2. RESTAR DINERO"

	Busca el código que dice:
		-- ✅ NUEVO: Forzar el valor INMEDIATAMENTE en un loop rápido
		task.spawn(function()
			local forceDuration = 120
			...
		end)

	REEMPLAZA TODO ESE BLOQUE (desde task.spawn hasta el end) con:
--]]

			-- ✅ CANCELAR guardian previo si existe
			if ActiveGuardianTasks[userId] then
				task.cancel(ActiveGuardianTasks[userId])
				ActiveGuardianTasks[userId] = nil

				if DEBUG then
					print(("[BaseModule] ⚠️ Guardian previo cancelado para userId %d"):format(userId))
				end
			end

			-- ✅ NUEVO: Forzar el valor INMEDIATAMENTE en un loop rápido
			ActiveGuardianTasks[userId] = task.spawn(function()
				local forceDuration = 120 -- Forzar por 120 segundos (2 minutos)
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

				-- Limpiar al terminar
				ActiveGuardianTasks[userId] = nil

				if DEBUG then
					print(("[BaseModule] 🛡️ Guardian rápido terminado (120s) para userId %d"):format(userId))
				end
			end)

--[[
	═══════════════════════════════════════════════════════════════════════
	PASO 3: LIMPIAR GUARDIANS AL REMOVER JUGADOR
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: Cerca del final de BaseModule.lua
	Busca donde dice:
		Players.PlayerRemoving:Connect(function(plr)

	Dentro de esa función, AGREGA:
--]]

Players.PlayerRemoving:Connect(function(plr)
	local userId = plr.UserId

	-- Código existente...
	BaseModule.RemovePlayer(userId)

	-- ✅ NUEVO: Cancelar guardian activo
	if ActiveGuardianTasks[userId] then
		task.cancel(ActiveGuardianTasks[userId])
		ActiveGuardianTasks[userId] = nil

		if DEBUG then
			print(("[BaseModule] Guardian cancelado para jugador que se fue: %d"):format(userId))
		end
	end

	-- ✅ NUEVO: Limpiar pending reductions
	if PendingMoneyReductions[userId] then
		PendingMoneyReductions[userId] = nil
	end
end)

--[[
	═══════════════════════════════════════════════════════════════════════
	QUÉ HACE ESTA SOLUCIÓN:
	═══════════════════════════════════════════════════════════════════════

	1. Antes de crear un guardian nuevo:
	   - Busca si hay uno activo
	   - Si existe, lo CANCELA
	   - Esto evita guardians múltiples

	2. Guarda referencia al task del guardian:
	   - ActiveGuardianTasks[userId] = task.spawn(...)
	   - Permite cancelarlo después

	3. Al final del guardian:
	   - Se limpia automáticamente
	   - ActiveGuardianTasks[userId] = nil

	4. Cuando el jugador se va:
	   - Cancela el guardian
	   - Limpia PendingMoneyReductions
	   - Evita memory leaks

	RESULTADO:
	✅ Solo UN guardian por jugador
	✅ No más guardians peleando
	✅ No más tick spam en el output
	✅ Dinero se mantiene estable

	═══════════════════════════════════════════════════════════════════════
	TESTING:
	═══════════════════════════════════════════════════════════════════════

	1. Presiona Play
	2. Deja que la base muera VARIAS veces seguidas
	3. Verifica el Output:

	PRIMERA MUERTE:
	[BaseModule] 💰 Dinero reducido: $999999 → $750000
	[BaseModule] 🛡️ Guardian activado - Target: $750000

	SEGUNDA MUERTE:
	[BaseModule] 💀 BASE DESTRUIDA
	[BaseModule] ⚠️ Guardian previo cancelado  ← NUEVO
	[BaseModule] 💰 Dinero reducido: $750000 → $562500
	[BaseModule] 🛡️ Guardian activado - Target: $562500

	NO DEBE HABER:
	❌ Guardian FORZÓ dinero (spam cada 0.1s)
	❌ Múltiples valores compitiendo

	═══════════════════════════════════════════════════════════════════════
--]]
