# 🎮 IMPLEMENTACIÓN OPCIONES A Y B - Apocalypse Tycoon

## 📋 RESUMEN

Este documento explica cómo implementar las dos opciones de gameplay solicitadas:

- **OPCIÓN A:** Sistema de Salto para Evadir Meteoritos + Feedback Visual ⭐ (1 hora)
- **OPCIÓN B:** Tutorial Interactivo para Nuevos Jugadores 📚 (1-2 horas)

Ambas opciones están **LISTAS PARA USAR** y solo requieren copiar archivos de GitHub a Roblox Studio.

---

## ⭐ OPCIÓN A: Sistema de Salto para Evadir Meteoritos

### **¿Qué hace?**
- Los jugadores pueden **saltar** (tecla Espacio) cuando un meteorito está por impactar
- Si están en el aire (saltando), **evaden el daño**
- Si están en el suelo, **reciben daño**
- **Feedback visual:**
  - Notificación "✓ DODGED!" (verde) cuando evaden
  - Notificación "-X HP" (rojo) cuando reciben daño
  - Camera shake diferente según resultado
- **Tracking de estadísticas:** dodges, hits, dodge rate

### **Estado Actual:**
- ✅ **MeteorDamageSystem.lua** → Ya existe en GitHub (ServerStorage/)
- ✅ **NotificationUI.client.lua** → Recién creado (StarterPlayerScripts/)
- ✅ **EventManager_REFACTORED.lua** → Ya configurado para crear RemoteEvents
- ⚠️ **Requiere:** Copiar 3 archivos a Studio

---

### **PASO A PASO - Implementar Opción A**

#### **1. Copiar archivos de GitHub a Roblox Studio:**

| GitHub | Roblox Studio | Acción |
|--------|---------------|--------|
| `ServerStorage/MeteorDamageSystem.lua` | `ServerStorage.MeteorDamageSystem` | Copiar como ModuleScript |
| `StarterPlayerScripts/NotificationUI.client.lua` | `StarterPlayerScripts.NotificationUI` | Copiar como LocalScript |
| `ServerStorage/EventManager_REFACTORED.lua` | `ServerScriptService.EventManager` | **REEMPLAZAR** tu EventManager actual |

#### **2. Verificar que existan los RemoteEvents:**

EventManager_REFACTORED crea automáticamente estos RemoteEvents al iniciarse:
- `ReplicatedStorage.Remotes.CameraShake`
- `ReplicatedStorage.Remotes.ShowNotification`

Si ya los creaste manualmente, EventManager los usará. Si no existen, los crea automáticamente.

#### **3. Verificar integración en tu main.server.lua:**

Asegúrate que EventManager llama a MeteorDamageSystem cuando impacta un meteorito.

**EventManager_REFACTORED.lua ya lo hace automáticamente** (líneas 274-280):
```lua
-- DAÑO A JUGADORES (mecánica de salto para evadir)
if hasMeteorDamage and MeteorDamageSystem then
	local basePart = getPlayerBasePart(ownerPlr)
	if basePart then
		MeteorDamageSystem:OnMeteorImpact(hitPos, basePart, meteorType)
	end
end
```

Si usas EventManager_REFACTORED, **no necesitas hacer nada más**. ✅

#### **4. Configuración (opcional):**

Puedes ajustar estos valores en `ServerStorage/Config/Config.lua`:

```lua
-- Configuración de daño a jugadores
METEOR_DAMAGE_RADIUS = 20,        -- Radio de daño en studs
METEOR_PLAYER_DAMAGE = 25,        -- Daño base a jugadores
JUMP_IMMUNITY_HEIGHT = 5,         -- Altura mínima para evadir
```

#### **5. Testing:**

1. Inicia el juego en Studio
2. Presiona **M** para spawnar un meteorito
3. **Prueba 1:** Quédate quieto → Deberías ver "-25 HP" (rojo) y camera shake fuerte
4. **Prueba 2:** Salta cuando el meteorito esté cayendo → Deberías ver "✓ DODGED!" (verde)
5. Verifica que tu barra de HP (abajo de la pantalla) cambie al recibir daño

#### **6. Debug:**

Si algo no funciona, verifica el Output:
```
[MeteorDamageSystem] ✓ Inicializado
[NotificationUI] ✓ Conectado a ShowNotification RemoteEvent
[EventManager] RemoteEvent 'ShowNotification' creado automáticamente
```

Si ves warnings, revisa que hayas copiado todos los archivos correctamente.

---

### **ESTADÍSTICAS Y ACHIEVEMENTS (Bonus)**

MeteorDamageSystem trackea automáticamente:
- `dodges` - Cantidad de meteoritos evadidos
- `hits` - Cantidad de meteoritos que te golpearon
- `dodge rate` - Porcentaje de evasión

