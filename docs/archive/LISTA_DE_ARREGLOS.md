# 🔧 LISTA DE ARREGLOS Y MEJORAS

## ❌ **PROBLEMAS ACTUALES (Reportados por usuario)**

### **1. Camera Shake NO funciona**
- **Archivo:** `StarterPlayerScripts/CameraShake_client.lua`
- **Problema:** No se ve el shake cuando impactan meteoritos
- **Posible causa:** RemoteEvent no conectado correctamente o intensidad muy baja
- **Prioridad:** 🔴 Alta (afecta feedback visual)

### **2. ProceduralModels NO se usan**
- **Archivo:** `ServerStorage/Managers/ProceduralModels.lua`
- **Problema:** Existen modelos procedurales pero no se instancian
- **Causa probable:** main.server.lua crea placeholders en lugar de usar ProceduralModels
- **Prioridad:** 🟡 Media (visual, no afecta gameplay)

### **3. Barra de vida de base DUPLICADA**
- **Archivos:**
  - Billboard en `BaseVisualsManager` (funciona)
  - UI en `StarterGui/BaseHUD` (¿duplicado?)
- **Problema:** Se ven DOS barras de HP de la base
- **Solución:** Determinar cuál usar y quitar la otra
- **Prioridad:** 🟡 Media (confunde al jugador)

### **4. Wall Sections se sobreponen con paredes default**
- **Archivo:** `ServerStorage/Managers/BaseVisualsManager.lua`
- **Problema:**
  - Base tiene 4 paredes decorativas por default
  - Upgrade_7 (Wall Section) crea muros en la misma posición
  - Se solapan visualmente
- **Solución:**
  - Opción A: Quitar paredes default de BaseVisualsManager
  - Opción B: Cambiar posición de Wall Sections
- **Prioridad:** 🟡 Media (visual)

### **5. Contador de waves NO sube**
- **Archivo:** `ServerScriptService/Main.server.lua` (línea ~1150)
- **Problema:** ServerState.CurrentWave se incrementa pero no se guarda/muestra
- **Posible causa:** No hay UI que lo muestre o no se sincroniza con cliente
- **Prioridad:** 🟢 Baja (no crítico para gameplay)

### **6. NO hay barra de vida del jugador**
- **Estado:** ✅ **SOLUCIONADO**
- **Archivo creado:** `StarterPlayerScripts/PlayerHealthUI.client.lua`
- **Acción:** Usuario debe copiarlo a Studio

### **7. NO hay mapa ni terreno**
- **Estado:** Pendiente de implementar
- **Descripción:** Solo hay Baseplate default de Roblox
- **Necesita:**
  - Terreno apocalíptico (rocas, cráteres)
  - Skybox oscuro
  - Iluminación tétrica
- **Prioridad:** 🟢 Baja (cosmético, no afecta gameplay)

---

## ✅ **ARREGLADO**

- ✅ EventManager (buscaba módulos en lugar incorrecto)
- ✅ MeteorDamageSystem integrado (falta UI para ver efecto)
- ✅ Barra de vida del jugador creada (pendiente copiar a Studio)

---

## 🎯 **PRIORIDADES PARA HOY**

### **FASE 1: Arreglar lo roto (2-3 horas)**
1. ✅ Barra de vida del jugador
2. 🔴 Camera Shake
3. 🔴 ProceduralModels
4. 🟡 Quitar barra duplicada
5. 🟡 Arreglar Wall Sections

### **FASE 2: Implementar Opción A - Sistema de Salto (1 hora)**
- MeteorDamageSystem ya está integrado
- Solo necesita UI de feedback ("DODGED!" cuando evades)
- Crear RemoteEvent para notificaciones

### **FASE 3: Implementar Opción B - Tutorial (2 horas)**
- TutorialManager.lua (backend)
- UI de pantalla completa (cliente)
- Secuencia de pasos interactivos

### **FASE 4: Mapa básico (1 hora)** (Opcional si da tiempo)
- Terreno con Terrain Editor
- Skybox oscuro
- Iluminación apocalíptica

---

## 📥 **ARCHIVOS QUE NECESITO VER**

Para arreglar los problemas, necesito que me pases:

### **Prioridad ALTA:**
1. `StarterPlayerScripts/CameraShake_client.lua`
2. `ServerStorage/Managers/ProceduralModels.lua`
3. `ServerStorage/Managers/BaseVisualsManager.lua`

### **Prioridad MEDIA:**
4. `StarterGui/BaseHUD/[script principal]` (si existe)
5. `StarterPlayerScripts/Controllers/CameraController.lua`
6. `StarterPlayerScripts/Controllers/UIController.lua`

### **Cuando estés listo para tutorial:**
7. Cualquier UI existente de tutorial (si ya hay algo)

---

## 🔄 **WORKFLOW DE HOY**

```
1. Usuario me pasa archivos necesarios
   ↓
2. Arreglo cada problema uno por uno
   ↓
3. Commit & push después de cada fix
   ↓
4. Usuario testea en Studio
   ↓
5. Si funciona → siguiente problema
   Si falla → debug y retry
   ↓
6. Repetir hasta terminar todos los arreglos
   ↓
7. Implementar Opciones A y B
   ↓
8. Testing final
```

---

## ⏱️ **ESTIMACIÓN DE TIEMPO**

| Tarea | Tiempo | Estado |
|-------|--------|--------|
| Barra vida jugador | 15 min | ✅ Hecho |
| Camera Shake | 30 min | ⏳ Pendiente |
| ProceduralModels | 45 min | ⏳ Pendiente |
| Barras duplicadas | 15 min | ⏳ Pendiente |
| Wall Sections | 30 min | ⏳ Pendiente |
| Contador waves | 20 min | ⏳ Pendiente |
| **SUBTOTAL FASE 1** | **~3 horas** | |
| Opción A (Salto) | 1 hora | ⏳ Pendiente |
| Opción B (Tutorial) | 2 horas | ⏳ Pendiente |
| Mapa básico | 1 hora | 🔵 Opcional |
| **TOTAL** | **6-7 horas** | |

**Meta de hoy:** Terminar Fase 1 + Opciones A y B = 6 horas

---

## 💬 **SIGUIENTE PASO**

Usuario debe pasar los 3 archivos de prioridad ALTA:
1. CameraShake_client.lua
2. ProceduralModels.lua
3. BaseVisualsManager.lua

Una vez tenga esos, empiezo a arreglar en orden de prioridad.

---

_Última actualización: Después de confirmar que EventManager funciona._
