--[[
═══════════════════════════════════════════════════════════════════════
🎯 ARREGLO FINAL: Wave Counter + UI Épica
═══════════════════════════════════════════════════════════════════════

PROBLEMAS IDENTIFICADOS:
1. Wave counter va "en el futuro" (sincronización incorrecta)
2. No hay feedback visual al completar wave
3. Contador de dinero aburrido
4. Leaderboard tapa el wave counter

SOLUCIONES:
═══════════════════════════════════════════════════════════════════════
]]

--═══════════════════════════════════════════════════════════════════════
-- PARTE 1: ARREGLAR SINCRONIZACIÓN (Main.Server.lua)
--═══════════════════════════════════════════════════════════════════════

--[[
Archivo: ServerScriptService.Main.Server
Ubicación: Loop de waves (~línea 1372)

BUSCAR el bloque que dice:
```lua
while true do
	local waveConfig = Config.GetWaveDifficulty(ServerState.CurrentWave)

	-- código...

	task.wait(adjustedInterval)

	print(("═══..."):rep(1))
	print(("[WAVE] Iniciando Wave %d"):format(ServerState.CurrentWave))
	-- ...

	ServerState.CurrentWave += 1
	CurrentWaveValue.Value = ServerState.CurrentWave  -- ❌ PROBLEMA AQUÍ
end
```

REEMPLAZAR con:
--]]

while true do
	local waveConfig = Config.GetWaveDifficulty(ServerState.CurrentWave)

	-- Ajustar por número de jugadores
	local playerCount = #Players:GetPlayers()
	local difficulty = Config.GetDynamicDifficulty(playerCount)
	local adjustedInterval = waveConfig.Interval * difficulty

	task.wait(adjustedInterval)

	-- ✅ SINCRONIZAR AL INICIO (muestra la wave que VAS A JUGAR)
	if CurrentWaveValue then
		CurrentWaveValue.Value = ServerState.CurrentWave
	end

	print(("═══════════════════════════════════════════════════════════"):rep(1))
	print(("[WAVE] Iniciando Wave %d"):format(ServerState.CurrentWave))
	print(("[WAVE] Meteoritos: %d | Daño: %d | Jugadores: %d"):format(
		waveConfig.Meteors, waveConfig.Damage, playerCount
		))
	print(("═══════════════════════════════════════════════════════════"):rep(1))

	-- Anuncio
	broadcastNotification(string.format("⚔️ WAVE %d INCOMING!", ServerState.CurrentWave), 5)

	-- Boss cada 5 waves
	if ServerState.CurrentWave % 5 == 0 then
		task.wait(5)
		broadcastNotification("💀 BOSS METEOR!", 3)
		task.wait(2)
		Events:BossMeteor()
	else
		-- Wave normal
		Config.METEOR_COUNT = waveConfig.Meteors
		Config.METEOR_DAMAGE = waveConfig.Damage

		task.wait(5)
		Events:MeteorStorm()
	end

	-- 🎉 NUEVO: Celebrar wave completada
	task.wait(2) -- Esperar que termine de caer el último meteorito

	broadcastNotification(string.format("✨ WAVE %d COMPLETED!", ServerState.CurrentWave), 3)

	if Config.DEBUG_MODE then
		print(("[WAVE] ✅ Wave %d completada"):format(ServerState.CurrentWave))
	end

	-- Incrementar contador de meteoros sobrevividos
	for _, plr in ipairs(Players:GetPlayers()) do
		if Base.GetHP(plr.UserId) > 0 then
			Base.IncrementMeteorsSurvived(plr.UserId)

			local stats = plr:FindFirstChild("Stats")
			if stats then
				local meteors = stats:FindFirstChild("MeteorsSurvived") :: IntValue?
				if meteors then
					meteors.Value = Base.GetMeteorsSurvived(plr.UserId)
				end
			end

			-- Achievement: 100 meteoros
			if Base.GetMeteorsSurvived(plr.UserId) == 100 and Achievements then
				Achievements.Award(plr.UserId, "Survivor100")
			end
		end
	end

	-- ✅ AL FINAL: Incrementar para la SIGUIENTE iteración
	ServerState.CurrentWave += 1

	logAnalytic("WaveCompleted", {
		wave = ServerState.CurrentWave - 1,
		survivors = #Players:GetPlayers(),
	})
end

--[[
═══════════════════════════════════════════════════════════════════════
RESULTADO DEL ARREGLO:

ANTES:
[WAVE] Iniciando Wave 5
[MAIN] ✅ Wave actualizada a 6  ← Muestra el futuro
Contador UI: "WAVE 6"            ← Incorrecto

DESPUÉS:
[MAIN] ✅ Wave sincronizada: 5
[WAVE] Iniciando Wave 5
Contador UI: "WAVE 5"            ← Correcto
... meteoritos caen ...
✨ WAVE 5 COMPLETED!
[WAVE] ✅ Wave 5 completada

═══════════════════════════════════════════════════════════════════════
]]
