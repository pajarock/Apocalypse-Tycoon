# ============================================
# APOCALYPSE TYCOON - AUTO FIX SCRIPT
# Este script renombra automáticamente los archivos
# ============================================

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  APOCALYPSE TYCOON - AUTO FIX" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Verificar ubicación
$currentPath = Get-Location
Write-Host "📁 Ubicación: $currentPath" -ForegroundColor Yellow

if (-not (Test-Path "src\ServerScriptService")) {
    Write-Host ""
    Write-Host "❌ ERROR: No se encuentra la carpeta src\ServerScriptService" -ForegroundColor Red
    Write-Host "   Por favor, ejecuta este script desde la carpeta proyecto_roblox" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit
}

Write-Host "✓ Carpeta correcta detectada" -ForegroundColor Green
Write-Host ""

# ============================================
# FUNCIÓN PARA RENOMBRAR ARCHIVOS
# ============================================
function Rename-IfExists {
    param(
        [string]$OldName,
        [string]$NewName
    )
    
    if (Test-Path $OldName) {
        if (Test-Path $NewName) {
            Write-Host "  ⚠ $NewName ya existe, eliminando duplicado..." -ForegroundColor Yellow
            Remove-Item $OldName -Force
        } else {
            Rename-Item -Path $OldName -NewName $NewName -Force
            Write-Host "  ✓ Renombrado: $OldName → $NewName" -ForegroundColor Green
        }
        return $true
    }
    return $false
}

# ============================================
# RENOMBRAR ARCHIVOS EN ServerScriptService
# ============================================
Write-Host "🔧 Verificando archivos en ServerScriptService..." -ForegroundColor Cyan
Write-Host ""

$fixed = 0

# Renombrar CreateRemotes
if (Rename-IfExists "src\ServerScriptService\1_CreateRemotes.server.lua" "src\ServerScriptService\CreateRemotes.server.lua") {
    $fixed++
}
if (Rename-IfExists "src\ServerScriptService\CreateRemotes.lua" "src\ServerScriptService\CreateRemotes.server.lua") {
    $fixed++
}

# Renombrar Main
if (Rename-IfExists "src\ServerScriptService\main_server.lua" "src\ServerScriptService\Main.server.lua") {
    $fixed++
}
if (Rename-IfExists "src\ServerScriptService\Main.lua" "src\ServerScriptService\Main.server.lua") {
    $fixed++
}

Write-Host ""
Write-Host "📊 Archivos corregidos: $fixed" -ForegroundColor Cyan
Write-Host ""

# ============================================
# LISTAR ARCHIVOS ACTUALES
# ============================================
Write-Host "📋 Archivos actuales en ServerScriptService:" -ForegroundColor Cyan
Write-Host ""

$files = Get-ChildItem -Path "src\ServerScriptService" -File | Select-Object -ExpandProperty Name

foreach ($file in $files) {
    if ($file -match "\.server\.lua$") {
        Write-Host "  ✓ $file" -ForegroundColor Green -NoNewline
        Write-Host " [Script]" -ForegroundColor Gray
    }
    elseif ($file -match "\.client\.lua$") {
        Write-Host "  ⚠ $file" -ForegroundColor Yellow -NoNewline
        Write-Host " [LocalScript - ¿debería estar aquí?]" -ForegroundColor Gray
    }
    elseif ($file -match "\.lua$") {
        Write-Host "  ✓ $file" -ForegroundColor Green -NoNewline
        Write-Host " [ModuleScript]" -ForegroundColor Gray
    }
    else {
        Write-Host "  ❌ $file" -ForegroundColor Red -NoNewline
        Write-Host " [TIPO DESCONOCIDO]" -ForegroundColor Gray
    }
}

# ============================================
# VERIFICAR ARCHIVOS NECESARIOS
# ============================================
Write-Host ""
Write-Host "🔍 Verificando archivos necesarios..." -ForegroundColor Cyan
Write-Host ""

$requiredFiles = @{
    "src\ServerScriptService\CreateRemotes.server.lua" = "Script"
    "src\ServerScriptService\Main.server.lua" = "Script"
    "src\ServerScriptService\AchievementModule.lua" = "ModuleScript"
    "src\ServerScriptService\BaseModule.lua" = "ModuleScript"
    "src\ServerScriptService\DataStoreModule.lua" = "ModuleScript"
    "src\ServerScriptService\EconomyModule.lua" = "ModuleScript"
    "src\ServerScriptService\EventManager.lua" = "ModuleScript"
}

$missing = 0
foreach ($file in $requiredFiles.Keys) {
    $fileName = Split-Path $file -Leaf
    if (Test-Path $file) {
        Write-Host "  ✓ $fileName" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $fileName (FALTA)" -ForegroundColor Red
        $missing++
    }
}

Write-Host ""

# ============================================
# RESULTADO FINAL
# ============================================
if ($missing -eq 0) {
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "  ✅ TODO CORRECTO!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Siguiente paso: Ejecuta 'rojo serve'" -ForegroundColor Yellow
} else {
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host "  ⚠ FALTAN ARCHIVOS" -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Faltan $missing archivos. Revisa la guía completa." -ForegroundColor Red
}

Write-Host ""
Read-Host "Presiona Enter para salir"
