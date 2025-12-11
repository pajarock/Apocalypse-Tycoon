# 🎨 Menu Effects Integration Guide

## Efectos Implementados:

### 1. 💧 **Toxic Slime Drip**
- Gotas de slime verde tóxico cayendo desde el header
- Color: ToxicGreen (#39CA3A)
- Animación orgánica con fade out
- Se genera aleatoriamente cada 2-4 segundos

### 2. ☢️ **Radioactive Particles**
- Partículas verdes flotando hacia arriba (como ceniza radioactiva)
- Colores: NeonGreen, ToxicGreen, BrightGreen
- Movimiento continuo con drift horizontal
- 10-15 partículas activas simultáneamente

### 3. 💧 **Click Sound**
- Sonido de gota al hacer click en cualquier botón/card
- Volumen: 30%
- Permite múltiples clicks rápidos (clones del sonido)

### 4. 🎬 **Menu Open/Close Animations**
- Apertura: Scale desde 0 + slide hacia arriba + rotación leve
- Cierre: Scale a 0 + slide hacia abajo + rotación inversa
- Sonido de apertura incluido
- Estilo: Back easing (con "overshoot" al final)

---

## 📋 Cómo Integrar en ShopUIController:

### PASO 1: Agregar el módulo MenuEffects

Copia el archivo `MenuEffects.lua` a la misma carpeta que `ShopUIController.luau` en Roblox Studio.

### PASO 2: Require el módulo en tu ShopUIController

Añade esto al inicio del archivo (después de los otros requires):

```lua
local MenuEffects = require(script.Parent.MenuEffects)
```

### PASO 3: Variables de efectos

Añade estas variables en la sección de `Internal state`:

```lua
-- Visual Effects & Audio
local effectsSystem: any = nil
local menuOpenSound: Sound? = nil
```

### PASO 4: Setup de efectos (después de crear el UI)

En tu función `BuildUI()`, **después de crear todo el mainFrame**, añade:

```lua
-- ═══════════════════════════════════════════════════════
-- 🎨 SETUP VISUAL EFFECTS & AUDIO
-- ═══════════════════════════════════════════════════════
local function setupEffects()
	-- Recopilar todos los botones para click sound
	local allButtons = {}

	-- Main tabs
	for _, btn in pairs(mainTabButtons) do
		table.insert(allButtons, btn)
	end

	-- Sub tabs (si existen)
	for _, btn in pairs(subTabButtons) do
		table.insert(allButtons, btn)
	end

	-- Buy button
	if buyButton then
		table.insert(allButtons, buyButton)
	end

	-- Close button
	if closeButton then
		table.insert(allButtons, closeButton)
	end

	-- Setup completo
	effectsSystem = MenuEffects.SetupAllEffects(mainFrame, allButtons)
	menuOpenSound = effectsSystem.openSound

	print("🔥 Menu effects initialized!")
end

-- Llamar después de crear UI
setupEffects()
```

### PASO 5: Integrar animaciones en toggle menu

Modifica tu función `ToggleMenu()` para usar las animaciones:

```lua
local function ToggleMenu()
	isMenuOpen = not isMenuOpen

	if isMenuOpen then
		-- ABRIR MENU
		screenGui.Enabled = true

		-- 🎬 ANIMACIÓN DE APERTURA + SONIDO
		MenuEffects.PlayOpenAnimation(mainFrame, menuOpenSound)

		-- Update UI
		UpdateCurrentTab()
		UpdateCash()

		-- Start auto-refresh
		if refreshConnection then refreshConnection:Disconnect() end
		refreshConnection = RunService.Heartbeat:Connect(function()
			task.wait(2)
			if isMenuOpen then
				UpdateItemStates()
			end
		end)

	else
		-- CERRAR MENU

		-- 🎬 ANIMACIÓN DE CIERRE
		local closeTween = MenuEffects.PlayCloseAnimation(mainFrame)

		-- Esperar a que termine la animación antes de ocultar
		closeTween.Completed:Connect(function()
			screenGui.Enabled = false
		end)

		-- Stop auto-refresh
		if refreshConnection then
			refreshConnection:Disconnect()
			refreshConnection = nil
		end
	end
end
```

---

## 🔊 Audio Asset IDs

**IMPORTANTE:** Necesitas reemplazar los asset IDs en `MenuEffects.lua`:

```lua
local SOUNDS = {
	MenuOpen = "rbxassetid://XXXXXXXX",    -- Sonido de apertura
	ClickDrop = "rbxassetid://XXXXXXXX",   -- Sonido de click/gota
}
```

### Sonidos Recomendados (Roblox Audio Library):

**Para Menu Open:**
- `rbxassetid://3398620867` - Sci-fi whoosh
- `rbxassetid://5153845714` - Tech power up
- `rbxassetid://6895079853` - Futuristic open

**Para Click/Drop:**
- `rbxassetid://3398620867` - Water drop
- `rbxassetid://12221967` - Button click
- `rbxassetid://3398620867` - Tech beep

---

## 🎨 Customización de Colores

Los efectos usan la paleta actualizada que detecté en tu código:

```lua
local COLORS = {
	NeonGreen = Color3.fromRGB(183, 255, 75),      -- Verde neón suave
	ToxicGreen = Color3.fromRGB(57, 202, 58),      -- Verde tóxico fuerte
	SludgeGreen = Color3.fromRGB(90, 166, 19),     -- Verde oscuro
	BrightGreen = Color3.fromRGB(57, 255, 20),     -- Verde brillante
	NuclearYellow = Color3.fromRGB(255, 215, 140), -- Amarillo nuclear
}
```

Si quieres cambiar algún color, edita el archivo `MenuEffects.lua`.

---

## 🔧 Ajustes Opcionales

### Más/Menos Partículas
En `CreateRadioactiveParticles()`, cambia:
```lua
task.wait(math.random(3, 8) / 10) -- Más bajo = más partículas
```

### Velocidad de Slime Drip
En `CreateSlimeDrip()`, cambia:
```lua
local dripSpeed = math.random(8, 15) / 10 -- Más bajo = más lento
```

### Volumen de Sonidos
En `CreateClickSound()`:
```lua
clickSound.Volume = 0.3 -- Cambiar de 0.0 a 1.0
```

En `CreateMenuOpenSound()`:
```lua
openSound.Volume = 0.4 -- Cambiar de 0.0 a 1.0
```

---

## ✅ Testing Checklist

Después de integrar, verifica:

- [ ] Menu se abre con animación de scale + slide + rotación
- [ ] Sonido se reproduce al abrir menu
- [ ] Gotas de slime verde caen desde el top del menu
- [ ] Partículas verdes flotan hacia arriba constantemente
- [ ] Click en tabs/botones produce sonido de gota
- [ ] Menu se cierra con animación inversa
- [ ] No hay errores en console

---

## 🚨 Troubleshooting

**Problema:** No veo las partículas
- Verifica que `ClipsDescendants = true` en mainFrame

**Problema:** No escucho sonidos
- Verifica los asset IDs en SOUNDS table
- Checa que Volume > 0
- Asegúrate que Roblox Studio sound está activado

**Problema:** Animación no funciona
- Verifica que mainFrame.AnchorPoint esté en (0.5, 0.5)
- Checa que no haya otros scripts modificando Position/Size

**Problema:** Slime se ve cortado
- Cambia `ClipsDescendants = false` en slimeContainer
- Ajusta ZIndex para que aparezca encima

---

## 📝 Notas Finales

- Los efectos son **performance-friendly** (lightweight)
- Las partículas se auto-destruyen (no memory leaks)
- Los sonidos se clonan para permitir clicks rápidos
- Todo usa TweenService (smooth animations)

¡Disfruta tu menu apocalíptico nuclear! ☢️🔥
