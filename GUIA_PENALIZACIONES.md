# 💀 GUÍA DE IMPLEMENTACIÓN - Sistema de Penalizaciones por Muerte

## 📋 RESUMEN

Este sistema agrega **consecuencias reales** cuando tu base es destruida:

✅ **Pantalla roja dramática** con "BASE DESTROYED"
✅ **Pérdida de dinero** (25% de tu cash actual)
✅ **Cooldown de respawn** (10 segundos sin jugar)
✅ **Respawn con HP reducida** (50% del máximo)

**Tiempo estimado de implementación: 10-15 minutos**

---

## 🎯 ARCHIVOS NECESARIOS

### **Ya creados en GitHub:**
1. `BaseDeathUI.client.lua` - UI de muerte (pantalla roja)
2. `SNIPPET_BASEMODULE_PENALIZACIONES.lua` - Función OnBaseDead
3. `SNIPPET_EVENTMANAGER_BASEDEAD.lua` - RemoteEvent BaseDead

---

## 🚀 PASO A PASO

### **PASO 1: Copiar BaseDeathUI.client.lua** (3 minutos)

1. **Ve a GitHub**: `src/StarterGui/BaseDeathUI.client.lua`
2. **Copia TODO el código** (Ctrl+A → Ctrl+C)
3. **En Roblox Studio**:
   - Ve a `StarterGui` (NO StarterPlayerScripts esta vez)
   - Clic derecho → **Insert Object** → **LocalScript**
   - Renombra a `BaseDeathUI`
   - Pega el código
   - Guarda (Ctrl+S)

**✅ Verificación:**
- El script está en `StarterGui.BaseDeathUI`
- Es un **LocalScript** (icono con engranaje)
- Tiene ~240 líneas

---

### **PASO 2: Agregar RemoteEvent en EventManager** (2 minutos)

1. **Abre** `ServerScriptService.EventManager_ARREGLADO`
2. **Busca** la sección de RemoteEvents (línea ~37-50)
3. Verás esto:

```lua
-- Create ScreenFlash RemoteEvent if it doesn't exist
if not Remotes:FindFirstChild("ScreenFlash") then
	local flash = Instance.new("RemoteEvent")
	flash.Name = "ScreenFlash"
	flash.Parent = Remotes
end
```

4. **INMEDIATAMENTE DESPUÉS**, agrega esto:

```lua
-- ✅ NUEVO: Create BaseDead RemoteEvent para notificaciones de muerte
if not Remotes:FindFirstChild("BaseDead") then
	local baseDead = Instance.new("RemoteEvent")
	baseDead.Name = "BaseDead"
	baseDead.Parent = Remotes

	if Config.DEBUG_MODE then
		print("[EventManager] ✅ RemoteEvent 'BaseDead' creado")
	end
end
```

5. **Guarda** (Ctrl+S)

**✅ Verificación:**
- El código está después de ScreenFlash
- Está ANTES del final del script
- No hay errores de sintaxis

---

### **PASO 3: Reemplazar función OnBaseDead en BaseModule** (5 minutos)

1. **Abre** `ServerScriptService.BaseModule_ARREGLADO`
2. **Busca** la función `OnBaseDead` (línea ~294 aproximadamente)
3. **Verás algo como esto:**

```lua
function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print((\"[BaseModule] 💀 BASE DESTRUIDA - userId %d\"):format(userId))
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- TODO: Implementar lógica de penalización aquí
	-- (posiblemente código viejo o comentarios)
end
```

4. **REEMPLAZA TODO ESO** con el código de `SNIPPET_BASEMODULE_PENALIZACIONES.lua`:

**Abre GitHub → SNIPPET_BASEMODULE_PENALIZACIONES.lua y copia las líneas 12-63:**

