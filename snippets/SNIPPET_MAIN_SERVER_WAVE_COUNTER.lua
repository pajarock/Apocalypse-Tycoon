--[[
	═══════════════════════════════════════════════════════════════════════
	SNIPPET PARA MAIN.SERVER.LUA - Sincronización de Wave Counter
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	- El servidor actualiza ServerState.CurrentWave
	- Pero el cliente (WaveCounterUI.client.lua) no lo ve
	- Necesitamos sincronizar con un IntValue en ReplicatedStorage

	SOLUCIÓN:
	Agregar 2 secciones de código en Main.Server.lua
--]]

--[[
	SECCIÓN 1: CREAR INTVALUE
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: Después de la sección de ServerState (línea ~107)

	Busca esto:
		local ServerState = {
			StartTime = os.time(),
			CurrentWave = 1,
			PlayersJoined = 0,
			TotalPurchases = 0,
			TotalDamage = 0,
		}

	INMEDIATAMENTE DESPUÉS, agrega esto:
--]]

-- ✅ NUEVO: Crear IntValue para sincronizar wave counter con clientes
local CurrentWaveValue = Instance.new("IntValue")
CurrentWaveValue.Name = "CurrentWave"
CurrentWaveValue.Value = ServerState.CurrentWave
CurrentWaveValue.Parent = game.ReplicatedStorage

if Config.DEBUG_MODE then
	print("[MAIN] ✅ IntValue 'CurrentWave' creado en ReplicatedStorage")
end

--[[
	SECCIÓN 2: ACTUALIZAR INTVALUE AL AVANZAR WAVE
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: En el loop de waves (línea ~1431)

	Busca esto:
		ServerState.CurrentWave += 1

		logAnalytic("WaveCompleted", {
			wave = ServerState.CurrentWave - 1,
			survivors = #Players:GetPlayers(),
		})

	REEMPLAZA con esto:
--]]

-- ✅ Avanzar wave
ServerState.CurrentWave += 1

-- ✅ NUEVO: Sincronizar con IntValue para que el cliente vea el cambio
CurrentWaveValue.Value = ServerState.CurrentWave

if Config.DEBUG_MODE then
	print(("[MAIN] ✅ Wave actualizada a %d (sincronizada con cliente)"):format(ServerState.CurrentWave))
end

logAnalytic("WaveCompleted", {
	wave = ServerState.CurrentWave - 1,
	survivors = #Players:GetPlayers(),
})

--[[
	═══════════════════════════════════════════════════════════════════════
	RESULTADO ESPERADO:
	═══════════════════════════════════════════════════════════════════════

	Al iniciar el servidor:
	[MAIN] ✅ IntValue 'CurrentWave' creado en ReplicatedStorage
	[WaveCounterUI] ✓ Conectado a CurrentWave IntValue

	Al completar cada wave:
	[WAVE] Iniciando Wave 2
	[MAIN] ✅ Wave actualizada a 2 (sincronizada con cliente)
	[WaveCounterUI] 🎉 Wave 2 alcanzada!

	✅ El contador en pantalla (esquina superior derecha) se actualizará automáticamente
	✅ Verás animación de "pulse" y flash naranja cada vez que avanza la wave

	═══════════════════════════════════════════════════════════════════════
	TESTING:
	═══════════════════════════════════════════════════════════════════════

	1. Aplica las 2 secciones de código arriba
	2. Presiona Play en Studio
	3. Verifica que aparece el contador en la esquina superior derecha
	4. Espera a que termine la primera wave (~30 segundos)
	5. Verifica que el contador cambia de "WAVE 1" a "WAVE 2"
	6. Verás animación de pulse + flash naranja

	Si no funciona, revisa el Output y busca:
	- ⚠️ Si dice "No se encontró CurrentWave", reviste la SECCIÓN 1
	- ⚠️ Si el contador no avanza, revisa la SECCIÓN 2

	═══════════════════════════════════════════════════════════════════════
	NOTAS ADICIONALES:
	═══════════════════════════════════════════════════════════════════════

	✅ Esta solución usa IntValue (Opción A del WaveCounterUI)
	✅ Es la más simple y eficiente
	✅ No requiere RemoteEvents (menos overhead)
	✅ PropertyChangedSignal detecta cambios automáticamente

	Si en el futuro quieres usar RemoteEvent (Opción B):
	1. Crear RemoteEvent "WaveUpdate" en Remotes
	2. Usar WaveUpdate:FireAllClients(ServerState.CurrentWave)
	3. Eliminar el IntValue

	Pero IntValue es MEJOR para este caso (sincronización de estado simple).
--]]
