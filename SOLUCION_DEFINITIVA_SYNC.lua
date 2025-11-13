--[[
═══════════════════════════════════════════════════════════════════════
🎯 SOLUCIÓN DEFINITIVA: SYNC ECONOMY + BASEMODULE
═══════════════════════════════════════════════════════════════════════

PROBLEMA IDENTIFICADO:
Main.Server tiene un loop que cada segundo ejecuta:
    cash.Value = s.Cash  (línea 1307)

Esto sobrescribe cash.Value con el valor almacenado en EconomyModule,
ignorando cualquier cambio que haga BaseModule directamente.

SOLUCIÓN:
Cuando BaseModule reduce el dinero por muerte de base, debe actualizar
AMBOS lugares:
1. cash.Value (leaderstats)
2. Economy.GetState(userId).Cash (EconomyModule)

═══════════════════════════════════════════════════════════════════════
📋 INSTRUCCIONES
═══════════════════════════════════════════════════════════════════════

PASO 1: MODIFICAR BaseModule - AGREGAR REQUIRE
────────────────────────────────────────────────────────────────────────
Archivo: ServerScriptService.BaseModule

Busca la sección de CONFIGURACIÓN (cerca de línea 30-48).

DESPUÉS de estas líneas:
```lua
if not success or not Config then
	warn("[BaseModule] Config.lua no encontrado, usando valores por defecto")
	Config = {
		BASE_MAX_HP = 100,
		BASE_REGEN_RATE = 1,
		BASE_REGEN_DELAY = 5,
		SHIELD_DAMAGE_REDUCTION = 0.15,
		DEBUG_MODE = false
	}
end

local DEBUG = Config.DEBUG_MODE or false
```

AGREGA ESTAS LÍNEAS:
```lua
-- 🆕 REQUERIR ECONOMY PARA ACTUALIZAR DINERO
local Economy = nil
local economySuccess = pcall(function()
	Economy = require(game.ServerScriptService.EconomyModule)
end)

if not economySuccess or not Economy then
	warn("[BaseModule] EconomyModule no encontrado - penalizaciones de dinero desactivadas")
end
```

═══════════════════════════════════════════════════════════════════════

PASO 2: FUNCIÓN OnBaseDead COMPLETA CON SYNC
────────────────────────────────────────────────────────────────────────
Archivo: ServerScriptService.BaseModule

Busca la función `OnBaseDead` (debería estar cerca de línea 192-210).

REEMPLAZA COMPLETAMENTE esa función con este código:
--]]

--═══════════════════════════════════════════════════════════════════════
-- SISTEMA DE PENALIZACIONES POR MUERTE DE BASE
--═══════════════════════════════════════════════════════════════════════

local PendingMoneyReductions = {}
local ActiveGuardianTasks = {}

function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print(("[BaseModule] 💀 BASE DESTRUIDA - userId %d"):format(userId))
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- 1️⃣ OBTENER DINERO ACTUAL DESDE ECONOMY MODULE
	local currentMoney = 0
	local economyState = nil

	if Economy then
		economyState = Economy.GetState(userId)
		if economyState then
			currentMoney = economyState.Cash or 0
		end
	else
		-- Fallback: leer desde leaderstats si Economy no disponible
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local cashValue = ls:FindFirstChild("Cash")
			if cashValue then
				currentMoney = cashValue.Value
			end
		end
	end

	if DEBUG then
		print(("[BaseModule] 💵 ANTES - Dinero: $%d"):format(currentMoney))
	end

	-- 2️⃣ CALCULAR PENALIZACIÓN (25% del dinero actual)
	local moneyLost = math.floor(currentMoney * 0.25)
	local newAmount = math.max(0, currentMoney - moneyLost)

	if DEBUG then
		print(("[BaseModule] 💸 Pérdida calculada: $%d (25%%)"):format(moneyLost))
		print(("[BaseModule] 💵 NUEVO valor: $%d"):format(newAmount))
	end

	-- 3️⃣ ACTUALIZAR AMBOS LUGARES: ECONOMY Y LEADERSTATS

	-- A) Actualizar EconomyModule (la fuente de verdad)
	if economyState then
		economyState.Cash = newAmount
		if DEBUG then
			print(("[BaseModule] ✅ Economy.Cash actualizado a $%d"):format(newAmount))
		end
	end

	-- B) Actualizar leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cashValue = ls:FindFirstChild("Cash")
		if cashValue then
			cashValue.Value = newAmount
			if DEBUG then
				print(("[BaseModule] ✅ leaderstats.Cash actualizado a $%d"):format(newAmount))
			end
		end
	end

	-- 4️⃣ ACTIVAR GUARDIAN (protección por 120 segundos)
	PendingMoneyReductions[userId] = {
		TargetAmount = newAmount,
		StartTime = tick(),
		Duration = 120
	}

	-- Cancelar guardian previo si existe
	if ActiveGuardianTasks[userId] then
		task.cancel(ActiveGuardianTasks[userId])
		ActiveGuardianTasks[userId] = nil
		if DEBUG then
			print(("[BaseModule] 🔄 Guardian previo cancelado"))
		end
	end

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

			-- Si el dinero cambió, forzar de vuelta
			if cash.Value ~= newAmount then
				local oldValue = cash.Value

				-- 🆕 ACTUALIZAR AMBOS LUGARES
				cash.Value = newAmount

				if Economy then
					local state = Economy.GetState(userId)
					if state then
						state.Cash = newAmount
					end
				end

				if DEBUG then
					print(("[BaseModule] 🔍 DETECTIVE: Dinero cambió de $%d → $%d"):format(
						newAmount, oldValue
					))
					print(("[BaseModule] 🛡️ Guardian FORZÓ: $%d → $%d"):format(
						oldValue, newAmount
					))
				end
			end
		end

		ActiveGuardianTasks[userId] = nil
		if DEBUG then
			print(("[BaseModule] ✅ Guardian TERMINADO - Protección finalizada"):format())
		end
	end)

	-- 5️⃣ MOSTRAR PANTALLA DE MUERTE
	local Remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
	if Remotes then
		local BaseDead = Remotes:FindFirstChild("BaseDead")
		if BaseDead and BaseDead:IsA("RemoteEvent") then
			BaseDead:FireClient(player, moneyLost, 10)
			if DEBUG then
				print(("[BaseModule] 🎬 Pantalla de muerte enviada"):format())
			end
		end
	end

	-- 6️⃣ ESPERAR 10 SEGUNDOS Y RESPAWNEAR BASE
	task.wait(10)

	-- Respawnear con 50% HP
	local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
	BaseModule.SetHP(userId, respawnHP)

	if DEBUG then
		print(("[BaseModule] 🏗️ Base respawneada - userId %d con %d HP"):format(
			userId, respawnHP
		))
	end

	-- Actualizar visuales de la base
	local BaseStateChanged = Remotes and Remotes:FindFirstChild("BaseStateChanged")
	if BaseStateChanged and BaseStateChanged:IsA("RemoteEvent") then
		BaseStateChanged:FireClient(player, {
			UserId = userId,
			BaseHP = respawnHP,
			MaxHP = Config.BASE_MAX_HP,
		})
	end

	-- Actualizar visuales (si BaseVisualsManager está disponible)
	local BaseVisualsManager = nil
	pcall(function()
		BaseVisualsManager = require(game.ServerStorage.Managers.BaseVisualsManager)
	end)

	if BaseVisualsManager and BaseVisualsManager.UpdateBaseVisuals then
		BaseVisualsManager.UpdateBaseVisuals(userId, respawnHP, Config.BASE_MAX_HP)
	end
