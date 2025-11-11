--[[
	═══════════════════════════════════════════════════════════════════════
	SNIPPET PARA BaseModule.lua - Penalizaciones por Muerte
	═══════════════════════════════════════════════════════════════════════

	INSTRUCCIONES:
	1. Abre ServerScriptService.BaseModule_ARREGLADO en Studio
	2. Busca la función OnBaseDead (línea ~294)
	3. REEMPLAZA toda la función con esto:
--]]

function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print(("[BaseModule] 💀 BASE DESTRUIDA - userId %d"):format(userId))
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- ✅ PENALIZACIÓN PROGRESIVA (Opción A)

	-- 1. Calcular pérdida de dinero (25%)
	local leaderstats = player:FindFirstChild("leaderstats")
	local cashValue = leaderstats and leaderstats:FindFirstChild("Cash")
	local currentMoney = cashValue and cashValue.Value or 0

	local moneyLost = math.floor(currentMoney * 0.25) -- 25% de pérdida

	-- 2. Restar dinero
	if moneyLost > 0 and cashValue then
		cashValue.Value = math.max(0, currentMoney - moneyLost)

		if DEBUG then
			print(("[BaseModule] Dinero perdido: $%d (25%% de $%d)"):format(moneyLost, currentMoney))
		end
	end

	-- 3. Mostrar pantalla de muerte
	local BaseDead = game.ReplicatedStorage.Remotes:FindFirstChild("BaseDead")
	if BaseDead then
		BaseDead:FireClient(player, moneyLost, 10) -- 10 segundos de cooldown
	end

	-- 4. Cooldown de respawn (10 segundos)
	task.wait(10)

	-- 5. Respawn con 50% HP
	local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
	BaseModule.SetHP(userId, respawnHP)

	if DEBUG then
		print(("[BaseModule] Base respawneada - userId %d con %d HP (50%%)"):format(userId, respawnHP))
	end

	-- 6. Mensaje de ánimo
	if player then
		-- Opcional: Enviar mensaje motivacional
		local ShowNotification = game.ReplicatedStorage.Remotes:FindFirstChild("ShowNotification")
		if ShowNotification then
			ShowNotification:FireClient(player, "Base restored! Fight back! 💪", 3)
		end
	end
end

--[[
	═══════════════════════════════════════════════════════════════════════
	CONFIGURACIÓN DE PENALIZACIONES
	═══════════════════════════════════════════════════════════════════════

	Puedes ajustar estos valores según la dificultad que quieras:

	OPCIÓN A - PROGRESIVA (Actual): ⭐ Equilibrado
	- Pérdida de dinero: 25%
	- Cooldown: 10 segundos
	- HP respawn: 50%

	OPCIÓN B - HARSH (Difícil):
	- Pérdida de dinero: 50%
	- Cooldown: 20 segundos
	- HP respawn: 25%
	Cambios:
		local moneyLost = math.floor(currentMoney * 0.5)
		BaseDead:FireClient(player, moneyLost, 20)
		local respawnHP = math.floor(Config.BASE_MAX_HP * 0.25)

	OPCIÓN C - SOFT (Fácil):
	- Pérdida de dinero: 10%
	- Cooldown: 5 segundos
	- HP respawn: 75%
	Cambios:
		local moneyLost = math.floor(currentMoney * 0.1)
		BaseDead:FireClient(player, moneyLost, 5)
		local respawnHP = math.floor(Config.BASE_MAX_HP * 0.75)

	═══════════════════════════════════════════════════════════════════════
	NOTAS ADICIONALES
	═══════════════════════════════════════════════════════════════════════

	✅ La penalización crea INCENTIVO para:
	   - Saltar para evadir meteoritos
	   - Comprar mejoras defensivas (Shield Generator, Turrets)
	   - Comprar Wall Sections
	   - Reparar la base a tiempo

	✅ El cooldown de 10s da tiempo para:
	   - Leer el mensaje de muerte
	   - Ver cuánto dinero perdiste
	   - Planear tu estrategia para la siguiente wave

	✅ Respawn con 50% HP significa:
	   - No empiezas vulnerable (0% sería muy harsh)
	   - No empiezas seguro (100% no habría consecuencia)
	   - Necesitas reparar o esperar regen

	═══════════════════════════════════════════════════════════════════════
	TESTING
	═══════════════════════════════════════════════════════════════════════

	Para testear la penalización:
	1. Dale dinero a tu jugador (ej: $10,000)
	2. Deja que los meteoritos destruyan tu base
	3. Verifica:
	   - ✅ Pantalla roja aparece
	   - ✅ Mensaje muestra cuánto perdiste
	   - ✅ Countdown de 10 segundos
	   - ✅ Pierdes 25% del dinero
	   - ✅ Base respawnea con 50% HP
--]]
