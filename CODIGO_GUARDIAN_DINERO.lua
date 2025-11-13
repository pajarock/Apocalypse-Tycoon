--[[
	═══════════════════════════════════════════════════════════════════════
	CÓDIGO DEL GUARDIAN DE DINERO - Copiar al final de BaseModule.lua
	═══════════════════════════════════════════════════════════════════════

	INSTRUCCIONES:
	1. Abre ServerScriptService.BaseModule en Studio
	2. Ve al FINAL del archivo (antes de "return BaseModule")
	3. Copia TODO el código de abajo (líneas 14-59)
	4. Pégalo ANTES del "return BaseModule"
	5. Guarda (Ctrl+S)
--]]

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE GUARDIAN DE DINERO
--═══════════════════════════════════════════════════════════════════════

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

--═══════════════════════════════════════════════════════════════════════

--[[
	AHORA, en tu función OnBaseDead, busca donde reduces el dinero y AGREGA:

	Busca algo como:
		cashValue.Value = math.max(0, currentMoney - moneyLost)

	INMEDIATAMENTE DESPUÉS, agrega estas 5 líneas:
--]]

-- ✅ Activar guardian para mantener el dinero reducido
PendingMoneyReductions[userId] = {
	targetAmount = cashValue.Value,
	timestamp = tick()
}

--[[
	═══════════════════════════════════════════════════════════════════════
	RESULTADO:
	═══════════════════════════════════════════════════════════════════════

	El guardian mantendrá el dinero reducido durante 120 segundos.
	Si el autosave intenta revertirlo, el guardian lo fuerza de vuelta.
	Después de 2 minutos, el autosave habrá guardado el valor correcto.

	═══════════════════════════════════════════════════════════════════════
--]]
