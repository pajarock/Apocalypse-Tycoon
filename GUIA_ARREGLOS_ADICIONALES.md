# 🔧 GUÍA DE ARREGLOS ADICIONALES - Apocalypse Tycoon

## 📋 RESUMEN

Esta guía cubre los **últimos 2 arreglos** antes de que todo funcione perfectamente:

1. ✅ **Wave Counter** - Contador de oleadas en esquina superior derecha
2. ✅ **Eliminar barra de vida duplicada** - Solo mantener la de abajo-derecha

**Tiempo estimado: 10 minutos**

---

## 🎯 ARREGLO #1: WAVE COUNTER

### **Problema:**
- El servidor actualiza `ServerState.CurrentWave`
- Pero el cliente no lo ve
- El contador en pantalla no se actualiza

### **Solución:**
Sincronizar usando un `IntValue` en ReplicatedStorage que el cliente pueda escuchar.

---

### **PASO 1: Crear IntValue** (2 minutos)

1. **Abre** `ServerScriptService.Main.Server`
2. **Busca** la sección de ServerState (línea ~105-112):

```lua
local ServerState = {
	StartTime = os.time(),
	CurrentWave = 1,
	PlayersJoined = 0,
	TotalPurchases = 0,
	TotalDamage = 0,
}
```

3. **INMEDIATAMENTE DESPUÉS**, agrega esto:

```lua
-- ✅ NUEVO: Crear IntValue para sincronizar wave counter con clientes
local CurrentWaveValue = Instance.new("IntValue")
CurrentWaveValue.Name = "CurrentWave"
CurrentWaveValue.Value = ServerState.CurrentWave
CurrentWaveValue.Parent = game.ReplicatedStorage

if Config.DEBUG_MODE then
	print("[MAIN] ✅ IntValue 'CurrentWave' creado en ReplicatedStorage")
end
```

4. **Guarda** (Ctrl+S)

---

### **PASO 2: Sincronizar al avanzar Wave** (2 minutos)

1. **En el mismo archivo** (Main.Server.lua)
2. **Busca** el código donde avanza la wave (línea ~1431):

```lua
ServerState.CurrentWave += 1

logAnalytic("WaveCompleted", {
	wave = ServerState.CurrentWave - 1,
	survivors = #Players:GetPlayers(),
})
```

3. **REEMPLAZA** con esto:

```lua
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
```

4. **Guarda** (Ctrl+S)

---

### **PASO 3: Verificar que WaveCounterUI existe** (1 minuto)

1. **Ve a** `StarterPlayer → StarterPlayerScripts`
2. **Busca** un archivo llamado `WaveCounterUI` o `WaveCounterUI.client`
3. **Si NO existe:**
   - Ve a GitHub: `StarterPlayerScripts/WaveCounterUI.client.lua`
   - Cópialo completo
   - Crea un LocalScript en StarterPlayerScripts
   - Renombra a `WaveCounterUI`
   - Pega el código

**✅ Verificación:**
- El archivo está en `StarterPlayerScripts.WaveCounterUI`
- Es un **LocalScript**
- Tiene ~217 líneas

---

### **TESTING: Wave Counter** (3 minutos)

1. **Presiona Play** en Studio
2. **Mira la esquina superior derecha**
3. **Deberías ver:**
   - Un contador naranja con icono ☄️
   - Texto "WAVE 1"
   - Subtítulo "Survived"

**📊 Mensajes esperados en el Output:**

```
[MAIN] ✅ IntValue 'CurrentWave' creado en ReplicatedStorage
[WaveCounterUI] ✓ Conectado a CurrentWave IntValue
[WaveCounterUI] ✓ UI de wave counter creada
```

4. **Espera ~30 segundos** (o lo que dure tu primera wave)
5. **Verifica que el contador cambia a "WAVE 2"**
6. **Deberías ver:**
   - Animación de "pulse" (el contador se expande/contrae)
   - Flash naranja brillante en el borde
   - Mensaje en Output: `[WaveCounterUI] 🎉 Wave 2 alcanzada!`

