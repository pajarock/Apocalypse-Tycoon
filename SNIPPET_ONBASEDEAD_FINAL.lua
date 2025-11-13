--[[
	═══════════════════════════════════════════════════════════════════════
	FUNCIÓN OnBaseDead - VERSIÓN FINAL SIN DATASTOREMODULE
	═══════════════════════════════════════════════════════════════════════

	Esta versión NO depende de DataStoreModule.SavePlayerData (que no existe).
	En su lugar, confía en el autosave natural de tu sistema.

	UBICACIÓN: ServerScriptService.BaseModule
	BUSCA: function BaseModule.OnBaseDead(userId: number)
	REEMPLAZA con el código de abajo (líneas 13-108):
--]]

function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print(("[BaseModule] 💀 BASE DESTRUIDA - userId %d"):format(userId))
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- ═══════════════════════════════════════════════════════════════════
	-- 1. CALCULAR PÉRDIDA DE DINERO (25%)
	-- ═══════════════════════════════════════════════════════════════════

	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	local currentMoney = cashValue and cashValue.Value or 0

	local moneyLost = math.floor(currentMoney * 0.25) -- 25% de pérdida

	-- ═══════════════════════════════════════════════════════════════════
	-- 2. RESTAR DINERO (VERSIÓN SIMPLIFICADA)
	-- ═══════════════════════════════════════════════════════════════════

	if moneyLost > 0 and cashValue then
		local oldMoney = currentMoney

		-- ✅ Marcar que estamos en penalización (evitar que autosave revierta)
		player:SetAttribute("PenaltyInProgress", true)

		-- Reducir dinero
		cashValue.Value = math.max(0, currentMoney - moneyLost)

		-- Forzar propagación del cambio
		if leaderstats and leaderstats.Cash then
			leaderstats.Cash.Value = cashValue.Value
		end

		-- Esperar un poco para que se propague
		task.wait(0.2)

		-- Desmarcar
		player:SetAttribute("PenaltyInProgress", false)

		if DEBUG then
			print(("[BaseModule] 💰 Dinero reducido: $%d → $%d (pérdida: $%d)"):format(
				oldMoney, cashValue.Value, moneyLost
			))
		end
	end

	-- ═══════════════════════════════════════════════════════════════════
	-- 3. MOSTRAR PANTALLA DE MUERTE
	-- ═══════════════════════════════════════════════════════════════════

	local BaseDead = game.ReplicatedStorage.Remotes:FindFirstChild("BaseDead")
	if BaseDead then
		BaseDead:FireClient(player, moneyLost, 10) -- 10 segundos de cooldown
	else
		warn("[BaseModule] ⚠️ RemoteEvent 'BaseDead' no encontrado")
	end

	-- ═══════════════════════════════════════════════════════════════════
	-- 4. COOLDOWN DE RESPAWN (10 SEGUNDOS)
	-- ═══════════════════════════════════════════════════════════════════

	task.wait(10)

	-- ═══════════════════════════════════════════════════════════════════
	-- 5. RESPAWN CON 50% HP
	-- ═══════════════════════════════════════════════════════════════════

	local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
	BaseModule.SetHP(userId, respawnHP)

	-- ✅ Notificar a BaseVisualsManager
	local BaseVisualsManager = SS.Managers:FindFirstChild("BaseVisualsManager")
	if BaseVisualsManager then
		local BVM = require(BaseVisualsManager)
		if BVM and BVM.UpdateBaseVisuals then
			BVM:UpdateBaseVisuals(userId, respawnHP, Config.BASE_MAX_HP)

			if DEBUG then
				print(("[BaseModule] ✓ BaseVisualsManager actualizado"))
			end
		end
	end

	-- ✅ Disparar evento de cambio de estado para cliente
	local BaseStateChanged = game.ReplicatedStorage.Remotes:FindFirstChild("BaseStateChanged")
	if BaseStateChanged then
		BaseStateChanged:FireClient(player, respawnHP, Config.BASE_MAX_HP, 0) -- HP, MaxHP, Shields
	end

	-- ═══════════════════════════════════════════════════════════════════
	-- 6. MENSAJE MOTIVACIONAL (OPCIONAL)
	-- ═══════════════════════════════════════════════════════════════════

	local ShowNotification = game.ReplicatedStorage.Remotes:FindFirstChild("ShowNotification")
	if ShowNotification then
		ShowNotification:FireClient(player, "Base restored! Fight back! 💪", 3)
	end

	if DEBUG then
		print(("[BaseModule] Base respawneada - userId %d con %d HP (50%%)"):format(userId, respawnHP))
	end
end

--[[
	═══════════════════════════════════════════════════════════════════════
	NOTAS IMPORTANTES:
	═══════════════════════════════════════════════════════════════════════

	1. Esta versión NO usa DataStoreModule
	2. En su lugar usa player:SetAttribute("PenaltyInProgress", true)
	3. Esto permite que tu autosave skip este jugador durante la penalización
	4. Después de 10 segundos, el autosave normal guardará el dinero reducido

	═══════════════════════════════════════════════════════════════════════
	CONFIGURACIÓN REQUERIDA EN MAIN.SERVER.LUA (OPCIONAL):
	═══════════════════════════════════════════════════════════════════════

	Si quieres que el autosave respete el atributo PenaltyInProgress,
	modifica tu loop de autosave:

	BUSCA EL CÓDIGO DE AUTOSAVE (algo como):
--]]

for _, player in ipairs(Players:GetPlayers()) do
	-- Guardar datos del jugador
	DataStore:SavePlayer(player)
end

--[[
	AGREGA UN CHECK ANTES:
--]]

for _, player in ipairs(Players:GetPlayers()) do
	-- ✅ Skip jugadores en penalización
	if player:GetAttribute("PenaltyInProgress") then
		if Config.DEBUG_MODE then
			print(("[AUTOSAVE] Skipping " .. player.Name .. " (penalty in progress)"))
		end
		continue
	end

	-- Guardar datos del jugador
	DataStore:SavePlayer(player)
end

--[[
	═══════════════════════════════════════════════════════════════════════
	SI NO QUIERES MODIFICAR MAIN.SERVER.LUA:
	═══════════════════════════════════════════════════════════════════════

	Puedes omitir el check de SetAttribute. La versión simple también debería
	funcionar, solo que hay un pequeño riesgo de que el autosave lo sobrescriba.

	En ese caso, simplemente elimina las líneas:
	- player:SetAttribute("PenaltyInProgress", true)
	- player:SetAttribute("PenaltyInProgress", false)

	Y deja solo:
--]]

-- Reducir dinero
cashValue.Value = math.max(0, currentMoney - moneyLost)

-- Forzar propagación
if leaderstats and leaderstats.Cash then
	leaderstats.Cash.Value = cashValue.Value
end

task.wait(0.2)

--[[
	═══════════════════════════════════════════════════════════════════════
--]]
