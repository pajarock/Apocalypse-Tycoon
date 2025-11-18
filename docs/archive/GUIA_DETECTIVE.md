# 🔍 MODO DETECTIVE - Averiguar Qué Cambia el Dinero (5 MINUTOS)

## 🎯 OBJETIVO

Todavía hay spam (x40/s) porque **algo está cambiando el dinero constantemente**.

Vamos a averiguar **QUÉ** lo está cambiando.

---

## ⚡ 4 CAMBIOS RÁPIDOS

### **CAMBIO #1: Arreglar Error Línea 611** (1 min)

**Archivo:** `ServerScriptService.BaseModule`

Busca el **loop de regeneración** (cerca de línea 611):

```lua
for userId, state in pairs(BaseState) do
	if state.RegenEnabled and state.HP < state.MaxHP then
```

**REEMPLAZA TODO EL LOOP** con el código de `DIAGNOSTICO_FINAL.lua` (líneas 24-52).

O usa este código:

```lua
-- Loop de regeneración (iniciar en el server)
task.spawn(function()
	while true do
		task.wait(1)

		for userId, state in pairs(BaseState) do
			-- ✅ ARREGLADO: Validar todo
			if state and type(state) == "table" then
				local hp = state.HP
				local maxHP = state.MaxHP
				local regenEnabled = state.RegenEnabled
				local lastDamageTime = state.LastDamageTime or 0

				if hp and maxHP and regenEnabled and type(hp) == "number" and type(maxHP) == "number" then
					if hp < maxHP then
						local timeSinceDamage = tick() - lastDamageTime

						if timeSinceDamage >= Config.BASE_REGEN_DELAY then
							state.HP = math.min(hp + Config.BASE_REGEN_RATE, maxHP)

							if DEBUG and state.HP % 10 == 0 then
								print(("[BaseModule] Regen - userId %d: %d/%d"):format(
									userId, state.HP, state.MaxHP
								))
							end
						end
					end
				end
			end
		end
	end
end)
```

---

### **CAMBIO #2: Mejorar Debug del Guardian** (2 min)

**Archivo:** `ServerScriptService.BaseModule`
**Función:** `OnBaseDead`, dentro del guardian rápido

Busca (~línea 380-392):

```lua
if cash.Value ~= newAmount then
	cash.Value = newAmount

	if DEBUG then
		print(("[BaseModule] 🛡️ Guardian FORZÓ dinero a $%d (era $%d)"):format(
			newAmount, cash.Value
		))
	end
end
```

**REEMPLAZA con:**

```lua
if cash.Value ~= newAmount then
	local oldValue = cash.Value  -- ✅ Guardar ANTES de cambiar

	-- ✅ DETECTIVE: Averiguar qué pasó
	if DEBUG then
		print(("[BaseModule] 🔍 DETECTIVE: Dinero cambió de $%d → $%d (debería ser $%d)"):format(
			newAmount, oldValue, newAmount
		))
	end

	cash.Value = newAmount

	if DEBUG then
		print(("[BaseModule] 🛡️ Guardian FORZÓ: $%d → $%d"):format(
			oldValue, cash.Value
		))
	end
end
```

---

### **CAMBIO #3: Desactivar Guardian Normal** (1 min)

**Archivo:** `ServerScriptService.BaseModule`

Cerca del **final del archivo** (antes de `return BaseModule`), busca:

```lua
task.spawn(function()
	while true do
		task.wait(1)

		for userId, data in pairs(PendingMoneyReductions) do
			-- ... código ...
		end
	end
end)
```

**COMENTA TODO ESE BLOQUE:**

```lua
--[[ ✅ DESACTIVADO TEMPORALMENTE PARA TESTING
task.spawn(function()
	while true do
		task.wait(1)

		for userId, data in pairs(PendingMoneyReductions) do
			-- ... código ...
		end
	end
end)
--]]
```

Agrega `--[[` al inicio y `--]]` al final.

---

### **CAMBIO #4: Activar DEBUG** (1 min)

**Archivo:** `ServerScriptService.BaseModule`

Al inicio del archivo (~línea 61), busca:

```lua
local DEBUG = Config.DEBUG_MODE or false
```

**Cámbiala temporalmente a:**

```lua
local DEBUG = true -- ✅ Forzado para testing
```

**Guarda todos los cambios** (Ctrl+S)

---

## 🧪 TESTING CRÍTICO

1. **Presiona Play**
2. **Dale $1,000,000**
3. **Deja que la base muera UNA SOLA VEZ**
4. **ESPERA 30 SEGUNDOS**
5. **COPIA TODO EL OUTPUT** (todo, desde que muere hasta que para el spam)

### 📊 Busca Estas Líneas:

```
[BaseModule] 🔍 DETECTIVE: Dinero cambió de $750000 → $999999
[BaseModule] 🛡️ Guardian FORZÓ: $999999 → $750000
```

**ESTO NOS DIRÁ:**
- De qué valor a qué valor está cambiando
- Cuántas veces por segundo
- Si es el autosave, DataStore, u otra cosa

---

## 💬 DESPUÉS DEL TEST, RESPÓNDEME:

1. ¿Hiciste los 4 cambios? (Sí/No)
2. **PEGA TODO EL OUTPUT** (desde que muere hasta que para)
3. ¿Cuántas veces aparece "🔍 DETECTIVE"?
4. ¿Qué valores muestra? ($X → $Y)
5. ¿Hay error de línea 611? (Sí/No)

---

## 🎯 CON ESTA INFORMACIÓN

Sabré **EXACTAMENTE** qué está cambiando el dinero:

- Si es el autosave → Modificaremos el autosave
- Si es el DataStore → Modificaremos DataStore
- Si es otro sistema → Lo desactivaremos temporalmente

**Necesito ver el output completo para diagnosticar correctamente.** 🔍

---

## ⚠️ IMPORTANTE

**NO** juegues mucho tiempo con esto - solo UNA muerte y espera 30 segundos.

El objetivo es **diagnosticar**, no probar el sistema completo.

Después de ver el output, te daré la solución definitiva.