**❌ Si NO ves el contador:**
- Verifica que agregaste las 2 secciones de código (PASO 1 y PASO 2)
- Mira el Output para warnings en amarillo
- Si dice "No se encontró CurrentWave", revisa el PASO 1

**❌ Si el contador no avanza:**
- Revisa el PASO 2
- Verifica que `CurrentWaveValue.Value = ServerState.CurrentWave` está correcto
- No hay typos en el nombre de la variable

---

## 🎯 ARREGLO #2: ELIMINAR BARRA DE VIDA DUPLICADA

### **Problema:**
- Hay 2 barras de HP de la base:
  1. **Billboard** (flotante sobre la base) ← DUPLICADA
  2. **BaseHUD** (abajo-derecha en pantalla) ← QUEREMOS ESTA

### **Solución:**
Deshabilitar el Billboard en BaseVisualsManager

---

### **PASO 1: Abrir BaseVisualsManager** (1 minuto)

1. **Ve a** `ServerStorage → Managers`
2. **Abre** `BaseVisualsManager`
3. **Busca** la función que crea el Billboard (línea ~449)

---

### **PASO 2: Deshabilitar creación de Billboard** (1 minuto)

1. **Busca** esta línea (aprox. línea 449):

```lua
local billboard = createBillboard(basePart, playerName, userId)
```

2. **REEMPLAZA** con esto:

```lua
-- ✅ ARREGLADO: Deshabilitar billboard duplicado - usamos BaseHUD.client.lua
local billboard = nil -- Sin billboard duplicado
```

3. **Guarda** (Ctrl+S)

---

### **PASO 3: Deshabilitar actualizaciones de Billboard** (2 minutos)

1. **En el mismo archivo**, busca el código que actualiza el billboard (línea ~495-519)
2. **Verás algo como esto:**

```lua
-- Update Billboard HP bar
local billboard = data.decorations.billboard
if billboard then
	local hpBar = billboard:FindFirstChild("HPBar", true)
	if hpBar and hpBar:IsA("Frame") then
		local fill = hpBar:FindFirstChild("Fill")
		if fill and fill:IsA("Frame") then
			local percent = data.HP / data.MaxHP
			fill.Size = UDim2.new(percent, 0, 1, 0)

			-- Color según HP
			if percent > 0.6 then
				fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			elseif percent > 0.3 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
			else
				fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
		end
	end
end
```

3. **COMENTA TODO ESE BLOQUE** agregando `--[[` al inicio y `--]]` al final:

```lua
--[[
-- ✅ ARREGLADO: Billboard deshabilitado - actualizaciones se hacen en BaseHUD.client.lua
-- Update Billboard HP bar
local billboard = data.decorations.billboard
if billboard then
	local hpBar = billboard:FindFirstChild("HPBar", true)
	if hpBar and hpBar:IsA("Frame") then
		local fill = hpBar:FindFirstChild("Fill")
		if fill and fill:IsA("Frame") then
			local percent = data.HP / data.MaxHP
			fill.Size = UDim2.new(percent, 0, 1, 0)

			-- Color según HP
			if percent > 0.6 then
				fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			elseif percent > 0.3 then
				fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
			else
				fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
		end
	end
end
--]]
```

4. **Guarda** (Ctrl+S)

---

### **TESTING: Barra única** (2 minutos)

1. **Presiona Play** en Studio
2. **Mira tu base**
3. **Verifica:**
   - ✅ NO hay barra flotante sobre la base
   - ✅ SÍ hay barra en la esquina inferior derecha
   - ✅ La barra de abajo-derecha se actualiza al recibir daño

4. **Spawna un meteorito** (presiona M si tienes el comando)
5. **Verifica:**
   - La barra de abajo-derecha baja correctamente
   - NO hay barra flotante
   - El resto del juego funciona normal

**✅ Si todo funciona:**
- Solo deberías ver UNA barra de HP (abajo-derecha)
- La barra se actualiza correctamente
- No hay errores en el Output

---

## 📊 CHECKLIST FINAL

