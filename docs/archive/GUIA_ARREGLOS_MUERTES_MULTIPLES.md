# 🔧 ARREGLOS PARA MUERTES MÚLTIPLES (10 MINUTOS)

## 🚨 PROBLEMAS IDENTIFICADOS

Tu output muestra 2 problemas críticos:

### **Problema #1: Guardians Múltiples Peleando**
```
Guardian FORZÓ dinero a $421,875
Guardian FORZÓ dinero a $316,407  ← Guardians peleando!
Guardian FORZÓ dinero a $421,875
Guardian FORZÓ dinero a $316,407
(x100 veces por segundo)
```

**Causa:** Cada muerte crea un nuevo guardian, pero el anterior NO se cancela.

### **Problema #2: Pantalla Roja No Aparece**
Después de varias muertes, la pantalla roja deja de funcionar.

**Causa:** El UI se queda "enabled = true" y no se resetea correctamente.

---

## ⚡ ARREGLO #1: Un Solo Guardian (7 minutos)

### **Paso 1: Agregar Variable Global** (1 min)

**Archivo:** `ServerScriptService.BaseModule`

Busca estas líneas al inicio (~línea 67-68):
```lua
local BaseState = {}
local PendingMoneyReductions = {}
```

**INMEDIATAMENTE DESPUÉS**, agrega:
```lua
local ActiveGuardianTasks = {} -- [userId] = task thread
```

Debería quedar:
```lua
local BaseState = {}
local PendingMoneyReductions = {}
local ActiveGuardianTasks = {}  ← NUEVA LÍNEA
```

---

### **Paso 2: Cancelar Guardian Previo** (4 min)

**Archivo:** `ServerScriptService.BaseModule`
**Función:** `OnBaseDead`

Busca el código del guardian rápido (~línea 365):
```lua
-- ✅ NUEVO: Forzar el valor INMEDIATAMENTE en un loop rápido
task.spawn(function()
    local forceDuration = 120
    ...
end)
```

**REEMPLAZA TODO ESE BLOQUE** con el código de `SOLUCION_UN_GUARDIAN.lua` (líneas 51-99).

O copia esto directamente:

```lua
-- ✅ CANCELAR guardian previo si existe
if ActiveGuardianTasks[userId] then
	task.cancel(ActiveGuardianTasks[userId])
	ActiveGuardianTasks[userId] = nil

	if DEBUG then
		print(("[BaseModule] ⚠️ Guardian previo cancelado para userId %d"):format(userId))
	end
end

-- ✅ NUEVO: Forzar el valor INMEDIATAMENTE en un loop rápido
ActiveGuardianTasks[userId] = task.spawn(function()
	local forceDuration = 120 -- Forzar por 120 segundos
	local startTime = tick()

	while tick() - startTime < forceDuration do
		task.wait(0.1)

		local plr = Players:GetPlayerByUserId(userId)
		if not plr then break end

		local stats = plr:FindFirstChild("leaderstats")
		local cash = stats and stats:FindFirstChild("Cash")

		if cash then
			if cash.Value ~= newAmount then
				cash.Value = newAmount

				if DEBUG then
					print(("[BaseModule] 🛡️ Guardian FORZÓ dinero a $%d (era $%d)"):format(
						newAmount, cash.Value
					))
				end
			end
		else
			break
		end
	end

	-- Limpiar al terminar
	ActiveGuardianTasks[userId] = nil

	if DEBUG then
		print(("[BaseModule] 🛡️ Guardian rápido terminado (120s) para userId %d"):format(userId))
	end
end)
```

---

### **Paso 3: Limpiar al Salir** (2 min)

**Archivo:** `ServerScriptService.BaseModule`

Busca esta sección cerca del final:
```lua
Players.PlayerRemoving:Connect(function(plr)
	BaseModule.RemovePlayer(plr.UserId)
end)
```

**REEMPLÁZALA** con:
```lua
Players.PlayerRemoving:Connect(function(plr)
	local userId = plr.UserId

	BaseModule.RemovePlayer(userId)

	-- ✅ NUEVO: Cancelar guardian activo
	if ActiveGuardianTasks[userId] then
		task.cancel(ActiveGuardianTasks[userId])
		ActiveGuardianTasks[userId] = nil

		if DEBUG then
			print(("[BaseModule] Guardian cancelado para jugador que se fue: %d"):format(userId))
		end
	end

	-- ✅ NUEVO: Limpiar pending reductions
	if PendingMoneyReductions[userId] then
		PendingMoneyReductions[userId] = nil
	end
end)
```