```lua
function BaseModule.OnBaseDead(userId: number)
	if DEBUG then
		print((\"[BaseModule] 💀 BASE DESTRUIDA - userId %d\"):format(userId))
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	-- ✅ PENALIZACIÓN PROGRESIVA (Opción A)

	-- 1. Calcular pérdida de dinero (25%)
	local leaderstats = player:FindFirstChild(\"leaderstats\")
	local cashValue = leaderstats and leaderstats:FindFirstChild(\"Cash\")
	local currentMoney = cashValue and cashValue.Value or 0

	local moneyLost = math.floor(currentMoney * 0.25) -- 25% de pérdida

	-- 2. Restar dinero
	if moneyLost > 0 and cashValue then
		cashValue.Value = math.max(0, currentMoney - moneyLost)

		if DEBUG then
			print((\"[BaseModule] Dinero perdido: $%d (25%% de $%d)\"):format(moneyLost, currentMoney))
		end
	end

	-- 3. Mostrar pantalla de muerte
	local BaseDead = game.ReplicatedStorage.Remotes:FindFirstChild(\"BaseDead\")
	if BaseDead then
		BaseDead:FireClient(player, moneyLost, 10) -- 10 segundos de cooldown
	end

	-- 4. Cooldown de respawn (10 segundos)
	task.wait(10)

	-- 5. Respawn con 50% HP
	local respawnHP = math.floor(Config.BASE_MAX_HP * 0.5)
	BaseModule.SetHP(userId, respawnHP)

	if DEBUG then
		print((\"[BaseModule] Base respawneada - userId %d con %d HP (50%%)\"):format(userId, respawnHP))
	end

	-- 6. Mensaje de ánimo
	if player then
		-- Opcional: Enviar mensaje motivacional
		local ShowNotification = game.ReplicatedStorage.Remotes:FindFirstChild(\"ShowNotification\")
		if ShowNotification then
			ShowNotification:FireClient(player, \"Base restored! Fight back! 💪\", 3)
		end
	end
end
```

5. **Guarda** (Ctrl+S)

**✅ Verificación:**
- La función OnBaseDead ahora tiene ~52 líneas (no solo un TODO)
- Tiene las 6 secciones: Calcular, Restar, Mostrar, Cooldown, Respawn, Mensaje
- No hay errores de sintaxis en rojo

---

### **PASO 4: TESTEAR** (5 minutos) ⭐ CRÍTICO

1. **Presiona Play** en Studio
2. **Dale dinero** a tu jugador (usa comando /give si tienes, o juega normalmente)
   - Asegúrate de tener al menos $1000 para ver la pérdida
3. **Deja que los meteoritos destruyan tu base**
   - Espera o presiona M varias veces si tienes spawn manual
4. **Verifica:**
   - ✅ Aparece pantalla roja con "BASE DESTROYED"
   - ✅ Muestra cuánto dinero perdiste
   - ✅ Countdown de 10 segundos visible
   - ✅ Después de 10s, la pantalla desaparece
   - ✅ Tu dinero bajó 25%
   - ✅ Tu base respawneó con 50% HP

**📊 Mensajes esperados en el Output:**

```
[EventManager] ✅ RemoteEvent 'BaseDead' creado
[BaseDeathUI] ✓ Listening for base death events
[BaseModule] 💀 BASE DESTRUIDA - userId 12345678
[BaseModule] Dinero perdido: $250 (25% de $1000)
[BaseModule] Base respawneada - userId 12345678 con 50 HP (50%)
[BaseDeathUI] Respawn animation completed
```

---

## 🔧 AJUSTAR DIFICULTAD (Opcional)

Si quieres hacer la penalización **más dura** o **más suave**, edita estas líneas en `OnBaseDead`:

### **Opción B - HARSH (Difícil):**

```lua
-- Cambiar estas 3 líneas:
local moneyLost = math.floor(currentMoney * 0.5) -- 50% en vez de 25%
BaseDead:FireClient(player, moneyLost, 20) -- 20 segundos en vez de 10
local respawnHP = math.floor(Config.BASE_MAX_HP * 0.25) -- 25% HP en vez de 50%
```

### **Opción C - SOFT (Fácil):**

```lua
-- Cambiar estas 3 líneas:
local moneyLost = math.floor(currentMoney * 0.1) -- 10% en vez de 25%
BaseDead:FireClient(player, moneyLost, 5) -- 5 segundos en vez de 10
local respawnHP = math.floor(Config.BASE_MAX_HP * 0.75) -- 75% HP en vez de 50%
```

---

## 💡 ¿POR QUÉ ESTA PENALIZACIÓN ES BUENA?

### **Crea incentivos para:**
1. **Saltar para evadir meteoritos** (MeteorDamageSystem)
2. **Comprar mejoras defensivas** (Shield Generator, Turrets)
3. **Comprar Wall Sections** para proteger la base
4. **Reparar la base a tiempo** antes de que muera

### **Balanceo:**
- **25% de pérdida** es suficiente para doler, pero no devastador
- **10s cooldown** da tiempo para leer el mensaje y planear estrategia
- **50% HP respawn** significa que no estás 100% vulnerable, pero tampoco seguro
- Necesitas **activamente reparar** o esperar regeneración

