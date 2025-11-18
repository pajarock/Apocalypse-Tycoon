@echo off
REM Script seguro para configurar proyecto de Roblox
REM NO borra nada, solo crea estructura

echo ============================================
echo CONFIGURACION SEGURA DE PROYECTO ROBLOX
echo ============================================
echo.

REM Verificar si ya existe src/
if exist src\ (
    echo [ADVERTENCIA] La carpeta 'src' ya existe!
    echo.
    choice /C SN /M "Deseas RENOMBRAR la carpeta existente a 'src_old'"
    if errorlevel 2 goto :EOF
    if errorlevel 1 (
        echo Renombrando src a src_old...
        move src src_old
    )
)

echo Creando estructura de carpetas...
echo.

REM Crear estructura base
mkdir src
mkdir src\ServerScriptService
mkdir src\ServerStorage
mkdir src\ServerStorage\Config
mkdir src\StarterGui
mkdir src\StarterGui\BaseHUD
mkdir src\StarterGui\ShopUI
mkdir src\StarterPlayer
mkdir src\StarterPlayer\StarterPlayerScripts
mkdir src\ReplicatedStorage
mkdir src\ReplicatedStorage\Remotes

echo [OK] Estructura de carpetas creada
echo.
echo SIGUIENTE PASO:
echo 1. Copia manualmente tus archivos .lua a las carpetas correspondientes
echo 2. NO uses 'rojo serve' hasta que todos los archivos esten copiados
echo.
pause
