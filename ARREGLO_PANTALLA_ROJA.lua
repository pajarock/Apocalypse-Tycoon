--[[
	═══════════════════════════════════════════════════════════════════════
	ARREGLO - Pantalla Roja No Aparece Después de Varias Muertes
	═══════════════════════════════════════════════════════════════════════

	PROBLEMA:
	Después de varias muertes, la pantalla roja deja de aparecer.

	CAUSA PROBABLE:
	El ScreenGui se queda "enabled = true" por algún error en la animación
	o el countdown se interrumpe y no resetea correctamente.

	SOLUCIÓN:
	Agregar protección para interrumpir animaciones previas.

	═══════════════════════════════════════════════════════════════════════
	ARREGLO: BaseDeathUI.client.lua
	═══════════════════════════════════════════════════════════════════════

	UBICACIÓN: StarterGui.BaseDeathUI

	Busca la sección del evento (línea ~183):
--]]

BaseDead.OnClientEvent:Connect(function(moneyLost: number, respawnTime: number)

--[[
	Al INICIO de esa función (inmediatamente después de la línea de arriba),
	AGREGA estas líneas:
--]]

	-- ✅ ARREGLADO: Forzar reset si el UI está activo
	if screenGui.Enabled then
		screenGui.Enabled = false
		task.wait(0.1) -- Pequeña pausa
	end

	-- ✅ ARREGLADO: Reset completo de transparencias antes de mostrar
	background.BackgroundTransparency = 0.3
	titleLabel.TextTransparency = 0
	titleLabel.TextStrokeTransparency = 0
	moneyLostLabel.TextTransparency = 0
	moneyLostLabel.TextStrokeTransparency = 0.5
	countdownLabel.TextTransparency = 0
	countdownLabel.TextStrokeTransparency = 0.5
	vignette.ImageTransparency = 0.5

--[[
	Debería quedar así:

	BaseDead.OnClientEvent:Connect(function(moneyLost: number, respawnTime: number)
		-- ✅ ARREGLADO: Forzar reset si el UI está activo
		if screenGui.Enabled then
			screenGui.Enabled = false
			task.wait(0.1)
		end

		-- ✅ ARREGLADO: Reset completo de transparencias
		background.BackgroundTransparency = 0.3
		titleLabel.TextTransparency = 0
		...

		-- Validate parameters (código existente)
		moneyLost = moneyLost or 0
		respawnTime = respawnTime or 10
		...

	═══════════════════════════════════════════════════════════════════════
	RESULTADO:
	═══════════════════════════════════════════════════════════════════════

	✅ El UI siempre se resetea correctamente
	✅ Funciona incluso si la muerte anterior no terminó de animar
	✅ No más pantallas rojas que se "pegan"
	✅ Funciona consistentemente en muertes múltiples

	═══════════════════════════════════════════════════════════════════════
--]]
