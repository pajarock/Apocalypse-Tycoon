# Apocalypse Tycoon - Configuración Segura

## ⚠️ IMPORTANTE: Lee esto ANTES de conectar Rojo

### 🛡️ Precauciones de Seguridad

1. **NUNCA** ejecutes `rojo serve` sin antes tener un backup
2. **SIEMPRE** guarda tu lugar de Roblox antes de conectar
3. **VERIFICA** que todos los archivos .lua estén en su lugar

---

## 📦 Paso 1: Verificar Estructura

Tu proyecto debe verse así:

```
proyecto_roblox/
├── default.project.json          ← Configuración de Rojo
├── setup_project_safe.bat        ← Script de ayuda (Windows)
├── README.md                      ← Este archivo
└── src/
    ├── ServerScriptService/
    │   ├── main_server.lua        ✓
    │   ├── BaseModule.lua         ✓
    │   ├── EconomyModule.lua      ✓
    │   ├── EventManager.lua       ✓
    │   ├── DataStoreModule.lua    ✓
    │   ├── AchievementModule.lua  ✓
    │   └── 1_CreateRemotes.lua    ✓
    ├── ServerStorage/
    │   └── Config/
    │       ├── Config.lua         ✓
    │       └── Upgrades.lua       ✓
    ├── StarterGui/
    │   ├── BaseHUD/
    │   │   └── BaseHUD_client.lua ✓
    │   ├── ShopUI/
    │   │   └── Shop_client.lua    ✓
    │   ├── EventNotifier.lua      ✓
    │   └── DamageNumbers.lua      ✓
    └── StarterPlayer/
        └── StarterPlayerScripts/
            └── ProximityUpgrades_client.lua ✓
```

## 🚀 Paso 2: Primer Uso SEGURO

### A. Backup Manual (CRÍTICO)

1. Abre Roblox Studio
2. Ve a `File > Save to File As...`
3. Guarda como: `ApocalypseTycoon_BACKUP_[fecha].rbxl`
4. Copia ese archivo a otra carpeta (Escritorio, Documents, etc.)

### B. Iniciar Rojo en Modo Seguro

```bash
# Opción 1: Iniciar normalmente
rojo serve

# Opción 2: Especificar puerto (si hay conflicto)
rojo serve --port 34873
```

**⚠️ NO CONECTES TODAVÍA**

### C. Conectar desde Roblox Studio (Primera vez)

1. **Instala el plugin de Rojo** (si no lo tienes):
   - https://rojo.space/docs/v7/getting-started/installation/

2. **En Roblox Studio:**
   - Abre el plugin de Rojo (icono arriba)
   - Haz clic en "Connect"
   - Puerto: `34872` (o el que especificaste)

3. **IMPORTANTE**: 
   - La primera vez, Rojo **LEERÁ** tu juego, no lo sobrescribirá
   - Si tienes `$ignoreUnknownInstances: true` en el config (ya lo agregué), Rojo NO borrará nada que no esté en el config

### D. Verificación Post-Conexión

Después de conectar, verifica que:
- ✓ Todos tus scripts aparecen en Studio
- ✓ No se borró nada
- ✓ Los remotes siguen ahí

Si algo salió mal:
1. **NO guardes en Studio**
2. Cierra Studio sin guardar
3. Abre tu backup `.rbxl`

---

## 🔄 Workflow Normal (Después de la primera vez)

### Editar código:

```bash
# 1. Inicia Rojo
rojo serve

# 2. Conecta desde Studio (plugin de Rojo)

# 3. Edita archivos en VSCode/tu editor
# Los cambios aparecerán automáticamente en Studio

# 4. Guarda en Studio cuando termines
```

### Editar en Studio:

**NOTA**: Si editas directamente en Studio:
- Los cambios se verán en Studio
- Pero **NO** se guardarán en tus archivos .lua
- Necesitas usar "Two-way sync" (avanzado) o editar solo en VSCode

---

## 🔧 Comandos Útiles

```bash
# Ver qué cambios hay
rojo sourcemap default.project.json --output sourcemap.json

# Construir archivo de lugar sin conectar
rojo build --output game.rbxl

# Verificar configuración
rojo --version
```

---

## 🆘 Solución de Problemas

### "Rojo borró todo mi juego"

Si esto pasa:
1. **Cierra Studio SIN guardar**
2. Abre tu backup `.rbxl`
3. Revisa el archivo `default.project.json`
4. Asegúrate de tener `$ignoreUnknownInstances: true`

### "No veo mis scripts en Studio"

1. Verifica que los archivos .lua existan en `src/`
2. Revisa que los nombres coincidan con `default.project.json`
3. Desconecta y reconecta Rojo

### "Puerto en uso"

```bash
# Usa otro puerto
rojo serve --port 34873

# Luego en Studio, conecta al nuevo puerto
```

---

## 📝 Configuración de Git (Opcional pero Recomendado)

```bash
git init
git add .
git commit -m "Initial commit: estructura base con Rojo"

# Conectar con GitHub
git remote add origin https://github.com/tu-usuario/ApocalypseTycoon.git
git push -u origin main
```

---

## ✅ Checklist Pre-Conexión

Antes de ejecutar `rojo serve`:

- [ ] Tengo backup del archivo .rbxl
- [ ] Todos los archivos .lua están en `src/`
- [ ] El archivo `default.project.json` existe
- [ ] He leído las precauciones de seguridad
- [ ] Sé dónde está mi backup si algo sale mal

---

## 🎯 Beneficios de Este Setup

✅ Editar código en tu IDE favorito (VSCode)
✅ Claude Code puede ver todo el proyecto
✅ Control de versiones con Git
✅ Sincronización automática con Studio
✅ Backup automático con Git

---

## 📞 Soporte

Si tienes problemas:
1. Lee la sección "Solución de Problemas"
2. Verifica el log de Rojo en la terminal
3. Busca en la documentación: https://rojo.space/docs

**¡No te preocupes!** Con los backups, siempre puedes volver atrás.