Para ver las stats de un jugador:
```lua
-- Desde un servidor script
local MeteorDamageSystem = require(game.ServerStorage.MeteorDamageSystem)

local stats = MeteorDamageSystem:GetPlayerStats(userId)
print("Dodges:", stats.dodges)
print("Hits:", stats.hits)

local dodgeRate = MeteorDamageSystem:GetDodgeRate(userId)
print("Dodge rate:", dodgeRate * 100, "%")
```

Puedes usar estos datos para:
- Achievements ("Evade 10 meteoritos")
- Leaderboard de mejores esquivadores
- Rewards ("50% dodge rate → bonus coins")

---

## 📚 OPCIÓN B: Tutorial Interactivo

### **¿Qué hace?**
- **Tutorial paso a paso** para nuevos jugadores
- Aparece automáticamente la primera vez que juegan
- Guía visual con flechas, highlights y círculos
- Pasos interactivos:
  1. Bienvenida
  2. Recolectar coins iniciales
  3. Comprar primer upgrade
  4. Explicar sistema de meteoritos
  5. Enseñar mecánica de salto
  6. Mostrar wave counter
  7. Finalizar

### **Estado Actual:**
- ✅ **TutorialManager.lua** → Ya existe en GitHub (ServerStorage/)
- ⚠️ **Requiere:** Activación en main.server.lua
- ⚠️ **Opcional:** Crear UI personalizado (o usar el incluido)

---

### **PASO A PASO - Implementar Opción B**

#### **1. Copiar archivo de GitHub:**

| GitHub | Roblox Studio | Acción |
|--------|---------------|--------|
| `ServerStorage/TutorialManager.lua` | `ServerStorage.TutorialManager` | Copiar como ModuleScript |

#### **2. Activar el tutorial en main.server.lua:**

Busca la sección donde un jugador se une al juego (PlayerAdded) y agrega:

```lua
local Players = game:GetService("Players")
local TutorialManager = require(game.ServerStorage.TutorialManager)

Players.PlayerAdded:Connect(function(player)
	-- ... tu código existente (crear base, dar coins, etc.) ...

	-- 🔥 NUEVO: Iniciar tutorial para jugadores nuevos
	task.spawn(function()
		-- Esperar a que el jugador cargue completamente
		player.CharacterAdded:Wait()
		task.wait(2) -- Delay para que vea el mundo

		-- Verificar si es primera vez que juega
		local hasPlayedBefore = player:GetAttribute("HasCompletedTutorial")

		if not hasPlayedBefore then
			print(("[TUTORIAL] Iniciando para %s"):format(player.Name))

			-- Iniciar tutorial
			TutorialManager:StartTutorial(player)

			-- Cuando termine, marcar como completado
			player:SetAttribute("HasCompletedTutorial", true)

			-- Opcional: Dar reward por completar tutorial
			-- EconomyManager:AddCoins(player.UserId, 500)
		else
			print(("[TUTORIAL] %s ya completó el tutorial"):format(player.Name))
		end
	end)
end)
```

#### **3. Personalizar pasos del tutorial (opcional):**

Si quieres modificar los pasos, edita `TutorialManager.lua` línea ~150:

```lua
local TUTORIAL_STEPS = {
	{
		ID = "welcome",
		Title = "¡Bienvenido a Apocalypse Tycoon!",
		Description = "Sobrevive a oleadas de meteoritos y mejora tu base.",
		Duration = 4,
		CameraFocus = nil, -- Sin focus especial
	},
	{
		ID = "collect_coins",
		Title = "Recolectar Recursos",
		Description = "Camina hacia los coins que aparecen para recolectarlos.",
		Duration = 10,
		HighlightPart = "CoinSpawner", -- Nombre del part a destacar
		WaitForAction = "CollectCoin", -- Esperar a que recolecte
	},
	-- ... más pasos ...
}
```

#### **4. Testing:**

1. **Borra** el atributo `HasCompletedTutorial` de tu jugador:
   ```lua
   -- En consola de Studio:
   game.Players.LocalPlayer:SetAttribute("HasCompletedTutorial", false)
   ```

2. Reinicia el juego

3. El tutorial debería iniciarse automáticamente

4. Sigue los pasos y verifica que funcione correctamente

#### **5. Configuración avanzada:**

Puedes personalizar el UI del tutorial editando las funciones de creación de UI en TutorialManager:
- `createTutorialUI()` - UI principal
- `createHighlight()` - Highlight de objetos
- `createArrow()` - Flechas indicadoras

---

### **SKIP TUTORIAL (Opcional)**

Si quieres permitir que los jugadores salten el tutorial:

1. Agrega un botón "Skip" en el UI del tutorial
2. Conecta el botón a esta función:
   ```lua
   local function onSkipButtonPressed()
   	TutorialManager:SkipTutorial(player)
   	player:SetAttribute("HasCompletedTutorial", true)
   end
   ```

---

## 🔄 COMBINANDO OPCIONES A Y B

Si implementas ambas opciones, el tutorial puede enseñar la mecánica de salto:

