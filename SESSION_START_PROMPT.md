# 🎯 PROMPT DE INICIO PARA NUEVA SESIÓN

Copia y pega esto al inicio de la nueva sesión de Claude:

---

**Contexto**: Proyecto Apocalypse Tycoon (Roblox, Knit Framework, UTF-8)

**Tarea**: Integrar Machine Gun + Sistema de Meteoritos + Base Knit para que la torreta funcione completamente (detectar, disparar, hacer daño a meteoritos que caen en la base correcta).

**Estado actual**:
- ✅ Visuales de upgrade funcionan perfectamente (PR anterior merged)
- ✅ Machine Gun tiene 5 tiers con stats definidos (T1-T5)
- ❌ Meteoritos caen en base legacy (NO en base Knit creada con /testbase)
- ❌ Machine Gun no dispara a nada (falta sistema de targeting)
- ❌ No hay sistema de damage funcional

**Script completo**: Lee el archivo `NEXT_SESSION_METEOR_INTEGRATION.md` que tiene TODO el plan paso a paso.

**IMPORTANTE**:
1. Empezar con FASE 1: INVESTIGACIÓN (leer MeteorDamageSystem.lua, EventManager.lua, buscar base Knit)
2. Reportar findings ANTES de codificar
3. Proponer arquitectura y esperar aprobación
4. Solo entonces implementar

**Branch**: Crear `claude/machine-gun-firing-[SESSION_ID]` desde main

**Criterio de éxito**: Machine Gun detecta meteoritos, dispara automáticamente, hace daño, meteoritos caen en base Knit.

Empieza con: "Voy a leer NEXT_SESSION_METEOR_INTEGRATION.md y empezar con la investigación del código legacy..."
