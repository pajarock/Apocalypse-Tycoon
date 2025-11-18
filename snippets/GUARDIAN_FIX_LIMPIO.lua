-- ✅ GUARDIAN ARREGLADO - Reemplaza el código del Guardian en BaseModule.lua

-- Iniciar nuevo guardian
ActiveGuardianTasks[userId] = task.spawn(function()
	local startTime = tick()
	local forceDuration = 120 -- 2 minutos
	local checkInterval = 0.5 -- Revisar cada 0.5 segundos

	if DEBUG then
		print(("[BaseModule] 🛡️ Guardian ACTIVADO - Protegiendo $%d por %ds"):format(
			newAmount, forceDuration
		))
	end

	while tick() - startTime < forceDuration do
		task.wait(checkInterval)

		-- Verificar si el jugador sigue conectado
		local plr = Players:GetPlayerByUserId(userId)
		if not plr then
			if DEBUG then
				print(("[BaseModule] ⚠️ Guardian: Jugador desconectado"):format())
			end
			break
		end

		local cash = plr:FindFirstChild("leaderstats") and plr:FindFirstChild("leaderstats"):FindFirstChild("Cash")
		if not cash then
			if DEBUG then
				warn(("[BaseModule] ⚠️ Guardian: Cash no encontrado"):format())
			end
			break
		end

		-- ✅ ARREGLADO: Solo evitar que BAJE del mínimo, permitir que SUBA
		if cash.Value < newAmount then
			local oldValue = cash.Value

			-- Forzar al mínimo solo si bajó
			cash.Value = newAmount

			if Economy then
				local state = Economy.GetState(userId)
				if state then
					state.Cash = newAmount
				end
			end

			if DEBUG then
				print(("[BaseModule] 🛡️ Guardian PROTEGIÓ: Dinero bajó de $%d a $%d"):format(
					newAmount, oldValue
				))
				print(("[BaseModule] 🛡️ Guardian RESTAURÓ: $%d → $%d"):format(
					oldValue, newAmount
				))
			end
		elseif DEBUG and cash.Value > newAmount then
			-- Income normal funcionando, no hacer nada
			print(("[BaseModule] ✅ Guardian: Income OK ($%d, mínimo protegido: $%d)"):format(
				cash.Value, newAmount
			))
		end
	end

	ActiveGuardianTasks[userId] = nil
	if DEBUG then
		print(("[BaseModule] ✅ Guardian TERMINADO - Protección finalizada"):format())
	end
end)

--[[
CAMBIO CRÍTICO:
ANTES: if cash.Value ~= newAmount then
AHORA:  if cash.Value < newAmount then

ESTO PERMITE QUE EL INCOME SUBA NORMALMENTE
]]
