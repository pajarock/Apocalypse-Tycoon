--[[
	═══════════════════════════════════════════════════════════════════════
	SNIPPET PARA BaseModule.lua - Función OnBaseDead ARREGLADA
	═══════════════════════════════════════════════════════════════════════

	ARREGLOS INCLUIDOS:
	✅ Guardado forzado con DataStore para evitar revert del dinero
	✅ Notificación a BaseVisualsManager para actualizar visuals
	✅ Dispara evento BaseStateChanged para sincronizar con cliente
	✅ Comentarios mejorados y debugging

	UBICACIÓN: ServerScriptService.BaseModule

	BUSCA LA FUNCIÓN: function BaseModule.OnBaseDead(userId: number)
	(Aproximadamente línea 192-204)

	REEMPLAZA TODA LA FUNCIÓN con el código de abajo (líneas 16-93):
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
	-- 2. RESTAR DINERO (CON GUARDADO FORZADO)
	-- ═══════════════════════════════════════════════════════════════════

	if moneyLost > 0 and cashValue then
		local oldMoney = currentMoney

		-- Reducir dinero
		cashValue.Value = math.max(0, currentMoney - moneyLost)

		-- ✅ ARREGLADO: Forzar guardado inmediato con DataStore
		local DataStoreModule = game.ServerScriptService:FindFirstChild("DataStoreModule")
		if DataStoreModule then
			local DSM = require(DataStoreModule)
			if DSM and DSM.SavePlayerData then
				-- Guardar inmediatamente para evitar que se revierta
				task.spawn(function()
					local success, err = pcall(function()
						DSM.SavePlayerData(player)
					end)

					if not success then
						warn(("[BaseModule] ⚠️ Error guardando datos: %s"):format(tostring(err)))
					elseif DEBUG then
						print(("[BaseModule] ✓ Datos guardados exitosamente"))
					end
				end)
			end
		end

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

	-- ✅ ARREGLADO: Notificar a BaseVisualsManager
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

	-- ✅ ARREGLADO: Disparar evento de cambio de estado para cliente
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
	CONFIGURACIÓN ADICIONAL REQUERIDA:
	═══════════════════════════════════════════════════════════════════════

	IMPORTANTE: Si no tienes estas variables al inicio del módulo, agrégalas:

	En la parte superior de BaseModule.lua (después de local Players = ...):
--]]

-- local SS = game:GetService("ServerStorage") -- Si no existe
-- local DEBUG = Config.DEBUG_MODE or false -- Si no existe

--[[
	═══════════════════════════════════════════════════════════════════════
	OPCIONES DE DIFICULTAD:
	═══════════════════════════════════════════════════════════════════════

	Para cambiar la severidad de la penalización, modifica estas 3 líneas:

	LÍNEA 31 - Pérdida de dinero:
		local moneyLost = math.floor(currentMoney * 0.25) -- 25%

	Opciones:
	- 0.10 = 10% (fácil)
	- 0.25 = 25% (balanceado) ← ACTUAL
	- 0.50 = 50% (difícil)

	LÍNEA 70 - Tiempo de cooldown:
		BaseDead:FireClient(player, moneyLost, 10) -- 10 segundos

	Opciones:
	- 5 = 5 segundos (fácil)
	- 10 = 10 segundos (balanceado) ← ACTUAL
	- 20 = 20 segundos (difícil)

	LÍNEA 80 - HP de respawn:
		local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5) -- 50%

	Opciones:
	- 0.75 = 75% HP (fácil)
	- 0.50 = 50% HP (balanceado) ← ACTUAL
	- 0.25 = 25% HP (difícil)

	═══════════════════════════════════════════════════════════════════════
	MENSAJES ESPERADOS EN OUTPUT (DEBUG MODE):
	═══════════════════════════════════════════════════════════════════════

	[BaseModule] 💀 BASE DESTRUIDA - userId 3620016515
	[BaseModule] 💰 Dinero reducido: $1000 → $750 (pérdida: $250)
	[BaseModule] ✓ Datos guardados exitosamente
	[BaseModule] SetHP userId 3620016515: 0 → 50
	[BaseModule] ✓ BaseVisualsManager actualizado
	[BaseModule] Base respawneada - userId 3620016515 con 50 HP (50%)

	═══════════════════════════════════════════════════════════════════════
	TROUBLESHOOTING:
	═══════════════════════════════════════════════════════════════════════

	❌ "Dinero no se reduce"
	→ Verifica que DataStoreModule existe en ServerScriptService
	→ Verifica que tiene función SavePlayerData(player)
	→ Si no existe, el dinero se restará pero puede revertirse al autosave

	❌ "Base no re-aparece"
	→ Verifica que BaseVisualsManager existe en ServerStorage.Managers
	→ Si no existe, comenta las líneas 84-94 (no crítico)
	→ Verifica que la función UpdateBaseVisuals existe

	❌ "Error: SS is not defined"
	→ Agrega al inicio del módulo: local SS = game:GetService("ServerStorage")

	═══════════════════════════════════════════════════════════════════════
--]]
