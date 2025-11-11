--[[
	═════════════════════════════════════════════════════════════════════
	SNIPPET PARA MAIN.SERVER.LUA - Inyección de BaseModule en EventManager
	═════════════════════════════════════════════════════════════════════

	INSTRUCCIONES:
	1. Abre tu archivo Main.Server.lua en Roblox Studio
	2. Busca la sección donde cargas los módulos (alrededor de la línea 66-72)
	3. Verás algo como esto:

		local Config = require(ServerStorage.Config.Config)
		local UpgDefs = require(ServerStorage.Config.Upgrades)
		local DataStore = require(ServerScriptService.DataStoreModule)
		local Economy = require(ServerScriptService.EconomyModule)
		local Events = require(ServerScriptService.EventManager)
		local Base = require(ServerScriptService.BaseModule)

	4. INMEDIATAMENTE DESPUÉS de esas líneas, agrega esto:
--]]

-- ✅ NUEVO: Inyectar BaseModule en EventManager (arregla dependencia circular)
Events:SetBaseModule(Base)

if Config.DEBUG_MODE then
	print("[MAIN] ✅ BaseModule inyectado en EventManager exitosamente")
end

--[[
	═════════════════════════════════════════════════════════════════════
	RESULTADO ESPERADO:

	Al iniciar el servidor, deberías ver en el Output:

	[EventManager ARREGLADO] ✅ Módulo cargado - esperando inyección de BaseModule
	[BaseModule ARREGLADO] ✅ Módulo cargado (sin dependencia circular)
	[MAIN] ✅ BaseModule inyectado en EventManager exitosamente
	[EventManager] ✅ BaseModule inyectado exitosamente

	Si ves esos 4 mensajes, TODO FUNCIONA CORRECTAMENTE! ✅
	═════════════════════════════════════════════════════════════════════

	NOTA IMPORTANTE:
	- NO copies TODO este archivo
	- SOLO copia las 2 líneas (68-69) donde dice Events:SetBaseModule(Base)
	- Pégalas DESPUÉS de la línea donde cargas Base = require(...)
--]]
