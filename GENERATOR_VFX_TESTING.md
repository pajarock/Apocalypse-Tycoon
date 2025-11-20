# 🎨 TESTING: Generator Visual Effects (FASE 1)

## 📋 Resumen
Sistema de efectos visuales para generadores con 3 tiers temáticos apocalípticos.

**Branch**: `claude/feature/refactor-generators-v1-01C944AuDAUepscDb49YbK1Z`

**Cambios implementados**:
- ✅ GeneratorVFXManager.lua - Sistema modular de efectos visuales
- ✅ Billboard flotante dinámico (+$5, +$10, +$20)
- ✅ Sistema de partículas por tier (lava, cristal, energía)
- ✅ Glow pulsante con PointLight
- ✅ Integración completa con UpgradeService

---

## 🎯 Efectos Implementados

### 1️⃣ TIER 1: Extractor Volcánico 🔥
```
Color: Naranja ardiente (255, 100, 50)
Partículas: Chispas de lava flotando hacia arriba
Glow: Naranja brillante pulsante
Billboard: +$5 en color dorado cálido
```

### 2️⃣ TIER 2: Recolector Meteórico 💎
```
Color: Púrpura místico (150, 50, 200)
Partículas: Fragmentos cristalinos flotando
Glow: Púrpura brillante pulsante
Billboard: +$10 en color púrpura luminoso
```

### 3️⃣ TIER 3: Procesador Avanzado ⚡
```
Color: Cyan brillante (0, 255, 255)
Partículas: Energía pura con arcos eléctricos
Glow: Cyan eléctrico pulsante
Billboard: +$20 en color cyan brillante
```

---

## 🧪 Cómo Testear en Roblox Studio

### PASO 1: Abrir el Proyecto

1. Abre Roblox Studio
2. Carga el proyecto Apocalypse-Tycoon
3. Verifica que estás en la branch correcta (usa git)

### PASO 2: Iniciar el Juego

1. Presiona F5 para iniciar el juego
2. Espera a que los servicios se carguen:
```
[GeneratorVFXManager] ✓ Module loaded with 3 tiers
[UpgradeService] ✅ Started - Update loops running
```

### PASO 3: Colocar un Generador

1. Presiona **Z** para abrir el build menu
2. Selecciona **Generator**
3. Colócalo en tu base

**✅ Verificar**: Al colocar, deberías ver INMEDIATAMENTE:
- ✨ MainPart se vuelve **Neon naranja brillante**
- 🔥 **Partículas de lava** subiendo desde el generador
- 💡 **Luz pulsante** naranja (pulsa cada segundo)

### PASO 4: Observar Producción de Dinero

Espera **1 segundo** después de colocar el generador.

**✅ Verificar cada segundo**:
- 💰 Un **billboard flotante** aparece sobre el generador
- Muestra: **"+$5"** en color dorado cálido
- El texto **flota hacia arriba** durante 1.5 segundos
- Desaparece con **fade out** suave

### PASO 5: Colocar Múltiples Generadores

Coloca 2-3 generadores más.

**✅ Verificar**:
- Cada generador tiene su propio glow y partículas
- Los billboards aparecen de forma **independiente**
- No hay lag ni stuttering (gracias a object pooling)

### PASO 6: Verificar Object Pooling

Coloca y destruye generadores varias veces.

**✅ Verificar en Output**:
```
-- Deberías ver mensajes como:
[UpgradeService] 💰 Generator registered: OBJ_123 (Owner: 456, Rate: $5/s, Tier: 1)
[UpgradeService] Generator unregistered: OBJ_123
```

**✅ NO deberías ver**:
- Warnings sobre crear demasiadas instancias
- Lag al crear/destruir generadores

---

## 🔍 Testing Avanzado (Opcional)

### Command Bar Testing

Abre la Command Bar (F9 → abajo) y ejecuta:

```lua
-- Obtener GeneratorVFXManager
local ServerStorage = game:GetService("ServerStorage")
local VFXManager = require(ServerStorage.Managers.GeneratorVFXManager)

-- Obtener un generador existente
local generator = workspace:FindFirstChild("Generator", true)

if generator then
    -- Test: Mostrar producción manual
    VFXManager:ShowMoneyProduction(generator, 100, 1) -- $100, Tier 1

    -- Test: Cambiar tier visualmente
    VFXManager:RemoveEffects(generator)
    VFXManager:ApplyGlowPulse(generator, 2) -- Tier 2 (púrpura)
    VFXManager:CreateParticles(generator, 2) -- Partículas púrpura

    print("✅ Manual VFX test completed!")
else
    print("❌ No generator found in workspace")
end
```

### Verificar Tier Config