```lua
-- En TutorialManager, paso de enseñar dodge
{
	ID = "teach_dodge",
	Title = "¡Evade Meteoritos!",
	Description = "Presiona ESPACIO para saltar cuando un meteorito esté cerca. Si estás en el aire, evadirás el daño.",
	Duration = 8,
	TriggerEvent = "SpawnTutorialMeteor", -- Spawnar meteorito de práctica
	WaitForAction = "DodgeMeteor", -- Esperar a que esquive
},
```

Y en el listener del tutorial:
```lua
-- Conectar con MeteorDamageSystem
MeteorDamageSystem.OnDodge:Connect(function(userId, meteorType)
	-- Si el jugador está en tutorial, avanzar al siguiente paso
	if TutorialManager:IsInTutorial(userId) then
		TutorialManager:CompleteStep(userId, "teach_dodge")
	end
end)
```

---

## 📊 COMPARACIÓN DE OPCIONES

| Característica | Opción A | Opción B | Tiempo |
|----------------|----------|----------|--------|
| Gameplay nuevo | ✅ Mecánica de salto | ❌ Solo tutorial | 1h |
| Retención de jugadores | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | - |
| Dificultad de implementación | 🟢 Fácil | 🟡 Media | - |
| Feedback visual | ✅ Notificaciones | ✅ UI paso a paso | - |
| Requiere testing | ⭐⭐ | ⭐⭐⭐⭐ | - |
| Archivos a copiar | 3 | 1 | - |

### **MI RECOMENDACIÓN:**

1. **Primero:** Implementa **Opción A** (1 hora) → Es rápido y agrega gameplay inmediato
2. **Segundo:** Implementa **Opción B** (1-2 horas) → Tutorial mejora retención de nuevos jugadores
3. **Opcional:** Combínalas para que el tutorial enseñe la mecánica de dodge

**ORDEN TOTAL:** Arreglos (3h) → Opción A (1h) → Opción B (1-2h) = **5-6 horas**

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### **Opción A - Sistema de Salto:**
- [ ] Copiar `MeteorDamageSystem.lua` a `ServerStorage`
- [ ] Copiar `NotificationUI.client.lua` a `StarterPlayerScripts`
- [ ] Reemplazar `EventManager` con `EventManager_REFACTORED.lua`
- [ ] Testear dodge (saltar cuando cae meteorito)
- [ ] Testear hit (quedarse quieto)
- [ ] Verificar notificaciones aparecen

### **Opción B - Tutorial:**
- [ ] Copiar `TutorialManager.lua` a `ServerStorage`
- [ ] Agregar código de activación en `main.server.lua`
- [ ] Personalizar pasos del tutorial (opcional)
- [ ] Testear tutorial completo
- [ ] Verificar que solo aparezca primera vez
- [ ] Agregar reward al completar (opcional)

---

## 🆘 TROUBLESHOOTING

### **Opción A no funciona:**

**Problema:** Notificaciones no aparecen
- ✅ Verifica que `NotificationUI.client.lua` esté en StarterPlayerScripts
- ✅ Verifica que EventManager cree el RemoteEvent "ShowNotification"
- ✅ Revisa el Output para warnings

**Problema:** Siempre recibo daño, incluso saltando
- ✅ Verifica que `JUMP_IMMUNITY_HEIGHT` en Config sea 5 (no más de 10)
- ✅ Salta MÁS ALTO (mantén presionado Espacio)
- ✅ Revisa el Output: debería decir "DODGED" si funciona

**Problema:** No recibo daño nunca
- ✅ Verifica que `MeteorDamageSystem` esté en ServerStorage (no ServerScriptService)
- ✅ Verifica que EventManager_REFACTORED tenga las líneas 274-280

### **Opción B no funciona:**

**Problema:** Tutorial no inicia
- ✅ Verifica que `HasCompletedTutorial` esté en `false`
- ✅ Verifica que agregaste el código en `PlayerAdded`
- ✅ Espera 2-3 segundos después de spawnar

**Problema:** Tutorial se congela en un paso
- ✅ Revisa el Output para ver qué paso está esperando
- ✅ Completa la acción requerida (recolectar coin, comprar upgrade, etc.)
- ✅ Usa `TutorialManager:SkipTutorial(player)` para saltar

---

## 🎉 ¡LISTO!

Una vez implementadas ambas opciones, tu juego tendrá:
- ✅ Mecánica de dodge skill-based
- ✅ Feedback visual claro
- ✅ Tutorial para retener jugadores nuevos
- ✅ Sistema de stats para achievements futuros

**Próximos pasos sugeridos:**
1. Agregar achievements basados en dodge stats
2. Leaderboard de mejores esquivadores
3. Power-ups temporales (speed boost, double jump, etc.)
4. Meteoritos especiales que requieren 2 saltos
5. Modo hardcore: 1-hit kill

---

_Última actualización: Después de crear NotificationUI y actualizar EventManager_REFACTORED._