---

## 🆘 TROUBLESHOOTING

### **"La pantalla roja no aparece"**

**Causa:** BaseDeathUI no está corriendo o RemoteEvent no existe

**Solución:**
1. Verifica que `BaseDeathUI.client.lua` está en **StarterGui** (NO StarterPlayerScripts)
2. Abre el Output y busca: `[BaseDeathUI] ✓ Listening for base death events`
3. Si no está, verifica que es un **LocalScript** (no Script)
4. Verifica que agregaste el RemoteEvent en EventManager (PASO 2)

---

### **"El dinero no baja"**

**Causa 1:** No tienes leaderstats.Cash

**Solución:**
1. Verifica que tu jugador tiene `leaderstats` en el Explorer
2. Verifica que dentro de leaderstats hay un `IntValue` llamado `Cash`
3. Si no está, tu sistema de economía no está inicializado

**Causa 2:** Código de deducción no se ejecuta

**Solución:**
1. Mira el Output
2. Si dice `Dinero perdido: $0`, significa que cashValue.Value era 0
3. Dale dinero manualmente con un script: `player.leaderstats.Cash.Value = 1000`

---

### **"La base no respawnea"**

**Causa:** SetHP no existe o tiene un bug

**Solución:**
1. Verifica que `BaseModule.SetHP()` existe (debería estar en BaseModule_ARREGLADO)
2. Mira el Output para errores
3. Si dice error de SetHP, pégame el error completo

---

### **"El cooldown es demasiado largo/corto"**

**Solución:**
Ajusta el número en estas 2 líneas de `OnBaseDead`:

```lua
BaseDead:FireClient(player, moneyLost, 10) -- Cambia 10 por el valor que quieras
task.wait(10) -- Cambia 10 por el MISMO valor
```

Por ejemplo, para 5 segundos:
```lua
BaseDead:FireClient(player, moneyLost, 5)
task.wait(5)
```

---

## ✨ DESPUÉS DE IMPLEMENTAR

Una vez que TODO funcione, deberías notar:

✅ **Jugadores tienen incentivo real** para evitar que destruyan su base
✅ **La penalización es justa** - no pierdes todo, pero duele lo suficiente
✅ **La pantalla roja es dramática** - hace que la muerte se sienta importante
✅ **El mensaje motivacional** ayuda a no sentirse derrotado

---

## 📈 PRÓXIMOS PASOS

Después de que el sistema de penalizaciones funcione:

1. ✅ **Wave Counter** - Ya tenemos el snippet listo
2. ✅ **Eliminar barra de vida duplicada** - Ya tenemos el snippet
3. 🔄 **MeteorDamageSystem** - Sistema de salto para evadir
4. 🔄 **Tutorial interactivo** - Para nuevos jugadores
5. 🔄 **Claim Base System** - Para que nuevos usuarios reclamen su base

---

## 📊 CHECKLIST FINAL

Antes de marcar como completo:

### **Implementación:**
- [ ] BaseDeathUI.client.lua copiado en StarterGui
- [ ] RemoteEvent "BaseDead" agregado en EventManager
- [ ] Función OnBaseDead reemplazada en BaseModule

### **Testing:**
- [ ] Pantalla roja aparece al morir
- [ ] Muestra cuánto dinero perdiste
- [ ] Countdown de 10 segundos funciona
- [ ] Dinero baja 25%
- [ ] Base respawnea con 50% HP
- [ ] No hay errores en el Output

### **Opcional:**
- [ ] Ajusté la dificultad (HARSH/SOFT) según mi preferencia
- [ ] Probé con diferentes cantidades de dinero ($100, $1000, $10000)
- [ ] Mensaje motivacional aparece (si ShowNotification existe)

---

## 🎉 CONFIRMACIÓN

Cuando hayas terminado TODO, respóndeme:

1. ¿La pantalla roja aparece cuando muere tu base? (Sí/No)
2. ¿El dinero baja correctamente? (Sí/No)
3. ¿El countdown de 10s funciona? (Sí/No)
4. ¿Hay algún error en el Output? (Sí/No - pégame el error si hay)

Después continuamos con el wave counter y eliminar la barra duplicada.

---

_Guía creada: 2025-11-11_
_Sistema de penalización: PROGRESIVA (Opción A)_
_Pérdida: 25% dinero | Cooldown: 10s | Respawn: 50% HP_