```lua
local ServerStorage = game:GetService("ServerStorage")
local VFXManager = require(ServerStorage.Managers.GeneratorVFXManager)

-- Ver configuración de cada tier
for tier = 1, 3 do
    local config = VFXManager:GetTierConfig(tier)
    print(string.format("Tier %d: %s - Color: %s",
        tier, config.Name, tostring(config.Color)))
end
```

---

## ✅ Criterios de Éxito

### Test PASADO ✅ si:

1. **Efectos visuales al colocar**:
   - ✅ MainPart se vuelve Neon con color correcto
   - ✅ PointLight aparece y pulsa
   - ✅ Partículas aparecen y suben

2. **Billboard flotante**:
   - ✅ Aparece cada segundo mostrando "+$5"
   - ✅ Flota hacia arriba
   - ✅ Desaparece con fade out
   - ✅ Color correcto según tier

3. **Performance**:
   - ✅ No hay lag al colocar múltiples generadores
   - ✅ Billboards se reutilizan (object pooling)
   - ✅ No hay memory leaks

4. **Cleanup**:
   - ✅ Efectos se eliminan al destruir generador
   - ✅ No quedan partículas "huérfanas"

### Test FALLIDO ❌ si:

1. ❌ No aparecen efectos visuales al colocar
2. ❌ Billboard no flota o no desaparece
3. ❌ Lag severo con 3+ generadores
4. ❌ Errors en el Output
5. ❌ Efectos permanecen después de destruir generador

---

## 🐛 Troubleshooting

### Problema: No aparecen efectos visuales

**Causa**: GeneratorVFXManager no se cargó correctamente

**Verificar**:
```lua
-- En Command Bar
local ServerStorage = game:GetService("ServerStorage")
local VFXManager = require(ServerStorage.Managers.GeneratorVFXManager)
print("VFXManager loaded:", VFXManager ~= nil)
```

**Solución**: Verifica que el archivo existe en `ServerStorage/Managers/`

---

### Problema: Billboard no aparece

**Causa 1**: MainPart no existe en el modelo

**Verificar**:
```lua
-- En Command Bar
local generator = workspace:FindFirstChild("Generator", true)
if generator then
    local mainPart = generator:FindFirstChild("MainPart")
    print("MainPart exists:", mainPart ~= nil)
end
```

**Solución**: Asegúrate de que el modelo del generador tiene un Part llamado "MainPart"

---

**Causa 2**: PlayerDataService no está agregando dinero

**Verificar Output**:
```
[ECONOMY] ADMIN gave 5 cash to uid=123456
```

Si NO ves esto, el generador no está produciendo dinero.

---

### Problema: Lag con múltiples generadores

**Causa**: Demasiadas partículas activas

**Solución temporal**:
```lua
-- Reducir PARTICLE_RATE en GeneratorVFXManager.lua
-- Cambiar línea ~34:
local PARTICLE_RATE = 5 -- En vez de 10
```

---

### Problema: Efectos no se eliminan

**Causa**: UnregisterGenerator no se está llamando

**Verificar Output**:
```
[UpgradeService] Generator unregistered: OBJ_123
```

Si NO ves esto al destruir, hay un problema con BaseOwnershipService.

---

## 📊 Resultados Esperados

Después de **10 segundos** con **1 generador Tier 1**:

- **Dinero ganado**: +$50
- **Billboards mostrados**: 10 (uno por segundo)
- **Partículas activas**: ~10-20 (constante)
- **FPS**: Sin cambios significativos

Con **3 generadores**:

- **Dinero ganado**: +$150 (10 segundos)
- **Billboards simultáneos**: Hasta 3 (uno por generador)
- **Partículas activas**: ~30-60
- **FPS**: Debería mantenerse estable (60 FPS)

---

## 🎨 Próximos Pasos (FASE 2 - Futuro)

Una vez que FASE 1 funcione correctamente:

- [ ] Implementar ProximityPrompt con estadísticas
- [ ] Agregar sonido de "cash register" cuando produce
- [ ] Implementar diferentes modelos visuales por tier
- [ ] Agregar efecto de construcción al colocar
- [ ] Sistema de upgrades de tier (T1 → T2 → T3)

---

## 📝 Notas Importantes

1. **Por ahora SOLO Tier 1** está activo (todos los generadores son Tier 1)
2. **TODO en el código** marca dónde expandir para Tier 2 y 3
3. El sistema está **preparado** para múltiples tiers, solo falta:
   - Agregar "GeneratorT2" y "GeneratorT3" en UpgradeDefinitions
   - Detectar el tipo en RegisterGenerator
4. **Object pooling** ya está implementado para billboards (max 20)

---

**Fecha de creación**: 2025-11-20
**Autor**: Claude (VFX Integration Team)
**Branch**: `claude/feature/refactor-generators-v1-01C944AuDAUepscDb49YbK1Z`
**Status**: ✅ Listo para testing en Roblox Studio
