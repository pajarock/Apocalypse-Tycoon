# 🚀 2 ARREGLOS ULTRA-SIMPLES (10 MINUTOS)

## ❌ PROBLEMAS ACTUALES

1. **Error línea 530** - `attempt to compare nil <= number`
2. **Dinero no se reduce** - Autosave lo revierte de $750,000 → $999,999

**BUENAS NOTICIAS:** NO necesitas tocar Main.Server.lua ✅

---

## ⚡ ARREGLO #1: Error Línea 530 (3 minutos)

**Archivo:** `ServerScriptService.BaseModule`

### Paso 1: Buscar el loop de regeneración

Presiona **Ctrl+F** y busca: `Loop de regeneración`

O busca línea ~324 que dice:
```lua
task.spawn(function()
	while true do
		task.wait(1)

		for userId, state in pairs(BaseState) do
			if state.RegenEnabled and state.HP < state.MaxHP then
```

### Paso 2: Cambiar UNA línea

Busca esta línea específica (aproximadamente línea 330):
```lua
if state.RegenEnabled and state.HP < state.MaxHP then
```

**Reemplázala con ESTAS 7 LÍNEAS:**
```lua
if state and type(state) == "table" then
	local hp = state.HP
	local maxHP = state.MaxHP
	local regenEnabled = state.RegenEnabled
	local lastDamageTime = state.LastDamageTime or 0

	if hp and maxHP and regenEnabled and hp < maxHP then
```

### Paso 3: Agregar un `end` extra

Al final del bloque del `if` (aproximadamente línea 343), antes del último `end`, agrega:
```lua
		end  -- ✅ NUEVO: Cierra el if state
	end      -- Cierra el for (ya existía)
end          -- Cierra el while (ya existía)
```

### Paso 4: Cambiar `state.LastDamageTime`

Busca esta línea dentro del loop:
```lua
local timeSinceDamage = tick() - state.LastDamageTime
```

**Cámbiala a:**
```lua
local timeSinceDamage = tick() - lastDamageTime
```

Y también cambia:
```lua
state.HP = math.min(state.HP + Config.BASE_REGEN_RATE, state.MaxHP)
```

Por:
```lua
state.HP = math.min(hp + Config.BASE_REGEN_RATE, maxHP)
```

**Guarda** (Ctrl+S)

✅ **Resultado:** No más error de línea 530

---

## ⚡ ARREGLO #2: Dinero (7 minutos)

### Paso 1: Agregar el Guardian

**Archivo:** `ServerScriptService.BaseModule`

1. Ve al **FINAL** del archivo
2. Busca: `return BaseModule`
3. **ANTES** de esa línea, copia todo el código de `CODIGO_GUARDIAN_DINERO.lua` (líneas 14-59)
4. Pégalo
5. **Guarda** (Ctrl+S)

### Paso 2: Activar el Guardian en OnBaseDead

**En la misma función OnBaseDead:**

1. Busca donde reduces el dinero:
```lua
cashValue.Value = math.max(0, currentMoney - moneyLost)
```

2. **INMEDIATAMENTE DESPUÉS**, agrega estas 5 líneas:
```lua
-- ✅ Activar guardian
PendingMoneyReductions[userId] = {
	targetAmount = cashValue.Value,
	timestamp = tick()
}
```

3. **Guarda** (Ctrl+S)

✅ **Resultado:** El dinero se mantendrá reducido aunque el autosave intente revertirlo

---

## 🧪 TESTING (5 minutos)

1. **Presiona Play** en Studio
2. **Dale $1,000,000** a tu jugador
3. **Deja que la base muera**

### Output Esperado:

```
[BaseModule] 💀 BASE DESTRUIDA - userId 3620016515
[BaseModule] 💰 Dinero reducido: $999999 → $750000 (pérdida: $249999)
[BaseModule] 🛡️ Guardian activado por 120 segundos

... (espera 30-60s al autosave) ...

[BaseModule] 🛡️ Guardian: Forzando dinero de userId 3620016515 a $750000
[DATASTORE] saved uid=3620016515 cash=750000  ← ✅ CORRECTO
[AUTOSAVE] Guardado: averockMx ($750000)

... (espera 2 minutos) ...

[BaseModule] ✓ Guardian: Dinero de userId 3620016515 asegurado
```

---

## ✅ CHECKLIST

Después de implementar:

- [ ] No hay error de línea 530 en el Output
- [ ] El dinero se reduce en pantalla (esquina superior derecha)
- [ ] El autosave guarda el dinero reducido (no $999,999)
- [ ] Aparece mensaje "Guardian activado"
- [ ] Aparece mensaje "Guardian: Forzando dinero"
- [ ] Después de 2 minutos, aparece "Guardian asegurado"

---

## 🆘 SI ALGO NO FUNCIONA

### "Sigo viendo error de línea 530"
→ Verifica que agregaste el `end` extra
→ Cuenta los `end` del loop: debe haber 3 en total

### "El guardian no aparece en el Output"
→ Verifica que pegaste el código del guardian ANTES de `return BaseModule`
→ Verifica que agregaste las 5 líneas en OnBaseDead

### "El dinero sigue sin reducirse"
→ Espera 60 segundos al primer autosave
→ Verifica que aparece el mensaje "Guardian: Forzando dinero"
→ Si no aparece, el guardian no está activado correctamente

---

## 📁 ARCHIVOS EN GITHUB

- `SOLUCION_FINAL_SIMPLE.lua` - Explicación completa
- `CODIGO_GUARDIAN_DINERO.lua` - Código listo para copiar
- `ARREGLOS_ULTRA_SIMPLES.md` - Esta guía

---

## 💬 CONFIRMACIÓN

Cuando termines, respóndeme con:

1. ¿Ya NO hay error de línea 530? (Sí/No)
2. **Pega la línea del AUTOSAVE** después de morir
3. ¿Viste el mensaje "Guardian activado"? (Sí/No)
4. ¿Viste el mensaje "Guardian: Forzando dinero"? (Sí/No)

¡Ya casi terminamos! Estos son los ÚLTIMOS arreglos antes de que todo funcione perfecto 💪
