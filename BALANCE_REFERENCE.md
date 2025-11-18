# ⚖️ BALANCE REFERENCE - Apocalypse Tycoon

**Versión:** Balance Moderado (Opción B)
**Fecha:** 2025-11-18
**Objetivo:** Mantener desafío mientras se permite progresión justa

---

## 📊 PROGRESIÓN DE WAVES

### Antes del Balance (OP):
```
Wave 1: 10 meteoritos | 25 daño | 87s intervalo → 4 impactos = muerte
Wave 2: 12 meteoritos | 30 daño | 84s intervalo → 3 impactos = muerte
Wave 3: 14 meteoritos | 35 daño | 81s intervalo → 3 impactos = muerte
Wave 5: 18 meteoritos | 45 daño | 75s intervalo → 2 impactos = muerte
```

### Después del Balance (MODERADO):
```
Wave 1:  7 meteoritos | 18 daño | 90s intervalo → 6 impactos = muerte ✅
Wave 2:  9 meteoritos | 22 daño | 87s intervalo → 5 impactos = muerte ✅
Wave 3: 11 meteoritos | 26 daño | 84s intervalo → 4 impactos = muerte ✅
Wave 5: 15 meteoritos | 34 daño | 78s intervalo → 3 impactos = muerte ✅
Wave 10: 27 meteoritos | 54 daño | 60s intervalo → Boss fight
```

---

## 🛡️ SISTEMA DE SHIELDS

### Antes:
- **Reducción por nivel:** 15%
- **Shield L1:** -15% daño
- **Shield L2:** -30% daño
- **Shield L3:** -45% daño (max)

**Problema:** Shields muy débiles, no valían la pena

### Después (BALANCEADO):
- **Reducción por nivel:** 18% (+20% efectividad)
- **Shield L1:** -18% daño
- **Shield L2:** -36% daño
- **Shield L3:** -54% daño (max)

**Impacto en Wave 5 (34 daño base):**
- Sin shield: 34 daño → 3 impactos = muerte
- Shield L1: 34 × 0.82 = **27.9 daño** → 4 impactos = muerte ✅
- Shield L2: 34 × 0.64 = **21.8 daño** → 5 impactos = muerte ✅
- Shield L3: 34 × 0.46 = **15.6 daño** → 6 impactos = muerte ✅

---

## 🎯 VALORES CLAVE

### Meteoritos:
- **Base por wave:** 7 (antes: 8)
- **Crecimiento:** +2 por wave (sin cambios)
- **Spawn rate:** 1 por segundo

### Daño:
- **Fórmula:** `14 + (wave × 4)`
- **Base:** 14 (antes: 20)
- **Crecimiento:** +4 por wave (antes: +5)

### Intervalos:
- **Fórmula:** `max(45, 90 - (wave × 3))`
- **Wave 1:** 90 segundos
- **Wave 10:** 60 segundos
- **Mínimo:** 45 segundos

---

## 📈 CURVA DE SUPERVIVENCIA

### Early Game (Waves 1-3):
- **Objetivo:** Aprender mecánicas
- **Meteoritos:** 7-11 por wave
- **Daño:** 18-26 por impacto
- **Estrategia:** Farmear income, comprar generador/shield

### Mid Game (Waves 4-7):
- **Objetivo:** Optimizar defensa
- **Meteoritos:** 13-19 por wave
- **Daño:** 30-42 por impacto
- **Estrategia:** Shield L2-L3, muros, MaxHP upgrades

### Late Game (Waves 8-10):
- **Objetivo:** Preparar para boss
- **Meteoritos:** 21-27 por wave
- **Daño:** 46-54 por impacto
- **Estrategia:** Maximizar defensa, farm agresivo

### Boss Waves (10, 20, 30...):
- **Special mechanics:** Meteorito gigante + lluvias
- **Recompensas:** Cash bonus, full heal

---

## 🔄 COMPARACIÓN DE REDUCCIÓN DE DAÑO

### Wave 3 (26 daño):
| Shield Level | Daño Recibido | Impactos para morir |
|--------------|---------------|---------------------|
| Sin shield   | 26 daño       | 4 impactos          |
| Shield L1    | 21.3 daño     | 5 impactos ✅       |
| Shield L2    | 16.6 daño     | 6 impactos ✅       |
| Shield L3    | 12 daño       | 8 impactos ✅       |

### Wave 5 (34 daño):
| Shield Level | Daño Recibido | Impactos para morir |
|--------------|---------------|---------------------|
| Sin shield   | 34 daño       | 3 impactos          |
| Shield L1    | 27.9 daño     | 4 impactos ✅       |
| Shield L2    | 21.8 daño     | 5 impactos ✅       |
| Shield L3    | 15.6 daño     | 6 impactos ✅       |

### Wave 10 (54 daño):
| Shield Level | Daño Recibido | Impactos para morir |
|--------------|---------------|---------------------|
| Sin shield   | 54 daño       | 2 impactos          |
| Shield L1    | 44.3 daño     | 2 impactos          |
| Shield L2    | 34.6 daño     | 3 impactos ✅       |
| Shield L3    | 24.8 daño     | 4 impactos ✅       |

---

## 💡 RECOMENDACIONES DE GAMEPLAY

### Prioridad de Compras:
1. **Wave 1-2:** Generator (income) → Shield L1
2. **Wave 3-4:** Shield L2 → Walls/MaxHP
3. **Wave 5+:** Shield L3 → Maximize income → Walls

### Estrategias Avanzadas:
- **Dash system:** Evitar meteoritos grandes (2.5s cooldown)
- **Repair timing:** Esperar 60s entre repairs para reset del streak
- **Income scaling:** Cada upgrade cuesta +15% más que el anterior

---

## 🔧 ARCHIVOS MODIFICADOS

1. **src/ServerStorage/Config/Config.lua:**
   - Línea 62: `SHIELD_REDUCTION_PER_LEVEL = 0.18`
   - Línea 339: `METEORS_PER_WAVE_BASE = 7`
   - Línea 344: `Damage = 14 + (waveNum * 4)`

2. **src/StarterGui/ShopUI/Shop.client.lua:**
   - Línea 201: `shieldReduction = shieldLevel * 18`
   - Línea 226: `nextReduction = (shieldLevel + 1) * 18`

---

## 📝 NOTAS PARA FUTURO BALANCE

### Si el juego es muy fácil:
- Incrementar `METEORS_PER_WAVE_BASE` de 7 a 8
- Incrementar daño base de 14 a 16
- Reducir shields de 18% a 16%

### Si el juego es muy difícil:
- Reducir `METEORS_PER_WAVE_BASE` de 7 a 6
- Reducir daño base de 14 a 12
- Incrementar shields de 18% a 20%

### Otras opciones:
- Agregar regeneración pasiva de HP
- Aumentar tiempo entre waves
- Reducir velocidad de meteoritos
- Agregar power-ups temporales

---

**🎮 ¡Buena suerte sobreviviendo al apocalipsis!**