end

--[[
═══════════════════════════════════════════════════════════════════════

PASO 3: CLEANUP AL DESCONECTARSE
────────────────────────────────────────────────────────────────────────
Busca la sección donde se conecta PlayerRemoving (cerca del final del archivo).

REEMPLAZA o AGREGA este código:
--]]

Players.PlayerRemoving:Connect(function(plr)
	local userId = plr.UserId
	BaseModule.RemovePlayer(userId)

	-- 🆕 CANCELAR GUARDIAN ACTIVO
	if ActiveGuardianTasks[userId] then
		task.cancel(ActiveGuardianTasks[userId])
		ActiveGuardianTasks[userId] = nil
		if DEBUG then
			print(("[BaseModule] 🗑️ Guardian cancelado (jugador salió)"):format())
		end
	end

	-- 🆕 LIMPIAR PENALIZACIONES PENDIENTES
	if PendingMoneyReductions[userId] then
		PendingMoneyReductions[userId] = nil
	end
end)

--[[
═══════════════════════════════════════════════════════════════════════

PASO 4: (OPCIONAL) DESACTIVAR GUARDIAN NORMAL
────────────────────────────────────────────────────────────────────────
Si tienes un guardian normal (loop que vigila PendingMoneyReductions),
DESACTÍVALO temporalmente para evitar conflictos.

Busca un bloque como:
```lua
task.spawn(function()
	while true do
		task.wait(1)
		for userId, data in pairs(PendingMoneyReductions) do
			-- ...
		end
	end
end)
```

COMÉNTALO con --[[ y --]]:
```lua
--[[ DESACTIVADO TEMPORALMENTE
task.spawn(function()
	while true do
		task.wait(1)
		for userId, data in pairs(PendingMoneyReductions) do
			-- ...
		end
	end
end)
--]]
```

═══════════════════════════════════════════════════════════════════════
🧪 TESTING
═══════════════════════════════════════════════════════════════════════

1. Aplica TODOS los cambios
2. Guarda (Ctrl+S)
3. Dale $1,000,000 a tu jugador
4. Deja que la base muera UNA vez
5. Observa el Output:
   ✅ Debería mostrar:
      - Dinero reducido a $750,000
      - Guardian activado
      - NO más spam de detective

6. Espera el autosave (120 segundos)
7. Verifica que se guarde $750,000 (NO $999,999)

═══════════════════════════════════════════════════════════════════════
✅ POR QUÉ ESTO FUNCIONA
═══════════════════════════════════════════════════════════════════════

ANTES:
1. BaseModule reduce cash.Value → $750,000
2. Economy.Cash mantiene → $999,999 ❌
3. Main.Server loop: cash.Value = Economy.Cash → $999,999
4. Guardian detecta y fuerza → $750,000
5. LOOP INFINITO ❌

DESPUÉS:
1. BaseModule reduce AMBOS:
   - cash.Value → $750,000 ✅
   - Economy.Cash → $750,000 ✅
2. Main.Server loop: cash.Value = Economy.Cash → $750,000
3. Guardian NO detecta cambio (ambos son $750,000)
4. NO HAY SPAM ✅
5. Autosave guarda $750,000 ✅

═══════════════════════════════════════════════════════════════════════
]]