**Guarda** (Ctrl+S)

---

## ⚡ ARREGLO #2: Pantalla Roja (3 minutos)

**Archivo:** `StarterGui.BaseDeathUI`

Busca la línea (~183):
```lua
BaseDead.OnClientEvent:Connect(function(moneyLost: number, respawnTime: number)
```

**INMEDIATAMENTE DESPUÉS** (primera línea dentro de la función), agrega:

```lua
	-- ✅ ARREGLADO: Forzar reset si el UI está activo
	if screenGui.Enabled then
		screenGui.Enabled = false
		task.wait(0.1)
	end

	-- ✅ ARREGLADO: Reset completo de transparencias
	background.BackgroundTransparency = 0.3
	titleLabel.TextTransparency = 0
	titleLabel.TextStrokeTransparency = 0
	moneyLostLabel.TextTransparency = 0
	moneyLostLabel.TextStrokeTransparency = 0.5
	countdownLabel.TextTransparency = 0
	countdownLabel.TextStrokeTransparency = 0.5
	vignette.ImageTransparency = 0.5
```

Debería quedar así:
```lua
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
```

**Guarda** (Ctrl+S)

---

## 🧪 TESTING

1. **Presiona Play**
2. **Deja que la base muera 3-4 veces seguidas**
3. **Verifica el Output**

### 📊 Output Esperado:

**PRIMERA MUERTE:**
```
[BaseModule] 💀 BASE DESTRUIDA - userId 3620016515
[BaseModule] 💰 Dinero reducido: $999999 → $750000
[BaseModule] 🛡️ Guardian activado - Target: $750000
```

**SEGUNDA MUERTE:**
```
[BaseModule] 💀 BASE DESTRUIDA - userId 3620016515
[BaseModule] ⚠️ Guardian previo cancelado  ← ✅ NUEVO
[BaseModule] 💰 Dinero reducido: $750000 → $562500
[BaseModule] 🛡️ Guardian activado - Target: $562500
```

**NO DEBE HABER:**
- ❌ Guardian FORZÓ dinero (spam cada 0.1s)
- ❌ Múltiples valores compitiendo
- ❌ Tick tick tick constante

**Y LA PANTALLA ROJA:**
- ✅ Aparece en TODAS las muertes
- ✅ Countdown visible
- ✅ Mensaje de dinero perdido

---

## ✅ CHECKLIST

- [ ] Agregada variable `ActiveGuardianTasks` en BaseModule
- [ ] Guardian ahora cancela el previo antes de crear uno nuevo
- [ ] Limpieza de guardians en PlayerRemoving
- [ ] BaseDeathUI resetea transparencias al inicio
- [ ] Guardado ambos archivos
- [ ] Testing: muere 3-4 veces seguidas
- [ ] Verificar que NO hay spam de guardian
- [ ] Verificar que pantalla roja aparece siempre

---

## 💬 DESPUÉS DE IMPLEMENTAR, RESPÓNDEME:

1. ¿Hiciste los cambios en BaseModule? (Sí/No)
2. ¿Hiciste los cambios en BaseDeathUI? (Sí/No)
3. ¿Moriste 3-4 veces seguidas? (Sí/No)
4. ¿Viste "Guardian previo cancelado"? (Sí/No)
5. ¿La pantalla roja aparece siempre? (Sí/No)
6. ¿Hay spam de guardian en el Output? (Sí/No)
7. **¿Qué dice el AUTOSAVE después de varias muertes?** (pega la línea)

---

## 🎯 RESULTADO ESPERADO

Si funciona:
- ✅ **Solo UN guardian activo por jugador**
- ✅ **No más spam en el Output**
- ✅ **Dinero se mantiene estable**
- ✅ **Pantalla roja funciona siempre**
- ✅ **Autosave guarda el valor correcto**
- ✅ **Sistema 100% funcional en muertes múltiples**

---

**¡Estos son los ÚLTIMOS arreglos! Después de esto, todo funciona perfecto.** 💪