### **Wave Counter:**
- [ ] IntValue creado en Main.Server (después de ServerState)
- [ ] CurrentWaveValue.Value se actualiza al avanzar wave
- [ ] WaveCounterUI.client.lua existe en StarterPlayerScripts
- [ ] Contador aparece en esquina superior derecha
- [ ] Contador avanza al completar waves
- [ ] Animación de pulse y flash funciona

### **Barra de Vida Única:**
- [ ] Billboard creación deshabilitada (línea ~449)
- [ ] Billboard actualizaciones comentadas (líneas ~495-519)
- [ ] Solo hay UNA barra visible (abajo-derecha)
- [ ] La barra se actualiza correctamente
- [ ] No hay errores en el Output

---

## 🆘 TROUBLESHOOTING

### **"El wave counter dice 'No se encontró CurrentWave'"**

**Solución:**
1. Verifica que agregaste el código del PASO 1 (crear IntValue)
2. Verifica que está DESPUÉS de la declaración de ServerState
3. Verifica que dice `CurrentWaveValue.Parent = game.ReplicatedStorage`
4. NO debe tener typos en el nombre "CurrentWave"

---

### **"El contador aparece pero no avanza"**

**Solución:**
1. Verifica que agregaste el código del PASO 2 (sincronizar)
2. Verifica que la línea `CurrentWaveValue.Value = ServerState.CurrentWave` existe
3. Mira el Output al completar una wave
4. Debería decir: `[MAIN] ✅ Wave actualizada a 2`

---

### **"Sigo viendo la barra flotante"**

**Solución:**
1. Verifica que comentaste la creación de billboard (PASO 2 del arreglo #2)
2. Verifica que la línea dice `local billboard = nil`
3. Si aún aparece, busca en BaseVisualsManager otras menciones de "billboard"
4. Puede que haya múltiples lugares donde se crea

---

### **"La barra de abajo-derecha no se actualiza"**

**Causa:** Esto es un problema diferente (BaseHUD.client.lua)

**Solución:**
1. Verifica que `BaseHUD.client.lua` existe en StarterGui
2. Verifica que escucha el RemoteEvent "BaseStateChanged"
3. Mira el Output para errores
4. Si no hay mensajes de BaseHUD, el script no está corriendo

---

## ✨ DESPUÉS DE IMPLEMENTAR

Una vez que ambos arreglos funcionen:

✅ **Wave Counter:**
- Contador visible en esquina superior derecha
- Se actualiza automáticamente cada wave
- Animaciones dramáticas al avanzar
- Los jugadores saben en qué wave están

✅ **Barra de Vida Única:**
- Solo UNA barra visible (abajo-derecha)
- Menos confusión para el jugador
- Mejor UX (no hay información duplicada)
- Más espacio visual en la base

---

## 🎉 CONFIRMACIÓN FINAL

Cuando hayas terminado TODO, respóndeme:

1. ¿El wave counter aparece y se actualiza? (Sí/No)
2. ¿Solo hay UNA barra de vida? (Sí/No)
3. ¿La barra de abajo-derecha funciona correctamente? (Sí/No)
4. ¿Hay algún error en el Output? (Sí/No - pégame el error si hay)

---

## 📈 ESTADO DEL PROYECTO

### **✅ COMPLETO:**
1. Meteoritos visibles
2. Camera shake
3. Screen flash
4. Sistema de penalizaciones por muerte
5. Wave counter
6. Barra de vida única

### **🔄 PENDIENTE:**
1. Claim Base System (nuevo usuario reclama base + primera mascota)
2. MeteorDamageSystem (salto para evadir)
3. Tutorial interactivo
4. ProceduralModels para upgrades
5. Mapa/terreno

### **🚀 LISTO PARA CONTINUAR:**
Una vez que estos 2 arreglos funcionen, el juego estará **100% estable** y podemos continuar con las features nuevas sin preocuparnos de bugs básicos.

---

_Guía creada: 2025-11-11_
_Prioridad: MEDIA_
_Dependencias: GUIA_IMPLEMENTACION_COMPLETA.md, GUIA_PENALIZACIONES.md_
